# Alışveriş listesi

Düzeneği kurmak için gereken her şey. Seçim ilkesi: **bilinen üretici, eksiksiz veri sayfası, yetkili satıcı.** Neden bu parçalar: [`tasarim_kararlari.md`](tasarim_kararlari.md).

Fiyatlar üretici ya da yetkili satıcı sitelerindeki liste fiyatları (KDV, kargo ve gümrük hariç); değişebilir.

---

## Özet

| # | Parça | Üretici / model | Adet | Nereden | Liste fiyatı |
|---|---|---|---|---|---|
| 1 | Motor + dişli + enkoder | **maxon** DCX 22 L (12 V) + GPX 22 LZ 26:1 + ENX 16 EASY 1024 CPT | 1 | maxon çevrimiçi mağaza (kombinasyon) | ≈ 472 € |
| 2 | Motor sürücü | **Pololu #4035** (TI DRV8874) | 2 | Pololu / yetkili satıcı | ≈ 12 $ / adet |
| 3 | Denetleyici | **Espressif ESP32-DevKitC** (WROOM-32E) | 1 | DigiKey / Mouser | |
| 4 | Kol açısı enkoderi | **Same Sky (CUI) AMT22**, 14 bit, tek tur, kol mili çapında manşon | 1 | DigiKey / Mouser | |
| 5 | Akım sensörü | **Adafruit #5832** (TI INA228, 20 bit) | 1 | Adafruit / yetkili bayi | ≈ 15 $ |
| 6 | Sıcaklık sensörü | **Adafruit TMP117** (TI TMP117, ±0,1 °C) | 2 | Adafruit / yetkili bayi | |
| 7 | RS-422 alıcı | **TI AM26LV32E** (3,3 V) + SOIC-16 adaptör kartı | 1 (+1 yedek) | DigiKey / Mouser | |
| 8 | Güç kaynağı | **Mean Well** 12 V, ≥ 3 A | 1 | yetkili bayi | |
| 9 | Rulman | **SKF / NSK / FAG**, kol mili çapında | 2 | rulmancı | |
| 10 | Kol mili, kol, uç ağırlıkları, vidalar | çelik mil, 15 cm alüminyum lama, M5–M6 somun/pul, M3/M2 vida | | hırdavat | |
| 11 | Gövde ve boşluklu kaplin | 3B baskı (1,5° / 3° / 5° kaplin parçaları) | | kendi/okul yazıcısı ya da baskı servisi | |
| 12 | Breadboard, jumper, lehim malzemesi | | | | |

Sürücüden iki adet: biri yedek, ya da ileride ikinci eklem için.

---

## 1. maxon motor kombinasyonu

maxon dişli kutusunu ve enkoderi yalnızca motorla birlikte, bir **kombinasyon** olarak satıyor. Çevrimiçi mağazada "Start combination" ile:

| Bileşen | Seçim | Liste fiyatı (1–4 adet) |
|---|---|---|
| Motor | **DCX 22 L**, sargı **12 V** (değerli metal fırça) | 220,41 € |
| Dişli kutusu | **GPX 22 LZ**, 2 kademe, **26:1** (azaltılmış boşluk, 0,85°) | 150,63 € |
| Enkoder | **ENX 16 EASY**, **1024 CPT**, 3 kanal, RS-422 | 101,05 € |
| **Toplam** | | **≈ 472 €** + KDV, kargo, gümrük |

Yapılandırıcıda kontrol edilecekler:
- 12 V sargının bu fırça/yatak seçeneğinde bulunması ve kataloğdaki değerler (nominal 1,30 A, durma 6,54 A, k_t 22,9 mN·m/A, R 1,84 Ω).
- GPX 22 çıkış mili çapı ve biçimi (kaplin tasarımı buna göre).
- Enkoder kablosu/konnektörü (RS-422 için diferansiyel çiftler).
- Türkiye'ye gönderim ve teslim süresi. maxon'un Türkiye'de bir satış ortağı bulunamadı.

**Almayın:** markasız "enkoderli dişli motor"lar (JGA25-370, JGB37-520 vb.). Veri sayfaları tutarsız, enkoderleri 11 darbe/tur.

## 2. Motor sürücü: Pololu #4035 (TI DRV8874)

- 2,1 A sürekli (oda sıcaklığı, ek soğutma yok), 4,5–37 V, mantık 1,8–5 V.
- Akım ölçüm çıkışı (CS, ≈ 1,1 V/A) ve ayarlanabilir akım sınırı: **≈ 2 A'e ayarlanacak** (motorun durma akımı 6,54 A).
- Kontrol modu: PH/EN. EN'ye 20 kHz PWM, PH yön; nSLEEP HIGH.
- **Almayın:** TB6612FNG (önerilen en fazla 1,0 A sürekli), L298N (2–3 V kayıp).

## 3. ESP32-DevKitC (Espressif)

- Espressif'in kendi kartı, WROOM-32E modüllü; taklit "ESP32 DevKit" kartları değil.
- Yetkili distribütörden (DigiKey, Mouser) alınmalı.
- 5 V pini (USB'den) maxon enkoderini ve AMT22'yi besler.

## 4. Kol açısı: AMT22

- 14 bit mutlak, tek tur, SPI; doğruluk ±0,2°; 100 µs güncelleme.
- Manşon seti 2–8 mm; kol mili çapına uyanı (ör. 6 ya da 8 mm) seçilecek. Mıknatıs gerekmez.
- Besleme 5 V, çıkış 3,3 V seviyesinde.

## 5. Akım: Adafruit INA228 (#5832)

- 20 bit, I²C, 85 V'a kadar ortak mod, 0,1 % hassasiyetli şant.
- Motor hattına seri bağlanır (çift yönlü). PWM geçişleri ölçümü bozarsa sürücünün besleme hattına alınır.

## 6. Sıcaklık: Adafruit TMP117 × 2

- ±0,1 °C (−20…50 °C), 16 bit, I²C.
- Biri ortam (düzenekten uzakta), biri motor gövdesinde (ısı iletken yapıştırıcıyla).
- Adresler 0x48 ve 0x49 (ikincisinin ADDR ayarı değiştirilir).

## 7. RS-422 alıcı: TI AM26LV32E

- 3,3 V ile çalışan dört kanallı diferansiyel alıcı; maxon enkoderinin A, B, I kanallarını ESP32'nin 3,3 V girişlerine çevirir.
- SOIC-16 kılıf → SOIC-16'dan DIP'e adaptör kartına lehimlenir.

## 8. Güç: Mean Well 12 V, ≥ 3 A

- DC jak + jak→klemens adaptörü.

## 9–11. Mekanik

| Parça | Ne | Not |
|---|---|---|
| Rulman | 2 adet SKF / NSK / FAG; iç çapı kol miliyle aynı (ör. 6 mm 626-2Z ya da 8 mm 608-2Z) | Kol milini taşır |
| Kol mili | 8–10 cm, rulman iç çapında çelik mil | AMT22 manşonu da bu çapta |
| Kol | 15 cm alüminyum lama (≈ 15×2 mm) | Hafif; kütle ≈ 20 g |
| Uç ağırlıkları | M5–M6 somun / pul | ≈ 20 g'dan başla |
| Gövde | 3B baskı ya da alüminyum köşebent | Motor flanşı ve iki rulman aynı eksende |
| Kaplin | 3B baskı, dil + yuva; yuva genişliği 1,5° / 3° / 5° | Toplam boşluk ≈ dişli (0,85°) + kaplin |

---

## Sipariş öncesi kontrol listesi

- [ ] maxon kombinasyonu yapılandırıldı, mil çapı ve kesin fiyat alındı.
- [ ] Simülasyon maxon değerleriyle tekrarlandı (tork ve kontrolcü hızı payı).
- [ ] AMT22 manşon çapı ile rulman ve kol mili çapı aynı.
- [ ] Kartların orijinal olduğu (yetkili satıcı) doğrulandı.
