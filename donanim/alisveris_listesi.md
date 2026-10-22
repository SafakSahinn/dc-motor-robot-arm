# Alışveriş listesi

Her görev için değerlendirilen bütün parçalar, fiyatları ve seçilme ya da elenme nedenleriyle. Seçim ilkesi: **bilinen üretici, eksiksiz veri sayfası, yetkili satıcı; çözünürlük ve doğruluk ölçülen boşluğun (1,5–5°) çok altında.** Ayrıntılı gerekçeler: [`tasarim_kararlari.md`](tasarim_kararlari.md).

Fiyatlar üretici ya da yetkili satıcı sitelerindeki liste fiyatları; aksi yazmadıkça KDV, kargo ve gümrük hariç, 1 adet. Fiyatlar değişebilir. Fiyatı bulunamayanlarda "teklif" yazıyor. ✅ = seçilen.

---

## Toplam maliyet

| Düzen | Motor | Diğer parçalar | Toplam (yaklaşık) | Not |
|---|---|---|---|---|
| ✅ **Seçilen** | maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16 1024: ≈ 472 € | ≈ 13 € + ≈ 136 $ + küçük parçalar | **≈ 485 € + 136 $** | Her parametre belgeli; en ince enkoder; dişli boşluğu 0,85° |
| maxon, standart dişli | DCX 22 L + GPX 22 A 21:1 + ENX 16: ≈ 436 € | aynı | ≈ 449 € + 136 $ | 36 € daha ucuz; dişli boşluğu 1,05° |
| Ekonomik, bilinen marka | Pololu 37D 30:1, 64 CPR: 60,95 $ | aynı | ≈ 13 € + 197 $ | Enkoder kaba (0,19°); dişli boşluğu ve rotor eylemsizliği belgesiz; durma akımı 5,5 A |

"Diğer parçalar": ESP32-DevKitC ≈ 13 €, DRV8874 × 2 = 23,88 $, AMT22 73,72 $, INA228 14,95 $, TMP117 × 2 = 23,00 $; ayrıca AM26LV32E, Mean Well adaptör, rulman, mil, vida ve 3B baskı.

---

## 1. Motor, dişli kutusu ve enkoder

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **maxon** DCX 22 L 12 V + GPX 22 LZ 26:1 + ENX 16 EASY 1024 CPT | Durma 150 mN·m / 6,54 A; dişli 0,7 N·m sürekli, boşluk 0,85°; çıkışta ≈ 106.500 sayım/tur (0,0034°) | 220,41 + 150,63 + 101,05 ≈ **472 €** | **Seçildi.** Bütün parametreler katalogda (R, L, k_t, rotor eylemsizliği); dişli boşluğu küçük ve belgeli. Eksi: pahalı, Türkiye satış ortağı yok, enkoder RS-422 |
| maxon, aynı motor + GPX 22 A (standart) 21:1 | Boşluk 1,05°, 0,7 N·m sürekli | dişli 114,21 € (toplam ≈ 436 €) | Tasarruf seçeneği; dişlinin kendi boşluğu biraz daha büyük |
| Faulhaber 2232 SR + 20/1R + IEH2-4096 | Faulhaber'in eşleşen takımı; enkoder 4096 çizgi/tur | motor ≈ 112 € (bayi); dişli + enkoder: teklif | maxon ile aynı sınıf; tam takım fiyatı bulunamadı, teklif istenebilir |
| Pololu 37D 12 V 30:1, 64 CPR (#4752) | Durma ≈ 14 kg·cm / 5,5 A (tahmini); çıkışta 1920 sayım/tur (0,19°); düz + helis dişli | **60,95 $** | Ekonomik orta yol; dişli boşluğu ve rotor eylemsizliği belirtilmemiş, enkoder maxon'dan ≈ 55 kat kaba |
| JGB37-520 12 V 1:30 (direnc.net) | Durma 5 kg·cm / 2,3 A; 11 darbe/tur (çıkışta 1320, 0,27°) | 639 TL | Elendi: markasız, veri sayfası kısmi, büyük rotor |
| JGA25-370 12 V 1:34 | Durma ≈ 0,41 N·m (tedarikçiye göre değişiyor); 11 darbe/tur | Türkiye'de enkoderli sürümü yok | Elendi: markasız, veriler tutarsız, tork sınırda |
| SAMM L tipi 12 V 1:42 | Durma ≥ 8,5 kg·cm; 13 darbe/tur | ≈ 826 TL | Elendi: stokta yoktu, enkoder kaba |
| Hobi servo (SG90, MG996R) | İçinde hazır konum kontrolcüsü | — | Elendi: kendi kontrolcümüzü devre dışı bırakır |

Kaynaklar: [DCX 22 L](https://www.maxongroup.com/maxon/view/product/motor/dcmotor/DCX/DCX22/DCX22L01EBSL703) · [DCX 22 L katalog (12 V sargı)](https://www.maxongroup.com/medias/sys_master/root/8992307871774/EN-22-109.pdf) · [GPX 22 LZ 26:1](https://www.maxongroup.com/maxon/view/product/gear/planetary/GPX/GPX22/GPX22-2-Stufig-LZ/GPX22LZKLSL26D0CPLW) · [GPX 22 A 21:1](https://www.maxongroup.com/maxon/view/product/gear/planetary/GPX/GPX22/GPX22-2-Stufig-A/GPX22AAKLSL21D0CPLW) · [ENX 16 EASY](https://www.maxongroup.com/maxon/view/product/ENX16EASY06) · [Faulhaber 2232 SR veri sayfası](https://www.faulhaber.com/fileadmin/Import/Media/EN_2232_SR_DFF.pdf) · [Pololu 37D #4752](https://www.pololu.com/product/4752) · [JGB37-520](https://www.direnc.net/jgb37-520-12v-330rpm-enkoderli-motor) · [SAMM L tipi](https://market.samm.com/en/l-tipi-enkoderli-metal-disli-dc-motor)

**maxon siparişi:** dişli kutusu ve enkoder yalnızca motorla birlikte, "kombinasyon" olarak satılıyor (maxon çevrimiçi mağaza → "Start combination"). Yapılandırıcıda kontrol edilecekler: 12 V sargının seçilen fırça/yatak seçeneğinde bulunması, GPX 22 çıkış mili çapı (kaplin tasarımı için), enkoder kablosu, Türkiye'ye gönderim ve teslim süresi.

## 2. Geliştirme kartı (denetleyici)

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **Espressif ESP32-DevKitC** (WROOM-32E) | 240 MHz çift çekirdek, tek duyarlıklı FPU, donanım enkoder sayacı (PCNT), Wi-Fi | ≈ 13 € (KDV dahil, Conrad) | **Seçildi.** 1 kHz döngü, bir motor enkoderi, SPI/I²C sensörler için rahat; Wi-Fi IoT için hazır. Eksi: double yavaş; Wi-Fi döngü zamanlamasını bozabilir (ayrı çekirdeğe sabitlenecek) |
| Espressif ESP32-S3-DevKitC-1 (N8) | 240 MHz çift çekirdek, vektör komutları, dahili USB | 15,95 $ (Adafruit) | Güçlü alternatif; bizim iş yükümüzde belirgin üstünlüğü yok |
| Teensy 4.1 (PJRC / SparkFun) | 600 MHz Cortex-M7, çift duyarlıklı FPU, 4 donanım enkoder çözücüsü, Ethernet | 31,50 $ (SparkFun) | Yükseltme yolu: iki eklem ve 5–10 kHz döngüde kontrol buraya taşınır, ESP32 IoT için kalır |
| STM32 Nucleo-G474RE (ST) | 170 MHz Cortex-M4F, motor kontrolüne özel zamanlayıcılar, donanım enkoder arayüzü | 20,13 $ (DigiKey) | Endüstride motor kontrolü standardı; kurulumu ve öğrenmesi daha zahmetli |
| Arduino Uno R3 / R4 Minima | R3: 8 bit 16 MHz, 2 KB RAM; R4 Minima: 48 MHz Cortex-M4 | R4 Minima ≈ 23 € (KDV dahil) | Elendi: 1 kHz döngü + gözlemci + veri kaydı için sınırda |

Kaynaklar: [Teensy 4.1](https://www.pjrc.com/store/teensy41.html) · [SparkFun Teensy](https://www.sparkfun.com/development-boards/microcontrollers/teensy.html) · [Nucleo-G474RE, DigiKey](https://www.digikey.com/en/products/detail/stmicroelectronics/NUCLEO-G474RE/10231585) · [ESP32-S3-DevKitC-1, Adafruit](https://www.adafruit.com/product/5312) · [Conrad (ESP32-DevKitC, Uno R4)](https://www.conrad.com/en/o/microcontroller-boards-kits-mcu-2420148.html) · [ESP32 PCNT](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/peripherals/pcnt.html)

## 3. Motor sürücü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **Pololu #4035** (TI DRV8874) | 2,1 A sürekli, 4,5–37 V, akım ölçüm çıkışı (≈ 1,1 V/A), ayarlanabilir akım sınırı | 11,94 $ (× 2 = 23,88 $) | **Seçildi.** Nominal 1,3 A'e pay; akım sınırı ≈ 2 A. İkinci kart yedek / ikinci eklem |
| Adafruit DRV8871 (#3190) | Tek kanal, ≈ 3,6 A tepe, direnç ile akım sınırı | ≈ 10,4–11,6 $ (Mouser) | Yedek seçenek; akım ölçüm çıkışı yok |
| Pololu TB6612FNG (#713) | 2 kanal, 1 A sürekli; Toshiba: 1,2 A mutlak sınır, önerilen ≤ 1,0 A | 4,95 $ | Elendi: motorun nominal akımı 1,3 A; akım ölçümü yok |
| L298N modülü | Bipolar, ≈ 2–3 V kayıp | — | Elendi: kayıp gerilim akıma göre değişir, ısınır |
| BTS7960 modülü | 40 A sınıfı | — | Elendi: gereğinden çok büyük, markasız |

Kaynaklar: [Pololu #4035](https://www.pololu.com/product/4035) · [Pololu #713](https://www.pololu.com/product/713) · [Toshiba TB6612FNG veri sayfası](https://toshiba.semicon-storage.com/info/docget.jsp?did=10660)

## 4. Kol açısı sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **Same Sky (CUI) AMT22**, 14 bit tek tur (**AMT222B-V**) | 14 bit (0,022°), ±0,2° doğruluk, SPI 2 MHz, 100 µs, mile manşonla (2–8 mm), 5 V besleme / 3,3 V çıkış | 73,72 $ (DigiKey) | **Seçildi.** Doğruluk üretici garantisinde, mıknatıs hizasına bağlı değil |
| ams OSRAM AS5047P + adaptör (AS5047P-TS_EK_AB) | 14 bit, SPI + ABI, çok düşük gecikme (DAEC) | ≈ 16,7 $ – 21,7 € (stok sorunlu) | İyi ve ucuz; doğruluk mıknatıs hizasına bağlı; adaptör bazı satıcılarda üretimden kalkmış |
| AS5600 modülü | 12 bit, I²C | ≈ 258 TL | Elendi: markasız, doğruluk belgesiz, çözünürlük 4 kat düşük |
| Yüksek sınıf mutlak enkoder (ör. RLS AksIM-2) | 18–20 bit | teklif | Gereğinden hassas ve pahalı |

Kaynaklar: [AMT222B-V, DigiKey](https://www.digikey.com/en/products/detail/same-sky-formerly-cui-devices/AMT222B-V/9838236) · [AMT22 serisi](https://www.sameskydevices.com/product/motion/rotary-encoders/absolute/modular/amt22-series) · [AMT22 veri sayfası](https://www.mouser.lt/pdfdocs/amt22.pdf) · [AS5047P veri sayfası](https://www.infineon.com/row/public/documents/24/49/infineon-as5047p-datasheet-en.pdf) · [AS5047P adaptör, Farnell](https://be.farnell.com/en-BE/ams-osram-group/as5047p-ts-ek-ab/adapter-board-kit-position-sensor/dp/4158644)

AMT22 parça kodu: A = 12 bit tek tur, **B = 14 bit tek tur**, C/D = çok turlu; "-V" = manşonlu kit.

## 5. Akım sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **Adafruit INA228 (#5832)** | TI INA228: 20 bit delta-sigma, I²C, 85 V ortak mod, ofset ≤ ±1 µV, kazanç hatası ≤ ±%0,05; %0,1 şant | 14,95 $ | **Seçildi.** INA229 ile aynı çekirdek; hazır, bilinen markalı kart |
| TI INA229 | Aynı çekirdek, SPI 10 MHz | hazır kart bulunamadı | TI değerlendirme kartı ya da kendi PCB'miz gerekirdi |
| Adafruit INA219 (#904) | 12 bit, I²C, 26 V | — | Elendi: çözünürlük ≈ 256 kat düşük |
| Hall etkili modüller (ACS712 vb.) | Analog | — | Elendi: gürültülü, ESP32 ADC gerekir |

Kaynaklar: [Adafruit INA228](https://adafruit.com/product/5832) · [TI INA229](https://www.ti.com/product/INA229)

**Yerleşim:** şant motor hattına seri (çift yönlü). PWM geçişleri ölçümü bozarsa sürücünün besleme hattına alınır; anlık akım için DRV8874'ün CS çıkışı da kaydedilir. 1 kHz döngüde ≈ 0,5 ms dönüşüm süresi.

## 6. Sıcaklık sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ **Adafruit TMP117 (#4821) × 2** | TI TMP117: ±0,1 °C (−20…50 °C), 16 bit, I²C | 11,50 $ (× 2 = 23,00 $) | **Seçildi.** Biri ortam, biri motor gövdesi (0x48, 0x49) |
| Sensirion SHT45 | Sıcaklık + nem | — | Doğruluk değerini doğrulamadık; nem ölçmek istenirse eklenebilir |
| DS18B20 | ±0,5 °C, 1-Wire | — | Elendi: 5 kat daha az doğru, çok taklidi var |
| NTC termistör | Analog | — | Elendi: kalibrasyon ve ADC gerekir |

Kaynaklar: [Adafruit TMP117](https://www.adafruit.com/product/4821) · [TI TMP117](https://www.mouser.in/en/new/texas-instruments/ti-tmp117-temperature-sensor/)

## 7. Diğer parçalar

| Parça | Seçim | Fiyat | Neden |
|---|---|---|---|
| Enkoder alıcısı | ✅ TI AM26LV32E + SOIC-16 adaptör (× 2) | teklif (birkaç $) | maxon'un RS-422 çıkışını 3,3 V'a çevirir ([TI](https://ti.com/lit/gpn/am26lv32e)) |
| Güç kaynağı | ✅ Mean Well 12 V, ≥ 3 A | teklif | Bilinen marka; motor nominali 1,3 A, akım sınırı 2 A |
| Rulman | ✅ SKF / NSK / FAG × 2, kol mili çapında (ör. 6 mm 626-2Z, 8 mm 608-2Z) | rulmancı | Kol mili motordan ayrı döner |
| Kol mili | ✅ 8–10 cm çelik mil; AMT22 manşonu ve rulmanla aynı çap | hırdavat | |
| Kol ve ağırlıklar | ✅ 15 cm alüminyum lama; M5–M6 somun/pul ile ≈ 20 g uç | hırdavat | Yerçekimi torkunu açıdan bağımsız değiştirmek için |
| Gövde ve kaplin | ✅ 3B baskı; kaplin 1,5° / 3° / 5° | baskı | Ana deney değişkeni; toplam boşluk ≈ 0,85° + kaplin |
| Breadboard, kablo, lehim | ✅ | | |

---

## Sipariş öncesi kontrol listesi

- [ ] maxon kombinasyonu yapılandırıldı; kesin fiyat, mil çapı, gönderim ve gümrük öğrenildi. (Bütçe zorlarsa: önce GPX 22 A 21:1, sonra Faulhaber teklifi, en son Pololu 37D.)
- [ ] Simülasyon seçilen motorun değerleriyle tekrarlandı (tork ve kontrolcü hızı payı).
- [ ] AMT22 manşon çapı = rulman iç çapı = kol mili çapı.
- [ ] Kartlar yetkili satıcıdan (orijinal).
