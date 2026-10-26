savedcmd_qcom_qg.mod := printf '%s\n'   qcom_qg.o | awk '!x[$$0]++ { print("./"$$0) }' > qcom_qg.mod
