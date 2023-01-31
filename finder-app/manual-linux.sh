#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
export CROSS_COMPILE=aarch64-none-linux-gnu-
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
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
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
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
else
    cp -fr ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
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
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd ${OUTDIR}/rootfs
echo "Current Directory: ${PWD}"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
export SYSROOT=$(aarch64-none-linux-gnu-gcc -print-sysroot)
cd ${OUTDIR}/rootfs
cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 lib
cp -a ${SYSROOT}/lib64/ld-2.31.so lib
cp -a ${SYSROOT}/lib64/libm.so.6 lib
cp -a ${SYSROOT}/lib64/libm-2.31.so lib
cp -a ${SYSROOT}/lib64/libresolv.so.2 lib
cp -a ${SYSROOT}/lib64/libresolv-2.31.so lib
cp -a ${SYSROOT}/lib64/libc.so.6 lib
cp -a ${SYSROOT}/lib64/libc-2.31.so lib

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1


# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} DESTDIR=${OUTDIR}/rootfs

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp autorun-qemu.sh ${OUTDIR}/rootfs/home/
sudo cp finder-test.sh ${OUTDIR}/rootfs/home/
sudo cp writer ${OUTDIR}/rootfs/home/

cd ${OUTDIR}/rootfs

# TODO: Chown the root directory
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
# gzip initramfs.cpio

