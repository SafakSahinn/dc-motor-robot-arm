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
     - θ_L: rms 0,05°, en çok 0,14–0,20°. Nicemleme (`floor`, −q/2 kayması) + bir örnek gecikme.
     - φ: en çok bir enkoder sayımı (0,27°).
     - v̂: rms 0,04–0,11 rad/s.
     - i: rms 1,4–1,7 mA.
     - Mod 3'te akımdan bulunan tork K_m·i ile komut u arasındaki fark rms 0,010–0,017 N·m (Tmax'ın %2–3'ü). Tanılamada tork girdisi olarak mod 3'te u ya da K_m·i kullanılabilir. Mod 1'de zıt EMK yüzünden gerçek tork u değil, K_m·i.
     - Örnek kayıt `olcum_4b_ornek.mat` (chirp, mod 3). 4.3'ün tanılama algoritması bu biçimdeki veriyi okuyacak.
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
