savedcmd_ov02b10.mod := printf '%s\n'   ov02b10.o | awk '!x[$$0]++ { print("./"$$0) }' > ov02b10.mod
