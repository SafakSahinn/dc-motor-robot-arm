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

## Açık işler

1. Tarayıcı bağlanınca IEEE Xplore'da sistematik sorgular: backlash + (gain scheduling OR LPV OR scheduled OR "operating point") + (gravity OR "vertical" OR "load torque"); "observer bandwidth" + backlash + "limit cycle"; backlash + "mode detection" / "contact detection".
2. Tam metin okunacaklar: Zhang 2023 IJCIM (en kritik), IFAC 2020 ESO limit cycle, Lagerberg–Egardt 2007, Ruderman kayan kip, EV anti-jerk 2026, 2R gecikmeli geri besleme.
3. OpenAlex sınırı kalkınca ileriye atıf taraması: Zhang 2023 ve IFAC 2020'ye atıf yapanlar.
