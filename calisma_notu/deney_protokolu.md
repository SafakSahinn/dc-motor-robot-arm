# Deney protokolü: sistem tanılama ve salınım sınırı (donanım)

Bu belge, dijital ikizde (`simulasyon/simulink/`, README madde 4.3) sınanan tanılama yöntemlerini donanımda uygulanacak sıralı bir deney listesine çevirir. Her deneyin yöntemi, benzetimdeki doğruluğu ve gerekçesi README'de; burada yalnız **ne yapılacağı, hangi ayarla, kaydın ne zaman geçerli sayılacağı** var. Analiz betikleri benzetimdeki betiklerle aynı; yalnız girdi, benzetim yerine firmware kaydı olur (`olcum_oku` → `K` biçimi).

Sayılar D düzeneğinin benzetim değerleridir (J_M = J_L = 0,0036 kg·m², K_s = 10 N·m/rad, 2r = 3°, mgl = 0,24 N·m). Donanımda farklı çıkacakları için "beklenen" sütunları yalnız kabaca denetim içindir.

## 0. Ortak ayarlar

| Konu | Ayar | Neden |
|---|---|---|
| Döngü ve kayıt | 1 kHz, kayıt **seyreltmesiz** (her örnek): t, θ_L (kol AS5600 ham, I²C-1), φ (motor arka milindeki AS5600, tur sayımıyla; kol tarafında 0,0029°), Hall sayımı (sağlama), v̂, u, V (PWM görev oranından), i | 4.3'te 5 ms'lik kayıt K_m ve J_M'yi %4–13 bozdu (README 4.2 düzeltmesi) |
| Hız kestirimi | **Gözlemci** (iki satırlık Euler güncellemesi), bütün deneylerde aynı | Sınır kestiriciye bağlı (README yan soru: fark +0,05–0,10, periyot −0,15). Periyot yöntemi kullanılmaz |
| Kontrolcü | P–PI (k_p = r_gs²·K_s/K_V, K_V, K_I benzetimle aynı) | r_gs ekseni Ghaffari tanımıyla |
| Sürücü modu | **Mod 1 (gerilim), bütün deneylerde** | Hızlı akım döngüsü gerekmiyor: tanılama mod 1'de de aynı doğrulukta (README 4.3, 4e). Akım yalnız kayıt için |
| Meta veri | Firmware sürümü, kazançlar, mod, kestirici, sıcaklıklar, uç kütlesi | Benzetim aynısıyla kurulur |

**Not (6 Kasım 2026):** φ artık motor arka milindeki AS5600'ten okunuyor (önce Hall enkoderdi, kol tarafında 0,27°). D1–D5'in ikizdeki doğrulukları Hall nicemlemesiyle bulundu; daha ince φ'yle aynı ya da daha iyi olmaları beklenir, ikizde yeniden koşulmadı. 180° çevresindeki yüz kestirici deneyleri D7 olarak §5'te (8 Kasım 2026).

## 1. Deney sırası

Sıra bağımlılığa göre: her deney öncekilerin sonucunu kullanır. D1–D2 kol sökülü, D3–D4 kol takılı, D5 motor kilitli, D6 asıl deney.

| # | Düzenek | Ne yapılır | Süre × tekrar | Çıkan | Benzetimde doğruluk | Betik |
|---|---|---|---|---|---|---|
| D0 | Kalibrasyon | `mimari.md` §5'in 1–3, 8, 11. maddeleri: Hall enkoder yönü ve sayım/tur, motor AS5600'ün tur sayımı (Hall'a göre kayma yok) ve tur içi doğrusallık tablosu, iki AS5600'ün ayarı (SF = 11, FTH ve HYST kapalı), akım ölçümü kalibrasyonu, döngü zamanlaması (iki I²C hattı birlikte), akım (tork) sınırı | — | Sensör ölçekleri, I_sınır | — | — |
| D1 | Kol sökülü | Mod 1, açık çevrim, gerilim sinüsü 0,25 Hz (u = 0,4 N·m eşdeğeri, ≈ 9,8 V genlik) | 9 s × 3 | K_m, R_a, J_M, b_M, F_c | K_m %0,05, J_M %0,5, b_M %1,4, F_c %1 | `km_kestir.m`, `tani_JM.m` |
| D2 | Kol sökülü | Mod 1, açık çevrim, tork sinüsü 0,1 N·m eşdeğeri (V = R_a·u/K_m), 0,02 Hz | 36 s × 3 | F_s | %1–2,5 | `tani_Fs.m` |
| D3 | Kol takılı | Kol 90°'de durgun başlar. P–PI r_gs 0,8, mod 1, referansa sinüs 90° ± 70°, 0,05 Hz | 21 s × 5 | K_s, mgl, AS5600 sıfırı θ₀ | K_s %0,5–1, mgl %0,1, θ₀ 0,05° | `tani_Ks.m`, `tani_mgl.m` |
| D4 | Kol takılı | Kol 0°'da asılı başlar. P–PI **r_gs 0,5**, mod 1, referansa sinüs 0° ± 60°, 0,05 Hz | 21 s × 5 | r (boşluk yarı genişliği) | %0,2 | `tani_r.m` |
| D5 | Motor dişlisi **kilitli** | Kol kontrolcüyle 90°'ye getirilir, motor dişlisi pimle gövdeye sabitlenir, motor kapatılır. Kola aşağı yönde hafif vuruş; vuruş sonrası 0,6 s θ_L | 10 vuruş | c_s, J_L | c_s %3,5, J_L %0,5 | `tani_cs.m` (kilit) |
| D6 | Kol takılı, asıl deney | Açı × r_gs taraması, her noktada 3 başlangıç sapması (0,2 / 1 / 5°), mod 1 | Bkz. §3 | Kritik r_gs(θ₀) | — | `mimari.md` §4.2 tarama betiği |
| D7 | Kol takılı, 179–181° | Yüz kestirici: 42 senaryo × 3 tekrar + edilgen karşılaştırma | Bkz. §5 | H7, B12, B13 | İkizde 42/42 | `ikiz_dogrula.m` ölçütleri |

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
2. ~~**Akım ölçümü.**~~ **Kapandı (2026-11-06).** İkize INA228 ölçüm modeli eklendi (`akim_gurultu.m`, framing iş sırası 5a): pencere 0,54 ms, gecikme 0,1 ms ve gürültü ≤ 0,02 N·m (beklenenin ≈ 20 katı) sonucu değiştirmiyor. Akım sıfırı her deneyden önce alınır (ofset ±0,02 N·m bozuyor).
3. ~~**Hız kestirimi.**~~ **Kapandı (2026-11-06).** Gözlemci hızı (w^) ikizde 42 senaryoda ideal hızla aynı sonucu verdi (`hiz_gozlemci.m`); firmware'de `HIZ_GOZLEMCI` olarak yazıldı ve kartta ikizle birebir doğrulandı (`calisma_notu/esp32.md` adım 4–6).
4. **D5 için kilit parçası.** Motor dişlisini gövdeye sabitleyen pim ya da kelepçe malzeme ve mekanik tasarıma eklenmeli. Kilit, motor dişlisini dönmeyecek kadar sıkı tutmalı ama kola yük bindirmemeli. **Öneri (onay bekliyor):** kaplinin motor tarafındaki göbeğe radyal delik; gövdeye bağlı basılı tutucudan geçen M3 pim. Kol tarafı serbest kalır.
5. **Mekanik durdurucunun yeri.** `mimari.md` §3 "0° altı ve 180° üstü" diyor; D7 179–181°'de çalıştığı için durdurucu tam 180°'de olamaz. **Öneri (onay bekliyor):** durdurucular −15° ve 195°, yazılım sınırı −5° ve 190°.
6. ~~**Yüz kestirici mod 1'de.**~~ **Sınandı (2026-11-08), mod seçimi onay bekliyor.** İkize motorun elektrik tarafı eklendi (`p.motorElk`; Simscape `sm_motor_model`'e karşı doğrulandı). 42 senaryo mod 1'de (framing iş sırası 5c): nominal koşullarda ve INA228 hatasında 42/42, sargı ısınmasında (R_a ×1,25) da 42/42. Gerçekçi model hatası köşelerinin toplamında tork girişliden 6 senaryo eksik (320 / 326 / 336). Kayıp zıt EMK sönümünden geliyor: mod 2, yani gözlemcinin ŵ'siyle zıt EMK kompanzasyonu (V = R̂_a·u/K̂_m + K̂_m·ŵ), kaybı geri getiriyor. **Öneri (onay bekliyor):** D7'yi mod 1'de koş; firmware'e mod 2 (ŵ) seçeneğini ekle, 179/181°'de yanlış yüz görülürse D7'yi mod 2'de tekrarla. Mod 3 seçeneği yok (madde 1).

## 5. D7: 180° çevresinde yüz kestirici (Katkı 1'in donanım sınaması)

İkizdeki 42 senaryonun (`framing.md` iş sırası 3 ve 5) donanımdaki karşılığı. D1–D6'dan sonra yapılır, çünkü kestirici ve ofset tablosu D1–D4'ün ölçtüğü r, K_s, mgl, F_c, J_M'yi kullanır.

### 5.1 Ayar

| Konu | Ayar | Neden |
|---|---|---|
| Kontrol | Motor tarafı P–PI (r_gs 0,5) + ofset tablosu φ_ref = θ + s^·r + mgl·sin θ / K_s, ofset yüz değişiminde 0,5 s rampalı | İkizdeki kurulum (iş sırası 3) |
| Kestirici | Olay + yoklama, kartın parametreleri ikizle aynı: gözlemci 40 Hz, `tauEsik` 0,015, `yokA` 0,12, `yokEsik` 0,04, `yokOrta` 0,6, `vDurF` 10 Hz, yoklama bandı ±1° | Ayarlı kestirici (iş sırası 3, 1 kHz ayarı) |
| Bilinen değerler | r, K_s, mgl, J_M: D1–D4 ölçümü. **F̂_c = 0,9 × ölçülen F_c**, F̂_s ölçülen | F̂_c fazlası yoklamayı bozuyor, eksiği zararsız (iş sırası 4–5b) |
| Hedef kaydırma | Tam 180° istekleri kolun geldiği tarafa göre 179,5° / 180,5°'ye kaydırılır | Kullanıcı kararı (a), H7 tanımı |
| Akım | INA228 sıfırı her koşudan önce (motor kapalıyken 0,5 s ortalama) | Ofset ±0,02 N·m'de bozuluyor (iş sırası 5a) |
| Isınma | Koşulara başlamadan 5 dk ısınma hareketi; TMP117 motor gövdesi sıcaklığı her koşunun meta verisine | F_c sıcaklıkla kayar; kayma tek başına güvenli, model hatalarıyla birleşince pay daralıyor (iş sırası 5b) |
| Sürücü modu | §0'daki mod 1 (gerilim); yedek mod 2 (zıt EMK kompanzasyonu, gözlemcinin ŵ'siyle) | Mod 1 nominal koşullarda 42/42; yalnız büyük model hatası köşelerinde zıt EMK sönümü birkaç senaryo kaybettiriyor, mod 2 bunu geri getiriyor (framing 5c, §4/6; onay bekliyor) |

### 5.2 Senaryolar

7 istek (179; 179,25; 179,75; 180; 180,25; 180,75; 181°) × 2 geliş yönü × 3 bozucu = 42 senaryo. Her koşu 8 s.

- **Geliş yönü:** kol önce isteğin 1,1° altında (alttan) ya da üstünde (üstten) kontrolcüyle durdurulur, 2 s bekler, sonra istek basamak olarak verilir. İkizdeki `p.adim = ±1,1°` başlangıcıyla aynı.
- **Bozucu 1, yok:** yalnız basamak.
- **Bozucu 2, darbe:** basamaktan 3 s sonra kola 180°'den uzaklaştıran yönde bilinen bir vuruş. İkizdeki darbe 0,05 N·m, 20 ms (25 Hz sinüsün yarım periyodu), yani ≈ 0,6 mN·m·s açısal itme. **Öneri (onay bekliyor):** kolun ucuna ipe asılı küçük bir sarkaç vurucu (ör. 5 g bilye) bilinen bir açıdan bırakılır; itme m·v·ℓ'den hesaplanır, bırakma açısı ilk denemelerde kol AS5600'ün gördüğü tepe sapma ikizdekiyle eşleşecek biçimde ayarlanır. El ile vuruş tekrarlanabilir olmadığından kullanılmaz. Vuruş anı motor akımındaki sıçramadan kayda işaretlenir.
- **Bozucu 3, yanlış başlangıç yüzü:** mekanik bir şey gerekmez; kestiricinin başlangıç s^'si firmware'e yanlış (−s₀) verilir. İkizdeki `p.yuz0 = −s₀` ile aynı.

### 5.3 Kayıt ve ölçütler

Kayıt §0'daki alanlara ek olarak: s^, ofsetteki rampalı yüz, yoklama evresi, w^ ve d^ (gözlemci). Hepsi kartın `Cikti` paketinde zaten var (`firmware/src/kontrol.h`). Olay kararı ayrı bir alan değil: yoklama dışında (evre 0) s^'nin değiştiği örnek olaydır.

| Ölçüt | Tanım | Ölçen | Ölçüm çözünürlüğü |
|---|---|---|---|
| H7 | Son 1 s ortalama kol hatası ≤ 0,5°, en büyük ≤ 1°, B12 sağlanmış | Kol AS5600 (I²C-1), θ₀ D3'ten | 0,088° (0,5° ≈ 6 sayım) |
| B12 | Son 1 s'de dişlinin yaslandığı yüz doğru: δ = φ − θ_L'nin işareti, \|δ\| ≥ r iken | φ motor AS5600, θ_L kol AS5600 | δ'da ≈ 0,09° (r ≈ 1,5°'ye göre yeterli) |
| B13 | Yoklama ve sonraki 0,3 s'de kol hareketi ≤ 0,5° (darbesiz senaryolarda) | Kol AS5600 | 0,088°; ikizde en çok 0,43° bulundu, pay az: AS5600 gürültüsüyle birlikte değerlendirilir |

### 5.4 Tekrar ve karşılaştırma

- Her senaryo 3 tekrar: 126 koşu × (8 s + ≈ 5 s hazırlık) ≈ 30 dk. Darbeli 42 koşu el ile tetiklenir.
- **Başarı:** ikiz 42/42 veriyor; donanımda her tekrarda 42/42 hedeflenir. Geçemeyen senaryo, D1–D5 değerleriyle kurulmuş ikizde aynı tohumla yeniden koşulur ve iki kayıt yan yana konur: fark modelden mi, donanımdan mı?
- **Karşılaştırma satırı (Katkı 1'in kanıtı):** aynı 42 senaryo edilgen kestiriciyle (durgunken sign(u)) de koşulur. İkizde sürtünmeli durumda 20/42; donanımda da belirgin biçimde kötü çıkması, olay + yoklamanın gerekli olduğunu gösterir.
- **Kayma sınaması:** 126 koşunun başında ve sonunda D1 kısaca (1 tekrar) yinelenir; F_c'nin oturum içindeki kayması ölçülür ve iş sırası 5b'nin güvenli aralığıyla karşılaştırılır.
