#!/usr/bin/env bash
#
# Non-interactive NetHunter kernel build for the Samsung Galaxy J7 Prime
# (SM-G610F / SM-G610X, codename on7xelte), OneUI (Android 9 Pie) base.
#
# This reproduces the SM-G610X / OneUI path of KRAKEN's interactive cronos9.sh
# without the menu, so it can run in CI / a container. The kernel source is
# expected to be bind-mounted at /kernel (the working directory).
#
# Stage 1 goal: produce arch/arm64/boot/Image. DTB and boot.img packaging come later.
set -euo pipefail

CONFIGS="arch/arm64/configs"
DEVICE_DEFCONFIG="on7xelteswa_defconfig" # SM-G610X (on7xelte)
BASE_DEFCONFIG="oneui_defconfig"         # OneUI / Pie USB + base
NETHUNTER_DEFCONFIG="KRAKEN_defconfig"   # NetHunter feature set
MERGED_DEFCONFIG="tmp_defconfig"

export ARCH=arm64
export ANDROID_MAJOR_VERSION=p
export PLATFORM_VERSION=9.0.0
JOBS="$(nproc)"

echo "==> Toolchain"
echo "    CROSS_COMPILE=${CROSS_COMPILE:-unset}"
echo "    CROSS_COMPILE_ARM32=${CROSS_COMPILE_ARM32:-unset}"
"${CROSS_COMPILE}gcc" --version | head -n1

echo "==> Merging defconfig: ${DEVICE_DEFCONFIG} + ${BASE_DEFCONFIG} + ${NETHUNTER_DEFCONFIG}"
cat "${CONFIGS}/${DEVICE_DEFCONFIG}" \
	"${CONFIGS}/${BASE_DEFCONFIG}" \
	"${CONFIGS}/${NETHUNTER_DEFCONFIG}" >"${CONFIGS}/${MERGED_DEFCONFIG}"

# Upstream KRAKEN references external Realtek drivers as gitlinks but ships no
# .gitmodules, so their sources are absent in a fresh clone. Disable the ones
# that are missing (both their Kconfig source line and any Makefile obj entry,
# which for rtl8192eu is an unconditional obj-y) so the tree configures and
# builds. Our target adapter (Alfa AWUS036NH, RT3070) uses the in-tree
# rt2800usb driver and is unaffected.
# TODO: vendor these drivers (aircrack-ng forks) to restore full adapter support.
echo "==> Disabling missing external Realtek drivers"
WL="drivers/net/wireless"
for d in rtl8812au rtl8192eu rtl8188eus; do
	if [ ! -f "${WL}/${d}/Kconfig" ]; then
		echo "    - ${d} (missing): disabling Kconfig + Makefile references"
		sed -i "s|^source \"${WL}/${d}/Kconfig\"|# &|" "${WL}/Kconfig"
		sed -i -E "s|^([[:space:]]*obj-[^=]*\+=[[:space:]]*${d}/)|# \1|" "${WL}/Makefile"
	fi
done
sed -i -E '/^CONFIG_(88XXAU|RTL8192EU|RTL8188EU)=/d' "${CONFIGS}/${MERGED_DEFCONFIG}"

echo "==> make ${MERGED_DEFCONFIG}"
make "${MERGED_DEFCONFIG}"

echo "==> make Image (-j${JOBS})"
make -j"${JOBS}" Image

if [ -f arch/arm64/boot/Image ]; then
	echo "==> SUCCESS: arch/arm64/boot/Image ($(du -h arch/arm64/boot/Image | cut -f1))"
else
	echo "==> FAILED: Image not produced" >&2
	exit 1
fi
