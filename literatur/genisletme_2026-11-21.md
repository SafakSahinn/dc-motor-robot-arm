# Literatür genişletme, 21 Kasım 2026

İki soru:
1. Neubauer 2015'in açığını (tork sıfırken boşluk yüzü tanımsız) yazarlar ya da başkaları 2015'ten bu yana kapatmış mı?
2. Hocanın önerisi (yaylı ikinci dişliyle mekanik ön yük) kestirimi gereksiz kılar mı? Ön yükün sınırları ne?

Kaynak durumu işaretleri: **TM** = tam metin okundu, **Ö** = yalnız özet, **B** = yalnız başlık veya bibliyografik kayıt.

---

## Soru 1. Neubauer 2015'in açığı kapatılmış mı?

### 1.1 Makalenin kendisi (TM, yeniden okundu)

Neubauer, Gattringer, Müller, Steinhauser, Höbarth, "A two-stage calibration method for industrial robots with joint and drive flexibilities", *Mech. Sci.* 6:191–201, 2015, DOI 10.5194/ms-6-191-2015.

- Boşluk modeli, denklem (18): `R = R|_{φ = q + sign(M)·p_BL}`, burada `sign(0) = 0`. Gerekçe (s. 195): *"gear backlash is not a geometric error and depend on the pose of the robot. In order to identify the direction in which the clearance is present, the center of mass of each body must be considered. To avoid the evaluation of the body dynamics the decision is based on the sign of the motor torque M in each axis."*
- **Gelecek çalışma cümlesi (Sonuç, aynen):** *"The calculation of optimal poses for the elasticity parameter identification is part of future work."* Gelecek çalışma olarak yalnız esneklik tanılaması için en uygun duruşların seçimi anılıyor. Sıfır tork durumundan ya da boşluk yönünden söz eden bir gelecek çalışma cümlesi yok.
- Sonuç: sıfır tork durumu makalede açık bir problem olarak bile tanımlanmamış. `sign(0) = 0` yalnız matematiksel bir uzlaşım. Kalibrasyonda bu duruşlardan kaçınılabildiği için yazarlar bu durumu ele alma gereği duymamış.

### 1.2 İleri atıf taraması

OpenAlex `cites:W1779531569` ile 28 kayıt, Semantic Scholar ile 21 kayıt. Birleşimleri yaklaşık 29 çalışma. Hepsine başlık düzeyinde bakıldı, boşlukla ilgili olanların özetleri okundu.

| Çalışma | Durum | Boşluk yüzüne ne yapıyor | Bizimle ilişkisi |
|---|---|---|---|
| Yao, Yang, Ju, Zhou 2026 *IEEE Access* 14:2236 (10.1109/ACCESS.2025.3643729) | TM (önceden) | Yön = hedefe varmadan önceki eklem hızının işareti | Rakip değil, ikinci kaba kural (yaklaşma yönü). Yerçekimi yok |
| Yao, Zhou, Huang, Xu 2025 RICAI (10.1109/RICAI68060.2025.11385015) | Ö | Aynı kural, aynı sonuçlar (%47,97 / %53,44); 2026 makalesinin konferans hâli | Rakip değil |
| Gattringer, Neubauer, Kaserer, Müller 2017 *Mech. Mach. Sci.* (RAAD) (10.1007/978-3-319-61276-8_23) | B (S2 TLDR) | 30 parametreli kalibrasyon, parametreler arasında "gear backlash" da var | **Açık nokta:** yüz kuralını değiştirip değiştirmediği bilinmiyor, tam metin gerekli (Springer, kurum erişimi) |
| Klose, Wahrburg 2022 AMC (10.1109/AMC51637.2022.9729322) | Ö | Dişli çıkışında konum ve tork sensörü kullanıyor | Kola sensör koyuyor, rakip değil |
| Reyhani, Marko, Janisch, Kugi 2024 *Mechatronics* (10.1016/j.mechatronics.2024.103140) | Ö | Esnek eklemli robotta gerçek zamanlı gözlemci karşılaştırması. Boşluk yok | Gözlemci literatürü için referans |
| Gnad, Gattringer, Müller 2025 *ASME Lett. Transl. Robot.* (10.1115/1.4067689) | Ö | Delta robotta frekans alanında esneklik tanılama. Hareket düzeltmesinde "preloading of drives" seçeneği var | Soru 2 için ilginç, tam metin gerekli |
| Diğer ≈ 22 çalışma (kalibrasyon incelemeleri, frezeleme robotları, kobot kalibrasyonu, UR5 hasar sonrası doğrulama vb.) | B/Ö | Boşluk yüzü ele alınmıyor | İlgisiz |

### 1.3 Yazar takibi (OpenAlex, 2015 sonrası)

- **Neubauer** (OpenAlex A5023648513): 2017'den sonra robotik yayını yok. Ulaşım, lojistik ve C-ITS alanına geçmiş (FH Oberösterreich).
- **Steinhauser** (A5008780244): 2016–2020 arasında öğrenen kontrol (ILC) ve zamanda en iyi yörünge çalışmış (KU Leuven / Flanders Make). Boşlukla ilgili yayını yok.
- **Gattringer ve Müller** (JKU Linz): 24 çalışma 13 terimle tarandı (backlash, clearance, load reversal, zero torque, preload, lost motion vb.). "Backlash" geçen yalnız iki çalışma var:
  - Gattringer 2017 (yukarıda).
  - Ziegler, Rameder, Gattringer, Müller 2023 *Mech. Mach. Sci.* (10.1007/978-3-031-32606-6_28, arXiv 2510.25335, **TM**): Alt beden dış iskeletinde boşluk (±0,5°) "şeffaf mod" için kullanılıyor. Motor açısı ile **dişli çıkışındaki mutlak enkoder** açısının farkı sanal bir yayla torka çevriliyor: `τ = K_T (q_j − q_M,j)`. Kol tarafında sensör olduğu için rakip değil. İlginç bir ayrıntı: boşluğun yüzünü bilmek yerine boşluğun kendisini bir algılayıcı gibi kullanıyorlar.
- Sonuç: ekip boşluk yüzü problemine geri dönmemiş.

### 1.4 Hedefli sorgular

OpenAlex (`title_and_abstract.search`, 2015 sonrası) ve Semantic Scholar (gevşek arama) ile 20'den fazla sorgu yapıldı. Semantic Scholar'ın hız sınırı nedeniyle birkaç sorgu çalışmadı. Bunlar OpenAlex'te kısa anahtar kelimelerle yeniden denendi.

Sorgular: backlash zero torque (crossing), backlash contact side / contact estimation, backlash load reversal gravity, backlash direction gravity torque robot joint, backlash state estimation motor current, backlash inverted pendulum, backlash upright, backlash mode estimation, backlash engagement observer, backlash gravity robot, backlash sensorless robot, lost motion gravity, backlash unstable equilibrium.

En yakın yeni bulgular:

| Çalışma | Durum | Ne yapıyor | Bizden farkı |
|---|---|---|---|
| **Ruderman, Fridman 2019 *IEEE TCST*** "Model-free sliding-mode-based detection and estimation of backlash in drives with single encoder" (10.1109/TCST.2019.2956914) | Ö | **Yalnız eyleyici tarafındaki enkoderle** kayan kipli türevleyici kullanıyor. Farklı boşluk kiplerinin (temas / serbest) farklı bozucu dinamiği var. Çarpma anında sınırsız, dürtü biçiminde bir bozucu oluşuyor. Bu, kayan kipin kısa süreliğine kaybolmasına yol açıyor, yani **çarpmanın gerçekleştiği an saptanabiliyor**. Boşluk büyüklüğü kestiriliyor. İki ataletli düzenekte deney var | Motor tarafından **kip geçişi / çarpma anı** sezmek yapılmış. Ancak yerçekimi yok, kolun **hangi yüzde durduğu** (özellikle dururken, tork sıfırken) kestirilmiyor, hedef boşluk büyüklüğü. Rapordaki 3. gruba (motor sinyaliyle ölçenler) eklenmeli. **Tam metin okunmalı** (IEEE, kurum erişimi) |
| Papageorgiou, Blanke, Niemann, Richter 2017 IFAC (10.1016/j.ifacol.2017.08.621) | Ö | Kayan kipli gözlemci ile uyarlamalı kestirici, ölü bölge genişliği | Boyut kestirimi, yüz yok. Notlarımızda kaynakça olarak geçiyordu |
| Ruderman, Iwasaki 2015 ICM (10.1109/ICMECH.2015.7084054) | Ö | Sensörsüz burulma kontrolünde histerezisli kayıp hareket. İki uç durum karşılaştırılıyor: en büyük kalıcı yük ve yerçekiminden gelen yük | Yerçekimi var, ama yüz kestirimi yok. Ruderman 2016 TIE'nin öncülü |
| Reddy ve ark. 2022 *IEEE TMECH* (10.1109/TMECH.2021.3137461) | Ö | Taşıt aktarma organında Kalman ile boşluk **büyüklüğü** (CAN hız ve tork) | Boyut kestirimi, tekerlek hızı yük tarafı ölçüsü |
| Heinz, Reichenbacher, Nelles 2022 CCTA (10.1109/CCTA49430.2022.9966093) | Ö | Anahtarlamalı Kalman ile anlık boşluk açısı ve temas anı (4 ms doğruluk) | Motor **ve tekerlek** hızı kullanılıyor, yani yük tarafı ölçüsü var |
| Capito ve ark. 2023 SAE (10.4271/2023-01-0454) | Ö | Taşıtta tork sıfırdan geçerken tork değişim hızını boşluk bölgesinde düşürüyor | "Sıfır geçişinde boşluk" mühendislik pratiği. Kestirim yok, yüzün nerede olduğu tork işaretinden varsayılıyor |
| Awan, Khan 2024 *Eng. Proc.* (10.3390/engproc2024075032) | Ö | Ters sarkaçta iki motorlu (drive–anti drive) boşluk giderme, yalnız benzetim | Soru 2 için çift motor örneği |

### 1.5 Soru 1 sonucu

- **Kapatılmamış.** Neubauer ekibi konuya dönmemiş, sonradan atıf yapan çalışmalar da açığı kapatmamış. Literatürde boşluk yüzü için hâlâ iki kaba kural var: tork işareti (Neubauer 2015) ve yaklaşma yönü (Yao 2025/2026). İkisi de tork sıfırken ve kol devrilebilir durumdayken (180°) belirsiz kalıyor.
- **Kısmen yakın tek çizgi:** Ruderman–Fridman 2019. Bu çalışma yalnız motor tarafındaki ölçüyle **çarpma / kip geçişi anını** saptıyor. Bizim yöntem de dolaylı olarak bir geçişe dayanıyor (küçük itiş sonrası temas). Bu yüzden ilişki rapora açıkça yazılmalı: onlar "geçiş ne zaman oldu ve boşluk ne kadar büyük" sorusunu cevaplıyor, biz "kol şu an hangi yüzde, yerçekimi bunu belirlemiyorken" sorusunu cevaplıyoruz.
- **Açık kalan iki kontrol** (tam metin gerekiyor, ikisi de kurum erişimiyle okunabilir):
  1. Gattringer ve ark. 2017 RAAD: boşluk yüzü kuralı yine `sign(M)` mi?
  2. Ruderman–Fridman 2019 TCST: dururken ya da sıfır torkta yüz bilgisi çıkarıyorlar mı?
- Rapordaki "doğrudan rakip yok" iddiası (rapor 1.3 ve yaklaşık satır 380) şimdilik geçerli. Ruderman–Fridman 2019 3. gruba eklenmeli.

---

## Soru 2. Mekanik ön yük (hocanın yaylı ikinci dişlisi)

### 2.1 Bulunan kaynaklar

| Çalışma | Durum | Bulgu |
|---|---|---|
| **Steinle, Leipe, Lechler, Verl 2025 *Prod. Eng.* 19:419–427** (10.1007/s11740-024-01318-7, açık erişim) | **TM** | Kremayer–pinyonda **elektriksel ön yük** (iki motor). Endüstride ön yük devreye almada anma torkunun %10–30'u olarak sabit seçiliyor ve kalıcı bırakılıyor. Sürekli ön yük *"leads to significant energy consumption, increased friction and wear of the mechanics"*. Alt sınır `τ_p > τ_fr,s` koşulu (iki tahrik zincirinde aynı anda boşluk oluşmasını önler, kaynak Verl–Engelberth 2018). Üst sınır motorların sürekli torku. Ön yük yükseldikçe sertlik ve doğal frekans artıyor, sönüm azalıyor. **Yöntem:** ön yük torku `τ_p,a = K_a·|d e_x/dt|`, kayan ortalama filtreden geçiriliyor ve sınırlanıyor. **Sonuç:** benzer doğrulukta, en yüksek ön yüke göre ortalama **%77 daha az ön yük torku**. Dururken ön yük düşüyor |
| Verl, Engelberth 2018 *CIRP Annals* 67(1):369 (10.1016/j.cirp.2018.03.006) | B | "Adaptive preloading for rack-and-pinion drive systems". En küçük ön yük koşulu. Okunmalı |
| Engelberth ve ark. 2015 *Prod. Eng.* 9(2):269 (10.1007/s11740-015-0601-3) | B | Elektriksel ön yüklü kremayer tahriklerinin özellikleri |
| Du, Yang, Wang, Chen, Fang 2025 *Actuators* 14(4):173 (10.3390/act14040173) | Ö (MDPI erişimi engelledi) | Ön yüklü esnek taşıyıcılı boşluksuz 3K planet redüktör. **Ön yük arttıkça hem ileri hem geri verim düşüyor**, yük torku arttıkça artıyor. Ön yük en çok güneş–planet kavramasını etkiliyor. Dört prototipte model hatası %2,3 / %4,0 |
| Du, Zhang, Yang, Chen, Wang 2023 *Mech. Mach. Theory* (10.1016/j.mechmachtheory.2023.105495) | B | Kobotlar için esnek, boşluk gideren taşıyıcılı 3K planet dişli |
| Du, Wang, Tu, Chen, Lu 2025 ICIEA (10.1109/ICIEA65512.2025.11148910) | Ö | Çift motor ve çift taşıyıcıyla bileşik planet redüktör. İki motorun bias torku dişleri karşı yüzlere yaslıyor, ağır yükte bile boşluk gideriliyor (benzetim) |
| Li, Yang, Teng, Cui, Chen 2024 ICRCA (10.1109/ICRCA60878.2024.10649134) | Ö | Taşlama robotu ekleminde **ek bir dişli çiftiyle** boşluk giderme, sonlu elemanlarla analiz. Boşluk temas basıncını az, gerilmeyi çok etkiliyor. Hocanın önerisinin endüstrideki bir örneği |
| Kaiser, Schäfer, Schütz, Parspour, Lechler 2024 SPEEDAM (10.1109/SPEEDAM61530.2024.10609128) | Ö | Çift motorlu, **elektriksel ön yüklü** robot eklemi için toplu parametreli model. Ön yük açıkken ölçümle model arasında kalıcı farklar var |
| Sun, Liang, Fang 2019 *Industrial Robot* (10.1108/IR-06-2018-0124) | Ö | Delme robotunda ön yüklü çift somun ve çift motorla boşluk giderme |
| Su ve ark. 2021 IJCNN (10.1109/IJCNN52387.2021.9534277) | Ö | Fazla eyleyicili paralel robotta iç ön yükün çok amaçlı en iyilenmesi (güç, anahtarlama kaybı) |
| Notlarımızdan: Ghaffari 2013 TMECH, Sun 2023, Xu 2023 RA-L, Karim 2018 | TM (önceden) | Tork ön yükü aştığında kararsızlık (Ghaffari). Anma akımını aşan çift motorlu ön yük (Sun). Servo çatışması (Xu). Dış tork mekanik ön yük gibi davranıyor (Karim) |

### 2.2 Soru 2 için ara değerlendirme (tartışmaya açık)

1. **Hocanın önerisi literatürde iyi bilinen bir yöntem.** Makaslı veya bölünmüş dişli, ek dişli çifti, çift motor, esnek taşıyıcı gibi birçok mekanik ve elektriksel ön yük çözümü var. Kendi başına yeni değil, kestirimimizin de rakibi değil. İki yaklaşım farklı tasarım noktalarında duruyor.
2. **Ön yükün literatürde açıkça yazılı üç bedeli var:** verim kaybı (Du 2025), sürtünme ve aşınma artışı, sürekli enerji tüketimi (Steinle 2025). Ayrıca ön yükün bir tork sınırı var: iletilen tork aşınca boşluk geri geliyor ve sistem kararsızlaşabiliyor (Ghaffari 2013).
3. **Steinle 2025'in mantığı bizim mantığımızla aynı yönde:** ön yükü yalnız gerektiğinde uygulamak. Onlar bunu iki motor ve yük tarafı ölçüsüyle (doğrusal ölçek) yapıyor. Bizim tek motorlu sistemimizde yerçekimi zaten "bedava" bir ön yük. Yalnız 180° civarında bu ön yük kayboluyor, sorun da tam orada başlıyor.
4. **Bu sorunun cevabı tezi güçlendirebilir:** "Mekanik ön yük sorunu ortadan kaldırır, ama bedelli. Ön yükü sürekli yüksek tutmak yerine, yerçekiminin yetmediği yerde ve gerektiği kadar uygulamak için kolun hangi yüzde olduğunu bilmek gerekir. Mekanik ön yük olan sistemde de aynı kestirim ön yükün hâlâ çalışıp çalışmadığını izler."
5. Yay ön yükünü açıya göre boyutlandırma ve ön yük kaybını yalnız motor sinyalleriyle sezme konusunda doğrudan bir kaynak bulunamadı. Bu da olası bir katkı alanı.

### 2.3 Eksik kalanlar

- **Patent taraması yapılmadı.** Anti-backlash gear, scissor gear ve spring preload konularında patent çok. Google Patents ya da Espacenet, Chrome üzerinden taranacak.
- Kurum erişimiyle okunacak tam metinler: Verl–Engelberth 2018 CIRP, Du 2025 *Actuators* (MDPI), Gnad 2025 ASME, Li 2024 ICRCA.
