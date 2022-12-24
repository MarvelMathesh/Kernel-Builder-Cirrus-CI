#!/bin/bash

# cd To An Absolute Path
cd /tmp/rom

# clone kernel tree
git clone $KT_LINK -b $KT_BRANCH --depth=1 --single-branch
cd *

# Compile
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 10G
ccache -o compression=true
ccache -z

export ROOT=$(pwd)
export ZIPNAME=M23-Kernel-Mrsiri-$(date +"%F")
export MAKE_FLAGS=(
        CROSS_COMPILE=aarch64-elf-
        CROSS_COMPILE_ARM32=arm-eabi-
        )
JOBS=$(nproc --all)

export KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

function clone() {
    if ! [ -a AnyKernel3 ]; then
        git clone --depth=1 https://github.com/MarvelMathesh/AnyKernel3 -b land AnyKernel3
    fi
    if ! [ -a clang ]; then
        git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 -b android12-release
    fi
    if ! [ -a clang ]; then
        git clone --depth=1 https://github.com/physwizz/compiler -b main compiler
    fi
}

function compile() {
    if [ -a out ]; then
        rm -rf out
    fi
    export ARCH=arm64
    export ANDROID_MAJOR_VERSION=r
    export KERNEL_LLVM_BIN=$(pwd)/linux-x86/clang-r416183b/bin/
    export CROSS_COMPILE=$(pwd)/compiler/bin/aarch64-linux-android-
    make -C $(pwd) O=out $KERNEL_MAKE_ENV REAL_CC=$KERNEL_LLVM_BIN KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y vendor/m23xq_eur_open_defconfig -j"$JOBS" \
        "${MAKE_FLAGS[@]}"
    make -C $(pwd) O=out $KERNEL_MAKE_ENV REAL_CC=$KERNEL_LLVM_BIN KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j"$JOBS" \
        "${MAKE_FLAGS[@]}"
}

function repack() {
    if ! [ -a AnyKernel3/Image.gz-dtb ]; then
        cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    fi
    cd AnyKernel3
    if [ -a "${ZIPNAME}".zip ]; then
        rm -rf "${ZIPNAME}".zip
    fi
    zip -r9 "${ZIPNAME}".zip ./* -x .git README.md ./*placeholder zipsigner-3.0.jar
    if [ -a Image.gz-dtb ]; then
        rm -rf Image.gz-dtb
    fi
    if [ -a "${ZIPNAME}"-signed.zip ]; then
        rm -rf "${ZIPNAME}"-signed.zip
    fi
    java -jar zipsigner-3.0.jar "${ZIPNAME}".zip "${ZIPNAME}"-signed.zip
    cd "$ROOT"
}

clone
compile
repack

cd AnyKernel3
export kernel=$(ls *.zip)
