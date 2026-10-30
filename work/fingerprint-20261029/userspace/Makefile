CC ?= aarch64-linux-gnu-gcc
CFLAGS ?= -O2 -Wall -Wextra
BIN = fpc-tac

$(BIN): fpc-tac.c qseecom-fpc.h
	$(CC) $(CFLAGS) -o $@ fpc-tac.c

# qseecom-fpc.h é a cópia da UAPI do kernel (mesma ABI dos ioctls).
qseecom-fpc.h: ../kernel/src/include/uapi/misc/qseecom-fpc.h
	cp $< $@

clean:
	rm -f $(BIN)

.PHONY: clean
