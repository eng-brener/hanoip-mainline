/*
 * Read only a known identity register on the sensor candidates used by the
 * Hanoip diagnostic. The first I2C message selects a register address; the
 * second reads it. This utility has no register-write operation.
 */
#include <errno.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static int parse_hex(const char *s, unsigned long *value)
{
	char *end;

	errno = 0;
	*value = strtoul(s, &end, 0);
	return errno || !*s || *end || *value > 0xff;
}

int main(int argc, char **argv)
{
	unsigned long addr, reg;
	unsigned char command, value = 0;
	struct i2c_msg msgs[2];
	struct i2c_rdwr_ioctl_data transfer = { .msgs = msgs, .nmsgs = 2 };
	int fd, ret;

	if (argc != 4 || strncmp(argv[1], "/dev/i2c-", 9) ||
	    parse_hex(argv[2], &addr) || parse_hex(argv[3], &reg)) {
		fprintf(stderr, "usage: %s /dev/i2c-N 0x68|0x39 0x75|0x93\n",
			argv[0]);
		return 2;
	}
	if (!((addr == 0x68 && reg == 0x75) ||
	      (addr == 0x39 && reg == 0x93))) {
		fprintf(stderr, "refusing non-identity register/address pair\n");
		return 2;
	}
	command = (unsigned char)reg;
	msgs[0] = (struct i2c_msg) {
		.addr = (unsigned short)addr,
		.flags = 0,
		.len = 1,
		.buf = &command,
	};
	msgs[1] = (struct i2c_msg) {
		.addr = (unsigned short)addr,
		.flags = I2C_M_RD,
		.len = 1,
		.buf = &value,
	};

	fd = open(argv[1], O_RDWR | O_CLOEXEC);
	if (fd < 0) {
		perror(argv[1]);
		return 1;
	}
	ret = ioctl(fd, I2C_RDWR, &transfer);
	if (ret < 0) {
		perror("I2C read");
		close(fd);
		return 1;
	}
	close(fd);
	printf("address=0x%02lx register=0x%02lx value=0x%02x\n",
	       addr, reg, value);
	return 0;
}
