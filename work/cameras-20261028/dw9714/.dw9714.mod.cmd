savedcmd_dw9714.mod := printf '%s\n'   dw9714.o | awk '!x[$$0]++ { print("./"$$0) }' > dw9714.mod
