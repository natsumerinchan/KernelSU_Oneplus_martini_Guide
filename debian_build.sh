#! /bin/bash

set -eux

export KERNEL_PATH=$PWD
export CLANG_PATH=~/toolchains/proton-clang
export PATH=${CLANG_PATH}/bin:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
export SUBARCH=arm64
export KERNEL_DEFCONFIG=vendor/lahaina-qgki_defconfig
export LLVM_VERSION=13
export SETUP_KERNELSU=true  # Enable if you want KernelSU
export KernelSU_TAG=main    # Select KernelSU tag or branch
# Custom Keystore hash and size for KernelSU Manager
# Use `ksud debug get-sign <apk_path>` to get them
if [ "${1-}" == "custom" ] || [ "${2-}" == "custom" ]; then
    export KSU_EXPECTED_SIZE=0x352
    export KSU_EXPECTED_HASH=f29d8d0129230b6d09edeec28c6b17ab13d842da73b0bc7552feb81090f9b09e
else
    unset KSU_EXPECTED_SIZE
    unset KSU_EXPECTED_HASH
fi

if [ "${1-}" == "clean" ] || [ "${2-}" == "clean" ]; then
    test -d ~/.ccache && rm -rf ~/.ccache
    test -d ~/.cache/ccache && rm -rf ~/.cache/ccache
    test -d "$KERNEL_PATH/out" && rm -rf "$KERNEL_PATH/out"
fi

update_kernel() {
    cd $KERNEL_PATH
    git stash
    git pull
}

setup_environment() {
    cd $KERNEL_PATH
    sudo apt update
    sudo apt install zstd tar wget curl libarchive-tools
    if [ ! -d $CLANG_PATH ]; then
      mkdir -p $CLANG_PATH
      git clone --depth=1 https://github.com/kdrag0n/proton-clang $CLANG_PATH
    fi
    chmod +x llvm.sh
    sudo ./llvm.sh $LLVM_VERSION
    rm ./llvm.sh
    sudo apt install --fix-missing
    sudo ln -s --force /usr/bin/clang-$LLVM_VERSION /usr/bin/clang
    sudo ln -s --force /usr/bin/ld.lld-$LLVM_VERSION /usr/bin/ld.lld
    sudo ln -s --force /usr/bin/llvm-objdump-$LLVM_VERSION /usr/bin/llvm-objdump
    sudo ln -s --force /usr/bin/llvm-ar-$LLVM_VERSION /usr/bin/llvm-ar
    sudo ln -s --force /usr/bin/llvm-nm-$LLVM_VERSION /usr/bin/llvm-nm
    sudo ln -s --force /usr/bin/llvm-strip-$LLVM_VERSION /usr/bin/llvm-strip
    sudo ln -s --force /usr/bin/llvm-objcopy-$LLVM_VERSION /usr/bin/llvm-objcopy
    sudo ln -s --force /usr/bin/llvm-readelf-$LLVM_VERSION /usr/bin/llvm-readelf
    sudo ln -s --force /usr/bin/clang++-$LLVM_VERSION /usr/bin/clang++
}

setup_kernelsu() {
    cd $KERNEL_PATH
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s $KernelSU_TAG
    # Enable KPROBES
    scripts/config --file "arch/$ARCH/configs/$KERNEL_DEFCONFIG" -e MODULES -e KPROBES -e HAVE_KPROBES -e KPROBE_EVENTS
}

unsetup_kernelsu() {
    cd $KERNEL_PATH
    test -e "$KERNEL_PATH/drivers/kernelsu" && rm "$KERNEL_PATH/drivers/kernelsu"
    grep -q "kernelsu" "$KERNEL_PATH/drivers/Makefile" && sed -i '/kernelsu/d' "$KERNEL_PATH/drivers/Makefile"
    grep -q "kernelsu" "$KERNEL_PATH/drivers/Kconfig" && sed -i '/kernelsu/d' "$KERNEL_PATH/drivers/Kconfig"
}

build_kernel() {
    cd $KERNEL_PATH
    make O=out CC="ccache clang" CXX="ccache clang++" ARCH=arm64 CROSS_COMPILE=$CLANG_PATH/bin/aarch64-linux-gnu- CROSS_COMPILE_ARM32=$CLANG_PATH/bin/arm-linux-gnueabi- LD=ld.lld $KERNEL_DEFCONFIG
    # Disable LTO
    if [[ $(echo "$(awk '/MemTotal/ {print $2}' /proc/meminfo) < 16000000" | bc -l) -eq 1 ]]; then
        scripts/config --file out/.config -d LTO -d LTO_CLANG -d THINLTO -e LTO_NONE
    fi
    # Delete old files
    test -d $KERNEL_PATH/out/arch/arm64/boot && rm -rf $KERNEL_PATH/out/arch/arm64/boot/*
    # Begin compile
    time make O=out CC="ccache clang" CXX="ccache clang++" ARCH=arm64 -j`nproc` CROSS_COMPILE=$CLANG_PATH/bin/aarch64-linux-gnu- CROSS_COMPILE_ARM32=$CLANG_PATH/bin/arm-linux-gnueabi- LD=ld.lld 2>&1 | tee kernel.log
}

make_anykernel3_zip() {
    cd $KERNEL_PATH
    test -d $KERNEL_PATH/AnyKernel3 && rm -rf $KERNEL_PATH/AnyKernel3
    git clone https://gitlab.com/inferno0230/AnyKernel3 --depth=1 $KERNEL_PATH/AnyKernel3
    if test -e $KERNEL_PATH/out/arch/arm64/boot/Image && test -d $KERNEL_PATH/AnyKernel3; then
       zip_name="ONEPLUS9RT-v5.4.$(grep "^SUBLEVEL =" Makefile | awk '{print $3}')-$(date +"%Y%m%d").zip"
       cd $KERNEL_PATH/AnyKernel3
       cp $KERNEL_PATH/out/arch/arm64/boot/Image $KERNEL_PATH/AnyKernel3
       zip -r ${zip_name} *
       mv ${zip_name} $KERNEL_PATH/out/arch/arm64/boot
       cd $KERNEL_PATH
    fi
}

clear

# update_kernel   //Please uncomment if you need it

if test -e $CLANG_PATH/env_is_setup; then
   echo [INFO]Environment have been setup!
else
   setup_environment
   touch $CLANG_PATH/env_is_setup
fi

if test "$SETUP_KERNELSU" == "true"; then
   setup_kernelsu
else
   echo [INFO] KernelSU will not be Compiled
   unsetup_kernelsu
fi

build_kernel

make_anykernel3_zip
cd $KERNEL_PATH
echo [INFO] Products are put in $KERNEL_PATH/out/arch/arm64/boot
echo [INFO] Done.
