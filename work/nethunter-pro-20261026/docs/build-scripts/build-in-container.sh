#!/usr/bin/env bash
#
# $ ./$0
# $ ./$0 [...] --force
# $ CONTAINER=docker ./$0
#

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#
## Environment
#

set -euEo pipefail
trap 'cleanup' INT TERM

cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#
## Variables
#

CONTAINER="${CONTAINER:-}"
FORCE=0
IMAGE="${IMAGE:-kali-build/kali-nethunterpro}"   # Alt: docker.io/godebos/debos ~ https://hub.docker.com/r/godebos/debos ~ https://github.com/go-debos/debos
OPTS=()
SUDO=()

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#
## Functions
#

## Output bold only if both stdout/stderr are opened on a terminal
if [ -t 1 ] && [ -t 2 ]; then
  b() { tput bold; echo -n "${*}"; tput sgr0; }
else
  b() { echo -n "${*}"; }
fi

point() { echo " * ${*}"; }
warn()  { echo "WARNING: ${*}" 1>&2; }
fail()  { echo "ERROR: ${*}"   1>&2; exit 1; }

vexec() { b "$ ${*}"; echo; exec "${@}"; }   # Last program in this script should use exec
vrun()  { b "$ ${*}"; echo;      "${@}" <&0 & child_pid=${!}; wait "${child_pid}"; }   # Backgrounded + waited on (rather than a plain foreground call) so cleanup() can kill it if we're interrupted

## Kill vrun()
cleanup() { [ -n "${child_pid:-}" ] && kill -TERM "${child_pid}" 2>/dev/null; return 0; }

build_container() {
  local _cache_args=()
  [ "${FORCE}" -eq 1 ] && _cache_args=(--no-cache)

  if [ "${FORCE}" -eq 1 ] || ! "${SUDO[@]}" "${CONTAINER}" inspect --type image "${IMAGE}" >/dev/null 2>&1; then
    vrun "${SUDO[@]}" "${CONTAINER}" build --network host "${_cache_args[@]}" --tag "${IMAGE}" .
    echo
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#
## Parse & validate arguments
#

_passthrough=()
while [ $# -gt 0 ]; do
  case "${1}" in
    --force)  FORCE=1;                shift ;;
    ## Consumed, not forwarded - the --volume below needs OUT_DIR, and it must be absolute
    -o|--output)
              OUT_DIR="$( realpath -m -- "${2:-}" )"; shift 2 ;;
    --output=*)
              OUT_DIR="$( realpath -m -- "${1#*=}" )"; shift ;;
    *)        _passthrough+=("${1}"); shift ;;
  esac
done
set -- "${_passthrough[@]}"
unset _passthrough

if command -v podman >/dev/null 2>&1 && \
  { [ -z "${CONTAINER}" ] || [ "${CONTAINER}" == "podman" ]; }; then
  CONTAINER=podman

  ## We don't want stdout in the journal
  OPTS+=( --log-driver none )

  _rootless=$( "${CONTAINER}" info --format '{{.Host.Security.Rootless}}' 2>/dev/null ) || true
  if [ "${_rootless}" != "false" ]; then
    warn "${CONTAINER} is rootless (or '${CONTAINER} info' failed)"
    warn "  ${CONTAINER} info Host.Security.Rootless: '${_rootless}'"

    ## Using /dev/kvm speeds up building a lot (KVM + QEMU), otherwise its slooooow (QEMU only)
    ##   Podman can run (easy) as rootful and rootless. Rootless needs permission to access /dev/kvm
    ##   Its possible to pass the hosts groups (primary + secondary/supplementary) in order to access /dev/kvm
    ##   You have (a lot of) options with podman, one of them is crun vs runc.
    ##   Had issues (2026-06-12), runc (1.3.5+ds1-1) was silently having issues - crun (1.28-1) working
    if ! command -v crun >/dev/null 2>&1; then
      warn "rootless ${CONTAINER} + runc cannot access: /dev/kvm"
      warn "  Either: install crun (e.g. $ sudo apt install crun) or re-run with sudo (aka rootful)"
      fail "Missing 'crun', aborting"
    fi

    OPTS+=(
      --runtime crun            # runc works with rootful, crun works with rootless, in order to (correctly) pass secondary/supplementary hosts groups into container
      --userns=keep-id   # Builds, but on podman the artifact differs   # Keeps host's uid/gid, quieting fakemachine's "do not run as root" warning
      --group-add keep-groups   # Pass all host groups (e.g. kvm) into the userns (user namespace) to access /dev/kvm
    )
  fi
elif command -v docker >/dev/null 2>&1 && \
  { [ -z "${CONTAINER}" ] || [ "${CONTAINER}" == "docker" ]; }; then
  CONTAINER=docker
else
  if [ -z "${CONTAINER}" ]; then
    fail "No container engine detected, aborting"
  elif [ "${CONTAINER}" = "podman" ] || [ "${CONTAINER}" = "docker" ]; then
    fail "Requested container engine is not installed: ${CONTAINER}"
  else
    fail "Unknown CONTAINER value: ${CONTAINER}"
  fi
fi

## Permissions & security
OPTS+=(
  ## The build happens via `debos`, which uses `fakemachine` to spin up a nested QEMU/KVM VM and does the actual OS install inside that VM, not via chroot/debootstrap in this container directly.
  ##   So there is no "--cap-add" from bpftrace.
  ## The final check was to compare artifacts produced from the "baseline" bare metal build (./build.sh) at the start, with a container (./build-in-container.sh)
  ##   NOTE: but virt-ls does not report file capabilities
  ##   $ tar -tvJf output/rootfs*.tar.xz
  ## ...that is the intermediate rootfs ./rootfs.yaml packs for ./image.yaml to unpack, kept only under -k or -r/--rootfs (./build.sh removes ${OUT_DIR}/rootfs.tar.xz otherwise). Capabilities survive
  ## the pack, so it stands on its own. The shipped .img is the second:
  ##   $ virt-ls -l -R --uids kali-nethunterpro-*.img
  ## Plus, this artifact has a partitioned disk image, so need loop-mount it and read the rootfs directly:
  ##   $ sudo losetup -fP --show kali-nethunterpro-*.img
  ##   > /dev/loop0
  ##   $ sudo mount -o ro /dev/loop0p1 /mnt/root          # largest partition
  ##   $ sudo find /mnt/root -printf '%p %M %U:%G %s\n' | sort
  ##   $ sudo getcap -r /mnt/root
  ##   > /mnt/root/usr/bin/fping cap_net_raw=ep
  ##   > /mnt/root/usr/lib/nmap/nmap cap_net_bind_service,cap_net_admin,cap_net_raw=eip
  ##   > /mnt/root/usr/lib/x86_64-linux-gnu/gstreamer1.0/gstreamer-1.0/gst-ptp-helper cap_net_bind_service,cap_net_admin,cap_sys_nice=ep
  ##   $ sudo umount /mnt/root && sudo losetup -d /dev/loop0
  ## Items checked for:
  ##   - Size (compression noise excluded)
  ##   - File count
  ##   - Permissions
  ##   - Owner/group
  ##   - Path
  ##   - Content
  ##   - Capabilities and device nodes
  ## Output that differs between two identical builds is filtered first:
  ##   /etc/ssh/ssh_host_*_key
  ##   /etc/ssl/private/ssl-cert-snakeoil.key
  ##   /var/lib/inetsim/certs/default_key.pem
  ##   /var/lib/texmf/web2c/pdftex/latex.fmt
  ##   /var/lib/texmf/web2c/pdftex/pdflatex.fmt
  ##   /var/lib/texmf/web2c/luahbtex/luahbtex.fmt
  ##   /var/lib/apt/lists/..._Packages
  ##   /var/lib/command-not-found/commands.db
  --cap-drop=ALL
)

## Core values
OPTS+=(
  --rm

  #--network host

  --volume "${PWD}:/build"   # Will not build without it: --workdir /build is empty and the entrypoint is not found   # Alt: ${PWD}:/srv or ${PWD}:/recipes   # Alt: --mount type=bind,source=${PWD},destination=/recipes
  --workdir /build

  ## This is for ./build.sh, so it can hand ${OUT_DIR} back to the invoking user (matters more if ran with sudo)
  --env "HOST_UID=${SUDO_UID:-$( id -u )}"
  --env "HOST_GID=${SUDO_GID:-$( id -g )}"
)

## If stdin is an option, use tty
if [ -t 0 ]; then
  OPTS+=(
    --interactive
    --tty
  )
fi

## Output artifacts location
if [ -n "${OUT_DIR:-}" ]; then
  mkdir -pv "${OUT_DIR}"
  OPTS+=(
    --volume "${OUT_DIR}:${OUT_DIR}"   # Will not build without it: ./build.sh cannot hand the artifact back to the host
    --env "OUT_DIR=${OUT_DIR}"
  )
fi

## Scratchpad for temp working artifacts - due to $TMPDIR: debos/fakemachine
if [ -n "${SCRATCHPAD_DIR:-}" ]; then
  mkdir -pv "${SCRATCHPAD_DIR}"
  OPTS+=(
    --volume "${SCRATCHPAD_DIR}:${SCRATCHPAD_DIR}"   # Will not build without it: debos writes the intermediate rootfs there
    --env "SCRATCHPAD_DIR=${SCRATCHPAD_DIR}"
  )
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Kernel-based Virtual Machine (KVM) - Check if virtualization extensions is enabled (in BIOS/UEFI)
[ -e /dev/kvm ] \
  || fail "Missing: /dev/kvm"

stat -c "%g" /dev/kvm \
  || fail "Cannot stat: /dev/kvm (permissions issue?)"

OPTS+=( --device /dev/kvm )   # Will not build without it: debos/fakemachine needs KVM

## debos's image-partition action (./image.yaml, not ./rootfs.yaml) needs these itself, in fakemachine's PreNoMachine stage (before the nested VM even starts)
## Loop devices - ensure some exist (host may never have used one, e.g. `loop` module not loaded), then pass each in explicitly
## mknod needs root. ${SUDO[@]} is only filled in by rootless_sudo(), which this
##   build-script does not have, so decide it here instead
_loop_sudo=()
if [ "$( id -u )" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    _loop_sudo=(sudo)
  fi
fi
"${_loop_sudo[@]}" modprobe loop 2>/dev/null || true

## The kernel creates /dev/loopN on demand via /dev/loop-control
##   The list passed into the container is fixed at start-up, so any node the kernel adds later is missing inside it
##   Hits when every existing node is already busy (e.g. multiple build-scripts running at once)
##   > losetup: [...].raw: failed to set up loop device: No such file or directory
##   > losetup: device node /dev/loop10 (7:10) is lost. You may use mknod(1) to recover it.
##   Therefore pre-create a pool up front, so the allocation always lands on a node passed in below (losetup's own recommendation)
_loop_missing=0
for _i in $( seq 0 15 ); do
  [ -e "/dev/loop${_i}" ] && continue
  "${_loop_sudo[@]}" mknod -m 0660 "/dev/loop${_i}" b 7 "${_i}" 2>/dev/null \
    && "${_loop_sudo[@]}" chown root:disk "/dev/loop${_i}" 2>/dev/null \
    || _loop_missing=$(( _loop_missing + 1 ))
done
[ "${_loop_missing}" -eq 0 ] \
  || warn "Could not pre-create ${_loop_missing} /dev/loopN node(s) - needs root. A build will fail if every pre-existing loop device is busy"
unset _i _loop_missing _loop_sudo

[ -e /dev/loop-control ] \
  && OPTS+=( --device /dev/loop-control )   # Needed together with the --device /dev/loopN line below - dropping either breaks the image   # > failed to setup loop device: could not open /dev/loop-control: no such file or directory

_loop_count=0
for _loopdev in /dev/loop[0-9]*; do
  ## Only pass loop devices which do exist and are block devices
  [ -b "${_loopdev}" ] || continue

  ## Only pass real loop devices, not partition nodes (loopNpM)
  case "${_loopdev##*/}" in loop*[!0-9]*) continue ;; esac

  OPTS+=( --device "${_loopdev}" )   # Needed together with --device /dev/loop-control above - dropping either breaks the image
  _loop_count=$(( _loop_count + 1 ))
done
[ "${_loop_count}" -eq 0 ] \
  && warn "No /dev/loopN devices found on the host - losetup will have nothing to attach to inside the container (try: $ sudo modprobe loop)"
unset _loopdev _loop_count

## Podman is better here, as Docker behaves a little bit different (its lacking host-uid remap)
if [ "$( id -u )" -eq 0 ] || [ "${CONTAINER}" = "docker" ]; then
  ## When running as root, force container to non-root to quiet fakemachine warning (as it does not want to be root)
  OPTS+=(
    --user "$( stat --format="%u:%g" . )"
    --group-add "$( stat -c "%g" /dev/kvm )"
  )

  [ -e /dev/loop-control ] \
    && OPTS+=( --group-add "$( stat -c "%g" /dev/loop-control )" )
fi

if [ -n "${DEBUG:-}" ]; then
  OPTS+=(
    --env "DEBUG=${DEBUG}"
  )
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#
## Build
#

build_container

vexec "${SUDO[@]}" "${CONTAINER}" run "${OPTS[@]}" "${IMAGE}" /build/build.sh "${@}"
