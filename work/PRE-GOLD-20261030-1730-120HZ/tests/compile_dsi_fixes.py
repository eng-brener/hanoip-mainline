#!/usr/bin/env python3
"""Apply the local fix diff to a disposable baseline copy and compile one TU.

Runs inside the existing build container. Baseline source/object mounts stay RO.
No image packaging or device access. Reuses the saved Kbuild compiler flags.
"""
from pathlib import Path
import shlex
import subprocess
import tempfile

repo = Path('/repo')
baseline = Path('/test/linux')
obj = Path('/test/obj')
relative = Path('drivers/gpu/drm/msm/dsi/dsi_host.c')
patches = [repo / 'work/display-120hz-20261030/dsi-fixes-all.patch']

with tempfile.TemporaryDirectory(prefix='dsi-fix-compile-') as temp:
    root = Path(temp)
    source = root / 'linux'
    destination = source / relative
    destination.parent.mkdir(parents=True)
    destination.write_bytes((baseline / relative).read_bytes())
    for patch in patches:
        subprocess.run(['git', 'apply', '--verbose', '-p2', str(patch)],
                       cwd=source, check=True)
    # Complete only the files read by the host tests, not a new kernel tree.
    for item in ('drivers/input/touchscreen/ilitek-hanoip-spi.c',
                 'drivers/regulator/qcom-lcdb-regulator.c',
                 'drivers/gpu/drm/msm/dsi/dsi_manager.c'):
        link = source / item
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(baseline / item)
    subprocess.run(['python3', str(repo / 'work/display-120hz-20261030/review_host_tests.py'),
                    '--source', str(source), '--repo', str(repo), '--fixed'], check=True)
    subprocess.run(['python3', str(repo / 'work/display-120hz-20261030/review_more_candidates.py'),
                    '--source', str(source), '--fixed'], check=True)
    command_file = obj / relative.parent / '.dsi_host.o.cmd'
    command = command_file.read_text().splitlines()[0].split(' := ', 1)[1]
    arguments = shlex.split(command.replace('/src/linux', str(baseline)))
    arguments = [arg for arg in arguments if not arg.startswith('-Wp,-MMD,')]
    arguments[arguments.index('-o') + 1] = str(root / 'dsi_host.o')
    arguments[arguments.index(str(baseline / relative))] = str(destination)
    # Diagnostics from this translation unit must be fatal.
    arguments.append('-Werror')
    subprocess.run(arguments, cwd=obj, check=True)
    result = subprocess.run(['aarch64-linux-gnu-readelf', '-h', str(root / 'dsi_host.o')],
                            text=True, capture_output=True, check=True)
    assert 'AArch64' in result.stdout
    print('PASS: corrected experimental DSI host compiled ARM64 with saved Kbuild flags and -Werror', flush=True)
