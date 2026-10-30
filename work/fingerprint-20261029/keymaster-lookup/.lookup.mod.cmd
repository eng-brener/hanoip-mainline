savedcmd_lookup.mod := printf '%s\n'   lookup.o | awk '!x[$$0]++ { print("./"$$0) }' > lookup.mod
