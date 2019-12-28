#!/bin/bash -e

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
EXTLINUXPATH=${LOCALPATH}/build/extlinux
TOOLPATH=${LOCALPATH}/rkbin/tools

PATH=$PATH:$TOOLPATH

finish() {
	echo -e "\e[31m MAKE SOURCE IMAGE FAILED.\e[0m"
	exit -1
}

trap finish ERR

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/u-boot ] && mkdir ${OUT}/u-boot

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

if [ $? -ne 0 ]; then
	exit
fi

cd ${LOCALPATH}/u-boot
# make clean
# make distclean
# make mrproper
make orangepi-rk3399_defconfig all

$TOOLPATH/loaderimage --pack --uboot ./u-boot-dtb.bin uboot.img 0x200000

tools/mkimage -n rk3399 -T rksd -d ../rkbin/rk33/rk3399_ddr_800MHz_v1.08.bin idbloader.img
cat ../rkbin/rk33/rk3399_miniloader_v1.06.bin >> idbloader.img
cp idbloader.img ${OUT}/u-boot/
cp ../rkbin/rk33/rk3399_loader_v1.08.106.bin ${OUT}/u-boot/

cat >trust.ini <<EOF
[VERSION]
MAJOR=1
MINOR=0
[BL30_OPTION]
SEC=0
[BL31_OPTION]
SEC=1
PATH=../rkbin/rk33/rk3399_bl31_v1.00.elf
ADDR=0x10000
[BL32_OPTION]
SEC=0
[BL33_OPTION]
SEC=0
[OUTPUT]
PATH=trust.img
EOF

$TOOLPATH/trust_merger trust.ini

cp uboot.img ${OUT}/u-boot/
mv trust.img ${OUT}/u-boot/

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/kernel ] && mkdir ${OUT}/kernel

cd ${LOCALPATH}/kernel
# make clean
# make distclean
# make mrproper
make rk3399_linux_defconfig
make -j8 rk3399-orangepi.img
# make -j8 modules
# sudo make INSTALL_MOD_PATH=~/RK3399/rootfs modules_install
cd ${LOCALPATH}

KERNEL_VERSION=$(cat ${LOCALPATH}/kernel/include/config/kernel.release)

cp ${LOCALPATH}/kernel/arch/arm64/boot/Image ${OUT}/kernel/
cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/rk3399-orangepi.dtb ${OUT}/kernel/

sed -e "s,fdt .*,fdt /rk3399-orangepi.dtb,g" -i ${EXTLINUXPATH}/rk3399.conf

./build/mk-image.sh -c rk3399 -t boot

echo -e "\e[36m Source Build Success! \e[0m"
