#!/bin/bash -e

LOCALPATH=$(pwd)
TOOLPATH=${LOCALPATH}/rkbin/tools

PATH=$PATH:$TOOLPATH

finish() {
	echo -e "\e[31m FLASH IMAGE FAILED.\e[0m"
	exit -1
}

trap finish ERR

sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/rkbin/rk33/rk3399_loader_*.bin
sleep 1
sudo $TOOLPATH/rkdeveloptool wl 0 out/system.img
sudo $TOOLPATH/rkdeveloptool rd

echo -e "\e[36m Flash Success! \e[0m"