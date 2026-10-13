# nethunter-j7prime

Samsung Galaxy J7 Prime (SM-G610F, `on7xelte`, Exynos 7870) için sıfırdan,
kaynaktan derlenerek oluşturulan tam destekli **Kali NetHunter** yapısı — hazır bir
imaj flash etmek yerine her katman elle kuruldu.

> Durum: **çalışıyor.** Kendi derlediğimiz özel NetHunter kernel'i cihazda boot
> ediyor ve tam Kali NetHunter yığını (uygulama paketi + Kali chroot) onun üstünde
> çalışıyor. Kalan doğrulama, donanım saldırı özelliklerinin runtime testleri (HID,
> Wi-Fi injection).

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

## Henüz runtime test edilmedi

Donanım saldırı özellikleri kernel'e derlendi ama henüz donanımda çalıştırılmadı:
HID saldırısı, AWUS036NH (RT3070) monitor mode + injection (`aireplay-ng -9`), WireGuard.

## Hedef cihaz

- SM-G610F, `on7xelte`, Exynos 7870 (ARM64, 8× Cortex-A53), 3 GB RAM.
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

## Yol haritası

- Runtime donanım testleri (HID, AWUS036NH injection, WireGuard).
- USB-at-boot sorununu düzeltmek.
- Harici Realtek sürücülerini (RTL8812AU/AC kartlar) vendorlamak.
- Cihazı/kernel'i Kali NetHunter projesine upstream etmek.

## Lisans

Kernel, Linux çekirdeğinin türevidir, dolayısıyla o bileşen **GPLv2**. Bu yönetim
deposunun lisansı henüz belirlenmedi. Telif: Kemal Aslıyüksek.

## Sorumluluk reddi

Yalnızca sahibi olduğunuz veya test izniniz olan donanımda yetkili güvenlik testi ve
eğitim içindir. Özel firmware flash'lamak Knox garanti bit'ini yakar ve cihazı
tuğlalayabilir; risk size aittir.
