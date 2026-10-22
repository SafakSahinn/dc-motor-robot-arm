# Okuma notları

Tam metni okunan makaleler. Her notta: ne yapmışlar, bizim çalışmayla ilişkisi, bizde olmayan ne.

## Kollár, Stépán, Turi — Digital balancing of systems with backlash (IEEE CDC 2002)

Dosya: `ieee/pdf/2002_1184344_...pdf` · DOI 10.1109/CDC.2002.1184344

- Sistem: arabalı ters sarkaç. Motor tekerleği elastik dişli kayışla sürüyor; boşluk kayış ile dişli arasında.
- Kontrolcü: PD (P, D kazançları). Gözlemci yok.
- Yöntem: yalnızca simülasyon ve sayısal çatallanma analizi (AUTO, Mathematica, MATLAB). Deney yok.
- Bulgu: boşluk, üst denge noktası çevresinde küçük genlikli sürekli salınım (limit cycle) üretiyor. P–D düzleminde "kararlı denge" ve "kararlı salınım" bölgelerini çizmişler. Zaman gecikmesi eklenince hareket düzensizleşiyor ama kaotik değil.
- Bizimle ilişkisi: 180° (dik yukarı) hipotezimizin dayanağı. Kaynak olarak gösterilecek.
- Bizde olup onlarda olmayan: yalnızca üst dengeye bakıyorlar, çalışma açısı değişmiyor; yerçekiminin dişliyi bastırma etkisi incelenmiyor; gözlemci yok; deney yok; arabalı sarkaç, tek eklemli kol değil.

## Sun, Wu, You — Limit cycle analysis and suppression for DOB-based missile autopilot (IEEE TAES 2025)

Dosya: `ieee/pdf/2025_11054329_...pdf` · DOI 10.1109/TAES.2025.3584008

- Sistem: hipersonik araç kanat eyleyicisi; boşluk benzeri histerezis modeli.
- Kontrolcü: çok frekanslı genişletilmiş durum gözlemcisi (MFESO) tabanlı otopilot.
- Bulgu: gözlemcinin yüksek kazancı boşlukla etkileşince yüksek genlikli sürekli salınım çıkıyor. Tanımlama fonksiyonu + frekans analiziyle salınımın frekans ve genliğini önceden tahmin etmişler. Çözüm: gözlemci bant genişliğini takip hatasına göre ayarlayan uyarlamalı mekanizma. Uçuş testiyle doğrulanmış.
- Bizimle ilişkisi: "gözlemci boşluğu giderir" varsayımının sınırı. Tanımlama fonksiyonu yöntemi bizim de kullanacağımız araç.
- Bizde olup onlarda olmayan: yerçekimi yok (kanat eyleyicisi); açıya bağlı yük ön yükü yok; ayarlama takip hatasına göre, bizim önerimiz çalışma açısına göre.

## Wang, Zou, Xu, Chang, Li — Backlash compensation based oscillation suppression control for automatic loading manipulator arm with NESO (Nonlinear Dynamics 2024)

Dosya: `ieee_disi/pdf/2024_Wang_Nonlinear_Dynamics_backlash_NESO_manipulator.pdf` · DOI 10.1007/s11071-024-09836-w

- Sistem: topçu mühimmat yükleme kolu (ALMA). PMSM, redüktörle kolun taban halkasını (seat ring) döndürüyor; dişli oranı 82,35, yük eylemsizliği 16,3 kg·m², kol 56,7 kg. Dönme ekseni düşey; kol yatay düzlemde dönüyor.
- Model: iki kütleli (motor + yük), aralarında burulma yayı K_s ve ölü bölge biçimli boşluk (2α = 13 mrad). Denk. (1)'de **yerçekimi terimi yok**; yük tarafı yalnızca J_l θ̈_l + B_l θ̇_l = τ_s.
- Kontrolcü: klasik üç döngü (konum P, hız PI, akım).
- Analiz: tanımlama fonksiyonu N(A) ile G(jω) ve −1/N(A) kesişimi; limit cycle frekansı ω_LC ≈ r_s·ω_a (r_s = sertlik oranı, ω_a = karşı-rezonans frekansı). α, J_l, k_p1 ve k_p2 değişince genlik ve frekansın nasıl değiştiği tabloda (Tablo 2). k_p1 > ~2093 ya da k_p2 > ~5,2 olunca sistem kararsız.
- Yorumları: boşluk, iletilen torku azaltıp "etkin burulma sertliğini" düşürüyor; limit cycle'ın asıl sebebi bu.
- Yöntem: üçüncü dereceden doğrusal olmayan genişletilmiş durum gözlemcisi (TNESO) iletim torkunu tahmin ediyor. Tahmin edilen ile hesaplanan tork arasındaki fark q-ekseni akımına telafi olarak ekleniyor. Lyapunov ile sınırlı hata ispatı var. Kutup atamalı telafi (Wang 2017 TIE) ile karşılaştırılıyor.
- Deney: gerçek ALMA tezgâhı, DSP28377D, 5 kHz. Konumlama hatası 0,006 rad'dan 0,001 rad'a düşüyor. Deneyde boşluk kasıtlı büyütülmemiş; tek çalışma noktası.
- Gelecek çalışma önerileri: doğrusal olmayan burulma sertliği, daha iyi sürtünme modeli. Yerçekimi ya da açıdan söz edilmiyor.
- Bizimle ilişkisi: en yakın rakip, ama boşluğumuzu doğruluyor. Tanımlama fonksiyonu + gözlemci + deney üçlüsü bizimkine çok benziyor; ancak yatay düzlemde dönen bir sistem, yük torku sıfır, çalışma açısının hiçbir etkisi yok.
- Bizde olup onlarda olmayan: açıya bağlı yerçekimi ön yükü (mgℓ sinθ); bunun boşluk ölü bölgesini nasıl "kapattığı" (dişliyi bir tarafa bastırdığı) ve limit cycle bölgesini açıya göre nasıl kaydırdığı; düşey düzlemde çalışan tek eklemli kol; düşük maliyetli donanım.
- Bizim için yararlı: Denk. (3)–(16) arası tanımlama fonksiyonu türetimi şablon olarak kullanılabilir. Yerçekimi eklenince boşluk girişine bir ön kayma (bias) gelecek; bu durumda simetrik N(A) yetmez, **kaymalı (bias) tanımlama fonksiyonu** (DIDF/ön yüklü giriş) gerekecek. Makalemizin yöntemsel katkısı tam da burası olabilir.
- Kaynakçasında takip edilecekler: [16] Villwock–Pacas 2009 TIE; [17] Merzouki 2007 CEP; [26] Kawai 2021 TIE; [27] Yokokura 2020 TIE (load-side acceleration, torsion torque sensing); [30] Wang 2017 TIE (indirildi); [31] Yang 2016 TMECH (shaft torque compensator); [34] Sun 2021 Asian J. Control (observer-based backlash compensation).

## Ghaffari, Mohammadiasl — Calculating the frequency of oscillation for servo axes distressed by clearance or preloading (IEEE/ASME TMECH 2013)

Dosya: `ieee/pdf/2013_Ghaffari_TMECH_clearance_preloading_oscillation.pdf` · DOI 10.1109/TMECH.2012.2195670

- Sistem: takım tezgâhı servo eksenleri. Dişli tahrikli döner tabla (Siemens servo, dişli oranı 1211, boşluk 0,04°) ve vidalı mil tahrikli doğrusal eksen (boşluk 0,4 mm). Döner tabla yatay, dönme ekseni düşey; yerçekimi yok.
- Model: iki kütle + burulma sertliği. Sertlik eğrisi dört türlü (Şekil 2): (a) ideal doğrusal, (b) boşluk (ölü bölge), (c) **ön yüklü anti-boşluk mekanizması** (yaylı çift pinyon / çift somun), (d) boşluk + ön yük birlikte.
- **"Ön yük" burada bizimkinden farklı:** iç mekanizmanın yayla verdiği simetrik bir ön gerilim. Eğri simetrik kalıyor (±τ_p). Dışarıdan gelen, tek yönlü bir yük torku (yerçekimi gibi) DEĞİL. Yani bunlar da simetrik tanımlama fonksiyonu kullanıyor.
- Kontrolcü: P konum + PI hız (Siemens Sinumerik).
- Analiz: çok döngülü sistemi tek döngülü G(s)·H(s) ve n(θ_d) biçimine çeviriyorlar (Şekil 5). Ana sonuç tek bir boyutsuz sayı, **sertlik oranı** r_gs = √(k_p·k_v / k_se):
  - r_gs ≥ 1 → kararsız salınım (mekanik rezonans, ω = ω_a)
  - 0,4 < r_gs < 1 → kararlı limit cycle, "rezonans rejimi", ω_lc ≈ √(k_p k_v / J_le) (tanımlama fonksiyonuyla)
  - r_gs ≤ 0,4 → "çarpma rejimi" (dişliler çarpışarak salınıyor; birinci harmonik varsayımı bozuluyor, tanımlama fonksiyonu yerine çarpma denklemleri ve sekme katsayısı e kullanılıyor)
- Ön yük için kritik gözlem (s. 927): anti-boşluk sistemi, **burulma torku ön yükü aşmadığı sürece doğrusal (boşluksuz) gibi davranıyor**. Tork ön yükü aşınca n(θ_d) azalan bir fonksiyona dönüşüyor ve salınım kararsız, hatta yıkıcı olabiliyor.
- Deney: iki gerçek endüstriyel tezgâh. Frekans tahmini simülasyonla %2–18, teoriyle %8–24 hata. Hatanın ana kaynağı ihmal edilen Coulomb sürtünmesi; sürtünme de kararlılık sınırını (r_gs = 1) kaydırıyor.
- Bizimle ilişkisi: yöntem olarak çok yakın. Hem bizim "tek döngüye indirgeme + tanımlama fonksiyonu + deney" planımızın şablonu, hem de "ön yük boşluğu bastırır" ilkesinin literatürdeki karşılığı.
- **Bizim için en önemli çıkarım:** onların "tork ön yükü aşmadıkça boşluk görünmez" sonucunun yerçekimi karşılığı şu: kolda yük torku mgℓ sinθ₀ bir ön kayma (bias) gibi davranır. Salınımın tork genliği bu kaymadan küçükse dişli boşluğun öbür tarafına hiç geçmez ve limit cycle oluşmaz. Böylece **açıya bağlı bir eşik koşulu** çıkıyor: |mgℓ sinθ₀| > (salınım tork genliği) ise limit cycle yok. 90° civarında kayma en büyük (bastırılmış), 0° ve 180°'de sıfır (boşluk tam etkin). Bu, kaymalı tanımlama fonksiyonu analizinin sözel özeti; makalede analitik olarak gösterilmeli.
- Kullanılabilecek araç: r_gs sertlik oranı; bizim kolda yerçekimi eklenince r_gs'nin açıya göre nasıl değiştiği (etkin sertlik açıya bağlı hale geliyor) bir harita olarak çizilebilir. Sürtünmenin kararlılık sınırını kaydırması da bizim düzenekte (ucuz dişli = yüksek sürtünme) hesaba katılmalı.
- Kaynakçasında takip edilecekler: [4] Wilson ve ark. 2007 J. Sound Vib. "Coexisting solutions and bifurcations in mechanical oscillator with backlash"; [5] Nordin 1995 lisans tezi; [8] Ghaffari, Tomizuka, Soltan 2008 Nonlinear Dyn. "Stability of limit cycles in nonlinear systems"; [13][14] Shahruz 2000/2002 (DOB ile doğrusal olmayanlık bastırma; [13] zaten indirildi: 2000_868924); [17] MohammadiAsl 2009 IROS "Vibration detection and backlash suppression in machine tools" (10.1109/IROS.2009.5354660; taramada çıktı, henüz indirilmedi).

## Wang, Yang, Zheng, Hu, Xu — Analysis and suppression of limit cycle oscillation for transmission system with backlash nonlinearity (IEEE TIE 2017)

Dosya: `ieee/pdf/2017_Wang_TIE_limit_cycle_backlash_transmission.pdf` · DOI 10.1109/TIE.2017.2711564

- Sistem: deney düzeneği. İki PMSM (biri tahrik, biri yük), arada elastik mil ve elle ayarlanabilen boşluk düzeneği (2b = 0,05 / 0,1 rad), yük tarafına takılabilen volanlar. Yatay mil; yerçekimi yok. Analizde yük torku T_l = 0 alınmış ("disturbance-free").
- Model: iki kütle + ölü bölge boşluk (Ghaffari 2013 ile aynı yapı, ona atıf yapıyor).
- **Önemli gözlem 1, sensör yeri:** konum sensörü motordaysa (yarı-kapalı çevrim) limit cycle yok ama 0,02 rad konum hatası var. Sensör yükteyse (tam-kapalı çevrim) hata gidiyor ama **kararlı limit cycle** çıkıyor (Şekil 4).
- Analiz: tanımlama fonksiyonu; ω_lc ≈ √(k_p k_v / J_l) = r_s·ω_ARF (Ghaffari'nin sertlik oranı formülü). Boşluk büyüyünce frekans aynı kalıyor, genlik artıyor; r_s büyüyünce ikisi de artıyor (Tablo I). r_s ≥ 1 ise frekans karşı-rezonans frekansına kilitleniyor.
- Yöntem: durum geri beslemeli telafi T_b = (k1 + k2 s + k3 s²)·θ_d; θ_d = motor açısı − yük açısı (iki enkoder gerekli). Kutup atamayla beşinci dereceden sistemi tek kütleli üçüncü dereceden sisteme eşdeğer yapıyorlar. Türev gürültüsü için üçüncü dereceden Butterworth (300 rad/s).
- Deney: tahmin edilen frekanslar deneyle çok iyi uyuşuyor (10,5'e karşı 10,2 Hz; 15,6'ya karşı 15,6 Hz; 7,9'a karşı 7,67 Hz). Çentik filtre limit cycle'ı sadece azaltıyor, durum geri beslemesi yok ediyor. Ani yük testi de var.
- **Önemli gözlem 2, bizim hipotezimizi destekliyor (s. 9268):** durum geri beslemeli sonuçta "geçici rejimde hafif çarpma görülüyor, çünkü **yüksüz durumda sistem her zaman temas halinde değil**" diyorlar. Yani yük torku olmadığında dişlinin temastan çıktığını kendileri not ediyor, ama yükün (ya da yerçekiminin) temas üzerindeki etkisini incelemiyorlar. Makalemizde motivasyon olarak alıntılanabilir.
- Bizimle ilişkisi: bizim donanım planımızı doğrudan etkiliyor. Kol miline AS5600 koyup konum döngüsünü oradan kapatırsak tam-kapalı çevrim olur, yani limit cycle riski artar. Bu bir sorun değil, aksine deneyin kendisi: limit cycle'ı görmek istiyoruz. İki sensör planı (motor enkoderi + kol AS5600) θ_d'yi ölçmemizi de sağlıyor; bu tam olarak bu makalenin kullandığı sinyal.
- Bizde olup onlarda olmayan: T_l = 0 varsayımı → bizde T_l = mgℓ sinθ, açıyla değişen bir yük torku. Tek çalışma noktası → bizde açı ekseni boyunca harita.
- Kaynakçasında takip edilecekler: **[9] Esbrook, Tan, Khalil 2014 IEEE TAC, "Self-excited limit cycles in an integral-controlled system with backlash"** (teorik açıdan önemli, integral eylem + boşluk; bizim PI kontrolcümüzle doğrudan ilgili); [8] Hu ve ark. 2014 Asian J. Control (yarı/tam/çift kapalı çevrim asimptotik analizi); [11] Wang 2016 IECON (aynı grubun önceki çalışması); [22] Szabat, Orlowska-Kowalska 2007 TIE (iki kütle, ek geri beslemeli PI); [23] Kang 2011 IJCAS (DOB boşluk telafisi); [24] Horng ve ark. 2006 TIE "Rejection of limit cycles induced from disturbance observers in motion control" (**DOB'un kendisinin limit cycle üretmesi**, bizim gözlemci kısmıyla doğrudan ilgili).

## Yu, Tang — Limited amplitude-disturbance observer control for backlash-containing electromechanical system (IEEE TIE, cilt 71, sayı 6, Haziran 2024; erken erişim 2023)

Dosya: `ieee/pdf/2023_TIE_limited_amplitude_DOB_backlash.pdf` · DOI 10.1109/TIE.2023.3290240 (künyede yıl 2024 yazılmalı)

- Sistem: triger kayışlı döner platform. 40 W BLDC, dişli kutusu 132:1, motor enkoderi + 26 bit yük enkoderi, 1 kHz örnekleme. Platform yatay düzlemde dönüyor; yerçekimi yok.
- Problem: DOB (bozucu gözlemcisi) boşluğu "dış bozucu" gibi tahmin edip telafi ediyor. Ancak hız sıfırdan geçerken (yön değişimi) boşluk eşdeğer kazancı 0 ile k₀ arasında aniden sıçrıyor (Denk. 13). Bu sıçrama DOB çıkışında **telafi sivrileri** (spike) üretiyor. Q filtresinin bant genişliği artırılınca G(jω) eğrisi −1/N(A) eğrisini kesiyor ve **DOB'un kendisi limit cycle üretiyor** (Şekil 6: bant genişliği büyüdükçe salınımın genliği ve frekansı artıyor).
- Yöntem (LADOB): Q filtresinin arkasına doyum (saturation) fonksiyonu ekleniyor; "önce frekansla, sonra genlikle süzme". Doyumun tanımlama fonksiyonu E(A) büyük genlikleri bastırıyor, böylece Q bant genişliği kararlılık bozulmadan artırılabiliyor. Doyum eşiği a'nın seçimi için kural veriliyor (dE/du analizi).
- Deney: sinüs ve rampa takibi ile sabit konum. PI / DOB / LADOB karşılaştırması; yön değişimindeki sivriler belirgin şekilde azalıyor. En iyi değerler 30 Hz Q bant genişliği ve eşik 80. Bant genişliği arttıkça gürültü sınır koyuyor.
- **Girişte geçen kritik cümle (s. 5960):** boşluk dinamiğini değiştiren etkenler arasında "**ağırlık merkezi** (center of gravity) ve dönme odağı" sayılıyor. Yani ağırlık merkezinin boşluk dinamiğini değiştirdiğini kabul ediyorlar, ama incelemiyorlar ve sistemleri yatay düzlemde. Makalemizde "literatürde değinilmiş ama incelenmemiş" diye alıntılanabilir.
- Bizimle ilişkisi: gözlemci tarafında en yakın güncel çalışma. Sun 2025 TAES ile aynı mesajı veriyor: **gözlemci kazancı/bant genişliği artınca boşlukla etkileşip limit cycle üretebiliyor**, tanımlama fonksiyonuyla öngörülebiliyor. Önerdikleri ayar tek bir sabit eşik.
- Bizde olup onlarda olmayan: yerçekimli düşey kolda boşluk geçişi açıya bağlı. 90° civarında yerçekimi dişliyi bastırdığı için boşluk geçişi (ve DOB sivrisi) seyrek; 0° ve 180°'de sık. Dolayısıyla **en uygun Q bant genişliği ya da doyum eşiği açıya bağlı olmalı**. Bu, "açıya göre ayarlanan gözlemci" fikrimizi destekliyor: sabit bir eşik yerine a(θ) ya da g(θ).
- Kaynakçada takip edilecekler: [27] (M(s)/P(s) ayrıştırmalı DOB yapısı); [28] (tam-kapalı çevrimde DOB bant genişliği sınırı); [31]–[33] doymalı doğrusal olmayan DOB'lar (peaking önleme); [13][14] değişken kazançlı anahtarlamalı kontrol.

## Esbrook, Tan, Khalil — Self-excited limit cycles in an integral-controlled system with backlash (IEEE TAC 2014, teknik not)

Dosya: `ieee/pdf/2014_Esbrook_Tan_Khalil_TAC_integral_backlash_limit_cycle.pdf` · DOI 10.1109/TAC.2013.2281859

- Sistem: soyut. n boyutlu doğrusal tesis, girişinde bir "play operator" (boşluğun matematiksel modeli, yarıçap r), durum geri beslemesi + **integral kontrol**. Fiziksel düzenek yok; yalnızca simülasyon.
- Yöntem: tanımlama fonksiyonu YERİNE kesin çözüm. Sistem iki modlu anahtarlamalı doğrusal sistem olarak yazılıyor: boşluğun içinde (A₁) ya da sınırında, yani temas halinde (A₂). Limit cycle'ın anahtarlama zamanları ve başlangıç durumu Newton–Raphson ile hesaplanıyor; kararlılık Poincaré dönüşümüyle belirleniyor. Tanımlama fonksiyonunun yaklaşık sonuçlarına karşı "kesin" sonuç veriyorlar.
- Limit cycle'ın oluşma mekanizması: boşluk içindeyken (A₁) sistem kararsız (integral birikiyor), temastayken (A₂) kararlı. Bu ikisi arasında gidip gelme sürekli salınım üretiyor. Yani **integral eylem + boşluk = kendiliğinden limit cycle**.
- Kanıtlanan özellikler:
  - Önerme 1: limit cycle genliği boşluk yarıçapı r ile **doğrusal** ölçekleniyor, periyot r'den bağımsız.
  - **Önerme 2: sabit bir referans y_r eklemek limit cycle'ı sadece koordinatta kaydırıyor; genliği ve periyodu değişmiyor.** Yani yerçekimsiz sistemde çalışma noktası limit cycle'ı hiç etkilemiyor.
  - Önerme 3: skaler örnekte tesis parametresi a büyüyünce genlik küçülüyor, frekans artıyor (doğrusal ölçek).
  - k_p → 0,5 olunca genlik hızla büyüyor ve sistem kararsızlaşıyor.
- **Bizim için en kritik nokta, makalenin çerçevesi:** Önerme 2 tam olarak yerçekiminin bozduğu şey. Onların sisteminde çalışma noktası değişse de dinamik aynı kalıyor. Bizim kolda ise referans açı θ₀ değişince yük tarafına mgℓ sinθ₀ kadar sabit bir tork geliyor. Bu tork dişliyi boşluğun bir kenarına bastırıyor (A₂ modunda tutuyor), yani sistemin hangi modda ne kadar kaldığını değiştiriyor. Koordinat kaydırmasıyla yok edilemez. Dolayısıyla "limit cycle çalışma noktasından bağımsızdır" sonucu yerçekimli kolda geçersiz. Makalemizin ana iddiası bu önermeye karşı-örnek olarak çok net kurulabilir.
- Ayrıca Önerme 1'deki doğrusal ölçek (genlik ∝ r) yerçekiminde bozulur. Yeni boyutsuz parametre ortaya çıkar: γ = mgℓ sinθ₀ / (K_s · r) (yük torku / boşluk kapatan yay torku). Limit cycle haritası bu parametreye göre çizilebilir.
- Yöntem olarak kullanılabilir: kaymalı tanımlama fonksiyonu yaklaşık kalacağı için, sonuçları bu makaledeki anahtarlamalı sistem + Newton–Raphson yöntemiyle "kesin" olarak doğrulamak makaleyi güçlendirir. PI kontrolcümüz (integral eylem) olduğu için bu çerçeve bize birebir uyuyor.
- Kaynakçasında takip edilecekler: [5] Macki, Nistri, Zecca 1992 (histerezisli sistemlerde periyodik salınımlar, harmonik denge); [6] Cavallo ve ark. 2005 TMECH (histerezisli eyleyicide limit cycle, tanımlama fonksiyonu + deney); [7] Mees, Bergen 1975 TAC "Describing functions revisited"; [8] Bergen, Chua, Mees, Szeto 1982 (tanımlama fonksiyonunun hata sınırları; DF'nin geçerliliğini savunmak için); [14] Girard 2003 (parçalı doğrusal sistemlerde limit cycle hesabı ve kararlılığı).

## Horng, Chou, Lee — Rejection of limit cycles induced from disturbance observers in motion control (IEEE TIE 2006)

Dosya: `ieee/pdf/2006_Horng_TIE_DOB_induced_limit_cycles.pdf` · DOI 10.1109/TIE.2006.885119

- Sistem: doğrusal motorlu konumlama tablası (Kollmorgen), lazer enkoder, 2 kHz. **Boşluğu bilerek dışarıda bırakmak için** vidalı mil yerine doğrusal motor seçmişler. Yani bu makalede boşluk yok.
- Problem: sistem hedefe yaklaşınca hız komutu sıfıra iniyor, sinyal/gürültü oranı düşüyor. Bu sırada DOB, **enkoder ve DAC nicemlemesinin** (kuantalama) yarattığı hataları "bozucu" sanıp düzeltmeye çalışıyor ve sürekli bir limit cycle üretiyor.
- Yöntem: ayrık zamanlı sistemlerde sıfır-girişli limit cycle yokluğu için Claasen ve ark. 1975 teoremini (Parseval + Hermitian matris negatif tanımlılığı) uyguluyorlar. Yeter koşul (Denk. 16): her frekansta |P(z) + B*(z)| < 2. Bu koşulu sağlayan kazançlar sistemi çok yavaşlattığı için, hızlanma–yavaşlama fazından sonra kazançları doğrusal biçimde ayarlayan basit bir uyarlamalı mekanizma ekliyorlar: hareket sırasında hızlı kazanç, durunca "limit cycle'sız" kazanç.
- Kobayashi'nin "ters tesis kutbunu z = −1'den içeri çek" önerisini test ediyorlar: genliği azaltıyor ama yok etmiyor; kutbu 0,98'e taşımak gerekiyor.
- Deney: kalıcı hata %85 azalıyor; DOB'lu orijinal sistemdeki saf harmonik limit cycle uyarlamayla kayboluyor.
- Bizimle ilişkisi, **deney tasarımı için önemli bir uyarı**: bizim düzenekte AS5600 12 bit (≈0,088°), motor enkoderi sınırlı çözünürlüklü, PWM de nicemli. DOB eklediğimizde nicemleme tek başına bir limit cycle üretebilir. Bu durumda gördüğümüz salınımın **boşluktan mı nicemlemeden mi** geldiğini ayırmamız gerekir. Ayırt edici test: nicemleme kaynaklı limit cycle açıdan bağımsız olmalı, boşluk kaynaklı olan ise açıya (yerçekimine) bağlı. Açı taraması bu ayrımı kendiliğinden yapıyor; bu, makalede bir kontrol deneyi olarak yazılabilir.
- Bizim için kullanılabilir: "hareket sırasında / dururken farklı kazanç" fikri bizim "açıya göre ayarlanan gözlemci" fikrimizin basit bir öncülü. Onlarda ayar zamana göre, bizde açıya göre olacak.
- Kaynakçasında takip edilecekler: [8] Kobayashi ve ark. 1996 AMC (DOB + ters tesis kutbu limit cycle); **[9] Fischer, Tomizuka 1996 AMC: x–y tablasında kaplin esnekliği ve boşluğun DOB ile limit cycle yarattığını raporluyor** (boşluk + DOB + limit cycle'ın deneysel ilk raporlarından); [10] Claasen ve ark. 1975 (ayrık zamanlı limit cycle yokluk ölçütü); [11] Olsson, Åström 2001 IEEE TCST "Friction generated limit cycles" (sürtünme + integral → limit cycle; bizim düzenekte sürtünme de olacağı için mutlaka okunmalı).

## Olsson, Åström — Friction generated limit cycles (IEEE TCST 2001)

Dosya: `ieee/pdf/2001_Olsson_Astrom_TCST_friction_generated_limit_cycles.pdf` · DOI 10.1109/87.930974

- Sistem: esnek servo (motor + esnek mil + yük; Lund laboratuvar düzeneği), yalnızca motor tarafında sürtünme var. Coulomb + statik sürtünme (stiction) modeli. Kontrolcü durum geri beslemesi + integral + gözlemci; tasarım tek bir parametreyle (Butterworth yarıçapı ρ) değiştiriliyor. Yalnızca simülasyon (önceki deneyleri yeniden üretiyor).
- Bulgu: aynı sistemde **sadece kontrolcü ayarı değişince** nitelikçe farklı limit cycle'lar çıkıyor:
  - ρ = 10: limit cycle yok
  - ρ = 11: yapışmalı (stick-slip) limit cycle; hız bir süre sıfırda kalıyor
  - ρ = 12 ve 15: yapışmasız, röle tipi salınım; sürtünme ±F_C arasında anında geçiyor, 15'te neredeyse sinüs
  - Mekanizma: kontrolcü (integral eylem) kararsız bir döngü kuruyor, sürtünme onu sınırlıyor.
- Limit cycle türleri: **tek (odd)** salınım = iki yönlü, denge etrafında simetrik (integral kontrollü konum kontrolünde tipik); **çift (even)** salınım = tek yönlü (stick-slip gibi).
- Yöntem: tanımlama fonksiyonu yapışmalı durumda yetersiz kalıyor. Yapışma ve kayma fazlarını ayrı doğrusal sistemler olarak yazıp faz sürelerini (h₁, h₂) Newton–Raphson ile buluyorlar; kararlılığı Poincaré dönüşümünün Jacobian'ıyla belirliyorlar. Esbrook 2014'ün boşluk için yaptığının sürtünme karşılığı.
- Bizimle ilişkisi, **sürtünmeyi boşluktan ayırmak** için:
  1. Ucuz dişli kutusunda (JGA25-370 gibi) sürtünme yüksek olacak. Gördüğümüz salınımın bir kısmı sürtünme + PI kaynaklı olabilir.
  2. Ayırt edici: sürtünme kaynaklı limit cycle yerçekiminden büyük ölçüde bağımsız (sürtünme her açıda var). Boşluk kaynaklı olan ise açıya bağlı. Yine açı taraması ayırıyor. (Ufak bir istisna: yerçekimi dişli dişlerindeki normal kuvveti artırdığı için dişli içi sürtünme 90°'de biraz artabilir. Bu ikinci derece bir etki, not edilmeli.)
  3. Makale için ilginç bir soru: yerçekimi boşluğa ön kayma eklediğinde limit cycle **tekten çifte** (simetrik iki yönlüden tek yönlüye) dönüşebilir mi? Açı 0°'dan 90°'ye giderken dişli önce iki yöne tam salınıyor, sonra sadece bir kenara vurup geri dönüyor olabilir. Bu geçiş deneyde θ_d (motor − kol açısı) sinyalinin simetrisinden ölçülebilir; yeni bir gözlem olabilir.
- Kaynakçasında takip edilecekler: [1] Wallenborg, Åström 1988 "Limit cycle oscillations in high performance robot drives" (robot tahrikinde limit cycle; tam bizim alan); [3] Tsypkin 1984 (röle sistemleri, Tsypkin yeri); [5] Åström 1995 "Oscillations in systems with relay feedback"; [6] Atherton 1975 "Nonlinear Control Engineering—Describing Function Analysis and Design" (kaymalı/çok girişli tanımlama fonksiyonunun standart kaynaklarından); [8] Olsson 1996 doktora tezi (sürtünmeli kontrol sistemleri); [9] Abelson 1996 (sürtünmenin ters sarkaç dengelemesine etkisi).

## Fischer, Tomizuka — Application and comparison of alternative position sensors in high-accuracy control of an X-Y table (IEEE AMC 1996)

Dosya: `ieee/pdf/1996_Fischer_Tomizuka_AMC_position_sensors_XY_table.pdf` · DOI 10.1109/AMC.1996.509298

- Sistem: yarı iletken tel bağlamada kullanılan x–y tablası (tek eksen). DC motor + kaplin + vidalı mil (boşluk ≈ 1 µm). İki sensör: motorda enkoder (1,25 µm) ve tablada lazer interferometre (5 nm). Yatay eksen.
- Kontrolcü: hız döngüsünde DOB (3. dereceden binom Q filtresi, tek parametre τ) + PD konum + ZPETC ileri besleme + isteğe bağlı sürtünme telafisi. **Konum döngüsüne bilerek integral konmamış**, çünkü "kalıcı rejime yaklaşırken limit cycle'a yol açabilir" (Esbrook 2014 ve Olsson 2001'in bulgularının pratikteki karşılığı).
- Bulgular (tamamen deneysel, analitik değil):
  - Yalnızca motor enkoderiyle (çakışık, collocated) küçük τ'da (yüksek DOB bant genişliğinde) limit cycle var; τ artınca kayboluyor. Burada baskın etken nicemleme (Horng 2006 ile uyumlu).
  - Tabla sensörüyle (çakışık olmayan, non-collocated) τ ≤ 2,4 ms'de "şiddetli limit cycle"lar oluşuyor. Sebep: kaplin esnekliği ve boşluk artık ileri yolda, yüksek frekansta model hatası büyüyor. Kendi ifadeleriyle bu limit cycle'ları analitik incelemek "zor". Wang 2017'nin tam-kapalı çevrim sonucunun 20 yıl önceki deneysel karşılığı.
  - **Boşluğun başlangıç konumu önemli (Şekil 11–13):** hareket başlarken dişli boşluğun hangi kenarında duruyorsa davranış ona göre değişiyor. Boşluğun "içinde" başlarsa motor önce yalnızca kendini hızlandırıyor, sonra yüke çarpıyor; "bastırılmış" başlarsa bütün kütle baştan bağlı. Konum hatasının ilk sivrisi buna göre farklı.
  - Yön değişiminde boşluk gerçek statik sürtünmeyi azaltıyor; sürtünme telafisi aşırı telafi yapıyor. Çözüm olarak yön değişiminde telafi %20'ye düşürülmüş.
- Bizimle ilişkisi:
  1. Şekil 13'teki "boşluğun başlangıç kenarı" bizim kolda **yerçekimi tarafından belirleniyor**: 90° civarında dişli hep aşağı yönde bastırılı, yani hep aynı kenarda; 0° ve 180°'de kenar belirsiz. Yani onların rastlantısal bir başlangıç koşulu olarak gördüğü şey bizim sistemde açıyla belirlenen sistematik bir durum.
  2. "Sürtünme telafisini yön değişiminde azalt" gözlemi bizde de geçerli olacak. Ayrıca yerçekimi kolu taşıdığı için yön değişiminin kendisi de açıya bağlı (90°'de yukarı ve aşağı hareketler çok farklı yüklü).
  3. Deney tasarımı: kol milindeki AS5600 = çakışık olmayan sensör. Bu makale ve Wang 2017, DOB bant genişliğini bu konfigürasyonda düşük tutmamız gerektiğini, ya da limit cycle'ı görmek istiyorsak tam bu ayarı tarayabileceğimizi gösteriyor.
- Kaynakçasında takip edilecekler: [2] Endo, Tomizuka, Hori 1993 ACC (DOB + PD + ZPETC yapısının kaynağı); [4] Lee 1994 doktora tezi; [6] Armstrong-Hélouvry, Dupont, Canudas de Wit 1994 Automatica, sürtünme modelleri anketi (sürtünme modeli seçimi için standart kaynak).

## Márton, Lantos — Friction and backlash induced limit cycles in mechanical control systems (ECC 2009)

Dosya: `ieee/pdf/2009_7075004_Friction_and_backlash_induced_limit_cycles_in_mechanical_con.pdf` · DOI 10.23919/ECC.2009.7075004

- Sistem: soyut. Motor + dişli (oran 5, boşluk 0,001 rad) + yük; Stribeck sürtünmesi; PID konum kontrolü, sabit referans. **Yay (esneklik) yok**, iki kütle doğrudan dişliyle bağlı. Yalnızca Simulink simülasyonu.
- Model: iki mod. Temas modu (CM): motor ile yük birlikte, eylemsizlik J_M + J_L/K_G². Boşluk modu (BM): ayrı, yük serbest (J_L q̈_L = 0), motor eylemsizliği yalnızca J_M. Mod geçiş koşulu (Denk. 4): hız işareti ve konum farkının ±β olması. Yük tarafında hiçbir dış tork yok, **yerçekimi yok**.
- Analiz: sürtünme sıfır hız civarında doğrusallaştırılıyor (Stribeck eğimi negatif sönüm gibi davranıyor). Kapalı çevrim karakteristik denklemi (s + γ)(s² + ω²) biçimine zorlanınca **limit cycle koşulu** çıkıyor (Denk. 14): K_P·T_D + F_V − (F_S − F_C)/q̇_S = J / T_I. Salınım frekansı ω² = K_P / J. Koşul iki modda farklı, çünkü J farklı.
- Ek: limit cycle içinde sinyallerin kaotik olduğunu iddia ediyorlar (Lyapunov üssü > 0, korelasyon boyutu < 2). T_D değiştikçe sistem geniş bir aralıkta limit cycle'da kalıyor.
- Değerlendirme: yaklaşım kaba (doğrusallaştırılmış model, Gershgorin daireleri, deney yok). Ama iki şey bizim için yararlı:
  1. **"İki modda farklı eylemsizlik" fikri**: bizim kolda yerçekimi temas modunda kalma süresini açıya göre değiştirdiği için etkin eylemsizlik de, dolayısıyla limit cycle frekansı da açıya bağlı olmalı. Deneyde **frekansın açıyla kayması** ölçülebilir bir imza olabilir: 90°'de (hep temasta) frekans √(K_P / (J_M + J_L/N²))'ye yakın, 0°'de (sık sık boşlukta) daha yüksek.
  2. Sürtünme + boşluk + integralin birlikte ele alındığı az sayıdaki çalışmadan biri. Bizim donanımda bu üçü birlikte olacak.
- Kaynakçasında takip edilecekler: **[9] Wang, Liu, Meng 1999 IEEE SMC, "A study of limit cycles and chaotic motions of a single-link robot manipulator during slow motion"**: tek eklemli kol! Yerçekimini içerip içermediği kontrol edilmeli, en yakın rakip olabilir. [3] Barreiro, Baños 2006 Automatica (boşluklu sistemlerde giriş-çıkış kararlılığı); [8][10] Hensen ve ark. 2002/2003 (sürtünme kaynaklı "hunting" limit cycle'ları, olay eşleme yöntemi); [14] Putra, Nijmeijer, van de Wouw 2007 Automatica (sürtünmenin eksik/fazla telafisi); [16] Tjahjowidodo ve ark. 2007 MSSP (boşluklu sistemlerde kaotik yanıt, deneysel).

## Wang, Liu, Meng — A study of limit cycles and chaotic motions of a single-link robot manipulator during slow motion (IEEE SMC 1999)

Dosya: `ieee/pdf/1999_Wang_Liu_Meng_SMC_single_link_limit_cycles_chaos.pdf` · DOI 10.1109/ICSMC.1999.825378

- Sistem: "rijit tek eklemli **düzlemsel** robot kolu" (yatay düzlem). Model I_c θ̈ + r θ̇ + τ_f = τ; **yerçekimi terimi yok, boşluk yok**, yalnızca eklem sürtünmesi (Coulomb + Stribeck + viskoz). Yalnızca simülasyon, 4 sayfalık bildiri.
- Analiz: Coulomb sürtünmesinin tanımlama fonksiyonu N = 4j/(πA) (sanal eksende) ile PID altında kararlı limit cycle ispatı; ω = √(k_p / I_c). Viskoz sürtünme katsayısı negatife çekilince (Stribeck etkisi) sanal eksen yakınında kaotik bölge (Poincaré haritası).
- Değerlendirme: zayıf, ama **"tek eklemli kol + limit cycle + tanımlama fonksiyonu" başlığını taşıyan bir çalışmanın bile yerçekimini modelden çıkardığını** gösteriyor. Makalemizde "tek eklemli kollarda limit cycle çalışmaları yerçekimini ya düzlemsel varsayımla yok sayıyor ya da tamamen telafi edilmiş kabul ediyor" cümlesine kaynak olur.
- Rakip değil; atıf olarak kullanılabilir.

## Malik, Malik, Munawar — Parameter estimation of a single-link robotic manipulator in presence of dead-band and dead-zone (IEEE IC4 2009)

Dosya: `ieee/pdf/2009_4909162_Parameter_estimation_of_a_single_link_robotic_manipulator_in.pdf` · DOI 10.1109/IC4.2009.4909162

- Sistem: kendi yaptıkları tek eklemli kol. DC motor + **plastik dişliler** (iki kademe, toplam 14:84; her kademede belirgin boşluk), kol ucunda yük kütlesi, son dişli milinde 2500 PPR enkoder, 2 ms örnekleme. **Kol yatay düzlemde** hareket ediyor; model ω̇ + bω = cτ, yerçekimi terimi yok.
- İki doğrusal olmama: (1) "dead-band": uygulanan ile gerçek PWM görev oranı arasındaki fark (sürücü kaynaklı); (2) "dead-zone": dişli boşluğu, tork tersinmesinde (Şekil 1, histerezis biçimli).
- Yöntem: kontrol değil, **parametre tanılama**. Önce sabit hızda (±25, ±35 PWM) dead-band ve b/c oranı; sonra kare dalga girişte **boşluktan etkilenmeyen veri parçalarını seçip** (Şekil 3: yön değişimindeki kısımlar atılıyor) doğrusal olmayan en küçük kareler ile b.
- Bizimle ilişkisi:
  1. Donanım olarak bize en yakın düzenek: ucuz plastik dişli, DC motor, kol milinde enkoder. "Ucuz donanımda boşluk büyük ve ölçülebilir" iddiamızı destekliyor.
  2. Tanılama stratejileri işimize yarar: **sürücünün PWM ölü bandı** (TB6612FNG'de de olacak) ayrıca tanılanmalı; yoksa boşlukla karışır. Ayrıca "yön değişimi segmentlerini at, kalanla parametre bul" yöntemi bizim J, b tanılamamız için doğrudan kullanılabilir.
  3. Yine yatay düzlem: yerçekimi bilerek dışarıda. Bu, düşey kolda yerçekiminin tanılamayı da değiştireceğini gösteriyor: düşey kolda kare dalga deneyinde 90° civarında yön değişimi olsa bile dişli boşluğu geçmeyebilir, yani "atılacak segment" açıya bağlı olur.
- Kaynakçada takip edilecek: [16] Malik ve ark. 2008 IASTED (yalnızca boşluklu önceki sürüm); [8] Tao, Kokotović 1995 IEEE TAC, "Adaptive control of systems with unknown output backlash" (boşluk telafisinin klasik kaynağı).

## Jung, Kong, Lee, Ahn, Kim — Backlash compensation for a humanoid robot using disturbance observer (IEEE IECON 2004)

Dosya: `ieee/pdf/2004_1432128_Backlash_compensation_for_a_humanoid_robot_using_disturbance.pdf` · DOI 10.1109/IECON.2004.1432128

- Sistem: 22 serbestlik dereceli insansı robotun tek eklem modülü. Maxon dişli DC motor (190:1), konik dişli; motorda 1000, çıkış milinde 512 darbe/tur enkoder. Deney **ayak bileğinin yaw (düşey eksen) hareketi** üzerinde; yani yine yerçekimi torku yok. Yük yalnızca eylemsizlik olarak ekleniyor (J_L: 0,7×10⁻⁶ → 0,0166 kg·m²).
- Kontrolcü: PD + DOB; Q(s) 4. dereceden alçak geçiren filtre, kesim frekansı elle seçilmiş. Teorik analiz yok.
- Bulgular:
  - Yüksüzken limit cycle yok; yük (eylemsizlik) takılınca simülasyonda 21,27 Hz, 0,0097 rad genlikli limit cycle; deneyde de salınım görülüyor (Şekil 13–14). DOB ile kayboluyor (Şekil 15–16).
  - **İlginç ölçüm:** iki enkoderle ölçülen boşluk yüksüzken 0,00059 rad, yüklüyken 0,0158 rad (≈27 kat). Yazarlar açıklamıyor. Muhtemel sebep: yüksüzken çıkış milini taşıyan bir tork olmadığı için dişliler boşluğu geçmeden de birlikte dönüyor (sürtünme ya da hafif temasla), yük eylemsizliği ise boşluğun tamamen açılmasını sağlıyor. Yani **"ölçülen boşluk" sabit bir mekanik sayı değil, yük koşuluna bağlı.**
- Bizimle ilişkisi:
  1. Bu, yerçekimi için de geçerli olmalı: kolumuzda ölçülen etkin boşluk açıya bağlı çıkabilir (90°'de dişli bastırılı, boşluk "kapalı"; 0°'de açık). Deneyde boşluğu tek bir açıda ölçüp sabit almak hata olur; **boşluk tanılaması birkaç açıda tekrarlanmalı**. Bu da makalede kendi başına bir bulgu olabilir.
  2. İki enkoderli ölçüm düzeni bizim plana (motor enkoderi + AS5600) birebir uyuyor.
  3. Zayıf yanı: analiz yok, Q filtresi deneme-yanılma. Bizim tanımlama fonksiyonu analizimiz bu boşluğu doldurur.
- Kaynakçada takip edilecekler: [9][10] Yamada, Komada, Ishida, Hori 1996 (yüksek dereceli DOB'lu servo sistem analizi); [4][5] Shahruz 2000/2002 (indirildi: 2000_868924).

## Kim, Kang, Kim, Huh — Implementation of disturbance observer for compensating backlash (ICROS-SICE 2009)

Dosya: `ieee/pdf/2009_5334346_Implementation_of_disturbance_observer_for_compensating_back.pdf` · (ICCAS-SICE 2009, IEEE Xplore 5334346)

- Sistem: insansı robotun **diz eklemi**; motor + konik dişli + yük, boşluk ölü bölge modeliyle (Denk. 2–3). Diz bir pitch eklemi, yani gerçekte yerçekimi yüklü. Ama yük modeli P₄ = 1/(J_L s² + f_L s): **yerçekimi terimi yok**. Yalnızca simülasyon; deney "gelecek çalışma".
- Konu: DOB'un gerçek donanıma uygulanması (yöntem değil, uygulama notu):
  1. **Enkoder nicemlemesi DOB'u kararsız yapıyor.** Çözüm iki ayrı Q filtresi: Q₁ bozucu kestirimi için geniş bantlı (1/(0,0003s+1)²), Q₂ ölçüm gürültüsünü bastırmak için dar bantlı (1/(0,05s+1)³). Gürültü bastırılmadan telafi sinyali ±10⁶ V'a çıkıyor ve sistem ıraksıyor; bastırılınca ±4 V.
  2. Yüksek dereceli DOB transfer fonksiyonlarını düşük frekansta genliği koruyan model indirgemeyle (Hsia 1972) 2. ve 4. dereceye indiriyorlar.
  3. Eşleştirilmiş z-dönüşümüyle 5 ms örneklemede ayrık zamana çeviriyorlar.
- Sonuç: DOB ile gecikme ve tepe değeri yalnızca ≈%5–7 iyileşiyor (sinüs takibi). Etki küçük.
- Bizimle ilişkisi:
  1. **"Yerçekimi yüklü eklem + boşluk + DOB" üzerine olup yerçekimini modellemeyen** ikinci örnek (bu sefer gerçek bir diz eklemi). Makalemizde "gerçekte yerçekimi yüklü eklemlerde bile analiz yerçekimsiz yapılıyor" iddiasının somut kanıtı.
  2. Bizim ESP32 uygulamamız için pratik bir rehber: AS5600 nicemlemesine karşı iki Q filtresi yapısı, model indirgeme ve ayrıklaştırma adımları doğrudan kullanılabilir. (Horng 2006'daki nicemleme uyarısıyla tutarlı.)
- Kaynakçada takip edilecekler: [1] Odai, Hori 2001 "Speed control of two-inertia system with gear backlash based on gear torque compensation"; [2] Merzouki, Cadiou 2005 CEP (boşluğun kestirimi); [4] Ohnishi 1987 (DOB'un orijinal kaynağı).

## Shahruz — Performance enhancement of a class of nonlinear systems by disturbance observers (IEEE/ASME TMECH 2000, kısa makale)

Dosya: `ieee/pdf/2000_868924_Performance_enhancement_of_a_class_of_nonlinear_systems_by_d.pdf` · DOI 10.1109/3516.868924

- Fikir (teorik çerçeve): çıkışı iki paralel doğru G₊ ve G₋ arasında kalan doğrusal olmayanlıklar (ölü bölge, boşluk, histerezis) "doğrusal kısım K·u + sınırlı bozucu d(t)" olarak ayrıştırılabilir (Denk. 1–5). Böylece doğrusal olmayan sistem, sınırlı bir bozucusu olan doğrusal sistem gibi ele alınabiliyor. DOB bu d'yi kestirip iptal edince sistem "doğrusal davranıyor".
- Örnekler (yalnızca simülasyon):
  1. DC motor + ölü bölge, PI kontrol: DOB ile yanıt boşluksuz sistemle örtüşüyor.
  2. **Dişli boşluklu ters sarkaç**, doğrusallaştırılmış P(s) = 1/(s² − 1), öncül-ardıl kompanzatör: boşluk yüzünden kalıcı limit cycle (büyüyerek oturan salınım); DOB (τ = 3 ms) ile yok oluyor. Ölçüm gürültüsü eklenince de çalışıyor.
- Bizimle ilişkisi:
  1. Literatürde "DOB boşluğu ve limit cycle'ı yok eder" iddiasının kaynağı bu makale; 2004 insansı robot ve Kim 2009 buna atıf yapıyor. Sun 2025, Yu–Tang 2024 ve Horng 2006 ise tersini gösteriyor (DOB bant genişliği artınca kendisi limit cycle üretiyor). Makalemizde bu iki tarafı karşılaştırmak iyi bir giriş olur.
  2. **Ters sarkaç örneği tam bizim 180° (dik yukarı) durumumuz:** P(s) = 1/(s² − 1)'deki "−1" yerçekiminin üst dengede verdiği kararsızlaştırıcı yay etkisi. Bu noktada yerçekimi torku sıfır (sin 0 = 0), yani dişliyi bastıran bir ön yük yok, boşluk tam etkin. Kollár 2002 ile birlikte "üst dengede boşluk → limit cycle" sonucunun ikinci kaynağı. Ama ikisi de **tek bir açıda** çalışıyor; açı değişince ne olduğu sorulmamış.
  3. **Teorik açıdan önemli bir uyarı:** Shahruz'un ayrıştırmasında d(t)'nin ortalaması sıfır varsayılmıyor ama örneklerde simetrik. Bizim kolda yerçekimi torku mgℓ sinθ₀ de DOB'un gördüğü "bozucu"nun içine giriyor (Q(0) = 1 olduğu için DOB sabit bileşeni de iptal eder). Yani 90°'de DOB'un kestirdiği sinyalin büyük kısmı yerçekimi (DC), küçük kısmı boşluk; 0°'de ise neredeyse tamamı boşluk. Bu, DOB'un **açıya göre farklı bir iş yaptığı** anlamına geliyor. "Açıya göre ayarlanan gözlemci" fikrimizin teorik gerekçesi olarak kullanılabilir: yerçekimi ileri besleme ile ayrıca telafi edilirse DOB yalnızca boşluğa ayrılabilir.
- Kaynakçada takip edilecekler: [13] **Kodama, Shirakawa 1968 IEEE TAC, "Stability of nonlinear feedback systems with backlash"** (boşluklu geri beslemeli sistemlerin kararlılığının klasik kaynağı); [14] Shahruz, Hauser 1989 ACC (doğrusal + sınırlı ayrıştırmanın ilk hali); [3] Umeno, Hori 1991 TIE (DOB tasarımının temel kaynağı); [10] Iwasaki ve ark. 1999 TMECH (DOB ile doğrusal olmayan sürtünme telafisi).

## ⚠ Sun, Li, Chen, Shi, Jiang — Dual-motor coordination for high-quality servo with transmission backlash (IEEE TIE, cilt 70, sayı 2, 2023)

Dosya: `ieee/pdf/2023_9732257_Dual_Motor_Coordination_for_High_Quality_Servo_With_Transmis.pdf` · DOI 10.1109/TIE.2022.3156154

**Bugüne kadar bulunan EN YAKIN çalışma.** Yerçekimi modelde var ve deney düşey düzlemde.

- Sistem: ağır yük taşıyan, **düşey düzlemde salınan kol** (heavy-duty swinging arm servo; askerî/endüstriyel). İki PMSM, iki ayrı dişli kademesiyle aynı yükü sürüyor; boşluk büyük (b₁ = 3,63°, b₂ = 3,37°; bilerek büyütülmüş). Yük: 9 kg, 0,1 m kol. Model (Denk. 1): J_L θ̈_L = T_sh1 + T_sh2 − C_L θ̇_L − **T_L(θ_L), T_L = M_L sinθ_L** (yerçekimi). Yükte enkoder, motorlarda resolver; TMS320F28379 DSP, 200 µs döngü.
- Görev: kolu **0°'dan (düşey) 90°'ye (yatay)** konumlamak, yani hedef açı yerçekimi torkunun EN BÜYÜK olduğu açı. Deneyler hep bu tek hedefte.
- **Kritik gözlem:**
  - Konum kazancı düşükken (K_p = 20, yavaş geçiş) salınım yok.
  - K_p = 50'de kol 90°'ye varınca **≈5° genlikli, 9 Hz salınım** var (MPC ile 13 Hz). Genliği boşluk sınırlıyor ve akustik vuruntu duyuluyor.
  - Yani **en büyük yerçekimi ön yükünde bile, kazanç yüksekse boşluk kaynaklı salınım oluşuyor.** Yorum: dinamik tork genliği yerçekimi torkunu (≈ 9 kg × 9,81 × 0,1 m ≈ 8,8 N·m) aşınca dişli boşluğun öbür tarafına geçiyor.
  - Kendi sonuçları: "titreşimi hızlı geçiş süreci uyarıyor".
- Çözüm: hedefe yaklaşınca (85°'den sonra) iki motora **ters yönlü sabit bir ön yük akımı** (i_co = 0,5–4 A) vererek dişlileri karşılıklı kilitlemek (yapay ön yük). Üstüne MPC + ESO. Ön yük kol durunca kademeli olarak geri çekiliyor (anma akımı 3,6 A olduğu için uzun süre tutulamaz). Sonuç: aşma 0,15°, kalıcı hata < 0,01°.
- **Yapmadıkları:**
  - Yerçekimini modele koymuşlar ama etkisini hiç tartışmıyorlar.
  - Açıya bağlı hiçbir analiz ya da deney yok; tek hedef açı (90°).
  - Tanımlama fonksiyonu analizi yok (kaynakçada Esbrook, Ghaffari, Wang 2017 var ama kullanmıyorlar).
  - Çift motor pahalı; tek motorlu ucuz sistem için bir öneri yok.
  - Yerçekiminin kendiliğinden bir ön yük gibi davrandığı, ya da yapay ön yükün açıya göre azaltılabileceği hiç söylenmiyor.
- **Bizim hipotezimize etkisi (ÖNEMLİ DÜZELTME):**
  1. "90°'de yerçekimi dişliyi bastırır, limit cycle oluşmaz" iddiası **koşulsuz doğru değil.** Bu makalenin deneyi, yüksek kazançta 90°'de bile salınım olduğunu gösteriyor. Ghaffari'den türettiğimiz eşik koşulu doğru çerçeve: limit cycle'ı belirleyen, **yerçekimi torku ile salınımın dinamik tork genliğinin oranı**. Bu oran hem açıya hem kontrolcü kazancına (ve boşluk büyüklüğüne, sertliğe) bağlı.
  2. Dolayısıyla makalemizin haritası tek eksenli (açı) değil, **iki eksenli** olmalı: (θ₀, K_p) ya da (θ₀, gözlemci bant genişliği) düzleminde "limit cycle var / yok" bölgeleri. Yerçekiminin etkisi, bu sınır eğrisinin açıyla nasıl kaydığı. Esbrook'un boyutsuz γ = mgℓ sinθ₀/(K_s·r) parametresi bu haritanın doğal ekseni.
  3. Bu makale aynı zamanda güçlü bir motivasyon: ağır sanayide **yapay ön yük için çift motor ve anma akımını aşan akımlar** kullanılıyor; yerçekiminin "bedava" ön yükünün nerede yeterli, nerede yetersiz olduğunu bilmek, ön yükü yalnızca gerektiği açıda ve gerektiği kadar uygulamayı mümkün kılar. Tek motorlu sistemde bunun karşılığı, açıya bağlı kazanç (ya da gözlemci) ayarlamasıdır.
  4. Makalemizde bu çalışma hem en yakın rakip hem de deneysel bir dayanak olarak alıntılanmalı: "Sun ve ark. (2023) T_L = M_L sinθ_L terimini modellemiş ve 90°'de 5°'lik limit cycle raporlamış, ancak yerçekiminin limit cycle üzerindeki açıya bağlı etkisini incelememiştir."
- Kaynakçada takip edilecekler: [6] Esbrook 2014 (okundu); [7] Cavallo ve ark. 2005; [13] Yadmellat, Kermani (MR eyleyicilerde limit cycle, sadece rezonans ve sönüme bağlı); [16] Yang ve ark. 2016 TMECH (şaft torku sınırlama + boşluk, DF tabanlı); [17] Masoud, Maas 2019 AIM; [22] çift motorda iki fazlı anti-boşluk (düşük maliyetli); [26] bias torkla aktif boşluk giderme + geri adımlama.

## Karim, Baumeister, Verl — Measurability of the dynamic behavior of gear backlash at industrial robots (IEEE M2VIP 2018)

Dosya: `ieee/pdf/2018_8600915_Measurability_of_the_dynamic_behavior_of_gear_backlash_at_in.pdf` · IEEE Xplore 8600915

- Sistem: KUKA KR500-3 MT endüstriyel robot (frezeleme bağlamında). Motor enkoderi, motor akımı, yük tarafında lazer-Doppler vibrometre, ivmeölçerler. Amaç kontrol değil, boşluğun dinamik etkisinin **ölçülebilirliği**.
- Simülasyon (Şekil 3–4, parametreler rastgele seçilmiş, nitel):
  - J_L/J_M büyüdükçe temas kapanmasının yük tarafındaki titreşimi sönümleniyor; 1:100'de neredeyse görünmüyor.
  - **Dış tork etkisi, doğrudan bizim konumuz:** "Sabit bir dış tork (yerçekimi) hareket yönüne ters ise, düşük dişli torklarında temas korunur; **dış tork mekanik bir ön yük gibi davranır**. Aksi halde dişlilerin ayrılmasını kolaylaştırır. τ_ext'in işaretine göre ayrılma noktaları salınım yörüngesinde yukarı ya da aşağı kayar." Yalnızca nitel bir şekil; analiz yok, limit cycle yok, kapalı çevrim yok.
- **Eski bir kaynağa işaret ediyor:** [6] S. Ahmad 1985 ICRA, "Second order nonlinear kinematic effects, and their compensation". Robot eksenlerinde boşluk telafisini **iki ölçütle** devreye sokuyor: (1) hareket yönü tersine dönmeli, (2) yeni hareket **yerçekimine karşı** olmalı. Ayrıca 1. eksen (düşey eksen) yerçekiminden etkilenmediği için orada yalnızca birinci ölçüt kullanılıyor. Yani **"robot eksenlerinde yerçekimi boşluğun ne zaman ortaya çıkacağını belirler" fikri 1985'ten beri endüstriyel telafide biliniyor** (statik konum hatası için).
- Deney: KUKA'da boşluk etkileri motor tarafı sinyallerinde (akım, enkoder) **ölçülemedi**; sürtünme ve yörünge planlayıcısının ivme darbeleri baskın. Yalnızca dolaylı uyarımla (başka eksen hareket ettirilerek) yük tarafı vibrometresinde dört seviyeli adım adım yer değiştirme görüldü. Ayrıca beklenmedik şekilde, robot dururken motor sabit bir akım çekiyor (kontrolcü dişliyi bir kenara mı yaslıyor, araştırılmamış).
- Bizimle ilişkisi:
  1. **Dürüstlük notunu güçlendiriyor:** "yerçekimi boşlukta ön yük gibi davranır" hem nitel olarak (bu makale) hem endüstriyel telafi kuralı olarak (Ahmad 1985) biliniyor. Makalemizde bunu açıkça kabul edip katkıyı netleştirmeliyiz: bilinen bir **statik/kinematik** gözlemi, **kapalı çevrim kararlılığına (limit cycle)** taşımak, açı–kazanç düzleminde nicel bir harita vermek ve gözlemci tasarımına bağlamak.
  2. Ölçüm uyarısı: motor tarafı sinyalleri boşluğu görmekte yetersiz kalabilir; **yük tarafı sensörü (bizde AS5600) şart**. J_L/J_M oranı büyükse (dişli oranı yüksek ⇒ yansıyan J_L küçük; dikkat!) etkiler değişir.
- Takip edilecekler: **[6] Ahmad 1985 ICRA** (IEEE'de olmalı, indirilmeli); [11] Yamada, Fujimoto, Terada 2016 ISIE (indirilenlerde var: 2016_7745054); [9] Lehmann ve ark. 2013 IFAC "clamping method" (iç sensörlerle boşluk tanılama); [4] Nordin, Galić, Gutman 1997 (boşluk modelleri).

## Padron, Yokokura, Ohishi, Miyazaki, Kawai — Evaluating the equivalence between nonlinear friction and backlash in two-inertia systems (IEEE AMC 2022)

Dosya: `ieee/pdf/2022_9729289_Evaluating_the_Equivalence_between_Nonlinear_Friction_and_Ba.pdf` · DOI 10.1109/AMC51637.2022.9729289

- Fikir: **sürtünme sıfır HIZDA, boşluk sıfır TORKTA tetiklenir.** Sürtünmedeki "yapış (stick) → kay (slip)" ile boşluktaki "ayrılma (disengagement) → yeniden kavrama çarpması (reengagement collision)" kontrol açısından birbirinin eşi. Aynı tasarım mantığı ikisine de uygulanabilir.
- Deney: iki ayrı düzenek (yağ keçeli dişli motor = sürtünme; boşluklu kaplin = boşluk), ikisinde de **tork sensörü**. DOB (sürtünme için) ve burulma DOB'u (TDOb, boşluk için); sıfırıncı ve birinci dereceden Q filtreleri.
  - Birinci dereceden gözlemci sıfırdan geçiş süresini kısaltıyor (ayrılma süresi 0,34 s → 0,21 s), ama çarpmayı büyütüyor.
  - Çözüm: "darbe torku bastırıcı" (ITS); burulma torkunun türevine sönüm ekleyerek etkin yay sertliğini düşürüyor. Çarpma torku 1,28 → 0,69 N·m.
- Yatay düzenekler, yerçekimi yok, limit cycle analizi yok.
- **Bizim için en değerli katkı, hipotezin tek cümlelik formülü:** boşluk iletilen torkun sıfırdan geçtiği anda devreye girer. Kolda iletilen tork ≈ mgℓ sinθ₀ (sabit) + dinamik tork (salınımlı). Sıfırdan geçiş ancak dinamik tork genliği |mgℓ sinθ₀|'yi aşarsa olur. Yani **yerçekimi, iletilen torkun sıfır geçişlerini açıya bağlı olarak engeller ya da serbest bırakır.** Bu, Ghaffari'nin ön yük gözlemi, Sun 2023'ün 90°'deki salınımı ve Wang 2017'nin "yüksüzken temas yok" gözlemiyle tutarlı; makalenin girişinde bu cümleyle kurulabilir.
- Ayrıca sürtünme ile boşluğu ayırmak için ek bir ölçüt veriyor: sürtünme olayları **hızın** sıfırdan geçtiği anlarda, boşluk olayları **iletilen torkun** sıfırdan geçtiği anlarda kümelenir. Deneyde (akım sensörü INA219 + iki açı sensörü) bu zamanlama ayrımı yapılabilir.
- Takip: [4] Yamada, Fujimoto 2019 IEEJ JIA (yük tarafı enkoderli hassas eklem torku kontrolü); [7] Padron ve ark. 2021 SAMCON (sürtünme–boşluk dualitesine dayalı kararlı burulma torku kontrolü).

## Yamada, Fujimoto, Terada — Joint torque control for backlash compensation in two-inertia system (IEEE ISIE 2016)

Dosya: `ieee/pdf/2016_7745054_Joint_torque_control_for_backlash_compensation_in_two_inerti.pdf` · DOI 10.1109/ISIE.2016.7745054

- Sistem: iki motorlu tezgâh; aradaki esnek kaplin dişli kaplinle değiştirilerek boşluk ekleniyor/çıkarılıyor; iki tarafta 20 bit enkoder, ayrıca tork sensörü (yalnızca doğrulama için). Yatay, yerçekimi yok. Karşı-rezonans 57 Hz, rezonans 71 Hz.
- **Boşluk tanılama yöntemi (bizim için hazır tarif):** motor tarafı hız kontrolünde, yükün motordan ayrıldığı an t₁ ile yeniden temas ettiği an t₂ arasında burulma hızını (ω_M − ω_L) integre et: 2ε = ∫(ω_M − ω_L)dt. Pratikte iki enkoderin t₁ ve t₂'deki açı farkı. Sonuç ε = 6,0 mrad. (Villwock–Pacas 2009 ve Yuki ve ark. 2012'ye dayanıyor.)
- Kontrol: eklem torkunu, iki enkoderden gelen burulma hızını kontrol ederek denetliyorlar (tork sensörü gerekmiyor; tork, reaksiyon kuvveti gözlemcisi RFOB ile kestiriliyor). Boşluk telafisi ileri beslemede ters ölü bölge modeliyle yapılıyor, ama türev aldığı için **telafi anında sivri akım** üretiyor. Çözümleri **sigmoid ile yumuşatılmış ters ölü bölge** modeli: sivri yok, gereken en büyük motor torku çok düşük.
- Bizimle ilişkisi:
  1. Boşluğu iki sensörle ölçme tarifi; Jung 2004'teki "ölçülen boşluk yüke bağlı" bulgusuyla birleştirince **farklı açılarda** uygulanmalı.
  2. "Yön değişiminde 0 N·m'ye yapışma + ardından çarpma titreşimi" (Şekil 9, 12) bizim düzenekte θ_d sinyalinde aranacak iz.
  3. Sigmoid yumuşatılmış ters model, ESP32'de ileri besleme telafisi denenirse kullanılabilir; yerçekimi ileri beslemesiyle birleştirilebilir.
- Takip: [8] Villwock, Pacas 2009 TIE (zaman alanında boşluk tanılama); [9] Yuki ve ark. 2012 IECON (PMSM'de çevrim içi boşluk tanılama); [7] Yamada ve ark. 2015 INDIN.

## Padron, Yokokura, Ohishi, Miyazaki, Kawai — Load-side acceleration control for geared motors with unknown backlash and nonlinear friction (IEEE IECON 2022)

Dosya: `ieee/pdf/2022_9969117_Load_Side_Acceleration_Control_for_Geared_Motors_with_Unknow.pdf` · DOI 10.1109/IECON49645.2022.9969117

- Sistem: dişli PMSM (50:1), boşluklu kaplin (2δ = 16 mrad), tork sensörü, yük enkoderi, ivmeölçer. Yatay, yerçekimi yok. Kontrolde yalnızca motor enkoderi ve tork sensörü kullanılıyor.
- İki yenilik:
  1. **VOFPIDO** (değişken dereceli kuvvet-konum bütünleşik DOB): yüksek dereceli DOB'u bir alçak geçiren + bant geçiren filtreler toplamı olarak yazıp, hıza bağlı anahtarlamayla gerektiğinde dereceyi artırıyor (sürtünmeyi hızlı telafi, gürültüye karşı sağlam).
  2. **BDDOb** (boşlukta devre dışı kalan DOB): ölçülen burulma torku |τ_s| < eşik olduğunda (yani dişli boşlukta) yük tarafı DOB'unun kestirim-telafi döngüsünü **kapatıyor**; temas gelince yeniden açıyor. Boşluk genişliğini bilmeye gerek yok. Böylece DOB boşluktaki "sahte bozucu"yu biriktirip çarpma anında patlatmıyor.
- Sonuç: deneyde boşluğu geçme süresi kısalıyor, ivme yanıtı hızlanıyor. Anahtarlamalı olduğu için kararlılık analizi yok ("gelecek çalışma").
- Bizimle ilişkisi:
  1. "Gözlemciyi boşluk durumuna göre ayarla" fikrinin **zamana/anlık torka bağlı** bir uygulaması. Bizim önerimiz bunun **açıya bağlı** öngörülü sürümü: yerçekimi |τ_s|'yi açıya göre sıfırdan uzak tutuyorsa (90° civarı) BDDOb neredeyse hiç devre dışı kalmaz; 0°/180° civarında sık sık kalır. Yani **açı, BDDOb anahtarının ne sıklıkla çalışacağını önceden söyler.** İkisi birleştirilebilir.
  2. Tork sensörü yerine bizde iki açı sensöründen θ_d (ya da INA219 akımı) ile "boşlukta mı" kestirimi yapılabilir.
  3. Kendi itiraflarıyla kararlılık analizi eksik; bizim tanımlama fonksiyonu + anahtarlamalı sistem analizimiz bu boşluğa da değer.

## Toplu not: kalan 11 IEEE makalesi (özet + sonuç + ilgili bölümler okundu, 18 Ekim)

Bu makalelerin hiçbirinde yerçekiminin açıya bağlı etkisi yok (pdftotext ile tam metinde "gravit" araması: 0 sonuç). Kısa notlar, bize değen yönleriyle:

**Gözlemci kazancını duruma göre değiştirenler (bizim "açıya bağlı gözlemci" fikrimizin öncülleri):**
- **2022_9959378, "Backlash oscillation suppression of servo system based on full-order terminal sliding mode control with variable-gain observer"** (IEEE): gözlemci kazancı, motor ile yük arasındaki **konum farkına** göre uyarlanıyor; boşluk bölgesindeyken kazanç düşürülüyor ("boşlukta büyük kazanç tutulursa motor ve yük şiddetle çarpışır"), dışında normal. + terminal kayan kip kontrol. Yalnızca simülasyon. → Padron 2022 BDDOb ile aynı aile: **anlık duruma bağlı anahtarlama**. Bizimki **açıya bağlı, önceden hesaplanabilir** zamanlama olacak. Makalede "değişken kazançlı gözlemciler [Padron 2022, bu çalışma, Sun 2025] anlık sinyale göre ayar yapıyor; yerçekimli kolda açı bu ayar için öngörülü bir bilgi sağlar" diye konumlanabilir.

**Ters sarkaç + boşluk (hepsi üst dengede, yani sıfır ön yük durumu):**
- **2010_5553538, Shibayama, Kroumov, Inoue, "Robust control of underactuated inverted pendulum system in presence of unknown disturbances"** (ICMIC 2010): arabalı sarkaç; boşluk **tekerlek–ray dişlisinde** ve arabanın sıfır noktası etrafında periyodik salınımına yol açıyor (deneysel, PI bastıramıyor). Gözlemci tabanlı sağlam kontrolle bastırılıyor. Sarkaç dik dengede.
- **2013_6579980, "Robust tracking performance and disturbance rejection for a class of uncertain nonlinear systems"** (IEEE): sabit tabanlı ters sarkaç, girişte boşluk; üst denge etrafında doğrusallaştırılmış (θ = 0 dik); DOB'u H∞ çok amaçlı en iyileme ile tasarlıyor. Simülasyon. "Boşluğun limit cycle'a yol açtığı biliniyor" diye anıyor.
- **2023_10252624, "Control of rotary inverted pendulum system driven by a servo-table with uncertain rod homing position"** (Purdue, eğitim düzeneği): ticari Quanser düzeneklerinin sürtünme, boşluk, kalibrasyon hatası gibi gerçek sorunları "gizlediğini", bu yüzden kendi düzeneklerini kurduklarını söylüyor. Ağırlık sürtünme ve esnek modlarda; boşluk yalnızca anılıyor. → **"Ucuz/kendi yapımı düzenek gerçek kusurları görünür kılar"** savımız için iyi bir atıf.
- Ortak sonuç (Kollár 2002, Shahruz 2000 ile birlikte): sarkaç-boşluk literatürü yalnızca dik dengeyi (sin θ ≈ θ, yerçekimi ön yükü sıfır) inceliyor; yatay ya da ara açılar hiç yok.

**Boşluk telafisi (ilgisi zayıf):**
- **2005_1460886, "Position control in the presence of unknown output backlash"** (SSST 2005): anten konumlama; motor konum/hız geri beslemesiyle hızlı iç döngü, motor-yük konum farkından yavaş dış döngü; boşluk genişliği bilinmeden kalıcı hatayı gideriyor. Simülasyon.
- **2007_4160843, "A new compensation technique for backlash in position control"**: iki kütle esnek sistem için anahtarlamasız doğrusal kontrolcü; Nordin–Gutman'ın "kesin boşluk modeli" ile simülasyon; boşluk genişliği gerekmiyor, yalnızca dişli oranı.
- **2019_8926953, "Backlash robotic systems compensation by inverse model based PID control"** (BUGO kaynak robotu, doğrusal eksen): ters boşluk modeli + PID; simülasyon + deney.
- **2023_10406931, "Robust ultra-local model control for single-axis servomechanism"**: vidalı mil + PMSM; ULMC + ESO + H∞; boşluk "belirsizlik"lerden biri olarak geçiyor.
- **2024_10927475, "Sliding-mode-based observer control for high-dynamic backlash rejection in dual-stage inertial stabilization system"** (ICCR 2024): Yu–Tang (LADOB) grubunun devamı; süper-büküm kayan kip gözlemci; yön değişimi sivrilerinde RMSE %35,5 azalıyor. Simülasyon.

**Boşluğun "işe yaradığı" ilginç bir örnek:**
- **2016_7793320, Yamada ve ark., "Proposal of high backdrivable control using load side encoder and backlash"** (IEEE): boşluk içinde yük tarafı motordan bağımsız boşta döndüğü için, dışarıdan itildiğinde yalnızca yük empedansı hissediliyor. Yük enkoderiyle motoru boşluğun ortasında tutarak geri sürülebilirliği artırıyorlar. → **Yerçekimli kolda bu yöntem 90°'de çalışmaz**: yerçekimi dişliyi hep bir kenara bastırdığı için "boşta dönme" yok. Yerçekiminin boşluğun hem zararlı hem yararlı etkilerini açıya göre değiştirdiğine bir örnek daha.

**Teleoperasyon:**
- **2013_6699787, "Compensation of backlash for teleoperated geared motor drives"** (IEEE): her eklemde iki özdeş dişli motor, ters yönlü torkla "bükülü" (twist) tutuluyor → aktif ön yük. Sun 2023'ün çift motor yaklaşımının dokunsal (haptik) versiyonu. Yatay.

## WoS taramasından indirilen 5 makale (22 Ekim)

Kaynak: `wos/wos_tarama_2026-10-22.md`. PDF'ler `wos/pdf/` klasöründe. Beşi de tam okundu; hiçbiri yerçekimini analiz etmiyor. Ama ikisinde konumuza doğrudan değen birer ayrıntı çıktı (D-Arm ve Hu 2017).

## ⚠ Xu, Wang, Zhao, Gao, Wan, Fang — A robotic manipulator using dual-motor joints: prototype design and anti-backlash control (IEEE RA-L, cilt 8, sayı 12, 2023)

Dosya: `wos/pdf/2024_10298640_D-Arm_dual_motor_joints_anti_backlash_RAL.pdf` · DOI 10.1109/LRA.2023.3327867

- Sistem: 7 eksenli seri kol (D-Arm, Rethink Sawyer düzeninde, 900 mm erişim, 12 kg yük). Tabana yakın ilk 3 eklem çift motorlu: her biri iki Panasonic servo + 50:1 planet dişli + 33:25 pinyon kademesi, toplam oran 66. Uçtaki 4 eklem harmonik (strain wave) dişlili tek motorlu. Planet dişlide boşluk 4–9 yay dakikası.
- Model (Denk. 1): J_L q̈_L + b_L q̇_L + **T_d** = Σ T_s,i. Burada T_d "yerçekiminden ya da çevreden gelen dış tork". Yerçekimi ayrı bir terim olarak yazılmamış, bilinmeyen bozucunun içine katılmış.
- Yöntem:
  - İkinci motoru, pinyon ile yük dişlisi arasındaki temas kuvvetini kontrol eden bir admitans konum düzelticisiyle sürüyorlar.
  - Motor torku belli eşiklerin altına inince (T_tl = 0,08 T_rat) boşluk evresine girildiği varsayılıyor; üstüne çıkınca (T_tu = 0,2 T_rat) temas evresine dönülüyor ve kontrol modu buna göre değişiyor.
  - Konum takibi çift motorlu LADRC (doğrusal aktif bozucu bastırma) ile yapılıyor.
  - Yeni kavram: "servo çatışması" (servo-conflict). İki motorun konum farkı, üretim hataları yüzünden açıya göre değişiyor; ön yük ya artıyor ya da kayboluyor.
- Deney:
  - J3 ekleminde yapıldı, ama kol bilerek **volan tipi bir yüke** çevrilmiş: 2. bağ dik, 4. bağ yatay kilitlenmiş, böylece eklem yerçekimi torku görmüyor.
  - Boşluk yaklaşık 0,7°, sinüs takibi yapılmış, 20 N·m'lik darbe bozucusu uygulanmış.
  - Tekrarlanabilirlik ±0,05 mm. Karşılaştırma: KUKA iiwa ±0,1 mm, ABB IRB 1200 ±0,025 mm.
- **Bize değen cümle (tekrarlanabilirlik ölçümü, s. 7):** 2. bağ dik konumdan geçerken J2'nin toplam torkunun yönü değişiyor (yazarlara göre "esas olarak yerçekimi"). Yük dişlisi boşluğu geçip karşı diş yüzeyine çarpıyor. J1 ve J3'te de toplam torkun yönü hareket yönünden farklı olduğunda aynısı oluyor. Sonuç: hareket süreksizliği, darbe ve aşınma.
  → Hipotezimizin mekanizması (yerçekimi torkunun işaret değiştirdiği açıda dişlinin boşluğa düşmesi) gerçek bir 7 eksenli kolda **nitel olarak gözlenmiş ve yazılmış**, ama analiz edilmemiş. Bu cümle Ahmad 1985 ve Karim 2018 ile aynı aileden: makalede "yerçekiminin dişliyi bastırdığı/bıraktığı biliniyor" paragrafında kanıt olarak anılmalı.
- **Yapmadıkları:**
  - Yerçekimi modelde ayrı terim değil.
  - Deney eklemi bilerek yerçekimsiz hale getirilmiş.
  - Limit cycle ve tanımlama fonksiyonu analizi yok.
  - Açıya bağlı bir ön yük önerisi yok. Ön yük eşikleri motor torkuna göre, yani anlık sinyale göre değişiyor.
- **Bizim için:**
  1. Motor torku eşiğiyle boşluk evresini tahmin etmek, bizim "tork sıfır geçişi" çerçevemizin pratikteki karşılığı. Yerçekimli kolda bu eşik açıya göre önceden hesaplanabilir: 90° civarında motor torku yerçekimi yüzünden hiç düşük eşiğin altına inmez.
  2. Endüstriyel kollarda yerçekimi sorununa iki yaklaşım görülüyor: ya uçtaki eklemleri harmonik dişliye kaydırmak ya da deneyi yerçekimsiz yapmak. Bizim "ucuz dişli + yerçekimini kullan" yönümüz bunun tam tersi; motivasyon paragrafında kullanılabilir.

## Hu, Yang, Xiao, Xu — Suppression of limit cycle oscillation for two-mass system with backlash nonlinearity based on dual Luenberger observer (IEEE ITEC Asia-Pacific 2017)

Dosya: `wos/pdf/2017_8080972_Hu_Yang_Xu_two_mass_backlash_limit_cycle_dual_Luenberger_ITEC.pdf` · IEEE Xplore 8080972

Harbin (HIT) grubu; Wang ve ark. 2017 TIE ile aynı ekip, ondan önceki konferans çalışması.

- Sistem: iki kütleli tahrik (sürücü motor + yük motoru, J_M = J_L = 0,0235 kg·m², K_s = 300 N·m/rad, karşı-rezonans frekansı ARF = √(K_s/J_L) ≈ 17,9 Hz). Tam kapalı çevrim kontrol (yük tarafında konum sensörü): konumda P, hızda PI. Yalnızca simülasyon.
- Limit cycle frekansı (Wang 2016 IECON'dan): "sertlik oranı" r_s = √(k_p k_v / J_L) / ARF.
  - r_s < 1 ise kararlı salınım, frekansı r_s · ARF.
  - r_s ≥ 1 ise büyüyen salınım, frekansı ARF.
  - Boşluk genişliği frekansı değiştirmiyor, yalnızca genliği değiştiriyor.
- Çözüm: iki Luenberger gözlemcisi kullanılıyor. Birincisi mil torkunu (T̂_w), ikincisi yük torkunu (T̂_L) kestiriyor. Aradaki fark bir PI'dan geçirilip tork komutuna ileri besleme olarak ekleniyor. Gözlemci kutupları tek bir üçlü kutup olarak seçilmiş.
- **Bize değen ayrıntı:** simülasyonda **sabit 1 N·m yük torku** var, yani bir ön yük var. Buna rağmen k_p = 20 ve 2b = 0,01 rad'da 14,4 Hz'lik limit cycle oluşuyor.
  - Boyutsuz sayımızla: γ = T_L / (K_s · b) = 1 / (300 × 0,005) ≈ **0,67**. 2b = 0,05 rad için γ ≈ 0,13.
  - Onların r_s'si bizim r_s = ω_c/ω_rez ile aynı fikir: kontrol döngüsü frekansının rezonans frekansına oranı. k_p = 20 için 0,82.
  - Bizim yasamız (γ_sınır ≈ 3 r_s³ ≈ 1,65) bu noktada salınım öngörüyor (γ < γ_sınır). Sonuç **tutarlı**.
  - **Uyarı:** yasamız r_s ≤ 0,33 için çıkarıldı, 0,82 aralığın çok dışında. Kontrolcü yapısı da farklı (bizde PID, onlarda P–PI ve tam kapalı çevrim). Yani bu bir kanıt değil, yalnızca çelişki olmadığını gösteren bir işaret.
  - Asıl önemi şu: literatürde sabit ön yüklü bir sistemde limit cycle görülmüş ama ön yükün etkisi hiç sorulmamış. Yük torku yalnızca simülasyonun bir ayarı olarak duruyor.
- **İkinci önemli nokta:** yük torku gözlemcisi (T̂_L) yerçekimli kolda tam olarak mgℓ sinθ'yı kestirir.
  - Bu durum Shahruz 2000 notuyla aynı: gözlemcinin işi 90° civarında yerçekimini kestirmek, 0° civarında boşluğu kestirmek.
  - Onların T̂_w − T̂_L farkı yerçekimli kolda açıya göre farklı davranacaktır. 90°'de fark küçük ve sabit, çünkü dişli bastırılı. 0°'de fark büyük ve işaret değiştiriyor.

## Bai, Yin, Li, Zhang, Yuan, Zhang — Backstepping control collaborative shaft torque observer for limit cycle oscillation suppression of fully closed-loop gear transmission servo system (IEEE TPEL, cilt 39, sayı 4, 2024)

Dosya: `wos/pdf/2024_10365568_Backstepping_shaft_torque_observer_limit_cycle_TPEL.pdf` · DOI 10.1109/TPEL.2023.3344485

- Sistem: 2 kW PMSM, dişli oranı 1 (boşluk benzetilmiş), sürücü motor + yük motoru tezgâhı (yatay sürükleme düzeneği), volanla eylemsizlik oranı R = 1 ya da 3. Boşluk 0–12,5° arasında ayarlanabiliyor. DSP + FPGA ile kontrol. Model (Denk. 4): J_l ω̇_l = T_s − T_l. **Yerçekimi yok.**
- Limit cycle analizi (Bölüm III):
  - Konumda P, hızda PI, tam kapalı çevrim. Doğrusal kısım G(s)H(s), boşluğun simetrik tanımlama fonksiyonu N(A); −1/N(A) eğrisiyle Nyquist eğrisi kesiştiriliyor.
  - Hız integrali küçük alınırsa frekans **ω_lc ≈ √(k_p k_v / J_l)**: yalnızca kazançlara ve yük eylemsizliğine bağlı, boşluk genişliğinden bağımsız.
  - Deneyde 14,8 Hz, genlik boşluk açısı kadar: 2r = 0,0087 / 0,026 / 0,044 rad için genlik 0,0086 / 0,0252 / 0,0435 rad. Frekans üçünde de aynı.
- Çözüm: hız ve akım döngülerinde geri adımlamalı kontrol (backstepping) + üçüncü dereceden mil torku gözlemcisi (STO). Gözlemcinin kutupları üçlü (s + ω_c)³, bant genişliği 200 rad/s. Gürültü ile bant genişliği arasındaki ödünleşim Bode çizimleriyle tartışılmış.
- **Yapmadıkları:**
  - Yerçekimi ve sabit yük torku analizi yok. Kullandıkları tanımlama fonksiyonu simetrik N(A), kaymalı değil.
  - Çalışma noktasının limit cycle'ı etkilemediği örtük olarak varsayılıyor (yatay tezgâh, Esbrook Önerme 2).
- **Bizim için:**
  1. "Frekans boşluktan bağımsız, genlik boşluk kadar" sonucu yerçekimsiz durumun referansı. Bizim beklentimiz (Márton 2009 notu) yerçekimli kolda frekansın **açıyla kayması**: dişli bir kenarda daha uzun kaldıkça etkin eylemsizlik değişir. Bu makale, kaymanın yerçekimsiz düzenekte olmadığını gösteren deneysel bir karşılaştırma noktası.
  2. Genliğin boşluk genişliğine eşit çıkması bizim iki kenarlı salınım sınıfımıza (sınıf 2) karşılık geliyor. Yerçekimi tek kenarlı salınıma (sınıf 1) geçişi sağlıyorsa genlik boşluk genişliğinden küçük çıkmalı. Ölçülebilir ve ayırt edici bir işaret.
  3. Gözlemci tasarımı (üçlü kutup, bant genişliği seçimi) ESP32'deki gözlemcimiz için doğrudan uyarlanabilir bir tarif.

## Sun, Gu — Backlash elimination control for robotic joints with dual-motor drive (Actuators, MDPI, cilt 13, sayı 8, 291, 2024)

Dosya: `wos/pdf/2024_Actuators_backlash_elimination_dual_motor_robotic_joints_MDPI.pdf` · DOI 10.3390/act13080291 · açık erişim

- Sistem: iki DC servo motorlu, planet dişli + pinyonlu robot eklemi prototipi. Simülasyonda 2r = 0,02 rad, dişli oranı 10.
- Yöntem: **değişken ön yük torku.**
  - İki motorun akımından büyük olanı bir dönüşüm fonksiyonuna giriyor.
  - Akım küçükken, yani tork yön değiştirmek üzereyken, motorlar arasına ön yük torku uygulanıyor (en fazla anma torkunun %10–30'u).
  - Akım büyükken bu ön yük sürüş torkuna çevriliyor ve iki motor yükü birlikte sürüyor.
  - Amaç: sabit ön yükün boşuna harcadığı enerjiyi azaltmak.
- Deney: eklem 360° ileri, 360° geri döndürülmüş, konum hatası ve akımlar gösterilmiş. Durağan hâlde ön yük akımı 250 mA'den 110 mA'e iniyor.
- **Yerçekimi yok**: modelde ve analizde geçmiyor. Eklemin hangi düzlemde döndüğü ve yükün ne olduğu belirtilmemiş. Limit cycle analizi yok.
- **Bizim için:** "ön yükü yalnızca akım küçükken uygula" kuralı, yerçekimli bir kolda **kendiliğinden açıya bağlı** hale gelirdi. 90° civarında motor akımı yerçekimi yüzünden hiç küçülmez, ön yük devreye girmez. 0° ve 180° civarında sık sık girer. Yazarlar bunu fark etmemiş. Bizim katkımız bu ilişkiyi açık ve önceden hesaplanabilir yapmak. Sun 2023'ün "ön yükü açıya göre azaltma" yorumuyla aynı yönde.

## Li, Xie, Chen, Ma, Yang, Liu — Dynamic simulation and adaptive backlash compensation control for the naval gun follow-up system with unknown backlash (Ships and Offshore Structures, 2026, çevrimiçi)

Dosya: `wos/pdf/2026_naval_gun_follow-up_adaptive_backlash_compensation_ShipsOffshore.pdf` · DOI 10.1080/17445302.2026.2716857

- Sistem: gemi topunun yükseliş (pitch) ve yön (azimuth) takip sistemleri. Servo motor → dişli (N) → büyük eylemsizlikli yük. Gemi yalpası düzensiz dalga spektrumundan üretiliyor (deniz durumu 3–5, 18 ve 30 knot).
- Model (Denk. 3–6): J q̈ + B q̇ = τ + d(t). Bütün dış etkiler d(t) içinde. **Yükseliş ekseninde topun dengesizlik torku (yerçekimi) modelde ayrı bir terim değil.** g yalnızca dalga denkleminde geçiyor. Gerçek toplarda bu tork genellikle denge düzeneğiyle (equilibrator) karşılanır, ama makalede bundan söz edilmiyor.
- Yöntem: ölü bölge tersinin yumuşak bir yaklaşığı + RBF sinir ağıyla yaklaşık hatanın çevrimiçi kestirimi + geri adımlama. Lyapunov ispatı var. Doğrulama MATLAB/Simulink ve RecurDyn çok-cisim birlikte benzetimiyle yapılmış (dişli temas kuvvetleri C alt programıyla). Fiziksel deney yok.
- Sonuç: tek nişan açısı (200 mrad ≈ 11,5°). Deniz durumu 4'te kararlılık doğruluğu PID'e göre %70–86 daha iyi.
- **Bizim için:** yerçekiminin fiziksel olarak en büyük olduğu eksenlerden birinde (top yükselişi) bile boşluk çalışması yerçekimini "bilinmeyen bozucu" olarak alıyor. Tek açıda çalışılmış, açı taraması yok. Literatürdeki örüntünün bir örneği daha. İlgi düzeyi düşük; yalnızca "yerçekimli eksen ama analiz yok" listesinde anılır.
- Kaynakçada takip edilebilir: Awan ve ark. 2024 Appl. Sci. 14(22):10265 (açık erişim), "Tracking control and backlash compensation in an inverted pendulum with switched-mode PID controllers": çift DC motorlu geri sürüşle sarkaç. Muhtemelen yine dik dengeye bakıyor, kontrol edilmeli.

## Henüz okunmadı (öncelik sırasıyla)

1. Márton, Lantos — Friction and backlash induced limit cycles (ECC 2009)
2. Malik ve ark. — Single-link parameter estimation, dead-band/dead-zone (IC4 2009)
3. ~~Humanoid DOB backlash (IECON 2004), Kim ve ark. 2009, Shahruz 2000~~ OKUNDU
4. ~~2022 Equivalence between nonlinear friction and backlash~~ OKUNDU
5. ~~2022 Load-side acceleration control~~ OKUNDU. **İndirilmiş 31 IEEE PDF'nin tamamı okundu (18 Ekim).**
6. ~~Wang 2024, Ghaffari 2013, Wang 2017, Yu–Tang 2024 (LADOB)~~ OKUNDU (yukarıda).
6b. ~~Esbrook–Tan–Khalil 2014, Horng 2006~~ OKUNDU. ~~Olsson–Åström 2001, Fischer–Tomizuka 1996~~ OKUNDU. Kalan yeni hedefler: Armstrong-Hélouvry ve ark. 1994 Automatica (sürtünme anketi, ScienceDirect → kampüste); Wallenborg, Åström 1988 (robot tahrikinde limit cycle); Atherton 1975 kitabı (kaymalı DF); Mees, Bergen 1975 TAC ve Bergen ve ark. 1982 (tanımlama fonksiyonunun geçerliliği/hata sınırları); Ghaffari, Tomizuka, Soltan 2008 Nonlinear Dyn. (limit cycle kararlılığı); kaymalı (bias) tanımlama fonksiyonu için bir ders kitabı kaynağı (Gelb & Vander Velde 1968 "Multiple-Input Describing Functions", ya da Khalil'in kitabı)
8. WoS okumalarından çıkan yeni hedefler (22 Ekim): Wang ve ark. 2016 IECON "Analysis of limit cycle mechanism for two-mass system with backlash nonlinearity" (sertlik oranı r_s, IEEE); Yang ve ark. 2016 TMECH, mil torku sınırlama (Sun 2023 listesinde de var); Awan ve ark. 2024 Appl. Sci. (açık erişim, sarkaç + çift DC motor); Robertz ve ark. 2010 ICRA "Precise robot motions using dual motor control" (endüstriyel robotta çift motor).
7. Springer referans listesinden eklenecek IEEE makaleleri: Wang ve ark. 2017 IEEE TIE (limit cycle, transmission backlash, 10.1109/TIE.2017.2711564); Villwock ve Pacas 2009 IEEE TIE (boşluk tanılama); Merzouki ve ark. 2007 CEP (boşluk gözlemi)
