# 4a: Ghaffari ve Mohammadiasl 2013, parametreler ve kararlar

Kaynak: A. Ghaffari, E. Mohammadiasl, "Calculating the frequency of oscillation for servo axes distressed by clearance or preloading," IEEE/ASME TMECH, 18(3), 922–931, 2013. DOI 10.1109/TMECH.2012.2195670.

## Model

- İki kütle: motor (Jm) ve yük (Jl), çevrim oranı kr, burulma sertliği ks, yük tarafında boşluk ±δ (Şekil 2b).
- Yansıtılmış büyüklükler: Jle = Jl/kr², cle = cl/kr², kse = ks/kr², R = Jle/Jm.
- Karşı-rezonans ωa = √(ks/Jl) = √(kse/Jle); rezonans ωr = ωa·h, h = √(1+R).
- Kontrolcü P–PI kaskad: konum P (kp, yük sensörü) → hız PI (kv, Ti, motor enkoderi). Akım döngüsü 1 alınır.
- Tek döngü biçimi (Şekil 5): G(s) denklem 5, H(s) denklem 6; DF: n(θd) denklem 10.

## Sertlik oranı ve rejimler (denklem 7, 20)

r_gs = √(kp·kv / kse) ≈ ωcr/ωa

| r_gs | Rejim | ω_lc |
|---|---|---|
| ≥ 1 | Kararsız | ωa |
| 0,4 – 1 | Rezonans, kalıcı çevrim | √(kp·kv / Jle) |
| ≤ 0,4, R ≥ 1,3 | Çarpma | (π/2)·kp |
| ≤ 0,4, R < 1,3 | Çarpma | (π/2)·(1+e)/(1−e)·kp |

## Parametre tablosu

Makalede verilenler düz, hesaplananlar *italik*.

| | Şekil 7 (sim.) | Şekil 8 (sim.) | Döner tabla, Şekil 9a | Döner tabla, Şekil 9b |
|---|---|---|---|---|
| Jm (kg·m²) | 0,0235 | 0,0235 | 0,0231 | 0,0231 |
| R | 2,12 | 2,12 | 0,788 | 0,788 |
| kr | 766 | 766 | 1211,65 | 1211,65 |
| fa | 11 Hz | 99 Hz | 15,3 Hz | 15,3 Hz |
| δ (yük tarafı) | 0,12° | 0,12° | 0,04° | 0,04° |
| Ti | 10 ms | 10 ms | 40 ms | 40 ms |
| kp (1/s), kv (N·m·s/rad) | 11,67; 20 | 11,67; 20 | — | — |
| kp·kv | *233,4* | *233,4* | *230,3* (r_gs'den) | *297,6* (r_gs'den) |
| Jle (kg·m²) | *0,0498* | *0,0498* | *0,0182* | *0,0182* |
| kse (N·m/rad) | *238,0* | *19 277* | *168,2* | *168,2* |
| fr | *19,4 Hz* | *174,9 Hz* | *20,5 Hz* | *20,5 Hz* |
| r_gs | *0,99* | *0,11* | 1,17 | 1,33 |
| Beklenen ω_lc | *10,9 Hz* (rezonans) | *2,9 Hz* (çarpma) | 15,3 Hz | 15,3 Hz |

Döner tabla sürtünmeleri (Ek): cm = 0,0421 N·m·s/rad, cle = 0,0982 N·m·s/rad, Coulomb motor 6 N·m, yük "2·kr N·m" (motora yansıyan 2 N·m). Konum ölçümü 36 000 çizgi/tur.

Öteleme ekseni (Ek, çarpma rejimi deneyi): Ti = 6 ms, Jm = 0,1417 kg·m², kr = 100π, fa = 38 Hz, R = 0,44, boşluk 0,4 mm; cm = 0,156 N·m·s/rad, cle = 0,067 N·s, Coulomb motor 5,2 N·m, yük 94,2 N, statik 188,5 N, Stribeck hızı 0,8 mm/s; e = 0,35.

## Kararlar

1. **Şekil 7/8'in r_gs değerleri: makale içi tutarsızlık.** Şekil başlıklarında kp = 11,67, kv = 20 ile r_gs = 0,9 (ωa = 11 Hz) ve 0,17 (ωa = 99 Hz) yazıyor; aynı parametrelerden denklem 7 ile 0,99 ve 0,11 çıkıyor. Kazançlar sabitken r_gs ∝ 1/ωa olduğundan iki şeklin oranı 99/11 = 9 olmalı; 0,9/0,17 = 5,3. Tek bir tanım ikisini birden açıklamıyor: 0,9 için R ≈ 2,57, 0,17 için R ≈ 0,89 gerekirdi. Karar: Şekil 7/8 makalenin parametreleriyle (r_gs = 0,99 ve 0,11) üretilir; ek olarak ωa sabitken kazançlar r_gs = 0,9 ve 0,17 verecek biçimde ayarlanıp aynı rejimlerin görüldüğü sınanır. Şekillerden okunan değerler (Adım 4'te karşılaştırma için): Şekil 7 ≈ 10,3 Hz, θd genliği ≈ 1,05°; Şekil 8 ≈ 2,4 Hz, θd ±0,10°'de düzleşiyor.
2. **Şekil 7/8'in sürtünme ve sönümü.** Makalede verilmiyor. Karar: viskoz terimler döner tabladan (cm = 0,0421, cle = 0,0982), Coulomb sürtünme sıfır (makalenin DF analizindeki varsayımla aynı). Döner tabla taraması makalenin verdiği gerçek sürtünmelerle yapılır.

## Adımlar

1. Parametre tablosu ve kararlar (bu belge).
2. Deney verisinin sayısallaştırılması: Şekil 11 (kp ve kv taraması, deney / simülasyon / DF) ve Tablo I.
3. MATLAB modeli `ghaffari2013.m`: P–PI, ölü bölgeli boşluk, viskoz ve Coulomb sürtünme.
4. Şekil 7/8 rejimlerinin üretimi.
5. Döner tabla taraması; denklem 12 ve tam DF çözümüyle karşılaştırma, hata Tablo I ile kıyaslanır.
6. Rejim sınıflandırıcısı: sönümlü titreşim, zorlanmış cevap, kalıcı çevrim, kararsızlık.
7. Bu çalışmanın modeline bağlantı: yerçekimsiz ve P–PI ile aynı r_gs'de aynı rejimler; JGB37 için r_gs ↔ ρ katsayısı.
