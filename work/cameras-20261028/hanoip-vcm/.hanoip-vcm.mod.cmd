savedcmd_hanoip-vcm.mod := printf '%s\n'   hanoip-vcm.o | awk '!x[$$0]++ { print("./"$$0) }' > hanoip-vcm.mod
