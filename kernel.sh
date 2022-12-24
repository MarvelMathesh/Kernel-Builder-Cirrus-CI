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

bash build-kernel.sh

cd AnyKernel3
export kernel=$(ls *.zip)
