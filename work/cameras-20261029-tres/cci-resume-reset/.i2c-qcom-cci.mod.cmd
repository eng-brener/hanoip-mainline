savedcmd_i2c-qcom-cci.mod := printf '%s\n'   i2c-qcom-cci.o | awk '!x[$$0]++ { print("./"$$0) }' > i2c-qcom-cci.mod
