#!/bin/bash

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out

if [ -f "ubuntu.img" ]; then
    rm ubuntu.img
fi

if [ -f "${OUT}/boot.img" ]; then
    rm out/system.img
fi

# ./build/mk-kernel.sh

dd if=/dev/zero of=ubuntu.img bs=1M count=2048
sudo mkfs.ext4 ubuntu.img
rm -rf ubuntu
mkdir ubuntu
sudo mount ubuntu.img ubuntu/
sudo cp -rfp rootfs/* ubuntu/
sudo umount ubuntu/
e2fsck -p -f ubuntu.img
resize2fs -M ubuntu.img
./build/mk-image.sh
./build/mk-flash.sh

