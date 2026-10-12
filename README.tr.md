# nethunter-j7prime

Samsung Galaxy J7 Prime (SM-G610F, `on7xelte`, Exynos 7870) için sıfırdan
geliştirilen, tam destekli **Kali NetHunter** portu.

> Durum: erken geliştirme. Faz 1 (araştırma / fizibilite) tamam; sırada toolchain ve
> özel kernel derlemesi var. Kernel derlenip tam yedek alınana kadar cihaza hiçbir
> şey flash edilmez.

## Neden

Emekli bir telefonu pratik, tamamen sahip olunan bir güvenlik araştırma ve öğrenme
cihazına çevirmek: mobil uygulama reverse engineering, request/response analizi ve
sahibinin kendi cihazlarına yönelik yetkili hacking için bir platform. Bu kişisel bir
hobi ve öğrenme projesidir, marka ürünü değildir.

## Hedef cihaz

- Model **SM-G610F**, kod adı `on7xelte`, SoC Exynos 7870 (ARM64, 8x Cortex-A53), 3 GB RAM.
- Stok: Android 8.1.0, kernel 3.18.14. Rootlu (Magisk), Knox yanmış, OEM unlock serbest.
- Harici Wi-Fi: Alfa AWUS036NH (Ralink RT3070, `rt2800usb`, monitor mode + injection, 2.4 GHz).

## Yaklaşım ve kararlar

- **Taban: Android 9 Pie (OneUI).** Donanım sağlamlığı için ve üzerine inşa ettiğimiz
  NetHunter kernel'inin birincil hedefi olduğu için seçildi. Android 11 Treble yolu
  elendi (bu cihazda GSI'de mikrofon/kamera kararsız).
- **Kernel: `Thiviyan/KRAKEN_7870_Nethunter` fork'u.** Build script'i G610 ailesini
  zaten hedefliyor (`on7xelteswa_defconfig`, DTS `exynos7870-on7xelte`). Upstream proje
  "dead" işaretli; fork'layıp G610F'te derleyip doğrulayıp cihaza özgü sorunları
  düzeltiyoruz, canlı tutup Kali NetHunter projesine upstream etmeyi hedefliyoruz.
- **Wi-Fi injection harici AWUS036NH üzerinden.** Belirsiz dahili BCM4343 radyosunu
  baypas ediyor (bilinen nexmon portu yok); `rt2800` sürücüsü kernel'de zaten var.
- **Flash Heimdall ile** (Odin değil), download mode üzerinden.

## Yol haritası

1. Araştırma / fizibilite — **tamam**. Bkz. [docs/RESEARCH.md](docs/RESEARCH.md).
2. Build ortamı (Docker) + aarch64 toolchain; KRAKEN fork + klon.
3. Kernel'i `on7xelteswa_defconfig` ile derle (henüz cihaza flash yok).
4. Stok Pie firmware yedek + TWRP + tam yedek, sonra flash.
5. NetHunter chroot + app paketi + özellik testleri (HID, AWUS036NH injection, vb.).
6. Olgunlaştırıp Kali NetHunter projesine upstream.

Prensip: **önce derle, en son flash.** Kernel hazır olana kadar cihaza dokunulmaz.

## Lisans

NetHunter kernel'i Linux çekirdeği türevidir, dolayısıyla o bileşen **GPLv2 olmak
zorunda**. Bu yönetim deposunun lisansı henüz belirlenmedi. Telif: Kemal Aslıyüksek.

## Sorumluluk reddi

Yalnızca sahibi olduğunuz veya test etmek için açık izniniz olan donanım ve sistemlerde
yetkili güvenlik testi ve eğitim içindir. Kullanımından siz sorumlusunuz. Özel firmware
flash'lamak Knox garanti bit'ini yakar ve cihazı tuğlalayabilir; risk size aittir.
