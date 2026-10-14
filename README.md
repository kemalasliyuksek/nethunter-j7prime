# nethunter-j7prime

A from-scratch, fully-supported **Kali NetHunter** build for the Samsung Galaxy
J7 Prime (SM-G610F, `on7xelte`, Exynos 7870) — built entirely from source rather
than flashed from a prebuilt image.

> Status: **working.** Our own custom NetHunter kernel boots on the device, and the
> full Kali NetHunter stack (app suite + Kali chroot) runs on top of it. External Wi-Fi
> monitor mode + injection (AWUS036NH) is now runtime-verified; the remaining validation
> is HID attack and WireGuard.

## What this is

An old J7 Prime turned into a Kali NetHunter pentest and learning device, with every
layer assembled by hand: a kernel compiled from source, a matching ROM, root, the
NetHunter userland, and a Kali chroot. Personal hobby and learning project, not a brand
product.

## Result (verified on device)

- **Custom kernel** `3.18.140-NetHunter-on7xelte`, compiled with our own Docker build
  pipeline. Neutral build identity (`nethunter@on7xelte`, fixed timestamp) — no build
  machine, user, or time leaked into the kernel string (OPSEC + reproducible).
- **Base:** YumiOS Pie (OneUI, `on7xelte`) + Magisk root (`su` → uid 0).
- **Kali NetHunter 2026.2:** app suite (5 apps: nethunter, kex, store, store.privileged,
  nhterm) + **Kali GNU/Linux Rolling** chroot (`apt` works). Installed as a Magisk module
  so it does **not** replace our kernel.
- **Kernel features compiled in** (verified via `/proc/config.gz`): AWUS036NH injection
  driver (`rt2800usb`, RT33XX), HID gadget (`f_hid`), MAC80211/CFG80211, WireGuard.

## Runtime-verified (on device)

- **External Wi-Fi monitor mode + injection** with the Alfa AWUS036NH (RT3070): `wlan1`
  put into monitor mode, `aireplay-ng -9` injection test at ~93% success, passive
  `airodump-ng` capture, and a client-less PMKID grab — all working. This required the
  `rt2870.bin` firmware fix in [Known issues](#known-issues); the adapter will not come
  up without it.

## Not yet runtime-tested

Compiled in but not yet exercised on hardware: HID attack, WireGuard.

## Target device

- SM-G610F, `on7xelte`, Exynos 7870 (ARM64, 8× Cortex-A53), 3 GB RAM.
- **64-bit SoC and kernel, but a 32-bit Android userspace** (`zygote32`, `armeabi-v7a`,
  so `uname -m` reports `armv8l`). The Kali chroot itself is 64-bit (arm64). This split
  matters: the frida-server must be the `android-arm` (32-bit) build, and pip inside the
  chroot needs an aarch64-wheel workaround (see Known issues).
- Stock Android 8.1 — this model **never got official Android 9 Pie**, which is why a
  OneUI Pie custom ROM (YumiOS) is required before our OneUI kernel.
- External Wi-Fi: Alfa AWUS036NH (Ralink RT3070), the reliable injection path.

## How it was built (high level)

1. **Kernel:** fork of the KRAKEN_7870 NetHunter kernel, built in Docker (Ubuntu 20.04 +
   ARM GNU 9.2 toolchain) for the G610X / OneUI (Pie) target. See [`docker/`](docker/).
2. **Recovery:** OrangeFox R11.0 — TWRP 3.3.0 failed the ROM install with
   "Updater process ended with signal 9" (legacy-property emulation vs an old update-binary).
3. **ROM:** YumiOS Pie (OneUI) — the base our kernel needs; its maintainer explicitly
   supports flashing a Cronos/Kraken kernel after a successful boot.
4. **Our kernel:** flashed with `dd` to the BOOT partition; re-rooted with Magisk.
5. **NetHunter:** generic `kali-nethunter-2026.2-generic-arm64-minimal.zip` installed as a
   Magisk module (keeps our kernel, adds the app suite + chroot + systemless scripts).

## Build

Clone the KRAKEN kernel source into `./kraken` first, then:

```
docker build -t nethunter-j7prime-builder docker/
docker run --rm --user 1000:1000 -e HOME=/tmp \
  -v $PWD/kraken:/kernel \
  -v $PWD/docker/build-kernel.sh:/usr/local/bin/build-kernel.sh:ro \
  nethunter-j7prime-builder
```

This produces a flashable `boot.img` under `kraken/KRAKEN/Out/`. The build script merges
the device + OneUI + NetHunter defconfigs, disables unavailable Realtek drivers, pins
WireGuard, sets a neutral build identity, and packages the boot image.

## Known issues

- With our kernel, USB/ADB does not come up at boot until the cable is physically
  replugged (the host sees no USB device at boot). To be fixed in ramdisk/init
  (`persist.sys.usb.config` / `init.usb.rc`).
- **AWUS036NH needs the `rt2870.bin` firmware, which YumiOS does not ship.** Without it
  the `rt2800usb` driver loads but the interface never comes up
  (`rt2x00lib_request_firmware: Failed to request Firmware`). The kernel's direct
  firmware load from `/data` is blocked by SELinux, and ueventd only searches the system
  firmware directories. Fix: drop `rt2870.bin` (from the `linux-firmware` project) into
  `/vendor/firmware` via a small Magisk module (`system/vendor/firmware/rt2870.bin`, with
  SELinux context `vendor_firmware_file`) so it loads at every boot.
- **frida-server does not run on this 32-bit Android.** The frida *client* installs fine
  in the chroot (using a `uname` shim so pip accepts the aarch64 wheels), but the
  `android-arm` frida-server crashes on launch inside the Samsung `dex2oat` path (missing
  `vendor.samsung.security.proca@1.0.so`). Dynamic instrumentation is blocked for now;
  static analysis and `mitmproxy` traffic interception are unaffected.

## Roadmap

- Remaining runtime hardware tests: HID attack, WireGuard (AWUS036NH injection done).
- Fix the USB-at-boot issue.
- Get frida-server working on 32-bit Android, or document it as unsupported.
- Vendor the external Realtek drivers (RTL8812AU/AC adapters).
- Upstream the device/kernel to the Kali NetHunter project.

## Credits

This project stands on the work of others:

- **KRAKEN_7870** NetHunter kernel — Thiviyan, BlackMesa / AnanJaser1211 (the Exynos7870
  kernel family our kernel is forked from)
- **YumiOS Pie** — TheRealModder (the OneUI base ROM)
- **OrangeFox Recovery** project
- **Kali NetHunter** — the Kali / OffSec team

## License

This management repository (build scripts and documentation) is licensed under the
**MIT License** — see [LICENSE](LICENSE). The kernel it builds is a derivative of the
Linux kernel and is therefore **GPLv2**. Copyright © 2026 Kemal Aslıyüksek.

## Disclaimer

For authorized security testing and education on hardware you own or have explicit
permission to test. Flashing custom firmware trips the Knox warranty bit and can brick a
device; proceed at your own risk.

Türkçe sürüm: [README.tr.md](README.tr.md).
