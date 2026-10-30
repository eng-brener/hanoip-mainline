savedcmd_hanoip-cam.mod := printf '%s\n'   hanoip-cam.o | awk '!x[$$0]++ { print("./"$$0) }' > hanoip-cam.mod
