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
| **Ruderman, Fridman 2019 *IEEE TCST*** 28(2):812–818, "Model-free sliding-mode-based detection and estimation of backlash in drives with single encoder" (10.1109/TCST.2019.2956914, arnumber 8935531) | **TM** (aşağıda 1.4a) | **Yalnız eyleyici tarafındaki enkoderle** kayan kipli türevleyici kullanıyor. Farklı boşluk kiplerinin (temas / serbest) farklı bozucu dinamiği var. Çarpma anında sınırsız, dürtü biçiminde bir bozucu oluşuyor. Bu, kayan kipin kısa süreliğine kaybolmasına yol açıyor, yani **çarpmanın gerçekleştiği an saptanabiliyor**. Boşluk büyüklüğü kestiriliyor. İki ataletli düzenekte deney var | Motor tarafından **kip geçişi / çarpma anı** sezmek yapılmış. Ancak yerçekimi yok, kolun **hangi yüzde durduğu** (özellikle dururken, tork sıfırken) kestirilmiyor, hedef boşluk büyüklüğü. Rapordaki 3. gruba (motor sinyaliyle ölçenler) eklenmeli. **Tam metin okunmalı** (IEEE, kurum erişimi) |
| Papageorgiou, Blanke, Niemann, Richter 2017 IFAC (10.1016/j.ifacol.2017.08.621) | Ö | Kayan kipli gözlemci ile uyarlamalı kestirici, ölü bölge genişliği | Boyut kestirimi, yüz yok. Notlarımızda kaynakça olarak geçiyordu |
| Ruderman, Iwasaki 2015 ICM (10.1109/ICMECH.2015.7084054) | Ö | Sensörsüz burulma kontrolünde histerezisli kayıp hareket. İki uç durum karşılaştırılıyor: en büyük kalıcı yük ve yerçekiminden gelen yük | Yerçekimi var, ama yüz kestirimi yok. Ruderman 2016 TIE'nin öncülü |
| Reddy ve ark. 2022 *IEEE TMECH* (10.1109/TMECH.2021.3137461) | Ö | Taşıt aktarma organında Kalman ile boşluk **büyüklüğü** (CAN hız ve tork) | Boyut kestirimi, tekerlek hızı yük tarafı ölçüsü |
| Heinz, Reichenbacher, Nelles 2022 CCTA (10.1109/CCTA49430.2022.9966093) | Ö | Anahtarlamalı Kalman ile anlık boşluk açısı ve temas anı (4 ms doğruluk) | Motor **ve tekerlek** hızı kullanılıyor, yani yük tarafı ölçüsü var |
| Capito ve ark. 2023 SAE (10.4271/2023-01-0454) | Ö | Taşıtta tork sıfırdan geçerken tork değişim hızını boşluk bölgesinde düşürüyor | "Sıfır geçişinde boşluk" mühendislik pratiği. Kestirim yok, yüzün nerede olduğu tork işaretinden varsayılıyor |
| Awan, Khan 2024 *Eng. Proc.* (10.3390/engproc2024075032) | Ö | Ters sarkaçta iki motorlu (drive–anti drive) boşluk giderme, yalnız benzetim | Soru 2 için çift motor örneği |

### 1.4a Ruderman–Fridman 2019, tam metin (İstinye OpenAthens, IEEE)

- Kurulum: iki ataletli sistem, yalnız motor tarafında enkoder, model yok. Yalnız ikinci mertebe eyleyici dinamiği, tork sabiti, sınırlar, sönüm ve atalet varsayılıyor. Kipler: "engagement" (iki yüz temasta), "gap" (boşlukta), "impact" (bir yönlü geçiş).
- Yöntem: ikinci mertebe süper-burulma (STA) türevleyicisi. Bozucu terimin üst sınırı L, temas ve boşluk kiplerini ayıracak biçimde seçiliyor (`U_max K_m + G < L`). Çarpma anında sınırsız, dürtü biçiminde bir bozucu oluşuyor ve kestirim hatası belirgin bir tepe yapıyor. Bu tepelerin zamanları ile motor açısından boşluk büyüklüğü çıkarılıyor.
- **Kestirim adımları S1–S3:** *"Fed the motor with u(t) = U sin(ωt)… sufficient for inducing a periodic motion"*. Yöntem motorun **sürekli, periyodik hareketini** gerektiriyor. Durağan konumda ya da sıfır torkta çalışmıyor.
- Yerçekimi yok. Kolun dururken hangi yüzde olduğu sorulmuyor. Amaç yalnız boşluk **büyüklüğü**.
- Gelecek çalışma (Sonuç, aynen): *"sensitivity analysis of the proposed method, in regard to lower sampling and quantization of the actuator signals and evaluation with other application cases."*
- **Bizim için:** Rakip değil. Rapordaki 3. grupta (motor sinyaliyle ölçenler) anılmalı. Fark tek cümleyle: onlar periyodik uyarımla boşluğun **büyüklüğünü** buluyor, biz dururken ve yerçekimi torku sıfırken kolun **hangi yüzde** olduğunu buluyoruz. Kaynakçasındaki Merzouki–Davila–Fridman–Cadiou 2007 *CEP* (kayan kipli boşluk gözlemi, iki taraf ölçüsü gerekiyor) ve Villwock–Pacas 2009 *TIE* (elektrik tahriklerinde boşluğun zaman alanında saptanması) da 3. gruba eklenebilir.

### 1.4b Gattringer ve ark. 2017 RAAD (tam metin erişilemedi)

- İstinye aboneliği bu Springer kitabını kapsamıyor. Sayfa satın alma gösteriyor, açık kopya yok (OpenAlex: kapalı, depolarda tam metin yok).
- Springer sayfasında okunan tam özet: 30 kalibrasyon parametresi (uzunluk, eksen kayıklığı, **gear backlash**, eklem ofseti). Ek olarak motor ile kol açısı arasındaki esnek sapma da modelde var. Lazer işaretçi ve kamera kullanılıyor, 83 en uygun duruş, Levenberg–Marquardt. Sonuç lazer izleyiciyle benzer doğrulukta.
- Kaynakçasında Neubauer 2015 var. Bu çalışma Neubauer 2015'in boşluk ve esneklik modelini düşük maliyetli ölçümle kullanıyor. Sıfır tork durumunu ele aldığına dair bir işaret yok, ama **tam metin görülmeden kesin değil**.

### 1.5 Soru 1 sonucu

- **Kapatılmamış.** Neubauer ekibi konuya dönmemiş, sonradan atıf yapan çalışmalar da açığı kapatmamış. Literatürde boşluk yüzü için hâlâ iki kaba kural var: tork işareti (Neubauer 2015) ve yaklaşma yönü (Yao 2025/2026). İkisi de tork sıfırken ve kol devrilebilir durumdayken (180°) belirsiz kalıyor.
- **Kısmen yakın tek çizgi:** Ruderman–Fridman 2019. Bu çalışma yalnız motor tarafındaki ölçüyle **çarpma / kip geçişi anını** saptıyor. Bizim yöntem de dolaylı olarak bir geçişe dayanıyor (küçük itiş sonrası temas). Bu yüzden ilişki rapora açıkça yazılmalı: onlar "geçiş ne zaman oldu ve boşluk ne kadar büyük" sorusunu cevaplıyor, biz "kol şu an hangi yüzde, yerçekimi bunu belirlemiyorken" sorusunu cevaplıyoruz.
- **Kontroller (21 Kasım):**
  1. Ruderman–Fridman 2019 TCST: tam metin okundu. Dururken ve sıfır torkta yüz bilgisi **çıkarmıyorlar**: yöntem periyodik sinüs uyarımı gerektiriyor, amaç boşluk büyüklüğü (1.4a).
  2. Gattringer ve ark. 2017 RAAD: tam metne erişilemedi. Özet ve kaynakça Neubauer 2015 çizgisinin devamı olduğunu gösteriyor (1.4b). Tek açık nokta bu, düşük risk.
- Rapordaki "doğrudan rakip yok" iddiası (rapor 1.3 ve yaklaşık satır 380) şimdilik geçerli. Ruderman–Fridman 2019 3. gruba eklenmeli.

---

## Soru 2. Mekanik ön yük (hocanın yaylı ikinci dişlisi)

### 2.1 Bulunan kaynaklar

| Çalışma | Durum | Bulgu |
|---|---|---|
| **Steinle, Leipe, Lechler, Verl 2025 *Prod. Eng.* 19:419–427** (10.1007/s11740-024-01318-7, açık erişim) | **TM** | Kremayer–pinyonda **elektriksel ön yük** (iki motor). Endüstride ön yük devreye almada anma torkunun %10–30'u olarak sabit seçiliyor ve kalıcı bırakılıyor. Sürekli ön yük *"leads to significant energy consumption, increased friction and wear of the mechanics"*. Alt sınır `τ_p > τ_fr,s` koşulu (iki tahrik zincirinde aynı anda boşluk oluşmasını önler, kaynak Verl–Engelberth 2018). Üst sınır motorların sürekli torku. Ön yük yükseldikçe sertlik ve doğal frekans artıyor, sönüm azalıyor. **Yöntem:** ön yük torku `τ_p,a = K_a·|d e_x/dt|`, kayan ortalama filtreden geçiriliyor ve sınırlanıyor. **Sonuç:** benzer doğrulukta, en yüksek ön yüke göre ortalama **%77 daha az ön yük torku**. Dururken ön yük düşüyor |
| **Verl, Engelberth 2018 *CIRP Annals* 67(1):369–372** (10.1016/j.cirp.2018.03.006) | **TM** (aşağıda 2.1a) | Çift motorlu elektriksel ön yükte, ön yükü referans torka göre azaltan karakteristik eğri. En küçük ön yükün gerekçesi sürtünme |
| Engelberth ve ark. 2015 *Prod. Eng.* 9(2):269 (10.1007/s11740-015-0601-3) | B | Elektriksel ön yüklü kremayer tahriklerinin özellikleri |
| Du, Yang, Wang, Chen, Fang 2025 *Actuators* 14(4):173 (10.3390/act14040173) | **TM** (Chrome üzerinden) | Ön yüklü esnek taşıyıcılı boşluksuz 3K planet redüktör. Ön yük, iki komşu planet dişlisini merkez dişlilere sırt sırta yaslayarak boşluğu gideriyor. **Ön yük arttıkça hem ileri hem geri verim düşüyor, "especially under the light-load condition"**. Yük torku arttıkça verim hızla artıyor, çünkü esnek taşıyıcı yükle geri esniyor ve ters kavrama kuvvetleri azalıyor. Ek kayıp ters kavrama kuvvetlerinden geliyor ve en çok güneş–planet çiftinde. En yüksek ön yüklü prototip (D) "hardly practical". Dört prototipte model hatası %2,30 / %4,01 |
| Du, Zhang, Yang, Chen, Wang 2023 *Mech. Mach. Theory* (10.1016/j.mechmachtheory.2023.105495) | B | Kobotlar için esnek, boşluk gideren taşıyıcılı 3K planet dişli |
| Du, Wang, Tu, Chen, Lu 2025 ICIEA (10.1109/ICIEA65512.2025.11148910) | Ö | Çift motor ve çift taşıyıcıyla bileşik planet redüktör. İki motorun bias torku dişleri karşı yüzlere yaslıyor, ağır yükte bile boşluk gideriliyor (benzetim) |
| Li, Yang, Teng, Cui, Chen 2024 ICRCA (10.1109/ICRCA60878.2024.10649134) | Ö | Taşlama robotu ekleminde **ek bir dişli çiftiyle** boşluk giderme, sonlu elemanlarla analiz. Boşluk temas basıncını az, gerilmeyi çok etkiliyor. Hocanın önerisinin endüstrideki bir örneği |
| Kaiser, Schäfer, Schütz, Parspour, Lechler 2024 SPEEDAM (10.1109/SPEEDAM61530.2024.10609128) | Ö | Çift motorlu, **elektriksel ön yüklü** robot eklemi için toplu parametreli model. Ön yük açıkken ölçümle model arasında kalıcı farklar var |
| Sun, Liang, Fang 2019 *Industrial Robot* (10.1108/IR-06-2018-0124) | Ö | Delme robotunda ön yüklü çift somun ve çift motorla boşluk giderme |
| Su ve ark. 2021 IJCNN (10.1109/IJCNN52387.2021.9534277) | Ö | Fazla eyleyicili paralel robotta iç ön yükün çok amaçlı en iyilenmesi (güç, anahtarlama kaybı) |
| Notlarımızdan: Ghaffari 2013 TMECH, Sun 2023, Xu 2023 RA-L, Karim 2018 | TM (önceden) | Tork ön yükü aştığında kararsızlık (Ghaffari). Anma akımını aşan çift motorlu ön yük (Sun). Servo çatışması (Xu). Dış tork mekanik ön yük gibi davranıyor (Karim) |

### 2.1a Verl–Engelberth 2018, tam metin (İstinye OpenAthens, ScienceDirect)

- Ön yük tanımı: `τ_p = K_w,1 τ_ref,1 − K_w,2 τ_ref,2`. Endüstride kullanılan "torque balancing" denetleyicisi (Siemens, Heidenhain).
- Sabit ön yükün bedeli: en büyük ilerleme torku `2(τ_max − τ_p,c)`'ye düşüyor.
- **Kritik cümle:** *"Despite preloading, backlash still occurs. In static state… backlash occurs during sign change of the torque of one motor."* Ön yük boşluğu ortadan kaldırmıyor. Yüz değişimini yalnız iki zincirden birine kaydırıyor. Avantajı: *"backlash never occurs simultaneously in both drive trains… the machine table is never in an undefined state"*.
- En küçük ön yük: `τ_p,0 > max(τ_s,1; τ_s,2)`, yani sürtünmeyi (stiction) aşmalı. Kapatma eşiği: `τ_off > max(τ_s,1; τ_s,2) + τ_s,t`. Yüz değişim bölgesi `2τ_p,0 < τ_ref,B < 2τ_off`.
- Sonuçlar:
  - Literatür ön yük için gerekçe vermeden anma torkunun yaklaşık %20'sini öneriyor. Bu çalışmada %4 yetiyor.
  - Boşluk 30 µm'den 9 µm'ye iniyor, sıfırlanmıyor, çünkü sürtünme tahrik zincirini elastik olarak deforme ediyor. Aşırı ön yükle (12,5 N·m) bile 4 µm kalıyor.
  - Ortalama ön yükü %20'den %10'a indirmek toplam enerjiyi %3 azaltıyor.
- Sınırlar: *"the detection of these modes is not subject of the presented concept"* (ön yükün ne zaman gerektiğini sezmek kapsam dışı). Dinamik hareketteki etki ve kararlılık kanıtı sonraya bırakılmış.
- **Bizim için:**
  1. Ön yük **yüz belirsizliğini yok etmiyor, nereye taşınacağını seçiyor.** Hocanın yaylı dişlisi de böyle çalışır: ön yük aşılınca yüz yine değişir.
  2. En küçük ön yük sürtünmeyle belirleniyor. Ucuz ve sürtünmesi yüksek dişlide yay ön yükü büyük olmak zorunda, bu da Du 2025'teki verim kaybını büyütür.
  3. "Ön yükün ne zaman gerektiğini sezmek" bu çalışmada açıkça kapsam dışı. Kolun hangi yüzde olduğunu kestirmek tam olarak bu boşluğu dolduruyor. Tezde Steinle 2025 ve Verl–Engelberth 2018 birlikte anılabilir: "uyarlamalı ön yük endüstride var, ama durumu sezen kısım ya yük tarafı ölçüsüne dayanıyor ya da kapsam dışı bırakılmış".

### 2.2 Soru 2 için ara değerlendirme (tartışmaya açık)

1. **Hocanın önerisi literatürde iyi bilinen bir yöntem.** Makaslı veya bölünmüş dişli, ek dişli çifti, çift motor, esnek taşıyıcı gibi birçok mekanik ve elektriksel ön yük çözümü var. Kendi başına yeni değil, kestirimimizin de rakibi değil. İki yaklaşım farklı tasarım noktalarında duruyor.
2. **Ön yükün literatürde açıkça yazılı üç bedeli var:** verim kaybı (Du 2025), sürtünme ve aşınma artışı, sürekli enerji tüketimi (Steinle 2025). Ayrıca ön yükün bir tork sınırı var: iletilen tork aşınca boşluk geri geliyor ve sistem kararsızlaşabiliyor (Ghaffari 2013).
3. **Steinle 2025'in mantığı bizim mantığımızla aynı yönde:** ön yükü yalnız gerektiğinde uygulamak. Onlar bunu iki motor ve yük tarafı ölçüsüyle (doğrusal ölçek) yapıyor. Bizim tek motorlu sistemimizde yerçekimi zaten "bedava" bir ön yük. Yalnız 180° civarında bu ön yük kayboluyor, sorun da tam orada başlıyor.
4. **Bu sorunun cevabı tezi güçlendirebilir:** "Mekanik ön yük sorunu ortadan kaldırır, ama bedelli. Ön yükü sürekli yüksek tutmak yerine, yerçekiminin yetmediği yerde ve gerektiği kadar uygulamak için kolun hangi yüzde olduğunu bilmek gerekir. Mekanik ön yük olan sistemde de aynı kestirim ön yükün hâlâ çalışıp çalışmadığını izler."
5. **Du 2025'ten çıkan ek argüman:** ön yükün verim bedeli **hafif yükte** en büyük. Bizim kolda 180° civarında yerçekimi torku sıfıra iner, yani eklem hafif yükte çalışır. Sabit bir yay ön yükü bu yüzden bedelini en çok tam ihtiyaç duyulduğu bölgede öder, 90° civarında ise gereksiz kalır (orada yerçekimi zaten ön yük).
6. Yay ön yükünü açıya göre boyutlandırma ve ön yük kaybını yalnız motor sinyalleriyle sezme konusunda doğrudan bir kaynak bulunamadı. Bu da olası bir katkı alanı.

### 2.3 Eksik kalanlar

- ~~Patent taraması yapılmadı.~~ Google Patents taraması yapıldı (2.4). Espacenet taranmadı.
- Tam metin durumu (21 Kasım, İstinye OpenAthens):
  - Ruderman–Fridman 2019 ve Du 2025 okundu. PDF'ler `literatur/genisletme/pdf/` içinde, depoda değil.
  - Gattringer 2017 (Springer) ve Gnad 2025 (ASME) aboneliğin dışında.
  - Verl–Engelberth 2018 (ScienceDirect): kullanıcı CAPTCHA'yı geçti, tam metin okundu ve PDF indirildi (2.1a).
  - Li 2024 ICRCA henüz denenmedi.

### 2.4 Patent taraması (Google Patents, 21 Kasım 2026)

**Yöntem.** Chrome üzerinden patents.google.com arama sayfası. Her sorguda en alakalı ilk 20 sonuç listelendi. Serbest metin sorguları çok gürültülü çıktı (cerrahi alet, taşıt aksı, şırınga pompası gibi), bu yüzden CPC sınıflarıyla daraltıldı:
- F16H55/18 (boşluksuz dişliler), F16H57/12 (boşluk alma düzenleri)
- B25J9/1641 (eklemde boşluk, sürtünme, esneklik telafisi)
- G05B2219/41059 (boşluk telafisi), G01M13/021 (dişli testi)

Sorgu konuları: yaylı / makaslı / bölünmüş dişli ön yükü, çift motorlu ön yük, ön yük kaybı ya da yay bozulması sezimi, motor akımı ve kodlayıcıyla boşluk ya da temas yüzü kestirimi, yerçekimi ile boşluk ilişkisi.

İşaretler: **İ** = 1. istem (ve gerekirse bağımlı istemler) okundu, **Ö** = yalnız özet, **B** = yalnız başlık. Sahip ve öncelik yılı arama listesinden alındı. JP ve CN patentlerinde Google'ın makine çevirisi okundu.

#### A. Mekanik ön yük ve boşluk giderme (hocanın önerisine yakın)

| Patent | Sahip, öncelik | Durum | Öz | Bizimle farkı |
|---|---|---|---|---|
| US20120017717A1 | Hon Hai, 2010 | Ö | Çıkış milinde iki ayar dişlisi, giriş dişlisinin iki diş yüzüne ayrı ayrı yaslanıyor. Robot kolunda kullanım | Saf mekanik çözüm. Sezme ya da izleme yok |
| EP2735767B1 | maxon motor, 2012 | B | Taşıyıcıları birbirine göre ön gerilmeli, boşluksuz planet dişli | Aynı |
| KR101855712B1 | Mintrobot, 2017 | B | Boşluksuz sikloid redüktör | Aynı |
| JP2020116677A | FANUC, 2019 | İ | Motor + motor dişlisi + yardımcı yatak tek birim. Birim, karşı dişliye yaklaşacak biçimde radyal kaydırılıp vidayla sabitleniyor (yay değil, ayar). **Açıklamada:** düşey eksen etrafında dönen eklemlerde (dikey mafsallı robotun 4–6. eksenleri, SCARA) *yerçekimi dişliye etki etmeyebiliyor*, bu yüzden boşluk yörünge doğruluğunu bozuyor | Yerçekiminin "doğal ön yük" olduğu ve onun olmadığı yerde sorunun başladığı fikrinin endüstri tarafından da kabul edildiğini gösteriyor. Çözümü montajda sabit ayar, durum sezimi yok |

#### B. Elektriksel / çift motorlu ön yük

| Patent | Sahip, öncelik | Durum | Öz | Bizimle farkı |
|---|---|---|---|---|
| US8436565B2 (CN101794136B) | FANUC, 2009 | İ | Bir gövdeyi süren iki motor (tandem). Hız denetleyicisinin integral çıkışı paylaşılıyor, iki tork komutuna zıt yönlü ön yük ekleniyor | İki motor şart. Ön yükün sağlığı izlenmiyor |
| US10700623B2 | EGT Eppinger, 2015 | İ | İki adım motoru mekanik bağlaşımla çıkışı sürüyor. Merkezi birim, konum referansının yanında ayrı bir **gerdirme (ön yük) referansı** ile iki sürücüye komut üretiyor | Aynı |
| US8686680B2 | Rethink Robotics, 2011 | Ö | Çift motorlu seri elastik eyleyici. Her motor bir dönüş yönünde dişler arası boşluğu kapatacak biçimde ön yüklü | Aynı |
| US10081102B1 | X Development, 2016 | İ | Yön değişiminde boşluk ölü bandının bir kısmını ana motor, kalanını küçük oranlı ikinci motor çıkış milinden geçiriyor ve iletimi yeni yöne yaslıyor | Yön değişim anını komuttan biliyor, kestirmiyor |
| CN122559963A | Danobat, 2025 | İ | Robot kolu ekleminde tahrik dişlisine iki motor pinyonu, ikinci motor birinciye zıt tork uyguluyor | Steinle 2025 ile aynı fikrin robot kolu patenti. Durum sezimi istemlerde yok |

#### C. Boşluk ölçme, izleme ve telafi

| Patent | Sahip, öncelik | Durum | Öz | Bizimle farkı |
|---|---|---|---|---|
| **US11602838B2** | Comau, 2019 | İ | Endüstriyel robot ekleminde dişli boşluğunu **yalnız motor kodlayıcısıyla, ek algılayıcı olmadan** izleme. Hareket sırasında kodlayıcı sinyalinde karakteristik bir salınım eğrisi aranıyor, genliğinden boşluk durumu (aşınma) çıkarılıyor | Bize en yakın "yalnız motor sinyali" patenti. Ama boşluğun **büyüklüğünü / aşınmasını** izliyor. Hangi yüzde temas olduğunu, yerçekimini ve ön yükü konu etmiyor |
| **US12259034B2** | Lenze, 2019 | İ | Elektrik motoruyla sürülen dişli kutusunda, **motor torkunun sıfırdan geçtiği yük değişimleri** motor ya da denetleyici büyüklükleriyle izleniyor. Yük çevrimi sayısı eşiği aşınca kritik durum bildiriliyor | Torkun sıfır geçişini (yani yüz değişimini) olay olarak kullanan tek patent. Ama yalnız **sayıyor** (aşınma ömrü). Yüz kestirimi, açı bağımlılığı ya da ön yük yok |
| **JP6881886B2** (US10259121B2) | Canon, 2015 | İ | Kolu, **yerçekimi momentinin eklem sürtünmesinden küçük olduğu** bir duruşa getirip giriş ve çıkış açı algılayıcılarıyla kayıp hareketi (lost motion) ölçüyor. Sonuçla eklem ömrü teşhisi | Yerçekiminin boşluğu gizlediğini ve ölçüm için onun küçük olduğu duruşun seçilmesi gerektiğini kabul ediyor. Bizim tersimiz: **çıkış algılayıcısı şart** ve ölçüm ayrı bir test duruşunda. Biz çalışma sırasında, yalnız motor tarafıyla kestiriyoruz |
| JP6053424B2 | Canon, 2012 | İ (kısmen) | Giriş kodlayıcısı + çıkışta iki ayrı kodlayıcı ile eklem açısı denetimi | Çıkış algılayıcısına dayanıyor |
| US9645565B2 (EP2911832B1) | Cognibotics, 2012 | İ | Eklemi kenetleyip hareketini kısıtlıyor, tahrik zincirini sürerken tork ve konum büyüklüklerini izleyip eklem özelliğini (boşluk, esneklik) çıkarıyor | Kenetleme gerektiren çevrimdışı tanılama |
| US10919150B2 | Kawasaki, 2017 | İ | Redüktör açısal iletim hatasını kestirip hız komutunu düzeltiyor | Boşluk değil iletim hatası. Yüz durumu yok |
| US11148287B1 | Orangewood Labs, 2020 | İ | Her eklemde iki kodlayıcı (giriş, çıkış) ve boşluk modeli. Gelecekteki boşluk hatası öngörülüp telafi ediliyor | Çıkış kodlayıcısı şart |
| US20240085221A1 | Honeywell, 2022 | İ | Eyleyicide uç durdurucular ve iki konum algılayıcısıyla gömülü test, boşluk miktarı ölçümü | Çevrimdışı, iki algılayıcı |
| CN110822073A | STEP (Shanghai), 2019 | İ | Girişi ters çevirip giriş ve çıkış açı eğrilerinden çıkışın durma süresini, oradan boşluğu hesaplıyor | Çevrimdışı, çıkış algılayıcısı şart |
| US9205560B1 | Redwood Robotics, 2013 | İ | İki eşdeğer olmayan algılayıcıdan eyleyicinin iç durumunu ayrı ayrı kestirip farkı eşikle karşılaştırarak arıza sezimi | Genel bir arıza sezimi çerçevesi. Boşluk ya da ön yüke özgü değil |
| WO2024088465A1 | Schaeffler, 2022 | Ö | Harmonik redüktörde esnek halkadan ölçülen torkla diş atlama arızasını sezip telafi etme | Farklı redüktör, tork algılayıcısı şart |

#### Sonuç (21 Kasım)

1. **Hocanın önerisinin (yaylı / ikinci dişli ile mekanik ön yük) patent tarafı kalabalık** (A ve B grupları). Bu, 2.2'deki "iyi bilinen yöntem" değerlendirmesini destekliyor. Bizim katkımız bu patentlerle yarışmıyor.
2. **"Ön yük kaybını ya da yay bozulmasını motor sinyaliyle sezme" için patent bulunamadı.** F16H55/18 ve G05B2219/41059 sınıflarında ön yük + izleme / kayıp + motor akımı sorguları ya yalnız mekanik tasarımlar ya da FANUC tandem patentini döndürdü.
3. **Tek motorlu, yerçekimi yüklü eklemde hangi diş yüzünde temas olduğunu yalnız motor akımı ve motor kodlayıcısıyla, çalışma sırasında kestiren bir patent bulunamadı.** En yakın üç patent katkımızın sınırlarını çiziyor, tezde anılmalı:
   - Comau US11602838B2: yalnız motor kodlayıcısı, ama boşluk büyüklüğü / aşınma.
   - Lenze US12259034B2: motor torku sıfır geçişi olay olarak, ama yalnız sayım.
   - Canon JP6881886B2: yerçekiminin boşluğu gizlediği kabul ediliyor, ama çıkış algılayıcısı ve ayrı test duruşu.
4. FANUC JP2020116677A açıklaması, "yerçekimi dişliye etki etmeyince boşluk sorun olur" fikrini endüstri dilinde söylüyor. 2.2'deki 3. ve 5. maddelere dayanak olarak kullanılabilir.

**Sınırlar.** Bu bir serbestlik (FTO) analizi değil, yalnız yenilik yönünde bir ön tarama. Sorgu başına ilk 20 sonuç okundu. Anahtar kelimeler İngilizce, JP/CN/DE patentleri Google'ın İngilizce çevirisi üzerinden yakalandı. Espacenet ve sınıf içi tam tarama yapılmadı. Bulunamaması yokluğun kanıtı değil.

### 2.5 Açık hâlâ açık mı? Ek tarama (21 Kasım, ikinci tur)

Kullanıcının isteği: açığın kapanmadığından emin olmak. Karşılaştırma ölçütü raporun katkı tanımı (rapor satır ~406): **180° çevresinde yerçekimi ön yükü sıfırken kolun hangi yüze yaslandığını, kola sensör koymadan, yalnız motor akımı ve motor açısıyla, çalışma sırasında kestirmek** (gerekirse itişle kolu temasa taşımak) ve ofset işaretini buna göre seçmek.

**Yapılanlar:**
1. En yakın patentlerin **ileri atıfları** (Google Patents "Cited By"): Comau US11602838B2 (4), Lenze US12259034B2 (8), Canon US10259121B2 / JP6881886B2 (45), Cognibotics US9645565B2 (42), FANUC tandem US8436565B2 (21). Konuyla ilgili satırlar süzülüp okundu.
2. **Çince ve Japonca anahtar kelimelerle** Google Patents: 齿隙/回差 + 重力 + 电机电流 + 关节; 消隙 + 弹簧 + 预紧 + 失效/检测; 双电机 + 消隙 + 预紧力矩 + 自适应; 啮合面/接触状态 + 电流 + 编码器; バックラッシュ + 重力 + モータ電流 + 推定. Sonuçların çoğu gürültü (cerrahi alet, mikroakışkan). İlgili olanlar aşağıda.
3. **Makale tarafı yeniden** (OpenAlex `search=`; eski `filter=title_and_abstract.search` sözdizimi artık 0 döndürüyor). 8 sorgu, ilk 10 sonuç.
4. **Espacenet:** Cloudflare bot doğrulaması çıktı, ajan geçmiyor. Kullanıcı geçince yapılacak.

**Yeni bulunan ve okunan patentler:**

| Patent | Sahip, öncelik | Durum | Öz | Katkımızla ilişkisi |
|---|---|---|---|---|
| **JP7674132B2** | Sumitomo Heavy Ind., 2021 | İ | Robot redüktörü durum izleme. Kollar arası bağıl konum ölçülüyor. **Yerçekiminin redüktöre ileri yönde moment uyguladığı bir duruş ile ters yönde uyguladığı ikinci bir duruş** seçiliyor ve her birinde bağıl konum değişimi referansla karşılaştırılıyor | Yerçekimiyle yüzü bilerek değiştirme fikri burada **var**. Ama çıkış tarafı (kollar arası) ölçümü şart, ayrı test duruşları kullanılıyor, amaç aşınma izleme. Yerçekiminin sıfır olduğu bölgede yüz kestirimi yok. Tezde mutlaka anılmalı (Canon ile birlikte) |
| **DE102017211549A1** | KUKA, 2017 | İ (kısmen) | Robot eklemini belirli bir eksen açısına getirip dişliye **art arda en az iki farklı (bağımlı istem: zıt yönlü) tork yükü** uygulama. Tahrik tarafı ve/veya çıkış tarafı açıları kaydedilip aşınma durumu çıkarılıyor | Motor torkuyla aktif yoklama ve yalnız tahrik tarafı açısı **mümkün** sayılmış. Bizim "itiş" fikrimize en yakın patent. Fark: çevrimdışı test, aşınma büyüklüğü ölçüyor. O anki yüzü kestirip denetimde kullanmıyor |
| **US11724390B2** | Samsung, 2021 | İ | Hedef boşluk ya da hedef ön yük ile ölçülen değer karşılaştırılıyor. Hata eşiği aşınca **ön yük eyleyicisi sürücü dişlinin eksenini kaydırıyor** (kapalı döngü ön yük). Açıklamada ölçüm, iki dişlideki kodlayıcıların gecikmesinden yapılıyor (motor akımı da olası algılayıcılar arasında sayılmış) | **Uyarlamalı ön yük + ölçüm** fikri patentli. 1. istem ölçüm yöntemini açık bırakıyor. "Kestirimle ön yükü tetikleme" rolünü tezde sunarken bu patent anılmalı. Bizim kestirim yöntemimiz bu istemde yok |
| US20230400384A1 (TWI922516B) | FANUC, 2020 | İ | Redüktör giriş ve çıkışında iki kodlayıcı, açı farkından arıza sezimi | Çıkış kodlayıcısı şart |
| US9709158B2 | Raytheon, 2012 | İ | İki motora zıt bias, sürüş komutu bias'a toplanıyor (çift motor ön yük denetimi) | B grubu, sezim yok |
| US20180126552A1 | ABB, 2015 | İ | Paralel iki motorlu dişli dizisi. Konuma göre deneysel boşluk tablosundan iki motor için telafi | Boşluk konuma bağlı tablo. Yüz kestirimi yok |
| JP5698777B2 | FANUC, 2013 | İ (kısmen) | Tandem iki motor, ön yük torkunu motor ivmesine göre üretiyor | Uyarlamalı elektriksel ön yük (Steinle 2025'in patent karşılığı gibi). Sezim yok |
| US20220090985A1 | Schlumberger, 2020 | İ (kısmen) | Eyleyiciyi çıkış hareket edene kadar sürüp ölçümler arasındaki farktan boşluk bulma | Çevrimdışı, boşluk büyüklüğü |
| DE102021205346A1 | ZF, 2021 | İ | Yük değişimi başlatılıp **akustik algılayıcıyla** darbe anı saptanıyor, aradaki süreden boşluk | Ek algılayıcı |
| EP4253798B1 | ABB, 2022 | İ (kısmen) | Elektrikli güç aktarımında dişli aşınması izleme (Lenze'ye atıf yapıyor) | Taşıt / genel tahrik, aşınma |
| CN121245854B | Chongqing Xiaokang, 2025 | İ (kısmen) | Robot eklem modülünde mekanik arıza olayının düzeyine göre tork denetimini ayarlama (Comau'ya atıf yapıyor) | Arıza düzeyine göre denetim, yüz kestirimi yok |
| CN120601776A | Wuhan Huazhiyang, 2025 | İ (kısmen) | Çift motorlu dişli sisteminde boşluk giderme denetim yöntemi | B grubu |
| CN102878279B | Chongqing Univ., 2012 | Ö | Elektrik denetimli, değişken diş kalınlıklı boşluk giderme dişli çifti | Mekanik ön yükün ayarlanabilir biçimi |

**Makale tarafında yeni (notlarımızda yoktu):**

| Çalışma | Durum | Öz | İlişki |
|---|---|---|---|
| Roozing, Volbeda 2025 *IEEE RA-L* (10.1109/lra.2025.3619805) | Ö | Sikloid redüktörlü robot eyleyicileri için iki boşluk giderme mekanizması. Değişen ön yükte boşluk **2–3 kat azalıyor**, bedeli sürtünme artışı (< 2 kat) | Mekanik ön yük bedeline sayısal dayanak (Du 2025, Steinle 2025 ile aynı grup) |
| Kiuichi, Fujimoto, Tsuji 2025 *Advanced Robotics* (10.1080/01691864.2025.2496677) | Ö | Redüktörlü motorda burulma açısal hızından boşluğu tanımlayıp burulma torku kestiriminden çıkarma, ölü bölge parametrelerini çevrim içi güncelleme | İki kodlayıcı (burulma açısı) gerekiyor. Yerçekimi ve yüz kestirimi yok |
| Noba ve ark. 2023 JSME Robomec (10.1299/jsmermd.2023.2a2-i20) | Ö | Çift kodlayıcılı motor, boşluk modeliyle burulma torku kestirimi | Çift kodlayıcı |
| Kotov 2026 *HardwareX* (10.1016/j.ohx.2026.e00767) | Ö | Ucuz UART servolarda boşluk ölçüm test düzeneği | Çevrimdışı ölçüm |

Önceden notlarımızda olanlar yeniden çıktı (kontrol amaçlı): "A virtual sensor for backlash in robotic manipulators" 2022 (10.1007/s10845-022-01934-z), dual-motor backlash elimination 2024 *Actuators*.

**Ara sonuç (Espacenet hariç):**
1. Açık **daraldı ama kapanmadı.** Parçaları ayrı ayrı biliniyor:
   - yerçekimiyle yüzü bilerek değiştirme (Sumitomo, Canon),
   - motor torkuyla aktif yoklama ve yalnız tahrik tarafı açısı (KUKA),
   - yalnız motor kodlayıcısıyla boşluk izleme (Comau),
   - tork sıfır geçişini olay olarak kullanma (Lenze),
   - ölçüme göre kapalı döngü ön yük (Samsung).
2. Bunların hiçbiri **yerçekimi ön yükünün sıfır olduğu bölgede, çalışma sırasında, yalnız motor akımı ve açısıyla o anki yüzü kestirip denetimde (ofset işareti) kullanmıyor.** Hepsi ya çıkış tarafı ölçümü ister, ya ayrı test duruşu / çevrimdışı test yapar, ya da yalnız büyüklük veya aşınma ölçer.
3. Katkı tanımı bu yüzden daha keskin yazılmalı: "yeni olan yerçekimini kullanmak ya da motor sinyaliyle boşluk ölçmek değil; ikisinin birleşimi ve tam olarak bilinen yöntemlerin çalışmadığı noktada (yerçekimi ön yükü sıfır) çevrim içi yüz kestirimi."
4. "Uyarlamalı ön yük tetikleyici" rolü için Samsung US11724390B2 anılmalı. O rol kestirim yöntemimizin bir **kullanımı** olarak sunulmalı, kendi başına yeni bir fikir olarak değil.

### 2.6 Espacenet taraması ve en yakın yeni patentler (21 Kasım, üçüncü tur)

Kullanıcı Cloudflare doğrulamasını geçti. Espacenet'te CQL sorguları (`ctxt` = başlık + özet + istem, `cpc=`) atıldı:
- E0 backlash preload + detect/monitor/diagnosis (63)
- E1 B25J9/1641 + backlash gravity (7)
- E2 G05B2219/41059 + backlash motor current + estimate (3)
- E4 backlash gravity motor + robot + current/torque + estimate (31)
- E5 anti-backlash spring + failure/fatigue/degradation/monitor (62)
- F1 F16H55/18 + monitor/detect/diagnosis/abnormal (10)
- F2 preload backlash + decrease/loss/abnormal + current/torque + motor (66)
- F3 backlash contact state + estimate/observer (347, ilk 20)
- F4 backlash gravity + zero/reversal/sign + joint/arm (114, ilk 20)
- H1 backlash correction gravity torque (28)
- H3 backlash gravity torque + small/zero/vicinity/balance (136, ilk 20)

Çince anahtar kelimeyle Espacenet sorgusu 0 döndü (yalnız İngilizce çeviri dizinleniyor). Çince patentler İngilizce çevirileri üzerinden yakalandı.

**Bize en yakın: yerçekimine bağlı boşluk düzeltmesi**

| Patent | Sahip, öncelik | Durum | Öz | Fark |
|---|---|---|---|---|
| **JPH07200018A** | Toyoda Machine Works, 1993 | İ | Mafsallı robotta, mevcut ve hedef konumdaki yerçekimi torkunun işaretine bakarak boşluk düzeltmesi. Hedefte \|τ_g\| eşikten büyük ve işaret değişiyorsa düzelt. Küçükse dönüş yönüne göre karar ver | **"Yerçekimi işaretiyle yüz seç, yerçekimi küçükse hareket yönüne bak" kuralı 1993'ten beri patentli.** Raporda "ofset tablosu bilinen yöntem" dememizi güçlendiriyor (Neubauer 2015'ten önce). Yüz ölçülmüyor, komuttan varsayılıyor |
| **WO2026074901A1** | Panasonic, 2024 (yayın 2026-04) | İ (5 istemin hepsi) | Eklemde yerçekimi torkunu hesapla, hız bileşeninin işaretini belirle. Düzeltme = işaret(hız) × k_gc. **k_gc, \|τ_g\| eşiğin altındayken 1, üstünde doğrusal olarak 0'a iniyor.** Açıklamada kol, gittiği yönde hedefin gerisinde duruyor (kayıp hareket) | Sorunumuzu (yerçekimi küçükken boşluk etkisi tam) ve bölgemizi doğrudan tanıyan en yeni patent. Ama yüzü **yaklaşma yönünden varsayıyor**, ölçülen sinyalden kestirmiyor. Hız ≈ 0'da (180° tutma, bozucu, salınım) işaret tanımsız. Bu Neubauer'in `sign(0)` açığının aynısı |
| WO2020008751A1 | Panasonic, 2018 | İ | Komut hızının dönüş anı ve dinamik model torkundan boşluk düzeltme miktarı | Komut ve model tabanlı |
| US12145275B2 | Panasonic | İ | Dönüşten önce duruş varsa (durma bayrağı) düzeltmenin frekansını düşürme | Komut tabanlı |
| **JP2009198203A** | Yaskawa, 2008 | İ | Düşey kremayer–pinyonda hareketli gövdeyi alttaki sabit tabana bırakıp yerçekimi yükünü kaldırıyor. Tork ters dönene kadar motor çevrilip **yalnız motor kodlayıcısı darbeleriyle** boşluk miktarı hesaplanıyor | Yalnız motorla ölçüm, ama çevrimdışı ve mekanik dayanakla. Yüz kestirimi yok |
| CN202646656U | PLA 63636, 2012 | Ö | Radar servosunda kasıtlı yerçekimi dengesizliği ile boşluk giderme (yerçekimi = mekanik ön yük) | "Yerçekimi bedava ön yük" fikrinin mekanik kullanımı. Sıfıra indiği bölgeyi ele almıyor |

**Diğer yeni okunanlar**

| Patent | Sahip, öncelik | Durum | Öz | Fark |
|---|---|---|---|---|
| CN122569605A | Dongguan Abasi, 2026 | İ (kısmen) | İnsansı robot eklem servo modülü: motor kodlayıcısı, **eklem çıkış açısı**, motor faz akımı, gövde duruşu, ayak teması → yerçekimi, eylemsizlik ve komşu eklem kompanzasyon torkları, "komütasyon öngörü penceresi" | Çıkış açısı ölçülüyor |
| CN123025288A | Guangzhou Jieningyue, 2026-08 | Ö (Espacenet özeti) | İnsansı robot uzaktan arıza bakımı: eklem anormalliğinde çok frekanslı mikro tedirgin tork, **motor ucu açısı + redüktör çıkış açısı + iç tork algılayıcısı** → aktarım boşluk açısı çözümleniyor | Aktif yoklama var, ama çıkış açısı ve tork algılayıcısı şart, çevrimdışı tanı |
| WO2025256084A1 | Chongqing Jinshan Medical, 2024 | İ (kısmen) | Robot kolu güç eklem modülü. En az iki dişli çifti. Duruştan harekete ya da yön değişiminde iki çifte zıt yönlü bias tork | B grubu (çift yollu ön yük) |
| CN119188753A | Guangzhou Keyi, 2024 | İ | Dinamik modelden beklenen tork ile gerçek tork farkı PID ile kompanze | Genel tork kompanzasyonu |
| CN120056110A | Shanghai Jiao Tong, 2025 | İ | Uyarım deneyinde eklem açısı, hızı ve akımından dinamik artık. Boşluk hata modeli PINN ile kompanze | Uyarım deneyi + öğrenme, yüz durumu yok |
| CN122577720A | Southeast Univ., 2026 | İ | Motor–redüktör boşluk histerezisini dikkat mekanizmalı ağla öngörüp kompanze | **Çıkış açısı, hızı ve ivmesi** girdi |
| WO2025234218A1 | Mitsubishi Electric, 2024 | İ | Redüktörün giriş ve çıkış motoru kodlayıcı darbeleriyle boşluk ölçümü | Üretim testi, iki kodlayıcı |
| CN122100237A | Chengdu Hangtian Kaite, 2026 | İ (kısmen) | Tork komutu, kodlayıcı hızı, sıcaklık ve titreşimden eklem modülü sağlık izleme | Genel sağlık izleme |
| CN108608462A | Suzhou Shangxian, 2018 | İ (kısmen) | Ağır yük kolunda dört aşamalı doğruluk kompanzasyonu: boşluk, model, yerçekimi, sapma | Kalibrasyon tabanlı |
| CN123047288A | Shenzhen Hengjiefeng, 2026 | Ö | Hassas işleme tezgahında sıcaklık ve **servo akımından vida ön yük bozulması** ve ters boşluk eşleşmesi | Bilyalı vida (dişli değil). Motor akımıyla **ön yük bozulması izleme fikrinin** en yakın örneği, tezde anılmalı |

**Sonuç (Espacenet dahil, 21 Kasım):**
1. **Ofset tablosunun "yerçekimi işaretine göre yüz seç" kuralı 1993'ten beri patentli** (Toyoda). Yerçekimi küçükken boşluk düzeltmesini tam uygulayıp yüzü hareket yönünden seçmek 2024'te patentlendi (Panasonic). Raporda bu kısmı zaten "bilinen yöntem" diye sunuyoruz. Doğru.
2. **Açık hâlâ açık, ama sınırı artık çok net:** yerçekimi torku küçükken bilinen bütün çözümler yüzü ya **komuttan** (hareket ya da yaklaşma yönü, dönüş anı: Toyoda, Panasonic, Neubauer) varsayıyor, ya da **ölçüyor ama çıkış tarafı algılayıcısı ya da ayrı ve çevrimdışı bir test** gerektiriyor (Yaskawa, KUKA, Canon, Sumitomo, Mitsubishi, CN123025288A). Hız ≈ 0 iken, bozucu altında ya da salınımda gerçek yüzü **çalışma sırasında, yalnız motor akımı ve açısıyla** kestiren bir patent ya da makale bulunamadı.
3. Katkının en keskin cümlesi (öneri): "Komutla varsayılan yüz, yerçekimi ön yükü sıfırken ve hız sıfıra yakınken gerçek yüzden ayrılabilir. Biz gerçek yüzü yalnız motor sinyalleriyle kestiriyoruz." Bunu kanıtlamak için benzetimde **komut tabanlı kural (Toyoda/Panasonic türü) ile kestiricinin karşılaştırılması** gerekir.
4. Ön yük kaybını motor akımıyla izleme: yalnız bilyalı vida için bir örnek var (CN123047288A, 2026). Dişli ön yükü (yaylı ya da makaslı) için bulunamadı.
5. Kalan risk: JP, CN ve KR patentlerinin özgün dildeki tam metinleri taranmadı (makine çevirisi). 2026'nın son aylarında yayımlanmamış başvurular doğal olarak görülemez (18 ay gizlilik).

### 2.7 Ek tarama ve gözlenebilirlik itirazı (23 Kasım 2026)

Beş ek sorgu yapıldı: 2024–26 yıllarında motor tarafından yüz kestirimi, donanımla (ek algılayıcıyla) sensörsüz boşluk, ucuz kol ve AS5600. **Yeniliği bozan bir kaynak çıkmadı.** Yeni görülenler:

| Kaynak | Ne yapıyor | Bizimle farkı |
|---|---|---|
| Precision Engineering, 2024 (ScienceDirect PII S0141635924002125) | Yalnız tahrik tarafı sinyallerinden, Hilbert–Huang dönüşümüyle boşluğun **büyüklüğünü** kestiriyor | Büyüklük (r) kestirimi, çevrimdışı/sinyal işleme. Çalışma sırasında **temas yüzü** kestirimi yok. Bizde r biliniyor sayılıyor, yoklama ise r'yi izlemeye aday (ikinci bildiri) |
| ResearchGate 398643236, "Gear Backlash Identification and Compensation ... Industrial Robot Repeatability" | Yön kuralı: düzeltmenin işareti hedefe varmadan önceki hızdan seçiliyor | Panasonic WO2026074901A1 ailesiyle aynı, **komut tabanlı** yüz varsayımı. Hız ≈ 0'da ve bozucu altında tanımsız (B1'deki "panasonic" kuralı bunu temsil ediyor) |
| dongho.dev blog yazısı | "Motor tarafı algılayıcı, boşluk içindeki çıkış konumunu çözemez" itirazı | Hakem itirazı olarak bildiride cevaplanmalı (aşağıda) |
| robonine (bütçe servo testleri) | Ucuz seri servolarda boşluğu yaklaşık 0,8° ölçmüş, çift servo ile ön yük denemiş | Düşük maliyetli kollarda boşluğun bizim r = 1,5° (yarı genişlik) mertebesinde olduğunu destekliyor. Ön yük B2'deki makas dişliye karşılık |

Künye notu: dongho.dev ve robonine sayfalarının tam bağlantıları 23 Kasım'daki yeniden aramada bulunamadı. Bildiride atıf yapılacaksa önce bağlantı ve sayı (0,8°) yeniden doğrulanmalı. Yeniden aramada ayrıca robonine'a bağlı bir Zenodo kaydı (records/19261714, ucuz UART servolarda boşluk test düzeneği, v3, 27 Mart 2026) ve SO-ARM100 deposunda "Feetech STS3215 servos have around 1 degree real backlash" başlıklı bir GitHub konusu görüldü. Bunların yalnız başlıkları görüldü, içerikleri okunmadı.

**Gözlenebilirlik itirazı ve cevabı.** İtiraz: "Motor tarafındaki enkoder, çıkışın boşluk içinde nerede olduğunu göremez. Motor tarafından yüz kestirimi bu yüzden imkânsız." Cevap:
1. Biz boşluk içindeki sürekli konumu kestirmiyoruz. Kestirdiğimiz, ayrık bir durum olan **temas yüzü** (s ∈ {−1, +1}).
2. Yüz değişimi motor tarafında iz bırakır. Temas kurulurken dişli torku sürtünme aralığının dışına çıkar ("olay", tork gözlemcisi + bilinen sürtünme aralığı). Temas kaybında da motor yükten kurtulur. Durum ancak bu geçişlerde değişebildiği için, geçişleri gözleyen bir kestirici durumu izleyebilir.
3. İzlenemeyen tek durum, hiç tork aktarılmadan boşlukta kalınan, yerçekiminin de sıfır olduğu durum. Orada **yoklama** (aktif, küçük mutlak itiş) yüzü sorgulayıp durumu gözlenebilir kılar. Yani gözlenebilirlik edilgen değil, **etkin algılamayla** sağlanıyor.
4. Kanıt: B1/B1-L benzetimleri (sürtünmeli tesiste olay+yok 210/210, soğuk başlangıçta bile) ve STA tespit edilebilirliği analizi.

Bu cevap bildirinin "Hakem soruları" bölümüne de eklenmeli (`calisma_notu/benzetim_B1_B3.md`).

**Patent ile akademik yenilik farkı (kullanıcıyla konuşuldu).** Bir patentin varlığı, akademik yeniliği kendiliğinden ne kanıtlar ne de bozar. Panasonic'in 2024 başvurusu iki şeyi gösteriyor: sorun sanayide güncel, ve motor tarafıyla çözülmek isteniyor. Teşhisli bir olumsuz donanım sonucu da ikinci bir çalışmaya veri olur.
