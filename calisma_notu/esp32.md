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

## Adım 4: algoritmanın C++'a çevrilmesi (2026-11-06)

### Kod (`firmware/src/kontrol.h/.cpp`)

`kontrol::Kontrolcu`: `baslat(Ayar)` + `adim(Girdi) → Cikti`. Saf C++ (yalnız `<stdint.h>`,
`<math.h>`), Arduino'ya bağlı değil. Kapsam: P-PI (motor tarafı konum + motor hızı), ofset
(`s_of*r + mgl sin(th_ref)/K_s`), tork gözlemcisi, yüz kestirici (edilgen / olay / yoklama /
olay+yoklama, rampa), doyum, anti-windup, integral ölü bandı, sürücü ölü bandı. Sıra
`kol_benzetim.m` ile birebir; her blokta MATLAB satır numarası yorumda.

- **Girdi** (10 B): motor AS5600 ham açısı (0..4095), motor hızı, ölçülen tork.
  **Çıktı** (20 B): u, w^, d^, s_of, s^, yoklama evresi, hesap süresi (çevrim).
  **Ayar** (180 B): aynı zamanda paket yükü; MATLAB karşılığı `ktl_ayar_paketle.m`.
- **Çok tur sayımı:** her örnekte Δ = ham − önceki, [−2048, 2048)'e sarılır, int32 sayaca
  eklenir (`mimari.md`'deki tarif). Başlangıç sayımı `Ayar.ilkSayim`.
- **float ve büyük açı:** 180°'de sayım ≈ 61 440; float açıyı (≈ 3,14 rad) 2,4e-7 rad adımla
  tutar, gözlemcinin 1 ms'lik artışları ise ~1e-6 rad. Bu yüzden açılar hep fark olarak
  hesaplanır: hedef = `refC` sayım + `refF` kesir, gözlemci phi^ yerine (phi^ − son ölçüm)
  farkını taşır. Yazılım benzetmesi: büyük bir zaman damgasına küçük süreleri eklemek yerine
  tamsayı "epoch" + küçük kayan ofset tutmak.
- **Zaman eşikleri tamsayıya çevrilir:** `yokBekle`, `yokTmin`, `yokTmax`, `yokPer` ve olay
  maskesi `baslat`'ta, MATLAB'ın double karşılaştırmasını (birikimli `ykT + Ts` dahil) aynen
  yaparak örnek sayısına dönüşür. Örnek: `yokTmax` 0,3 float'a çevrilip karşılaştırılsaydı
  300 değil 301. örnekte biterdi.
- **IRAM:** `adim()` IRAM'de (`KONTROL_HIZLI`). Flash'ta iken önbellek ıskası ilk turu 308 µs'ye,
  ilk yoklamayı 16–28 µs'ye, PIL'de her paketin ilk örneğini ~40 µs'ye çıkarıyordu. Float bölme
  de kaldırıldı (ESP32 FPU'sunda donanım bölme yok; 1/J_M önceden hesaplanır).
- **Hız kaynağı:** `HIZ_GIRDI` (dışarıdan verilen motor hızı) ya da `HIZ_GOZLEMCI` (w^).
  **Dikkat:** 42 senaryonun kurulumunda `p.fv = Inf`, yani ikizde kontrolcü motor hızını
  **hatasız** görüyor. Eşdeğerlik testi bu yüzden `HIZ_GIRDI` ile koşar. Donanımda hız
  gözlemciden gelecek (`mimari.md` §4.1 güncellemesi); ikizde bu henüz sınanmadı (aşağıda).
- `baslat()` double hesaplar yüzünden ~1 ms sürer. 1 kHz görevde çağrılmaz: haberleşme görevi
  hazır nesneyi kurar, kontrol görevi kopyalar.
- Kazanç: `kp`, `KV`, `KI` ayardan gelir (42 senaryoda r_gs 0,50 sabit). Açıya göre tablo
  (`tablo_ilk_D.csv`) henüz kodda yok; hedef değişince ayarla birlikte gönderilecek.

Yeni paketler (`protokol.h`): `20` T_KTL_BASLAT (Ayar → Turetilen: refC, refF, eşik sayıları),
`21` T_KTL_ADIM (n ≤ 12 Girdi → n Cikti; PIL'de n = 1). Ayrıca `10` kaydı `yukIter = 0` ile
başlatılırsa 1 kHz görev sahte yük yerine gerçek algoritmayı sentetik girdiyle koşar.

`kol_benzetim.m`'ye `p.ktlKayit` eklendi (varsayılan kapalı): her kontrol örneğinin girdisi ve
çıktısı `out.ktl`'ye yazılır. Gerileme kontrolü: `belirsiz_bant` ve `yuz_kestirici_as5600`
loglarında yalnız tarih satırı değişti.

### Açık döngü eşdeğerlik testi (`ktl_esdeger.m`, log `ktl_esdeger_log.txt`)

İkiz 42 senaryoyu `akim_gurultu.m`'nin "INA228 taban" kurulumuyla koşar (1 kHz, AS5600 motor
milinde, 0,4 ms gecikme, 0,043° gürültü, gözlemci torku INA228'den, akım döngüsü 500 Hz,
olay+yoklama, yokOrta 0,6, vDurF 10 Hz), sürtünmeli ve sürtünmesiz. Kaydedilen girdiler karta
12'şer örnekle beslenir; kart kendi durumuyla koşar (ikizin durumu kopyalanmaz).

| | sürtünmeli | sürtünmesiz |
|---|---:|---:|
| ayrık kararlar (s^, yoklama evresi) 8000 örneğin hepsinde aynı | 42/42 | 42/42 |
| en büyük \|Δu\| [N m] | 3,4e-7 | 3,2e-7 |
| en büyük \|Δw^\| [rad/s] | 1,2e-7 | 1,4e-7 |
| en büyük \|Δd^\| [N m] | 4,3e-8 | 4,4e-8 |
| en büyük \|Δs_of\| | 2,6e-6 | 2,6e-6 |
| kartta adım süresi ort / p99 / en uzun [µs] | 3,53 / 4,01 / 9,48 | 3,54 / 4,00 / 9,46 |

Farklar float yuvarlaması düzeyinde (u'nun 0,49 N m doyumunun ~1e-6'sı). s_of'taki 2,6e-6,
rampa adımının (0,004) float birikimi.

**1 kHz görevde (çekirdek 1, sentetik girdi, 10 000 tur):** adım ort 3,66 µs, p99 4,10, en
uzun 37,7 µs (yalnız ilk tur); periyot sapması en çok 1,7 µs, kaçan kesme 0. Bütçenin
(~980 µs) %0,4'ü. Kart sayaçlarında CRC hatası, sıra atlaması ve çöp bayt sıfır.

### Açık kalan

- ~~**Hız kaynağı**~~ **KAPANDI (6 Kasım 2026):** ikize `p.vKaynak = 'gozlemci'` eklendi
  (`hiz_gozlemci.m`, ayrıntı `framing.md` "Kontrolcünün hızı = gözlemcinin w^'si"). w^ ile
  (gozW 40 Hz) iki ikizde de H7 42/42, B13 ≤ 0,32°; ideal hızla aynı. Pay gozW 30–50 Hz.
  `ktl_ayar_paketle.m` bu modda `hizKaynak = 1` (HIZ_GOZLEMCI) gönderiyor. `ktl_esdeger.m`,
  `KTL_VKAYNAK=gozlemci` ile (log `ktl_esdeger_gozlemci_log.txt`): 81/84 senaryo ayrık
  kararlarda birebir, |Δw^| ≤ 1,5e-7. Kalan 3'ü tek örneklik eşitlik durumu: yoklamada
  `yol <= ykDm·yokOrta`, yol = 165 = 0,6·275 sayım. Double radyanda "geçmedi", float sayımda
  "geçti" çıkıyor; kart 1 ms erken frenliyor, sonrası aynı. Hızla ilgisi yok. **PIL'de bu
  modla koşulacak** (donanımdaki seçim).
- Açıya göre kazanç/ofset tablosu kodda değil (hedef başına ayar).

## Adım 5: adım kilitli PIL (2026-11-07)

İkiz MATLAB'da koşar. Her kontrol örneğinde (1 ms) motor ölçümü `T_KTL_ADIM` (n = 1) ile
karta gider, kartın u'su ikize uygulanır. Kart döngünün içinde ama gerçek zamansız: ikiz
cevabı bekler (yazılım benzetmesi: canlı sistem yerine, her isteği tek tek gönderip cevabını
bekleyen bir entegrasyon testi).

### Kod
- `kol_benzetim.m`: `p.ktlDis` kancası, `[u, c] = p.ktlDis(kc, sayim, v, uo, ilkSayim)`.
  MATLAB kontrolcüsü yine hesaplanır (**gölge**: aynı ölçümleri görür), ardından tesise dış
  kontrolcünün u'su uygulanır. Böylece her örnekte kapalı döngüde kart ile MATLAB aynı girdiyle
  karşılaştırılır. Yalnız yuzKes açıkken ve n = 1 iken; `out.ktl.uM` (gölge u), `out.ktl.kart`
  (kartın çıktıları). Kanca yokken davranış aynı (gerileme: `belirsiz_bant`,
  `yuz_kestirici_as5600` loglarında yalnız tarih değişti).
- `6_esp32/pil.m`: 42 senaryo × sürtünmeli/sürtünmesiz, kurulum "INA228 taban",
  `vKaynak = 'gozlemci'` (kartta HIZ_GOZLEMCI). Her senaryo iki kez koşar: **referans** (yalnız
  MATLAB) ve **PIL**. İkisi de n = 1, aynı tohum: enkoder gürültüsü tek `randn` akışından
  geldiği için 42'lik vektör koşusuyla karşılaştırma adil olmazdı. Kart `kc = 1`'de
  `T_KTL_BASLAT` ile kurulur (3 deneme).

### Sonuç (log `pil_log.txt`, 84 senaryo, 672 085 paket)

| | sürtünmeli | sürtünmesiz |
|---|---:|---:|
| H7 PIL / referans | 42/42 / 42/42 | 42/42 / 42/42 |
| en kötü \|e\| PIL / ref [°] | 0,178 / 0,177 | 0,002 / 0,002 |
| B13 en çok PIL / ref [°] | 0,324 / 0,324 | 0,296 / 0,296 |
| kart ile gölgenin ayrık kararları 8000 örnekte aynı | 42/42 | 42/42 |
| en büyük \|u_kart − u_gölge\| [N m] | 3,6e-7 | 3,0e-7 |
| en büyük \|θ_PIL − θ_ref\| [°] | 0,25 | 0,59 |
| tur (MATLAB gidiş-dönüş) ort / p99 / en uzun [ms] | 0,88 / 1,20 / 5,3 | 0,85 / 0,99 / 65 |
| kartta adım ort / en uzun [µs] | 3,46 / 9,40 | 3,48 / 9,27 |
| kayıp örnek | 0 | 0 |

Kart sayaçlarında CRC hatası, sıra atlaması, çöp bayt sıfır. Senaryo başına ~9 s (8 s benzetim).

**Yorum.**
- Kartın C++ kontrolcüsü kapalı döngüde MATLAB'ınkiyle aynı kararları veriyor. u farkı float
  yuvarlaması düzeyinde (adım 4'teki açık döngü sonucuyla aynı). Adım 4'teki yoklama `yokOrta`
  eşitlik durumu bu koşuda görülmedi.
- θ_PIL − θ_ref farkı (en çok 0,59°, sürtünmesiz "darbe" j17–19) bozucu sırasında geçici: kol
  boşluktayken 1e-7 N m'lik fark temas anını bir iki örnek kaydırıyor. Son 1 s hatası iki
  tarafta 0,001° içinde aynı. Bir senaryoda (sürtünmeli j20) yoklama sayısı PIL'de 1,
  referansta 2; sonuç yine aynı.
- **Windows/USB takılması:** ilk koşuda bir cevap 218 ms gecikti. Kart örneği almıştı (sayaçlar
  temiz), gecikme PC tarafındaydı. 200 ms zaman aşımı örneği "kayıp" saydı ve geç gelen cevap
  bir sonrakini bozdu (o senaryoda tek ayrışma). Zaman aşımı 2 s yapıldı: adım kilitli testte
  doğru tepki beklemek. Son koşuda bir tur 65 ms sürdü, zararsız. Gerçek zamanlı döngü (adım 6)
  kartta koşacağı için bu takılmalar oraya taşınmaz; ancak PC'den gerçek zamanlı komut akışı
  hiçbir zaman güvenilir olmaz.

Sıradaki: ESP32 kolunda adım 6 (kart içinde gerçek zamanlı ikiz); araştırma kolunda 5b (kayan
F_c) + 180° deney protokolü. Site Durum satırı 5b yapılınca (5a + 5b + ESP32 birlikte).
