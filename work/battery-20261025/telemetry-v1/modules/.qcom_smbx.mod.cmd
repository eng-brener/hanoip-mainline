savedcmd_qcom_smbx.mod := printf '%s\n'   qcom_smbx.o | awk '!x[$$0]++ { print("./"$$0) }' > qcom_smbx.mod
