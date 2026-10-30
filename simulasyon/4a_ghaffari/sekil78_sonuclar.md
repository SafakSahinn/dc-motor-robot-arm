# 4a Adım 4: Şekil 7 ve 8'in yeniden üretimi

Kod: [`ghaffari2013.m`](ghaffari2013.m), [`ghaffari_param.m`](ghaffari_param.m), [`ghaffari_duyarlilik.m`](ghaffari_duyarlilik.m), [`sonum_tarama.m`](sonum_tarama.m), [`ghaffari_sekil78.m`](ghaffari_sekil78.m). Kayıtlar: [`duyarlilik_log.txt`](duyarlilik_log.txt), [`sonum_tarama_log.txt`](sonum_tarama_log.txt). Makaledeki şekiller: [`sekiller/sekil07_rezonans_sim.png`](sekiller/sekil07_rezonans_sim.png), [`sekiller/sekil08_carpma_sim.png`](sekiller/sekil08_carpma_sim.png).

## Sonuç

Kalibre edilmiş tek parametre kümesiyle (viskoz sürtünme 0, temas sönümü ξ = 0,0135, kp = 11,67, kv = 20) iki rejim de yeniden üretildi: [`sekil78_kalibre.png`](sekil78_kalibre.png).

| | Makale (şekilden) | Bu model | Fark |
|---|---|---|---|
| Şekil 7, frekans | ≈ 10,3 Hz | 10,10 Hz | −%2 |
| Şekil 7, θd genliği | ≈ 1,05° | 1,08° | +%3 |
| Şekil 7, burulma genliği | ≈ 1,0° | 0,96° | −%4 |
| Şekil 7, hızlar (komut / motor / yük) | ≈ ±2 / ≈ 0 / ±11 rpm | ±2 / ≈ 0,3 / ±11 rpm | — |
| Şekil 8, frekans | ≈ 2,4 Hz | 2,61 Hz | +%9 |
| Şekil 8, θd | ±0,10°'de düzleşiyor | ±0,12°'de (= δ) düzleşiyor | — |
| Şekil 8, burulma darbeleri | ±2·10⁻³° | ±2,7·10⁻³° | — |
| Şekil 8, hızlar | ±0,2 rpm testere dişi, yük basamaklı | aynı biçim, ±0,22 rpm | — |

Denklem 12 Şekil 7 için 10,9 Hz, denklem 19 Şekil 8 için (π/2)·kp = 2,9 Hz öngörüyor.

## Farkı ne belirliyor? (duyarlılık)

| Etken | Şekil 7'ye etkisi | Şekil 8'e etkisi |
|---|---|---|
| Benzetim süresi (7 → 20 s) | yok | yok |
| Başlangıç sapması (0,05–5°) | yok | **var:** ≤ 0,2°'de çevrim, ≥ 1°'de sistem boşluk içinde durgun kalıyor |
| Integral terimi (Ti → ∞) | küçük (8,81 → 8,76 Hz) | yok |
| Viskoz sürtünme (cm, cle) | **büyük:** varken 8,8 Hz / 0,44°, yokken 9,8 Hz / 0,78° | orta: 2,1 ↔ 2,6 Hz |
| Temas sönümü ξ (0 → 0,1) | **büyük:** 9,9 Hz / 0,84° → 6,2 Hz / 0,22° | küçük |
| r_gs: başlık değerleri | kazançlar r_gs = 0,9 verecek biçimde: 9,1–9,2 Hz / 0,50–0,55° | r_gs = 0,17: 5,5–6,1 Hz |

## Çıkarımlar

1. **Şekil 7/8'in r_gs tutarsızlığı çözüldü.** Başlıktaki 0,9 ve 0,17 değerleri makalenin kendi eğrilerini üretmiyor (Şekil 8'de frekans 2,4 yerine 5,5–6,1 Hz çıkıyor); parametrelerden hesaplanan 0,99 ve 0,11 üretiyor. Şekiller kp = 11,67, kv = 20 ile çizilmiş; başlıklardaki r_gs değerleri hatalı.
2. **Makalenin benzetimi viskoz sürtünmesiz.** Döner tablanın cm, cle değerleriyle Şekil 7 tutmuyor (−%14 frekans, −%59 genlik); viskoz sürtünme sıfır ve küçük bir temas sönümüyle (ξ ≈ 0,013–0,015) tutuyor. Adım 1'deki karar 2 bu kanıta göre güncellendi; ghaffari_param varsayılanları döner tabla için aynen kalıyor.
3. **r_gs ≈ 1 yakınında genlik sönüme çok duyarlı.** Sönüm tamamen kaldırılınca genlik 5,3°'ye çıkıyor (r_gs = 0,99, kararsızlık sınırında); ξ = 0,0025 → 3,3°, 0,01 → 1,4°. Frekans ise 10,0–10,7 Hz aralığında kalıyor. Sınıflandırma ve sınır öngörüsünde frekans genlikten daha sağlam bir ölçüt.
4. **Çarpma rejiminde sonuç başlangıç koşuluna bağlı.** Boşluk içinde (|θd| < δ) yük hedefte, motor durgunken her konum bir denge; büyük bir başlangıç sapması sistemi bu dengelerden birine taşıyabiliyor. Kalıcı çevrim ile boşluk içi denge aynı parametrelerde birlikte var. Bu, rejim sınıflandırıcısında (Adım 6) ve deneyde uyarım protokolünün tanımlanmasını gerektiriyor: aynı noktada birden fazla başlangıç sapmasıyla deneme.
