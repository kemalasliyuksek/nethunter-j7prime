# nethunter-j7prime

A from-scratch, fully-supported **Kali NetHunter** port for the Samsung Galaxy
J7 Prime (SM-G610F, `on7xelte`, Exynos 7870).

> Status: early development. Phase 1 (research / feasibility) complete; building the
> toolchain and custom kernel next. Nothing is flashed to a device until the kernel
> builds and a full backup exists.

## Why

Turn a retired phone into a practical, fully-owned security-research and learning
device: a platform for mobile app reverse engineering, request/response analysis, and
authorized hacking of the owner's own devices. This is a personal hobby and learning
project, not a brand product.

## Target device

- Model **SM-G610F**, codename `on7xelte`, SoC Exynos 7870 (ARM64, 8x Cortex-A53), 3 GB RAM.
- Stock: Android 8.1.0, kernel 3.18.14. Already rooted (Magisk), Knox tripped, OEM unlock allowed.
- External Wi-Fi: Alfa AWUS036NH (Ralink RT3070, `rt2800usb`, monitor mode + injection, 2.4 GHz).

## Approach & decisions

- **Base: Android 9 Pie (OneUI).** Chosen for hardware stability and because it is the
  primary target of the NetHunter kernel we build on. The Android 11 Treble route was
  dropped (unstable mic/camera on GSI for this device).
- **Kernel: fork of `Thiviyan/KRAKEN_7870_Nethunter`.** Its build script already targets
  the G610 family (`on7xelteswa_defconfig`, DTS `exynos7870-on7xelte`). The upstream
  project is marked dead; we fork it, build and verify on the G610F, fix device-specific
  issues, keep it alive, and aim to upstream to the Kali NetHunter project.
- **Wi-Fi injection via the external AWUS036NH.** This sidesteps the uncertain internal
  BCM4343 radio (no known nexmon port); the `rt2800` driver is already in the kernel.
- **Flashing with Heimdall** (not Odin), via download mode.

## Roadmap

1. Research / feasibility — **done**. See [docs/RESEARCH.md](docs/RESEARCH.md).
2. Build environment (Docker) + aarch64 toolchain; fork & clone KRAKEN.
3. Build the kernel with `on7xelteswa_defconfig` (no device flashing yet).
4. Stock Pie firmware backup + TWRP + full backup, then flash.
5. NetHunter chroot + app suite + feature tests (HID, AWUS036NH injection, etc.).
6. Mature and upstream to the Kali NetHunter project.

Principle: **build first, flash last.** The device is not touched until the kernel is ready.

## License

The NetHunter kernel is a derivative of the Linux kernel, so that component **must be
GPLv2**. The license of this management repository is to be decided. Copyright: Kemal
Aslıyüksek.

## Disclaimer

For authorized security testing and education on hardware and systems you own or have
explicit permission to test. You are responsible for how you use it. Flashing custom
firmware trips the Knox warranty bit and can brick a device; proceed at your own risk.

Türkçe sürüm: [README.tr.md](README.tr.md).
