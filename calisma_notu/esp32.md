# ESP32 kolu: çalışma notu

Kart: ESP32-S (klasik ESP32-D0WD-V3 rev 3.1, 2 çekirdek 240 MHz, FPU), USB köprüsü CP2102 (COM4).
Firmware: `firmware/` (PlatformIO, Arduino-ESP32). MATLAB tarafı: `simulasyon/6_esp32/`.
Yol haritası: 1) ortam, 2) seri protokol, 3) 1 kHz görev iskeleti, 4) algoritmanın C'ye çevrilmesi,
5) adım kilitli PIL (42 senaryo), 6) kart içinde gerçek zamanlı ikiz, 7) sensör/sürücü kodları.

## Adım 1: ortam (2026-11-06, 3521756)

PlatformIO 6.2.0 (`python -m platformio ...`), yükleme 921600 baud, BOOT düğmesi gerekmiyor.
100 000 volatile float çarp-topla 6,3 ms: FPU çalışıyor.

## Adım 2: ikili seri protokol (2026-11-06)

### Paket

```
[A5][5A][tip:1][sira:2][uzunluk:1][yuk:0..128][crc:2]     (little-endian)
crc = CRC16-CCITT-FALSE (0x1021, başlangıç 0xFFFF), tip..yük üzerinden
```

Ek yük 8 bayt. Tipler: `01` yankı, `02` sayaçlar, `03` sayaç sıfırla, `04` baud değiştir
(onay eski hızda, sonra geçiş); cevap tipi = istek | 0x80, `7F` hata. Kart her paketin
sıra numarasını bir öncekinin +1'i olarak bekler ve CRC hatası, sıra atlaması, çöp bayt
(senkron kaybı) ve uzunluk hatası sayar. Tanım: `firmware/src/protokol.h`; MATLAB karşılığı:
`prot_paketle.m`, `prot_coz.m`, `prot_crc16.m` (öz sınama: `'123456789'` → `0x29B1`).

### Ölçüm (`seri_olcum.m`, log `seri_olcum_log.txt`, grafik `seri_olcum.png`)

PIL büyüklüğünde yük: 6 float = 24 B, paket 32 B. RTT = MATLAB'ın `write` çağrısından cevabın
son baytı okunana dek, N = 5000. Akış: 64 paket tek yazımda, 64 cevap okunur, 40 tekrar.

| baud | RTT p50 | p99 | en uzun | paket/s (akış) | kB/s her yön | kayıp / hata |
|---:|---:|---:|---:|---:|---:|---:|
| 921 600 | 1,13 ms | 1,33 ms | 4,01 ms | 2385 | 76,3 | 0 / 0 |
| 1 000 000 | 1,08 ms | 1,30 ms | 6,80 ms | 2647 | 84,7 | 0 / 0 |
| **1 500 000** | **0,85 ms** | **1,05 ms** | 2,43 ms | 3332 | 106,6 | 0 / 0 |
| 2 000 000 | çalışmıyor (kart geçiyor, CP2102 cevabı iletmiyor) | | | | | |
| 3 000 000 | .NET/CP210x sürücüsü kabul etmiyor (üst sınır 2 187 500) | | | | | |

Toplam 22 683 pakette (her baud için 7561) CRC hatası, sıra atlaması ve çöp bayt sıfır.

### Üç bulgu

1. **MATLAB `serialport()` kullanılamaz: her cevap ~15,7 ms.** Aynı kart, aynı paket: Python
   (pyserial) 1,3 ms, MATLAB `serialport` p50 15,7 ms (min 9,2). 15,625 ms Windows'un
   varsayılan zamanlayıcı adımı (1/64 s); `serialport`'un arka plandaki okuma iş parçacığı
   bu adımla uyanıyor. `NumBytesAvailable` yoklaması da aynı. Çözüm: MATLAB içinden
   **.NET `System.IO.Ports.SerialPort`** (`esp32_ac.m`). Engelleyici `ReadFile` kullanır, ek
   toolbox gerekmez. Yazılım benzetmesi: `serialport` "her 15 ms'de bir posta kutusuna bak"
   modunda; .NET ise "mektup gelene kadar kapıda bekle" modunda.
2. **Kartta bayt bayt `Serial.read()` darboğazdı.** Her çağrı IDF UART sürücüsünde kilit
   alıp bırakıyor. Toplu `Serial.read(buf, n)`'e geçince 921 600'de RTT p50 1,65 → 1,13 ms,
   akış 1761 → 2385 paket/s; 1,5 M'de RTT 1,35 → 0,85 ms. Ders: adım 3–5'te kartın seri
   tarafında hep toplu okuma/yazma kullan.
3. **RTT'nin kalan kısmı büyük ölçüde sabit.** 921 600 → 1,5 M geçişinde hattaki süre
   2 × 32 B × 10 bit: 0,69 → 0,43 ms (fark 0,26 ms), RTT farkı 0,28 ms. Geri kalan ~0,4 ms
   USB (CP2102 + Windows sürücüsü) ve .NET çağrılarından geliyor; baud ile azalmaz.
   Kartın paket işleme süresi en çok 40–150 µs (921 600'de yazma FIFO'yu beklerken uzar).

### PIL için anlamı (adım kilitli, 1 ms adım)

Bir PIL turu ≈ RTT + MATLAB'da paketle/çöz + ikizin bir adımı + kartta algoritmanın hesabı.

- RTT (1,5 M, p50/p99): 0,85 / 1,05 ms.
- MATLAB paketle + çöz: **~130 µs** (CRC'nin bayt döngüsü yorumlanıyor). Gerekirse CRC
  vektörleştirilebilir ya da PIL sırasında tek yönde basit toplama düşülebilir; şimdilik yeterli.
- İkiz adımı ve kart hesabı: adım 4–5'te ölçülecek (kart tarafı tahmini onlarca µs).

Yani bir tur **~1,0–1,2 ms + ikiz adımı**. PIL gerçek zamana yakın, büyük olasılıkla biraz
yavaş koşar. Adım kilitli olduğu için bu sorun değil: kart kendi saatine değil MATLAB'ın
gönderdiği örneğe göre çalışır, bir benzetim saniyesi ~1,1–1,5 duvar saniyesi sürer. 42
senaryonun toplam süresini senaryo uzunluğu belirler. Seyrek uzun turlar (en uzun 2,4–6,8 ms,
Windows zamanlaması) yalnız duvar saatini uzatır, sonucu değiştirmez.

**Karar:** PIL 1,5 Mbaud'da koşar. Kart 921 600'de açılır, MATLAB `T_BAUD` ile 1,5 M'ye geçirir.
Gerçek zamanlı çalışmada (adım 6–7) MATLAB döngüde olmadığından bu gecikme önemsizdir;
seri hat yalnız komut ve kayıt tamponu taşır (akış 1,5 M'de ~107 kB/s).
