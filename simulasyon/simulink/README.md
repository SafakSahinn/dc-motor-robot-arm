# Simulink dijital ikizi

Amaç: `kol_benzetim.m` ile aynı modeli Simulink'te kurmak. Bu model deney tasarımında, sistem tanılama planının sınanmasında ve ileride ESP32 firmware'ine taşınacak deney protokolünde kullanılacak. Açı × kazanç taramaları vektörize betikte kalır; Simulink tek koşu ve deney tasarımı içindir.

## Kararlar

- **Yalnız Simulink, Simscape yok.** Dişli teması (ölü bölge + K_s yayı + c_s sönümü, çekme yok) Simulink'in hazır Backlash bloğuyla kurulamaz, çünkü o blok sertliği olmayan kinematik bir boşluktur. Bu yüzden tesis bir MATLAB Function bloğunda, betikteki `f(x)` ile aynı denklemlerle yazılır. Simscape'in hazır bileşenleri betikteki modelle birebir eşleşmez.
- **Çözücü:** sabit adımlı `ode4` (RK4), adım 1e-4 s. Betikle aynı yöntem ve adım olduğu için sonuçlar sayısal yuvarlama düzeyinde örtüşmeli.
- **Kontrolcü** ayrık bloklarla, örnekleme süresi `Ts`, sıfırıncı derece tutucu: P–PI kaskat, tork sınırı, anti-windup, sürücü ölü bandı. Sensör katmanı (nicemleme, gecikme, hız filtresi) ayrı bir alt sistemdir.
- **Model betikle kurulur** (`kol_model_kur.m`). `.slx` ikili bir dosya; kaynak betiktir, `.slx` ondan üretilir.
- **Doğrulama ölçütü:** her referans hücrede aynı rejim sınıfı, genlik ve frekans farkı %1'in altında, θ(t) eğrisi üst üste.

## Referans hücreler (`referans_uret.m` → `referans.mat`)

D düzeneği, P–PI, ideal sensör, sürekli kontrol (Ts = dt), T = 8 s.

| # | Açı | r_gs | Başlangıç | Ek koşul | Betik sonucu |
|---|---|---|---|---|---|
| 1 | 90° | 1,20 | 1° | | düzensiz salınım (sınıf 5), A 2,06°, 8,0 Hz |
| 2 | 60° | 0,50 | 1° | | denge (sınıf 0) |
| 3 | 30° | 0,80 | 0,2° | 6,31 Hz sarsıntı, 0,10 N m, t < 1 s | sönüyor (sınıf 1) |
| 4 | 90° | 0,95 | 0,2° | tork sınırsız | denge (sınıf 1) |
| 5 | 90° | 0,95 | 5° | tork sınırsız | kalıcı çevrim (sınıf 3), A 8,14°, 7,1 Hz |

4 ve 5 aynı hücrenin iki kararlılığını gösterir. Hücre 1 düzensiz olduğu için başlangıç koşuluna duyarlıdır. Bu hücrede eğri ancak ilk saniyelerde üst üste beklenir; sonrasında yalnız istatistikler (genlik, frekans) karşılaştırılır.

## Adımlar

1. Referans veri. **Bitti.**
2. Tesis + P–PI, ideal sensör: `kol_model_kur.m` (bloklar `blok_tesis.m`, `blok_sensor.m`, `blok_kontrolcu.m`; parametreler `sim_param.m`), doğrulama `dogrula_2.m` → `dogrula_2_log.txt`. **Bitti:** 5 hücrenin 5'inde θ(t) betikle bit düzeyinde aynı. Tek fark sarsıntılı hücrede (en çok 1,7e-10°) ve sarsıntının t = 1 s'de kesildiği anın kayan nokta zamanlamasından geliyor. Düzensiz hücre 1 bile 8 s boyunca ayrışmıyor.
3. Sensör katmanı, gerçekçi düzey (`sensor_7c` ayarı: 1 kHz, AS5600 12 bit + 1 örnek gecikme, 11 darbe/tur enkoder, 50 Hz hız filtresi, Stribeck sürtünmesi, %3 ölü bant): `dogrula_3.m` → `dogrula_3_log.txt`. **Bitti:** 5 hücrede sınıf, genlik ve frekans aynı; θ(t) farkı en çok 1e-12°.
4. Deney kaynakları: sarsıntı, frekans taraması, serbest salınım. Sistem tanılama planı (K_s, c_s, J_M) bu modelde sınanır.
   - **4.1, deney kaynakları. Bitti.** Firmware'in üreteceği sinyal `blok_ayrik.m` içinde, Ts örneklemeli (yalnız Simscape modelleri; kol_benzetim ve kol_model'de yok). Ayar `p.dny` (bkz. `sim_param.m`):
     - Yer: `ref` (referansa eklenir), `tork` (tork komutuna eklenir), `acik` (kontrolcü kapalı, u = u0 + d, integral donuk).
     - Şekil: `basamak` (kısa Td ile darbe), `chirp` (doğrusal), `logchirp`, `sinus`. Kaynak t0 ≤ t < t0 + Td arasında çalışır.
     - Serbest salınım: `acik`, A = 0, u0 = 0 ve başlangıç sapması (`p.adim`).
     - Sarsıntı (`p.dA/df/dT`, kola dışarıdan etkiyen tork) olduğu gibi kaldı. Donanımda kola dışarıdan tork uygulanamıyor; firmware'deki karşılığı `tork` + `sinus`.
   - Regresyon: kaynak kapalıyken sm_motor_model çıktısı (3 hücre × mod 1/3, gerçekçi sensör) değişiklikten önceki hâliyle bit düzeyinde aynı.
   - Gösterim `deney_4a.m` → `deney_4a_log.txt`: 6 deney × mod 1/3, hepsi çalışıyor. İki gözlem:
     - **Kol aşağıdayken 10° serbest salınım işe yaramıyor.** Yerçekimi torku (0,24·sin 10° = 0,042 N·m) motor yapışma sürtünmesinin (F_s = 0,06 N·m) altında. Motor kıpırdamıyor, kol yalnız boşluk içinde titreşiyor (θ aralığı 4°, φ 2,5°). 30°'de kol motoru da sürükleyerek gerçekten salınıyor (1,2–1,5 Hz).
     - **Gerçekçi sensörde u, kaynak yokken de gürültülü.** 90°, r_gs 0,8, mod 1, kol duruyor: u ortalaması 0,27, standart sapması 0,22 N·m, zamanın %22'sinde tork sınırında. Gerçek hızla (fv = Inf) standart sapma 0,013 N·m. Kaynak: 11 darbe/tur enkoderin nicemleme basamağının (kol tarafında 0,27°) 1 kHz'de türevi ve 50 Hz filtre. Bu durum 5b'de de vardı; tanılamada u'nun ölçülen girdi olarak kullanılmasını ve donanımda sürücü ısınmasını ilgilendiriyor.
   - **4.2, sanal ölçüm. Bitti.** Firmware'in Ts = 1 ms'de kaydedeceği sinyaller ayrı bir çıkışta: `olc_out`, elektrik modelinde port 5 = [θ_L, φ, v̂, u, V, i], ideal motorda port 3 = ilk dördü. Okuma `olcum_oku.m` → yapı `K` (firmware kaydı + doğrulama için gerçek değerler `K.g`).
     - θ_L: AS5600, 12 bit, bir örnek gecikmeli (kontrolcünün gördüğü değerin aynısı).
     - φ: enkoder.
     - v̂: seçili hız kestirimi.
     - u: tork komutu.
     - V: komut gerilimi. PWM görev oranından bilinir.
     - i: IPROPI → ESP32 ADC, `blok_akim.m`. Gerçekçi ayar: basamak 0,46 mA (A_IPROPI 455 µA/A, R_IPROPI 3,6 kΩ, 12 bit / 3,1 V), gürültü std 1,4 mA (~3 LSB, ortalamasız), sabit tohumlu.
     - Mod 3'ün akım döngüsü i_adc'yi gürültüsüz kullanıyor (5b ile aynı). Yalnız kayıt gürültülü.
     - Regresyon: port 1–4 değişiklikten önceki hâliyle bit düzeyinde aynı.
   - Gösterim `olcum_4b.m` → `olcum_4b_log.txt` (gerçekçi sensör, gözlemci; chirp, darbe, 30° serbest salınım × mod 1/3). Ölçüm − gerçek:
     - θ_L: rms 0,05–0,06°, en çok 0,14–0,21°. Nicemleme (`floor`, −q/2 kayması) + bir örnek gecikme.
     - φ: en çok bir enkoder sayımı (0,27°).
     - v̂: rms 0,04–0,11 rad/s.
     - i: rms 1,4–1,6 mA.
     - Mod 3'te akımdan bulunan tork K_m·i ile komut u arasındaki fark rms 0,0005–0,021 N·m (Tmax'ın en çok %4'ü). Tanılamada tork girdisi olarak mod 3'te u ya da K_m·i kullanılabilir. Mod 1'de zıt EMK yüzünden gerçek tork u değil, K_m·i.
     - Örnek kayıt `olcum_4b_ornek.mat` (chirp, mod 3). 4.3'ün tanılama algoritması bu biçimdeki veriyi okuyacak.
     - **Düzeltme (2026-11-01, 4.3 sırasında bulundu):** kayıt ilk sürümde 1 ms değil **5 ms** aralıklıydı. Modelin `Decimation = dec` (= 5) ayarı yalnız sürekli çıkışları değil, Ts örneklemeli `olc_out`'u da seyreltiyordu. Ölçüm ve tanılama betikleri artık `dec = 1` ile koşuyor (`olc_out` gerçekten 1 ms; sürekli çıkışlar dt = 0,1 ms). Yukarıdaki sayılar düzeltilmiş koşudan; 5 ms'lik hâlden farkları küçük, çünkü bunlar örnek başına hata istatistikleri.
   - **Yan soru: hız kestirimi salınım sınırını kaydırıyor mu?** `blok_ayrik.m`'ye seçmeli kestirici eklendi, ayarı `p.hiz` (yalnız Simscape modelleri):
     - `fark`: varsayılan, 5b ile aynı. Regresyon bit düzeyinde aynı.
     - `periyot`: iki enkoder kenarı arasındaki süre. Donanımda GPIO kesmesi + µs zaman damgasıyla ölçülür; burada kenar zamanı aradeğerlemeyle bulunuyor. Yön değişince v = 0, kenar gelmezse v sıfıra doğru sınırlanıyor.
     - `gozlemci`: ikinci dereceden izleme gözlemcisi, kritik sönümlü, wo = 2π·50 Hz.

     Kol 90°'de dururken (r_gs 0,8, kaynaksız) u standart sapması: fark 0,224, periyot 0,013, gözlemci 0,020 N·m. Kolun kıpırdama aralığı sırasıyla 0,16 / 0,31 / 0,53°.

     Tarama `tarama_hiz.m` → `tarama_hiz_log.txt`: mod 1, gerçekçi sensör, 3 açı × r_gs 0,90–1,45 × 3 başlangıç sapması. Kritik r_gs (30/60/90°):

     | Kestirici | Kritik r_gs |
     |---|---|
     | fark | 1,00 / 1,35 / 1,40 |
     | periyot | 0,95 / 1,10 / 1,15 |
     | gözlemci | 1,00 / 1,30 / 1,30 |
     | gerçek hız (çapa: fv = Inf, gerisi gerçekçi) | 1,00 / 1,25 / 1,30 |

     - **Gözlemci gerçek hız gibi davranıyor:** sınır aynı (90°) ya da 0,05 içinde (60°).
     - **Fark kestiriminin gürültüsü sınırı 0,05–0,10 yukarı itiyor.** Titreşim etkisi (dither) yönünde, ama küçük.
     - **Periyot kestiricisi aykırı:** sınırı gerçek hızın 0,15 altına çekiyor, yani salınımı kolaylaştırıyor. Neden: kol dönüş noktasında yön değiştirince v = 0 okunuyor, yavaşlarken de v sıfıra kırpılıyor. Küçük genlikli dişli boşluğu çevriminde sönüm tam gereken anda kayboluyor. Kestiricinin kendi doğrusal olmama özelliği bu.
     - **Gerçekçi ile ideal sensör farkı hız kestiriminden gelmiyor.** Gerçek hızla bile 60°'de 1,25 (ideal 1,10). Fark nicemleme, gecikme, Ts = 1 ms ve sürtünmeden geliyor. Periyot kestiricisinin ideal sınıra yakın düşmesi rastlantı: iki ayrı etki birbirini götürüyor.
     - Sonuç: donanım deneyinde kullanılacak kestirici ikizde birebir aynı olmalı. Kritik r_gs öngörüsü kestiriciyle birlikte verilmeli. Firmware için en uygun aday gözlemci: gürültüsü düşük (u std 0,020 N·m, tavana vurma yok), sınırı gerçek hızla aynı, ESP32'de iki satırlık Euler güncellemesi. Periyot yöntemi kullanılmamalı.
   - **4.3, tanılama.** Girdi yalnız firmware kaydı (`olcum_oku` → `K`); gerçek değerler yalnız karşılaştırma için. Bütün koşular gözlemci kestiriciyle.
     - **Ön adım: K_m ve R_a (zıt EMK). Bitti.** `tani_Km.m` → `tani_Km_log.txt` (kayıtlar `tani_Km_kayit.mat`, `tani_Km(false)` yalnız analizi yeniden yapar). K_m'nin veri sayfası değeri yaklaşık olduğundan ve J_M kestiriminde tork K_m·i olarak girdiğinden ayrı ölçülüyor.
       - Denklem V = R_a·i + L_a·di/dt + K_m·φ̇. Kaba enkoderin türevini almamak için 20–200 ms'lik pencerelerde integrali alınıyor: ∫V dt = K_m·Δφ + R_a·∫i dt + c·Δi. Her pencere bir satır, en küçük kareler. Enkoder hatası böylece pencere uçlarında en çok bir sayım kalıyor, türevle büyümüyor.
       - **c ≈ L_a + R_a·τ.** Elektrik zaman sabiti (~0,3 ms) Ts'nin (1 ms) altında; c, L_a ile V/i kayıtları arasındaki örnekten kısa zaman kaymasının toplamı (R_a·i(t − τ) ≈ R_a·i − R_a·τ·di/dt). 1 kHz kayıtta 3–5 mH çıkıyor (gerçek L_a 2,5 mH), boşta gerçekçi 8,7 mH. L_a olarak ayrıca yorumlanmıyor. Terim atılırsa K_m ~%1 sapıyor.
       - Sonuç (K_m hatası; "EMK payı" = rms(K_m·φ̇) / rms(V)):

         | Deney | Mod | EMK payı | İdeal | Gerçekçi, 50–200 ms pencere | Gerçekçi, 20 ms |
         |---|---|---|---|---|---|
         | Kol takılı, 0°, P-PI, referansa sinüs 20° 1 Hz / 25° 1,2 Hz | 1 | %10 / %13 | ±0,02% | −0,2 … +0,2% | −0,8 / −0,4% |
         | aynı | 3 | %10 / %13 | ±0,07% | 0,0 … +0,3% | −0,4 / −0,1% |
         | Kol takılmadan, açık çevrim, gerilim sinüsü 0,25 Hz | 1 | %73 | −0,01% | −0,05 … +0,04% | −0,05% |

         R_a hatası her deneyde %0,1'in altında.
       - Kol takılıyken zıt EMK gerilimin yalnız %10–13'ü (kolu taşımak için gereken akım R_a·i'yi büyütüyor); buna rağmen 1 kHz kayıtla K_m %0,3 içinde. 20 ms'lik pencere biraz kötü (pencere başına Δφ az sayım). **Karar: pencere 100 ms. K_m her iki düzenekte de ölçülebiliyor.** Kol sökülebiliyorsa boşta deney tercih (EMK baskın, sonuç pencereden bağımsız), sökülemiyorsa kol takılı deney yeterli.
       - **Düzeltme:** bu adımın ilk sürümü (commit 27c1996) 5 ms'lik kayıtla yapılmıştı (bkz. 4.2 düzeltmesi). O hâliyle kol takılı deneyde K_m %4–13 dağınık, c = −12 mH çıkıyordu; "kol takılıyken K_m belirlenmiyor" ve "mod 3'te V'nin Ts ortalaması kaydedilmeli" sonuçlarına varılmıştı. İkisi de seyreltmenin yan etkisiymiş, geri alındı.
     - **Adım 1: J_M, b_M, F_c. Bitti.** Kolun sökülebildiği varsayıldı (asıl yöntem). Sökülemezse yedek yöntem de hazır (aşağıda).
       - **Asıl: kol takılmadan.** `tani_JM.m` → `tani_JM_log.txt` (K_m fonksiyonu ortak dosyada: `km_kestir.m`). Düzenek tani_Km ile aynı: r = 10⁴ rad, mod 1, açık çevrim. Tek kayıt K_m, R_a, J_M, b_M ve F_c'yi birlikte veriyor.
       - Denklem J_M·φ̈ = K_m·i − b_M·φ̇ − F_c·sgn(φ̇), pencere integrali: J_M·Δφ̇ + b_M·Δφ + F_c·sgn(φ̇)·W = K_m·∫i dt. φ̇ yalnız pencere uçlarında gerekiyor; enkoderden çevrim dışı, ±10 örneklik (±10 ms) yerel doğru uydurmasının eğimi. Pencere içinde |φ̇| < 2 rad/s olan pencereler atılıyor (yön değişimi ve Stribeck bölgesinde sürtünme sabit değil). K_m aynı kayıttan `km_kestir` ile.
       - Sonuç (gerçek: J_M 0,0036, b_M 2e-3, F_c 0,04 N·m):

         | Uyarım | Sensör | Pencere | J_M | b_M | F_c |
         |---|---|---|---|---|---|
         | **V sinüsü 0,25 Hz** | ideal | 20–100 ms | −0,08% | +0,10% | 0 (gerçek 0) |
         | **V sinüsü 0,25 Hz** | gerçekçi | 50 / 100 ms | **−0,56 / −0,21%** | **+1,4 / +1,4%** | **0,0397 / 0,0396** |
         | V sinüsü 0,25 Hz | gerçekçi | 20 ms | −2,3% | −2,9% | 0,0410 |
         | log chirp 0,5→5 Hz | ideal | 20–100 ms | ±0,1% | −2,9 … −4,4% | ~0,0015 |
         | log chirp 0,5→5 Hz | gerçekçi | 20–100 ms | −0,04 … −0,63% | −4,9 … +1,9% | 0,040–0,041 |

       - J_M her iki uyarımda iyi. b_M chirp'te daha dağınık: chirp'te hız düşük ve sürekli yön değiştiriyor, viskoz terim (b_M·φ̇) küçük kalıyor. 20 ms'lik pencere gerçekçi veride kötü (pencere başına az enkoder sayımı). **Karar: boşta deney 0,25 Hz gerilim sinüsüyle, 100 ms pencere, tek kayıt.**
       - Düzeltme: ilk sürüm (commit 8ad8a84) 5 ms'lik kayıtla yapılmıştı; o hâliyle chirp'te J_M %1,5–4 sapıyordu ve bunun eğim uydurmasından geldiği tahmin edilmişti. Gerçek neden seyreltmeymiş (±10 örnek o zaman ±50 ms ediyordu).
       - **Yedek: kol takılı, dişli boşluğunun içinde tork darbesi.** `tani_JM_kol.m` → `tani_JM_kol_log.txt`. Kol aşağıda asılı (0°). Boşluk ortası kullanılamıyor, çünkü r henüz bilinmiyor (Adım 3). Bunun yerine motor önce yavaşça bir yana döndürülür, AS5600 kolun kıpırdadığını görünce durulur: motor dişlinin bir yüzünde, önünde 2r = 3° serbest yol. Mod 3, açık çevrim tork darbesi 0,2 N·m × 20 ms; motor karşı yüze değmeden duruyor (hesap ~0,044 rad < 0,052 rad).
         - Enkoder bu harekette yalnız 6–9 sayım ilerliyor, hız tahmini anlamsız. Motor durgun başladığından denklem iki kez integralleniyor, hız tamamen düşüyor: J_M·(φ − φ₀) + F_c·d·(t − t₀)²/2 = K_m·∫(t − τ)·i dτ. Hareketin her örneği bir satır; uydurma motor durana ya da kol kıpırdayana kadar. b_M ihmal (60 ms'de etkisi ~%2, ayrılamıyor). K_m gerçek değer.
         - 10 darbe (5 ileri, 5 geri); her darbede başlangıcın enkoder ızgarasına göre konumu rastgele (gerçekte de öyle).
         - Sonuç: ideal veride J_M −%3,9 (ihmal edilen b_M ve akımın bir örnek gecikmeli kaydı). Gerçekçi veride tek darbe −%22 ile +%7 arası (std %11), 10 darbe birleşik **J_M −%13,5, F_c 0,050** (gerçek 0,040). Dağınıklığın kaynağı 6–9 sayımlık enkoder nicemlemesi; birleşik sapmanın kaynağı büyük olasılıkla hareketin başında ve sonunda baskın olan Stribeck sürtünmesi (F_s = 0,06), uydurmada sabit F_c varsayılıyor (ayrıca doğrulanmadı).
         - **Sonuç: yedek yöntem asıl yöntemden ~30 kat kötü (%13 ve %0,5).** Kol sökülemezse J_M bu doğrulukla bilinecek; etkisi 4.4'te kritik r_gs öngörüsüne yansıtılacak.
       - **Model düzeltmesi (bu adımda bulundu):** Simscape ağı her zaman göreli 0 konumundan başlıyor, ölçüm sensörleri `S.x0`'ı yalnız ofset olarak ekliyor. Hard Stop sınırları ise ağın göreli açısına göre ±r. Başlangıçta dişli boşluğun ortasında değilse (δ₀ = φ₀ − θ₀ ≠ 0), temas noktaları ±r yerine ±r − δ₀'a düşüyordu. Yedek yöntemin ilk koşusunda motor 1,5° sonra kola çarptı. `sm_model_kur.m`'de sınırlar artık `±S.r − (S.x0(1) − S.x0(3))`. Varsayılan başlangıçta δ₀ = 0, dolayısıyla önceki bütün Simscape sonuçları etkilenmemiş (δ₀ ≠ 0 kullanan tek eski betik `kok_neden_3.m`, o da kol_benzetim ile).
     - **Adım 2: dişli sertliği K_s. Bitti (c_s ölçülemiyor).** `tani_Ks.m` → `tani_Ks_log.txt`.
       - **Önce rezonans denendi, çalışmadı.** Kol 90°'de, P-PI kapalı çevrim, mod 3, torka chirp 2→30 Hz (0,03 / 0,06 / 0,1 N·m). İdeal sensörle dişli sapması δ = φ − θ_L'nin dinamik kısmı std 0,09–0,30°, yani enkoderin bir sayımının (0,273°) altında. Gerçekçi düzeyde 0,03 ve 0,06 N·m'de motor hiç kıpırdamıyor (statik sürtünme F_s = 0,06 uyarımı yutuyor), 0,1 N·m'de sapma 0,6 enkoder sayımı. Üst sınır fiziksel: dişlinin temasta kalması için dinamik tork ön yükü (mgl·sinθ) aşmamalı, yani sapma en fazla ±mgl/K_s = ±1,4° oynayabilir. Rezonans frekansı ve sönümü bu sensörlerle görülemiyor.
       - **Yöntem: yarı statik tarama.** P-PI kapalı çevrim, mod 3, referansa yavaş sinüs 90° ± 70° (0,05 Hz, 20 s). Kol 20°–160° arasında dönerken yerçekimi dişliyi hep aynı yüze yaslıyor (temas payı δ − r en az 0,3°), dişli torku mgl·sinθ ile 0,08–0,24 N·m arasında, sapma da onunla değişiyor. Dişli torku motor tarafından, Adım 1'in parametreleriyle: τ_g = K_m·i − J_M·φ̈ − b_M·φ̇ − F_c·sgn(φ̇), τ_g = K_s(δ − r) + c_s·δ̇. Pencere ortalaması (100 ms; φ̈ yerine pencere uçlarındaki hız, ±10 örnek yerel eğim): ort(τ_g) = K_s·ort(δ) − K_s·r [+ c_s·Δδ/W]. Hızın yön değiştirdiği ya da |φ̇| < 0,1 rad/s olan pencereler atılıyor.
       - **Neden kapalı çevrim:** açık çevrimde kol tarama yörüngesinde (ya da 90°'de) tutulamaz. Denklem yalnız ölçülen akım ve açıları içeriyor, kontrolcünün komutu denkleme girmiyor; kontrolcünün varlığı kestirimi bozmuyor.
       - Sonuç (gerçek K_s 10; gerçekçi düzeyde 5 koşu, gürültü tohumu ve başlangıcın sensör ızgarasına göre konumu farklı):

         | Uydurma | İdeal | Gerçekçi, ortalama ± std |
         |---|---|---|
         | bütün pencereler, c_s'li | 0,00% | −0,79 ± 0,17% |
         | bütün pencereler, c_s'siz | 0,00% | −0,91 ± 0,27% |
         | yalnız yukarı / yalnız aşağı | 0,00 / 0,00% | −1,21 / +0,73% |
         | **(yukarı + aşağı)/2** | 0,00% | **−0,24 ± 0,18%** |
         | (yukarı + aşağı)/2, Adım 1 kestirimleriyle (K_m, J_M, b_M, F_c) | +0,02% | −0,22 ± 0,18% |

       - Yukarı ve aşağı taramanın hatası zıt işaretli; iki yönün ortalaması onu söndürüyor. Yöne bağlı bir hata kaynağı (sürtünme modelindeki Stribeck kısmı ya da AS5600'ün bir örnek gecikmesi; ayrıca ayrıştırılmadı). **Karar: yukarı ve aşağı tarama ayrı uydurulup ortalanır, K_s ~%0,5 içinde.** Adım 1'in kestirim hataları K_s'ye yansımıyor.
       - Kol sürekli döndüğünden φ ve θ_L her pencerede birçok sayım geçiyor; sayımın altındaki sapma bu yüzden ortalamada ölçülebiliyor.
       - **Kesişim r'yi vermez.** Benzetimde kesişim 1,397° (gerçek r 1,500°). Fark nicemlemenin aşağı yuvarlamasından: her sensör ortalamada yarım basamak eksik okuyor; (q_M − q_L)/2 eklenince 1,489°. Gerçek donanımda ayrıca enkoder ve AS5600'ün sıfırları bağımsız, kesişime bilinmeyen bir ofset ekleniyor. r Adım 3'te.
       - **c_s bu deneyden çıkmıyor:** 0,021–0,048 arası dağınık (gerçek 0,02; ideal veride bile 0,017). Yarı statik harekette δ̇ ≈ 0. Rezonans yoluyla da ölçülemediğinden c_s bir varsayım olarak kalacak; 4.4'ten önce kritik r_gs öngörüsünün c_s'ye duyarlılığına bakılacak.
     - **c_s duyarlılığı. Sonuç: öngörü c_s'ye duyarlı.** `tarama_cs.m` → `tarama_cs_log.txt`. Kurulum `tarama_hiz.m` ile aynı (mod 1, P-PI, 3 açı × 3 başlangıç sapması, sınır = sınıf ≥ 3 ve A > 0,5°). Yalnız c_s değişiyor. Süreyi kısaltmak için r_gs aşağıdan yukarı taranıyor ve ilk salınan değerde duruluyor (`ilk` tanımıyla aynı sonuç; c_s = 0,02 satırı tarama_hiz'in gözlemci satırını birebir verdi). Sönüm oranı ζ_s = c_s / (2√(K_s·J_eş)), J_eş = J_M·J_L/(J_M + J_L) = 0,0018.

       | c_s [N·m·s/rad] | ζ_s | Gerçekçi, gözlemci (30 / 60 / 90°) | İdeal (30 / 60 / 90°) |
       |---|---|---|---|
       | 0 | 0 | ≤0,80 / 1,05 / 1,05 | 0,80 / 1,00 / 1,00 |
       | 0,01 | 0,037 | 0,90 / 1,20 / 1,20 | — |
       | **0,02 (varsayılan)** | **0,075** | **1,00 / 1,30 / 1,30** | **0,90 / 1,10 / 1,10** |
       | 0,04 | 0,149 | 1,10 / 1,35 / 1,40 | 1,00 / 1,20 / 1,20 |

       (≤0,80: taramanın alt ucu zaten salınıyor, gerçek sınır daha aşağıda.)
       - Etki büyük: c_s'nin 2 kat belirsizliği (0,01–0,04) sınırı 60–90°'de 1,20–1,40, 30°'de 0,90–1,10 aralığına yayıyor, yani ±0,10. Bu, K_s'nin (%0,5) ve J_M'nin (asıl yöntemde %0,5) belirsizliğinden çok büyük. Tarama adımı 0,05 olduğundan sayılar ±0,05 içinde.
       - Fiziksel yorum: c_s dişli çevriminde (limit cycle) dişler çarpışırken her temasta enerji yutuyor. Sönüm azaldıkça çevrim daha düşük kazançta kendini sürdürebiliyor.
       - İdeal sensörde de aynı eğim (c_s'nin her 0,02'si ~0,10), yani etki nicemlemeden değil modelin kendisinden geliyor.
       - Bu yüzden c_s için ayrı bir deney arandı (aşağıda, Adım 2b).
     - **Adım 2b: dişli sönümü c_s, kola darbe (çekiç testi). Bitti: motor mili kilitliyken ölçülebiliyor.** `tani_cs.m` → `tani_cs_log.txt`.
       - **Fikir:** Adım 2'deki chirp'te sorun, dinamik sapmanın motor enkoderinin bir sayımının altında kalmasıydı. Kola dışarıdan darbe verip yalnız kolun açısına bakılırsa (AS5600, enkoderden 3 kat ince) sorun ortadan kalkıyor. Kol 90°'de, yerçekimi dişliyi yaslıyor. t = 1 s'de kola 10 ms'lik yarım sinüs tork darbesi veriliyor (−0,42 N·m, aşağı, dişliyi daha çok sıkıştıran yönde). Darbe sonrası 0,6 s'lik θ_L kaydına sönümlü sinüs uyduruluyor: θ = c₀ + c₁t + e^(−σt)(a·cos ωt + b·sin ωt), ζ_göz = σ/√(σ² + ω²). Dişli her koşuda temasta kalıyor (pay ≥ 0,44°). Modelde yük bozucusuna başlangıç zamanı eklendi (`p.d0`, varsayılan 0; eski koşular değişmiyor).
       - **a) Motor kontrolcüyle tutuluyor** (P-PI r_gs 0,5, mod 3). Motor statik sürtünmeyle neredeyse kilitli (en çok 1 enkoder sayımı), f = 8,4 Hz = √(K_s/J_L)/2π. Gerçekçi düzeyde (3 koşu):

         | c_s | 0 | 0,01 | 0,02 | 0,04 |
         |---|---|---|---|---|
         | ζ_göz | 0,023 ± 0,004 | 0,037 ± 0,001 | 0,063 ± 0,002 | 0,115 ± 0,003 |

         c_s'ler net ayrışıyor, ama c_s = 0'da da 0,023'lük sönüm var: motorun mikro kayması ve kontrolcü enerji yutuyor. Eğri benzetimden kurulmak zorunda (eğim dζ/dc_s ≈ 2,6) ve sağlamlık denemesinde (c_s = 0,02'de bir bilinmeyen değiştirilerek) c_s kestirimi kayıyor:

         | Değişen | F_s 0,04 / 0,09 | F_c 0,03 / 0,05 | darbe −0,21 / −0,63 | r_gs 0,4 / 0,6 | J_L ×1,05 | b_L ×10 |
         |---|---|---|---|---|---|---|
         | c_s hatası | +0,006 / −0,005 | +0,003 / −0,002 | −0,002 / **+0,026** | +0,003 / −0,004 | −0,001 | 0,000 |

         r_gs ve darbe genliği deneyde bilinir (benzetim aynısıyla kurulur); F_c Adım 1'den %1 içinde. Asıl belirsizlik **F_s** (Adım 1'de ölçülmüyor): ±0,005, yani ~%25. Büyük darbe (−0,63) motoru kaydırıyor, uydurma bozuluyor.
       - **b) Motor mili mekanik olarak kilitli** (benzetimde J_M ×10⁴). Kol dişli yayı üzerinde tek kütle; kontrolcü ve motor sürtünmesi denklemden çıkıyor, eğriye gerek kalmıyor: ζ = (c_s + b_L)/(2√(K_s·J_L)) → c_s = 2√(K_s·J_L)·ζ_göz − b_L (K_s Adım 2'den, J_L geometriden). Gerçekçi düzey, 2 koşu:

         | Durum | Gerçek c_s | Formülle c_s |
         |---|---|---|
         | taban | 0 / 0,01 / 0,02 / 0,04 | 0,0000 / 0,0100 / 0,0195 / 0,0403 |
         | F_s 0,04 / 0,09 | 0,02 | 0,0204 / 0,0200 |
         | r_gs 0,6 | 0,02 | 0,0196 |
         | darbe −0,21 / −0,63 | 0,02 | 0,0207 / 0,0199 |
         | J_L ×1,05 (formülde nominal J_L) | 0,02 | 0,0198 |

         Hata her durumda ≤ 0,0007 (~%3,5); kritik r_gs'ye etkisi ~0,004, tarama adımının çok altında.
       - **Karar: c_s motor mili kilitlenip kola darbe verilerek ölçülür (b).** Donanım için: motor tarafındaki dişli (ya da mil) bir pim/kelepçeyle gövdeye sabitlenir, kol 90°'de dişliye yaslı bırakılır, kola elle hafif vurulur. Darbe genliği önemli değil, yeter ki dişli temastan ayrılmasın: θ_L tepeden tepeye ≲ 25 AS5600 sayımı (±mgl/K_s = ±1,4° sınırı). Kilitlenemezse (a) yolu kullanılır; o zaman F_s ayrıca ölçülmeli ya da c_s ±%25 belirsizlikle verilmeli.
       - **Not (ayrılamayan terim):** kilitli deney c_s + b_L'yi birlikte ölçüyor; kol yatağının sönümü dişlininkinden ayrılamıyor. Modelde b_L = 1e-4 (c_s'nin %0,5'i), önemsiz. Ama gerçek yatakta Coulomb sürtünmesi varsa sönüm üstel değil doğrusal azalır; kayıtta zarfın biçimine bakılmalı (benzetimde yatak sürtünmesi yok, sınanmadı).
     - **Adım 3: dişli boşluğu r. Bitti.** `tani_r.m` → `tani_r_log.txt`.
       - **Yöntem: sıfırın iki yanına yarı statik tarama** (Yamada 2016'nın yön değişimi sıçramasının yarı statik hâli). P-PI kapalı çevrim, mod 3, referansa yavaş sinüs 0° ± 60° (0,05 Hz, 20 s). Yerçekimi torku mgl·sinθ 0°'da işaret değiştiriyor: kol θ > 0'da dişliyi + yüze, θ < 0'da − yüze yaslıyor. Ölçülen sapma δ_m = φ_enkoder − θ_AS5600 = δ + o (o: iki sensörün bağımsız sıfırları ve nicemleme yuvarlaması). Temas varken τ_g = K_s(δ − s·r), s = işaret(θ). Pencere ortalamasıyla (Adım 2'deki gibi, 100 ms):
         - A) K_s, r, o birlikte: ort(τ_g) = K_s·ort(δ_m) − K_s·r·s − K_s·o
         - B) K_s Adım 2'den sabit: ort(δ_m) − ort(τ_g)/K_s = r·s + o
       - İki yüzün kümeleri arasındaki fark 2r; o iki kümede aynı olduğundan sadeleşiyor. Adım 2'deki kesişim sorunu (yuvarlama, bağımsız sıfırlar) burada yok. Yöntemin ofsete duyarsız olduğunu göstermek için analizde AS5600 okumasına keyfi 7,3° ofset eklendi. Yüz geçişi dinamik (kol boşluktan düşüyor); |θ| < 10° olan pencereler atılıyor. Tork motor tarafından, Adım 1'in kestirimleriyle.
       - Sonuç (gerçek r 1,500°; gerçekçi düzeyde 5 koşu, ortalama ± std):

         | Uydurma | İdeal | Gerçekçi |
         |---|---|---|
         | A) K_s serbest, bütün pencereler | 0,00% | −0,41 ± 0,18% |
         | A) (yukarı + aşağı)/2 | 0,00% | −0,05 ± 0,12% |
         | **B) K_s Adım 2'den, bütün pencereler** | 0,00% | **−0,11 ± 0,04%** |
         | B) (yukarı + aşağı)/2 | 0,00% | −0,12 ± 0,04% |
         | (A'nın K_s'si) | 0,00% | −1,0 ± 0,5% |
         | ofset o | 7,300° | 7,208° (7,3° − yuvarlama, r'ye sızmıyor) |

       - **Karar: B uydurması (K_s Adım 2'den), r ~%0,2 içinde.** Bu deneyde K_s'yi ayrıca uydurmak gereksiz ve daha kötü: tork aralığı (0–0,21 N·m) Adım 2'den dar. Yön ayrımı B'de gerekmiyor.
       - **Önemli yan bulgu: deney kazancı düşük olmalı.** İlk koşu Adım 2'nin kazancıyla (r_gs 0,8) yapıldı. Küçük açılarda (|θ| ≈ 10–30°) yerçekimi ön yükü az, dişli boşluğu çevrimi başlıyor. Dişli |θ| > 10° iken bile zamanın ~%7'sinde ters yüzdeydi (her yarım salınımın başında, kol 0°'dan uzaklaşırken), r hatası −1,4 ± 0,7% (B) ve −4,8 ± 2,8% (A) çıktı. r_gs 0,5 ile temas her koşuda en az 0,21° payla doğru yüzde. Bu, kritik r_gs'nin küçük açılarda 0,8'in altında olduğunu da gösteriyor (30°'de 1,00). Donanımda bu deney r_gs ≤ 0,5 ile yapılmalı, temas da "δ_m kümeleri iki ayrı düz çizgi mi" diye kayıttan kontrol edilmeli.
     - **Adım 4: kalan parametreler ve doğrulama.** 4.3'te henüz ölçülmeyenler: J_L, mgl, b_L, motorun statik sürtünmesi F_s. Plan: 4a mgl (eldeki kayıtlardan), 4b tanılanan takımla tanılamada kullanılmamış bir deneyin (dişli boşluğu salınımı dahil) benzetilip ölçümle karşılaştırılması, 4c gerekirse F_s.
       - **4a: mgl ve AS5600 sıfırı. Bitti.** `tani_mgl.m` → `tani_mgl_log.txt`. Yeni benzetim yok, Adım 2 (90° ± 70°) ve Adım 3 (0° ± 60°) kayıtları yeniden kullanılıyor. Kol denklemi τ_g = J_L·θ̈ + b_L·θ̇ + mgl·sinθ. AS5600'ün sıfırı bilinmediği için θ = θ_m − θ₀, mgl·sin(θ_m − θ₀) = a·sinθ_m + b·cosθ_m. Bu doğrusal; mgl = √(a² + b²), θ₀ = atan2(−b, a). Pencere ortalaması ve yukarı/aşağı ortalama Adım 2 ile aynı, AS5600'e keyfi 7,3° ofset eklendi.
         - **J_L terimi küçük ama sistematik:** sinüs taramada θ̈ = −ω²(θ − merkez), sinθ ya da cosθ terimiyle örtüşüyor. J_L ihmal edilince ideal veride bile mgl −0,17% (0° taraması) ve θ₀ −0,10° (90° taraması) sapıyor (J_L·ω²/mgl ≈ %0,15). J_L bu deneyden çıkmıyor, geometriden alınıp terim çıkarılıyor; J_L %5 yanlış olsa bile etkisi ≤ 0,01%.

         | Kayıt | mgl hatası, J_L ihmal / J_L ile | θ₀ hatası, J_L ihmal / J_L ile |
         |---|---|---|
         | 90° ± 70°, ideal | 0,00 / 0,00% | −0,099 / 0,000° |
         | 90° ± 70°, gerçekçi (5 koşu) | +0,01 / +0,01 ± 0,01% | −0,132 / −0,043 ± 0,007° |
         | 0° ± 60°, ideal | −0,17 / 0,00% | −0,027 / 0,000° |
         | 0° ± 60°, gerçekçi (5 koşu) | −0,12 / +0,06 ± 0,03% | −0,044 / −0,046 ± 0,004° |

         - Gerçekçi veride θ₀'da kalan −0,045° iki kayıtta da aynı; AS5600'ün yarım sayımı (0,044°, `floor` yuvarlaması). Kontrolcü de aynı sensörü okuduğu için zararsız.
         - **Karar: mgl Adım 2'nin kaydından (90° ± 70°, tork aralığı geniş), J_L terimiyle, %0,1 içinde. Aynı uydurma AS5600'ün sıfırını (kolun düşey konumunu) da veriyor; ayrı kalibrasyon gerekmiyor.**
       - **4b: tanılanan takımla öngörü. Bitti.** `tani_dogrula.m` → `tani_dogrula_log.txt`. Tanılanan takım: adımların gerçekçi koşu ortalamaları (J_M −0,21%, b_M +1,35%, F_c 0,0396, K_s −0,24%, c_s 0,0195, r −0,11%, mgl +0,01%); J_L ve b_L nominal (geometri). F_s ölçülmediğinden iki varsayım: F_s = F_c (Stribeck tepesi yok) ve F_s = 0,06 (doğru değer). Sensör, kontrolcü ve gözlemci üç takımda aynı. Tarama `tarama_cs` ile aynı (mod 1, 3 başlangıç sapması, ilk salınan r_gs).

         | Takım | Kritik r_gs (30 / 60 / 90°) | 90°, r_gs 1,45: sınıf, A, f | 90°, r_gs 1,60: sınıf, A, f |
         |---|---|---|---|
         | gerçek | 1,00 / 1,30 / 1,30 | 3, 1,25°, 8,12 Hz | 5, 1,77°, 8,19 Hz |
         | tanılanan, F_s = 0,06 | 0,95 / 1,30 / 1,30 | 3, 1,50°, 8,15 Hz | 5, 1,78°, 8,16 Hz |
         | tanılanan, F_s = F_c | 0,95 / 1,25 / 1,25 | 1 (sönüyor), — | 5, 1,79°, 8,20 Hz |

         - Tanılanan takım sınırı en çok bir tarama adımı (0,05) içinde öngörüyor; sınırın iyice üstünde (1,60) genlik %1, frekans %0,5 içinde.
         - Sınıra yakın (1,45) genlik %20 farklı. Bu bölgede sonuç başlangıç koşuluna ve küçük parametre farklarına duyarlı (F_s = F_c takımında 1° başlangıç sapması sönüyor, oysa sınır 1,25; başka bir başlangıç sapması salınıyor). Sınır yakınında tek koşunun genliği sağlam bir doğrulama ölçütü değil.
         - **Ölçülmeyen F_s öngörüyü 60–90°'de 0,05 aşağı çekiyor** (bir tarama adımı). Kalan parametrelerin hatalarının toplam etkisi bir adımın altında (30°'deki 0,05 farkı tek adım; sınırın tam üstünde).
         - **Sonuç: tanılama zinciri öngörüyü ±0,05 içinde veriyor. Kalan en büyük belirsizlik F_s; ölçmek kolay (4c).**
       - **4c: motorun statik sürtünmesi F_s, kopma torku. Bitti.** `tani_Fs.m` → `tani_Fs_log.txt`. Adım 1'in boşta düzeneği (kol sökülü), mod 3, açık çevrim. Torka çok yavaş sinüs (0,1 N·m, 0,02 Hz; sıfır geçişinde ~0,013 N·m/s rampa), her yarım periyotta bir kopma. Kopma anı: aynı yönde, aralarında ≤ 50 ms olan iki enkoder sayımının ilki. F_s = o andan önceki 20 ms'nin K_m·i ortalaması.
         - Tek sayım yetmiyor: modeldeki Stribeck sürtünmesi tanh(φ̇/v_ε) ile yumuşatılmış, kopmadan önce de çok yavaş sürünmeye izin veriyor (koşu başına 1–3 tek başına sayım). Gerçek dişli yapışır; donanımda algılama daha temiz olmalı.

         | Gerçek F_s | Düzey | Kestirim hatası (her iki yön) |
         |---|---|---|
         | 0,06 | ideal akım | +0,70 ± 0,02% |
         | 0,06 | gerçekçi (4 koşu, 8 kopma) | **+0,71 ± 0,21%** |
         | 0,09 | gerçekçi (2 koşu, 4 kopma) | −0,80 ± 0,30% |

         - Pozitif yanlılık rampa gecikmesinden (kopmadan algılamaya ~30–50 ms × rampa eğimi). Yöntem F_s'yi izliyor (0,09'da da %1 içinde).
         - **Karar: F_s boşta deneyde, Adım 1'in kaydından sonra aynı düzenekte ~36 s'lik ek bir kayıtla, %1 içinde.** 4b'de F_s'nin tamamen yanlış varsayılması sınırı bir adım kaydırıyordu; %1'lik hatanın etkisi ihmal edilebilir. Tanılanan takımın öngörüsü böylece 4b'deki "F_s = 0,06" satırı: 0,95 / 1,30 / 1,30 (gerçek 1,00 / 1,30 / 1,30).
       - **4d: J_L, kilitli darbe testinin frekansından. Bitti (yeni benzetim yok).** Kilitli motorda kol dişli yayı üzerinde tek kütle: ω_n² = K_s/J_L, ω_n = √(σ² + ω_d²) (Adım 2b'nin sönümlü sinüs uydurmasından). `tani_cs_log.txt`'nin "kilit" bloğundaki 23 koşudan (c_s 0–0,04, F_s, kazanç, darbe, J_L ×1,05 varyantları; gerçek K_s ile): **J_L hatası −0,25 … +0,13%**. Logdaki frekans iki basamaklı yuvarlandığından bu aralığın bir kısmı yuvarlama. K_s'nin hatası (Adım 2, −0,24%) J_L'ye birebir geçer. Donanımda ölçülen sertlik kilit pimi ve milin esnekliğini de içerir; D3'teki K_s ile karşılaştırılarak denetlenir (`calisma_notu/deney_protokolu.md`).
       - **4e: aynı deneyler mod 1'de (akım döngüsü olmadan). Bitti: mod 3 gerekmiyor.** Donanım planında akım I²C'den (INA228) okunuyor, benzetimdeki 10 kHz'lik akım döngüsünün (mod 3) karşılığı yok. Adım 2, 2b (kilit), 3 ve 4c mod 1 ile yeniden koşuldu (`tani_Ks(true,1)`, `tani_cs(true,'kilit',1)`, `tani_r(true,[],1)`, `tani_Fs(true,1)`; kayıtlar `*_mod1_kayit.mat`, sonuçlar aynı log dosyalarında "mod 1" başlığıyla). Denklemler ölçülen akımı (K_m·i) kullandığından sürücünün nasıl çalıştığı kestirime girmiyor.

         | Parametre (gerçekçi, ortalama ± std) | Mod 3 | Mod 1 |
         |---|---|---|
         | K_s, (yukarı + aşağı)/2 | −0,24 ± 0,18% | −0,28 ± 0,39% |
         | r, K_s Adım 2'den | −0,11 ± 0,04% | −0,15 ± 0,03% |
         | c_s, motor kilitli (c_s = 0,02) | −0,0005 | −0,0005 (aynı; motor kilitli, sürücü etkisiz) |
         | F_s = 0,06 | +0,71 ± 0,21% | −1,04 ± 0,68% |
         | F_s = 0,09 | −0,80 ± 0,30% | −2,40 ± 1,32% |

         - F_s mod 1'de biraz daha kötü ve aşağı yanlı: kopmaya yakın sürünmede zıt EMK akımı düşürüyor. %2–3'lük F_s hatasının kritik r_gs'ye etkisi ~0,002 (4b'de F_s'nin tamamen yanlış olması 0,05 ediyordu). K_s'nin dağınıklığı iki katına çıkıyor ama %0,5–1 içinde.
         - **Karar: bütün tanılama deneyleri mod 1'de yapılabilir; firmware'e hızlı akım döngüsü gerekmiyor.** Akım yalnız kayıt için ölçülüyor (1 kHz'te INA228 yeterli; benzetimdeki IPROPI → ADC varsayımı daha gürültülü, yani karamsar). Asıl deney (D6) zaten mod 1.
       - **4.3 özeti:** bütün parametreler firmware kaydından, gerçekçi sensörlerle: K_m %0,3, J_M %0,5, b_M %1,4, F_c %1, F_s %1, K_s %0,5, c_s %3,5 ve J_L %0,5 (motor kilitli darbe), r %0,2, mgl %0,1, AS5600 sıfırı 0,05°. Öngörülen kritik r_gs en çok bir tarama adımı (0,05) şaşıyor.
5. Simscape.
   - **5a, mekanik çapraz kontrol. Bitti.** `sm_model_kur.m` → `sm_kol_model.slx`, doğrulama `dogrula_5a.m` → `dogrula_5a_log.txt`. Kol ve motor Simscape fiziksel bloklarıyla kuruldu: Inertia, Rotational Damper, dişli teması için Rotational Hard Stop (`smooth` model; geçiş bölgesi sıfıra giderken temas yasası betikteki `max(K_s(δ−r)+c_s δ̇, 0)` ile aynı), Ideal Torque Source ve Ideal Rotational Motion Sensor. Yerçekimi, bozucu ve Stribeck sürtünmesi Simulink'te hesaplanıp tork olarak veriliyor (`blok_yuk.m`).
     - Sonuç: 10 koşunun (5 hücre × 2 sensör düzeyi) 10'unda rejim sınıfı aynı. İdeal düzeyde genlik ve frekans farkı %0,3'ün altında. Gerçekçi düzeyde salınan hücrede (5) genlik farkı %0,3; öteki hücrelerde genlik AS5600 çözünürlüğünün altında kaldığından frekans anlamsız.
     - Kalan farkın kaynağı sayısal: Simscape sabit adımlı çözücüde temas modunu adım boyunca sabit tutuyor, betikteki RK4 her ara aşamada yeniden değerlendiriyor. İlk adımlarda iki model 8 haneye kadar aynı; fark temas anlarında açılıyor ve adım 4 kat küçülünce yaklaşık 4 kat küçülüyor (hücre 2: 6,6e-4° → 1,7e-4°). Geçiş bölgesini 1e-6'dan 1e-8 rad'a daraltmak sonucu değiştirmiyor.
     - Teknik not: Hard Stop ağda cebirsel denklem bırakıyor. Simulink bu yüzden ağı "girdi çıktıyı anında etkiliyor" sayıyor ve geri besleme döngüsünü cebirsel döngü olarak görüyor. Durum tutan (persistent) MATLAB Function blokları böyle bir döngüde çalışamıyor. Çözüm: sensör ve kontrolcü tek bir durumsuz bloğa toplandı (`blok_ayrik.m`, hesap `blok_sensor` + `blok_kontrolcu` ile aynı), durumlar bir Unit Delay'e taşındı. Döngüyü Simulink çözüyor; gerçek bir anlık bağımlılık olmadığından sonuç değişmiyor.
   - **5b, motorun elektrik tarafı. Bitti.** `sm_model_kur(ad, 'elektrik')` → `sm_motor_model.slx`. Simscape Electrical DC Motor (R, L, zıt EMK; kol tarafına indirgenmiş eşdeğer, `sim_param.m`), DRV8874 ortalama gerilim modeli (±12 V doyum, 2 A akım sınırı → 0,43 N·m), IPROPI akım ölçümü. Firmware'in tork → gerilim çevrimi `blok_surucu.m`: mod 1 gerilim, mod 2 zıt EMK kompanzasyonu, mod 3 akım döngüsü (PI, 10 kHz, ADC → PWM bir örnek gecikme).
     - Tarama `tarama_5b.m` (3 açı × r_gs 0,70–1,40 × 3 başlangıç sapması, iki sensör düzeyi), sınır analizi `analiz_5b.m` → `tarama_5b_log.txt`. Kritik r_gs (30/60/90°):

       | Model | İdeal sensör | Gerçekçi sensör |
       |---|---|---|
       | İdeal tork 0,49 N·m | 0,85 / 1,05 / 1,10 | 0,90 / 1,25 / 1,30 |
       | İdeal tork 0,43 N·m | 0,90 / 1,10 / 1,10 | 1,00 / 1,35 / >1,40 |
       | Mod 1, 2, 3 | 0,90 / 1,10 / 1,10 | 1,00 / 1,35 / 1,40 |

     - Sonuç: firmware modu salınım sınırını değiştirmiyor. Sınırı kaydıran tek elektrik etkisi DRV8874'ün tork sınırı (0,49 → 0,43 N·m, sınır +0,05–0,10). Sınırda salınım dişli boşluğu çevrimi; zıt EMK sönümü (~7·b_M) bu çevrimin enerji dengesini fark edilir değiştirmiyor.
     - Sınır tanımı: sınıf ≥ 3 ve genlik > 0,5°. Gerçekçi sensörde AS5600 nicemleme titreşimi (~0,05°) `A_min` eşiğine takılıp tek tük "düzensiz" sayılıyordu (mod 2 ve 3'te 30°'de sahte 0,75 / 0,70); gerçek çevrimler 1°'nin üstünde.
     - Firmware kararı: mod 1 (gerilim) varsayılan; en basit, IPROPI gerektirmiyor. Mod 3 sistem tanılama deneyleri için eklenecek (tork akımdan doğrudan bilinir, sargı ısınmasıyla Ra kaymasından etkilenmez). Mod 2 kazanç getirmiyor, hız kestirimine bağımlı; kullanılmayacak.
   - **5c, Simscape Multibody 3B modeli. Bitti.** `mb_model_kur.m` → `mb_kol_model.slx`, geometri ve kütleler `mb_param.m`, doğrulama `dogrula_mb.m` → `dogrula_mb_log.txt` (θ(t) izleri `dogrula_mb_izler.mat`), görüntü `mb_kareler.m` → `rapor/img/mb_3b_gorunum.png`, `mb_kareler.png`.
     - Yapı: World Frame + Mechanism Configuration (mekanizma çerçevesinde yerçekimi −Y). Rotor ve kol aynı Z ekseninde iki ayrı Revolute Joint (Multibody'nin eklemlerinde boşluk yok). Rotor = kol tarafına indirgenmiş eşdeğer disk (Izz = J_M), kol = çubuk (150 mm, 20 g) + uç kütlesi (silindir). Açı tanımı 1B modelle aynı: 0° sarkık, 90° yatay, 180° dik.
     - Dişli teması 1B ağda kaldı: iki Rotational Multibody Interface eklemleri 1B mekanik ağa bağlıyor; ağda 5a'daki Rotational Hard Stop, b_M, b_L ve tork kaynakları var. Eklemler torku arayüzden alıyor, açı ve hızı kendi algılama portlarından veriyor.
     - Kütleler "Custom" eylemsizlikle, 1B modelin değerlerinden türetildi: g(m_r L/2 + m_u d) = mgℓ ve Izz_çubuk + m_r(L/2)² + Izz_uç + m_u d² = J_L. Uç kütlesi tam 150 mm'ye konunca iki koşul birlikte sağlanamıyor (uç kütlesinin kendi eylemsizliği −6,7e-7 kg·m² çıkıyor); bu yüzden m_u ve d birlikte çözüldü: m_u = 153,9 g, d = 149,5 mm.
     - Yerçekimi Multibody'den geliyor; `blok_yuk`'taki −mgℓ sin θ terimi çift sayılmasın diye model `S.mgl = 0` ile koşuluyor (gerçek mgℓ `M` yapısıyla geometriye giriyor).
     - **Çözücü bulgusu:** global açık `ode4` bu ağda yanlış sonuç veriyor. Eklemler ve arayüzler cebirsel denklem bırakıyor; MATLAB "implicit solver önerilir" uyarısı veriyor. Kontrolcü kapalıyken bütün sönümler sıfırlanınca 1B modelde dişli salınımı sabit kalıyor, 3B modelde her çevrimde büyüyor (sayısal enerji girişi). Kapalı çevrimde hücre 5 genliği 11,4° çıkıyor (doğrusu 8,1°), hücre 3 ve 4'te rejim sınıfı değişiyor. Adımı 4 kat küçültmek düzeltmiyor. `ode23t` ve `ode15s` ile iki model aynı (hücre 5: 8,126° / 8,126°, 7,07 Hz). Çözüm: fiziksel ağa yerel Backward Euler çözücüsü (Solver Configuration, adım dt); global çözücü ve kontrolcü ode4'te kalıyor. Yerel trapez ve bölümleme çözücüleri dt = 1e-4'te hücre 5 genliğinde %1,3 ve %2,8 sapıyor (8,248° ve 8,372°).
     - Sonuç: 10 koşunun 10'unda rejim sınıfı aynı. Salınan hücrelerde (genlik ≥ 0,05°) 3B − 1B farkı: hücre 1 ideal genlik %0,16, frekans %0,01; hücre 5 ideal %0,17 / %0,08; hücre 5 gerçekçi %0,31 / %0. Öteki hücrelerde genlik 0,05°'nin altında, frekans anlamsız; yüzde ölçütü uygulanmadı.
     - Mechanics Explorer animasyonu: `mb_animasyon.m` → `rapor/img/mb_animasyon.mp4` + `mb_me_kareler.png` (son çevrimden 6 kare). Arayüzlü MATLAB gerekir: `matlab -r "addpath('simulasyon/simulink'); mb_animasyon(5, [], true)"`; `-batch`'te Mechanics Explorer açılmıyor, koşu takılıyor.
       - Tuzak: `smwritevideo` hemen dönüyor ama MP4'ü ancak MATLAB boşta kalınca kapatıyor. Fonksiyon içinde `pause` ile beklemek ya da `quit` dosyayı yarım bırakıyor (`moov` bölümü yok, VideoReader açamıyor). Betik bu yüzden videoyu başlatıp dönüyor; bir `timer` dosya okunabilir olunca (yaklaşık 1 dk) kareleri çıkarıyor ve MATLAB'ı kapatıyor.
       - Mechanics Explorer'ın varsayılan kamerası XZ düzlemine (z yukarı) bakıyor. Mekanizma bu yüzden `T_eksen` dönüşümüyle kuruldu: eklem ekseni dünya −Y, yerçekimi dünya −Z. Rotor diskinde kütlesiz bir Graphic işaret φ'yi gösteriyor. Döndürmeden sonra 10 doğrulama koşusunun sayıları birebir aynı.
     - 3B perspektif görünüm `mb_kareler.m` ile (`-batch`'te çalışır): model koşuluyor, aynı geometri φ(t), θ(t) ile MATLAB figüründe çiziliyor. Görüntü bu yüzden `mb_kareler.m` ile alındı: model koşuluyor, φ(t) ve θ(t) ile aynı geometri (`mb_param`) MATLAB figüründe çiziliyor.
