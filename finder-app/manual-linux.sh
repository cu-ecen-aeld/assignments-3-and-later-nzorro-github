#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.4.50
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm
CROSS_COMPILE=arm-unknown-linux-gnueabi-
export CROSS_COMPILE=arm-unknown-linux-gnueabi-
export PATH=$PATH:${HOME}/x-tools/arm-unknown-linux-gnueabi/bin 

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/zImage ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    #1 - build clean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    # make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
    #2 build defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # make -j 4 ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    #3 build vmlinuz
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} zImage

    cp -fr ${OUTDIR}/linux-stable/arch/${ARCH}/boot/zImage  ${OUTDIR}/zImage

else
    cp -fr ${OUTDIR}/linux-stable/arch/${ARCH}/boot/zImage  ${OUTDIR}/zImage
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
    sudo rm -fr ${OUTDIR}/initramfs.cpio.gz
fi

# TODO: Create necessary base directories
mkdir "${OUTDIR}"/rootfs
cd "${OUTDIR}"/rootfs
mkdir bin dev etc home lib proc sbin sys tmp usr var
mkdir usr/{bin,lib,sbin}
mkdir -p var/log

export CONFIG_PREFIX=${OUTDIR}/rootfs
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone https://github.com/mirror/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
    sed -i "s/\.\/\_install/\.\/\.\.\/rootfs/g" .config
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd ${OUTDIR}/rootfs
echo "Current Directory: ${PWD}"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
export SYSROOT=$(arm-unknown-linux-gnueabi-gcc -print-sysroot)
cd ${OUTDIR}/rootfs
cp -a ${SYSROOT}/lib/ld-linux.so.3 lib
cp -a ${SYSROOT}/lib/ld-2.29.so lib
cp -a ${SYSROOT}/lib/libm.so.6 lib
cp -a ${SYSROOT}/lib/libm-2.29.so lib
cp -a ${SYSROOT}/lib/libresolv.so.2 lib
cp -a ${SYSROOT}/lib/libresolv-2.29.so lib
cp -a ${SYSROOT}/lib/libc.so.6 lib
cp -a ${SYSROOT}/lib/libc-2.29.so lib

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1


# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
export CC=${CROSS_COMPILE}gcc
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp autorun-qemu.sh ${OUTDIR}/rootfs/home/
sudo cp finder-test.sh ${OUTDIR}/rootfs/home/
sudo cp finder.sh ${OUTDIR}/rootfs/home/
sudo cp writer ${OUTDIR}/rootfs/home/
sudo cp -a ../conf  ${OUTDIR}/rootfs/
sudo cp -a conf ${OUTDIR}/rootfs/home/

cd ${OUTDIR}/rootfs

# TODO: Chown the root directory
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip initramfs.cpio

