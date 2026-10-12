# Build environment for the J7 Prime (on7xelte) NetHunter kernel.
# Ubuntu 20.04 is used on purpose: its OpenSSL 1.1 and GCC 9 match the old
# 3.18 Samsung kernel far better than newer releases (OpenSSL 3.0 breaks the
# 3.18 module-signing/cert tooling). The cross toolchain is ARM's own GNU 9.2,
# the version the KRAKEN build script targets.
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        bc bison flex \
        libssl-dev libncurses5-dev \
        build-essential cpio kmod ccache \
        zip unzip \
        git wget curl ca-certificates xz-utils \
        python-is-python3 python3 \
    && rm -rf /var/lib/apt/lists/*

# ARM GNU toolchain 9.2-2019.12 (aarch64 for the kernel, arm32 eabi for VDSO/etc).
ARG TC_BASE=https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel
RUN mkdir -p /opt/toolchains && cd /opt/toolchains \
    && wget -q "$TC_BASE/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz" \
    && wget -q "$TC_BASE/gcc-arm-9.2-2019.12-x86_64-arm-none-eabi.tar.xz" \
    && tar xf gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz \
    && tar xf gcc-arm-9.2-2019.12-x86_64-arm-none-eabi.tar.xz \
    && rm -f ./*.tar.xz

ENV CROSS_COMPILE=/opt/toolchains/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
ENV CROSS_COMPILE_ARM32=/opt/toolchains/gcc-arm-9.2-2019.12-x86_64-arm-none-eabi/bin/arm-none-eabi-

COPY build-kernel.sh /usr/local/bin/build-kernel.sh
RUN chmod +x /usr/local/bin/build-kernel.sh

# Kernel source is bind-mounted here at run time; nothing is baked into the image.
WORKDIR /kernel
ENTRYPOINT ["/usr/local/bin/build-kernel.sh"]
