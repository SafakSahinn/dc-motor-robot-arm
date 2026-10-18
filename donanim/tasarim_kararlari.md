# Tasarım kararları

Donanımda neyi neden seçtik, alternatifler ve artı/eksi yanlarıyla. Alışveriş listesi: [`alisveris_listesi.md`](alisveris_listesi.md).

Son güncelleme: 18 Ekim 2026.

---

## 1. Motor: JGA25-370 mi, JGB37-520 mi?

İkisi de 12 V, enkoderli, metal dişli DC motor. Araştırmanın sonucu belirli bir motora bağlı değil: simülasyondaki boyutsuz harita farklı düzeneklerin aynı kurala uyduğunu gösterdi. Motor değişince yalnızca çalışma noktası (kontrolcü kazancı) kayıyor.

| | **A) JGA25-370, 1:34 / 1:45** | **B) JGB37-520, 1:30** |
|---|---|---|
| Gövde | 25 mm, hafif | 37 mm, daha ağır |
| Durma torku | ≈ 4,2 kg·cm (0,41 N·m), tedarikçiye göre değişiyor | 5 kg·cm (0,49 N·m) |
| Nominal tork | ≈ 1–1,4 kg·cm | 3,5 kg·cm @ 1 A |
| Durma akımı | ≈ 1–1,5 A | 2,3 A |
| Rotor eylemsizliği | Küçük | ≈ 2–3 kat büyük (tahmin) |
| Enkoder | 11 darbe / motor turu | 11 darbe / motor turu |
| Çıkış mili | 4 mm D | 6 mm D |
| Bulunabilirlik | Enkoderli sürümü Türk online mağazalarında yok; Karaköy'de aranacak | direnc.net, 639 TL, veri sayfası açık |

**A'nın artıları**
- Küçük rotor → dişli rezonansı yüksek → kontrolcü hızında geniş pay (simülasyonda ω_c 45 rad/s'ye kadar rahat).
- Motor eylemsizliği kolunkine yakın; kol tarafındaki olaylar (boşluk vuruşları) motor tarafından bastırılmıyor, daha net görülüyor.
- Akımı TB6612FNG'nin 1,2 A sürekli sınırı içinde.

**A'nın eksileri**
- Torku sınırda: 50 g uç kütlesinde yüksek kazançta doyuma giriyor; ≈ 20 g uçla çalışmak gerekiyor.
- Tedarikçi verileri tutarsız; tam değerler belirsiz.
- Enkoderli sürümü bulmak zor.

**B'nin artıları**
- Daha güçlü; tork payı geniş, ısınma daha az sorun.
- Veri sayfası açık ve tutarlı.
- Hemen sipariş edilebilir.

**B'nin eksileri**
- Büyük rotor → dişli rezonansı düşer → ω_c ≈ 35 rad/s civarında çalışmak gerekiyor; 45'te motor doyuma giriyor (simülasyon: `simulasyon/motor_jgb37.m`).
- Durma akımı 2,3 A, TB6612FNG'nin sürekli sınırının üstünde: yazılımda akım sınırı şart.
- Daha ağır ve büyük; gövde de büyür.

**Karar:** Önce A aranır. Bulunamazsa B alınır. İkisiyle de araştırma yapılabilir.

---

## 2. Denetleyici: neden Arduino değil, ESP32?

| | Arduino Uno | **ESP32 (seçilen)** |
|---|---|---|
| İşlemci | 8 bit, 16 MHz | 32 bit, 240 MHz, çift çekirdek |
| Kayan nokta (float) | Donanım yok, yazılımla yavaş | Donanım FPU var |
| RAM | 2 KB | ≈ 520 KB |
| Enkoder sayma | Yazılım kesmesiyle (2 kesme pini) | **Donanım sayacı (PCNT)**: darbeler işlemciyi meşgul etmeden sayılır |
| PWM | 8 bit, ≈ 490 Hz / 980 Hz (duyulur) | 16 bite kadar, istenen frekansta (LEDC); 20 kHz → duyulmaz |
| Mantık seviyesi | 5 V | 3,3 V (sensörlerimizle aynı) |
| Veri kaydı | Seri hat yavaş, RAM yetmez | Hızlı seri hat, büyük tampon, istenirse Wi-Fi |
| Fiyat | Benzer | Benzer |

**Neden önemli:** Kontrol döngüsü saniyede 1000 kez çalışacak. Her turda iki sensör okunacak, gözlemci denklemleri kayan noktayla hesaplanacak, motor enkoderinin darbeleri sayılacak ve veri bilgisayara gönderilecek. Uno'da bu, hem hesap hızı hem de enkoder kesmelerinin döngüyü bozması yüzünden sınırda kalır. Döngü zamanlamasındaki düzensizlik (jitter) de ölçmeye çalıştığımız salınımı bozabilir.

**ESP32'nin eksileri**
- ADC'si gürültülü (biz kullanmıyoruz; sensörler dijital).
- Kurulum Uno'dan biraz daha karmaşık (Arduino IDE'ye ESP32 desteği eklenir).
- 3,3 V mantık: 5 V'luk bir parça bağlanırsa seviye dönüştürücü gerekir (bizim listede yok).

**Alternatifler:** STM32 (Blue Pill / Nucleo) de uygun olurdu, ama kurulumu daha zahmetli. Teensy 4 çok hızlı ama pahalı.

---

## 3. Haberleşme protokolleri

Sistemde dört ayrı bağlantı var; her biri için ayrı karar:

| Bağlantı | Protokol | Neden |
|---|---|---|
| **AS5600 (kol açısı) → ESP32** | **I²C, 400 kHz** (adres 0x36) | Dijital, gürültüye dayanıklı, iki kabloyla. Bir okuma ≈ 0,1 ms; 1 kHz döngüye rahat sığar |
| **INA219 (akım) → ESP32** | **I²C, aynı hat** (adres 0x40) | Adresler farklı, aynı iki kablo paylaşılır |
| **Motor enkoderi → ESP32** | **A/B kare dalga (kuadratür)**, ESP32 donanım sayacı (PCNT) | Enkoderin doğal çıkışı; donanım sayacı hiçbir darbeyi kaçırmaz |
| **ESP32 → motor sürücü** | **PWM 20 kHz** + 2 yön pini + STBY | Gerilimi PWM'in doluluk oranıyla ayarlarız; 20 kHz insan kulağının üstü |
| **ESP32 ↔ bilgisayar** | **USB seri (UART), 921600 baud** | Ölçüm verisini kaydetmek ve kazançları değiştirmek için. Zamanlaması öngörülebilir |

**Neden Wi-Fi değil:** Wi-Fi gecikmesi düzensiz ve kontrol döngüsünü kesintiye uğratabilir. Veri kaydı için kablolu USB daha güvenilir. İleride istenirse Wi-Fi ile uzaktan izleme eklenebilir; kontrol döngüsü yine ESP32'nin içinde kalır.

**Neden AS5600'ün analog çıkışı değil:** AS5600 analog gerilim de verebilir, ama ESP32'nin ADC'si gürültülü ve doğrusal değil. 12 bitlik dijital değeri I²C ile okumak daha temiz.

**Bilinen risk:** 1 kHz'te iki I²C cihazı okumak zamanlamayı zorlayabilir. Gerekirse INA219 daha seyrek okunur (ör. 200 Hz), ya da AS5600 için 1 MHz hızlı I²C modu denenir.

---

## 4. Motor sürücü: neden gerekli, neden TB6612FNG?

**Sürücü kullanmamak mümkün değil:**
- ESP32'nin bir pini en fazla ≈ 3,3 V ve birkaç on mA verir. Motor 12 V ve ≈ 1 A (durmada 2,3 A'ya kadar) istiyor. Pin doğrudan bağlanırsa ESP32 yanar.
- **Motorun iki yöne dönmesi şart.** Boşluk deneyinin özü torkun sıfırdan geçip yön değiştirmesi. Bunun için motorun kutbunu elektronik olarak değiştiren bir **H köprüsü** gerekiyor. Tek bir transistör motoru yalnızca açıp kapatır, yön değiştiremez.
- Motor durduğunda bobinde ters gerilim oluşur; sürücü kartı bunu güvenli biçimde söndürür.

**Sürücü seçenekleri**

| | **TB6612FNG (seçilen)** | L298N | DRV8871 | BTS7960 |
|---|---|---|---|---|
| Anahtar tipi | MOSFET | Bipolar transistör | MOSFET | MOSFET |
| Üzerinde kaybolan gerilim | ≈ 0,5 V (1 A'da) | **≈ 2–3 V** | ≈ 0,6 V | çok düşük |
| Akım (sürekli / tepe) | 1,2 A / 3,2 A | 2 A / 3 A | ≈ 2 A / 3,6 A | 40 A |
| 3,3 V mantık | Evet | Sınırda | Evet | Evet |
| Boyut, ısınma | Küçük, soğuk | Büyük, soğutuculu, ısınır | Küçük | Büyük |
| Bizim için | Uygun | Hassas kontrolde kötü | B motoru için daha rahat | Gereğinden büyük |

**Neden TB6612FNG:** Düşük kayıp, 3,3 V ile doğrudan çalışma, küçük ve ucuz, Türkiye'de kolay bulunuyor. L298N'nin üzerinde 2–3 V kaybolması, motora giden gerilimi hem düşürür hem de akıma bağlı olarak değiştirir; bu da kontrol modelini bozar.

**Eksisi:** 1,2 A sürekli sınır. A motoru için sorun değil. B motorunda normal çalışma ≈ 1 A olduğu için yeterli, ama yazılımda akım sınırı şart. B motoru alınır ve sınır sık sık devreye girerse **DRV8871**'e geçilir.

---

## 5. Kol açısı sensörü: neden AS5600?

- Boşluğu görmenin tek yolu motor açısı ile kol açısını **ayrı ayrı** ölçmek (θ_d). Simülasyonda sürtünme salınımını boşluk salınımından yalnızca bu fark ayırabildi.
- AS5600 temassız (mıknatıslı), 12 bit (0,088°), ucuz, I²C.
- Alternatifler: ikinci bir optik enkoder (daha hassas ama pahalı ve montajı zor), potansiyometre (sürtünme ekler, aşınır, gürültülü).

## 6. Akım sensörü: neden INA219?

- Motor torku akımla orantılı; tork kestirimi ve torkun sıfırdan geçtiği anlar (boşluk olaylarının zamanlaması) için gerekli.
- Ayrıca motorun ısınmasını izler.
- I²C, AS5600 ile aynı hatta.
