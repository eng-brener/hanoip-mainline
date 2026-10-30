savedcmd_dw9768.mod := printf '%s\n'   dw9768.o | awk '!x[$$0]++ { print("./"$$0) }' > dw9768.mod
