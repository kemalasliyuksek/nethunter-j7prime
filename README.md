# nethunter-j7prime

A from-scratch, fully-supported **Kali NetHunter** build for the Samsung Galaxy
J7 Prime (SM-G610F, `on7xelte`, Exynos 7870) — built entirely from source rather
than flashed from a prebuilt image.

> Status: **working.** Our own custom NetHunter kernel boots on the device, and the
> full Kali NetHunter stack (app suite + Kali chroot) runs on top of it. The remaining
> validation is runtime hardware-attack testing (HID, Wi-Fi injection).

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

## Not yet runtime-tested

The hardware-attack features are compiled in but have not been exercised on hardware yet:
HID attack, AWUS036NH (RT3070) monitor mode + injection (`aireplay-ng -9`), WireGuard.

## Target device

- SM-G610F, `on7xelte`, Exynos 7870 (ARM64, 8× Cortex-A53), 3 GB RAM.
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

## Roadmap

- Runtime hardware tests (HID, AWUS036NH injection, WireGuard).
- Fix the USB-at-boot issue.
- Vendor the external Realtek drivers (RTL8812AU/AC adapters).
- Upstream the device/kernel to the Kali NetHunter project.

## License

The kernel is a derivative of the Linux kernel, so that component is **GPLv2**. The
license of this management repository is to be decided. Copyright: Kemal Aslıyüksek.

## Disclaimer

For authorized security testing and education on hardware you own or have explicit
permission to test. Flashing custom firmware trips the Knox warranty bit and can brick a
device; proceed at your own risk.

Türkçe sürüm: [README.tr.md](README.tr.md).
