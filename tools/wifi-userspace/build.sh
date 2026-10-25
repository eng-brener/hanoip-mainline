#!/bin/sh
# Static musl builds of qrtr (lib + tools), rmtfs, tqftpserv, pd-mapper.
set -e
W=/tmp/wifi-build; S=$W/shim; CC="/tmp/usbnet-build/musl/bin/musl-gcc -static"
K=$W/kinc; rm -rf $K; mkdir -p $K
cp -r /usr/include/linux /usr/include/asm-generic $K/
cp -r /usr/include/aarch64-linux-gnu/asm $K/asm
CF="-O2 -Wall -D_GNU_SOURCE -idirafter $K -I$W/qrtr/include"
mkdir -p $W/out; cd $W/qrtr
$CC $CF -c lib/logging.c lib/qmi.c lib/qrtr.c
ar rcs $W/out/libqrtr.a logging.o qmi.o qrtr.o
$CC $CF -o $W/out/qrtr-lookup src/lookup.c $W/out/libqrtr.a
cd $W/rmtfs
$CC $CF -I$S -o $W/out/rmtfs qmi_rmtfs.c qmi_tlv.c rmtfs.c rproc.c sharedmem.c storage.c util.c $S/udev-shim.c $W/out/libqrtr.a -lpthread
cd $W/tqftpserv
$CC $CF -o $W/out/tqftpserv tqftpserv.c translate.c $W/out/libqrtr.a
cd $W/pd-mapper
$CC $CF -I$S -o $W/out/pd-mapper assoc.c json.c pd-mapper.c servreg_loc.c $S/lzma-stub.c $W/out/libqrtr.a
ls -la $W/out
for f in $W/out/qrtr-lookup $W/out/rmtfs $W/out/tqftpserv $W/out/pd-mapper; do readelf -h $f | grep -q EXEC && ! readelf -l $f | grep -q interp && echo "static ok ${f##*/}"; done
