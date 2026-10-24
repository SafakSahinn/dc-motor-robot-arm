# Framing, kapsam ve kısıtlar (taslak)

Çalışma notunun 1. aşaması. Seçilen yön ve gerekçesi: `framing_adaylari.md` (ana katkı B; L zorunlu bileşen; H motivasyon; O uzantı). Literatür taraması: `../literatur/son_tarama_2026-10-24.md`.

**Açı tanımı:** θ = 0° kol aşağı sarkık, 90° yatay, 180° dik yukarı. Yerçekimi torku T_g = mgℓ·sin θ: 90°'de en büyük, 0° ve 180°'de sıfır.

## 1. Problem

Dişli kutulu bir eklemde boşluk (backlash), kapalı çevrimde sabit bir hedefte bile kendiliğinden süren bir salınıma (limit cycle, LC) yol açabilir. Bu salınımın kazanca bağlı sınırı DF ile öngörülebiliyor (Ghaffari 2013, C. Wang 2017, Bai 2024). Ancak bu analizler yatay eksenler için yapılmış; dişliye etkiyen ortalama tork sıfır ya da simetrik bir mekanik ön yük olarak alınıyor.

Düşey düzlemde dönen bir robot kolunda durum farklı. Yerçekimi torku dişliyi tek bir yüze bastıran **doğal, tek yönlü bir ön yük** gibi davranır ve büyüklüğü kol açısıyla değişir: kol yataya yakınken dişli bastırılı kalır, düşeye yakınken boşlukta serbesttir. Bu etki nitel olarak biliniyor (Karim 2018, Xu 2023) ve sönümlü titreşim için ölçülmüş (Malzahn 2014). Fakat salınımın başladığı sınırın açıya ve kazanca birlikte nasıl bağlı olduğu ne haritalanmış ne de öngörülmüş.

Pratikteki sonucu şu: tek bir açıda ayarlanmış bir kontrolcü başka bir açıda salınabilir. Yerçekimi dengelemesi (karşı ağırlık, yay) de motor torkunu azaltırken bu doğal ön yükü fark ettirmeden ortadan kaldırır.

## 2. Araştırma sorusu

**Ana soru:** Yerçekimi etkisindeki tek motorlu, dişli boşluklu bir eklemde, sabit hedef açısı θ₀ ve kontrol kazancına bağlı olarak kendiliğinden süren salınımın başlama sınırı, Ghaffari'nin simetrik ön yük çerçevesi tek yönlü ve açıya bağlı yerçekimi ön yüküne genişletilerek ne doğrulukla öngörülebilir?

**Alt sorular:**
- **AS1.** Sınırı hangi boyutsuz sayılar belirler? Adaylar: yerçekimi oranı γ = mgℓ·sin θ₀ / (K_s·r), kazanç–sertlik oranı ρ = ω_c/ω_rez (Ghaffari'nin r_gs'si ile ilişkisi r_gs = ρ·√(J/J_eff)) ve sürtünme oranı φ = F_C / (K_s·r).
- **AS2.** Deneyde gözlenen salınım gerçekten boşluktan mı geliyor? Açı taraması sürtünme ve nicemleme kaynaklı salınımı ayırt edebilir mi? (L)
- **AS3.** Yerçekimi dengeleme oranı sınırı nasıl kaydırır? Hangi orandan sonra salınım başlar? (H)

## 3. Hipotezler

- **H1.** Kritik kazanç, |γ| büyüdükçe artar. 90° civarında salınımsız bir bölge oluşur, bu bölge kazanç arttıkça daralır. Simülasyonda gözlenen ölçekleme γ_sınır ≈ 3·ρ³ (ρ ≤ 0,33) bunun nicel biçimidir.
- **H2.** Simetrik ve yerçekimsiz DF (Ghaffari 2013) bu açı bağımlılığını öngöremez. Tek yönlü kaymayı içeren (iki girişli) DF öngörebilir.
- **H3.** Sürtünme ve nicemleme kaynaklı salınım açıdan bağımsızdır; boşluk kaynaklı salınım açıya bağlıdır.
- **H4.** Dengeleme oranı arttıkça etkin γ küçülür ve salınımsız bölge daralır. Tam dengelemede sınır, yerçekimsiz (yatay) eksenin sınırına iner.

## 4. En yakın literatür

✓ var · ✗ yok · ~ kısmen

| Çalışma | Yerçekimi modelde | Açı taranıyor | Kazanç taranıyor | Sabit hedefte LC | Sınır öngörüsü | Tek tahrik motoru | Fiziksel deney |
|---|---|---|---|---|---|---|---|
| Ghaffari 2013 (TMECH) | ✗ | ✗ | ✓ (r_gs) | ✓ | ✓ DF | ✓ | ✓ |
| C. Wang 2017 (TIE) | ✗ | ✗ | ✓ | ✓ | ~ frekans | ✓ | ✓ |
| Bai 2024 (TPEL) | ✗ | ✗ | ✓ | ✓ | ✓ DF | ✓ | ✓ |
| J. Wang 2024 (Nonlinear Dyn.) | ✗ | ✗ | ✓ | ✓ | ✓ DF | ✓ | ✓ |
| Yang 2017 (Proc. IMechE C) | ✗ | ✗ | ✓ | ✓ | ~ bölge | ✓ | ✓ |
| Kollár 2003 (EJDE) | ~ üst denge | ✗ | ✓ (P–D) | ✓ | ✓ kesin çözüm | ✓ | ✓ |
| Sun 2023 (TIE) | ✓ | ✗ (yalnız 90°) | ~ (2 değer) | ✓ | ✗ | ✗ (çift motor) | ✓ |
| Xu 2023 (RA-L) | ~ nitel | ~ ofset, hareket halinde | ✗ | ✗ | ✗ | ✗ (çift motor) | ✓ |
| Malzahn 2014 (tez) | ✓ | ✓ (10°) | ✗ | ✗ (sönümlü) | ✗ | ✓ | ✓ |
| Giovannitti 2022 (JIM) | ✓ | ~ sürekli dönüş | ✗ | ✗ | ✗ | ✓ | ✓ |
| Márton 2009 (ECC) | ✗ | ✗ | ✓ | ✓ | ~ yaklaşık | ✓ | ✗ |
| **Bu çalışma (hedef)** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

Not: C. Wang 2017'nin "r_s"si Ghaffari'nin r_gs'siyle aynı tanım, bizim eski r_s'mizden farklı. Karışıklığı önlemek için bizim oran bundan sonra ρ.

## 5. Önerilen katkı (Yol 2: yöntem geliştirme)

**Temel alınan yöntem:** Ghaffari 2013. Çok döngülü sistemi tek döngüye indirgeme, DF ve sertlik oranına göre rejim sınıflaması (kararsız / rezonans LC / çarpma).

**Giderilen eksiklik:** Ghaffari'de ön yük simetrik (±τ_p, yaylı anti-boşluk mekanizması) ve sabit. Yerçekimi ön yükü ise tek yönlü ve açıya bağlı.

**Katkılar:**
1. Ghaffari çerçevesinin tek yönlü, açıya bağlı ön yük için genişletilmesi (iki girişli DF ile). Sonuç: θ₀ × kazanç düzleminde salınım sınırının öngörüsü ve düzenekten bağımsız boyutsuz biçimi (γ, ρ).
2. Öngörünün tek motorlu, düşük maliyetli bir düzenekte deneysel doğrulanması: üç düzenek (uç kütlesi ya da boşluk genişliği değiştirilerek), iki sensörle θ_d ölçümü.
3. Gözlenen salınımın kaynağının açı taramasıyla ayrıştırılması (boşluk / sürtünme / nicemleme).
4. Sonucun tasarım kuralına çevrilmesi: verilen açı aralığı için en büyük güvenli kazanç ve izin verilebilir yerçekimi dengeleme oranı.

**İddia edilmeyenler:**
- Kaymalı (iki girişli) DF'nin kendisi yeni değil; boşluk için 1973'ten beri var.
- "Yerçekimi dişliyi bastırır" ilkesi nitel olarak biliniyor (Ahmad 1985, Karim 2018, Xu 2023).
- Kazanç düzleminde sınır çıkarma fikri de yeni değil (Kollár 2003, Yang 2017).

Yenilik bu üçünün yerçekimli bir eklemde açı eksenine taşınması, Ghaffari çerçevesine bağlanması ve deneyle doğrulanmasıdır.

## 6. Başarı ölçütleri (öneri, danışmanla netleşecek)

| # | Ölçüt | Hedef | Dayanak |
|---|---|---|---|
| B1 | Her θ₀'da kritik kazancın öngörü hatası (deneye göre) | Medyan ≤ %20; yerçekimsiz Ghaffari öngörüsünden en az 2 kat daha iyi | Ghaffari'nin frekans hatası %2–24 |
| B2 | Açı yönünde sınırın öngörü hatası (sabit kazançta) | ≤ 5° | Açı tarama adımı ve sınırın keskinliği |
| B3 | LC frekansı ve genliğinin öngörü hatası | Frekans ≤ %15, genlik ≤ %30 | C. Wang 2017'de frekans uyumu %1–3; genlik DF'de daha zayıf |
| B4 | Genellenebilirlik | Üç düzenekte sınır noktaları (γ, ρ) düzleminde aynı eğri üzerinde (dağılım ≤ 2×) | Simülasyonda ideal modelde 2–3×, gerçekçi modelde ~5× |
| B5 | Kaynak ayrıştırma (L) | Kontrollü senaryolarda doğru sınıflama ≥ %90 | Senaryolar: kaplin boşluğu, keçe pabuçla eklenen sürtünme, yazılımda bit atılarak üretilen nicemleme |
| B6 | Tekrarlanabilirlik ve belirsizlik | Her sınır noktası ≥ 3 tekrar; yayılım ve ölçüm belirsizliği raporlanır | Danışmanın 6. aşama beklentisi |
| B7 | Dengeleme kuralı (H) | Dengeleme oranına göre sınır kaymasının öngörüsü B1 ile aynı doğrulukta | H4 |

**Karşılaştırma yöntemleri (referans):** (i) yerçekimsiz Ghaffari / simetrik DF, (ii) sayısal benzetim (kesin), (iii) yalnız θ₀ = 90° için Sun 2023 benzeri tek açı ölçümü.

## 7. Kapsam ve kısıtlar

| Kısıt | Değer | Gerekçe |
|---|---|---|
| Eklem sayısı | 1 (omuz), düşey düzlemde döner | Açı bağımlılığını tek değişkene indirger. İki eklem ileriki çalışma (Malzahn'daki θ₂+θ₃ kanyonu). |
| Hareket aralığı | 0–180° | Ön yükün sıfırdan (0°, 180°) en büyüğe (90°) bütün aralığı. 180° = Kollár'ın üst denge durumu. |
| Hareket türü | Sabit hedef θ₀ + küçük adım (≈5°) | Hareket halinde boşluk geçişi kapsam dışı. |
| Açı taraması | Genelde 10°, 0° ve 180° civarında 1–2° | Simülasyonda sınır bölgeleri bu açılarda. |
| Kol ve yük | 15 cm alüminyum lama (≈20 g) + değiştirilebilir uç kütlesi 0 / 20 / 50 g → mgℓ ≈ 0,015 / 0,044 / 0,088 N·m | γ'yı açıdan bağımsız değiştirme düğmesi. Karşı ağırlık H için aynı düğme. |
| Boşluk | Motorun kendi boşluğu + ayarlanabilir kaplin 0 / 1,5 / 3 / 5° | Simülasyonda en güçlü düğme; kaplinin katkısı bilinen boşluk. 0° ayarı motorun kendi boşluğunu ölçmek için. |
| Kazanç (bant genişliği) | ω_c ≈ 30–45 rad/s (JGB37'nin tork sınırı, `simulasyon/motor_jgb37.m`); hedef ρ ≈ 0,25–0,40 (r_gs ≈ 0,5–0,8) | Ghaffari'nin rezonans LC rejimi (DF geçerli); simülasyonda ölçekleme yasası burada sağlam. ρ ve r_gs değerleri JGA25 parametreleriyle hesaplandı; JGB37'nin tanılanan J_M ve K_s değerleriyle yeniden hesaplanacak. Hedef bölge kaçarsa kaplin malzemesi (K_s) ile ayarlanır. |
| Kontrolcü | PID (türev motor enkoderinden) ve karşılaştırma için Ghaffari'nin P–PI yapısı | Ghaffari ile birebir karşılaştırma. |
| Ölçüm çözünürlüğü | Kol açısı AS5600 12 bit = 0,088°; motor enkoderi kol tarafında 0,27° (JGB37-520 1:30: 11 darbe × 4 kenar × 30 = 1320 sayım/tur) | θ_d çözünürlüğünü motor enkoderi sınırlar: 3° boşluk ≈ 11 adım. Bu sınır makalede açıkça yazılacak. |
| Örnekleme | 1 kHz (ESP32) | Simülasyonun gerçekçi modeliyle aynı. |
| Tork ve akım | JGB37-520 nominal ≈ 0,34 N·m @ 1 A, durma ≈ 0,49 N·m / 2,3 A; DRV8874 akım sınırı ≈ 2 A | Salınım deneyleri kısa; akım INA228 ile, sıcaklık TMP117 ile izlenir. |
| Bütçe | Sabit bir tavan yok; 3. aşamada birden fazla malzeme listesi (ekonomik / dengeli / üst sınıf) hazırlanacak, seçim danışmanla yapılacak. Bugünkü dengeli liste ≈ 639 TL + 13 € + 70 $ (motor + elektronik, mekanik hariç). | Ölçüm kalitesi ile maliyet arasındaki seçim, mimari belli olunca yapılmalı. |
| Süre | Sınav takvimine bağlı değil; projenin yapılabilir süresi ≈ 4–5 ay (aşama tablosu aşağıda) | Teori ve donanım kolları paralel yürütülür |

**Kapsam dışı:** hareket halinde boşluk geçişi, esnek kol, çok eklemli kol, çift motorlu aktif ön yük. Gözlemci tasarımı ve açıya göre geri besleme harmanlama (O) ana katkı tuttuktan sonra uzantı olarak ele alınır.

**Yapılabilir süre (aşama aşama):**

İki kol paralel yürür: **teori kolu** (4a–4b) ve **donanım kolu** (5a–5c). Deneyler (6a) iki kolun buluştuğu yerde başlar.

| Aşama | İş | Süre | Bağımlılık |
|---|---|---|---|
| 1–3 | Framing, donanım/yazılım planı, malzeme listeleri; danışmanla netleştirme | 1 hafta | — |
| 4a | Literatür sonucunun yeniden üretimi (önce Ghaffari 2013, sonra Sun 2023), oran eşlemesi | 2–3 hafta | 1–3 |
| 4b | İki girişli DF türetimi, sınır öngörüsü; simülasyonla karşılaştırma; rejimlerin ayrımı (sönümlü / zorlanmış / LC / kararsız) | 3–4 hafta | 4a |
| 5a | Sipariş ve teslim; bu sürede firmware iskeleti ve veri kayıt betiği yazılır | 2–3 hafta | 3; 4a ile paralel |
| 5b | Mekanik tasarım ve 3B baskı (kaplin, gövde, kol), montaj, kablolama | 2 hafta | 5a; 4b ile paralel |
| 5c | Sensör kalibrasyonu, alt sistem testleri, sistem tanılama (J, b, K_s, boşluk, sürtünme, ölü bant) | 2–3 hafta | 5b |
| 6a | Açı × kazanç deneyleri: 3 kurulum × ≈20 açı × ≈6 kazanç × 3 tekrar ≈ 1080 kısa deney (otomatik betikle) | 2–3 hafta | 5c, 4b |
| 6b | Kaynak ayrıştırma senaryoları (L) ve dengeleme deneyleri (H) | 1–2 hafta | 6a |
| 6c | Analiz, belirsizlik, model–deney farkları, makale yazımı (yöntem bölümleri 6a sırasında başlar) | 3–4 hafta | 6a–b |

**Toplam ≈ 4–5 ay (16–21 hafta).** Kritik yol donanım kolu: 1–3 → 5a → 5b → 5c → 6a → 6b → 6c. Teori kolu (5–7 hafta), donanım hazırlığının (6–8 hafta) içine sığıyor.

**Risk:** DF türetimi gecikirse deneyler durmaz. Deney verisi önce simülasyonla karşılaştırılır, DF karşılaştırması 6c'ye kayar.
