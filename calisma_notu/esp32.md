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

Son firmware ile (adım 3 sürümü: haberleşme çekirdek 0'da, engelleyici okuma):

| baud | RTT p50 | p99 | en uzun | paket/s (akış) | kB/s her yön | kayıp / hata |
|---:|---:|---:|---:|---:|---:|---:|
| 921 600 | 1,19 ms | 1,39 ms | 3,30 ms | 2374 | 76,0 | 0 / 0 |
| 1 000 000 | 1,12 ms | 1,33 ms | 3,36 ms | 2620 | 83,8 | 0 / 0 |
| **1 500 000** | **0,88 ms** | **1,06 ms** | 2,13 ms | 3274 | 104,8 | 0 / 0 |
| 2 000 000 | çalışmıyor (kart geçiyor, CP2102 cevabı iletmiyor) | | | | | |
| 3 000 000 | .NET/CP210x sürücüsü kabul etmiyor (üst sınır 2 187 500) | | | | | |

Her baud için 7561 paket; CRC hatası, sıra atlaması ve çöp bayt sıfır. Adım 2 sürümünde
(haberleşme `loop()` içinde, yoklamalı) sayılar aynı düzeydeydi: 1,5 M'de p50 0,85 ms.

**Bir kez görülen kayıp:** adım 3 firmware'inin ilk `seri_olcum` koşusunda 1,5 M'deki 64
paketlik toplu yazımda 448 bayt (14 paket) gelmedi. Sonraki MATLAB koşusunda ve Python ile
6 × 2561 pakette yeniden üretilemedi, sebebi bilinmiyor. PIL adım kilitli olduğundan toplu
yazım yapmaz; kayıt çekmede de her parça CRC + sıra no ile doğrulanır, kayıp sessiz geçmez.
Uzun PIL koşularında kayıp/zaman aşımı sayacı tutulmalı, gerekirse tekrar istenmeli.

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

- RTT (1,5 M, p50/p99): 0,88 / 1,06 ms.
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
seri hat yalnız komut ve kayıt tamponu taşır.

## Adım 3: 1 kHz kontrol görevi iskeleti (2026-11-06)

### Yapı (`firmware/src/main.cpp`)

- **Çekirdek 1, kontrol görevi**, en yüksek öncelik. Donanım zamanlayıcısı (1 MHz sayaç,
  1000 µs'de alarm) kesme üretir; kesme çevrim sayacını not edip görevi bildirimle uyandırır.
  Zamanlayıcı görevin içinde kurulur, böylece kesme de çekirdek 1'e bağlanır. Görev şimdilik
  sahte bir float yükü koşar (`sahteAdim`); adım 4'te gerçek algoritma buraya girer.
- **Çekirdek 0, haberleşme görevi.** `Serial.begin` burada çağrılır, UART kesmesi de çekirdek
  0'a kurulur. İlk bayt engelleyerek beklenir (`readBytes`, görev uyur), kalanı toplu okunur.
  Arduino `loop()` görevi silinir.
- **Kayıt tamponu**: 10 000 tur × 8 B (periyot, kesme→uyanma gecikmesi, adım süresi; CPU
  çevrimi, 240 MHz → 4,2 ns). Yeni paketler: `10` kaydı başlat (N, yük), `11` durum, `12` kaydı
  oku. `12` istenen aralığı **art arda paketlerle** (paket başına 30 kayıt, sıra no = parça
  indisi) bekleme olmadan gönderir. Ayrıca kaçırılan kesme sayılır.

### Ölçüm (`dongu_olcum.m`, log `dongu_olcum_log.txt`, grafik `dongu_olcum.png`)

Her koşul 10 000 tur (10 s). B ve C'de kayıt boyunca MATLAB kesintisiz adım kilitli yankı
gönderir (~9400 paket, PIL benzeri yük).

| koşul | \|periyot sapması\| p99 | en büyük | uyanma gecikmesi p50 / p99 / en uzun | adım süresi en uzun | kaçan |
|---|---:|---:|---:|---:|---:|
| A: sessiz hat, adım ~19 µs | 0,012 µs | 6,7 µs | 8,5 / 8,5 / 15,2 µs | 27 µs (ilk tur, önbellek) | 0 |
| B: yankı trafiği, adım ~19 µs | 6,7 µs | 9,6 µs | 8,5 / 13,9 / 17,4 µs | 19,4 µs | 0 |
| C: yankı trafiği, adım ~300 µs | 6,4 µs | 9,2 µs | 8,5 / 14,0 / 17,2 µs | 302 µs | 0 |

Kayıt çekme: 10 000 kayıt (80 kB) 0,56 s'de, 143 kB/s (1,5 M'nin %95'i). Tüm koşullarda kart
tarafında CRC hatası, sıra atlaması ve çöp bayt sıfır.

### Yorum

- **Periyot sapması en çok ~10 µs, yani periyodun %1'i.** Ortalama periyot tam 1000,0000 µs
  (donanım zamanlayıcısı kayma yapmaz); sapma yalnız uyanma gecikmesindeki oynamadan gelir.
  1 kHz kontrol için önemsiz: iş sırası 5a'da ikiz 2 ms'ye kadar ölçüm gecikmesine
  dayanıklı çıkmıştı, bu 200 kat büyük.
- **Uyanma gecikmesi sabit ~8,5 µs** (Arduino zamanlayıcı sarmalayıcısı + FreeRTOS bağlam
  değişimi). Seri trafik altında kuyruk 17 µs'ye uzar. Haberleşme ayrı çekirdekte olsa da iki
  çekirdek FreeRTOS çekirdek kilidini paylaşır: çekirdek 0 UART kuyruğunda kilidi tutarken
  çekirdek 1'in bildirimi kısa süre bekler. Yazılım benzetmesi: iki iş parçacığı ayrı CPU'da
  ama aynı mutex'e dokunuyor. Gerekirse kesme içinde doğrudan iş yapmak (görev yerine) ya da
  ESP-IDF'nin `gptimer`'ını sarmalayıcısız kullanmak bunu düşürür; şimdilik gerek yok.
- **Ağır yük (300 µs) zamanlamayı bozmuyor**: periyot ve gecikme dağılımı B ile aynı, kaçan
  kesme yok. Gerçek algoritmanın (adım 4) bütçesi rahat: 1000 µs − ~20 µs gecikme.
- **Adım süresinin kendisi çok kararlı**: 19 µs'lik adım p50 18,98, p99 19,30 µs. Adım 4'te
  algoritmanın süresi bu altyapıyla doğrudan ölçülecek.

Sıradaki: adım 4, algoritmanın C'ye çevrilmesi (P-PI, ofset tablosu, tork gözlemcisi, yüz
kestirici), `kol_benzetim.m`'deki sırayla, float ve int32 motor turu sayacıyla.
