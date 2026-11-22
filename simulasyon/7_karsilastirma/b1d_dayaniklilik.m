function b1d_dayaniklilik
% B1-D: B1 senaryolarında dayanıklılık. Yoklamanın katkısı ve gerçek donanımda belirsiz olan bilgiler.
% (i)  enkoder: AS5600 (motor milinde, gürültülü, kanonik) / 0,017° / 0,068° kol tarafı (gürültüsüz nicem)
% (ii) kestiricinin bildiği sürtünme FcN, FsN = c x gerçek (c 0,5 / 1,5 / 2), atalet JMN = 0,8 / 1,2 x JM
%      (yalnız sürtünmeli tesis; c = 1 durumu (i)'deki AS5600 satırı)
% Her koşul: başlangıç inancı doğru (yuz0 = s0) ve ters (-s0). Yöntemler: olay, olay+yok, L1 en iyi
% (momentum L100 e0,06 w^), lenze 0,03 (B1 sürtünmeli en iyi patent), edilgen (sign u).
% Senaryolar/ölçütler b1_kural_karsilastirma ile aynı. Paralel: B1D_PARCA / B1D_NPAR.
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
K = {};   % {etiket, sürtünme listesi, alanlar}
K(end+1,:) = {'enk AS5600', [1 2], struct('qM', qAS, 'nM', nAS)};
K(end+1,:) = {'enk 0.017°', [1 2], struct('qM', deg2rad(0.017), 'nM', 0)};
K(end+1,:) = {'enk 0.068°', [1 2], struct('qM', deg2rad(0.068), 'nM', 0)};
for c = [0.5 1.5 2]
    K(end+1,:) = {sprintf('sürt bilgisi x%g', c), 1, struct('qM', qAS, 'nM', nAS, 'FcN', 0.04*c, 'FsN', 0.06*c)}; %#ok<AGROW>
end
for c = [0.8 1.2]
    K(end+1,:) = {sprintf('JMN x%g', c), 1, struct('qM', qAS, 'nM', nAS, 'JMN', p0.JM*c)}; %#ok<AGROW>
end
onek = 'b1d';  mSec = 1:size(M,1);
% B1D_SURT = 1: sürtünme bilgisi tolerans penceresi (ince tarama). Yalnız sürtünme bilgisini kullanan yöntemler
% (olay, olay+yok, momentum). c x gerçek (sürtünmeli tesis) + sürtünmesiz tesiste 0,04/0,06 varsayımı.
if ~isnan(str2double(getenv('B1D_SURT'))) && str2double(getenv('B1D_SURT')) ~= 0
    K = {};
    for c = [0 0.25 0.75 1.1 1.25]
        K(end+1,:) = {sprintf('sürt bilgisi x%g', c), 1, struct('qM', qAS, 'nM', nAS, 'FcN', 0.04*c, 'FsN', 0.06*c)}; %#ok<AGROW>
    end
    K(end+1,:) = {'sürtünmesiz tesis, bilgi 0.04/0.06', 2, struct('qM', qAS, 'nM', nAS, 'FcN', 0.04, 'FsN', 0.06)};
    onek = 'b1dS';  mSec = 1:3;
end
V = {};   % (yöntem, koşul, başlangıç)
for k = 1:size(K,1), for m = mSec, for b = [1 -1], V(end+1,:) = {m, k, b}; end, end, end %#ok<AGROW>
parca = str2double(getenv('B1D_PARCA'));  npar = str2double(getenv('B1D_NPAR'));
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
     if isfield(M{m,2}, 'yuzKes'), f = fieldnames(ortak); for j = 1:numel(f), p.(f{j}) = ortak.(f{j}); end, end
     f = fieldnames(K{kk,3});  for j = 1:numel(f), p.(f{j}) = K{kk,3}.(f{j}); end
     f = fieldnames(M{m,2});   for j = 1:numel(f), p.(f{j}) = M{m,2}.(f{j}); end
     o = kol_benzetim(p, hedef, kpv*ones(1,n));
     sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;
     gy = sign(o.delta).*(abs(o.delta) >= p0.r);  yuzS = sign(sum(gy(son,:), 1));
     e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
     k = numel(R) + 1;
     R(k).yontem = M{m,1};  R(k).kosul = K{kk,1};  R(k).bas = bas;  R(k).sur = sur{a,1};  R(k).sen = sen{sc};
     R(k).tohum = ts;  R(k).h7 = abs(e) <= 0.5 & emax <= 1 & yuzS == sDog;  R(k).e = e;
   end
  end
 end
 fprintf('%s | %s | bas %+d bitti (%.0f s)\n', M{m,1}, K{kk,1}, bas, toc(t0));
end
save(dosya, 'R', 'M', 'K');
end
