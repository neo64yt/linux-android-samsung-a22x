#!/bin/bash

# install requirements first
# https://github.com/ravindu644/Android-Kernel-Tutorials#-install-required-dependencies-for-compiling-kernels

echo -e "\n[INFO]: BUILD STARTED..!\n"

#init submodules
git submodule init && git submodule update

export KERNEL_ROOT="$(pwd)"
export ARCH=arm64
export KBUILD_BUILD_USER="@ravindu644"

mkdir -p "${KERNEL_ROOT}/out" "${KERNEL_ROOT}/build" "${HOME}/toolchains"

# init clang-r383902b
if [ ! -d "${HOME}/toolchains/clang-r383902b" ]; then
    echo -e "\n[INFO] Cloning clang-r383902b...\n"
    mkdir -p "${HOME}/toolchains/clang-r383902b" && cd "${HOME}/toolchains/clang-r383902b"
    curl -LO "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0e9e7035bf8ad42437c6156e5950eab13655b26c/clang-r383902b.tar.gz"
    tar -xf clang-r383902b.tar.gz && rm clang-r383902b.tar.gz
    cd "${KERNEL_ROOT}"
fi

# init arm gnu toolchain
if [ ! -d "${HOME}/toolchains/gcc" ]; then
    echo -e "\n[INFO] Cloning ARM GNU Toolchain\n"
    mkdir -p "${HOME}/toolchains/gcc" && cd "${HOME}/toolchains/gcc"
    curl -LO "https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
    tar -xf arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
    cd "${KERNEL_ROOT}"
fi

# Export toolchain paths
export PATH="${HOME}/toolchains/clang-r383902b/bin:${PATH}"
export LD_LIBRARY_PATH="${HOME}/clang-r383902b/lib:${HOME}/clang-r383902b/lib64:${LD_LIBRARY_PATH}"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE="${HOME}/toolchains/gcc/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
export BUILD_CC="${HOME}/toolchains/clang-r383902b/bin/clang"

# From the OEM build script
export ANDROID_MAJOR_VERSION=r
export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Build options for the kernel
export BUILD_OPTIONS=(
    HOSTLDLIBS="-lyaml"
    KCFLAGS=-w
    CONFIG_SECTION_MISMATCH_WARN_ONLY=y
    -C "${KERNEL_ROOT}"
    O="${KERNEL_ROOT}/out"
    -j"$(nproc)"
    ARCH=arm64
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}"
    CC="${BUILD_CC}"
    CLANG_TRIPLE=aarch64-linux-gnu-
)

build_kernel(){
    # Make default configuration.
    # Replace 'your_defconfig' with the name of your kernel's defconfig
    make "${BUILD_OPTIONS[@]}" a22x_defconfig custom.config

    # Configure the kernel (GUI)
    make "${BUILD_OPTIONS[@]}" nconfig

    # Build the kernel
    make "${BUILD_OPTIONS[@]}" Image || exit 1

    # Copy the built kernel to the build directory
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image" "${KERNEL_ROOT}/build"

    echo -e "\n[INFO]: BUILD FINISHED..!"
}
build_kernel
