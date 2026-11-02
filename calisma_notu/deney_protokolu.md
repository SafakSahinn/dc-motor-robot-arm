# Deney protokolü: sistem tanılama ve salınım sınırı (donanım)

Bu belge, dijital ikizde (`simulasyon/simulink/`, README madde 4.3) sınanan tanılama yöntemlerini donanımda uygulanacak sıralı bir deney listesine çevirir. Her deneyin yöntemi, benzetimdeki doğruluğu ve gerekçesi README'de; burada yalnız **ne yapılacağı, hangi ayarla, kaydın ne zaman geçerli sayılacağı** var. Analiz betikleri benzetimdeki betiklerle aynı; yalnız girdi, benzetim yerine firmware kaydı olur (`olcum_oku` → `K` biçimi).

Sayılar D düzeneğinin benzetim değerleridir (J_M = J_L = 0,0036 kg·m², K_s = 10 N·m/rad, 2r = 3°, mgl = 0,24 N·m). Donanımda farklı çıkacakları için "beklenen" sütunları yalnız kabaca denetim içindir.

## 0. Ortak ayarlar

| Konu | Ayar | Neden |
|---|---|---|
| Döngü ve kayıt | 1 kHz, kayıt **seyreltmesiz** (her örnek): t, θ_L (AS5600 ham), φ (enkoder sayımı), v̂, u, V (PWM görev oranından), i | 4.3'te 5 ms'lik kayıt K_m ve J_M'yi %4–13 bozdu (README 4.2 düzeltmesi) |
| Hız kestirimi | **Gözlemci** (iki satırlık Euler güncellemesi), bütün deneylerde aynı | Sınır kestiriciye bağlı (README yan soru: fark +0,05–0,10, periyot −0,15). Periyot yöntemi kullanılmaz |
| Kontrolcü | P–PI (k_p = r_gs²·K_s/K_V, K_V, K_I benzetimle aynı) | r_gs ekseni Ghaffari tanımıyla |
| Sürücü modu | **Mod 1 (gerilim), bütün deneylerde** | Hızlı akım döngüsü gerekmiyor: tanılama mod 1'de de aynı doğrulukta (README 4.3, 4e). Akım yalnız kayıt için |
| Meta veri | Firmware sürümü, kazançlar, mod, kestirici, sıcaklıklar, uç kütlesi | Benzetim aynısıyla kurulur |

## 1. Deney sırası

Sıra bağımlılığa göre: her deney öncekilerin sonucunu kullanır. D1–D2 kol sökülü, D3–D4 kol takılı, D5 motor kilitli, D6 asıl deney.

| # | Düzenek | Ne yapılır | Süre × tekrar | Çıkan | Benzetimde doğruluk | Betik |
|---|---|---|---|---|---|---|
| D0 | Kalibrasyon | `mimari.md` §5'in 1–3, 8, 11. maddeleri: enkoder yönü ve sayım/tur, AS5600 ayarı, akım ölçümü kalibrasyonu, döngü zamanlaması, akım (tork) sınırı | — | Sensör ölçekleri, I_sınır | — | — |
| D1 | Kol sökülü | Mod 1, açık çevrim, gerilim sinüsü 0,25 Hz (u = 0,4 N·m eşdeğeri, ≈ 9,8 V genlik) | 9 s × 3 | K_m, R_a, J_M, b_M, F_c | K_m %0,05, J_M %0,5, b_M %1,4, F_c %1 | `km_kestir.m`, `tani_JM.m` |
| D2 | Kol sökülü | Mod 1, açık çevrim, tork sinüsü 0,1 N·m eşdeğeri (V = R_a·u/K_m), 0,02 Hz | 36 s × 3 | F_s | %1–2,5 | `tani_Fs.m` |
| D3 | Kol takılı | Kol 90°'de durgun başlar. P–PI r_gs 0,8, mod 1, referansa sinüs 90° ± 70°, 0,05 Hz | 21 s × 5 | K_s, mgl, AS5600 sıfırı θ₀ | K_s %0,5–1, mgl %0,1, θ₀ 0,05° | `tani_Ks.m`, `tani_mgl.m` |
| D4 | Kol takılı | Kol 0°'da asılı başlar. P–PI **r_gs 0,5**, mod 1, referansa sinüs 0° ± 60°, 0,05 Hz | 21 s × 5 | r (boşluk yarı genişliği) | %0,2 | `tani_r.m` |
| D5 | Motor dişlisi **kilitli** | Kol kontrolcüyle 90°'ye getirilir, motor dişlisi pimle gövdeye sabitlenir, motor kapatılır. Kola aşağı yönde hafif vuruş; vuruş sonrası 0,6 s θ_L | 10 vuruş | c_s, J_L | c_s %3,5, J_L %0,5 | `tani_cs.m` (kilit) |
| D6 | Kol takılı, asıl deney | Açı × r_gs taraması, her noktada 3 başlangıç sapması (0,2 / 1 / 5°), mod 1 | Bkz. §3 | Kritik r_gs(θ₀) | — | `mimari.md` §4.2 tarama betiği |

Tanılama toplamı (D1–D5) kurulum hariç ≈ 30 dakika kayıt.

## 2. Her deneyin geçerlilik ölçütü

Kayıt bu ölçütü sağlamıyorsa atılır ve tekrarlanır.

- **D1:** pencere başına |φ̇| > 2 rad/s olan en az 50 pencere (100 ms). İki tekrar arasında J_M farkı %2'yi aşmamalı.
- **D2:** her yönde en az bir kopma (aralarında ≤ 50 ms olan iki sayım). Tekrarlar arasında F_s farkı %3'ü aşmamalı. Kopmadan önceki tek başına sayımlar (sürünme) gerçek dişlide benzetimden az olmalı; çoksa algılama penceresi gözden geçirilir.
- **D3:** dişli tarama boyunca hep aynı yüze yaslı olmalı. Kontrol: δ_m = φ − θ_L, ort(τ_g)'ye karşı tek bir düz çizgi. Yukarı ve aşağı tarama ayrı uydurulur, ortalanır (yöne bağlı hata zıt işaretli).
- **D4:** |θ| > 10° iken δ_m − τ_g/K_s iki ayrı yatay kümede durmalı (iki dişli yüzü). Kümeler arasında örnek varsa (ters yüz) dişli takırdıyor demektir: r_gs düşürülür. Benzetimde r_gs 0,8 ile kayıtların %7'si ters yüzdeydi, r hatası %1,4–5 oldu.
- **D5:**
  - θ_L tepeden tepeye ≤ 25 AS5600 sayımı (dişli temastan ayrılmasın, ±mgl/K_s = ±1,4°).
  - Zarf üstel olmalı. Doğrusal azalıyorsa kol yatağında Coulomb sürtünmesi var demektir; c_s formülü geçersiz olur (benzetimde sınanmadı).
  - Kilit rijit mi? J_L = K_s/ω_n² (K_s D3'ten), kilit pimi ve milin esnemediğini varsayar. Pim esnerse yay "dişli + pim" seri bağlı olur, ω_n düşer, J_L büyük çıkar. Bu yüzden J_L, geometriden (tartı + CAD) bağımsız bir tahminle karşılaştırılır. Fark %5'i aşarsa J_L geometriden alınır.
  - c_s, sertliğe bağlı olmayan biçimde de hesaplanır: c_s + b_L = 2σ·J_L (σ, sönümlü sinüs uydurmasının zarf üssü). Kilit rijitse bu, 2√(K_s·J_L)·ζ ile aynı.
- **D6:** her noktada sınıf (`rejim_sinifla`, son 5 s) ve genlik; sınır tanımı benzetimle aynı (sınıf ≥ 3 ve A > 0,5°, herhangi bir başlangıç sapmasında).

## 3. Asıl deney (D6) ve karşılaştırma

1. D1–D5'in sonuçlarıyla ikiz kurulur (`tani_dogrula.m`'deki "tanılanan" takımın yerine ölçülen değerler).
2. İkiz, D6'nın her açısında kritik r_gs'yi öngörür. Benzetimde bu öngörü gerçek sınırı en çok bir tarama adımı (0,05) şaşırdı.
3. Donanımda tarama, öngörülen sınırın ±0,15 çevresinde 0,05 adımla yapılır (taramayı kısaltır).
4. Ölçüt: öngörülen − ölçülen sınır farkı. Aynı veri üzerinde Ghaffari (yerçekimsiz) öngörüsü ve önerilen DF öngörüsü de karşılaştırılır (`mimari.md` §4.4).
5. **Sınır yakınında tek koşuya güvenilmez.** Benzetimde sınırın hemen üstünde (r_gs 1,45) genlik %20 farklı çıktı; bir takımda 1°'lik başlangıç sapması söndü, öteki sapma salındı. Her noktada üç başlangıç sapması zorunlu.

## 4. Donanımdan önce kapatılması gereken açık noktalar

1. ~~Mod 3 akım döngüsü (D2–D5).~~ **Kapandı (2026-11-02).** Benzetimdeki mod 3'ün (10 kHz, IPROPI → ADC) donanımda karşılığı yoktu. D2–D5 benzetimde mod 1 ile yeniden koşuldu: K_s %0,5–1, r %0,2, c_s aynı, F_s %1–2,5 (README 4.3, 4e). Hızlı akım döngüsü gerekmiyor.
2. **Akım ölçümü.** Benzetim IPROPI → ADC'yi varsayıyor (basamak 0,46 mA, gürültü 1,4 mA). Mod 1'de akım yalnız kayıt için ölçüldüğünden 1 kHz'te INA228 yeterli ve daha az gürültülü; sonuçlar kötüleşmemeli (sınanmadı, benzetim karamsar taraf).
3. **Hız kestirimi.** `mimari.md` §4.1'deki iki yöntemin (fark + filtre, kenar zamanlaması) yerine gözlemci seçildi (README yan soru). Firmware tarifi buna göre güncellenmeli.
4. **D5 için kilit parçası.** Motor dişlisini gövdeye sabitleyen pim ya da kelepçe malzeme ve mekanik tasarıma eklenmeli. Kilit, motor dişlisini dönmeyecek kadar sıkı tutmalı ama kola yük bindirmemeli.
