# nethunter-j7prime

Samsung Galaxy J7 Prime (SM-G610F, `on7xelte`, Exynos 7870) için sıfırdan,
kaynaktan derlenerek oluşturulan tam destekli **Kali NetHunter** yapısı — hazır bir
imaj flash etmek yerine her katman elle kuruldu.

> Durum: **çalışıyor.** Kendi derlediğimiz özel NetHunter kernel'i cihazda boot
> ediyor ve tam Kali NetHunter yığını (uygulama paketi + Kali chroot) onun üstünde
> çalışıyor. Harici Wi-Fi monitor mode + injection (AWUS036NH) artık runtime doğrulandı;
> kalan doğrulama HID saldırısı ve WireGuard.

## Bu nedir

Eski bir J7 Prime'ın Kali NetHunter pentest ve öğrenme cihazına dönüştürülmesi; her
katman elle kuruldu: kaynaktan derlenen kernel, uyumlu bir ROM, root, NetHunter
userland ve Kali chroot. Kişisel hobi ve öğrenme projesi, marka ürünü değil.

## Sonuç (cihazda doğrulandı)

- **Özel kernel** `3.18.140-NetHunter-on7xelte`, kendi Docker build pipeline'ımızla
  derlendi. Nötr build kimliği (`nethunter@on7xelte`, sabit tarih) — build makinesi,
  kullanıcısı veya zamanı kernel string'ine sızmıyor (OPSEC + tekrarlanabilir).
- **Taban:** YumiOS Pie (OneUI, `on7xelte`) + Magisk root (`su` → uid 0).
- **Kali NetHunter 2026.2:** uygulama paketi (5 app: nethunter, kex, store,
  store.privileged, nhterm) + **Kali GNU/Linux Rolling** chroot (`apt` çalışıyor).
  Magisk modülü olarak kuruldu, yani kernel'imizi **ezmiyor**.
- **Kernel'e derlenen özellikler** (`/proc/config.gz` ile doğrulandı): AWUS036NH
  injection sürücüsü (`rt2800usb`, RT33XX), HID gadget (`f_hid`), MAC80211/CFG80211,
  WireGuard.

## Runtime doğrulandı (cihazda)

- **Harici Wi-Fi monitor mode + injection**, Alfa AWUS036NH (RT3070) ile: `wlan1` monitor
  moduna alındı, `aireplay-ng -9` injection testi ~%93 başarı, pasif `airodump-ng` capture
  ve istemcisiz bir PMKID yakalama — hepsi çalışıyor. Bu, aşağıdaki Bilinen sorunlardaki
  `rt2870.bin` firmware düzeltmesini gerektirdi; adaptör o olmadan ayağa kalkmıyor.

## Henüz runtime test edilmedi

Kernel'e derlendi ama henüz donanımda çalıştırılmadı: HID saldırısı, WireGuard.

## Hedef cihaz

- SM-G610F, `on7xelte`, Exynos 7870 (ARM64, 8× Cortex-A53), 3 GB RAM.
- **64-bit SoC ve kernel, ama 32-bit Android userspace** (`zygote32`, `armeabi-v7a`, bu
  yüzden `uname -m` → `armv8l`). Kali chroot'un kendisi 64-bit (arm64). Bu ayrım önemli:
  frida-server'ın `android-arm` (32-bit) sürümü olması gerekiyor ve chroot'taki pip
  aarch64-wheel workaround'u istiyor (bkz. Bilinen sorunlar).
- Stok Android 8.1 — bu model **resmi Android 9 Pie almadı**, bu yüzden OneUI kernel'imizden
  önce bir OneUI Pie custom ROM (YumiOS) gerekiyor.
- Harici Wi-Fi: Alfa AWUS036NH (Ralink RT3070), güvenilir injection yolu.

## Nasıl kuruldu (üst düzey)

1. **Kernel:** KRAKEN_7870 NetHunter kernel'inin fork'u, Docker'da (Ubuntu 20.04 +
   ARM GNU 9.2 toolchain) G610X / OneUI (Pie) hedefi için derlendi. Bkz. [`docker/`](docker/).
2. **Recovery:** OrangeFox R11.0 — TWRP 3.3.0 ROM kurulumunda "Updater process ended with
   signal 9" verdi (eski update-binary ile legacy-property emülasyonu çakışması).
3. **ROM:** YumiOS Pie (OneUI) — kernel'imizin ihtiyaç duyduğu taban; yapımcısı başarılı
   boot sonrası Cronos/Kraken kernel flash'ını açıkça destekliyor.
4. **Kernel'imiz:** `dd` ile BOOT partition'a yazıldı; Magisk ile tekrar root'landı.
5. **NetHunter:** generic `kali-nethunter-2026.2-generic-arm64-minimal.zip` Magisk modülü
   olarak kuruldu (kernel'imiz kalır, uygulama paketi + chroot + systemless scriptler eklenir).

## Derleme

Önce KRAKEN kernel kaynağını `./kraken` içine klonla, sonra:

```
docker build -t nethunter-j7prime-builder docker/
docker run --rm --user 1000:1000 -e HOME=/tmp \
  -v $PWD/kraken:/kernel \
  -v $PWD/docker/build-kernel.sh:/usr/local/bin/build-kernel.sh:ro \
  nethunter-j7prime-builder
```

Bu, `kraken/KRAKEN/Out/` altında flash edilebilir bir `boot.img` üretir. Build script'i
cihaz + OneUI + NetHunter defconfig'lerini birleştirir, bulunmayan Realtek sürücülerini
devre dışı bırakır, WireGuard'ı sabitler, nötr build kimliği ayarlar ve boot imajını paketler.

## Bilinen sorunlar

- Kernel'imizle USB/ADB boot'ta otomatik gelmiyor, kablo fiziksel çıkar-tak gerekiyor
  (host boot'ta USB cihazı görmüyor). Ramdisk/init tarafında düzeltilecek
  (`persist.sys.usb.config` / `init.usb.rc`).
- **AWUS036NH, YumiOS'un içermediği `rt2870.bin` firmware'ine ihtiyaç duyuyor.** O olmadan
  `rt2800usb` sürücüsü yükleniyor ama arayüz ayağa kalkmıyor
  (`rt2x00lib_request_firmware: Failed to request Firmware`). Kernel'in `/data`'dan doğrudan
  firmware yüklemesini SELinux engelliyor, ueventd ise yalnızca sistem firmware dizinlerine
  bakıyor. Çözüm: `rt2870.bin`'i (`linux-firmware` projesinden) küçük bir Magisk modülüyle
  `/vendor/firmware` altına koymak (`system/vendor/firmware/rt2870.bin`, SELinux context
  `vendor_firmware_file`); böylece her boot'ta yüklenir.
- **frida-server bu 32-bit Android'de çalışmıyor.** frida *client* chroot'a sorunsuz
  kuruluyor (pip'in aarch64 wheel'lerini kabul etmesi için bir `uname` shim'iyle), ama
  `android-arm` frida-server başlarken Samsung `dex2oat` yolunda çöküyor (eksik
  `vendor.samsung.security.proca@1.0.so`). Dinamik enstrümantasyon şimdilik kapalı; statik
  analiz ve `mitmproxy` trafik yakalama etkilenmiyor.

## Yol haritası

- Kalan runtime donanım testleri: HID saldırısı, WireGuard (AWUS036NH injection tamam).
- USB-at-boot sorununu düzeltmek.
- frida-server'ı 32-bit Android'de çalıştırmak ya da desteklenmiyor olarak belgelemek.
- Harici Realtek sürücülerini (RTL8812AU/AC kartlar) vendorlamak.
- Cihazı/kernel'i Kali NetHunter projesine upstream etmek.

## Krediler

Bu proje başkalarının emeği üstüne kuruldu:

- **KRAKEN_7870** NetHunter kernel — Thiviyan, BlackMesa / AnanJaser1211 (kernel'imizin
  fork'landığı Exynos7870 kernel ailesi)
- **YumiOS Pie** — TheRealModder (OneUI taban ROM)
- **OrangeFox Recovery** projesi
- **Kali NetHunter** — Kali / OffSec ekibi

## Lisans

Bu yönetim deposu (build script'leri ve dokümantasyon) **MIT Lisansı** altındadır —
bkz. [LICENSE](LICENSE). Derlediği kernel, Linux çekirdeğinin türevidir ve dolayısıyla
**GPLv2**'dir. Telif © 2026 Kemal Aslıyüksek.

## Sorumluluk reddi

Yalnızca sahibi olduğunuz veya test izniniz olan donanımda yetkili güvenlik testi ve
eğitim içindir. Özel firmware flash'lamak Knox garanti bit'ini yakar ve cihazı
tuğlalayabilir; risk size aittir.
