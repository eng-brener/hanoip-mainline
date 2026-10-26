savedcmd_qcom-spmi-sdam.mod := printf '%s\n'   qcom-spmi-sdam.o | awk '!x[$$0]++ { print("./"$$0) }' > qcom-spmi-sdam.mod
