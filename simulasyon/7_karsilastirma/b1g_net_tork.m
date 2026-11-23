function b1g_net_tork
% B1-G: net durağan torku sıfıra yakın eklemler (genişletme planı, tur 67).
% Senaryo (ortam B1G_SEN):
%   '1'  (varsayılan) yatay eklem: tesiste mgl = 0, kestirici de mglN = 0 bilir. Kod değişikliği yok.
%   '2a' karşı ağırlık: tesiste mgl x 0,1 / x 0,05 (D'nin dik kolu), kestirici mglN doğru, x0,5, x1,5.
%        Başlangıç inancı doğru = sign(sin hedef) (180°'de ilk hareket yönü); darbe/yük işareti -s0.
%   '2b' yay dengeleme: tesiste mgl = 0 ve artık tork -yayE sin 2th (kol_benzetim p.yayE), yayE 0,5 / 1 / 2 F_c
%        (0,02 / 0,04 / 0,08 N m). Kestirici mglN = 0 (artığı bilmez). Başlangıç inancı sign(sin 2 hedef).
%   B1G_EPS=1: B1'in 180° kuralı (|hedef - 180| < 0,5° ise hedef = 180 - 0,5 Yf), önek sonuna 'e'.
% Ölçüt yeni (yerçekimi yok, sign(sin hedef) anlamsız): |e| <= 0,5°, e_max <= 1° (son 1 s) VE
% kestiricinin son yüzü (o.yuzSon) = tesisin son 1 s'deki gerçek dişli torku işareti. Gerçek tork son 1 s
% boyunca hiç oluşmadıysa (kol boşlukta serbest) yuzS = 0: H7 sayılmaz, ayrıca "temassız" olarak sayılır.
% Başlangıç inancı: doğru = ilk hareket yönü (kol hedefin altından/üstünden yaklaşır, motor o yöne iter).
% Yöntemler B1-M ile aynı 5 yöntem + olay+yok'un "her açıda yoklama" varyantı (yokBant = pi: bant her
% hedefi kapsar). yokTorkEsik sabit (D düzeneğinin nominal mgl sin 1° = 0,0042 N m): yalnız
% yokBolge = 'tork' kipinde kullanılır, burada kullanılmıyor ama mgl = 0'da varsayılanı 0 olduğundan
% belirsizlik bırakmamak için sabitlendi. Paralel: B1G_PARCA / B1G_NPAR. Özet: b1g_ozet.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
mglD = p0.mgl;                                       % nominal (dik kol) mgl
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;  p0.gM = 4e-4;  p0.akimW = 2*pi*500;
kpv = 0.50^2*p0.Ks/p0.KV;  tD = 3;
ortak = struct('tOlc', true, 'tPen', 0.54e-3, 'tGec', 0.1e-3, 'vKaynak', 'gozlemci', ...
               'yokTorkEsik', mglD*sin(deg2rad(1)));
M = {'olay', struct('yuzKes','olay','vDurF',10);
     'olay+yok', struct('yuzKes','olay+yoklama','yokOrta',0.6,'vDurF',10);
     'olay+yok her açı', struct('yuzKes','olay+yoklama','yokOrta',0.6,'vDurF',10,'yokBant',pi);
     'momentum L100 e0.06', struct('yuzKes','momentum','momL',100,'momEsik',0.06,'momV','gozlemci');
     'lenze 0.03', struct('yuzKural','lenze','kuralU',0.03);
     'edilgen', struct('yuzKes','edilgen','vDurF',10)};
qAS = 2*pi/(4096*30);  nAS = deg2rad(0.043)/p0.N;
as = struct('qM', qAS, 'nM', nAS);
sen = getenv('B1G_SEN');  if isempty(sen), sen = '1'; end
scSec = 1:5;
switch sen
    case '1'
        onek = 'b1g1';
        K = {'yatay mgl 0', struct('mgl', 0, 'mglN', 0)};
        istek = [45 120 180 270];
    case '2a'   % karşı ağırlık: tesiste mgl x 0,1 ve x 0,05; kestirici mglN doğru ya da ±%50 yanlış
        onek = 'b1g2a';  K = {};
        for c = [0.1 0.05]
            for f = [1 0.5 1.5]
                K(end+1,:) = {sprintf('mgl x%g, mglN x%g', c, f), struct('mgl', c*mglD, 'mglN', f*c*mglD)}; %#ok<AGROW>
            end
        end
        istek = [45 120 180 270];
    case '2b'   % yay dengeleme: tesiste mgl = 0 + artık -yayE sin 2th; kestirici mglN = 0 (artığı bilmez)
        onek = 'b1g2b';  K = {};
        for c = [0.5 1 2]
            K(end+1,:) = {sprintf('yayE %gFc', c), struct('mgl', 0, 'mglN', 0, 'yayE', c*0.04)}; %#ok<AGROW>
        end
        istek = [45 120 180 270];   % sin 2th: 45/120 büyük, 180 kararlı sıfır, 270 kararsız sıfır
    case '3'    % dış bozucu, net torku küçük eklemde (2a: mgl x0,05 ve x0,1, mglN doğru); yalnız temel senaryo
        onek = 'b1g3';  K = {};  scSec = 1;
        for c = [0.05 0.1]
            j0 = struct('mgl', c*mglD, 'mglN', c*mglD);
            for f = [1 5 25]
                for A = [0.005 0.01 0.02 0.05]
                    K(end+1,:) = {sprintf('mgl x%g dA %g Hz %g', c, f, A), ek(j0, struct('bA', A, 'df', f, 'dT0', tD, 'dT', tD + 2))}; %#ok<AGROW>
                end
            end
            for B = [0.005 0.01 0.02]
                K(end+1,:) = {sprintf('mgl x%g dB %g', c, B), ek(j0, struct('bB', B, 'dBT0', tD))}; %#ok<AGROW>
            end
        end
        istek = [45 120 180 270];
    otherwise, error('bilinmeyen B1G_SEN: %s', sen);
end
epsK = strcmp(getenv('B1G_EPS'), '1');            % B1G_EPS=1: 180° ε kuralı (önek sonuna 'e')
if epsK, onek = [onek 'e']; end
sc_ad = {'temel', 'a1 darbe', 'a2 yük', 'c yaklaşma', 'd yön değ.'};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
V = {};   % (yöntem, koşul, başlangıç, tesis, senaryo)
for k = 1:size(K,1), for m = 1:size(M,1), for b = [1 -1], for a = 1:2, for sc = scSec
    V(end+1,:) = {m, k, b, a, sc}; %#ok<AGROW>
end, end, end, end, end
parca = str2double(getenv('B1G_PARCA'));  npar = str2double(getenv('B1G_NPAR'));
if isnan(parca), sec = 1:size(V,1);  dosya = [onek '_sonuc.mat'];
else, sec = parca:npar:size(V,1);  dosya = sprintf('%s_sonuc_%d.mat', onek, parca); end
[I, Yn] = ndgrid(istek, [1 -1]);  I = I(:)';  Yn = Yn(:)';  n = numel(I);
R = struct([]);  t0 = tic;
for v = sec
   m = V{v,1};  kk = V{v,2};  bas = V{v,3};  a = V{v,4};  sc = V{v,5};
   Yf = Yn;  if sc == 5, Yf = -Yn; end
   hedef = I;  s0 = Yn;                            % mgl = 0: ilk hareket yönü = ilk temas yüzü
   if epsK                                         % B1'in 180° kuralı: bant içindeki hedef 0,5° kaydırılır
       kay = abs(I - 180) < 0.5;  hedef(kay) = 180 - 0.5*Yf(kay);
   end
   if K{kk,2}.mgl > 0                              % yerçekimi var: B1 kuralı sign(sin hedef), 180°'de Yn
       s0 = sign(round(sind(hedef)*1e9));  s0(s0 == 0) = Yn(s0 == 0);
   elseif isfield(K{kk,2}, 'yayE')                 % yay artığı: durağan dişli torku işareti sign(sin 2 hedef)
       s0 = sign(round(sind(2*hedef)*1e9));  s0(s0 == 0) = Yn(s0 == 0);
   end
   q = p0;  q.Fc = sur{a,2};  q.Fs = sur{a,3};  q.yuz0 = bas*s0;  q.adim = 1.1*Yn;
   switch sc
       case 2, q.dA = -0.05*s0;  q.df = 25;  q.dT0 = tD;  q.dT = tD + 0.02;   % yüzden koparan darbe
       case 3, q.dB = -0.02*s0;  q.dBT0 = tD;                                 % yüzü çevirmeye çalışan sabit yük
       case 4, W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
       case 5, W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
   end
   if sc >= 4, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
   kz = K{kk,2};                                   % senaryo 3: bozucu genliği -s0 yönünde (sinüs ilk yarı dalgası yüzden koparır)
   if isfield(kz, 'bA'), q.dA = -kz.bA*s0;  kz = rmfield(kz, 'bA'); end
   if isfield(kz, 'bB'), q.dB = -kz.bB*s0;  kz = rmfield(kz, 'bB'); end
   for ts = 1:3
     p = q;  p.nTohum = ts;
     if isfield(M{m,2}, 'yuzKes'), p = ek(p, ortak); end
     p = ek(p, as);  p = ek(p, kz);  p = ek(p, M{m,2});
     o = kol_benzetim(p, hedef, kpv*ones(1,n));
     sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;
     gy = sign(o.tau_s).*(abs(o.tau_s) > 0);  yuzS = sign(sum(gy(son,:), 1));
     e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
     iyi = abs(e) <= 0.5 & emax <= 1;  yuzK = sign(o.yuzSon(:)');
     k = numel(R) + 1;
     R(k).yontem = M{m,1};  R(k).kosul = K{kk,1};  R(k).bas = bas;  R(k).sur = sur{a,1};
     R(k).sen = sc_ad{sc};  R(k).tohum = ts;  R(k).hedef = hedef;  R(k).Yn = Yn;
     R(k).h7 = iyi & yuzS ~= 0 & yuzK == yuzS;  R(k).iyi = iyi;  R(k).e = e;  R(k).emax = emax;
     R(k).yuzS = yuzS;  R(k).yuzK = yuzK;
     if isfield(o, 'yuzDegis'), R(k).yuzDeg = o.yuzDegis; else, R(k).yuzDeg = zeros(1,n); end
     ts3 = o.t >= tD & o.t < tD + 2;  gy3 = sign(o.tau_s(ts3,:));   % bozucu penceresinde gerçek yüz değişimi var mı
     R(k).gercekCevir = any(gy3 == -s0, 1) & any(gy3 == s0, 1);
     if isfield(o, 'yokSay'), R(k).yokSay = o.yokSay; else, R(k).yokSay = zeros(1,n); end
   end
   fprintf('%s | %s | %s | bas %+d | %s bitti (%.0f s)\n', M{m,1}, K{kk,1}, sur{a,1}, bas, sc_ad{sc}, toc(t0));
end
save(dosya, 'R', 'M', 'K');
end

function q = ek(q, s)
f = fieldnames(s);  for j = 1:numel(f), q.(f{j}) = s.(f{j}); end
end
