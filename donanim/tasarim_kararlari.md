# Tasarım kararları

Donanımda neyi neden seçtik, alternatifler ve artı/eksi yanlarıyla. Alışveriş listesi: [`alisveris_listesi.md`](alisveris_listesi.md).

**Seçim ilkesi.** Çalışma yayına yönelik ve ileride genişletilecek: iki eklemli kol, daha hızlı döngüler, gözlemci denemeleri. Bu yüzden her parça iki koşulu sağlamalı:

1. **Bilinen bir üreticiden, veri sayfası eksiksiz olmalı.** Hakem "motor eylemsizliği ne, enkoder çözünürlüğü ne" diye sorduğunda cevap üretici belgesinde olmalı.
2. **Çözünürlük ve doğruluk ölçmek istediğimiz etkinin çok altında olmalı.** Ölçmek istediğimiz boşluk 1,5–5°.

İlk listedeki markasız parçalar (JGA25-370 / JGB37-520 motorlar, TB6612FNG ve INA219 modülleri, AS5600) bu iki koşulu sağlamadığı için değiştirildi.

---

## Özet

| Görev | Eski seçim | Yeni seçim | Neden değişti |
|---|---|---|---|
| Motor + dişli + enkoder | JGA25-370 / JGB37-520 (markasız) | **maxon DCX 22 L + GPX 22 LZ 26:1 + ENX 16 EASY 1024** | Parametreler belgeli; enkoder çıkışta ≈ 70 kat daha ince |
| Motor sürücü | TB6612FNG | **TI DRV8874 (Pololu #4035)** | TB6612FNG 1,2 A'i sürekli veremiyor (önerilen ≤ 1,0 A) |
| Denetleyici | ESP32 (herhangi bir kart) | **ESP32, orijinal Espressif ESP32-DevKitC** | Kart aynı; taklit yerine üreticinin kendi kartı |
| Kol açısı | AS5600 (12 bit) | **Same Sky (CUI) AMT22, 14 bit mutlak** | Doğruluk ±0,2° garanti; çözünürlük 4 kat |
| Akım | INA219 (12 bit) | **TI INA228, Adafruit #5832 (20 bit)** | Çözünürlük ≈ 256 kat |
| Sıcaklık | yok | **TI TMP117 × 2 (Adafruit)**: ortam + motor gövdesi | Sonuçları sıcaklıkla ilişkilendirmek |
| Enkoder alıcısı | gerekmiyordu | **TI AM26LV32E** (3,3 V RS-422 alıcı) | maxon enkoderi diferansiyel çıkışlı |
| Güç kaynağı | herhangi 12 V adaptör | **Mean Well 12 V, ≥ 3 A** | Bilinen marka, düzgün regülasyon |

---

## 1. Motor, dişli kutusu ve enkoder: maxon

| | **Seçilen: maxon** | Eski: JGA25-370 1:34 |
|---|---|---|
| Motor | DCX 22 L, 12 V sargı | markasız 25 mm |
| Dişli | GPX 22 **LZ** (azaltılmış boşluk), 2 kademe, **26:1** | düz dişli, oran 34 |
| Dişli boşluğu (yüksüz, ortalama) | **0,85°** (üretici verisi) | bilinmiyor |
| Dişli sürekli torku | 0,7 N·m | bilinmiyor |
| Enkoder | ENX 16 EASY, **1024 CPT**, 3 kanal, RS-422 | 11 darbe/tur |
| Çıkışta sayım / tur | 1024 × 4 × 26 ≈ **106.500** (≈ 0,0034°) | 11 × 4 × 34 ≈ 1.500 (≈ 0,24°) |
| Parametreler | Tamamı katalogda (R, L, k_t, rotor eylemsizliği, zaman sabitleri) | Tedarikçi verileri tutarsız |
| Fiyat (KDV ve kargo hariç, 1–4 adet) | ≈ 220 € + 151 € + 101 € ≈ **472 €** | ≈ 600 TL |

DCX 22 L, 12 V sargı (değerler maxon kataloğundan okunmuştur; sipariş öncesi yapılandırıcıda teyit edilmeli):

| Büyüklük | Değer |
|---|---|
| Nominal tork / akım | 29,5 mN·m / 1,30 A |
| Durma torku / akımı | 150 mN·m / 6,54 A |
| Sargı direnci, endüktans | 1,84 Ω, 0,192 mH |
| Tork sabiti | 22,9 mN·m/A |
| Rotor eylemsizliği | ≈ 8 g·cm² (48 V sürümünde 8,12 g·cm²) |

**Neden maxon:**
- Modelde gereken her parametre üretici kataloğunda. Sistem tanılama yalnızca doğrulama için yapılır, tahmin için değil. Makalede düzenek tablosu doğrudan belgeye dayanır.
- Dişli boşluğu belgeli ve küçük (0,85°). Bizim çalışmamızda boşluğu ayarlanabilir kaplin belirleyecek; dişli kutusunun kendi boşluğunun küçük ve tutarlı olması deney değişkenini temiz tutar. Toplam boşluk ≈ dişli (0,85°) + kaplin.
- Enkoder çıkışta yaklaşık 70 kat daha ince. Hız kestirimi (türev terimi motor enkoderinden alınıyor) çok daha az gürültülü olur.
- Rotor eylemsizliği (≈ 8 g·cm²) simülasyonda varsaydığımızın (1,5×10⁻⁶ kg·m² = 15 g·cm²) yaklaşık yarısı. Bu, dişli rezonansını yükseltir ve kontrolcü hızına pay bırakır. Simülasyon maxon değerleriyle tekrarlanacak.
- Yüklenebilirlik: oran 26 ve verim ≈ %81 ile, 2 A akım sınırında çıkışta ≈ 0,96 N·m. Simülasyonun istediği tepe tork ≈ 0,25 N·m.

**Neden GPX 22 LZ 26:1:** Azaltılmış boşluklu (LZ) sürüm, standart (A, 21:1, 1,05°) sürüme göre daha az boşluklu. Oran simülasyondaki 34'e yakın; çıkış hızı 12 V'ta ≈ 190 rpm.

**Eksileri:**
- Fiyat (≈ 472 € + KDV, kargo ve gümrük). maxon'un Türkiye'deki satış yolu bulunamadı; maxon çevrimiçi mağazası üzerinden sipariş, Türkiye'ye gönderim koşulları teyit edilecek.
- maxon dişli kutusunu ve enkoderi yalnızca motorla birlikte, "kombinasyon" olarak satıyor; yapılandırıcıda tek sipariş olarak oluşturulmalı.
- Enkoder çıkışı diferansiyel RS-422 ve 5 V beslemeli: ESP32'ye doğrudan bağlanmaz, 3,3 V alıcı gerekir (bkz. 6).
- Durma akımı 6,54 A, sürücünün 6 A tepe değerinin üstünde: sürücünün akım sınırı ≈ 2 A'e ayarlanacak.

**Alternatif:** Faulhaber (benzer kalite ve fiyat). Pololu'nun 37D motorları iyi belgelenmiş, ama dişlileri genel amaçlı ve durma akımı 5,5 A; maxon'un yerini tutmuyor.

---

## 2. Motor sürücü: TI DRV8874 (Pololu #4035)

**TB6612FNG neden çıktı:** Toshiba veri sayfasında 1,2 A bir *mutlak sınır*. Önerilen çalışma aralığı en fazla **1,0 A** (motor beslemesi ≥ 4,5 V), izin verilen kayıp gücü 0,78–1,36 W (karta göre). Pololu da kartını "1 A sürekli" olarak veriyor. Yani 1,2 A'de sürekli çalışma garanti değil; ayrıca yeni motorun nominal akımı 1,3 A.

| | TB6612FNG (eski) | **DRV8874 (Pololu #4035)** |
|---|---|---|
| Sürekli akım | 1,0 A önerilen (1,2 A mutlak sınır) | **2,1 A** (oda sıcaklığı, ek soğutma yok) |
| Tepe | 3,2 A (10 ms tek darbe) | 6 A (çip) |
| Motor gerilimi | 4,5–13,5 V | 4,5–37 V |
| Akım ölçüm çıkışı | yok | **CS, ≈ 1,1 V/A** |
| Akım sınırlama | yok | **Ayarlanabilir** (VREF), çevrim çevrim |
| Mantık | 2,7–5,5 V | 1,8–5 V (ESP32 ile doğrudan) |
| Kanal | 2 | 1 (ikinci eklem için ikinci kart) |
| Fiyat | | ≈ 12 $ |

Üretici: çip Texas Instruments, kart Pololu. Akım sınırı ≈ 2 A'e ayarlanacak (motor nominali 1,3 A, deney tepe akımı ≈ 0,5 A).

Diğerleri: L298N (2–3 V kayıp, hassas kontrolde kötü), BTS7960 (gereğinden büyük).

---

## 3. Denetleyici: ESP32 yeterli mi?

**Bu çalışma için yeterli.** Gereken: 1 kHz kontrol döngüsü, bir motor enkoderi, SPI ve I²C sensörler, gözlemci hesabı, USB ile veri kaydı.

| İhtiyaç | ESP32 | Durum |
|---|---|---|
| 1 kHz döngü + gözlemci | 240 MHz, çift çekirdek, tek duyarlıklı FPU | Rahat |
| Enkoder sayma | Donanım darbe sayacı (PCNT), kuadratür çözme, gürültü filtresi | Rahat; 1024 CPT motor tam hızda ≈ 340 kHz kenar/sn |
| SPI (AMT22) + I²C (INA228, TMP117) | Donanım SPI ve I²C | Rahat |
| PWM 20 kHz | LEDC / MCPWM | Rahat |
| IoT (ileride) | Dahili Wi-Fi | Ek kart gerekmez |

**İleride dikkat edilecekler:**
- Kayan noktalı işlemci yalnızca tek duyarlıklı (float). Çift duyarlıklı (double) hesap yazılımla ve yavaş. Gözlemci float ile yazılmalı.
- Wi-Fi açıkken kontrol döngüsünün zamanlaması bozulabilir. Kontrol döngüsü bir çekirdeğe, Wi-Fi diğerine sabitlenmeli; döngü zamanlaması her deneyde kaydedilmeli.
- Analog girişleri gürültülü; bu yüzden bütün sensörler dijital seçildi.
- İki eklemli kol ve 5 kHz üstü döngüler sınıra yaklaşırsa, kontrolü Teensy 4.1'e (600 MHz, çift duyarlıklı FPU, 4 donanım enkoder çözücüsü) taşıyıp ESP32'yi yalnızca IoT için bırakmak doğal bir yükseltme yolu.

**Hangi kart:** Taklit kartlar yerine Espressif'in kendi geliştirme kartı (ESP32-DevKitC, WROOM-32E modüllü), yetkili distribütörden.

---

## 4. Kol açısı sensörü: Same Sky (CUI) AMT22

| | AS5600 (eski) | AS5047P (ams OSRAM) | **AMT22 (seçilen)** |
|---|---|---|---|
| Çözünürlük | 12 bit (0,088°) | 14 bit (0,022°) | **14 bit (0,022°)** |
| Doğruluk | belgede net değil; mıknatıs hizasına bağlı | mıknatıs hizasına bağlı | **±0,2° (üretici)** |
| Arayüz | I²C | SPI, 14 bit + ABI | SPI, 2 MHz, mod 0 |
| Güncelleme | | çok düşük gecikme (DAEC) | 100 µs (14 bit) |
| Montaj | ayrı mıknatıs, hassas hizalama | ayrı mıknatıs, hassas hizalama | **Mile manşonla geçer** (2–8 mm), mıknatıs yok |
| Besleme / mantık | 3,3 V | 3,3 / 5 V | 5 V besleme, çıkış 3,3 V seviyesinde |

**Neden AMT22:** Boşluk 1,5–5° iken açı farkı θ_d'nin doğruluğu belirleyici. AMT22'nin doğruluğu üreticinin garantisinde ve mıknatıs hizalamasına bağlı değil; kapasitif ölçüm tozdan ve yağdan etkilenmiyor. 14 bitte ±0,2° doğruluk, en küçük boşluğun (1,5° kaplin + 0,85° dişli) yaklaşık %9'u. 100 µs güncelleme 1 kHz döngüye sığıyor.

**Dikkat:** 14 bitte en yüksek hız 4000 rpm (bizim kolda fazlasıyla yeterli). MISO çıkışı 3,3 V seviyesinde, ESP32'ye doğrudan bağlanır; veri sayfası MOSI/CS eşiklerini tam vermiyor, ilk testte doğrulanacak.

---

## 5. Akım sensörü: TI INA228 (Adafruit #5832)

| | INA219 (eski) | **INA228 (seçilen)** | INA229 |
|---|---|---|---|
| ADC | 12 bit | **20 bit, delta-sigma** | 20 bit, delta-sigma |
| Arayüz | I²C | I²C | SPI (10 MHz) |
| Ortak mod gerilimi | 0–26 V | −0,3–85 V | −0,3–85 V |
| Ofset / kazanç hatası | | ±1 µV / ±%0,05 (en çok) | aynı |
| Dönüşüm süresi | | 50 µs – 4,12 ms, 1–1024 ortalama | aynı |
| Hazır kart | var | **Adafruit #5832, ≈ 15 $** | bulunamadı |

**INA228 ve INA229 aynı ölçüm çekirdeği**; fark yalnızca arayüz. INA229 için hazır, bilinen markalı bir kart bulamadık (TI değerlendirme kartı ya da kendi PCB'miz gerekirdi). INA228'in Adafruit kartı hazır ve 0,1 % hassasiyetli şant direnciyle geliyor.

**Bilinmesi gereken:** 20 bit, ADC'nin çözünürlüğü. Gürültüsüz etkin çözünürlük dönüşüm süresine bağlı: 1 kHz döngüde ≈ 0,5 ms dönüşüm süresi seçilecek, bu yine de INA219'un çok üstünde.

**Yerleşim:** Şant motor hattına seri bağlanır (çift yönlü akım ölçümü). PWM geçişlerinin ölçümü bozup bozmadığı ilk testte kontrol edilecek; bozarsa şant sürücünün besleme hattına alınır ve anlık motor akımı için DRV8874'ün CS çıkışı da kaydedilir.

---

## 6. Enkoder alıcısı: TI AM26LV32E

maxon ENX 16 EASY çıkışı diferansiyel RS-422 (A, A̅, B, B̅, I, I̅), 5 V beslemeli. ESP32'nin girişleri 3,3 V. AM26LV32E, 3,3 V ile çalışan dört kanallı RS-422 alıcısı (32 MHz'e kadar, ±7 V ortak mod). Diferansiyel hat, motorun PWM gürültüsüne karşı da daha dayanıklı. SOIC kılıflı olduğu için bir adaptör kartına lehimlenecek.

---

## 7. Sıcaklık: TI TMP117 × 2 (Adafruit)

- **Doğruluk:** −20 °C ile 50 °C arasında ±0,1 °C (kalibrasyonsuz), 16 bit, 0,0078 °C çözünürlük, I²C.
- **Birincisi ortam sıcaklığı:** düzenekten uzakta, hava akımına açık.
- **İkincisi motor gövdesi:** motorun dış yüzeyine ısı iletken yapıştırıcıyla. Önerimiz bu, çünkü sonuçları ortam sıcaklığından çok motorun kendi sıcaklığı etkiliyor:
  - Bakır sargının direnci ≈ %0,39/°C değişir; aynı gerilimde akım ve tork değişir.
  - Dişli yağının viskozitesi, yani sürtünme, sıcaklıkla değişir.
- **Veri olarak:** Her deney kaydına başlangıç ve bitiş sıcaklıkları (ortam + motor) yazılır, sıcaklık ayrıca 1–10 Hz ile sürekli kaydedilir. Sonuçlar "şu sıcaklıkta şu sınır" biçiminde karşılaştırılabilir; sürtünme parametresi sıcaklığa göre tanılanabilir.
- **Adresler:** ikisi aynı I²C hattında, 0x48 ve 0x49 (ADDR pini ile).

---

## 8. Haberleşme

| Bağlantı | Protokol | Not |
|---|---|---|
| maxon ENX 16 → AM26LV32E → ESP32 | RS-422 diferansiyel → 3,3 V kuadratür → donanım sayacı (PCNT) | 5 V enkoder beslemesi USB'den |
| AMT22 (kol açısı) → ESP32 | SPI, 2 MHz, mod 0 | 5 V besleme, 3,3 V çıkış |
| INA228 (akım) → ESP32 | I²C, adres 0x40 | Hızlı mod (1 MHz) desteklenir |
| TMP117 × 2 → ESP32 | I²C, 0x48 ve 0x49 | 1–10 Hz yeterli |
| ESP32 → DRV8874 | PH/EN: EN'ye 20 kHz PWM, PH yön; nSLEEP HIGH | Akım sınırı VREF ile ≈ 2 A |
| ESP32 ↔ bilgisayar | USB seri, 921600 baud | Veri kaydı; Wi-Fi kontrol döngüsünde kullanılmaz |

Kol açısının SPI'ye, akımın I²C'ye alınması 1 kHz döngüdeki I²C yükünü azaltıyor (eski tasarımda iki sensör aynı I²C hattındaydı).

---

## 9. Güç ve mekanik

- **Güç:** Mean Well 12 V, ≥ 3 A adaptör. Motor nominali 1,3 A; sürücü akım sınırı 2 A.
- **Rulman:** bilinen marka (SKF, NSK, FAG), iki adet, kol mili çapında.
- **Kaplin:** 3B baskı, ayarlanabilir boşluk (1,5 / 3 / 5°). GPX 22 çıkış mili çapı yapılandırıcıdan teyit edildikten sonra tasarlanacak.

---

## Sıradaki

1. maxon yapılandırıcısında kombinasyonu oluşturmak (DCX 22 L 12 V + GPX 22 LZ 26:1 + ENX 16 EASY 1024), kesin fiyat, mil çapı ve teslim süresi.
2. Simülasyonu maxon değerleriyle (rotor eylemsizliği, k_t, R, oran 26, dişli boşluğu 0,85°) tekrarlamak: kontrolcü hızı payı ve tork yeterliliği.
3. Diğer parçalar yetkili distribütörden (DigiKey, Mouser) ya da orijinal ürün satan bayilerden.
