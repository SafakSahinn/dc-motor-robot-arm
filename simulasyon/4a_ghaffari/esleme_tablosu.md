# Boyutsuz oranların ve kontrolcü parametrelerinin eşlemesi

Kaynaklarda aynı sembol farklı büyüklükleri gösterebildiği için bu çalışmada tek bir tanım takımı kullanılır ve her kaynağın değerleri bu tanımlara çevrilir. Bütün büyüklükler kol (yük) tarafına indirgenmiştir.

## 1. Tanımlar

| Sembol | Tanım | Anlamı |
|---|---|---|
| R | J_L / J_M | Eylemsizlik oranı (Ghaffari'nin R'si) |
| ω_a | √(K_s / J_L) | Karşı-rezonans |
| **r_gs** | √(k_p k_v / K_s) | Sertlik oranı (Ghaffari 2013). C. Wang 2017'nin r_s'si aynı tanım. |
| **ρ** | ω_c / ω_rez, ω_rez = √(K_s / J_eff), J_eff = J_M J_L/(J_M + J_L) | Bu çalışmanın ilk simülasyonlarındaki oran (eski adı r_s) |
| **γ** | mgℓ sin θ₀ / (K_s r) | Yerçekimi ön yükü / boşluğun yarı genişliğini kapatan temas torku. Yerçekimli DF'deki tek açı parametresi. |
| φ | F_C / (K_s r) | Coulomb sürtünmesi / temas torku |
| ζ_c | c_s / (2 √(K_s J_eff)) | Temas modunun sönüm oranı |
| μ | mgℓ / T_max | Tork payı (yerçekiminin motor torkundan aldığı pay) |

**Dönüşüm:** r_gs = ρ (J_M + J_L)/√(J_M J_L) = ρ (1 + R)/√R. R = 1'de r_gs = 2ρ; R = 0,17'de 2,86ρ; R = 24'te 5,1ρ.

## 2. Kontrolcü eşlemesi: P–PI (Ghaffari, C. Wang, Sun) ↔ PID (bu çalışma)

P–PI kaskadı (konum P, hız PI, hız motor enkoderinden):

u = K_V (k_p e − v) + K_I ∫(k_p e − v) dt = (K_V k_p) e + (K_I k_p) ∫e dt − K_V v − K_I (θ_M − θ_M,0)

| PID | P–PI karşılığı | Not |
|---|---|---|
| K_p | K_V k_p | r_gs = √(K_p / K_s) her iki yapıda |
| K_d (motor hızından) | K_V | Ghaffari'nin k_v'si (kol tarafı) |
| K_i | K_I k_p | Ghaffari'nin T_i'si: K_I = 1/T_i (kol tarafı) |
| — | −K_I (θ_M − θ_M,0) | P–PI'nin fazlası: motor açısına zayıf bir "yay". Bu çalışmanın ayarında K_I = 0,05 ω_a K_V, etkisi küçük. |

Motor tarafı → kol tarafı: k_v,kol = k_v,motor N², T_i,kol = T_i,motor / N², K_s ve J aynı kuralla.

PID'nin rijit model ayarında (K_p = J ω_c², K_d = 1,4 J ω_c) r_gs = ω_c √(J/K_s), yani r_gs = ρ √(J/J_eff).

## 3. Kaynakların değerleri

Makalede verilenler düz, hesaplananlar *italik*.

| | R | f_a | k_p (1/s) | k_v (N·m·s/rad) | r_gs | ρ | γ(90°) | ζ_c | μ | Gözlenen |
|---|---|---|---|---|---|---|---|---|---|---|
| Ghaffari 2013, Şekil 7 (sim.) | 2,12 | 11 Hz | 11,67 | 20 (motor) | *0,99* | *0,46* | 0 | *0,024*⁴ | — | 10,3 Hz çevrim |
| Ghaffari 2013, döner tabla 9a / 9b | 0,79 | 15,3 Hz | — | — | 1,17 / 1,33 | *0,58 / 0,66* | 0 | — | — | 15,3 Hz (rezonans) |
| C. Wang 2017, k_p 50 | 24 | *15,8 Hz* (ölçülen 15,6) | 50 | 0,38 | 0,66 | *0,13* | 0 | — | 0 | 10,2 Hz çevrim |
| C. Wang 2017, k_p 150 | 24 | | 150 | 0,38 | 1,15 | *0,23* | 0 | — | 0 | 15,6 Hz |
| C. Wang 2017, J_L = 42 J_M | 42 | *11,9 Hz* | 50 | 0,38 | 0,66 | *0,10* | 0 | — | 0 | 7,67 Hz |
| Sun 2023, K_p 20 | *0,70* | *38,9 Hz* | 20 | *≈ 6,4*¹ | *≈ 0,15*¹ | *≈ 0,07* | *0,024*² | — | *0,04*³ | salınım yok |
| Sun 2023, K_p 50 | *0,70* | | 50 | *≈ 6,4*¹ | *≈ 0,23*¹ | *≈ 0,11* | *0,024*² | — | *0,04*³ | 90°'de ≈ 5°, 9 Hz |
| Bu çalışma, A (dengeli liste) | 0,17 | 20,5 Hz | 4,6–15 | 0,54 | 0,5–0,9 | 0,18–0,32 | 0,17 | 0,14 | 0,09 | harita: `yercekimli_sonuclar.md` |
| Bu çalışma, D (ağır uç) | 1,0 | 8,4 Hz | 6,6–21 | 0,38 | 0,5–0,9 | 0,25–0,45 | 0,92 | 0,075 | 0,49 | harita: `yercekimli_sonuclar.md` |

¹ Sun 2023 hız döngüsünün PI katsayılarını vermiyor ("moderate"). k_v, gözlenen 9 Hz'den Ghaffari'nin denklem 12'siyle (f ≈ √(k_p k_v / J_L) / 2π) geri çıkarıldı. Bu ilişki rezonans rejiminde (r_gs > 0,4) geçerli; çıkan r_gs ≈ 0,23 çarpma rejimine düştüğü için değer yalnız büyüklük mertebesi.
² Sun 2023: iki motor (her biri 1,8·10⁻⁴ kg·m², N = 20 → J_M = 0,144), yük 8,3 kg × 0,11 m (J_L ≈ 0,100, nokta kütle), dal başına K_s = 3000 N·m/rad (eşzamanlı sürüşte iki dal paralel: 6000), b = 3,5° yarı genişlik ("boşluk mesafesi 2b"), mgℓ = 8,96 N·m. Tek dal sertliğiyle γ = 0,049.
³ Anma torku 2,1 N·m, 3 kat aşırı yük, iki motor, N = 20 → T_max ≈ 252 N·m.
⁴ Makalede verilmiyor; Şekil 7'nin yeniden üretiminde kalibre edilen değer ([`sekil78_sonuclar.md`](sekil78_sonuclar.md)): ω_a'ya göre ξ = 0,0135 (c_s = 2ξK_s/ω_a), buradaki tanımla ζ_c = ξ√(1 + R) ≈ 0,024.

## 4. Gözlemler

- **Ön yük oranı:** Ghaffari'nin ön yükü (Şekil 2c–d, τ_p) yaylı anti-boşluk mekanizmasından gelen simetrik bir iç gerilimdir; deneyleri yalnız boşluklu düzenekte. γ'nın tek yönlü, açıya bağlı karşılığı literatürde yok. C. Wang 2017'de yük torku sıfır (γ = 0); "yüksüzken sistem her zaman temasta değil" gözlemi γ = 0 durumunun kendisi.
- **Sun 2023 ile tutarlılık:** γ(90°) ≈ 0,02–0,05; yerçekimli DF'ye göre bu ön yükte etkin kazancın en küçük değeri n₁,min ≈ 0,04–0,08, yani bastırma neredeyse yok ve sınır Ghaffari'ninkine çok yakın. 90°'de bile salınım görülmesi bununla uyumlu. K_p = 20'de salınımın görülmemesini yazarlar yavaş geçişin titreşimi uyarmamasına bağlıyor; bu, yerçekimli DF'nin öngördüğü ve benzetimde doğrulanan iki kararlılıkla (`rejim_siniflandirma.md`, ek) nitel olarak tutarlı. Nicel yeniden üretim için hız PI katsayıları ve temas sönümü gerekli; makalede yok.
- **Ölçek:** Bu çalışmanın düzenekleri γ ekseninde Sun 2023'ün 7–40 katı. Yerçekiminin etkisini görünür kılan şey yükün büyüklüğü değil, γ'nın (yük / boşluk × sertlik) büyüklüğü.
- **Temas sönümü:** Ghaffari'nin Şekil 7'si ancak küçük bir temas sönümüyle (ζ_c ≈ 0,024) yeniden üretilebildi; bu çalışmada K_s ve c_s tahminiyle ζ_c = 0,075 (D) ve 0,14 (A). Yerçekimli DF'de temas sönümünün etkisi A'da büyük (kritik kazanç hatası %55 → %27). Kaynakların hiçbiri c_s'yi raporlamıyor; düzenekte tanılanması gerekir.

## 5. Rejim adlarının eşlemesi

| Ghaffari 2013 | C. Wang 2017 | Bu çalışma (`rejim_sinifla`) | Yerçekimli DF |
|---|---|---|---|
| r_gs ≥ 1: kararsız (mekanik rezonans, ω_a) | r_s ≥ 1: ω_lc = ω_ARF | kararsız (4); tork sınırıyla kalıcı çevrim ya da düzensiz (3, 5) | X; tork sınırıyla S |
| 0,4 < r_gs < 1: rezonans çevrimi | 0 < r_s < 1: ω_lc = r_s ω_ARF | kalıcı çevrim (3) | C (n_req > n₁,min(γ)) |
| r_gs ≤ 0,4: çarpma çevrimi | — | kalıcı çevrim (3), boşlukta geçen süre yüksek; başlangıca bağlı | C, DF zayıf |
| — | — | denge (0), sönümlü titreşim (1) | . (n_req ≤ n₁,min(γ)) |
| — | — | zorlanmış cevap (2) | DF kapsamı dışı (dış zorlama) |
| — | — | iki kararlılık: denge + çevrim | C ve γ > 0 (eşik a₁) |
