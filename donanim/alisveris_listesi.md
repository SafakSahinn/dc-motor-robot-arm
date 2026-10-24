# Alışveriş listesi

Aynı düzenek için üç malzeme listesi ve her görevde değerlendirilen bütün adaylar, fiyatları ve seçilme/elenme nedenleriyle. **Seçilen: dengeli liste.** Gerekçeler: [`tasarim_kararlari.md`](tasarim_kararlari.md).

> **Güncel liste (24 Ekim 2026):** fiyat ve stokları doğrulanmış, satın alma kanalı (EKOM), iki mekanik seçenek ve toplamlarla birlikte güncel malzeme listesi [`../calisma_notu/malzeme.md`](../calisma_notu/malzeme.md) dosyasında. Bu dosya bütün adayların karşılaştırması olarak korunuyor; güç kaynağı ve mekanik kalemler için güncel olan çalışma notudur.

Fiyatlar üretici ya da satıcı sitelerindeki liste fiyatları: TL fiyatları KDV dahil; $ ve € fiyatları KDV, kargo ve gümrük hariç, 1 adet. Değişebilir. ✅ = dengeli listede.

---

## Üç liste yan yana

| Görev | 1. İlk liste (en ucuz) | ✅ 2. Dengeli liste (seçilen) | 3. Üst sınıf liste |
|---|---|---|---|
| Motor + enkoder | JGB37-520 12 V 1:30, 639,29 TL | **JGB37-520 12 V 1:30, 639,29 TL** (Karaköy'de enkoderli JGA25-370 bulunursa o) | maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16, ≈ 472 € |
| Motor sürücü | TB6612FNG modülü, 81,36 TL | **Pololu DRV8874 (#4035), 11,94 $** | Pololu DRV8874 × 2, 23,88 $ |
| Denetleyici | ESP32 DevKit (genel), ≈ 270 TL | **Espressif ESP32-DevKitC, ≈ 13 €** | Espressif ESP32-DevKitC, ≈ 13 € |
| Kol açısı | AS5600 modülü (markasız), ≈ 258 TL | **Adafruit AS5600 (#6357), 5,95 $** + diametral mıknatıs | AMT22 14 bit (AMT222B-V), 73,72 $ |
| Akım | INA219 modülü, 87,18 TL | **Adafruit INA228 (#5832), 14,95 $** | Adafruit INA228, 14,95 $ |
| Sıcaklık | — | **Adafruit TMP117 × 2, 23,00 $** | Adafruit TMP117 × 2, 23,00 $ |
| Enkoder alıcısı | gerekmez | gerekmez | TI AM26LV32E (RS-422) |
| Güç | Genel 12 V 2 A adaptör | **Mean Well 12 V 3 A, ≈ 15 $** | Mean Well 12 V 3 A, ≈ 15 $ |
| **Toplam (elektronik + motor)** | **≈ 1.336 TL** + adaptör | **≈ 639 TL + 13 € + 70 $** | **≈ 485 € + 150 $** |

Mekanik parçalar (rulman, mil, kol, ağırlıklar, vidalar, 3B baskı gövde ve kaplin) üç listede de aynı ve toplama dahil değil.

**Neden dengeli liste:**
- Motor ilk listedeki gibi: simülasyon bu sınıfla yapıldı, hemen alınabilir, parametreler tanılanacak. maxon kombinasyonu tek başına dengeli listenin ≈ 10 katı.
- Sürücü değişti: TB6612FNG önerilen en fazla 1,0 A, motorun durma akımı 2,3 A. DRV8874 ≈ 7 $ fazlasına 2,1 A sürekli, donanım akım sınırı ve akım ölçüm çıkışı veriyor.
- Kol açısında AMT22 bu motorla boşa gider: θ_d'yi ucuz motorun enkoderi (≈ 0,27°) sınırlar. Adafruit AS5600 aynı çipin orijinali, belgeli ve 5,95 $.
- INA228 fiyatı az değiştiriyor (≈ 15 $), çözünürlüğü ≈ 256 kat artırıyor.
- TMP117 ucuz ve ortam + motor sıcaklığını her deneye veri olarak ekliyor.
- Yükseltme yolu açık: motor ve kol enkoderi üst sınıfa çevrilebilir, diğer parçalar aynı kalır.

**Sınır:** motor enkoderi çıkışta 1320 sayım/tur (≈ 0,27°); 1,5–5°'lik boşluk 6–18 adımla ölçülür. Boşluğun varlığı ve genliği görülür, ince ayrıntı için üst sınıf motor gerekir.

---

## Bütün adaylar

### 1. Motor, dişli kutusu ve enkoder

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ JGB37-520, 12 V, 1:30 (direnc.net) | Durma 5 kg·cm / 2,3 A; nominal 3,5 kg·cm @ 1 A; 11 darbe/tur (çıkışta 1320, 0,27°); 6 mm D mil | 639,29 TL | Dengeli liste. Hemen alınabilir, veri sayfası kısmen var; rotor büyük (ω_c ≈ 35 rad/s) |
| JGA25-370, 12 V, 1:34 | Durma ≈ 0,41 N·m; 11 darbe/tur; 4 mm D mil | Türkiye'de online enkoderli yok | İlk tercihti (küçük rotor); Karaköy'de bulunursa JGB37 yerine |
| maxon DCX 22 L 12 V + GPX 22 LZ 26:1 + ENX 16 EASY 1024 | Durma 150 mN·m / 6,54 A; dişli boşluğu 0,85°; çıkışta ≈ 106.500 sayım/tur | 220,41 + 150,63 + 101,05 ≈ 472 € | Üst sınıf; her parametre katalogda |
| maxon, aynı + GPX 22 A 21:1 | Boşluk 1,05° | ≈ 436 € | Üst sınıfın biraz ucuzu |
| Faulhaber 2232 SR + 20/1R + IEH2-4096 | Enkoder 4096 çizgi/tur | motor ≈ 112 € (bayi); dişli + enkoder teklif | maxon sınıfı |
| Pololu 37D 12 V 30:1, 64 CPR (#4752) | Durma ≈ 14 kg·cm / 5,5 A; çıkışta 1920 sayım/tur (0,19°) | 60,95 $ | Enkoder JGB37'den yalnız ≈ 1,5 kat ince; ithalatla kazancı az |
| SAMM L tipi, 12 V, 1:42 | Durma ≥ 8,5 kg·cm; 13 darbe/tur | ≈ 826 TL | Stokta yoktu |
| Hobi servo (SG90, MG996R) | Hazır iç kontrolcü | — | Elendi |

Kaynaklar: [JGB37-520](https://www.direnc.net/jgb37-520-12v-330rpm-enkoderli-motor) · [JGB37-520 veri sayfası](https://pdf.direnc.net/upload/jgb37-520-datasheet.pdf) · [DCX 22 L](https://www.maxongroup.com/maxon/view/product/motor/dcmotor/DCX/DCX22/DCX22L01EBSL703) · [GPX 22 LZ 26:1](https://www.maxongroup.com/maxon/view/product/gear/planetary/GPX/GPX22/GPX22-2-Stufig-LZ/GPX22LZKLSL26D0CPLW) · [GPX 22 A 21:1](https://www.maxongroup.com/maxon/view/product/gear/planetary/GPX/GPX22/GPX22-2-Stufig-A/GPX22AAKLSL21D0CPLW) · [ENX 16 EASY](https://www.maxongroup.com/maxon/view/product/ENX16EASY06) · [Faulhaber 2232 SR](https://www.faulhaber.com/fileadmin/Import/Media/EN_2232_SR_DFF.pdf) · [Pololu 37D #4752](https://www.pololu.com/product/4752) · [SAMM](https://market.samm.com/en/l-tipi-enkoderli-metal-disli-dc-motor)

### 2. Geliştirme kartı

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ Espressif ESP32-DevKitC (WROOM-32E) | 240 MHz çift çekirdek, tek duyarlıklı FPU, PCNT, Wi-Fi | ≈ 13 € (KDV dahil, Conrad) | Dengeli liste; orijinal kart |
| Genel "ESP32 DevKit" | Aynı çip, kart üreticisi belirsiz | ≈ 270 TL (f1depo) | İlk liste; USB çipi ve regülatör değişken |
| ESP32-S3-DevKitC-1 (N8) | Vektör komutları, dahili USB | 15,95 $ (Adafruit) | Belirgin üstünlüğü yok |
| Teensy 4.1 | 600 MHz Cortex-M7, double FPU, 4 enkoder çözücü, Ethernet | 31,50 $ (SparkFun) | Yükseltme yolu (iki eklem, 5–10 kHz) |
| STM32 Nucleo-G474RE | 170 MHz Cortex-M4F, motor kontrol zamanlayıcıları | 20,13 $ (DigiKey) | Kurulumu zahmetli |
| Arduino Uno R3 / R4 Minima | 8 bit 16 MHz / 48 MHz Cortex-M4 | R4 ≈ 23 € | Elendi: sınırda |

Kaynaklar: [Conrad](https://www.conrad.com/en/o/microcontroller-boards-kits-mcu-2420148.html) · [f1depo ESP32](https://www.f1depo.com/urun/esp32-wifi-bluetooth-gelistirme-kiti) · [ESP32-S3, Adafruit](https://www.adafruit.com/product/5312) · [Teensy 4.1](https://www.pjrc.com/store/teensy41.html) · [SparkFun Teensy](https://www.sparkfun.com/development-boards/microcontrollers/teensy.html) · [Nucleo-G474RE](https://www.digikey.com/en/products/detail/stmicroelectronics/NUCLEO-G474RE/10231585)

### 3. Motor sürücü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ Pololu #4035 (TI DRV8874) | 2,1 A sürekli, 4,5–37 V, akım ölçüm çıkışı, ayarlanabilir akım sınırı | 11,94 $ | Dengeli liste; akım sınırı ≈ 2 A |
| TB6612FNG modülü | Önerilen ≤ 1,0 A sürekli (1,2 A mutlak sınır) | 81,36 TL (direnc.net); Pololu #713 4,95 $ | İlk liste; durma akımı (2,3 A) sınırın iki katı |
| Adafruit DRV8871 (#3190) | ≈ 3,6 A tepe | ≈ 10,4–11,6 $ | Yedek; akım ölçümü yok |
| L298N / BTS7960 | 2–3 V kayıp / 40 A sınıfı | — | Elendi |

Kaynaklar: [Pololu #4035](https://www.pololu.com/product/4035) · [TB6612FNG, direnc.net](https://www.direnc.net/tb6612fng-dc-ve-step-motor-surucu-modulu) · [Pololu #713](https://www.pololu.com/product/713) · [Toshiba veri sayfası](https://toshiba.semicon-storage.com/info/docget.jsp?did=10660)

### 4. Kol açısı sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ Adafruit AS5600 (#6357) | ams AS5600, 12 bit (0,088°), I²C; mıknatıs ayrı | 5,95 $ | Dengeli liste; orijinal çip, belgeli kart |
| AS5600 modülü (markasız) | 12 bit, I²C | ≈ 258 TL (Çiçeksepeti) | İlk liste; çip orijinal olmayabilir |
| ams AS5047P + adaptör | 14 bit, SPI + ABI | ≈ 16,7 $ – 21,7 € (stok sorunlu) | Ara seçenek |
| Same Sky AMT22 14 bit (AMT222B-V) | ±0,2° doğruluk, SPI, mıknatıssız | 73,72 $ | Üst sınıf; ince enkoderli motorla anlamlı |

Kaynaklar: [Adafruit AS5600](https://www.adafruit.com/product/6357) · [AS5600, Çiçeksepeti](https://www.ciceksepeti.com/as5600-manyetik-aci-sensoru-olcum-modulu-12-bit-temassiz-pozisyon-kcm45524464) · [AS5047P](https://www.infineon.com/row/public/documents/24/49/infineon-as5047p-datasheet-en.pdf) · [AMT222B-V](https://www.digikey.com/en/products/detail/same-sky-formerly-cui-devices/AMT222B-V/9838236)

**Mıknatıs:** diametral (kuzey-güney yan yana), 6 × 2,5 mm; eksenel mıknatıs çalışmaz. Mile ortalanmalı; sensör motor enkoderine göre birkaç açıda kalibre edilecek.

### 5. Akım sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ Adafruit INA228 (#5832) | 20 bit, I²C, 85 V, ofset ≤ ±1 µV, kazanç hatası ≤ ±%0,05 | 14,95 $ | Dengeli liste |
| INA219 modülü | 12 bit, I²C, 26 V | 87,18 TL (direnc.net) | İlk liste |
| TI INA229 | Aynı çekirdek, SPI | hazır kart yok | — |
| Hall modülleri (ACS712 vb.) | Analog | — | Elendi |

Kaynaklar: [Adafruit INA228](https://adafruit.com/product/5832) · [INA219, direnc.net](https://www.direnc.net/ina129-cift-yonlu-akim-sensor-modulu-en) · [TI INA229](https://www.ti.com/product/INA229)

### 6. Sıcaklık sensörü

| Seçenek | Özellik | Fiyat | Değerlendirme |
|---|---|---|---|
| ✅ Adafruit TMP117 (#4821) × 2 | ±0,1 °C (−20…50 °C), 16 bit, I²C | 11,50 $ × 2 | Dengeli liste; ortam + motor gövdesi (0x48, 0x49) |
| Sensirion SHT45 | Sıcaklık + nem | — | Nem istenirse |
| DS18B20 / NTC | ±0,5 °C / analog | — | Elendi |

Kaynak: [Adafruit TMP117](https://www.adafruit.com/product/4821)

### 7. Diğer

| Parça | Seçim | Fiyat | Not |
|---|---|---|---|
| ✅ Güç | Mean Well 12 V 3 A (GST36 serisi) | ≈ 14,6 $ – 17 € | [Farnell](https://ie.farnell.com/mean-well/gst36e12-p1j/adaptor-ac-dc-12v-3a/dp/2815899) · [Jameco](https://www.jameco.com/z/GST36B12-P1J-MEAN-WELL-12V-3A-36W-Class-2-AC-DC-Industrial-Desktop-Power-Adapter-Level-VI-2-1mm-Plug_2257361.html) |
| ✅ Diametral mıknatıs | 6 × 2,5 mm | — | AS5600 için |
| ✅ Rulman | 2 adet, kol mili çapında (SKF / NSK tercih) | rulmancı | |
| ✅ Kol, mil, ağırlıklar, vidalar | 15 cm alüminyum lama, çelik mil, ≈ 20 g uç, M3 vida | hırdavat | |
| ✅ Gövde, boşluklu kaplin | 3B baskı; 1,5° / 3° / 5° | baskı | JGB37 mili 6 mm D |
| RS-422 alıcı | TI AM26LV32E | birkaç $ | Yalnız üst sınıf listede |

---

## Sipariş kontrol listesi (dengeli liste)

- [ ] JGB37-520 1:30 (ya da Karaköy'de enkoderli JGA25-370): model etiketi fotoğrafı, mil çapı, enkoder besleme gerilimi.
- [ ] DRV8874, Adafruit AS5600, INA228, TMP117 × 2: tek siparişte yetkili distribütörden (kargo ve gümrük tek sefer).
- [ ] Espressif ESP32-DevKitC, Mean Well 12 V 3 A, diametral mıknatıs.
- [ ] Rulman iç çapı = kol mili çapı.
