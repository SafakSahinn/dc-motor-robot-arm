# Malzeme listeleri (taslak)

Çalışma notunun 3. aşaması. Liste `mimari.md`'deki mimariden türetilmiştir. Her kalemde model, adet, temel özellik, gerekçe, kaynak, fiyat ve stok verilir. Ayrıca uyum, montaj ihtiyaçları, toplamlar ve kritik alternatifler yer alır.

**Fiyat ve stok doğrulaması: 8 Kasım 2026** (DigiKey, direnc.net, Motorobit), satıcıların kendi sayfalarından. Pazar yeri ve tahmin kalemleri (Hepsiburada, Cimri, baskı hizmeti, hırdavat) 24 Ekim 2026 araştırmasından.
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
| Motor açısı (ince) + kol açısı | AS5600 modülü (markasız) × 2 | **Adafruit AS5600 (#6357) × 2 + diametral mıknatıs** (biri motorun arka milinde, biri kol milinde) | Same Sky AMT222B-V (14 bit) kolda |
| Akım | INA219 modülü, 87,18 TL (direnc.net) | **Adafruit INA228 (#5832)** | Adafruit INA228 |
| Sıcaklık | — | **Adafruit TMP117 (#4821) × 2** | Adafruit TMP117 × 2 |
| Enkoder alıcısı | gerekmez | gerekmez | TI AM26LV32E (RS-422) |

**Ekonomik listenin bugünkü durumu:** yerli stokta güvenli bir sürücü (≥ 2 A) yok; INA219 akım sensörü stokta. Ekonomik liste bu yüzden şu an kurulamıyor. Dengeli listenin elektroniği (≈ 86 $) zaten düşük maliyetli; aradaki farkın büyük kısmı motordan değil kart kalitesinden geliyor.

### 2.1 Dengeli liste: kalem kalem

| # | Kalem (tam model) | Adet | Temel özellik | Seçim gerekçesi | Kaynak | Fiyat | Stok (08.11.2026) |
|---|---|---|---|---|---|---|---|
| E1 | JGB37-520, 12 V, 333 rpm, enkoderli (1:30) | 1 | Durma ≈ 0,49 N·m / 2,3 A; nominal ≈ 0,34 N·m @ 1 A; Hall enkoder 11 darbe/tur → kol tarafında 1320 sayım/tur (0,27°; yüz kestirici için kaba, motor açısını arka mildeki AS5600 ölçer, Hall tur sayımı sağlaması ve yedek); mil 6 mm D. **Veri sayfasıyla doğrulandı** ([direnc.net PDF](https://pdf.direnc.net/upload/jgb37-520-datasheet.pdf), 12 V / 333 rpm satırı): oran 1:30; boşta 120 mA; yükte 3,5 kg·cm (0,34 N·m) @ 1 A, 250 rpm; durma 5 kg·cm (0,49 N·m) / 2,3 A; enkoder besleme **3,3–5 V** (ESP32'nin 3,3 V'u doğrudan yeter, seviye çevirici gerekmez); "motor bir turda 11 sinyal" | Simülasyon bu sınıfla yapıldı; yurtiçinde hemen alınabilir; parametreler tanılanacak | [direnc.net](https://www.direnc.net/jgb37-520-12v-330rpm-enkoderli-motor) | 665,41 TL | Stokta |
| E2 | Pololu #4035 (TI DRV8874) | 1 | 2,1 A sürekli / 6 A tepe; 4,5–37 V; mantık 1,8–5 V; akım ölçüm çıkışı (CS); ayarlanabilir akım sınırı | Durma akımı (2,3 A) TB6612'nin önerilen 1,0 A sınırının çok üstünde; donanım akım sınırı salınım deneylerinde motoru korur | [DigiKey](https://www.digikey.com/en/products/detail/pololu/4035/26714680) → EKOM | 11,94 $ | 288 |
| E3 | Espressif ESP32-DevKitC-32E (WROOM-32E) | 1 | 240 MHz çift çekirdek; PCNT enkoder sayacı; LEDC PWM; iki I²C denetleyicisi; micro-USB | 1 kHz döngü için yeterli; iki I²C hattı TMP117 için gerekli; orijinal kart | [DigiKey](https://www.digikey.com/en/products/detail/espressif-systems/ESP32-DEVKITC-32E/12091810) → EKOM | 10,00 $ | **0** (tahmini 5 Ağustos 2027). Elde ESP32-S (ESP32-D0WD-V3, aynı çip) var ve tüm firmware onda çalışıyor; E3 yalnız yedek anlamında. Stoktaki tek DevKitC türevi ESP32-DEVKITC-VIE (11,00 $, 202 adet) harici anten konektörlü (IPEX), anteni ayrıca gerekir |
| E4 | Adafruit AS5600 (#6357), STEMMA QT | 2 | ams AS5600, 12 bit (0,088°), I²C 1 MHz, adres 0x36 (sabit), filtre SF = 11 ile 0,286 ms gecikme; mıknatıs dahil değil | Biri motorun arka mil ucunda (kontrol: kol tarafında 0,0029°, yüz kestiricinin istediği ≤ 0,02°'yi sağlar, `framing.md` iş sırası 3), biri kol milinde (yalnız doğrulama). Adres aynı olduğundan ayrı I²C hatlarında. Orijinal çip, belgeli kart | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/6357/26832926) → EKOM | 5,95 $ × 2 | 414 |
| E5 | Radial Magnets 8995, NdFeB N35, Ø6 × 2,5 mm, **diametral** | 3 (1 yedek) | Diametral mıknatıslanma; 80 °C | AS5600 diametral mıknatıs ister; Adafruit'in önerdiği disk mıknatıs eksenel, mil ucuna uygun değil | [DigiKey](https://www.digikey.com/en/products/detail/radial-magnets-inc/8995/5126077) → EKOM | 0,40 $ | 57.396 |
| E6 | Adafruit INA228 (#5832), STEMMA QT | 1 | 20 bit ΔΣ ADC; I²C; 85 V ortak mod; ofset ≤ ±1 µV; kazanç hatası ≤ ±%0,05 | Tork kestirimi ve ısınma izleme; INA219'a göre ≈ 15 $ fark, çok daha yüksek çözünürlük | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/5832/21839815) → EKOM | 14,95 $ | 1.791 |
| E7 | Adafruit TMP117 (#4821), STEMMA QT | 2 | ±0,1 °C (−20…50 °C); 16 bit; I²C en fazla 400 kHz; adres 0x48 / 0x49 (ADDR köprüsüyle) | Ortam ve motor gövdesi sıcaklığı (tekrarlanabilirlik, B6) | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/4821/13571586) → EKOM | 11,50 $ × 2 | 720 |
| E8 | Adafruit STEMMA QT / Qwiic kablo, 100 mm (#4210) | 5 | JST SH 4 pin | Sensörleri lehimsiz zincirlemek: I²C-0 ESP32 → motor AS5600 → INA228 (2), I²C-1 ESP32 → kol AS5600 → TMP117 → TMP117 (3) | [DigiKey](https://www.digikey.com/en/products/detail/adafruit-industries-llc/4210/10230021) → EKOM | 0,95 $ × 5 | 28.014 |

### 2.2 Güç ve elektrik

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| P1 | **Masaüstü 12 V adaptör, ≥ 2 A (tercihen 3 A)**: evde varsa o kullanılır | 1 | 12 V DC, regüleli (anahtarlamalı), 5,5 × 2,1 mm jak | Fişe takılır, şebeke kablolaması gerekmez | Evdeki adaptör; yoksa yerel satıcı | 0 TL (evdeki) / 483,94 TL: direnc.net "12V 3A Adaptör - Masa Tipi" (jak ölçüsü sayfada yazmıyor, 5,5 × 2,1 olduğu sipariş öncesi sorulmalı). Diğerleri: MS-36-12 metal kasa 616,53 TL; Mean Well kapalı tip 769,46 TL | Stokta |
| P2 | DC jak, dişi, klemensli (5,5 × 2,1 mm) | 1 | — | Adaptörü DRV8874'ün VM girişine bağlamak | yerel / direnc.net | ≈ 20 TL (doğrulanmadı: direnc.net aramasında klemensli dişi jak çıkmadı, 08.11) | — |
| P4 | Elektrolitik kondansatör 470 µF 25 V | 2 | 8 × 12 mm | DRV8874 VM girişinde ek dolgu (bulk) kondansatörü; ucuz adaptörün dalgalanmasını da bastırır | [direnc.net](https://www.direnc.net/arama?q=470uf+25v) | 2,87 TL × 2 | Stokta |
| P5 | CHINT NP2-BE102 acil stop butonu (NC) | 1 | Metal, mantar başlı | 12 V motor hattında yazılımdan bağımsız kesme | [Motorobit](https://www.motorobit.com/arama?q=acil+stop) | 306,00 TL (255,00 + KDV) | Stokta |
| P6 | Breadboard ya da delikli pertinaks, jumper kablo seti, micro-USB veri kablosu, klemens | 1 set | — | Bağlantılar | yerel / direnc.net | ≈ 250 TL (doğrulanmadı) | — |

**Güç kaynağı seçimi neyi değiştirir?**

| Ölçüt | Gereken | Neden |
|---|---|---|
| Gerilim | **12 V** | Motor 12 V'luk. 9 V gibi düşük gerilim tork payını ve en yüksek hızı azaltır; daha yüksek gerilim motoru zorlar. DRV8874 4,5–37 V kabul eder, sınırlayan motor. |
| Akım | **≥ 2 A, tercihen 3 A** | Sürücünün akım sınırı ≈ 2 A. Salınım deneyleri tipik olarak < 1 A çeker, ama adım anlarında ve durmada akım sınıra kadar çıkar. Modem/router adaptörleri genelde 12 V 1–1,5 A'dir; yetmez. |
| Kalite (dalgalanma, regülasyon) | Regüleli anahtarlamalı adaptör yeterli | Motor gerilimi DRV8874'ün PWM'iyle ve kapalı çevrimle ayarlandığı için besleme dalgalanmasının sonuca etkisi küçük. 470 µF kondansatör yüksek frekanslı dalgalanmayı bastırır. INA228 besleme gerilimini her deneyde kaydettiği için olası bir sapma veride görünür. |
| Tekrarlanabilirlik | Bütün deneylerde aynı adaptör | Adaptör modeli deney meta verisine yazılır. |
| Güvenlik | Masaüstü adaptör en güvenlisi | Panel tipi kaynak (aşağıda) 230 V kablolama ister. |

**Sonuç:** evdeki adaptör, etiketinde 12 V ve en az 2 A yazıyorsa kullanılabilir. Bu araştırma sonucunu değiştirmez; yalnız tork payını ve gürültüyü küçük ölçüde etkiler, o da kayıt altına alınır.

**Alternatif (panel tipi, istenirse):** Mean Well LRS-35-12, 12 V 3 A 36 W ([direnc.net](https://www.direnc.net/12v-3a-kapali-tip-switch-mode-adaptor), 769,46 TL, stokta, 08.11). Klemensleri açık olduğu için Schurter DD11.0111.1111 sigortalı ve anahtarlı IEC giriş ([DigiKey](https://www.digikey.com/en/products/detail/schurter-inc/DD11-0111-1111) → EKOM, 16,04 $, stok 1.173), 1 A gecikmeli sigorta, güç kablosu ve yalıtkan kutu gerekir. İlk seçim olan Mean Well GST36E12-P1J masaüstü adaptör DigiKey'de stokta değil (tahmini 18 Ocak 2027).

## 3. Mekanik: iki seçenek

Ayarlanabilir boşluklu kaplin (dil ve yuva, 0 / 1,5 / 3 / 5°) hazır satılmıyor. Bu yüzden iki seçenekte de özel parça olarak bastırılır.
- **A seçeneği:** gövde, braket ve yataklama hazır parçalardan; yalnız kaplin ve küçük tutucular bastırılır.
- **B seçeneği:** gövde, braket, kaplin, sürtünme diski ve tutucular baskı hizmetiyle; yataklama 608 rulmanla.

### 3.1 Ortak kalemler (A ve B)

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| M1 | 8 mm krom kaplı indüksiyonlu mil, 500 mm | 1 | Ø8, sertleştirilmiş | Kol mili ≈ 120 mm kesilir; kalan yedek | [Motorobit](https://www.motorobit.com/arama?q=8mm+mil) | 244,80 TL (204,00 + KDV) | Stokta (300 / 400 mm boyları tükendi) |
| M2 | Kol–mil bağlantısı: 8 mm hex göbek (setuskurlu) | 1 | 8 mm deliğe setuskurla sıkılır, kol göbeğe cıvatalanır | Kol–mil arasında ek boşluk olmamalı; düz yüzey açılmış mile iki setuskur | [Motorobit](https://www.motorobit.com/arama?q=kaplin) ("8mm Motor Şaftı ile Uyumlu Hex Tekerlek Kaplini") | 122,40 TL (102,00 + KDV) | Stokta |
| M3 | Ayarlanabilir boşluk kaplini: motor tarafı (6 mm D) + kol tarafı (8 mm) + 4 dil parçası (0 / 1,5 / 3 / 5°) | 1 takım | PETG ya da PA12 baskı; setuskurlar için M3 gömme somun | Boşluk düğmesi (framing'in en güçlü düğmesi); 0° parçası motorun kendi boşluğunu ölçmek için | Baskı hizmeti | B seçeneğinin baskı ücretine dahil; A'da ≈ 150–300 TL (doğrulanmadı) | — |
| M4 | Mıknatıs tutucu + AS5600 tutucu: kol mili ucu (setuskurla) ve motor arka mili (Hall disk göbeğine takılan ≈ 5 mm uzatma + motor arka kapağına bağlı sensör tutucu) | 2 + 2 | Baskı | Mıknatısı mil ekseninde ortalamak; hava aralığı 0,5–3 mm; motor tarafında Hall halka mıknatısından ≈ 5 mm uzaklık (`mimari.md` §3) | Baskı hizmeti | M3 ile birlikte | — |
| M5 | Kol: alüminyum lama 20 × 3 mm, ≈ 200 mm | 1 | — | 15 cm etkin boy + göbek ve karşı ağırlık uzantısı | Yerel hırdavat / alüminyumcu | ≈ 50–100 TL. **Pazar araştırması:** Hepsiburada ve Trendyol'da uygun ilan bulunamadı; hırdavat ya da alüminyumcuda boy kesimi. | — |
| M6 | Uç ve karşı ağırlıklar: M8 somun ve rondelalar | 1 set | 20 ve 50 g'a tamamlanır | Kütle hassas terazide tartılır; kalibrasyon ağırlığına gerek kalmaz | Yerel hırdavat | ≈ 50 TL (doğrulanmadı) | — |
| M7 | Hassas terazi, 0,01 g, ≥ 200 g kapasite | 1 | — | Uç kütlesini, kolu ve ağırlıkları tartmak (mgℓ, J_L hesabı) | [Hepsiburada](https://www.hepsiburada.com/ara?q=hassas+terazi+0.01) | ≈ 260–560 TL. **Pazar araştırması:** 200 g / 0,01 g cep terazisi 260 TL; Janva 399 TL; Bydiz BY-500 (500 g / 0,01 g) 559,90 TL. 50 g uç kütlesi ve kol için 500 g kapasite rahat. | Satışta |
| M8 | Sürtünme pabucu: keçe parçası, M3 vida, baskı yayı, sürtünme diski | 1 set | Vidayla ayarlı bastırma kuvveti | L senaryosunda açıdan bağımsız sürtünme eklemek | Yerel + baskı | ≈ 50 TL + baskı (doğrulanmadı) | — |
| M9 | Vida seti: M3 (6–20 mm), M4, M5 ve somunlar | 1 set | Paslanmaz | Montaj | Yerel hırdavat (Motorobit'te M3 boyların çoğu tükendi) | ≈ 150 TL (doğrulanmadı) | — |

### 3.2 A seçeneği: hazır parçalar

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| A1 | KFL08 yataklı rulman (flanşlı, 8 mm) | 2 | İçinde bilyalı rulman ve setuskur | Kol milini gövdeye yataklar; motor yatağı eğilme yükü taşımaz | [Motorobit](https://www.motorobit.com/kfl08-yatakli-rulman-8mm) | 107,10 TL × 2 (89,25 + KDV) | Stokta (100+) |
| A2 | 2020 alüminyum sigma profil (6 kanal), ≈ 1 m (3–4 parçaya kesim) | 1 | Rijit gövde (ilk rezonans ≥ 100 Hz hedefi) | Gövde rijitliği; parçalar T-somunla ayarlanabilir | Yerel sigma profil satıcısı (kesimli) | ≈ 300–600 TL. **Pazar araştırması:** Hepsiburada'da 20 × 20 ilanı yok, yalnız 20 × 80 (350 mm, 489,99 TL) ve 30 × 30 (2 × 20 cm, 349,99 TL); Cimri'de 20 × 20 ilanı 319 TL (birim belirtilmemiş). Profil üreticileri 6 m boy satıyor; kesimli parça için yerel bayiden teklif alınmalı. | — |
| A3 | 2020 köşebent × 8, M5 T-somun × 20, M5 vida × 20 | 1 set | — | Gövde montajı, motor braketi ve KFL08 bağlantısı | Pazar yerleri / profil bayisi | ≈ 640–1.040 TL. **Pazar araştırması:** Cimri'de bağlantı parçaları 49–99 TL/adet, M5 T-somun paketi ≈ 249 TL; Hepsiburada'da M5 T-somun ilanları 189–199 TL; direnc.net'teki M4 T-somun tükendi. Profil bayisinden takım halinde almak daha ucuz olabilir. | — |
| A4 | 37 mm redüktörlü motor için L tipi metal braket | 1 | 6 × M3 motor deliği (31 mm aralık) | Motoru gövdeye hizalı bağlamak | Yurt dışı (AliExpress) | ≈ 2–5 $. **Pazar araştırması:** Türk pazar yerlerinde 37 mm braket bulunamadı (direnc.net'teki Pololu braketi kaldırılmış; Hepsiburada'daki motor braketleri RS775 gibi farklı ölçüler); Hindistan'da ₹99 + KDV, yani ≈ 1,2 $. | — |

### 3.3 B seçeneği: 3B baskı hizmeti

| # | Kalem | Adet | Özellik | Gerekçe | Kaynak | Fiyat | Stok |
|---|---|---|---|---|---|---|---|
| B1 | Baskı parçaları: gövde (taban + iki rulman yuvası), motor braketi, kaplin takımı (M3), tutucular (M4), sürtünme diski (M8) | 1 takım | PETG, %40–60 doluluk; tahmini 250–400 g | Hazır braket ve profil gerekmez; geometri tam istenen gibi | Türkiye'de baskı hizmeti | ≈ 750–2.400 TL. **Pazar araştırması:** 2026 tarihli ticari bir fiyat listesi bulunamadı; firmalar gram başına teklif veriyor (ör. İstanbul'da 3Dörtgen, Armut'taki hizmet verenler). Bir üniversitenin döner sermaye tarifesinde PETG 0,20 mm 6 TL/g (KDV dahil, tarih belirsiz). Ham PETG filament ≈ 0,74 TL/g (1 kg 741 TL). Okulda yazıcı bulunursa maliyet ≈ 200–300 TL'ye iner. | Teklif alınacak |
| B2 | 608-2Z rulman (8 × 22 × 7 mm), SKF ya da NSK | 2 | Metal kapaklı, yağlı | Baskı gövdeye preslenir | [Hepsiburada](https://www.hepsiburada.com/ara?q=skf+608+2z) (direnc.net'teki 608ZZ tükendi) | ≈ 160 TL. **Pazar araştırması:** SKF 608-2Z C3 ikili paket ≈ 159 TL; markasız 608-2RS 10'lu 74,50–399,90 TL. Marka rulman tercih edilir (açıya göre değişen sürtünme olmasın). | Satışta |
| B3 | Isıyla gömülen M3 pirinç insert (M3 × 4 mm) | 20 | — | Baskı parçalarında sökülüp takılabilir vida bağlantısı | [Hepsiburada](https://www.hepsiburada.com/ara?q=m3+insert+3d+yaz%C4%B1c%C4%B1) | ≈ 560 TL. **Pazar araştırması:** 10'lu paket 280 TL (Teknik Filament). Tahminden pahalı çıktı; yurt dışından 100'lü paket ≈ 3–5 $ ya da gömme somun (M3 altıgen somun) tasarımıyla insert ihtiyacı azaltılabilir. | Satışta |

**Rijitlik uyarısı (B seçeneği):** baskı gövde profilden daha esnektir. Gövde kalın duvarlı tasarlanmalı. Montajdan sonra darbe testiyle ilk rezonans ölçülmeli (hedef ≥ 100 Hz, `mimari.md`). Hedef tutmazsa gövde A seçeneğine çevrilir; kaplin ve tutucular aynen kullanılır.

## 4. Uyum kontrolü

| Konu | Değerler | Durum |
|---|---|---|
| Motor gerilimi | Motor 12 V; DRV8874 VM 4,5–37 V; adaptör 12 V | ✓ |
| Akım | Motor durma 2,3 A; DRV8874 2,1 A sürekli / 6 A tepe; akım sınırı ≈ 2 A'e ayarlanır; adaptör ≥ 2 A | ✓ (donanım sınırıyla) |
| Güç | Adaptör ≥ 24 W (12 V × 2 A); sürücünün akım sınırıyla motor en fazla ≈ 24 W çeker; ESP32 ve sensörler USB'den | ✓ |
| Mantık seviyesi | ESP32 3,3 V; DRV8874 mantık 1,8–5 V; Adafruit kartları 3,3 V; enkoder 3,3 V ile beslenecek | ✓ (veri sayfası enkoder beslemesini 3,3–5 V veriyor; seviye çevirici gerekmez) |
| I²C adresleri | Motor AS5600 0x36, INA228 0x40 (I²C-0, 1 MHz); kol AS5600 0x36, TMP117 0x48 ve 0x49 (I²C-1, 400 kHz) | ✓ (iki AS5600 ayrı hatlarda; ikinci TMP117'de ADDR köprüsü) |
| Mil çapları | Motor 6 mm D → kaplin motor tarafı; kol mili 8 mm → KFL08 / 608 / hex göbek / kaplin kol tarafı | ✓ |
| Mıknatıs | Ø6 diametral × 2 → kol mili ucundaki ve motor arka milindeki tutucularda; AS5600 hava aralığı 0,5–3 mm | ✓ (tutucular baskı parçası); motor tarafında Hall sayım/tur montajda kontrol edilir |
| Bağlayıcılar | Adafruit kartları STEMMA QT; ESP32 tarafına STEMMA QT–dişi pin kablosu ya da breadboard | ✓ |

## 5. Montaj ihtiyaçları

- **Takım:** havya ve lehim (pin başlıkları), matkap, eğe (mil üzerine setuskur düzlüğü), metal testere (mil ve lama kesimi), alyan seti, multimetre.
- **Sıra:**
  1. Gövde.
  2. Rulmanlar (KFL08 ya da preslenmiş 608) ve mil; eksen hizası mil–motor arasında kontrol edilir.
  3. Motor braketi ve motor.
  4. Kaplin, önce 0° parçasıyla.
  5. Kol, göbek ve ağırlıklar.
  6. Mıknatıslar ve iki AS5600 (kol mili ucu; motor arka mili).
  7. Sürtünme pabucu.
  8. Mekanik durdurucular.
  9. Elektrik: şebeke tarafı kutuda; 12 V hattında acil stop; ortak toprak.
- **Kontrol:** kaplin 0° ile θ_d genişliği ölçülür. Beklenmeyen bir boşluk varsa kol–mil ya da mıknatıs bağlantısı gözden geçirilir.

## 6. Toplamlar (dengeli elektronik)

| Kalem grubu | Türk firmaları (TL) | EKOM teklifine girecek ($, DigiKey liste) |
|---|---|---|
| Elektronik ve motor (E1–E8) | 665,41 (E1) | 77,74 (E2–E8, ikinci AS5600 ve yedek mıknatıs dahil); E3 çıkarılırsa 67,74 |
| Güç ve elektrik (P1–P6) | ≈ 580 (evdeki adaptörle) – 1.065 (yeni masa tipi adaptörle) | — |
| **Elektronik + güç toplamı** | **≈ 1.250–1.730 TL** | **77,74 $** (E3'süz 67,74 $) + EKOM'un kargo, gümrük ve vergi payı |

Panel tipi Mean Well seçilirse (masa tipi adaptör yerine): + ≈ 290 TL ve + 16,04 $, ayrıca sigorta, kablo ve kutu.

| Mekanik | A: hazır parçalar | B: baskı hizmeti |
|---|---|---|
| Ortak kalemler (M1–M9) | ≈ 1.080–1.580 TL | ≈ 930–1.280 TL (kaplin baskısı B1'e dahil) |
| Seçeneğe özgü | ≈ 1.150–1.850 TL + braket ≈ 2–5 $ | ≈ 1.470–3.120 TL |
| **Mekanik toplam** | **≈ 2.230–3.430 TL + ≈ 2–5 $** | **≈ 2.400–4.400 TL** |

**Genel toplam (dengeli elektronik + mekanik):** A ile ≈ 3.480–5.160 TL + ≈ 80–83 $; B ile ≈ 3.650–6.130 TL + ≈ 78 $ (E3 çıkarılırsa $ kısmından 10 $ düşer). EKOM'un TL teklifi kargo, gümrük ve vergileri içerdiğinden $ kısmı TL'ye çevrildiğinde liste fiyatından yüksek çıkar.

Pazar araştırmasından sonra iki seçeneğin maliyeti birbirine yaklaştı: profil aksesuarları beklenenden pahalı, baskı hizmetinin fiyatı ise teklife bağlı. Seçimi rijitlik ve iş yükü belirlemeli: A daha rijit ve sökülüp takılabilir, B daha az parça tedariki gerektirir.

Aralıkla verilen fiyatlar pazar araştırmasına dayalı tahmindir; sipariş öncesi teklif alınmalı.

## 7. Kritik alternatifler

| Kalem | Alternatif | Ne zaman |
|---|---|---|
| Motor | JGA25-370 1:34 enkoderli (küçük rotor, ω_c 45'e kadar) | Karaköy'de bulunursa |
| Motor | Pololu 37D 30:1, 64 CPR (#4752, 60,95 $) | Enkoder 1,5 kat ince; ithalat gerekir |
| Motor + kol sensörü | maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16 EASY (≈ 472 €) ve Same Sky AMT222B-V (73,72 $, DigiKey stok 672) | Sonuçlar umut verir ve θ_d'nin ince ölçümü gerekirse (üst sınıf). Diğer parçalar aynı kalır. |
| Sürücü | Adafruit DRV8871 (#3190) | DRV8874 bulunamazsa; akım ölçüm çıkışı yok |
| Denetleyici | Teensy 4.1 | İki eklem ya da 5 kHz üstü döngü |
| Güç | Mean Well LRS-35-12 + sigortalı IEC giriş + kutu | Daha düzgün regülasyon istenirse; 230 V kablolama gerekir |
| Gövde | A ↔ B | B'nin rijitliği yetmezse A'ya geçilir |

## 8. Doğrulanamayanlar ve yapılacaklar

- **Pazar araştırmasıyla tahmin edilenler (24.10.2026):** 2020 profil ve aksesuarlar, motor braketi (yurt dışı), baskı hizmeti, alüminyum lama, hırdavat. Kesinleştirmek için bir Türk profil bayisinden kesim fiyatı ve bir baskı hizmetinden gram fiyatı alınacak.
- **Pazar araştırmasıyla netleşenler:** 608-2Z (≈ 160 TL), hassas terazi (260–560 TL), M3 insert (10'lu 280 TL).
- **EKOM teklifi:** E2–E8 DigiKey sepetine eklenip EKOM'a gönderilecek; TL teklif bu listeye işlenecek. Üniversite kurumsal hesabı kullanılabilir mi, danışmana sorulacak.
- **Adaptör:** evdeki adaptörün etiketi kontrol edilecek (12 V, ≥ 2 A).
- ~~**Motor veri sayfası.**~~ **Kapandı (08.11.2026):** direnc.net'in veri sayfası 12 V / 333 rpm için 1:30 oranını, 0,34 / 0,49 N·m'yi ve 3,3–5 V enkoder beslemesini doğruluyor (E1). Gelen ürünün etiketi yine kontrol edilir; ürün sayfasındaki "21KG" ve "0,08–0,15 A" ifadeleri veri sayfasıyla uyuşmuyor, veri sayfası esas alındı.
- **E3 stokta yok (08.11.2026):** ESP32-DevKitC-32E DigiKey'de 0 adet (tahmini Ağustos 2027). Eldeki ESP32-S yeterli; yedek alınıp alınmayacağı kullanıcı kararı.
- **Adaptör jak ölçüsü:** direnc.net masa tipi 12 V 3 A adaptörün sayfasında jak ölçüsü yok; yeni adaptör alınırsa sorulacak.
