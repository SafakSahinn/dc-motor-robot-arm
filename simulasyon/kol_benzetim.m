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
%   Ofsetteki r, K_s, mgl kestiricinin bildiği değerlerdir: p.rN, p.KsN, p.mglN (varsayılan: ikizin gerçeği).
%   Çıktı: out.shat (s^ kaydı), out.dhat, out.yuzDegis, out.yuzDegisAn, out.yuzSon,
%   out.yokSay (yoklama sayısı), out.yokKol (yoklama + 0,3 s içinde kolun en büyük hareketi [rad],
%   yalnız ölçüm için gerçek theta kullanılır), out.yokTemas (temas bulan yoklama sayısı).
% İsteğe bağlı yük bozucusu (zorlanmış cevap): p.dA sin(2 pi p.df (t - dT0)) [N m] kola etki eder,
% p.dT0 <= t < p.dT aralığında (dT0 varsayılan 0, dT Inf). p.x0, p.z0: önceki benzetimin son
% durumundan sürdürme.

th_ref = deg2rad(theta0_deg(:)');
dA = 0;  df = 0;  dT = Inf;  dT0 = 0;
if isfield(p,'dA'), dA = p.dA;  df = p.df; end
if isfield(p,'dT'), dT = p.dT; end
if isfield(p,'dT0'), dT0 = p.dT0; end
bozucu = @(tt) dA*sin(2*pi*df*(tt-dT0))*(tt >= dT0 && tt < dT);
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
kesMod = 0;                                        % 0 kapalı, 1 edilgen, 2 olay, 3 yoklama, 4 olay+yoklama
if isfield(p,'yuzKes') && ~isempty(p.yuzKes)
    kesMod = find(strcmp(p.yuzKes, {'edilgen','olay','yoklama','olay+yoklama'}));
    if isempty(kesMod), error('bilinmeyen yuzKes: %s', p.yuzKes); end
    sh = sign(sin(th_ref));  if isfield(p,'yuz0'), sh = p.yuz0(:)'.*ones(1,n); end
    sh(sh == 0) = 1;  sOf = sh;                    % s^ ve ofsetteki (rampalı) yüz
    rN = al(p,'rN', p.r);                            % kestiricinin/ofsetin bildiği değerler (duyarlılık, iş sırası 4)
    ofsG = al(p,'mglN', p.mgl)*sin(th_ref)/al(p,'KsN', p.Ks);  ofs = sOf*rN + ofsG;
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
    yokEtkin = (kesMod >= 3) & abs(th_ref - pi) <= yokBant + 1e-12;
    wh = zeros(1,n);  dh = zeros(1,n);           % ph (phi^) başlangıç durumundan sonra kurulur
    perSay = zeros(1,n);  perIs = zeros(1,n);  durSay = zeros(1,n);
    yuzDeg = zeros(1,n);  yuzDegAn = zeros(1,n);
    yk = false(1,n);  ykF = zeros(1,n);  ykT = zeros(1,n);  ykPhi0 = zeros(1,n);  ykDir = zeros(1,n);
    ykYon = zeros(1,n);  ykDm = zeros(1,n);
    ykSon = -Inf(1,n);  ykSay = zeros(1,n);  ykTemas = zeros(1,n);  ykTh0 = zeros(1,n);
    ykIzBit = -Inf(1,n);  ykKol = zeros(1,n);
end

% Başlangıç: kol hedefin p.adim derece altında, durgun, dişli boşluğun ortasında
x = zeros(4,n);
x(3,:) = th_ref - deg2rad(p.adim);
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
if kesMod > 0, ph = olc(x(1,:), p.qM); end
gL = 0;  if isfield(p,'gL'), gL = p.gL; end
thBuf = repmat(olc(x(3,:), p.qL), gL+1, 1);        % gecikme tamponu (en eski satır kullanılır)
if motorD, qv = p.qM; else, qv = p.qL; end
yv_prev = olc(x(1+2*~motorD,:), qv);  vhat = zeros(1,n);
aV = 1 - exp(-2*pi*p.fv*p.Ts);                     % filtre katsayısı (fv=Inf -> 1)
Iolu = 0;  if isfield(p,'Iolu'), Iolu = p.Iolu; end
Isif = isfield(p,'Isifirla') && p.Isifirla;
e_onc = zeros(1,n);

nStep = round(p.T/p.dt);
kCtl  = max(1, round(p.Ts/p.dt));
iAn   = round((p.T-p.Tan)/p.dt);
nRec  = floor((nStep-iAn)/p.dec);
TH = zeros(nRec,n);  DEL = zeros(nRec,n);  TAU = zeros(nRec,n);  U = zeros(nRec,n);
if kesMod > 0, SH = zeros(nRec,n);  DH = zeros(nRec,n); end
k = 0;

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
        if yuzMod > 0                              % üst sınır: yüz ikizin gerçek deltasından
            dl = x(1,:) - x(3,:);  tm = abs(dl) >= p.r;
            if yuzMod == 2
                durSay = (durSay + 1).*(abs(x(4,:)) < yuzV);
                tm = tm & durSay >= yuzN;
            end
            yy = yz;  yy(tm) = sign(dl(tm));
            dg = yy ~= yz;  yuzDeg = yuzDeg + dg;  yuzDegAn = yuzDegAn + dg*(i >= iAn);
            yz = yy;  ofs = yz*p.r + ofsG;
        end
        if kesMod > 0                              % yüz kestirici: yalnız enkoder + u
            tt = i*p.dt;  shOnc = sh;
            y  = ymot;
            eo = y - ph;                           % gözlemci (u: son uygulanan tork)
            ph = ph + p.Ts*(wh + l1*eo);
            wh = wh + p.Ts*((u - bMN*wh - dh)/JMN + l2*eo);
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
            if kesMod >= 3                         % etken yoklama (evreler: 1 it, 2 fren, 3 geri, 4 fren)
                yk = ykF > 0;  ykT(yk) = ykT(yk) + p.Ts;
                yol = ykDir.*(y - ykPhi0);
                tsY = ykDir.*dh - FcN;                              % itiş yönünde dişli torku tahmini
                bT = ykF == 1 & tsY > yokEs & ykT >= yokTmin & ykDir.*wh > vEs;  % temas: s^ = itiş yönü
                bS = ykF == 1 & ~bT & yol >= yokD;                  % serbest yol: boşluk -> s^ doğru
                ykF(bS) = 2;                                        % frenle, sonra geri getir
                b3 = ykF == 2 & ykDir.*wh <= 0;  ykF(b3) = 3;  ykDm(b3) = yol(b3);
                b4 = ykF == 3 & yol <= ykDm*yokOrta;   ykF(b4) = 4;
                bB = (ykF == 4 & (ykDir.*wh >= 0 | yol <= 0)) | bT | (yk & ykT >= yokTmax);
                ykF(bB) = 0;  ykSon(bB) = tt;  ykIzBit(bB & ~bT) = tt + 0.3;
                ykTemas = ykTemas + bT;  sh(bT) = ykDir(bT);
                bas = yokEtkin & ykF == 0 & durSay*p.Ts >= yokBek & (tt - ykSon) >= yokPer & ykSay < yokMaks;
                ykF(bas) = 1;  ykT(bas) = 0;  ykPhi0(bas) = y(bas);  ykDir(bas) = -sh(bas);
                ykTh0(bas) = x(3,bas);  ykSay = ykSay + bas;
                yk = ykF > 0;  ykYon = ykDir.*(1 - 2*(ykF == 2 | ykF == 3));   % evreye göre tork yönü
                izl = yk | tt <= ykIzBit;
                ykKol(izl) = max(ykKol(izl), abs(x(3,izl) - ykTh0(izl)));
            end
            dg = sh ~= shOnc;  yuzDeg = yuzDeg + dg;  yuzDegAn = yuzDegAn + dg*(i >= iAn);
            if kesMod >= 3, ykSon(dg & ykF == 0) = -Inf; end   % yüz değişti: oturunca yeniden yokla
            if rampa > 0
                adm = 2*p.Ts/rampa;  sOf = sOf + max(min(sh - sOf, adm), -adm);
            else
                sOf = sh;
            end
            ofs = sOf*rN + ofsG;
        end
        e  = th_ref + ofs - thm;
        if ppi
            ev = kpP.*e - v;                       % hız hatası (kol tarafı)
            u0 = KV.*ev + KI.*z;
            iz = ev;
        else
            u0 = Kp.*e + Ki.*z - Kd.*v;
            iz = e;
        end
        u  = min(max(u0,-p.Tmax),p.Tmax);
        doy = (u0 > p.Tmax & iz > 0) | (u0 < -p.Tmax & iz < 0);
        if Isif, z(e.*e_onc < 0) = 0; end          % hata işaret değiştirdi: integrali sıfırla
        e_onc = e;  zOnc = z;
        z  = z + iz*p.Ts .* ~doy .* (abs(e) >= Iolu);  % basit anti-windup + ölü bant
        if kesMod >= 3                             % yoklama sırasında kontrolcü donar
            u(yk) = min(max(yokA*ykYon(yk), -p.Tmax), p.Tmax);  z(yk) = zOnc(yk);   % mutlak itiş torku
        end
        u(abs(u) < p.olu) = 0;                     % sürücü ölü bandı
    end
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
    end
end

t = (1:nRec)'*p.dt*p.dec;
out.t = t;  out.th = TH;  out.delta = DEL;  out.tau_s = TAU;  out.u = U;
out.theta0_deg = theta0_deg;  out.wc = wc;
out.x_son = x;  out.z_son = z;                     % p.x0, p.z0 ile sürdürmek için
if yuzMod > 0, out.yuzDegis = yuzDeg;  out.yuzDegisAn = yuzDegAn;  out.yuzSon = yz; end
if kesMod > 0
    out.shat = SH;  out.dhat = DH;  out.yuzDegis = yuzDeg;  out.yuzDegisAn = yuzDegAn;  out.yuzSon = sh;
    if kesMod >= 3, out.yokSay = ykSay;  out.yokKol = ykKol;  out.yokTemas = ykTemas; end
end

% --- Analiz ---
thd = rad2deg(TH);
out.A_deg = (max(thd)-min(thd))/2;                 % salınım genliği [derece]
side = sign(DEL) .* (abs(DEL) >= p.r);             % +1 / -1 temas kenarı, 0 boşlukta
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
        sag = d >  p.r;  sol = d < -p.r;
        ts(sag) = max(p.Ks*(d(sag)-p.r) + p.cs*dd(sag), 0);
        ts(sol) = min(p.Ks*(d(sol)+p.r) + p.cs*dd(sol), 0);
        if p.Fc > 0                                % yumuşatılmış Stribeck sürtünmesi
            tf = (p.Fc + (p.Fs-p.Fc)*exp(-(dphi/p.vs).^2)) .* tanh(dphi/p.veps);
        else
            tf = 0;
        end
        dx = [dphi;
              (u - p.bM*dphi - tf - ts)/p.JM;
              dth;
              (ts - p.bL*dth - p.mgl*sin(th) + bozucu(tt))/p.JL];
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
