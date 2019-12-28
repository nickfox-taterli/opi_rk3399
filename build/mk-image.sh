#!/bin/bash -e

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
TOOLPATH=${LOCALPATH}/rkbin/tools
SIZE="4000"
ROOTFS_PATH="ubuntu.img"

PATH=$PATH:$TOOLPATH

LOADER1_SIZE=8000
RESERVED1_SIZE=128
RESERVED2_SIZE=8192
LOADER2_SIZE=8192
ATF_SIZE=8192
BOOT_SIZE=229376

LOADER1_START=64
RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

finish() {
	echo -e "\e[31m MAKE IMAGE FAILED.\e[0m"
	exit -1
}

trap finish ERR

SYSTEM=${OUT}/system.img
rm -rf ${SYSTEM}

dd if=/dev/zero of=${SYSTEM} bs=1M count=0 seek=$SIZE

parted -s ${SYSTEM} mklabel gpt
parted -s ${SYSTEM} unit s mkpart loader1 ${LOADER1_START} $(expr ${RESERVED1_START} - 1)
parted -s ${SYSTEM} unit s mkpart reserved1 ${RESERVED1_START} $(expr ${RESERVED2_START} - 1)
parted -s ${SYSTEM} unit s mkpart reserved2 ${RESERVED2_START} $(expr ${LOADER2_START} - 1)
parted -s ${SYSTEM} unit s mkpart loader2 ${LOADER2_START} $(expr ${ATF_START} - 1)
parted -s ${SYSTEM} unit s mkpart atf ${ATF_START} $(expr ${BOOT_START} - 1)
parted -s ${SYSTEM} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
parted -s ${SYSTEM} set 6 boot on
parted -s ${SYSTEM} unit s mkpart rootfs ${ROOTFS_START} 100%

ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"

gdisk ${SYSTEM} <<EOF
x
c
7
${ROOT_UUID}
w
y
EOF

dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${LOADER1_START} conv=notrunc

dd if=${OUT}/u-boot/uboot.img of=${SYSTEM} seek=${LOADER2_START} conv=notrunc
dd if=${OUT}/u-boot/trust.img of=${SYSTEM} seek=${ATF_START} conv=notrunc

dd if=${OUT}/boot.img of=${SYSTEM} conv=notrunc seek=${BOOT_START}

dd if=${ROOTFS_PATH} of=${SYSTEM} seek=${ROOTFS_START}

echo -e "\e[36m Image Build Success! \e[0m"