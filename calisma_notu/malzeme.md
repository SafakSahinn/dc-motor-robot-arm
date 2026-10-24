# Malzeme listeleri (taslak)

Çalışma notunun 3. aşaması. Liste `mimari.md`'deki mimariden türetilmiştir. Her kalemde model, adet, temel özellik, gerekçe, kaynak, fiyat ve stok verilir. Ayrıca uyum, montaj ihtiyaçları, toplamlar ve kritik alternatifler yer alır.

**Fiyat ve stok doğrulaması: 24 Ekim 2026**, satıcıların kendi sayfalarından.
- TL fiyatları KDV dahildir (satıcı "+ KDV" yazıyorsa %20 eklendi).
- $ fiyatları DigiKey liste fiyatıdır (1 adet, KDV ve gümrük hariç).
- "Doğrulanmadı" yazan kalemlerin fiyatı tahmindir; sipariş öncesi kontrol edilmeli.

**Kaynak önceliği:** önce Türk firmaları, bulunamazsa yurt dışı.

## 1. Satın alma kanalları

| Kanal | Ne alınır | Not |
|---|---|---|
| **EKOM** (İstanbul), DigiKey'in Türkiye yetkili ortağı | Adafruit, Pololu, Espressif, Schurter, Radial Magnets kalemleri | DigiKey sepeti EKOM'a iletilir. EKOM kargo, gümrük ve vergiler dahil TL teklif verir; TL ile kredi kartı ya da havale; teslim ortalama 7 iş günü. **Üniversiteler kurumsal hesapla ödeme vadesi alabilir.** Ürünler DigiKey üzerinden üreticiden gelir (orijinal). İletişim: +90 212 590 97 15, info@e-kom.com |
| **direnc.net** | Motor, güç kaynağı, pasif elemanlar | Stokta olanlar "Sepete ekle" ile görünür |
| **Motorobit** | Mil, yataklı rulman, göbek, acil stop | Fiyatlar "+ KDV"; stok "Sepete ekle / Tükendi" ile görünür |
| Pazar yerleri (Trendyol vb.) | Hassas terazi, profil aksesuarları | Satıcı kalitesi değişken |
| Yerel hırdavat / rulmancı | Alüminyum lama, vida, keçe, 608 rulman | Online stok bilgisi yok |
| Yurt dışı (AliExpress) | Yalnızca Türkiye'de bulunamayan: 37 mm motor braketi | Teslim 2–4 hafta |

Türk elektronik mağazalarında (direnc.net, Robotistan) INA228, TMP117, Adafruit AS5600 ve Pololu DRV8874 bulunamadı. Bu kalemler EKOM üzerinden Türkiye'den alınabiliyor.

## 2. Elektronik: üç seviye

✅ = önerilen (dengeli) liste.

| Görev | Ekonomik (yerli, markasız) | ✅ Dengeli | Üst sınıf |
|---|---|---|---|
| Motor + enkoder | JGB37-520 12 V 1:30 | **JGB37-520 12 V 1:30** | maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16 EASY 1024 |
| Motor sürücü | Yerli ≥ 2 A modül: BTS7960 **tükendi** (direnc.net) | **Pololu DRV8874 (#4035)** | Pololu DRV8874 |
| Denetleyici | Genel ESP32 DevKit | **Espressif ESP32-DevKitC-32E** | Espressif ESP32-DevKitC-32E |
| Kol açısı | AS5600 modülü (markasız) | **Adafruit AS5600 (#6357) + diametral mıknatıs** | Same Sky AMT222B-V (14 bit) |
| Akım | INA219 modülü: **tükendi** (direnc.net) | **Adafruit INA228 (#5832)** | Adafruit INA228 |
| Sıcaklık | — | **Adafruit TMP117 (#4821) × 2** | Adafruit TMP117 × 2 |
| Enkoder alıcısı | gerekmez | gerekmez | TI AM26LV32E (RS-422) |

**Ekonomik listenin bugünkü durumu:** yerli stokta güvenli bir sürücü (≥ 2 A) ve akım sensörü yok. Ekonomik liste bu yüzden şu an kurulamıyor. Dengeli listenin elektroniği (≈ 86 $) zaten düşük maliyetli; aradaki farkın büyük kısmı motordan değil kart kalitesinden geliyor.

### 2.1 Dengeli liste: kalem kalem

| # | Kalem (tam model) | Adet | Temel özellik | Seçim gerekçesi | Kaynak | Fiyat | Stok (24.10.2026) |
|---|---|---|---|---|---|---|---|
| E1 | JGB37-520, 12 V, 333 rpm, enkoderli (1:30) | 1 | Durma ≈ 0,49 N·m / 2,3 A; nominal ≈ 0,34 N·m @ 1 A; Hall enkoder 11 darbe/tur → kol tarafında 1320 sayım/tur (0,27°); mil 6 mm D | Simülasyon bu sınıfla yapıldı; yurtiçinde hemen alınabilir; parametreler tanılanacak | [direnc.net](https://www.direnc.net/jgb37-520-12v-330rpm-enkoderli-motor) | 639,29 TL | Stokta |
| E2 | Pololu #4035 (TI DRV8874) | 1 | 2,1 A sürekli / 6 A tepe; 4,5–37 V; mantık 1,8–5 V; akım ölçüm çıkışı (CS); ayarlanabilir akım sınırı | Durma akımı (2,3 A) TB6612'nin önerilen 1,0 A sınırının çok üstünde; donanım akım sınırı salınım deneylerinde motoru korur | [DigiKey](https://www.digikey.com/en/products/detail/pololu/4035/26714680) → EKOM | 11,94 $ | 313 |
| E3 | Espressif ESP32-DevKitC-32E (WROOM-32E) | 1 | 240 MHz çift çekirdek; PCNT enkoder sayacı; LEDC PWM; iki I²C denetleyicisi; micro-USB | 1 kHz döngü için yeterli; iki I²C hattı TMP117 için gerekli; orijinal kart | [DigiKey](https://www.digikey.com/en/products/detail/espressif-systems/ESP32-DEVKITC-32E/12091810) → EKOM | 10,00 $ | 731 |
| E4 | Adafruit AS5600 (#6357), STEMMA QT | 1 | ams AS5600, 12 bit (0,088°), I²C 1 MHz, filtre SF = 11 ile 0,286 ms gecikme; mıknatıs dahil değil | Orijinal çip, belgeli kart; motor enkoderinden üç kat ince (θ_d'yi motor enkoderi sınırlar) | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/6357/26832926) → EKOM | 5,95 $ | 527 |
| E5 | Radial Magnets 8995, NdFeB N35, Ø6 × 2,5 mm, **diametral** | 2 (1 yedek) | Diametral mıknatıslanma; 80 °C | AS5600 diametral mıknatıs ister; Adafruit'in önerdiği disk mıknatıs eksenel, mil ucuna uygun değil | [DigiKey](https://www.digikey.com/en/products/detail/radial-magnets-inc/8995/5126077) → EKOM | 0,40 $ | 34.505 |
| E6 | Adafruit INA228 (#5832), STEMMA QT | 1 | 20 bit ΔΣ ADC; I²C; 85 V ortak mod; ofset ≤ ±1 µV; kazanç hatası ≤ ±%0,05 | Tork kestirimi ve ısınma izleme; INA219'a göre ≈ 15 $ fark, çok daha yüksek çözünürlük | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/5832/21839815) → EKOM | 14,95 $ | 2.008 |
| E7 | Adafruit TMP117 (#4821), STEMMA QT | 2 | ±0,1 °C (−20…50 °C); 16 bit; I²C en fazla 400 kHz; adres 0x48 / 0x49 (ADDR köprüsüyle) | Ortam ve motor gövdesi sıcaklığı (tekrarlanabilirlik, B6) | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/4821/13571586) → EKOM | 11,50 $ × 2 | 857 |
| E8 | Adafruit STEMMA QT / Qwiic kablo, 100 mm (#4210) | 4 | JST SH 4 pin | Sensörleri lehimsiz bağlamak; iki ayrı I²C hattı | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/4210/10230021) → EKOM | 0,95 $ × 4 | 17.903 |

### 2.2 Güç ve elektrik

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| P1 | **Mean Well LRS-35-12** (kapalı tip) | 1 | 12 V 3 A 36 W; 85–264 VAC; kısa devre, aşırı yük ve aşırı gerilim koruması | Bilinen marka, düşük dalgalanma. Önceki seçim GST36E12-P1J masaüstü adaptör DigiKey'de stokta değil (tahmini 18 Ocak 2027) | [direnc.net](https://www.direnc.net/12v-3a-kapali-tip-switch-mode-adaptor) | 739,26 TL | Stokta |
| P2 | Schurter DD11.0111.1111 (IEC C14 giriş, sigorta yuvası, 2 kutuplu anahtar) | 1 | Panel tipi şebeke girişi | LRS-35-12 açık klemensli; şebeke girişi sigortalı ve anahtarlı olmalı | [DigiKey](https://www.digikey.com/en/products/detail/schurter-inc/DD11-0111-1111) → EKOM | 16,04 $ | 1.173 |
| P3 | 5 × 20 mm sigorta, 1 A gecikmeli + IEC C13 güç kablosu | 1 + 1 | — | P2 için | yerel / direnc.net | ≈ 50 TL (doğrulanmadı) | — |
| P4 | Elektrolitik kondansatör 470 µF 25 V | 2 | 8 × 12 mm | DRV8874 VM girişinde ek dolgu (bulk) kondansatörü | [direnc.net](https://www.direnc.net/arama?q=470uf+25v) | 2,32 TL × 2 | Stokta |
| P5 | CHINT NP2-BE102 acil stop butonu (NC) | 1 | Metal, mantar başlı | 12 V motor hattında yazılımdan bağımsız kesme | [Motorobit](https://www.motorobit.com/arama?q=acil+stop) | 303,00 TL | Stokta |
| P6 | Breadboard ya da delikli pertinaks, jumper kablo seti, micro-USB veri kablosu, klemens | 1 set | — | Bağlantılar | yerel / direnc.net | ≈ 250 TL (doğrulanmadı) | — |

**Güvenlik notu:** LRS-35-12 kapalı tip ama klemensleri açık (230 V). Şebeke tarafı yalıtkan bir kutuya ya da baskı kapağa alınır; topraklama klemensi bağlanır. Şebeke kablolaması istenmezse alternatif: aynı güçte hazır masaüstü 12 V 3 A adaptör (P1'in yerine; P2 ve P3 gerekmez).

## 3. Mekanik: iki seçenek

Ayarlanabilir boşluklu kaplin (dil ve yuva, 0 / 1,5 / 3 / 5°) hazır satılmıyor. Bu yüzden iki seçenekte de özel parça olarak bastırılır.
- **A seçeneği:** gövde, braket ve yataklama hazır parçalardan; yalnız kaplin ve küçük tutucular bastırılır.
- **B seçeneği:** gövde, braket, kaplin, sürtünme diski ve tutucular baskı hizmetiyle; yataklama 608 rulmanla.

### 3.1 Ortak kalemler (A ve B)

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| M1 | 8 mm krom kaplı indüksiyonlu mil, 500 mm | 1 | Ø8, sertleştirilmiş | Kol mili ≈ 120 mm kesilir; kalan yedek | [Motorobit](https://www.motorobit.com/arama?q=8mm+mil) | 242,40 TL | Stokta (300 / 400 mm boyları tükendi) |
| M2 | Kol–mil bağlantısı: 8 mm hex göbek (setuskurlu) | 1 | 8 mm deliğe setuskurla sıkılır, kol göbeğe cıvatalanır | Kol–mil arasında ek boşluk olmamalı; düz yüzey açılmış mile iki setuskur | [Motorobit](https://www.motorobit.com/arama?q=kaplin) ("8mm Motor Şaftı ile Uyumlu Hex Tekerlek Kaplini") | 121,20 TL | Stokta |
| M3 | Ayarlanabilir boşluk kaplini: motor tarafı (6 mm D) + kol tarafı (8 mm) + 4 dil parçası (0 / 1,5 / 3 / 5°) | 1 takım | PETG ya da PA12 baskı; setuskurlar için M3 gömme somun | Boşluk düğmesi (framing'in en güçlü düğmesi); 0° parçası motorun kendi boşluğunu ölçmek için | Baskı hizmeti | B seçeneğinin baskı ücretine dahil; A'da ≈ 150–300 TL (doğrulanmadı) | — |
| M4 | Mıknatıs tutucu (mil ucuna setuskurla) + AS5600 tutucu | 1 + 1 | Baskı | Mıknatısı mil ekseninde ortalamak; hava aralığı 0,5–3 mm | Baskı hizmeti | M3 ile birlikte | — |
| M5 | Kol: alüminyum lama 20 × 3 mm, ≈ 200 mm | 1 | — | 15 cm etkin boy + göbek ve karşı ağırlık uzantısı | Yerel hırdavat | ≈ 50–100 TL (doğrulanmadı) | — |
| M6 | Uç ve karşı ağırlıklar: M8 somun ve rondelalar | 1 set | 20 ve 50 g'a tamamlanır | Kütle hassas terazide tartılır; kalibrasyon ağırlığına gerek kalmaz | Yerel hırdavat | ≈ 50 TL (doğrulanmadı) | — |
| M7 | Hassas terazi, 0,01 g (ör. bydiz MH-999, 1 kg) | 1 | — | Uç kütlesini, kolu ve ağırlıkları tartmak (mgℓ, J_L hesabı) | [Trendyol](https://www.trendyol.com/sr?q=hassas%20terazi%200.01) | ≈ 300–600 TL (doğrulanmadı) | Satışta |
| M8 | Sürtünme pabucu: keçe parçası, M3 vida, baskı yayı, sürtünme diski | 1 set | Vidayla ayarlı bastırma kuvveti | L senaryosunda açıdan bağımsız sürtünme eklemek | Yerel + baskı | ≈ 50 TL + baskı (doğrulanmadı) | — |
| M9 | Vida seti: M3 (6–20 mm), M4, M5 ve somunlar | 1 set | Paslanmaz | Montaj | Yerel hırdavat (Motorobit'te M3 boyların çoğu tükendi) | ≈ 150 TL (doğrulanmadı) | — |

### 3.2 A seçeneği: hazır parçalar

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| A1 | KFL08 yataklı rulman (flanşlı, 8 mm) | 2 | İçinde bilyalı rulman ve setuskur | Kol milini gövdeye yataklar; motor yatağı eğilme yükü taşımaz | [Motorobit](https://www.motorobit.com/kfl08-yatakli-rulman-8mm) | 106,06 TL × 2 | Stokta |
| A2 | 2020 alüminyum sigma profil (6 kanal), ≈ 1 m (3–4 parçaya kesim) | 1 | Rijit gövde (ilk rezonans ≥ 100 Hz hedefi) | Gövde rijitliği; parçalar T-somunla ayarlanabilir | Türk profil satıcıları / pazar yerleri | ≈ 300–600 TL (doğrulanmadı) | — |
| A3 | 2020 köşebent × 8, M5 T-somun × 20, M5 vida × 20 | 1 set | — | Gövde montajı, motor braketi ve KFL08 bağlantısı | Pazar yerleri (direnc.net'teki M4 T-somun tükendi) | ≈ 300 TL (doğrulanmadı) | — |
| A4 | 37 mm redüktörlü motor için L tipi metal braket | 1 | 6 × M3 motor deliği (31 mm aralık) | Motoru gövdeye hizalı bağlamak | Yurt dışı (AliExpress). Türkiye'de bulunamadı: direnc.net'teki Pololu braketi kaldırılmış | ≈ 2–5 $ (doğrulanmadı) | — |

### 3.3 B seçeneği: 3B baskı hizmeti

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| B1 | Baskı parçaları: gövde (taban + iki rulman yuvası), motor braketi, kaplin takımı (M3), tutucular (M4), sürtünme diski (M8) | 1 takım | PETG, %40–60 doluluk; tahmini 250–400 g | Hazır braket ve profil gerekmez; geometri tam istenen gibi | Türkiye'de baskı hizmeti (ör. İstanbul'da gram başına teklif veren firmalar) | ≈ 750–2.400 TL (doğrulanmadı; referans 3–6 TL/g) | Teklif alınacak |
| B2 | 608-2Z rulman (8 × 22 × 7 mm), SKF ya da NSK | 2 | Kapaklı, yağlı | Baskı gövdeye preslenir | Yerel rulmancı (direnc.net'teki 608ZZ tükendi) | ≈ 100–250 TL (doğrulanmadı) | — |
| B3 | Isıyla gömülen M3 dişli insert | 20 | — | Baskı parçalarında sökülüp takılabilir vida bağlantısı | Pazar yerleri | ≈ 100 TL (doğrulanmadı) | — |

**Rijitlik uyarısı (B seçeneği):** baskı gövde profilden daha esnektir. Gövde kalın duvarlı tasarlanmalı. Montajdan sonra darbe testiyle ilk rezonans ölçülmeli (hedef ≥ 100 Hz, `mimari.md`). Hedef tutmazsa gövde A seçeneğine çevrilir; kaplin ve tutucular aynen kullanılır.

## 4. Uyum kontrolü

| Konu | Değerler | Durum |
|---|---|---|
| Motor gerilimi | Motor 12 V; DRV8874 VM 4,5–37 V; kaynak 12 V | ✓ |
| Akım | Motor durma 2,3 A; DRV8874 2,1 A sürekli / 6 A tepe; akım sınırı ≈ 2 A'e ayarlanır | ✓ (donanım sınırıyla) |
| Güç | Kaynak 36 W; motor durmada ≈ 28 W; ESP32 ve sensörler USB'den | ✓ |
| Mantık seviyesi | ESP32 3,3 V; DRV8874 mantık 1,8–5 V; Adafruit kartları 3,3 V; enkoder 3,3 V ile beslenecek | ✓ (enkoderin 3,3 V'ta çalıştığı montajda doğrulanacak; değilse seviye çevirici) |
| I²C adresleri | AS5600 0x36, INA228 0x40 (I²C-0, 1 MHz); TMP117 0x48 ve 0x49 (I²C-1, 400 kHz) | ✓ (ikinci TMP117'de ADDR köprüsü) |
| Mil çapları | Motor 6 mm D → kaplin motor tarafı; kol mili 8 mm → KFL08 / 608 / hex göbek / kaplin kol tarafı | ✓ |
| Mıknatıs | Ø6 diametral → mil ucundaki tutucuda; AS5600 hava aralığı 0,5–3 mm | ✓ (tutucu baskı parçası) |
| Bağlayıcılar | Adafruit kartları STEMMA QT; ESP32 tarafına STEMMA QT–dişi pin kablosu ya da breadboard | ✓ |

## 5. Montaj ihtiyaçları

- **Takım:** havya ve lehim (pin başlıkları), matkap, eğe (mil üzerine setuskur düzlüğü), metal testere (mil ve lama kesimi), alyan seti, multimetre.
- **Sıra:**
  1. Gövde.
  2. Rulmanlar (KFL08 ya da preslenmiş 608) ve mil; eksen hizası mil–motor arasında kontrol edilir.
  3. Motor braketi ve motor.
  4. Kaplin, önce 0° parçasıyla.
  5. Kol, göbek ve ağırlıklar.
  6. Mıknatıs ve AS5600.
  7. Sürtünme pabucu.
  8. Mekanik durdurucular.
  9. Elektrik: şebeke tarafı kutuda; 12 V hattında acil stop; ortak toprak.
- **Kontrol:** kaplin 0° ile θ_d genişliği ölçülür. Beklenmeyen bir boşluk varsa kol–mil ya da mıknatıs bağlantısı gözden geçirilir.

## 6. Toplamlar (dengeli elektronik)

| Kalem grubu | Türk firmaları (TL) | EKOM teklifine girecek ($, DigiKey liste) |
|---|---|---|
| Elektronik ve motor (E1–E8) | 639,29 (E1) | 70,44 (E2–E8, yedek mıknatıs dahil) |
| Güç ve elektrik (P1–P6) | ≈ 1.347 (P3 ve P6 tahmini) | 16,04 (P2) |
| **Elektronik + güç toplamı** | **≈ 1.986 TL** | **86,48 $** + EKOM'un kargo, gümrük ve vergi payı |

| Mekanik | A: hazır parçalar | B: baskı hizmeti |
|---|---|---|
| Ortak kalemler (M1–M9) | ≈ 1.110–1.610 TL | ≈ 960–1.310 TL (kaplin baskısı B1'e dahil) |
| Seçeneğe özgü | ≈ 810–1.110 TL + braket ≈ 2–5 $ | ≈ 950–2.750 TL |
| **Mekanik toplam** | **≈ 1.920–2.720 TL + ≈ 2–5 $** | **≈ 1.910–4.060 TL** |

**Genel toplam (dengeli elektronik + mekanik):** A ile ≈ 3.900–4.710 TL + ≈ 88–91 $; B ile ≈ 3.900–6.050 TL + ≈ 86 $. EKOM'un TL teklifi kargo, gümrük ve vergileri içerdiğinden $ kısmı TL'ye çevrildiğinde liste fiyatından yüksek çıkar.

Fiyatı doğrulanmamış kalemler aralıklarla verildi; sipariş öncesi bu kalemler için teklif alınmalı.

## 7. Kritik alternatifler

| Kalem | Alternatif | Ne zaman |
|---|---|---|
| Motor | JGA25-370 1:34 enkoderli (küçük rotor, ω_c 45'e kadar) | Karaköy'de bulunursa |
| Motor | Pololu 37D 30:1, 64 CPR (#4752, 60,95 $) | Enkoder 1,5 kat ince; ithalat gerekir |
| Motor + kol sensörü | maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16 EASY (≈ 472 €) ve Same Sky AMT222B-V (73,72 $, DigiKey stok 672) | Sonuçlar umut verir ve θ_d'nin ince ölçümü gerekirse (üst sınıf). Diğer parçalar aynı kalır. |
| Sürücü | Adafruit DRV8871 (#3190) | DRV8874 bulunamazsa; akım ölçüm çıkışı yok |
| Denetleyici | Teensy 4.1 | İki eklem ya da 5 kHz üstü döngü |
| Güç | Hazır masaüstü 12 V 3 A adaptör | Şebeke kablolaması istenmezse |
| Gövde | A ↔ B | B'nin rijitliği yetmezse A'ya geçilir |

## 8. Doğrulanamayanlar ve yapılacaklar

- **Fiyatı doğrulanmadı:** 2020 profil ve aksesuarlar, motor braketi (yurt dışı), baskı hizmeti, 608-2Z, hassas terazi, hırdavat kalemleri. Sipariş öncesi bir Türk profil satıcısından kesim fiyatı ve bir baskı hizmetinden gram fiyatı alınacak.
- **EKOM teklifi:** E2–E8 ve P2 DigiKey sepetine eklenip EKOM'a gönderilecek; TL teklif bu listeye işlenecek. Üniversite kurumsal hesabı kullanılabilir mi, danışmana sorulacak.
- **Motor veri sayfası:** direnc.net sayfası dişli oranını ve enkoder ayrıntısını vermiyor; veri sayfasından (ve gelen ürünün etiketinden) 1:30 oranı ve enkoder besleme gerilimi doğrulanacak.
