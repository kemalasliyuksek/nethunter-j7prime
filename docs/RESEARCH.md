# J7 Prime (SM-G610F) Kali NetHunter Port — Research Notes

Last updated: 2026-10-12

Goal: a from-scratch, fully-supported, open-source Kali NetHunter port for the Samsung
Galaxy J7 Prime (SM-G610F, `on7xelte`, Exynos 7870). Next phase: mobile app reverse
engineering, request/response analysis, authorized pentesting of the owner's own devices.

## Device facts (read from the device)

- Model SM-G610F, codename `on7xelte`, SoC Exynos 7870 (ARM64, 8x Cortex-A53), 3 GB RAM.
- Stock Android 8.1.0 (SDK 27), kernel 3.18.14, security patch 2020-04, build `G610FDDS1CTE4`, CSC TUR.
- Magisk 29.0 rooted, Zygisk on. Knox warranty bit = 1 (tripped). OEM unlock allowed.
- `/data` unencrypted. Internal Wi-Fi: Broadcom BCM4343 (bcmdhd). USB OTG, HIDRAW, UHID enabled.
- Stock kernel has no `f_hid` gadget; `TIMA_RKP`, `DEFEX`, `SEC_RESTRICT_*` enabled
  (to be disabled in our custom kernel).
- Flash path: Odin/Heimdall download mode (not fastboot). Heimdall not yet installed.

## Feasibility: doable, but no "download-and-flash" package exists

Verdict: **a fully-supported NetHunter is a realistic goal for this device.** The four
foundations are in place: a base ROM exists, a NetHunter kernel base for Exynos7870
exists, Samsung publishes the kernel source, and the bootloader is unlockable. But there
is no verified ready-made image for our exact model (G610F); the work is adapting the
existing pieces to our device, building, and testing. That is the project itself.

### 1. Base ROM — available (all unofficial)

- LineageOS 18.1 (Android 11) community build (XDA, "devotag"). NOT on the official LineageOS wiki.
- /e/OS R builds dated 2024-09 and 2024-10; users report "works fine".
- CerberusOS v1.8 (Pie / Android 9) for on7xelte.
- Android 11 AOSP-based Treble ROM (G610), "no bugs beyond soft reboots on rotation".
- Device tree repo: `github.com/samsungexynos7870/android_device_samsung_on7xelte` (crdroid branch, old, 35 commits).
- Warning: `j7elte` (J7 2015) and `j7xelte` (J7 2016) are DIFFERENT devices. Don't mix them up.

### 2. NetHunter kernel base — exists but scattered and unverified on G610F

- **KRAKEN_7870_Nethunter** (`github.com/Thiviyan/KRAKEN_7870_Nethunter`, Nethunter branch):
  NetHunter kernel for Exynos7870. "Works on OneUI Pie and Treble Q arm64 a-only."
  rt2800 + aircrack injection drivers added. 3038 commits (serious base).
  BUT: project marked "DEAD"; primary target is J730 (J7 2017); bootloop report on G611MT;
  G610X support appears only in a dead Telegram post, unverified.
- Helios_7870 kernel family said to cover j7xelte/on7xelte (GitHub topic list).
- Kali's official image list (`nethunter.kali.org/image-models.html`) has an "on7xlte"
  entry (NOT our `on7xelte`; likely On7 2016 Qualcomm); may not be our device, to be confirmed.
- **CRITICAL (from build script `cronos9.sh`):** the G610 family is in KRAKEN's build
  targets. `CR_CONFG_G610X=on7xelteswa_defconfig`, `FL_MODEL=on7xelte`, DTS
  `exynos7870-on7xelte_swa_open_00.dtb`. Shared `oneui_defconfig` + `KRAKEN_defconfig` +
  `treble_defconfig` are merged → OneUI (Pie) base is supported. Toolchain: GCC
  aarch64-none-linux-gnu, ARCH=arm64. So the defconfig + DTS + build script for our
  device are ready. "swa" = South-West Asia; our AP is also `on7xeltedd` (South Asia),
  looks compatible, but G610F-specific testing is required.
- **Strategy:** fork KRAKEN (DEAD) → build/test on G610F → fix device-specific issues →
  keep it as our live port + upstream. No need to start from Samsung source.

### 3. Internal Wi-Fi monitor/injection (nexmon) — uncertain, not critical

- nexmon (seemoo-lab) supports chips like bcm4339 (Nexus 5), bcm43430a1 (RPi).
- No ready nexmon port found for BCM4343 + Exynos. Doable but needs a new patch against
  that exact firmware version; high effort, uncertain payoff.
- Reliable path: external OTG USB Wi-Fi adapter. **We have an Alfa AWUS036NH (RT3070,
  `rt2800usb`), and KRAKEN already includes rt2800 injection.** Internal radio is a "bonus".

### 4. Samsung kernel source — available (GPLv2)

- Search `G610F` at opensource.samsung.com. Generally published; direct link not yet
  confirmed. Not strictly needed since KRAKEN already forks the 7870 kernel tree.

### 5. TWRP — no official, unofficial exists

- No official TWRP page for on7xelte. Unofficial builds and a G610F/DS/DD guide on XDA.
- Recovery will be chosen to match whichever base ROM/kernel recipe we settle on.

## Decisions (2026-10-12)

- **Base: Android 9 Pie (OneUI).** Stability priority; primary target of the KRAKEN
  NetHunter kernel. Android 11 Treble route dropped.
- **External Wi-Fi: Alfa AWUS036NH present.** Ralink RT3070, `rt2800usb`, monitor mode +
  injection, 2.4 GHz only (no 5 GHz). KRAKEN has rt2800 injection → internal
  BCM4343/nexmon uncertainty bypassed.
- **Kernel base = fork of KRAKEN_7870_Nethunter.**

## Architecture & chosen path

NetHunter = rooted Android (base ROM) + custom kernel + Kali chroot + app suite. The
kernel is the heart. We take KRAKEN's Exynos7870 NetHunter kernel (already targets the
G610 family), build it for the G610F, fix device-specific issues, and keep the internal
radio as a separate research branch while using the external adapter.

## Phase plan

1. Research/verification (no flashing) — **done**.
2. Build environment (Docker) + aarch64 toolchain; fork & clone KRAKEN.
3. Build the kernel with `on7xelteswa_defconfig` (no device flashing yet).
4. TWRP + FULL BACKUP (recovery guarantee). No flashing before this.
5. Base ROM install + hardware test.
6. NetHunter chroot + app suite + feature tests.
7. Mature and upstream to the Kali NetHunter GitLab (device contribution).

## Open questions

- Which Pie base ROM is most stable for on7xelte (CerberusOS etc.)? Which ROM/vendor was
  KRAKEN tested against?
- Direct Samsung open-source link for the correct (Pie, G610F) source version.
- License of this management repo and the GitHub remote (personal account).

## Outcome (2026-10-13)

Feasibility confirmed and executed end to end. A full Kali NetHunter was built from
source and installed on the device:

- Custom kernel `3.18.140-NetHunter-on7xelte` (our Docker pipeline, neutral build identity).
- Base ROM: YumiOS Pie (OneUI) — G610F has no official Pie, so a OneUI Pie custom ROM was
  required. Recovery: OrangeFox R11.0 (TWRP 3.3.0 failed the ROM install with "signal 9").
- Root: Magisk v30.7. NetHunter: generic 2026.2 minimal zip installed as a Magisk module
  (our kernel kept, not replaced).
- Kali chroot runs (`Kali GNU/Linux Rolling`, `apt` works). Kernel features compiled and
  verified in `/proc/config.gz`: RT2800USB_RT33XX (AWUS036NH), f_hid, MAC80211/CFG80211,
  WireGuard.

Pending: runtime hardware tests (HID, injection, WireGuard). Known issue: USB/ADB not up
at boot (needs a cable replug). See the README for current status and the full build flow.

## Sources

- https://github.com/Thiviyan/KRAKEN_7870_Nethunter
- https://github.com/samsungexynos7870/android_device_samsung_on7xelte
- https://nethunter.kali.org/image-models.html
- https://github.com/seemoo-lab/nexmon
- https://community.e.foundation/t/unofficial-build-samsung-galaxy-j7-prime-j7-on-nxt-on7xelte-for-e-os-r/62367
- https://www.getdroidtips.com/lineage-os-18-1-samsung-galaxy-j7-prime/
- https://www.getdroidtips.com/root-twrp-recovery-galaxy-j7-prime/
- https://opensource.samsung.com
