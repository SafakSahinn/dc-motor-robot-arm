function out = kol_benzetim(p, theta0_deg, wc)
% KOL_BENZETIM  İki kütleli kol + dişli boşluğu + yerçekimi + PID benzetimi.
% theta0_deg ve wc aynı boyutlu diziler olabilir: her eleman ayrı bir
% benzetim; hepsi vektör halinde aynı anda çözülür (sabit adımlı RK4).
%
% Durumlar (kol tarafına indirgenmiş):
%   phi  : motor açısı / N           dphi : hızı
%   th   : kol açısı (0 = dik aşağı)  dth  : hızı
% Dişli torku tau_s, phi - th farkı boşluk yarı genişliği r'yi aşınca oluşur.
%
% Kontrolcü her p.Ts saniyede bir çalışır, arada tork sabit tutulur:
%   tau = Kp e + Ki z - Kd v,   e = th_ref - th_ölçülen,  z = sum(e)*Ts
%   v   = motor hızı (p.Dkaynak='motor') ya da kol hızı ('kol');
%   p.gL > 0 ise kol açısı ölçümü gL kontrol örneği gecikmeli kullanılır (AS5600 filtresi + I2C okuması).
%         p.fv sonluysa nicemlenmiş açının farkından + birinci derece filtreyle kestirilir.
%   Motor açısı ölçümü (varsayılan ideal zamanlama, gürültüsüz): p.gM [s] gecikme (benzetim adımı
%   p.dt çözünürlüğünde; motor miline takılan AS5600'ün filtresi + I2C okuması için), p.nM [rad, kol
%   tarafı] RMS beyaz gürültü (nicemlemeden önce eklenir; tohum p.nTohum, varsayılan 1). Konum
%   hatası (Pkaynak='motor'), hız farkı (Dkaynak='motor', fv sonlu) ve yüz kestirici aynı ölçümü görür.
% Ardından doyum (+-Tmax) ve sürücü ölü bandı (|tau| < olu -> 0).
% Kazançlar rijit model (J = JM + JL) için kapalı çevrim hızı wc'ye göre:
%   Kp = J wc^2,  Kd = 2*0.7*J*wc,  Ki = Kp*wc/4.
%
% p.kontrol = 'PPI' ise Ghaffari 2013 kaskadı (kol tarafı büyüklüklerle); bu durumda
% üçüncü argüman wc yerine konum kazancı kp [1/s] olarak okunur:
%   wcmd = kp e,  tau = KV (wcmd - v) + KI z,  z = sum(wcmd - v)*Ts,  v = motor hızı
%   KV = kv kr^2, KI = kr^2/Ti (Ghaffari'nin motor tarafı kv, Ti'sinden); r_gs = sqrt(kp KV / Ks).
%
% İsteğe bağlı integratör katmanı (varsayılan kapalı; eski sonuçlar değişmez):
%   p.Iolu [rad]  : |e| < Iolu iken integral birikmez (ölü bant, z donar)
%   p.Isifirla    : true ise konum hatası işaret değiştirdiğinde z = 0 (sıfırlama)
% İsteğe bağlı konum kaynağı (varsayılan 'kol'): p.Pkaynak = 'motor' ise e = th_ref - phi_ölçülen
%   (motor enkoderi, nicemleme p.qM); kontrolcü kol sensörünü hiç görmez. Kol, boşluğun bir
%   ucunda ve dişli esnemesi kadar hedeften kayık durabilir (kalıcı hata <= r + tau_s/Ks).
% p.ofset [rad] (skaler ya da her benzetim için bir değer): e = th_ref + ofset - ölçülen.
%   Motor tarafı geri beslemede boşluk + dişli esnemesi telafisi için (ofset_tablosu.m).
% p.ofsetYuz (varsayılan yok/kapalı): ÜST SINIR deneyi için ofsetin işareti kolun GERÇEK temas
%   yüzünden (ikizde delta = phi - th) seçilir: ofset = s*r + mgl sin(th_ref)/Ks.
%   'anlik' : her kontrol örneğinde, temas varken (|delta| >= r) s = sign(delta); boşlukta s tutulur.
%   'durunca': s yalnız kol durgunken (|dth| < p.yuzV, p.yuzN örnek boyunca) ve temas varken güncellenir.
%   Başlangıç yüzü p.yuz0 (yoksa sign(sin th_ref), 0 ise +1). p.ofset bu durumda kullanılmaz.
%   Çıktı: out.yuzDegis (tüm süre), out.yuzDegisAn (analiz penceresi) yüz seçimi değişim sayıları.
% p.yuzKes (varsayılan yok/kapalı): YALNIZ MOTOR SİNYALLERİYLE yüz kestirici (iş sırası 3).
%   Ofset = s_of*r + mgl sin(th_ref)/Ks; s_of kestiricinin yüzü s^'ye p.yuzRampa [s] sürede
%   (-1'den +1'e) rampayla gider (0: basamak). Başlangıç yüzü p.yuz0 (yoksa sign(sin th_ref)).
%   Kestirici yalnız enkoderi (olc(phi, qM)), uygulanan torku u ve kendi durumunu görür.
%   Tork gözlemcisi (Luenberger, üçlü kutup p.gozW [rad/s]): JM phi'' = u - bM phi' - d,
%   d = tau_f + tau_s. Sürtünme aralığı: hareketteyken tau_f = sign(w^)*[FcN, FsN], dururken
%   [-FsN, FsN] -> tau_s aralığı [lo, hi].
%   'edilgen' : motor durgunken (|w^| < p.vDur, p.yuzN örnek) s^ = sign(u) (karşılaştırma tabanı)
%   'olay'    : lo > p.tauEsik ya da hi < -p.tauEsik, p.Nper örnek sürerse s^ = o işaret
%               (çarpma ya da tork aktaran her hareket)
%   'yoklama' : |th_ref - 180°| <= p.yokBant ve motor p.yokBekle s (varsayılan 0,5: 0,3 s'de kol boşlukta hâlâ düşüyor olabiliyor, 1 s'de
%               ince enkoder yapışma-kayma kıpırtısını gördüğü için motor hiç o kadar durgun sayılmıyor) durgunken, kontrolcü
%               dondurulur, u = p.yokA*(-s^) uygulanır (inanılan BOŞLUĞA doğru mutlak itiş; tutma
%               torku eklenmez, çünkü sürtünmeye yaslanmış integratör onu Fs mertebesine çıkarabiliyor).
%               İtiş yönündeki dişli torku tahmini (-s^)*d^ - FcN > p.yokEsik olursa temas var: s^ = itiş
%               yönü, itiş kesilir (yalnız itiş p.yokTmin (3/gozW) s sürdükten ve motor itiş yönünde
%               hareket ederken; öncesinde d^ hâlâ eski tutma torkunu gösteriyor). Motor önce p.yokD
%               yol alırsa boşluk: s^ doğru. Yol süresine
%               bakmak işe yaramıyor: dişli yayı sıkışırken motor ilk anda neredeyse serbest ilerliyor.
%               Boşluk bulunursa motor bang-bang ile (fren, geri it, fren) başlangıca döndürülür; kol
%               desteksiz kaldığı süre kısalır. Geri itişten frene geçiş yol <= p.yokOrta*(alınan yol) olunca
%               (varsayılan 0,5: başlangıçta durur; 0,6: alınan yolun ~%20'si kadar önde durur, kol yoklamada
%               biraz düştüğünden motor ona çarpıp yayı fazladan sıkıştırmaz). Durgunluk kararı p.vDurF [Hz]
%               birinci derece süzgeçten geçmiş w^ ile (varsayılan Inf: süzgeç yok; enkoder gürültüsüne karşı). En çok p.yokTmax s. Bir yüz değişiminden sonra motor
%               oturunca yeniden yoklanır (en çok p.yokMaks); ayrıca p.yokPer s'de bir (varsayılan Inf).
%               'olay+yoklama'da yoklama torku olay sayılmaz.
%   'olay+yoklama': ikisi birlikte.
%   p.rOlc = true (B3; yalnız yoklama kiplerinde, varsayılan kapalı): TAM GEÇİŞ yoklaması, boşluğu ölçer.
%               Aynı başlama koşulu (yokEtkin, yokBekle, yokPer, yokMaks); refYol varsa bölge o anki referansa göre.
%               Kontrolcü donar; motor yavaş yol izleyiciyle (ref p.rOlcV [rad/s] 0,1 ile ilerler; PD bandı p.rOlcW
%               10 Hz, JMN ile; ileri besleme FcN; |u| <= p.rOlcA 0,12) evre 11: inanılan yüze (s^), 12: öbür yüze,
%               13: yeniden ilk yüze, 14: ilk geçiş yolunun yarısı kadar geri (ortaya), sonra kontrolcüye.
%               Temas: itiş yönünde dişli torku ykDir*d^ - (FcN + (FsN - FcN) exp(-(w^/vsN)^2)) > p.rOlcEsik (0,01),
%               motor önce 0,8 rOlcV'yi geçmiş ve o andan p.rOlcTb (0,03) s geçmiş olmalı (kalkış yapışması ve
%               gözlemci gecikmesi), evrede yokTmin dolmuş olmalı. vsN varsayılan p.vs.
%               Ölçüm: 2r^ = ort(yol_a - (tau1 + tau2)/KsN, yol_b - (tau2 + tau3)/KsN) (iki yön: kolun yavaş kayması
%               birinci mertebede düşer). |yol_a - yol_b| <= p.rOlcTut (0,75°) ise kabul (yalnız motor sinyali).
%               Bir yüz yol p.rOlcMaks (3 rN) içinde bulunmazsa ya da evreler p.rOlcTmax (3) s'yi aşarsa iptal.
%               Çıktı out.rOlc: n, iptal (benzetim başına), t, rHat, yol (a), yol2 (b), tau1, tau2, kol (bu yoklamada
%               kolun en büyük hareketi, gerçek theta; yalnız değerlendirme), kabul, rN (ölçümden sonraki rN)
%               (satır = ölçüm, en çok p.rOlcKayit); out.rNSon.
%   p.rGun (rOlc ile; varsayılan 'yok'): kabul edilen her ölçümden sonra ofsetin rN'si güncellenir.
%               Yalnız kabul edilen VE yeniliği (mutlak: r^ - rN; fark: r^ - r^0 - D) <= p.rGunKapi (0,3) rN olan ölçüm kullanılır (out.rOlc.gun; yanlış
%               temas r^ ~ 0 verir ve iki yön birlikte yanıldığında tutarlılık testi onu yakalamaz).
%               'mutlak': rN += p.rGunK (0,5) (r^ - rN).  'fark': ilk kabul edilen ölçüm başvuru r^0 (o anda r = rN0
%               varsayılır), sonra D += rGunK (r^ - r^0 - D), rN = rN0 + D (ölçümün sabit sapması düşer).
%   p.rNKahin = true (karşılaştırma tabanı; rGun ile birlikte değil): her kontrol örneğinde rN = p.r*rFn(t).
%   Literatür tabanları (B1-L, 7_karsilastirma/b1_literatur_taban.m; yoklama yok, gözlemci yine çalışır):
%   'momentum': genelleştirilmiş momentum gözlemcisi (Ruderman-Iwasaki 2016 TIE sanal sensörünün tork
%               kısmı): r = L(JM w - ∫(u - bM w + r)), r -> -d; dişli torku = -r - sign(w^)FcN (hareketteyken).
%               |.| > p.momEsik ise s^ = işareti (histerezis). p.momL [rad/s] (100), p.momEsik [N m] (0,01),
%               p.momV = 'fark' (enkoder farkı, makaledeki gibi) ya da 'gozlemci' (w^).
%   'sta'     : model içermeyen süper-burulma türevleyicisi (Ruderman-Fridman 2019 TCST, denklem 5-6):
%               x^' = w^ + k1|e|^½ sgn e, w^' = k2 sgn e, e = y - x^, k2 = 1,1 p.staL, k1 = 2,028 √k2.
%               Çarpma: |e| > p.staEsik [rad] ve sgn e = -sgn w^ (ani yavaşlama) -> s^ = sgn w^.
%               p.staUyar = [U f T] (U > 0: makalenin S1 uyarımı): 180° bandında motor p.yokBekle s
%               durgunken T s boyunca u'ya U sin(2π f t) eklenir, integral donar; en çok p.staMaks kez.
%               Çıktı out.staSay.
%   p.yokBolge (yoklamanın etkin olduğu bölge; varsayılan '180'):
%     '180'     : |th_ref - 180°| <= p.yokBant (eski davranış)
%     '180+360' : ayrıca |th_ref - 360°| <= p.yokBant (dik aşağı; yerçekimi torku orada da sıfır)
%     'tork'    : '180' bandı YA DA durgunken kestirilen dişli torku belirsiz: |d^| <= FsN + p.yokTorkEsik
%                 (sürtünme aralığı sıfırı içeriyor; yerçekimi + dış yükün net durağan torku küçük).
%                 Her kontrol örneğinde yeniden değerlendirilir. p.yokTorkEsik [N m], varsayılan mglN sin 1°.
%   p.thYildiz (varsayılan false): bilinmeyen sabit yük yerçekimini dengeleyince oluşan sıfır tork noktası
%     (θ*) için hedef kaydırma; 180°'deki ε kuralının genellemesi. Süzülmüş d^ (p.tyF Hz, yoklamada
%     dondurulur) ile yük kestirilir; kaydırmasız hedefte beklenen net tork |n0| < p.tyK*tyMin ise
%     (tyMin = mglN sin p.tyEps, varsayılan 0,5°; t >= p.tyBas) hedef, net tork sign(n0)*tyMin olacak
%     kadar kaydırılır (en çok p.tyMaks, varsayılan 0,5°); |n0| > 2 tyMin olunca bırakılır. out.tyD.
%     p.tyArama = true: yük kestirimi yerine arama. Referans dururken s^ ~2 s'de 2 kez değişirse (yüz
%     avlanması) hedef p.tyHiz (0,25°/s) ile, net tork sign(n0) yönüne gidecek biçimde kaydırılır
%     (en çok p.tyMaks); avlanma durunca tutulur; uçta 1 s daha sürerse bir kez öbür yöne; referans
%     değişince sıfırlanır.
%   Ofsetteki r, K_s, mgl kestiricinin bildiği değerlerdir: p.rN, p.KsN, p.mglN (varsayılan: ikizin gerçeği).
%   p.rN skaler ya da benzetim başına bir değer (1 x n, ör. hedef açıda okunmuş r(θ) haritası; B1-M ek).
%   Çıktı: out.shat (s^ kaydı), out.dhat, out.yuzDegis, out.yuzDegisAn, out.yuzSon,
%   out.yokSay (yoklama sayısı), out.yokKol (yoklama + 0,3 s içinde kolun en büyük hareketi [rad],
%   yalnız ölçüm için gerçek theta kullanılır), out.yokTemas (temas bulan yoklama sayısı).
% Gözlemcinin gördüğü tork (iş sırası 5; varsayılan kapalı: gözlemci son komut u'yu hatasız görür):
%   p.akimW [rad/s] : tesise uygulanan tork komutu birinci derece izler (mod 3 akım döngüsü bandı;
%                     varsayılan Inf: tork = komut). Kayıtlardaki out.u yine komuttur.
%   p.tOlc = true   : gözlemci u yerine INA228 ölçümünü görür (k_t i, kol tarafı N m):
%                     tKaz * ort(uygulanan tork, [t - tGec - tPen, t - tGec]) + tOfs + tGur*randn
%                     tPen [s] dönüşüm süresi x ortalama sayısı (varsayılan Ts: son aralığın ortalaması =
%                     eski davranış), tGec [s] dönüşüm sonu ile okuma arası gecikme (varsayılan 0), tGur [N m]
%                     RMS beyaz gürültü (her kontrol örneğinde bir), tOfs [N m], tKaz (1). Gürültü ayrı
%                     rastgele akıştan (tohum p.tTohum, varsayılan 2). Hepsi p.dt çözünürlüğünde.
% p.vKaynak (varsayılan 'olcum': v yukarıdaki gibi p.fv'ye göre): 'gozlemci' ise P-PI'nin hız terimi
%   tork gözlemcisinin w^'si olur (donanımdaki seçim, mimari.md §4.1; kartta kontrol::HIZ_GOZLEMCI).
%   Kartla aynı sıra: v, yüz kestirici bloğunda o örnekte GÜNCELLENMİŞ w^'dir (e satırından hemen önce
%   atanır). Yalnız yuzKes açıkken (gözlemci yalnız orada var); değilse hata. ktlKayit'te KT.v = w^.
% p.ktlKayit = true (yalnız yuzKes açıkken; varsayılan kapalı): her kontrol örneğinin girdi ve çıktısı
%   out.ktl'ye yazılır (ESP32 açık döngü eşdeğerlik testi, 6_esp32/ktl_esdeger.m). Alanlar (örnek x senaryo):
%   sayim (motor ölçümü / qM, tamsayı), v (kontrolcünün gördüğü hız), uo (gözlemcinin gördüğü tork),
%   u, wh, dh, sOf, sh, ykF; ayrıca ilkSayim (gözlemcinin başlangıç phi^'si / qM).
% p.ktlDis (varsayılan yok; adım kilitli PIL, 6_esp32/pil.m): dış kontrolcü, fonksiyon tutamacı
%   [u, c] = p.ktlDis(kc, sayim, v, uo, ilkSayim). Her kontrol örneğinde (kc = 1, 2, ...) MATLAB
%   kontrolcüsü yine hesaplanır (gölge: aynı ölçümleri görür), sonra tesise dış kontrolcünün u'su
%   uygulanır. sayim, v, uo ktlKayit'teki gibi; c dış kontrolcünün tanı satırı (sayısal, sabit uzunluk).
%   Yalnız yuzKes açıkken ve tek senaryoda (n = 1); ktlKayit kendiliğinden açılır. out.ktl'ye ek
%   alanlar: uM (gölge MATLAB u'su; KT.u uygulanan u'dur), kart (örnek x numel(c)).
% p.FcKay (varsayılan yok; iş sırası 5b): gerçek sürtünmenin zamanla kayması. Tesisteki F_c ve F_s
%   birlikte m(t) = 1 + (FcKay - 1)*min(t/FcKayT, 1) ile çarpılır (t = 0'da 1, FcKayT'de FcKay; sonra
%   sabit). p.FcKayT varsayılan p.T. Kestiricinin bildiği FcN/FsN değişmez. Sabit bir sapma için
%   FcKayT çok küçük verilir (ör. 1e-9).
% p.motorElk (varsayılan 0: tesis torku = komut; iş sırası 5c): motorun elektrik tarafı, simulink/sim_param.m
%   ve blok_surucu.m ile aynı eşdeğer motor (kol tarafı, Kt = Ke = Km). Beşinci durum akım i:
%   La di/dt = V - Ra i - Km phi',  tesis torku = Km i. Sürücü her p.dt adımında (Tsur = dt) çalışır:
%   1 gerilim modu V = RaN u/KmN;  2 zıt EMK kompanzasyonu V = RaN u/KmN + KmN v (v: kontrolcünün hızı;
%   p.elkV = 'gozlemci' ise tork gözlemcisinin w^'si, yalnız yuzKes açıkken);
%   3 akım döngüsü i_ref = u/KmN (+-Ilim), PI (Kp = La wi, Ki = Ra wi, wi = 2 pi p.akimBant [Hz], 500),
%   akım ölçümü bir adım gecikmeli. Ardından DRV8874 akım sınırı |V - Km w| <= Ra Ilim ve besleme +-Vs.
%   Değerler (varsayılan veri sayfası eşdeğeri): p.Vs 12, p.Km = Vs/w0 (w0 333 rpm), p.Ra = Km Vs/0,49,
%   p.La 2,5e-3, p.Ilim (2/2,3) Vs/Ra; firmware'in bildikleri p.KmN, p.RaN (varsayılan gerçeği).
%   p.akimW ile birlikte kullanılamaz. tOlc açıksa INA228 Km i'yi (gerçek akım x gerçek Km) görür.
%   Çıktı: out.iTepe (tüm süre en büyük |i| [A, eşdeğer]), out.Vdoy (V'nin besleme ya da akım sınırında
%   kaldığı adımların oranı).
% p.yuzKural (varsayılan yok/kapalı; B1 karşılaştırması, 7_karsilastirma/): KOMUT TABANLI TABAN KURALLAR.
%   Ofset = s_of*r + mgl sin(th_ref)/Ks (yuzKes ile aynı tablo, aynı p.yuzRampa, p.rN/p.KsN/p.mglN);
%   yalnız s'yi seçen kural farklı. tau_g = mglN sin(th_ref(t)).
%   'panasonic' : (WO2026074901A1 türü) yön = sign(hız komutu), hız komutu P-PI'nin wcmd'si (bir önceki
%                 örnek); |wcmd| < p.kuralV iken yön tutulur. k = 1 (|tau_g| <= p.kuralT1), p.kuralT2'de 0'a
%                 doğrusal iner: s = k*yön + (1-k)*sign(tau_g). Yalnız p.kontrol = 'PPI'.
%   'toyoda'    : (JPH07200018A türü) |tau_g| > p.kuralT1 ise s = sign(tau_g), değilse dönüş yönü =
%                 sign(kontrolcünün gördüğü motor hızı v); |v| < p.kuralV iken tutulur.
%   'lenze'     : (US12259034B2 türü, tork sıfır geçişi) s = sign(u) (bir önceki örnekte uygulanan tork),
%                 |u| < p.kuralU iken tutulur (histerezis).
%   Varsayılanlar: kuralV 0,05 rad/s, kuralT1 0,02, kuralT2 0,04, kuralU 0,01 N m. Başlangıç yüzü p.yuz0.
%   Çıktı: out.shat (sign(s), 0 ise önceki), out.yuzDegis, out.yuzDegisAn, out.yuzSon.
% p.refYol (varsayılan yok: referans sabit th_ref): fonksiyon tutamacı, t [s] -> 1 x n referans [rad].
%   Kontrolcü ve (yuzKes/yuzKural açıksa) ofsetin yerçekimi terimi bunu kullanır; başlangıç durumu
%   refYol(0) - p.adim. theta0_deg yine son hedeftir (analiz ve yoklama bandı ona göre).
% p.dB (varsayılan 0; skaler ya da her benzetim için bir değer) [N m]: kola sabit yük, p.dBT0 <= t < p.dBT1.
% p.onYuk (varsayılan 0/kapalı; B2, mekanik ön yük): makas (anti-backlash) dişli. Asıl yarı A, delta = +r'de
%   sert temas (K_s); yaylı yarı B pinyonu öbür yüzden A'ya doğru p.taup [N m] ön yükle bastırır, B'nin
%   yayı p.Kp [N m/rad] (2r sıkışınca B, A'nın dayanağına oturur: delta = -r'de sert temas, K_s):
%     tau_s = max(K_s(d - r) + c_s d', 0)[d > r] - max(taup + Kp (r - d), 0) + min(K_s(d + r) + c_s d', 0)[d < -r]
%   Durağan: tau > -taup iken kol A yüzünde (boşluk yok, sertlik K_s + Kp); tau < -taup iken yay esner,
%   yüz değişir. taup = Kp = 0 eski modelle birebir aynıdır. taup, Kp skaler ya da her benzetim için bir
%   değer. p.taupFn (isteğe bağlı, B3) t [s] -> çarpan: ön yük taup*taupFn(t) (yay gevşemesi).
%   Ön yükün sürtünme bedeli: tesisteki F_c ve F_s'ye p.muP*taup(t) eklenir (varsayılan muP 0).
%   Kestiricinin bildiği FcN/FsN değişmez. out.tau_s net dişli torkudur (A - B).
% p.kayitEk = true (varsayılan kapalı; B2 bedel): out.w motor hızı [rad/s, kol tarafı]; motorElk açıksa
%   out.i akım [A, eşdeğer] ve out.V sürücü gerilimi [V] (aynı kayıt aralığı p.dec).
% Model dışı etkiler (B1-M, 7_karsilastirma/b1m_model_disi.m; hepsi varsayılan kapalı, kestirici bilmez):
%   p.cogA [N m, kol tarafı], p.cogK (12), p.cogF [rad]: motor torkuna cogging -cogA sin(cogK N phi + cogF)
%     (motor mili turu başına cogK periyot).
%   p.sfA, p.sfF: konuma bağlı sürtünme, tesis sürtünmesi (1 + sfA sin(N phi + sfF)) ile çarpılır (mil turu
%     başına bir kez). Stribeck biçimi için tesisin p.Fs, p.vs değerleri ayrıca değiştirilebilir.
%   p.rA, p.rK (1), p.rF: açıya bağlı boşluk, tesiste r(th) = r (1 + rA sin(rK th + rF)) (rK = 1 çıkış dişlisi
%     eksantrikliği). Kestirici/ofset p.rN'yi (varsayılan p.r) sabit bilir; analiz sınıfı yine p.r ile.
%   p.rFn (isteğe bağlı, B3 aşınma): t [s] -> skaler çarpan; tesiste r(t) = p.r*rFn(t) (rA ile birlikte
%     r(t)(1 + rA sin ...)); makas dişlinin B yayı da r(t)'ye göre. rFn(0) = 1 olmalı. Kestirici p.rN'yi
%     bilir (değişmez). Analizdeki temas kenarı (side) ve ofsetYuz üst sınırı da o anki r(t)'yi kullanır.
%   p.yayE [N m] (B1-G 2b, yay dengeleme): kola artık tork -yayE sin(2 th) eklenir (yerçekimi terimine ek;
%     dengelenmiş kolda tesis mgl = 0 ile birlikte). Kestirici varsayılan olarak bilmez (p.yayEN, aşağıda).
%   p.FcL, p.FsL [N m] (B1-G 1b, kol yatağı/rulman sürtünmesi; varsayılan 0, FsL varsayılanı FcL): kola
%     motor tarafıyla aynı biçimde yumuşatılmış Stribeck sürtünmesi (FcL + (FsL - FcL) e^-(th'/vs)^2) tanh(th'/veps).
%     Kestirici bilmez (gözlemci yalnız motor tarafını modelliyor).
%   p.yayEN [N m] (varsayılan 0; B1-G 2b artığı): kestiricinin bildiği yay artığı. yuzKes/yuzKural ofsetine
%     yayEN sin(2 th_ref)/KsN eklenir (durağan dişli torku mgl sin th + yayE sin 2th'nin esneme payı).
%   p.dayama [N m] (varsayılan 0/kapalı; B1-G 1d, kol yatağı yapışmasına bilinçli dayama; yalnız yuzKes açıkken):
%     kestiricinin bildiği net durağan tork |mglN sin th_ref + yayEN sin 2th_ref| <= p.dayEsik (0,0042) olan
%     hedeflerde, motor ilk kez p.dayBekle (0,5) s durgun kalınca (yoklama dışında) dayama katsayısı kD
%     p.dayRampa (0,5) s'de 0 -> 1 çıkar ve öyle kalır. Ofsete sOf*kD*dayama/KsN (fazladan sıkışma), torka
%     sOf*kD*dayama ileri besleme eklenir (integratör bununla çekişmez). Skaler ya da benzetim başına bir değer.
%   p.asHar = [E1 f1 E2 f2] [rad, motor mili tarafı]: AS5600 açıya bağlı harmonik hatası; motor ölçümüne
%     (nicemleme ve gürültüden önce) (E1 sin(psi + f1) + E2 sin(2 psi + f2))/N eklenir, psi = N phi.
% İsteğe bağlı yük bozucusu (zorlanmış cevap): p.dA sin(2 pi p.df (t - dT0)) [N m] kola etki eder,
% p.dT0 <= t < p.dT aralığında (dT0 varsayılan 0, dT Inf). p.x0, p.z0: önceki benzetimin son
% durumundan sürdürme.

th_ref = deg2rad(theta0_deg(:)');
yayEN = al(p,'yayEN',0);  yayKN = al(p,'KsN',p.Ks);   % ofsette yay artığının esnemesi (B1-G 2b, kestiricinin bildiği)
dA = 0;  df = 0;  dT = Inf;  dT0 = 0;
if isfield(p,'dA'), dA = p.dA;  df = p.df; end
if isfield(p,'dT'), dT = p.dT; end
if isfield(p,'dT0'), dT0 = p.dT0; end
bozucu = @(tt) dA*sin(2*pi*df*(tt-dT0))*(tt >= dT0 && tt < dT);
if isfield(p,'dB') && any(p.dB(:) ~= 0)          % sabit yük basamağı (B1)
    dB = p.dB(:)';  dBT0 = al(p,'dBT0',0);  dBT1 = al(p,'dBT1',Inf);
    bozucu = @(tt) dA*sin(2*pi*df*(tt-dT0))*(tt >= dT0 && tt < dT) + dB*(tt >= dBT0 && tt < dBT1);
end
refY = isfield(p,'refYol') && ~isempty(p.refYol);   % zamanla değişen referans (B1)
wc     = wc(:)';
n      = numel(th_ref);
J      = p.JM + p.JL;
Kp = J*wc.^2;  Kd = 2*0.7*J*wc;  Ki = Kp.*wc/4;
ppi = isfield(p,'kontrol') && strcmp(p.kontrol,'PPI');
if ppi, kpP = wc;  KV = p.KV.*ones(1,n);  KI = p.KI.*ones(1,n); end
motorD = strcmp(p.Dkaynak,'motor');
motorP = isfield(p,'Pkaynak') && strcmp(p.Pkaynak,'motor');  % konum hatası motor tarafından (phi)
ofs = zeros(1,n);  if isfield(p,'ofset'), ofs = p.ofset(:)'.*ones(1,n); end  % hedef ofseti [rad]
yuzMod = 0;                                        % 0 kapalı, 1 anlık, 2 durunca
if isfield(p,'ofsetYuz') && ~isempty(p.ofsetYuz)
    yuzMod = find(strcmp(p.ofsetYuz, {'anlik','durunca'}));
    if isfield(p,'yuz0'), yz = p.yuz0(:)'.*ones(1,n); else, yz = sign(sin(th_ref)); end
    yz(yz == 0) = 1;
    yuzV = 0.01; if isfield(p,'yuzV'), yuzV = p.yuzV; end
    yuzN = 200;  if isfield(p,'yuzN'), yuzN = p.yuzN; end
    durSay = zeros(1,n);  yuzDeg = zeros(1,n);  yuzDegAn = zeros(1,n);
    ofsG = p.mgl*sin(th_ref)/p.Ks;  ofs = yz*p.r + ofsG;
end
dyAc = false;                                      % kol yapışmasına dayama (B1-G 1d)
kesMod = 0;                                        % 0 kapalı, 1 edilgen, 2 olay, 3 yoklama, 4 olay+yoklama,
ykMod = false;  rOlc = false;                      % 5 momentum, 6 sta (B1-L literatür tabanları)
if isfield(p,'yuzKes') && ~isempty(p.yuzKes)
    kesMod = find(strcmp(p.yuzKes, {'edilgen','olay','yoklama','olay+yoklama','momentum','sta'}));
    if isempty(kesMod), error('bilinmeyen yuzKes: %s', p.yuzKes); end
    ykMod = kesMod == 3 || kesMod == 4;            % etken yoklama yalnız bu iki kipte
    sh = sign(sin(th_ref));  if isfield(p,'yuz0'), sh = p.yuz0(:)'.*ones(1,n); end
    sh(sh == 0) = 1;  sOf = sh;                    % s^ ve ofsetteki (rampalı) yüz
    rKah = al(p,'rNKahin', false);                   % kâhin karşılaştırması: rN = gerçek r(t) (B3)
    rN = al(p,'rN', p.r);                            % kestiricinin/ofsetin bildiği değerler (duyarlılık, iş sırası 4)
    ofsG = al(p,'mglN', p.mgl)*sin(th_ref)/al(p,'KsN', p.Ks);
    if yayEN ~= 0, ofsG = ofsG + yayEN*sin(2*th_ref)/yayKN; end
    ofs = sOf.*rN + ofsG;
    rampa  = al(p,'yuzRampa', 0.5);
    wo     = al(p,'gozW', 2*pi*40);
    JMN    = al(p,'JMN', p.JM);   bMN = al(p,'bMN', p.bM);
    FcN    = al(p,'FcN', p.Fc);   FsN = al(p,'FsN', p.Fs);
    tauE   = al(p,'tauEsik', 0.015); Nper = al(p,'Nper', 100);
    vEs    = al(p,'vEsik', 0.05);    vDur = al(p,'vDur', 0.01);
    yuzN   = al(p,'yuzN', 200);
    yokA   = al(p,'yokA', 0.12);     yokD = al(p,'yokD', deg2rad(0.5));
    yokEs  = al(p,'yokEsik', 0.04);  yokTmax = al(p,'yokTmax', 0.3);
    yokTmin = al(p,'yokTmin', 3/wo);                % gözlemcinin eski tutma torkunu unutma süresi
    yokBek = al(p,'yokBekle', 0.5);  yokPer = al(p,'yokPer', Inf);  yokMaks = al(p,'yokMaks', 6);
    yokBant = al(p,'yokBant', deg2rad(1));
    yokOrta = al(p,'yokOrta', 0.5);  vDurF = al(p,'vDurF', Inf);
    aDur = 1 - exp(-2*pi*vDurF*p.Ts);  whF = zeros(1,n);   % durgunluk kararı için süzülmüş w^ (Inf: süzgeç yok)
    l1 = 3*wo;  l2 = 3*wo^2;  l3 = JMN*wo^3;
    yokEtkin = ykMod & abs(th_ref - pi) <= yokBant + 1e-12;
    ybMod = find(strcmp(al(p,'yokBolge','180'), {'180','180+360','tork'}));
    if isempty(ybMod), error('bilinmeyen yokBolge: %s', p.yokBolge); end
    if ybMod == 2
        yokEtkin = yokEtkin | (ykMod & abs(mod(th_ref + pi, 2*pi) - pi) <= yokBant + 1e-12);
    end
    yokEtkin0 = yokEtkin;
    yokTE = al(p,'yokTorkEsik', al(p,'mglN',p.mgl)*sin(deg2rad(1)));
    tyAc = al(p,'thYildiz', false);                % θ* hedef kaydırma (yükün yarattığı sıfır tork noktası)
    tyMgl = al(p,'mglN', p.mgl);  tyKs = al(p,'KsN', p.Ks);
    aTy = 1 - exp(-2*pi*al(p,'tyF', 1)*p.Ts);
    tyMin = tyMgl*sin(al(p,'tyEps', deg2rad(0.5)));  tyK = al(p,'tyK', 0.75);
    tyMaks = al(p,'tyMaks', deg2rad(0.5));  tyBas = al(p,'tyBas', 1);
    dhF = zeros(1,n);  tyD = zeros(1,n);  tyS = zeros(1,n);
    tyAra = al(p,'tyArama', false);  tyHiz = al(p,'tyHiz', deg2rad(0.25));   % arama: kaydırma hızı [rad/s]
    tyAv = zeros(1,n);  tyThOnc = th_ref;  tyCap = zeros(1,n);  tyDon = false(1,n);
    wh = zeros(1,n);  dh = zeros(1,n);           % ph (phi^) başlangıç durumundan sonra kurulur
    perSay = zeros(1,n);  perIs = zeros(1,n);  durSay = zeros(1,n);
    yuzDeg = zeros(1,n);  yuzDegAn = zeros(1,n);
    yk = false(1,n);  ykF = zeros(1,n);  ykT = zeros(1,n);  ykPhi0 = zeros(1,n);  ykDir = zeros(1,n);
    ykYon = zeros(1,n);  ykDm = zeros(1,n);
    ykSon = -Inf(1,n);  ykSay = zeros(1,n);  ykTemas = zeros(1,n);  ykTh0 = zeros(1,n);
    ykIzBit = -Inf(1,n);  ykKol = zeros(1,n);
    if al(p,'rOlc',false) && ~ykMod, error('rOlc yalnız yoklama kiplerinde'); end
    rOlc = ykMod && al(p,'rOlc',false);           % tam geçiş yoklaması: r ölçümü (B3)
    if rOlc
        rOlcV = al(p,'rOlcV', 0.1);  rOlcEs = al(p,'rOlcEsik', 0.01);  rOlcA = al(p,'rOlcA', 0.12);
        rOlcMk = al(p,'rOlcMaks', []);  rOlcTmax = al(p,'rOlcTmax', 3);   % boş: o anki 3 rN (rN güncellenebilir)
        gMod = find(strcmp(al(p,'rGun','yok'), {'yok','mutlak','fark'})) - 1;   % çevrim içi rN güncellemesi
        if isempty(gMod), error('bilinmeyen rGun: %s', p.rGun); end
        if gMod > 0 && al(p,'rNKahin',false), error('rGun ile rNKahin birlikte kullanılamaz'); end
        rGunK = al(p,'rGunK', 0.5);  rGunKapi = al(p,'rGunKapi', 0.3);  rN0 = rN.*ones(1,n);  rRef = NaN(1,n);  rD = zeros(1,n);
        wY = 2*pi*al(p,'rOlcW', 10);  rOKp = JMN*wY^2;  rOKd = 2*0.7*JMN*wY;
        rOKs = al(p,'KsN', p.Ks);  rOlcK = al(p,'rOlcKayit', 200);  rOvs = al(p,'vsN', p.vs);
        rOlcTb = al(p,'rOlcTb', 0.03);  ykMovT = zeros(1,n);
        rOR = NaN(rOlcK,n);  rOT = rOR;  rOY = rOR;  rOY2 = rOR;  rO1 = rOR;  rO2 = rOR;  rOK = rOR;  rOA = false(rOlcK,n);  rOU = rOA;  rOG = rOR;
        rOlcTut = al(p,'rOlcTut', deg2rad(0.75));
        rOn = zeros(1,n);  rOab = zeros(1,n);
        ykYa = zeros(1,n);  ykA = zeros(1,n);  ykT2 = zeros(1,n);  ykTau0 = zeros(1,n);
        ykP1 = zeros(1,n);  ykTau1 = zeros(1,n);  ykRef = zeros(1,n);  ykS0 = zeros(1,n);  ykHd = zeros(1,n);
        ykTt = zeros(1,n);  ykKolP = zeros(1,n);  ykMov = false(1,n);  ykU = zeros(1,n);
    end
    if kesMod == 5                                 % momentum gözlemcisi (B1-L, L1)
        mmL = al(p,'momL', 100);  mmE = al(p,'momEsik', 0.01);
        mmV = strcmp(al(p,'momV','fark'), 'gozlemci');
        mmI = zeros(1,n);  mmR = zeros(1,n);  mmY = [];
    end
    if kesMod == 6                                 % STA çarpma dedektörü (B1-L, L2)
        stL = al(p,'staL', 100);  stK2 = 1.1*stL;  stK1 = 2.028*sqrt(stK2);
        stE = al(p,'staEsik', 10*p.qM);  stX = [];  stW = zeros(1,n);
        stU = al(p,'staUyar', [0 2 1]);  stMaks = al(p,'staMaks', 3);
        stA = false(1,n);  stT = zeros(1,n);  stSay = zeros(1,n);
        stEtkin = abs(th_ref - pi) <= yokBant + 1e-12;
    end
    dyAc = any(al(p,'dayama',0) ~= 0);
    if dyAc                                        % kol yapışmasına dayama (B1-G 1d)
        dyT = p.dayama(:)'.*ones(1,n);  dyKs = al(p,'KsN', p.Ks);
        dyBek = al(p,'dayBekle', 0.5);  dyRam = al(p,'dayRampa', 0.5);
        dyEtkin = abs(al(p,'mglN', p.mgl)*sin(th_ref) + yayEN*sin(2*th_ref)) <= al(p,'dayEsik', 0.0042) + 1e-12;
        dyBas = false(1,n);  dyK = zeros(1,n);
    end
end
if kesMod == 0 && any(al(p,'dayama',0) ~= 0), error('dayama yalnız yuzKes açıkken'); end
kurMod = 0;                                       % 0 kapalı, 1 panasonic, 2 toyoda, 3 lenze (B1)
if isfield(p,'yuzKural') && ~isempty(p.yuzKural)
    if kesMod > 0 || yuzMod > 0, error('yuzKural, yuzKes ve ofsetYuz ile birlikte kullanılamaz'); end
    kurMod = find(strcmp(p.yuzKural, {'panasonic','toyoda','lenze'}));
    if isempty(kurMod), error('bilinmeyen yuzKural: %s', p.yuzKural); end
    if kurMod == 1 && ~ppi, error('yuzKural = ''panasonic'' yalnız PPI ile (hız komutu)'); end
    sh = sign(sin(th_ref));  if isfield(p,'yuz0'), sh = p.yuz0(:)'.*ones(1,n); end
    sh(sh == 0) = 1;  sOf = sh;  kYon = sh;  kS = sh;
    rN = al(p,'rN', p.r);  rampa = al(p,'yuzRampa', 0.5);
    ofsG = al(p,'mglN', p.mgl)*sin(th_ref)/al(p,'KsN', p.Ks);
    if yayEN ~= 0, ofsG = ofsG + yayEN*sin(2*th_ref)/yayKN; end
    ofs = sOf.*rN + ofsG;
    kuralV = al(p,'kuralV', 0.05);  kuralT1 = al(p,'kuralT1', 0.02);  kuralT2 = al(p,'kuralT2', 0.04);
    kuralU = al(p,'kuralU', 0.01);
    yuzDeg = zeros(1,n);  yuzDegAn = zeros(1,n);
end
if refY                                            % ofsetin yerçekimi katsayısı (yuzKes/yuzKural)
    ofsGk = al(p,'mglN', p.mgl)/al(p,'KsN', p.Ks);
end
wKom = zeros(1,n);                                 % son hız komutu (P-PI wcmd; panasonic)

% Başlangıç: kol hedefin p.adim derece altında, durgun, dişli boşluğun ortasında
x = zeros(4,n);
if refY, x(3,:) = p.refYol(0) - deg2rad(p.adim); else, x(3,:) = th_ref - deg2rad(p.adim); end
x(1,:) = x(3,:);
z = zeros(1,n);  u = zeros(1,n);
if isfield(p,'x0'), x = p.x0;  z = p.z0; end        % önceki benzetimin son durumundan sürdür
gMs = round(al(p,'gM',0)/p.dt);  nM = al(p,'nM',0);    % motor ölçümü: gecikme [adım], gürültü
if gMs > 0, phBuf = repmat(x(1,:), gMs+1, 1); end
if nM > 0
    rng(al(p,'nTohum',1));  olcM = @(xx) olc(xx + nM*randn(size(xx)), p.qM);
else
    olcM = @(xx) olc(xx, p.qM);
end
asH = al(p,'asHar',[0 0 0 0]);                     % AS5600 harmonik hatası (B1-M)
if any(asH([1 3]) ~= 0)
    olcM0 = olcM;  asN = p.N;
    olcM = @(xx) olcM0(xx + (asH(1)*sin(asN*xx + asH(2)) + asH(3)*sin(2*asN*xx + asH(4)))/asN);
end
cogA = al(p,'cogA',0);  cogK = al(p,'cogK',12);  cogF = al(p,'cogF',0);   % model dışı tesis etkileri (B1-M)
sfA = al(p,'sfA',0);  sfF = al(p,'sfF',0);
rAc = al(p,'rA',0);  rKc = al(p,'rK',1);  rFc = al(p,'rF',0);
rFnAc = isfield(p,'rFn') && ~isempty(p.rFn);      % zamanla değişen boşluk çarpanı (B3)
yayE = al(p,'yayE',0);                            % yay dengelemenin artık torku (B1-G 2b)
FcL = al(p,'FcL',0);  FsL = al(p,'FsL',FcL);       % kol tarafı Coulomb/yapışma sürtünmesi (B1-G 1b)
surL = FcL > 0 || FsL > 0;
if kesMod > 0, ph = olc(x(1,:), p.qM); end
ua = u;  aAk = 1 - exp(-al(p,'akimW',Inf)*p.dt);       % akım döngüsü (Inf: tork = komut)
tOlc = kesMod > 0 && al(p,'tOlc',false);           % gözlemci torku ölçümden mi (iş sırası 5)
if tOlc
    tG = round(al(p,'tGec',0)/p.dt);  tP = max(1, round(al(p,'tPen',p.Ts)/p.dt));
    tGur = al(p,'tGur',0);  tOfs = al(p,'tOfs',0);  tKaz = al(p,'tKaz',1);
    tAkis = RandStream('mt19937ar', 'Seed', al(p,'tTohum',2));   % motor gürültüsünden ayrı akış
    tBuf = repmat(u, tG+tP, 1);
end
fKay = isfield(p,'FcKay') && ~isempty(p.FcKay);   % sürtünme kayması (iş sırası 5b)
if fKay, fKayK = p.FcKay;  fKayT = al(p,'FcKayT',p.T); end
onY = al(p,'onYuk',0) ~= 0;                       % makas dişli ön yükü (B2)
if onY
    oTp = p.taup(:)'.*ones(1,n);  oKp = p.Kp(:)'.*ones(1,n);  oMu = al(p,'muP',0);
    oFn = isfield(p,'taupFn') && ~isempty(p.taupFn);
    surVar = p.Fc > 0 || (oMu > 0 && any(oTp > 0));
else
    surVar = p.Fc > 0;
end
elk = al(p,'motorElk',0);                          % motorun elektrik tarafı (iş sırası 5c)
if elk > 0
    if ~any(elk == [1 2 3]), error('motorElk 1, 2 ya da 3 olmalı'); end
    if ~isinf(al(p,'akimW',Inf)), error('motorElk ile akimW birlikte kullanılamaz'); end
    eVs = al(p,'Vs',12);  eKm = al(p,'Km', eVs/(333*2*pi/60));  eRa = al(p,'Ra', eKm*eVs/0.49);
    eLa = al(p,'La',2.5e-3);  eIl = al(p,'Ilim', (2/2.3)*eVs/eRa);
    eKmN = al(p,'KmN',eKm);  eRaN = al(p,'RaN',eRa);
    ewi = 2*pi*al(p,'akimBant',500);  eKpi = eLa*ewi;  eKii = eRa*ewi;
    if size(x,1) < 5, x(5,:) = 0; end               % akım (p.x0 4 satırsa 0'dan)
    elkVg = strcmp(al(p,'elkV','kontrol'), 'gozlemci');
    if elkVg && kesMod == 0, error('elkV = ''gozlemci'' yalnız yuzKes açıkken'); end
    eV = zeros(1,n);  eZi = zeros(1,n);  eIadc = x(5,:);  iTepe = zeros(1,n);  eDoy = zeros(1,n);
end
gL = 0;  if isfield(p,'gL'), gL = p.gL; end
thBuf = repmat(olc(x(3,:), p.qL), gL+1, 1);        % gecikme tamponu (en eski satır kullanılır)
if motorD, qv = p.qM; else, qv = p.qL; end
yv_prev = olc(x(1+2*~motorD,:), qv);  vhat = zeros(1,n);
aV = 1 - exp(-2*pi*p.fv*p.Ts);                     % filtre katsayısı (fv=Inf -> 1)
Iolu = 0;  if isfield(p,'Iolu'), Iolu = p.Iolu; end
Isif = isfield(p,'Isifirla') && p.Isifirla;
e_onc = zeros(1,n);
ktlD = isfield(p,'ktlDis') && ~isempty(p.ktlDis);  % dış kontrolcü (PIL)
if ktlD && (kesMod == 0 || n ~= 1), error('ktlDis yalnız yuzKes açıkken ve n = 1 iken'); end
ktlK = kesMod > 0 && (al(p,'ktlKayit',false) || ktlD);   % kontrol örneklerinin kaydı (ESP32 eşdeğerlik)
vKay = al(p,'vKaynak','olcum');                      % kontrolcünün hız kaynağı
vGoz = strcmp(vKay,'gozlemci');
if ~vGoz && ~strcmp(vKay,'olcum'), error('bilinmeyen vKaynak: %s', vKay); end
if vGoz && kesMod == 0, error('vKaynak = ''gozlemci'' yalnız yuzKes açıkken (gözlemci orada)'); end

nStep = round(p.T/p.dt);
kCtl  = max(1, round(p.Ts/p.dt));
iAn   = round((p.T-p.Tan)/p.dt);
nRec  = floor((nStep-iAn)/p.dec);
TH = zeros(nRec,n);  DEL = zeros(nRec,n);  TAU = zeros(nRec,n);  U = zeros(nRec,n);
if kesMod > 0, SH = zeros(nRec,n);  DH = zeros(nRec,n); end
if kurMod > 0, SH = zeros(nRec,n); end
kEk = al(p,'kayitEk',false);                       % ek kayıt (B2 bedel)
if kEk, WR = zeros(nRec,n);  if elk > 0, IR = zeros(nRec,n);  VR = zeros(nRec,n); end, end
k = 0;
if ktlK
    nK = ceil(nStep/kCtl);  kc = 0;  bos = zeros(nK,n);
    KT = struct('sayim',bos,'v',bos,'uo',bos,'u',bos,'wh',bos,'dh',bos,'sOf',bos,'sh',bos,'ykF',bos);
    KT.ilkSayim = round(ph/p.qM);
    if ktlD, KT.uM = bos;  KT.kart = []; end
end

for i = 0:nStep-1
    if gMs > 0, phBuf = [phBuf(2:end,:); x(1,:)]; end   % en eski satır gMs adım önceki phi
    if mod(i,kCtl) == 0                            % ---- kontrolcü örneği ----
        if gMs > 0, ymot = olcM(phBuf(1,:)); else, ymot = olcM(x(1,:)); end   % motor ölçümü (bir kez)
        if motorP, thm = ymot; else, thm = olc(x(3,:), p.qL); end
        if gL > 0, thBuf = [thBuf(2:end,:); thm];  thm = thBuf(1,:); end
        if isinf(p.fv)
            v = motorD*x(2,:) + ~motorD*x(4,:);
        else
            if motorD, yv = ymot; else, yv = olc(x(3,:), qv); end
            vhat = vhat + aV*((yv - yv_prev)/p.Ts - vhat);
            yv_prev = yv;  v = vhat;
        end
        if refY                                    % zamanla değişen referans
            thr = p.refYol(i*p.dt);
            if kesMod > 0 || kurMod > 0
                ofsG = ofsGk*sin(thr);  if yayEN ~= 0, ofsG = ofsG + yayEN*sin(2*thr)/yayKN; end
            end
        else
            thr = th_ref;
        end
        if yuzMod > 0                              % üst sınır: yüz ikizin gerçek deltasından
            if rFnAc, rY = p.r*p.rFn(i*p.dt); else, rY = p.r; end   % ikizin o anki gerçek r'si (B3)
            dl = x(1,:) - x(3,:);  tm = abs(dl) >= rY;
            if yuzMod == 2
                durSay = (durSay + 1).*(abs(x(4,:)) < yuzV);
                tm = tm & durSay >= yuzN;
            end
            yy = yz;  yy(tm) = sign(dl(tm));
            dg = yy ~= yz;  yuzDeg = yuzDeg + dg;  yuzDegAn = yuzDegAn + dg*(i >= iAn);
            yz = yy;  ofs = yz*rY + ofsG;
        end
        if kesMod > 0                              % yüz kestirici: yalnız enkoder + u
            tt = i*p.dt;  shOnc = sh;
            if rKah, if rFnAc, rN = p.r*p.rFn(tt)*ones(1,n); else, rN = p.r*ones(1,n); end, end   % kâhin: gerçek r(t)
            y  = ymot;
            eo = y - ph;                           % gözlemci (u: son uygulanan tork)
            ph = ph + p.Ts*(wh + l1*eo);
            if tOlc                                % gözlemcinin gördüğü tork: INA228 ölçümü
                bt = tBuf(end-tG-tP+1:end-tG, :);
                uo = tKaz*(sum(bt, 1)/tP) + tOfs + tGur*randn(tAkis, 1, n);
            else
                uo = u;
            end
            wh = wh + p.Ts*((uo - bMN*wh - dh)/JMN + l2*eo);
            dh = dh - p.Ts*l3*eo;
            if isinf(vDurF), whF = wh; else, whF = whF + aDur*(wh - whF); end
            durSay = (durSay + 1).*(abs(whF) < vDur);
            if kesMod == 1                         % edilgen: durgunken sign(u)
                d1 = durSay >= yuzN & u ~= 0;  sh(d1) = sign(u(d1));
            end
            if kesMod == 2 || kesMod == 4          % olay: sürtünme aralığını aşan dişli torku
                sg = sign(wh).*(abs(wh) > vEs);
                a1 = dh - sg*FsN;  a2 = dh - sg*FcN;  dur0 = (sg == 0)*FsN;
                lo = min(a1,a2) - dur0;  hi = max(a1,a2) + dur0;
                ad = (lo > tauE) - (hi < -tauE);
                perSay = (perSay + 1).*(ad ~= 0 & ad == perIs);  perIs = ad;
                d2 = ad ~= 0 & perSay >= Nper;
                if kesMod == 4, d2 = d2 & ykF == 0 & tt - ykSon > yokTmin; end   % yoklama torku olay sayılmaz
                sh(d2) = ad(d2);
            end
            if kesMod == 5                         % momentum gözlemcisi: r -> -d, s^ = sign(dişli torku)
                if isempty(mmY), mmY = y; end
                if mmV, wm = wh; else, wm = (y - mmY)/p.Ts; end
                mmY = y;
                mmI = mmI + p.Ts*(uo - bMN*wm + mmR);       % ∫(u - b w + r)
                mmR = mmL*(JMN*wm - mmI);
                sgm = sign(wh).*(abs(wh) > vEs);
                tsM = -mmR - sgm*FcN;                       % d - nominal Coulomb = dişli torku kestirimi
                sh(tsM > mmE) = 1;  sh(tsM < -mmE) = -1;    % histerezis: |tsM| <= mmE iken s^ tutulur
            end
            if kesMod == 6                         % STA (model yok): çarpma = ani yavaşlama tepesi
                if isempty(stX), stX = y; end
                ee = y - stX;
                stX = stX + p.Ts*(stW + stK1*sqrt(abs(ee)).*sign(ee));
                stW = stW + p.Ts*stK2*sign(ee);
                dd = abs(ee) > stE & sign(ee) == -sign(stW) & abs(stW) > vEs;
                sh(dd) = sign(stW(dd));                     % çarpılan yüz = motorun hareket yönü
                if stU(1) > 0                               % uyarım (makalenin S1'i): 180° bandında, durgunken
                    stT(stA) = stT(stA) + p.Ts;  stA(stT >= stU(3)) = false;
                    bas = stEtkin & ~stA & durSay*p.Ts >= yokBek & stSay < stMaks;
                    stA(bas) = true;  stT(bas) = 0;  stSay = stSay + bas;
                end
            end
            if ykMod                         % etken yoklama (evreler: 1 it, 2 fren, 3 geri, 4 fren)
                yk = ykF > 0;  ykT(yk) = ykT(yk) + p.Ts;
                yol = ykDir.*(y - ykPhi0);
                tsY = ykDir.*dh - FcN;                              % itiş yönünde dişli torku tahmini
                bT = ykF == 1 & tsY > yokEs & ykT >= yokTmin & ykDir.*wh > vEs;  % temas: s^ = itiş yönü
                bS = ykF == 1 & ~bT & yol >= yokD;                  % serbest yol: boşluk -> s^ doğru
                ykF(bS) = 2;                                        % frenle, sonra geri getir
                b3 = ykF == 2 & ykDir.*wh <= 0;  ykF(b3) = 3;  ykDm(b3) = yol(b3);
                b4 = ykF == 3 & yol <= ykDm*yokOrta;   ykF(b4) = 4;
                bB = (ykF == 4 & (ykDir.*wh >= 0 | yol <= 0)) | bT | (yk & ykF < 10 & ykT >= yokTmax);
                ykF(bB) = 0;  ykSon(bB) = tt;  ykIzBit(bB & ~bT) = tt + 0.3;
                ykTemas = ykTemas + bT;  sh(bT) = ykDir(bT);
                if rOlc                              % tam geçiş: 11 yüz 1, 12 yüz 2, 13 yeniden yüz 1, 14 ortaya dön
                    ykTt(yk) = ykTt(yk) + p.Ts;
                    cp = ykF >= 11 & ykF <= 13;
                    yeniM = cp & ~ykMov & ykDir.*wh > 0.8*rOlcV;     % kalkıştaki yapışma torku temas sayılmasın
                    ykMov(yeniM) = true;  ykMovT(yeniM) = tt;         % kopmadan sonra gözlemci rOlcTb s otursun
                    tsR = ykDir.*dh - (FcN + (FsN - FcN)*exp(-(wh/rOvs).^2));   % itiş yönünde dişli torku (Stribeck'li)
                    cc = cp & ykMov & tt - ykMovT >= rOlcTb & ykT >= yokTmin & tsR > rOlcEs;
                    c1 = cc & ykF == 11;  c2 = cc & ykF == 12;  c3 = cc & ykF == 13;
                    for j = find(c2 | c3)                            % geçiş yolu: 2r^ = yol - (tau_a + tau_b)/KsN
                        yR = abs(y(j) - ykP1(j));  e2r = yR - (ykTau1(j) + tsR(j))/rOKs;
                        if c2(j), ykYa(j) = e2r;  ykA(j) = yR;  ykT2(j) = tsR(j);  continue; end
                        rOn(j) = rOn(j) + 1;  m = min(rOn(j), rOlcK);
                        rOR(m,j) = (ykYa(j) + e2r)/4;                % iki yönün ortalaması: kolun yavaş kayması birinci mertebede düşer
                        rOA(m,j) = abs(ykA(j) - yR) <= rOlcTut;      % iki geçiş tutarlı mı (kol oynamadı mı; yalnız motor)
                        if numel(rN) == 1, rN = rN*ones(1,n); end
                        if gMod == 2 && ~isnan(rRef(j)), yen = rOR(m,j) - rRef(j) - rD(j); else, yen = rOR(m,j) - rN(j); end
                        rOU(m,j) = rOA(m,j) && abs(yen) <= rGunKapi*rN(j);   % akla yatkınlık (yenilik): aşınma yavaş
                        if gMod > 0 && rOU(m,j)                      % rN güncellemesi (tutarlı ve akla yatkın ölçüm)
                            if gMod == 1                             % mutlak: üstel ortalama
                                rN(j) = rN(j) + rGunK*(rOR(m,j) - rN(j));
                            elseif isnan(rRef(j))                    % fark: ilk kabul edilen ölçüm başvuru (r = rN0 sayılır)
                                rRef(j) = rOR(m,j);
                            else
                                rD(j) = rD(j) + rGunK*(rOR(m,j) - rRef(j) - rD(j));  rN(j) = rN0(j) + rD(j);
                            end
                        end
                        rOG(m,j) = rN(min(j, numel(rN)));
                        rOT(m,j) = tt;  rOY(m,j) = ykA(j);  rOY2(m,j) = yR;  rO1(m,j) = ykTau0(j);  rO2(m,j) = ykT2(j);
                        rOK(m,j) = max(abs(x(3,j) - ykTh0(j)), ykKolP(j));   % kolun bu yoklamadaki en büyük hareketi (gerçek theta)
                    end
                    cy = c1 | c2 | c3;                               % temas: yönü çevir, yeni yol bu noktadan
                    ykTau0(c1) = tsR(c1);
                    ykP1(cy) = y(cy);  ykTau1(cy) = tsR(cy);
                    ykF(c1) = 12;  ykF(c2) = 13;  ykF(c3) = 14;
                    ykDir(cy) = -ykDir(cy);  ykRef(cy) = y(cy);  ykS0(cy) = y(cy);  ykT(cy) = 0;  ykMov(cy) = false;
                    ykHd(c3) = ykA(c3)/2;                            % ortaya: ilk geçiş yolunun yarısı
                    if isempty(rOlcMk), rOlcMax = 3*rN.*ones(1,n); else, rOlcMax = rOlcMk.*ones(1,n); end
                    ab1 = ykF == 11 & abs(y - ykPhi0) > rOlcMax;    % yüz 1 bulunamadı: bitir
                    ab2 = (ykF == 12 | ykF == 13) & ~cy & abs(y - ykP1) > rOlcMax;   % öbür yüz bulunamadı: ortaya dön
                    rOab = rOab + ab1 + ab2;
                    ykHd(ab2) = abs(y(ab2) - ykP1(ab2))/2;
                    ykF(ab2) = 14;  ykDir(ab2) = -ykDir(ab2);  ykRef(ab2) = y(ab2);  ykS0(ab2) = y(ab2);  ykT(ab2) = 0;
                    zA = ykF >= 11 & ykF <= 13 & ykTt >= rOlcTmax;  rOab = rOab + zA;
                    bR = ab1 | zA | (ykF == 14 & (ykDir.*(y - ykS0) >= ykHd | ykTt >= rOlcTmax + 1));
                    ykF(bR) = 0;  ykSon(bR) = tt;  ykIzBit(bR) = tt + 0.3;
                end
                if ybMod == 3, yokEtkin = yokEtkin0 | abs(dh) <= FsN + yokTE; end
                if rOlc && refY                      % tam geçiş + yol: bölge o anki referansa göre
                    yokEtkin = abs(thr - pi) <= yokBant + 1e-12;
                    if ybMod == 2, yokEtkin = yokEtkin | abs(mod(thr + pi, 2*pi) - pi) <= yokBant + 1e-12; end
                end
                bas = yokEtkin & ykF == 0 & durSay*p.Ts >= yokBek & (tt - ykSon) >= yokPer & ykSay < yokMaks;
                ykF(bas) = 1;  ykT(bas) = 0;  ykPhi0(bas) = y(bas);  ykDir(bas) = -sh(bas);
                ykTh0(bas) = x(3,bas);  ykSay = ykSay + bas;
                if rOlc                              % önce inanılan yüze (sh), sonra öbürüne
                    ykF(bas) = 11;  ykDir(bas) = sh(bas);  ykRef(bas) = y(bas);  ykMov(bas) = false;
                    ykTt(bas) = 0;  ykKolP(bas) = 0;
                end
                yk = ykF > 0;  ykYon = ykDir.*(1 - 2*(ykF == 2 | ykF == 3));   % evreye göre tork yönü
                izl = yk | tt <= ykIzBit;
                ykKol(izl) = max(ykKol(izl), abs(x(3,izl) - ykTh0(izl)));
                if rOlc
                    ykKolP(izl) = max(ykKolP(izl), abs(x(3,izl) - ykTh0(izl)));
                    ra = ykF >= 11;                  % yavaş yol izleyici: ref rOlcV ile ilerler
                    ykRef(ra) = ykRef(ra) + ykDir(ra)*rOlcV*p.Ts;
                    ykU = ykDir.*(FcN + rOKd*rOlcV) + rOKp*(ykRef - y) - rOKd*wh;
                    ykU = min(max(ykU, -rOlcA), rOlcA);
                end
            end
            if tyAc                                % θ*: net durağan tork küçükse hedefi en çok tyMaks kaydır
                tyYd = ykF > 0 | tt <= ykIzBit;    % yoklama sırasında d^ yoklama torkunu içerir
                dhF(~tyYd) = dhF(~tyYd) + aTy*(dh(~tyYd) - dhF(~tyYd));
                thr0 = thr;
                Lh = tyMgl*sin(thr0 + tyD) - dhF;  % dış yük kestirimi (kol: tau_s = mgl sin - yük)
                n0 = tyMgl*sin(thr0) - Lh;          % kaydırmasız hedefte beklenen net durağan tork
                tySg = sign(n0);  tySg(tySg == 0) = 1;
                if tyAra                            % arama: yüz avlanması sürdükçe hedefi kaydır
                    tyAv = tyAv*exp(-p.Ts/2) + (sh ~= shOnc);          % ~2 s pencerede s^ değişimi
                    rs = abs(thr0 - tyThOnc) < 1e-9;  tyThOnc = thr0;  % referans duruyor mu
                    tyS(~rs) = 0;  tyD(~rs) = 0;  tyCap(~rs) = 0;  tyDon(~rs) = false;
                    av = rs & tt >= tyBas & tyAv >= 1.5 & ~tyYd;
                    tyYeni = av & tyS == 0;  tyS(tyYeni) = tySg(tyYeni);
                    ta = av & tyS ~= 0;
                    yon = tyS.*sign(cos(thr0));  yon(yon == 0) = 1;     % net tork tyS yönüne gitsin
                    tyD(ta) = min(max(tyD(ta) + yon(ta)*tyHiz*p.Ts, -tyMaks), tyMaks);
                    uc = ta & abs(tyD) >= tyMaks - 1e-12;  tyCap(uc) = tyCap(uc) + p.Ts;  tyCap(~uc) = 0;
                    dn = tyCap >= 1 & ~tyDon;  tyS(dn) = -tyS(dn);  tyDon(dn) = true;  tyCap(dn) = 0;  % uçta 1 s: öbür yön
                else
                    tyAk = tt >= tyBas & abs(n0) < tyK*tyMin;
                    tyYeni = tyAk & tyS == 0;  tyS(tyYeni) = tySg(tyYeni);
                    tyS(abs(n0) > 2*tyMin) = 0;     % yük kalktı ya da değişti: kaydırmayı bırak
                    tyHd = zeros(1,n);  ta = tyS ~= 0;
                    tyHd(ta) = (tyS(ta)*tyMin - n0(ta))./(tyMgl*cos(thr0(ta)));
                    tyHd = min(max(tyHd, -tyMaks), tyMaks);
                    tyD = tyD + aTy*(tyHd - tyD);
                end
                thr = thr0 + tyD;  ofsG = tyMgl/tyKs*sin(thr);
                if yayEN ~= 0, ofsG = ofsG + yayEN*sin(2*thr)/yayKN; end
            end
            dg = sh ~= shOnc;  yuzDeg = yuzDeg + dg;  yuzDegAn = yuzDegAn + dg*(i >= iAn);
            if ykMod, ykSon(dg & ykF == 0) = -Inf; end   % yüz değişti: oturunca yeniden yokla
            if rampa > 0
                adm = 2*p.Ts/rampa;  sOf = sOf + max(min(sh - sOf, adm), -adm);
            else
                sOf = sh;
            end
            ofs = sOf.*rN + ofsG;
            if dyAc                                % dayama: ilk durgunluktan sonra rampayla, kalıcı
                dyBas = dyBas | (dyEtkin & ykF == 0 & durSay*p.Ts >= dyBek);
                if dyRam > 0, dyK(dyBas) = min(dyK(dyBas) + p.Ts/dyRam, 1); else, dyK(dyBas) = 1; end
                ofs = ofs + sOf.*dyK.*dyT/dyKs;
            end
        end
        if kurMod > 0                             % komut tabanlı taban kurallar (B1)
            shOnc = sh;
            if kurMod == 3                         % lenze: tork işareti, histerezisli
                kS(u > kuralU) = 1;  kS(u < -kuralU) = -1;
            else
                if kurMod == 1, wy = wKom; else, wy = v; end   % panasonic: hız komutu, toyoda: dönüş
                kYon(wy > kuralV) = 1;  kYon(wy < -kuralV) = -1;
                tg = al(p,'mglN', p.mgl)*sin(thr);  sg = sign(tg);  sg(sg == 0) = kYon(sg == 0);
                if kurMod == 1
                    kk = min(max((kuralT2 - abs(tg))/(kuralT2 - kuralT1), 0), 1);
                    kS = kk.*kYon + (1 - kk).*sg;
                else
                    kS = kYon;  bg = abs(tg) > kuralT1;  kS(bg) = sg(bg);
                end
            end
            sh(kS ~= 0) = sign(kS(kS ~= 0));
            dg = sh ~= shOnc;  yuzDeg = yuzDeg + dg;  yuzDegAn = yuzDegAn + dg*(i >= iAn);
            if rampa > 0
                adm = 2*p.Ts/rampa;  sOf = sOf + max(min(kS - sOf, adm), -adm);
            else
                sOf = kS;
            end
            ofs = sOf.*rN + ofsG;
        end
        if vGoz, v = wh; end                       % hız = bu örnekte güncellenmiş w^ (kart: HIZ_GOZLEMCI)
        e  = thr + ofs - thm;
        if ppi
            wKom = kpP.*e;                         % hız komutu (panasonic kuralı bir sonraki örnekte kullanır)
            ev = kpP.*e - v;                       % hız hatası (kol tarafı)
            u0 = KV.*ev + KI.*z;
            iz = ev;
        else
            u0 = Kp.*e + Ki.*z - Kd.*v;
            iz = e;
        end
        if dyAc, u0 = u0 + sOf.*dyK.*dyT; end     % dayama torku ileri besleme
        u  = min(max(u0,-p.Tmax),p.Tmax);
        doy = (u0 > p.Tmax & iz > 0) | (u0 < -p.Tmax & iz < 0);
        if Isif, z(e.*e_onc < 0) = 0; end          % hata işaret değiştirdi: integrali sıfırla
        e_onc = e;  zOnc = z;
        z  = z + iz*p.Ts .* ~doy .* (abs(e) >= Iolu);  % basit anti-windup + ölü bant
        if ykMod                             % yoklama sırasında kontrolcü donar
            u(yk) = min(max(yokA*ykYon(yk), -p.Tmax), p.Tmax);  z(yk) = zOnc(yk);   % mutlak itiş torku
            if rOlc, ra = ykF >= 11;  u(ra) = min(max(ykU(ra), -p.Tmax), p.Tmax); end   % tam geçiş izleyicisi
        end
        if kesMod == 6 && stU(1) > 0               % STA uyarımı: kontrolcü çalışır, integral donar, sinüs eklenir
            u(stA) = min(max(u(stA) + stU(1)*sin(2*pi*stU(2)*stT(stA)), -p.Tmax), p.Tmax);  z(stA) = zOnc(stA);
        end
        u(abs(u) < p.olu) = 0;                    % sürücü ölü bandı
        if ktlK
            kc = kc + 1;
            if ktlD                                % PIL: tesise dış kontrolcünün u'su
                KT.uM(kc,:) = u;
                [u, cK] = p.ktlDis(kc, round(ymot/p.qM), v, uo, KT.ilkSayim);
                if kc == 1, KT.kart = zeros(nK, numel(cK)); end
                KT.kart(kc,:) = cK;
            end
            KT.sayim(kc,:) = round(ymot/p.qM);  KT.v(kc,:) = v;  KT.uo(kc,:) = uo;  KT.u(kc,:) = u;
            KT.wh(kc,:) = wh;  KT.dh(kc,:) = dh;  KT.sOf(kc,:) = sOf;  KT.sh(kc,:) = sh;  KT.ykF(kc,:) = ykF;
        end
    end
    if elk > 0                                     % sürücü (blok_surucu.m'nin vektör yazımı)
        ew = x(2,:);
        if elk == 3
            ee = min(max(u/eKmN, -eIl), eIl) - eIadc;  eVc = eKpi*ee + eZi;
        elseif elk == 2
            if elkVg, eVc = eRaN*u/eKmN + eKmN*wh; else, eVc = eRaN*u/eKmN + eKmN*v; end
        else
            eVc = eRaN*u/eKmN;
        end
        eV = min(max(eVc, eKm*ew - eRa*eIl), eKm*ew + eRa*eIl);   % DRV8874 akım sınırı
        eV = min(max(eV, -eVs), eVs);                             % besleme
        if elk == 3                                               % anti-windup
            aw = eV == eVc | (eV < eVc & ee < 0) | (eV > eVc & ee > 0);
            eZi = eZi + eKii*p.dt*ee.*aw;
        end
        eDoy = eDoy + (eV ~= eVc);
        eIadc = x(5,:);  iTepe = max(iTepe, abs(x(5,:)));
        ua = eKm*x(5,:);                           % adım başındaki tork (INA228 kaydı için)
    elseif aAk == 1, ua = u; else, ua = ua + aAk*(u - ua); end   % tesise uygulanan tork (akım döngüsü)
    if tOlc, tBuf = [tBuf(2:end,:); ua]; end       % son satır: bu adımda uygulanan tork
    tt = i*p.dt;
    k1 = f(x, tt);  k2 = f(x+0.5*p.dt*k1, tt+0.5*p.dt);  k3 = f(x+0.5*p.dt*k2, tt+0.5*p.dt);
    k4 = f(x+p.dt*k3, tt+p.dt);
    x = x + p.dt/6*(k1+2*k2+2*k3+k4);
    ii = i+1;
    if ii > iAn && mod(ii-iAn,p.dec)==0
        k = k+1;
        [~,ts] = f(x, tt+p.dt);
        TH(k,:) = x(3,:);  DEL(k,:) = x(1,:)-x(3,:);  TAU(k,:) = ts;  U(k,:) = u;
        if kesMod > 0, SH(k,:) = sh;  DH(k,:) = dh; end
        if kurMod > 0, SH(k,:) = sh; end
        if kEk, WR(k,:) = x(2,:);  if elk > 0, IR(k,:) = x(5,:);  VR(k,:) = eV; end, end
    end
end

t = (1:nRec)'*p.dt*p.dec;
out.t = t;  out.th = TH;  out.delta = DEL;  out.tau_s = TAU;  out.u = U;
out.theta0_deg = theta0_deg;  out.wc = wc;
out.x_son = x;  out.z_son = z;
if ktlK, out.ktl = KT; end                     % p.x0, p.z0 ile sürdürmek için
if elk > 0, out.iTepe = iTepe;  out.Vdoy = eDoy/nStep; end
if kEk, out.w = WR;  if elk > 0, out.i = IR;  out.V = VR; end, end
if yuzMod > 0, out.yuzDegis = yuzDeg;  out.yuzDegisAn = yuzDegAn;  out.yuzSon = yz; end
if kurMod > 0, out.shat = SH;  out.yuzDegis = yuzDeg;  out.yuzDegisAn = yuzDegAn;  out.yuzSon = sh; end
if kesMod > 0
    out.shat = SH;  out.dhat = DH;  out.yuzDegis = yuzDeg;  out.yuzDegisAn = yuzDegAn;  out.yuzSon = sh;
    if rOlc || rKah, out.rNSon = rN.*ones(1,n); end   % B3: kestiricinin son bildiği r
    if ykMod, out.yokSay = ykSay;  out.yokKol = ykKol;  out.yokTemas = ykTemas; end
    if rOlc                                    % tam geçiş ölçümleri (B3; satır = ölçüm, sütun = benzetim)
        out.rOlc = struct('n', rOn, 'iptal', rOab, 't', rOT, 'rHat', rOR, 'yol', rOY, 'yol2', rOY2, 'tau1', rO1, ...
            'tau2', rO2, 'kol', rOK, 'kabul', rOA, 'gun', rOU, 'rN', rOG);
    end
    if kesMod == 6, out.staSay = stSay; end
    if tyAc, out.tyD = tyD; end
end

% --- Analiz ---
thd = rad2deg(TH);
out.A_deg = (max(thd)-min(thd))/2;                 % salınım genliği [derece]
if rFnAc                                           % kayıt anındaki gerçek r(t) (B3)
    rKay = p.r*arrayfun(p.rFn, (iAn + (1:nRec)'*p.dec)*p.dt);
    side = sign(DEL) .* (abs(DEL) >= rKay);
else
    side = sign(DEL) .* (abs(DEL) >= p.r);         % +1 / -1 temas kenarı, 0 boşlukta
end
out.gecis = zeros(1,n);  out.bosluk_orani = mean(side==0);
for j = 1:n
    s = side(:,j);  s = s(s~=0);
    out.gecis(j) = sum(abs(diff(s))>0);            % kenar değiştirme sayısı (analiz penceresinde)
end
out.f_Hz = out.gecis/2/p.Tan;
% Sınıflar (A esigi 0.05 der ~ AS5600 cozunurlugunun yarisi):
%   0 denge | 1 dişli bastırılı salınım (sürtünme/nicemleme) | 2 tek kenarlı boşluk salınımı
%   3 iki kenarlı boşluk salınımı | 4 kararsız
sal = out.A_deg > 0.05;
out.sinif = zeros(1,n);
out.sinif(sal & out.bosluk_orani <= 0.02) = 1;
out.sinif(sal & out.bosluk_orani >  0.02 & out.gecis < 2) = 2;
out.sinif(sal & out.gecis >= 2) = 3;
out.LC = out.sinif == 3;                           % geriye uyumluluk
sapma = abs(thd - theta0_deg(:)');
out.kararsiz = mean(sapma(end-round(end/3):end,:)) > 10 | max(sapma) > 45;
out.sinif(out.kararsiz) = 4;

    function [dx, ts] = f(x, tt)
        phi = x(1,:); dphi = x(2,:); th = x(3,:); dth = x(4,:);
        d = phi - th;  dd = dphi - dth;
        ts = zeros(size(d));
        if rFnAc, r0 = p.r*p.rFn(tt); else, r0 = p.r; end   % zamanla büyüyen boşluk (B3, aşınma)
        if rAc ~= 0                                % açıya bağlı boşluk (B1-M)
            rrr = r0*(1 + rAc*sin(rKc*th + rFc));
            sag = d >  rrr;  sol = d < -rrr;
            ts(sag) = max(p.Ks*(d(sag)-rrr(sag)) + p.cs*dd(sag), 0);
            ts(sol) = min(p.Ks*(d(sol)+rrr(sol)) + p.cs*dd(sol), 0);
        else
            sag = d >  r0;  sol = d < -r0;
            ts(sag) = max(p.Ks*(d(sag)-r0) + p.cs*dd(sag), 0);
            ts(sol) = min(p.Ks*(d(sol)+r0) + p.cs*dd(sol), 0);
        end
        if onY                                     % makas dişli: B yarısının yay kuvveti
            if oFn, tp = oTp*p.taupFn(tt); else, tp = oTp; end
            ts = ts - max(tp + oKp.*(r0 - d), 0);
            fc = p.Fc + oMu*tp;  fs = p.Fs + oMu*tp;
        else
            fc = p.Fc;  fs = p.Fs;
        end
        if surVar                                  % yumuşatılmış Stribeck sürtünmesi
            tf = (fc + (fs-fc).*exp(-(dphi/p.vs).^2)) .* tanh(dphi/p.veps);
            if fKay, tf = tf*(1 + (fKayK - 1)*min(tt/fKayT, 1)); end
            if sfA ~= 0, tf = tf.*(1 + sfA*sin(p.N*phi + sfF)); end   % konuma bağlı sürtünme (B1-M)
        else
            tf = 0;
        end
        if elk > 0, tm = eKm*x(5,:); else, tm = ua; end   % tesis torku
        if cogA ~= 0, tm = tm - cogA*sin(cogK*p.N*phi + cogF); end   % cogging (B1-M)
        dx = [dphi;
              (tm - p.bM*dphi - tf - ts)/p.JM;
              dth;
              (ts - p.bL*dth - p.mgl*sin(th) + bozucu(tt))/p.JL];
        if yayE ~= 0, dx(4,:) = dx(4,:) - yayE*sin(2*th)/p.JL; end   % yay dengeleme artığı (B1-G 2b)
        if surL                                    % kol yatağı sürtünmesi (B1-G 1b)
            dx(4,:) = dx(4,:) - (FcL + (FsL-FcL)*exp(-(dth/p.vs).^2)).*tanh(dth/p.veps)/p.JL;
        end
        if elk > 0, dx(5,:) = (eV - eRa*x(5,:) - eKm*dphi)/eLa; end
    end
end

function v = al(p, ad, vars)
% AL  p.(ad) varsa onu, yoksa varsayılanı döndürür.
if isfield(p, ad), v = p.(ad); else, v = vars; end
end

function y = olc(x, q)
% Nicemleme: q = 0 ise ideal.
if q > 0, y = q*floor(x/q); else, y = x; end
end
