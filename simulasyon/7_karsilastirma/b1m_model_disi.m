function b1m_model_disi
% B1-M: modelde olmayan (kestiricinin bilmediği) tesis/sensör etkileri altında B1 senaryoları.
% Etkiler (kol_benzetim başlığı, "Model dışı etkiler"): cogging, Stribeck biçimi, konuma bağlı sürtünme,
% açıya bağlı boşluk r(th) (çıkış dişlisi rK = 1, pinyon varsayımı rK = 6), AS5600 harmonik açı hatası,
% hepsi orta seviyede birlikte. Kestiricinin bildiği değerler (FcN 0,04, FsN 0,06, rN = r) değişmez.
% Fazlar tohuma bağlı (her tohum farklı faz). Kurulum, senaryolar, H7 ölçütü b1d_dayaniklilik ile aynı;
% yalnız son yüz dişli torkunun işaretinden (r değişkenken delta >= r ölçütü yanıltır). Denetim için
% eski (delta) ölçütü de h7d olarak kaydedilir. Paralel: B1M_PARCA / B1M_NPAR. Özet: b1m_ozet.
% B1M_EK=1: ek koşul listesi (önek b1mE; özet için B1M_ONEK=b1mE). Başarısızlık türü: b1m_tur.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;  p0.gM = 4e-4;  p0.akimW = 2*pi*500;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
ortak = struct('tOlc', true, 'tPen', 0.54e-3, 'tGec', 0.1e-3, 'vKaynak', 'gozlemci');
M = {'olay', struct('yuzKes','olay','vDurF',10);
     'olay+yok', struct('yuzKes','olay+yoklama','yokOrta',0.6,'vDurF',10);
     'momentum L100 e0.06', struct('yuzKes','momentum','momL',100,'momEsik',0.06,'momV','gozlemci');
     'lenze 0.03', struct('yuzKural','lenze','kuralU',0.03);
     'edilgen', struct('yuzKes','edilgen','vDurF',10)};
qAS = 2*pi/(4096*30);  nAS = deg2rad(0.043)/p0.N;
as = struct('qM', qAS, 'nM', nAS);    % kestirici sürtünmeyi tesisin gerçeği bilir (b1d AS5600 satırı gibi)
K = {};   % {etiket, sürtünme listesi (1 sürtünmeli, 2 sürtünmesiz), alanlar}
K(end+1,:) = {'denetim (etkisiz)', [1 2], as};
for c = [0.1 0.25 0.5]
    K(end+1,:) = {sprintf('cogging %gFc', c), [1 2], ek(as, struct('cogA', 0.04*c))}; %#ok<AGROW>
end
K(end+1,:) = {'Stribeck vs 0.01', 1, ek(as, struct('vs', 0.01, 'FcN', 0.04, 'FsN', 0.06))};
K(end+1,:) = {'Stribeck vs 0.2', 1, ek(as, struct('vs', 0.2, 'FcN', 0.04, 'FsN', 0.06))};
K(end+1,:) = {'Stribeck Fs/Fc 1', 1, ek(as, struct('Fs', 0.04, 'FcN', 0.04, 'FsN', 0.06))};
K(end+1,:) = {'Stribeck Fs/Fc 2', 1, ek(as, struct('Fs', 0.08, 'FcN', 0.04, 'FsN', 0.06))};
for a = [0.2 0.4 0.6]
    K(end+1,:) = {sprintf('konum sürt a%g', a), 1, ek(as, struct('sfA', a))}; %#ok<AGROW>
end
for rk = [1 6]
    for b = [0.2 0.4]
        K(end+1,:) = {sprintf('r(th) rK%d b%g', rk, b), [1 2], ek(as, struct('rA', b, 'rK', rk))}; %#ok<AGROW>
    end
end
for E = [0.25 0.5 1]
    K(end+1,:) = {sprintf('AS5600 harm %g°', E), [1 2], ek(as, struct('asHar', deg2rad([E 0 E/2 0])))}; %#ok<AGROW>
end
K(end+1,:) = {'birleşik orta', [1 2], ek(as, struct('cogA', 0.01, 'sfA', 0.4, 'rA', 0.2, 'rK', 1, ...
              'asHar', deg2rad([0.5 0 0.25 0])))};
onek = 'b1m';  mSec = 1:size(M,1);
if strcmp(getenv('B1M_EK'), '1')   % B1-M ek koşuları (tur 66): (a) r(th) haritası ofsette, (b) birleşik ortadan
    onek = 'b1mE';  K = {};        % birer birer çıkarma, (c) AS5600 2°, (d) cogging ince taraması
    for rk = [1 6]
        for b = [0.2 0.4]
            K(end+1,:) = {sprintf('r(th) rK%d b%g harita', rk, b), [1 2], ek(as, struct('rA', b, 'rK', rk, 'rHarita', true))}; %#ok<AGROW>
        end
    end
    bo = struct('cogA', 0.01, 'sfA', 0.4, 'rA', 0.2, 'rK', 1, 'asHar', deg2rad([0.5 0 0.25 0]));
    cik = {'cogging', {'cogA'}; 'konum sürt', {'sfA'}; 'r(th)', {'rA', 'rK'}; 'AS5600', {'asHar'}};
    for j = 1:size(cik,1)
        K(end+1,:) = {['birleşik - ' cik{j,1}], [1 2], ek(as, rmfield(bo, cik{j,2}))}; %#ok<AGROW>
    end
    K(end+1,:) = {'AS5600 harm 2°', [1 2], ek(as, struct('asHar', deg2rad([2 0 1 0])))};
    for c = [0.125 0.15 0.175 0.2]
        K(end+1,:) = {sprintf('cogging %gFc', c), [1 2], ek(as, struct('cogA', 0.04*c))}; %#ok<AGROW>
    end
end
V = {};   % (yöntem, koşul, başlangıç)
for k = 1:size(K,1), for m = mSec, for b = [1 -1], V(end+1,:) = {m, k, b}; end, end, end %#ok<AGROW>
parca = str2double(getenv('B1M_PARCA'));  npar = str2double(getenv('B1M_NPAR'));
if isnan(parca), sec = 1:size(V,1);  dosya = [onek '_sonuc.mat'];
else, sec = parca:npar:size(V,1);  dosya = sprintf('%s_sonuc_%d.mat', onek, parca); end
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Yn] = ndgrid(istek, [1 -1]);  I = I(:)';  Yn = Yn(:)';  n = numel(I);
sen = {'temel', 'a1 darbe', 'a2 yük', 'b salınım', 'c yaklaşma', 'd yön değ.'};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
R = struct([]);  t0 = tic;
for v = sec
 m = V{v,1};  kk = V{v,2};  bas = V{v,3};
 for a = K{kk,2}
  for sc = 1:numel(sen)
   if sc == 4, continue; end                       % b salınımda H7 yok
   Yf = Yn;  if sc == 6, Yf = -Yn; end
   hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Yf(kay);
   s0 = sign(sind(hedef));  sDog = s0;
   q = p0;  q.Fc = sur{a,2};  q.Fs = sur{a,3};  q.yuz0 = bas*s0;  q.adim = 1.1*Yn;
   switch sc
       case 2, q.dA = 0.05*sign(180 - hedef);  q.df = 25;  q.dT0 = tD;  q.dT = tD + 0.02;
       case 3, q.dB = 0.02*s0;  q.dBT0 = tD;  sDog = -s0;
       case 5, W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
       case 6, W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
   end
   if sc >= 5, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
   for ts = 1:3
     p = q;  p.nTohum = ts;
     if isfield(M{m,2}, 'yuzKes'), p = ek(p, ortak); end
     p = ek(p, K{kk,3});  p = ek(p, M{m,2});
     fz = @(o) 2*pi*mod(0.618*ts + o, 1);           % tohuma bağlı faz
     p.cogF = fz(0.10);  p.sfF = fz(0.35);  p.rF = fz(0.60);
     if isfield(p, 'asHar'), p.asHar([2 4]) = [fz(0.85) fz(0.20)]; end
     if isfield(p, 'rHarita')                       % ofset r(th)'yi hedef açıda okur (kararlı durumda th ~ hedef)
         p.rN = p.r*(1 + p.rA*sin(p.rK*deg2rad(hedef) + p.rF));  p = rmfield(p, 'rHarita');
     end
     o = kol_benzetim(p, hedef, kpv*ones(1,n));
     sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;
     gy = sign(o.tau_s).*(abs(o.tau_s) > 0);  yuzS = sign(sum(gy(son,:), 1));
     gd = sign(o.delta).*(abs(o.delta) >= p0.r);  yuzD = sign(sum(gd(son,:), 1));
     e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
     k = numel(R) + 1;  iyi = abs(e) <= 0.5 & emax <= 1;
     R(k).yontem = M{m,1};  R(k).kosul = K{kk,1};  R(k).bas = bas;  R(k).sur = sur{a,1};  R(k).sen = sen{sc};
     R(k).tohum = ts;  R(k).h7 = iyi & yuzS == sDog;  R(k).h7d = iyi & yuzD == sDog;
     R(k).iyi = iyi;  R(k).e = e;  R(k).emax = emax;
   end
  end
 end
 fprintf('%s | %s | bas %+d bitti (%.0f s)\n', M{m,1}, K{kk,1}, bas, toc(t0));
end
save(dosya, 'R', 'M', 'K');
end

function q = ek(q, s)
f = fieldnames(s);  for j = 1:numel(f), q.(f{j}) = s.(f{j}); end
end
