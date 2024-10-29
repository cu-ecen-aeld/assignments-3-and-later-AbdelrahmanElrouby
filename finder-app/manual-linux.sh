#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

# OUTDIR=/tmp/aeld
OUTDIR=$HOME
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
# FINDER_APP_DIR=$(realpath $(dirname $0))
FINDER_APP_DIR="/home/abdelrahman/assignment-1-AbdelrahmanElrouby/finder-app"
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(realpath $(${CROSS_COMPILE}gcc -print-sysroot))

# echo "Using default directory ${OUTDIR} for output"
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
    sudo git apply ~/e33a814e772cdc36436c8c188d8c42d019fda639.patch
    # TODO: Add your kernel build steps here


    # Cleaning the kernel build tree and removing .config file
    make ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        mrproper

    # Setup the new .config file for our virt arm dev board
    make ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        defconfig 

    # Building the kernel image
    make -j4 ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        all 
    
    # Building the device tree
    make ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        dtbs

fi


echo "Adding the Image in outdir"

sudo cp -p ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}/Image

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ] ;then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

# Creating the root filesystem directory
mkdir -p rootfs && cd rootfs/

# Creating base directories
mkdir -p bin dev usr var temp home etc proc sys lib lib64 sbin
mkdir -p usr/bin usr/sbin
mkdir -p var/log 

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ];then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox

    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox

make ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} 

make CONFIG_PREFIX=${OUTDIR}/rootfs \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    install

sudo chmod u+s busybox

echo "Library dependencies"
program_interpreter=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter" | \
    awk -F': ' '{print $2}' | tr -d '[]')
shared_libraries=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | \
    awk -F': ' '{print $2}' | tr -d '[]')
# TODO: Add library dependencies to rootfs
sudo cp ${SYSROOT}${program_interpreter} ${OUTDIR}/rootfs/lib

for library in ${shared_libraries}; do
    sudo cp ${SYSROOT}/lib64/"$library" "$OUTDIR/rootfs/lib64/"
done

# sudo cp ${SYSROOT}/lib64/${shared_libraries} ${OUTDIR}/rootfs/lib64
# Copy the program interpreter
# if [ -n "$program_interpreter" ]; then
#     sudo cp "$program_interpreter" "$OUTDIR/rootfs/lib64/"
# else
#     echo "No program interpreter found."
# fi

# # Copy each shared library individually
# if [ -n "$shared_libraries" ]; then
#     for library in $shared_libraries; do
#         sudo cp "$library" "$OUTDIR/rootfs/lib64/"
#     done
# else
#     echo "No shared libraries found."
# fi

# TODO: Make device nodes

# Make a Null device 
sudo rm -f ${OUTDIR}/rootfs/dev/null && sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3 

# Make a Console device 
sudo rm -f ${OUTDIR}/rootfs/dev/console && sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1 

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE} all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

mkdir -p ${OUTDIR}/rootfs/home/conf
sudo cp -r conf/* ${OUTDIR}/rootfs/home/conf
sudo cp writer.sh finder.sh writer \
    finder-test.sh autorun-qemu.sh  ${OUTDIR}/rootfs/home/


# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

echo "Creating initramfs.cpio.gz"
# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
