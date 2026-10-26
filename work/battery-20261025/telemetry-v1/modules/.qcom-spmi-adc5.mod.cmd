savedcmd_qcom-spmi-adc5.mod := printf '%s\n'   qcom-spmi-adc5.o | awk '!x[$$0]++ { print("./"$$0) }' > qcom-spmi-adc5.mod
