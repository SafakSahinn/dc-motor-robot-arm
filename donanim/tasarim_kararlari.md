# Tasarım kararları

Donanımda neyi neden seçtik, alternatifler ve artı/eksi yanlarıyla. Üç liste, bütün adaylar ve fiyatlar: [`alisveris_listesi.md`](alisveris_listesi.md).

Malzemeyi üç düzeyde değerlendirdik: en ucuz **ilk liste**, maxon motorlu **üst sınıf liste** ve ikisinin arasındaki **dengeli liste**. **Dengeli liste seçildi:** motor ilk listedeki gibi kaldı; ucuz ama kritik parçalar (sürücü, akım ve sıcaklık sensörü, orijinal kartlar) bilinen üreticilerden alındı.

---

## Özet

| Görev | Seçim | Neden |
|---|---|---|
| Motor + enkoder | JGB37-520 12 V 1:30 (ya da enkoderli JGA25-370) | Simülasyon bu sınıfla yapıldı; hemen alınabilir; parametreler tanılanacak. maxon tek başına dengeli listenin ≈ 10 katı |
| Sürücü | Pololu DRV8874 (#4035) | TB6612FNG önerilen en fazla 1,0 A; motorun durma akımı 2,3 A |
| Denetleyici | Espressif ESP32-DevKitC | Orijinal kart; fark birkaç dolar |
| Kol açısı | Adafruit AS5600 + diametral mıknatıs | Orijinal ams çipi; motor enkoderi (0,27°) θ_d'yi sınırladığından daha ince sensör ölçüme yansımaz |
| Akım | Adafruit INA228 (20 bit) | ≈ 15 $ fazlasına ≈ 256 kat çözünürlük |
| Sıcaklık | Adafruit TMP117 × 2 | Ortam ve motor gövdesi her deneyle kaydedilir |
| Güç | Mean Well 12 V 3 A | Bilinen marka, düzgün regülasyon |

Toplam (elektronik + motor): ilk liste ≈ 1.336 TL, **dengeli ≈ 639 TL + 13 € + 70 $**, üst sınıf ≈ 485 € + 150 $.

---

## 1. Motor: neden ilk motorla devam?

| | **JGB37-520 1:30 (seçilen)** | JGA25-370 1:34 | maxon (üst sınıf) |
|---|---|---|---|
| Durma torku / akımı | 5 kg·cm (0,49 N·m) / 2,3 A | ≈ 0,41 N·m / ≈ 1–1,5 A | 150 mN·m × 26 / 6,54 A |
| Nominal | 3,5 kg·cm @ 1 A | ≈ 1–1,4 kg·cm | 29,5 mN·m / 1,30 A |
| Enkoder, çıkışta | 11 × 4 × 30 = 1320 sayım/tur (0,27°) | 11 × 4 × 34 ≈ 1500 (0,24°) | ≈ 106.500 (0,0034°) |
| Rotor | Büyük; ω_c ≈ 35 rad/s | Küçük; ω_c 45'e kadar | ≈ 8 g·cm² |
| Mil | 6 mm D | 4 mm D | yapılandırıcıda |
| Bulunabilirlik / fiyat | direnc.net, 639,29 TL | Online enkoderli yok; Karaköy | maxon mağaza, ≈ 472 € |

- Simülasyon bu motor sınıfıyla yapıldı; JGB37 için ayrı tork kontrolü: `simulasyon/motor_jgb37.m` (ω_c ≈ 35 rad/s).
- Parametreler belgesiz; sistem tanılama zaten planda: R ve k_t ölçümle, J_m ve b adım ve serbest yavaşlama yanıtından; ölü bant ve boşluk birkaç açıda.
- **Sınırı:** motor enkoderi kaba (0,27°); 1,5–5°'lik boşluk 6–18 adımla ölçülür. Boşluğun varlığı ve genliği görülür; ince ayrıntı için üst sınıf motor gerekir. Makalede açıkça yazılacak.
- **Yükseltme yolu:** sonuçlar umut verirse maxon (DCX 22 L + GPX 22 LZ 26:1 + ENX 16 EASY 1024) ve kol tarafında AMT22; sürücü, denetleyici, akım ve sıcaklık sensörleri aynı kalır.

---

## 2. Sürücü: TI DRV8874 (Pololu #4035)

**TB6612FNG neden çıktı:** Toshiba veri sayfasında 1,2 A bir *mutlak sınır*; önerilen çalışma aralığı en fazla **1,0 A** (motor beslemesi ≥ 4,5 V), izin verilen kayıp gücü 0,78–1,36 W. Pololu da kartını "1 A sürekli" olarak veriyor. Deney akımımız düşük olsa da JGB37'nin durma akımı (2,3 A) bunun iki katı; TB6612FNG'de koruma yalnız yazılımda kalırdı.

| | TB6612FNG | **DRV8874 (Pololu #4035)** |
|---|---|---|
| Sürekli akım | 1,0 A önerilen | **2,1 A** |
| Motor gerilimi | 4,5–13,5 V | 4,5–37 V |
| Akım ölçüm çıkışı | yok | **CS, ≈ 1,1 V/A** |
| Akım sınırlama | yok | **Ayarlanabilir** (≈ 2 A'e ayarlanacak) |
| Mantık | 2,7–5,5 V | 1,8–5 V |
| Fiyat | 81,36 TL / 4,95 $ | 11,94 $ |

---

## 3. Denetleyici: ESP32 yeterli mi?

**Bu çalışma için yeterli:** 1 kHz döngü, bir motor enkoderi (donanım sayacı PCNT, kuadratür, gürültü filtresi), I²C sensörler, gözlemci, USB ile veri kaydı; Wi-Fi IoT için hazır.

**İleride dikkat edilecekler:**
- Kayan nokta donanımı yalnız tek duyarlıklı; gözlemci float ile yazılmalı.
- Wi-Fi açıkken kontrol döngüsü bir çekirdeğe, Wi-Fi diğerine sabitlenmeli; döngü zamanlaması her deneyde kaydedilmeli.
- ADC gürültülü; bu yüzden bütün sensörler dijital.
- İki eklem ve 5 kHz üstü döngüde doğal yükseltme: kontrol Teensy 4.1'e (600 MHz, double FPU, 4 donanım enkoder çözücüsü), ESP32 yalnızca IoT için.

**Hangi kart:** Espressif'in kendi ESP32-DevKitC'si (WROOM-32E), yetkili satıcıdan. Genel kartlar çalışır ama USB çipi ve regülatör kalitesi değişken.

---

## 4. Kol açısı: Adafruit AS5600

θ_d = motor açısı/N − kol açısı. Ölçümün inceliğini iki sensörden kaba olanı belirler; dengeli listede bu, motor enkoderi (0,27°).

| | **Adafruit AS5600 (seçilen)** | AS5600 modülü (markasız) | AS5047P | AMT22 |
|---|---|---|---|---|
| Çözünürlük | 12 bit (0,088°) | 12 bit | 14 bit | 14 bit (0,022°), ±0,2° doğruluk |
| Arayüz | I²C | I²C | SPI + ABI | SPI |
| Montaj | Diametral mıknatıs, hizalama | aynı | aynı | Manşon, mıknatıssız |
| Fiyat | 5,95 $ | ≈ 258 TL | ≈ 16,7 $ – 21,7 € | 73,72 $ |

AS5600 motor enkoderinden üç kat ince; daha ince sensör bu motorla ölçüme yansımaz. Adafruit kartı orijinal ams çipiyle, belgeli ve markasız modülden ucuz. Diametral mıknatıs (6 × 2,5 mm) mile ortalanacak; doğruluk hizalamaya bağlı olduğundan sensör motor enkoderine göre birkaç açıda kalibre edilecek.

---

## 5. Akım: Adafruit INA228

| | INA219 | **INA228 (seçilen)** | INA229 |
|---|---|---|---|
| ADC | 12 bit | **20 bit, delta-sigma** | 20 bit |
| Arayüz | I²C | I²C | SPI |
| Ortak mod | 0–26 V | −0,3–85 V | −0,3–85 V |
| Ofset / kazanç hatası | | ≤ ±1 µV / ≤ ±%0,05 | aynı |
| Hazır kart / fiyat | 87,18 TL | Adafruit #5832, 14,95 $ | yok |

20 bit ADC çözünürlüğü; 1 kHz döngüde ≈ 0,5 ms dönüşüm süresi, etkin çözünürlük yine INA219'un çok üstünde. Şant motor hattına seri (çift yönlü); PWM geçişleri ölçümü bozarsa besleme hattına alınır, anlık akım için DRV8874'ün CS çıkışı da kaydedilir.

---

## 6. Sıcaklık: Adafruit TMP117 × 2

- ±0,1 °C (−20…50 °C), 16 bit, I²C.
- Biri ortam (düzenekten uzakta), biri motor gövdesinde (ısı iletken yapıştırıcıyla).
- Neden motor gövdesi de: bakır sargı direnci ≈ %0,39/°C değişir; dişli yağının viskozitesi (sürtünme) sıcaklığa bağlı. Ucuz motorda bu etkiler belgesiz, ölçmek daha da önemli.
- Her deney kaydına başlangıç/bitiş sıcaklıkları; deney boyunca 1–10 Hz sürekli kayıt. Adresler 0x48 ve 0x49.

---

## 7. Haberleşme

| Bağlantı | Protokol | Not |
|---|---|---|
| Motor enkoderi → ESP32 | A/B kuadratür → PCNT | Enkoder 3,3–5 V; 3,3 V ile beslenirse çıkış doğrudan ESP32'ye (veri sayfasından teyit) |
| AS5600 → ESP32 | I²C-0, 0x36 | 1 MHz (Fast-mode Plus) |
| INA228 → ESP32 | I²C-0, 0x40 | aynı hat |
| TMP117 × 2 → ESP32 | **I²C-1** (ikinci hat), 0x48 / 0x49 | **400 kHz**, 1–10 Hz. TMP117 veri sayfasında SCL en fazla 400 kHz; 1 MHz'lik hatta çalışması garanti değil. ESP32'nin iki I²C denetleyicisi var. |
| ESP32 → DRV8874 | EN'ye 20 kHz PWM, PH yön, nSLEEP HIGH | Akım sınırı ≈ 2 A |
| ESP32 ↔ bilgisayar | USB seri, 921600 baud | Veri kaydı; kontrol döngüsünde Wi-Fi yok |

**Bilinen risk:** 1 kHz'te iki I²C cihazı (AS5600, INA228) zamanlamayı zorlayabilir; bu yüzden I²C-0 1 MHz'te çalışır, yavaş TMP117'ler ayrı hatta. Gerekirse INA228 daha seyrek okunur.

**AS5600 filtre ayarı (zorunlu):** varsayılan yavaş filtrede (SF = 00) adım yanıtı gecikmesi **2,2 ms**. Konum geri beslemesi bu sensörden alındığı için bu gecikme döngüde bir faz kaybı yaratır ve salınım sınırını kaydırır. **SF = 11** seçilir: gecikme 0,286 ms, gürültü 0,043° RMS (çözünürlüğün, 0,088°, yarısı). Hızlı filtre eşiği (FTH) kapalı tutulur, çünkü salınım sırasında filtre davranışı değişmemeli. Kalan gecikme benzetim modeline eklenir.

---

## 8. Güç ve mekanik

- **Güç:** Mean Well 12 V 3 A. Genel adaptörlerde dalgalanma doğrudan motor gerilimine biner.
- **Rulman:** 2 adet, kol mili çapında (SKF / NSK tercih).
- **Kaplin:** 3B baskı, ayarlanabilir boşluk (1,5 / 3 / 5°); JGB37 mili 6 mm D. Toplam boşluk = motorun kendi dişli boşluğu (tanılamada ölçülecek) + kaplin.
