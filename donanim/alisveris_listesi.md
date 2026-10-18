# Alışveriş listesi

Düzeneği kurmak için gereken her şey, seçenekleri ve mağazada neye bakılacağıyla birlikte. Telefondan açıp alışveriş sırasında kullanılmak üzere hazırlandı.

Son güncelleme: 18 Ekim 2026. Fiyatlar o günkü site fiyatları; değişmiş olabilir.

---

## Özet

| # | Parça | Adet | Öncelik | Tahmini fiyat |
|---|---|---|---|---|
| 1 | Enkoderli dişli DC motor (12 V) | 2 | **Şart** | 600–700 TL / adet |
| 2 | Motor sürücü TB6612FNG | 1 | **Şart** | |
| 3 | ESP32 geliştirme kartı | 1 | **Şart** | |
| 4 | Manyetik açı sensörü AS5600 (+ mıknatıs) | 1 | **Şart** | ≈ 260 TL |
| 5 | Akım sensörü INA219 | 1 | **Şart** | |
| 6 | 12 V adaptör (≥ 2 A) | 1 | **Şart** | |
| 7 | Breadboard + jumper kablolar | 1 takım | **Şart** | |
| 8 | Rulman (iç çap mil çapına uygun) | 2 | **Şart** | |
| 9 | Kol mili (çelik/alüminyum çubuk) | 1 | **Şart** | |
| 10 | Alüminyum lama (kol) | 1 | **Şart** | |
| 11 | Vida, somun, pul (M3) | 1 takım | **Şart** | |
| 12 | Gövde ve kaplin | — | **Şart** | 3B baskı (aşağıya bak) |
| 13 | Yedek AS5600, yedek kablolar | | İyi olur | |

Tek mağazadan almak kargoyu azaltır. Direnc.net'te 1, 2, 3 (muhtemelen), 5, 6, 7 bulunuyor.

---

## 1. Motor (en önemli parça)

### Ne arıyoruz
| Kontrol | Ne olmalı | Mağazada nasıl anlarsın |
|---|---|---|
| Gerilim | **12 V** | Etiket ya da satıcı |
| Enkoder | **Olmalı** | Arkasında küçük devre kartı ve **6 kablo**: 2 motor (kırmızı, beyaz) + 4 enkoder (VCC, GND, A, B). 2 kablolu olanda enkoder yok |
| Dişli oranı | **1:30 – 1:50** | 12 V'ta boşta hız yaklaşık **120–330 rpm** |
| Durma torku | **≥ 4 kg·cm** | Veri sayfası iste; yoksa model numarasının / etiketin fotoğrafını çek |
| Dişliler | **Metal** | Plastik çabuk aşınır |
| Çıkış mili | **D biçimli** (bir yüzü düz) | Kaplin bağlantısı kolay |
| Adet | **2** | Biri yedek |

### Seçenekler

**A) JGA25-370, 12 V, enkoderli, 1:34 ya da 1:45 (ilk tercih)**
- 25 mm gövde, küçük rotor → dişli rezonansı yüksek → kontrolcü hızında daha geniş pay (ω_c 45 rad/s'ye kadar).
- Türk online mağazalarında **enkoderli sürümü bulunamadı** (Hepsiburada, n11, Trendyol'dakiler enkodersiz). Karaköy'de aranacak.
- Etikette "JGA25-370" ve 6 kablo; 1:34 ≈ 176 rpm, 1:45 ≈ 130 rpm (12 V boşta).

**B) JGB37-520, 12 V, enkoderli, 1:30, 333 rpm (online yedek)**
- [direnc.net, 639 TL](https://www.direnc.net/jgb37-520-12v-330rpm-enkoderli-motor) · [veri sayfası](https://pdf.direnc.net/upload/jgb37-520-datasheet.pdf)
- Nominal 3,5 kg·cm (0,34 N·m) @ 1 A; durma 5 kg·cm (0,49 N·m), 2,3 A; enkoder 11 darbe / motor turu.
- Daha güçlü ama rotor büyük → ω_c ≈ 35 rad/s civarında çalışılmalı (simülasyon: `simulasyon/motor_jgb37.m`).
- Durma akımı 2,3 A, TB6612FNG'nin 1,2 A sürekli sınırının üstünde → yazılımda akım sınırı konacak.
- Aynı serinin diğer oranları (12 V): 1:19 = 530 rpm, 3,1 kg·cm durma (biraz zayıf); 1:56 = 178 rpm, 9 kg·cm (güçlü ama motor eylemsizliği daha da büyür). **1:30 en dengelisi.**

**C) SAMM Market "L tipi enkoderli metal dişli DC motor", 12 V, 1:42**
- [market.samm.com](https://market.samm.com/en/l-tipi-enkoderli-metal-disli-dc-motor), ≈ 826 TL. Nominal 4 kg·cm, durma ≥ 8,5 kg·cm, enkoder 13 darbe/tur, 6 mm mil.
- 18 Ekim'de **stokta yoktu**.

**Almayın:**
- Enkodersiz motorlar (2 kablolu).
- N20 boyutu mini motorlar (JGA12-N20B): tork çok düşük.
- Hobi servolar (SG90, MG996R): içindeki hazır kontrolcü bizim kontrolcümüzü devre dışı bırakır.

---

## 2. Motor sürücü: TB6612FNG

- 1,2 A sürekli, 3,2 A tepe; motor beslemesi 4,5–13,5 V; mantık 3,3 V ile çalışır (ESP32'ye doğrudan bağlanır).
- **STBY** pini HIGH yapılmazsa motor dönmez (en sık yapılan hata).
- Nereden: [direnc.net](https://www.direnc.net/tb6612fng-dc-ve-step-motor-surucu-modulu) · [robotistan](https://www.robotistan.com/tb6612fng-stepper-motor-dc-motor-driver) · [robolinkmarket](https://www.robolinkmarket.com/motor-surucu-1a-cift-dc-tb6612fng)
- Alternatif: motorun durma akımı yüksekse (JGB37: 2,3 A) daha güçlü bir sürücü düşünülebilir, ama normal çalışmada akım ≈ 1 A; şimdilik TB6612FNG yeterli.
- **Almayın:** L298N. Üzerinde ~2 V gerilim düşer ve ısınır; hassas kontrol için kötü.

## 3. ESP32 geliştirme kartı

- Herhangi bir **ESP32-WROOM-32 DevKit** (30 ya da 38 pinli). USB üzerinden programlanır.
- Kontrol döngüsü 1 kHz; Arduino Uno bunun için yavaş kalıyor.
- USB çipi **CP2102** ya da **CH340** olabilir; ikisi de olur (CH340 için Windows sürücüsü gerekebilir).
- Pinleri lehimli (header'lı) olanı al, breadboard'a takılsın.

## 4. Manyetik açı sensörü: AS5600

- 12 bit (0,088°), I²C, 3,3 V. Kol milinin ucuna konacak; kolun açısını motor enkoderinden bağımsız ölçer.
- **Modülle birlikte diametral mıknatıs gelmeli** (6 mm çapında, 2–3 mm kalınlığında küçük disk; kuzey-güney kutbu yan yana). Gelmezse ayrıca "AS5600 mıknatıs" ya da "diametral mıknatıs 6x2,5" diye ara. Normal (eksenel) mıknatıs çalışmaz.
- Nereden: [Çiçeksepeti, ALKATRONİK, ≈ 258 TL](https://www.ciceksepeti.com/as5600-manyetik-aci-sensoru-olcum-modulu-12-bit-temassiz-pozisyon-kcm45524464). Direnc.net ve Robotistan'da da bakılmalı.
- Ucuz olduğu için **2 adet** almak mantıklı.

## 5. Akım sensörü: INA219

- I²C, ±3,2 A (0,1 Ω şant ile), 3–5 V. Motorun çektiği akımı ölçer: tork kestirimi ve ısınma takibi için.
- Nereden: [direnc.net](https://www.direnc.net/ina129-cift-yonlu-akim-sensor-modulu-en)
- AS5600 ile aynı I²C hattına bağlanır; adresleri farklı (AS5600: 0x36, INA219: 0x40), çakışma yok.

## 6. Güç kaynağı

- **12 V, en az 2 A** adaptör (DC jak). 3 A olursa daha rahat.
- Jak için bir **DC dişi jak → klemens** adaptörü al (breadboard'a bağlamak için).
- ESP32 USB'den beslenecek (bilgisayardan).

## 7. Breadboard ve kablolar

- Tam boy breadboard (830 delik).
- Jumper kablo takımı: erkek-erkek, erkek-dişi, dişi-dişi.
- Motorun enkoder kablosu genellikle **PH2.0 6 pinli** soketle gelir; soket kablosu motorla gelmezse "PH2.0 6 pin kablo" al.

## 8–11. Mekanik parçalar

| Parça | Ne | Not |
|---|---|---|
| Rulman | 2 adet; iç çapı kol miliyle aynı (ör. **4 mm iç çaplı 684ZZ** ya da **8 mm iç çaplı 608ZZ**) | Kol milini taşır; mil çapına göre seç |
| Kol mili | 8–10 cm, rulmanın iç çapında çelik ya da alüminyum çubuk | Hırdavat / maket mağazası |
| Kol | **15 cm** alüminyum lama (ör. 15×2 mm) | Hafif olmalı; kütle ≈ 20 g |
| Uç ağırlıkları | M5–M6 somun / pul | Deneyde değiştirilecek ağırlık (≈ 20 g'dan başla) |
| Vida takımı | M3 vida, somun, pul | Motor flanşı ve gövde için (JGA25 ve JGB37 flanşları M3) |

## 12. Gövde ve kaplin

**Kaplin** motor milini kol miline bağlayan parça. Bizim kaplin bilerek "boşluklu" olacak: motor tarafında bir dil, kol tarafında dilden biraz geniş bir yuva. Yuva genişliği boşluğu belirler; **1,5°, 3° ve 5°** için üç farklı parça basılacak ve deneyde değiştirilecek. Hazır satılmaz.

**Gövde** motoru ve rulmanları aynı eksende tutan taşıyıcı.

İkisi için de seçenekler:
- **3B yazıcı** (kendinin ya da okulun). Tasarım dosyaları bu klasöre eklenecek.
- **3B baskı servisi** (online ya da Karaköy'deki atölyeler).
- 3B baskı mümkün değilse: gövde için alüminyum köşebent; kaplin için sabit bir metal kaplin (motor tarafı 4 ya da 6 mm, kol tarafı mil çapına göre). Bu durumda ayarlanabilir boşluk yerine yalnızca motorun kendi dişli boşluğu kullanılır.

---

## Mağazada hatırlatmalar

- Motorun **model numarasını ve etiketini fotoğrafla**; veri sayfası yoksa sonradan bakılır.
- Motor milinin çapını öğren (JGA25: 4 mm, JGB37: 6 mm); kaplin tasarımı buna göre yapılacak.
- AS5600'ün mıknatısla gelip gelmediğini sor.
- Kartların pinlerinin lehimli olup olmadığına bak.
