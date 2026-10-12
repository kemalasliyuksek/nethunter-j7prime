#!/usr/bin/env bash
#
# Non-interactive NetHunter kernel build for the Samsung Galaxy J7 Prime
# (SM-G610F / SM-G610X, codename on7xelte), OneUI (Android 9 Pie) base.
#
# Reproduces the SM-G610X / OneUI path of KRAKEN's interactive cronos9.sh
# without the menu, so it can run in CI / a container. The kernel source is
# bind-mounted at /kernel (the working directory).
#
# Produces a flashable boot.img at KRAKEN/Out/.
set -euo pipefail

CONFIGS="arch/arm64/configs"
DEVICE_DEFCONFIG="on7xelteswa_defconfig" # SM-G610X (on7xelte)
BASE_DEFCONFIG="oneui_defconfig"         # OneUI / Pie USB + base
NETHUNTER_DEFCONFIG="KRAKEN_defconfig"   # NetHunter feature set
MERGED_DEFCONFIG="tmp_defconfig"

# boot.img packaging (OneUI / Pie path)
AIK="KRAKEN/A.I.K"     # Android Image Kitchen
RAMDISK="KRAKEN/Oneui" # OneUI ramdisk + split_img template
DTS_DIR="arch/arm64/boot/dts"
ONEUI_DTSI="arch/arm64/boot/exynos7870_Oneui.dtsi"
OUT_DIR="KRAKEN/Out"
IMAGE_NAME="S133PY-N18-Nethunter-on7xelte-oneui"

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
# that are missing (Kconfig source line + any Makefile obj entry, which for
# rtl8192eu is an unconditional obj-y) so the tree configures and builds. Our
# target adapter (Alfa AWUS036NH, RT3070) uses the in-tree rt2800usb driver.
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

# The build generates DTBs from arch/arm64/boot/dts/exynos7870.dtsi, which
# cronos9.sh swaps per variant. For OneUI, mount the OneUI dtsi.
echo "==> Selecting OneUI device tree"
cp "${ONEUI_DTSI}" "${DTS_DIR}/exynos7870.dtsi"

echo "==> make ${MERGED_DEFCONFIG}"
make "${MERGED_DEFCONFIG}"

echo "==> make Image + dtbs (-j${JOBS})"
make -j"${JOBS}" Image dtbs

if [ ! -f arch/arm64/boot/Image ]; then
	echo "==> FAILED: Image not produced" >&2
	exit 1
fi
echo "    Image: $(du -h arch/arm64/boot/Image | cut -f1)"

echo "==> Building boot.img-dtb (dtbTool)"
./scripts/dtbTool/dtbTool -o boot.img-dtb -d "${DTS_DIR}/" -s 2048

echo "==> Packing boot.img (Android Image Kitchen, OneUI ramdisk)"
cp -rf "${RAMDISK}"/* "${AIK}/"
cp arch/arm64/boot/Image "${AIK}/split_img/boot.img-zImage"
cp boot.img-dtb "${AIK}/split_img/boot.img-dtb"
(cd "${AIK}" && ./repackimg.sh)
# Append SEANDROIDENFORCE so the device does not show the red custom-kernel warning.
printf 'SEANDROIDENFORCE' >>"${AIK}/image-new.img"

mkdir -p "${OUT_DIR}"
cp "${AIK}/image-new.img" "${OUT_DIR}/${IMAGE_NAME}.img"

if [ -f "${OUT_DIR}/${IMAGE_NAME}.img" ]; then
	echo "==> SUCCESS: ${OUT_DIR}/${IMAGE_NAME}.img ($(du -h "${OUT_DIR}/${IMAGE_NAME}.img" | cut -f1))"
else
	echo "==> FAILED: boot.img not produced" >&2
	exit 1
fi
