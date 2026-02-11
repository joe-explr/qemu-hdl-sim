#!/bin/bash
#runs from scripts
echo "start build-qemus"
source sourceme.sh

cd $COSIM_REPO_HOME
# get acc.h and accelerator_pcie into this folder
echo "downloading qemu. Sometimes this fails and you need to start again multiple times"
wget https://download.qemu.org/qemu-10.1.3.tar.xz

echo "extracting qemu (1/2)"
tar -xJf qemu-10.1.3.tar.xz
mv qemu-10.1.3 qemu-10.1.3_orig

echo "extracting qemu (2/2)"
tar -xJf qemu-10.1.3.tar.xz

echo "patching qemu"
cd qemu-10.1.3
patch -p2 < ../qemu-10.1.3-cosim.patch

echo "building patched qemu"
mkdir build
cd build
../configure --target-list=x86_64-softmmu --enable-vnc --enable-sdl --enable-curses --enable-spice
make -j$nproc

echo "building original qemu"
cd $COSIM_REPO_HOME/qemu-10.1.3_orig
cd qemu-10.1.3_orig
mkdir build
cd build
../configure --target-list=x86_64-softmmu --enable-vnc --enable-sdl --enable-curses --enable-spice
make -j$nproc

cd $COSIM_REPO_HOME/scripts
echo "finish build-qemus"

