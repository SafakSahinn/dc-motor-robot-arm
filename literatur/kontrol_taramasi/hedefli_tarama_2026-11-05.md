# Hedefli tarama: kontrol ve kestirim yönü (5 Kasım 2026)

**Amaç:** Çalışmanın ağırlığını analizden (salınım sınırını öngörmek) tasarıma (salınımı önleyen kontrolcü ve kestirici) kaydırmak. Bu yönde literatür açığı kalıyor mu, onu kontrol etmek.

**Yöntem ve sınırları:** OpenAlex ve Semantic Scholar o gün anonim aramayı sınırladı (429 hatası, sıfır sonuç). Tarayıcı eklentisi bağlı olmadığı için IEEE Xplore'a kurum girişiyle girilemedi. Bu yüzden web araması (9 sorgu) ve Crossref meta verisi kullanıldı. Yeni makalelerin hiçbirinin tam metni okunmadı, yargılar özetlere ve arama özetlerine dayanıyor. Sistematik IEEE taraması hâlâ yapılmalı.

Betikler bu klasörde: `oa.ps1` (OpenAlex), `s2.ps1` (Semantic Scholar).

## Önerilen üç bileşen

1. Açıya göre planlanan kontrolcü ve gözlemci: kazanç ve gözlemci bant genişliği, yerçekimi ön yükünün açıya bağlı değerine göre ayarlanır. Ayar tablosu tanımlama fonksiyonu (DF) haritasından gelir.
2. Ek sensör olmadan boşluk ve salınım kestirimi: yalnız motor akımı ve enkoder kullanılır.
3. ESP32 üzerinde gömülü gerçekleme.

## Bulgular

### Bileşen 1: doğrudan rakip bulunamadı

| Kaynak | Ne yapıyor | Bizden farkı |
|---|---|---|
| Zhang, Wang, Bailey, Keogh 2023, *Int. J. Computer Integrated Manufacturing* 36(3), DOI 10.1080/0951192X.2022.2090609 | Endüstriyel robotta yön değişiminde ileri beslemeli boşluk ve yapışma telafisi. Boşluk ikinci eklemde duruşa bağlı. Duruşa göre planlanan telafi öneriliyor. | Açık çevrim konum telafisi. Limit cycle, kapalı çevrim kararlılığı ve kazanç planlaması yok. **Tam metni okunmalı:** duruşa bağlılığı yerçekimine bağlıyor mu? |
| ESO tabanlı sürtünme telafisi ve düşük hızda limit cycle bastırma, IFAC-PapersOnLine 2020, DOI 10.1016/j.ifacol.2020.12.1863 | DF analizi: gözlemci bant genişliği arttıkça salınımı bastırmak için gereken hız kazancı da artıyor. Telafiyi yalnız gerektiğinde açan bir anahtarlama kuralı var. | Sürtünme var, boşluk ve yerçekimi yok. Bant genişliği ile kazanç arasındaki bağı DF ile kuran yöntem bizim tasarım yöntemimize çok yakın. **Okunmalı ve anılmalı.** |
| Wang ve ark. 2024, *Nonlinear Dynamics* (zaten okundu) | NESO ile boşluk telafisi, salınım bastırma | Yerçekimi yok, tek çalışma noktası |
| G. Sun 2021 IET, Padron 2022 BDDOb, 2022_9959378, Sun 2025 TAES, Yu–Tang 2024 LADOB (zaten okundu) | Kazanç veya gözlemci o anki hata, tork ya da salınıma göre değişiyor | Tepkisel çalışıyor, açıya ve yerçekimine göre önceden ayar yok |
| Sun 2023 TIE (zaten okundu) | Düşey kolda ikinci motorla yapay ön yük, MPC ve ESO | İki motor gerekiyor, tek açı. Bizdeki doğal ön yük açıya bağlı. |
| Márton–Lantos 2009, IFAC "Limit cycle existence condition..." (S1474667015370117) | Boşluk ve sürtünme düzleminde salınım sınırı. Parametrelerden bağımsız bir salınımdan kaçınma koşulu. | Yerçekimi yok. Kaçınma koşulu tasarım kuralı olarak anılabilir. |
| 2R manipülatörde gecikmeli geri beslemeyle salınım bastırma (ResearchGate kaydı, ayrıntısı doğrulanmadı) | DF ile analiz ve kontrolcü tasarımı | Yerçekimi ve açıya bağlılık belirtilmemiş. **Künyesi bulunmalı.** |
| Analysis and Suppression of Limit Cycle Oscillation for Transmission System With Backlash Nonlinearity (2017, ResearchGate) | Boşluk genişliği frekansı değiştirmiyor, genliği artırıyor. Kontrol sertliği ikisini de artırıyor. | Yerçekimi yok |
| TU/e tezi "Limit cycling in controlled mechanical systems" | Genel çerçeve | Arka plan kaynağı |

**Sonuç:** "Yerçekimi ön yükünün açıya bağlı değerine göre, DF haritasından önceden ayarlanan kazanç ve gözlemci bant genişliği" ile limit cycle'ı önleyen bir çalışma bulunamadı. Açık duruyor. En büyük risk Zhang 2023: duruşa göre planlama fikri orada var, ama ileri beslemeli konum telafisi olarak.

### Bileşen 2: çok öncül var, tek başına yeni değil

| Kaynak | İçerik |
|---|---|
| Lagerberg–Egardt 2007, IEEE TCST (ECC 2003 sürümü, 2004 Chalmers tezi) | Kalman tabanlı boşluk boyutu ve boşluk içi konum kestirimi, standart hız sensörleriyle, gerçek araçta |
| "Backlash phenomenon observation and identification in electromechanical system" (ResearchGate 257427079, büyük olasılıkla Ruderman grubu) | Kayan kipli türev alıcıyla yalnız motor tarafı ölçümünden boşluk kestirimi |
| Lehmann ve ark. 2013, IFAC MIM, DOI 10.3182/20130619-3-RU-3018.00226 (40 atıf) | Kenetleme yöntemi: robot ortama kenetlenip iç sensörlerle boşluk ve sertlik ölçülüyor (ABB ve KUKA) |
| Elektrikli araç anti-jerk 2026, Springer IJCAS, DOI 10.1007/s12555-026-00074-x | Tam gözlemci gerekmiyor, yalnız boşluğa giriş anı tespit ediliyor |
| Ford tipi patent US8447491 | Temas yokken gözlemlenebilirlik kayboluyor, durum benzetimle sürdürülmeli |
| Ruderman 2018, Giovannitti 2022, D-Arm 2023, Villwock–Pacas 2009 (zaten biliniyordu) | Röle, yerçekimi sıfır geçişi ya da motor torku eşiğiyle boşluk tanılama |

Yuki 2012 IECON bulunamadı. Künye doğrulanmalı.

**Sonuç:** Boşluk kestirimi ve tanılama yeni değil. Bileşen 2 ancak destekleyici bir parça olarak kalabilir: yerçekimi ve açı bilgisini de kullanan, salınımın başladığını erken yakalayan ve Bileşen 1'deki planlamayı (gerekirse güvenli moda geçişi) besleyen bir tespit katmanı. Gözlemlenebilirlik kaybı (temas yokken) ve giriş anı tespiti (2026) en yakın öncüller.

### Bileşen 3

Katkı değil, uygulama bölümü. Anılacaklar: Horng 2006 (nicemleme kaynaklı limit cycle), Kim 2009 (ayrık gerçekleme).

## Kurtarma kararı (öneri)

Kurtarma mümkün. Yeni çerçeve:

> **Ana katkı:** Yerçekimi etkisindeki dişli boşluklu eklemde, kontrolcü kazancının ve gözlemci bant genişliğinin yerçekimi açısına göre önceden planlanması. Planlama kuralı, yerçekimini hesaba katan DF analizinden ve dijital ikizden türetilir. Hedef, salınıma girmeden açıdan bağımsız en yüksek başarımı elde etmek.
> **Destekleyici katkı:** Yalnız motor tarafı sinyalleriyle salınımın başladığını tespit edip planlamayı düzelten bir katman.
> **Uygulama:** ESP32 üzerinde 1 kHz'te çalışan gerçekleme ve açı taramalı deney.

Önceki işler yeni çerçevede şöyle kullanılır: DF ve limit cycle haritası tasarım tablosu olur. Dijital ikiz ve tanılama sonuçları denetleyici tasarımının modeli olur. Deney protokolü (D0–D6) aynen kalır, D6'ya planlamalı ve planlamasız karşılaştırması eklenir.

## 2. tur: IEEE Xplore ve tam metin (aynı gün, tarayıcı bağlandıktan sonra)

### IEEE Xplore sorguları (13 sorgu, `/rest/search`, kurum girişi gerekmedi)

| Sorgu (All Metadata) | Kayıt | Konuyla ilgili olanlar |
|---|---|---|
| backlash AND (gain scheduling OR gain-scheduled OR LPV) | 7 | 7893560 (2016): LPV modelle değişken ve bilinmeyen boşluk genişliği, yerçekimi yok. 11616391 (ACC 2026): Fairino FR3 robotta hız ve yüke göre kazanç planlamalı PID. Sürekli hatanın kaynağı eklem esnekliği ve boşluk. Limit cycle ve açıya bağlı yerçekimi yok. Diğerleri araç ve direksiyon. |
| backlash AND gravity AND (limit cycle OR oscillation) | 7 | PA-10 harmonik dişli modelleme (2004, 2005), 5410358 anti-backlash dişlide tork telafisi. Açıya bağlı analiz yok. |
| backlash AND (observer bandwidth OR adaptive/variable bandwidth OR variable gain) | 2 | 9959378 (zaten okundu) |
| backlash AND limit cycle AND (operating point OR position-dependent OR configuration-dependent OR load torque) | 8 | Wang 2017 TIE ve Hu 2017 ITEC (zaten okundu), 8868674 özdeğer tabanlı limit cycle analizi, 9901536 boşluk iptalli MPC, 10256212 tork tipi ters boşluk modeli |
| backlash AND (mode/contact detection OR backlash state OR gap estimation) | 3 | 9966093 (2022) elektrikli aktarma organında boşluk açısı kestirimi, 8172348 düşük maliyetli robotta temas tespiti |
| backlash AND gravity AND (observer OR DOB OR ESO) | 1 | 5410358 |
| backlash AND limit cycle AND describing function AND (design OR tuning) | 5 | Wang 2017 TIE, Sun 2025 TAES (zaten okundu) |
| (gear backlash OR geared) AND gravity AND (single-link OR single joint OR pendulum) | 6 | Ruderman–Iwasaki 2016 TIE (7153537): motor torku ve hızıyla "sanal burulma sensörü" kuruyor, sensörsüz. Diğerleri sarkaç ve dengeleme robotu. |
| backlash AND preload AND (gravity OR load torque) | 3 | 10363063 (2023): çift motorla elektriksel ön yük, frezeleme robotu |
| backlash AND limit cycle AND (detection OR monitoring) | 7 | 5354660 (2009, 14 atıf): takım tezgâhında titreşim ve limit cycle tespiti ile boşluk bastırma |
| (DOB OR ESO) AND (gain scheduling OR bandwidth scheduling) AND (robot OR manipulator OR joint) | 9 | 9229519 VSA'da kazanç planlamalı GESO (boşluk yok), 11646850 uyarlamalı bant genişlikli ESO (hava-su robotu). Boşluk yok. |
| backlash AND manipulator AND (gravity compensation OR gravitational torque) | 4 | PA-10, eksoskeleton PID. Analiz yok. |
| (backlash OR dead zone) AND (angle/posture/pose/position-dependent) | 6 | 972619 (2000) konuma göre değişen kayıp hareket telafisi (CNC), 10591213 (2024) kremayer dişlide duruma bağlı aktarım hatasının öğrenilmesi. İkisi de ileri beslemeli konum düzeltmesi, salınım yok. |

**Sonuç:** IEEE'de de doğrudan rakip çıkmadı. Kazanç planlama ya da bant genişliği planlaması ile boşluk ve yerçekimini birleştiren kayıt yok.

### Zhang ve ark. 2023 (IJCIM): TAM METİN OKUNDU, risk değil

- KUKA KR120 robotu, lazer izleyici, düşük hız (1,5–10 mm/s).
- Yaklaşım tamamen **açık çevrim ileri beslemeli yörünge değişikliği**. Kendi ifadeleriyle, yavaş harekette dinamik tepki ihmal edilebildiği için boşluğa bağlı kararsızlık daha az önemli. Açık çevrimin kararsızlaştırıcı etkisi olmadığını da yazıyorlar. **Limit cycle, kapalı çevrim kararlılığı ve kazanç ayarı YOK.**
- "Planlama": boşluk telafi sabiti d_b, gerekirse eklem açısının fonksiyonu yapılabilir diyorlar ama yapmıyorlar. A2 ekleminde boşluk açıyla 0,0022° ile 0,0050° arasında değişiyor, nedenini "dişli kutusu kusurları ve ön yük değişimi" diye veriyorlar.
- **Motivasyon için faydalı alıntı:** girişte "boşluğun yaygın çözümü ön yüklemedir; endüstriyel robotlarda bu, kol ve yük ağırlığıyla doğal olarak vardır" diyorlar. Bu, açıya bağlı doğal ön yük fikrimizin bilinen bir statik gözlem olduğunu ama kapalı çevrimde incelenmediğini destekliyor. Sonuçta da gelecek iş olarak "eklem yüklenmesini hesaba katmak" öneriliyor.
- Makalede **Weigand–Gafur–Ruskowski 2021 RCIM** (ikincil enkoderlerle düzlük tabanlı eklem kontrolü, boşluk ve sürtünme) anılıyor. Okunacaklar listesine eklendi.

### Tam metni okunamayanlar

- IFAC 2020 ESO ve limit cycle (10.1016/j.ifacol.2020.12.1863): ScienceDirect bot doğrulaması çıkardı, aşılmadı. Sürtünmeyle ilgili olduğu için yenilik riski değil, yöntem kaynağı. Tarayıcıda elle açılınca okunabilir.
  - **Tam metin okundu (5 Kasım, OpenAthens + açık erişim PDF, ayrıntı `okuma_notlari.md`) → RİSK DEĞİL, yöntem kaynağı.** Piao, Wang, Sun, Chen; s. 1313–1318. BLDC + redüktör, yalnız konum ölçümü, RESO. DF (Coulomb + Stribeck) ile LC'siz kritik (ω_o, k_d) tablosu: ω_o 10→100 için k_d 0,36→0,85. Anahtarlama kuralı hataya (histerezis 0,02/0,03°) ve komut hızına (v_δ = 0,01 °/s, deneysel) bağlı, tepkisel. Boşluk, yerçekimi, açıya göre planlama yok; ω_o sabit. Dikkat: DF'ye göre LC olmaması gereken ayarda deneyde LC çıkmış (statik sürtünme ihmali) → DF sınırına dijital ikizle doğrulama ve pay gerekiyor.

## 3. tur: Web of Science Core Collection (aynı gün)

İstinye Microsoft SSO hesabıyla girildi (oturum zaten açıktı, şifre girilmedi). Gelişmiş arama `#advancedSearchInputArea` alanına JS ile yazılıp Search düğmesine basıldı. Sonuç listesi sanal; ilk 8 kayıt görünür, gerisi kaydırınca yükleniyor.

| Sorgu | Kayıt | İlgili olanlar |
|---|---|---|
| TS=(backlash AND ("gain schedul*" OR LPV OR "linear parameter varying")) | 9 | IEEE ile aynı (araç direksiyonu, haptik, 2016 LPV iki kütle). Yeni rakip yok. |
| TS=(backlash AND gravit* AND ("limit cycle*" OR oscillat*)) | 2 | Düz dişli dinamiği, makro/mikro manipülatör görsel servo. Rakip yok. |
| TS=(backlash AND (observer/adaptive/variable bandwidth OR bandwidth schedul* OR variable gain OR gain adapt*) AND (limit cycle* OR oscillat* OR servo*)) | 1 | G. Sun 2021 IET (zaten okundu) |
| TS=((backlash OR dead zone) AND (angle/pose/posture/position/configuration-dependent) AND (control* OR observer*)) | 12 | **Li ve ark. 2026, *Mechatronics* 118** (aşağıda). **Dai ve ark. 2026, *MSSP* 258** (aşağıda). Weigand 2021 RCIM, cobot eklem tanılama, kremayer 2024 (biliniyor). |
| TS=(backlash AND gravit* AND (observer* OR DOB OR ESO OR "extended state" OR schedul* OR adaptive)) | 3 | Takım tezgâhı tablası, iki eksenli tarayıcı. Rakip yok. |
| TS=(backlash AND "limit cycle*" AND (detect* OR monitor* OR motor-side OR sensorless OR estimat*)) | 17 | **Di Rito ve ark. 2018 MetroAeroSpace**: uçuş eyleyicisinde limit cycle genliği ve frekansından boşluk kestirimi (sağlık izleme). Perumal–Selvaganesan 2019 *Trans. Inst. Meas. Control*: girişe bağlı Nyquist ile limit cycle öngörüsü, kesirli dereceli kontrolcüyle bastırma (yerçekimi yok). Diğerleri tanılama ve sürtünme. |

### Yeni yakın çalışmalar (yalnız özet okundu)

- **Li, Xie, ..., He 2026, *Mechatronics* 118 — "Dynamic dead-zone modeling and backlash compensation for rotary servo actuators based on PSO-BP neural network".** Boşluk genişliğinin **yük torkuna ve açısal konuma bağlı** olduğunu veriyle (sinir ağı) modelliyor. Asimetrik dinamik ölü bölge modeli, üzerine zaman-optimal kayan kipli telafi var. Amaç hız takibi; sinüs takibinde hız hatası %28–45 azalıyor. **Limit cycle, kararlılık sınırı, kazanç ya da gözlemci planlaması yok.** Yerçekimi açıkça geçmiyor. Bizim için anlamı: "açıya ve yüke bağlı boşluk" gözlemi 2026'da yayımlanmış. Katkımızı "boşluk açıya bağlıdır" iddiasına değil, **kapalı çevrim salınım sınırının ve kontrolcü planlamasının** açıya bağlı yerçekimi ön yükünden türetilmesine dayandırmalıyız. **Anılmalı.**
  - **Tam metin okundu (5 Kasım, ayrıntı `okuma_notlari.md`) → RİSK DEĞİL.** DOI 10.1016/j.mechatronics.2026.103535. Açı bağımlılığı RV redüktör geometrisinden (periyodik), yerçekiminden değil; yük, elektrikli yük simülatöründen (DD motor + tork sensörü), eyleyici düşey yük taşımıyor. Kazançlar sabit (SMC p=0,1, ε=5; PI K_p=16,09, K_i=505,38), açıya göre kazanç/gözlemci planlaması yok. Kararlılık yalnız kayma yüzeyi Lyapunov'u, limit cycle ya da salınım sınırı analizi yok. Yalnız hız takibi (sinüs), sabit hedef deneyi yok. Kaynakçada yakın yeni çalışma yok; kontrol edilecek tek aday Ahangarian Abhari ve ark. 2019 TIMC (robot kolunda bilinmeyen boşluk).
- **Dai, Wan, ..., Zhou 2026, *MSSP* 258 — "A two-layered control for backlash compensation and oscillation suppression in ball screw drives".** Boşluk geçişini üç evreye ayırıyor. Yön değişiminden sonraki **motor tarafı konum artışlarıyla evreyi öngörüyor**. Tork kaybı için ileri besleme, salınım için ESO tabanlı sönüm katmanı var. Vidalı mil, yön değişimi, yerçekimi yok. 2. bileşen (motor tarafı tespit) için güncel ve güçlü bir öncül. **Anılmalı.**
  - **Tam metin okundu (5 Kasım, ayrıntı `okuma_notlari.md`) → RİSK DEĞİL, öncül olarak anılacak.** DOI 10.1016/j.ymssp.2026.114675. Evre "tespiti" aslında yön değişiminden sonra motor tarafı artışlarının tümlenip **önceden bilinen** boşluk sınırlarında doyurulması; sınırlar lazer interferometreyle ölçülüp BP ağıyla haritalanmış. Yük tarafı lineer enkoder (tam kapalı çevrim + hız farkı sönümü) kullanılıyor. ESO kazancı ve K_d sabit, yatay X–Y eksenleri, yerçekimi yok, konum bağımlılığı vida aşınmasından. Sabit hedefte LC başlangıç tespiti ve DF/LC analizi yok. Kaynakçadaki temas tespiti işleri (Reddy 2021/2023, Yonezawa 2024/2025) araç aktarma organı, yön değişimi odaklı.
- **Di Rito 2018:** limit cycle'dan boşluk kestirimi. Ruderman 2018 ailesine eklenir.

## Kurtarma kararı (güncel)

Kontrol ve kestirim çerçevesinde **ana katkı açık**: yerçekiminin açıya bağlı ön yüküne göre kontrolcü kazancını ve gözlemci bant genişliğini önceden planlayıp limit cycle'ı önlemek. Bunu yapan bir kayıt bulunamadı: IEEE 13 sorgu, web 9 sorgu, Zhang 2023 tam metin. En yakın işler ya tepkisel (G. Sun 2021, Padron 2022, Sun 2025), ya ileri beslemeli konum telafisi (Zhang 2023, 972619, 10591213), ya da yerçekimsiz LPV ve kazanç planlaması (7893560, 11616391, 9229519).

## Açık işler

1. Tarayıcı bağlanınca IEEE Xplore'da sistematik sorgular: backlash + (gain scheduling OR LPV OR scheduled OR "operating point") + (gravity OR "vertical" OR "load torque"); "observer bandwidth" + backlash + "limit cycle"; backlash + "mode detection" / "contact detection".
2. Tam metin okunacaklar: Zhang 2023 IJCIM (en kritik), IFAC 2020 ESO limit cycle, Lagerberg–Egardt 2007, Ruderman kayan kip, EV anti-jerk 2026, 2R gecikmeli geri besleme.
3. OpenAlex sınırı kalkınca ileriye atıf taraması: Zhang 2023 ve IFAC 2020'ye atıf yapanlar.
