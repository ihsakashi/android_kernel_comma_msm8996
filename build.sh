#!/bin/bash
#
# Kernel Build Script v1.0
#
# Copyright (C) 2017 Michele Beccalossi <beccalossi.michele@gmail.com>
#               2021 Yuvraj Chohan <yuvch122@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

export ARCH=arm64
export BUILD_JOB_NUMBER=$(grep processor /proc/cpuinfo | wc -l)
export BUILD_CROSS_COMPILE=/home/builder/toolchains/gcc-arm-8.2-2018.08-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu-

FUNC_CLEAN_ENVIRONMENT()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "START : FUNC_CLEAN_ENVIRONMENT"
	echo "=================================================================="
	echo ""

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			mrproper || exit -1
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			distclean || exit -1

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_CLEAN_ENVIRONMENT"
	echo "=================================================================="
	echo ""

	exit 1
}

FUNC_CUSTOM_CLEAN()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "START : FUNC_CUSTOM_CLEAN"
	echo "=================================================================="
	echo ""

	echo "◊ Deleting log files..."
	rm -f cfp_log.txt
	rm -f build_kernel.log
	echo ""
	echo "◊ Deleting all the previous builds..."
	rm -rf out/*.zip
	echo ""
	echo "◊ Cleaning build folder..."
	rm -f build/ak2/dtb
	rm -f build/ak2/Image.gz-dtb
	rm -f build/ak2/.version
	echo ""
	echo "◊ Deleting patch related leftovers..."
	rm -rf *.patch
	rm -rf *.diff
	find . -name "*.orig" -delete
	find . -name "*.rej" -delete

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_CUSTOM_CLEAN"
	echo "=================================================================="
	echo ""

	exit 1
}

FUNC_UNKNOWN_INPUT()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "ERROR : UNKNOWN_INPUT"
	echo "=================================================================="
	echo ""
	echo "Usage: ./build_kernel.sh [option]"
	echo ""
	echo "Currently available options are:"
	echo ""
	echo "1 - to build kernel"
	echo ""
	echo "9 - to run the custom cleaning routine"
	echo "0 - to clean the build environment"
	echo ""
	echo "=================================================================="
	echo "ERROR : UNKNOWN_INPUT"
	echo "=================================================================="
	echo ""

	exit 1
}

if [ $1 == 0 ]; then
	FUNC_CLEAN_ENVIRONMENT
elif [ $1 == 9 ]; then
	FUNC_CUSTOM_CLEAN
elif [ $1 == 1 ]; then
	continue
else
	FUNC_UNKNOWN_INPUT
fi

KERNEL_NAME=comma_kernel
KERNEL_DEFCONFIG=comma_defconfig

PAGE_SIZE=4096
DTB_PADDING=0

RDIR=$(pwd)
OUTDIR=$RDIR/out/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
INCDIR=$RDIR/include
ZIPDIR=$RDIR/build/ak2
EXTDIR=$RDIR/out

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=================================================================="
	echo ""
	echo "◊ Build defconfig:	$KERNEL_DEFCONFIG"

	echo ""
	echo "◊ Generating kernel config..."
	echo ""
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	echo ""
	echo "◊ Building kernel..."
	echo ""
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "=================================================================="
	echo ""
}

FUNC_BUILD_ZIP()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_BUILD_ZIP"
	echo "=================================================================="
	echo ""

	cp $OUTDIR/Image.gz-dtb $ZIPDIR/Image.gz-dtb

	VERSION=$(grep -Po -m 1 '(?<=VERSION = ).*' $RDIR/Makefile)
	PATCHLEVEL=$(grep -Po -m 1 '(?<=PATCHLEVEL = ).*' $RDIR/Makefile)
	SUBLEVEL=$(grep -Po -m 1 '(?<=SUBLEVEL = ).*' $RDIR/Makefile)
	echo "linux.version=$VERSION.$PATCHLEVEL.$SUBLEVEL" >> $ZIPDIR/.version

	if ! [ -d $EXTDIR ]; then
		mkdir $EXTDIR
	fi
	cd $ZIPDIR
	echo "=> Output: $EXTDIR/${KERNEL_NAME}.zip"
	echo ""
	zip -r9 $EXTDIR/${KERNEL_NAME}.zip * .version -x modules/\*

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_BUILD_ZIP"
	echo "=================================================================="
	echo ""
}

# MAIN FUNCTION
rm -rf ./build_kernel.log
(
	tput reset

	START_TIME=$(date +%s)
	START_COMPILE=$(date +%s)
	FUNC_BUILD_KERNEL
	END_COMPILE=$(date +%s)
	FUNC_BUILD_ZIP
	END_TIME=$(date +%s)

	let "COMPILE_TIME=$END_COMPILE-$START_COMPILE"
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "◊ Total kernel compile time was $COMPILE_TIME seconds."
	echo "◊ Total build time was $ELAPSED_TIME seconds."
	echo ""
) 2>&1 | tee -a ./build_kernel.log
sed -i '1s/.*//' ./build_kernel.log