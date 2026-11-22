function b1_literatur_taban
% B1_LITERATUR_TABAN  B1-L: literatürdeki yalnız motor sinyalli kestiricilerle karşılaştırma, 179-181°.
% Senaryolar, ölçütler, tohumlar b1_kural_karsilastirma.m ile aynı (6 senaryo x 14 koşu x 3 tohum).
% Yöntemler (hepsi aynı algılayıcı: AS5600 nicem + gürültü + gecikme, INA228 torku, aynı ofset/rampa):
%   momentum    : L1, Ruderman-Iwasaki 2016 TIE sanal sensörünün tork kısmı (genelleştirilmiş momentum
%                 gözlemcisi) + işaret/histerezis. Izgara: momL x momEsik x momV (fark / gözlemci w^)
%   sta         : L2, Ruderman-Fridman 2019 TCST STA türevleyicisi + çarpma anı. Izgara: staL x staEsik
%   sta+uyarim  : L2, makalenin S1 uyarımı (180° bandında durgunken U sin 2πft, 1 s, en çok 3 kez)
%   edilgen     : L3, Neubauer 2015 Mech. Sci. kuralı, durgunken s = sign(motor torku)
%   olay        : ablasyon (bizim kestirici yoklamasız)
%   olay+yok    : bizim kestirici (B1 kanonik), olay+yok+ty: θ* aramasıyla, ust_sinir: gerçek yüz
% Paralel: B1L_PARCA = 1..B1L_NPAR ortam değişkeniyle yöntem listesi bölünür (her parça b1l_sonuc_<k>.mat);
% boşsa hepsi tek süreçte. Özet: b1l_ozet.m.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.akimW = 2*pi*500;
nAS = deg2rad(0.043)/p0.N;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
ortak = struct('tOlc', true, 'tPen', 0.54e-3, 'tGec', 0.1e-3, 'vKaynak', 'gozlemci');

% --- yöntem listesi: {ad, parametre etiketi, alanlar} ---
Y = {};
for L = [30 100 300], for E = [0.005 0.01 0.03], for v = {'fark', 'gozlemci'}
    Y(end+1,:) = {'momentum', sprintf('L%d e%g %s', L, E, v{1}), struct('yuzKes','momentum','momL',L,'momEsik',E,'momV',v{1})}; %#ok<AGROW>
end, end, end
for L = [10 30 100 300], for E = [3 10 30]
    Y(end+1,:) = {'sta', sprintf('L%d e%dq', L, E), struct('yuzKes','sta','staL',L,'staEsik',E*p0.qM)}; %#ok<AGROW>
end, end
for L = [10 30], for E = [3 10], for U = [0.03 0.06 0.12], for f = [2 5]
    Y(end+1,:) = {'sta+uyarim', sprintf('L%d e%dq U%g f%d', L, E, U, f), ...
        struct('yuzKes','sta','staL',L,'staEsik',E*p0.qM,'staUyar',[U f 1],'vDurF',10)}; %#ok<AGROW>
end, end, end, end
Y(end+1,:) = {'edilgen', '-', struct('yuzKes','edilgen','vDurF',10)};
Y(end+1,:) = {'olay', '-', struct('yuzKes','olay','vDurF',10)};
Y(end+1,:) = {'olay+yok', '-', struct('yuzKes','olay+yoklama','yokOrta',0.6,'vDurF',10)};
Y(end+1,:) = {'olay+yok+ty', '-', struct('yuzKes','olay+yoklama','yokOrta',0.6,'vDurF',10,'thYildiz',true,'tyArama',true)};
Y(end+1,:) = {'ust_sinir', '-', struct('ofsetYuz','anlik')};
for kr = {'panasonic', [0.01 0.05 0.2]; 'toyoda', [0.01 0.05 0.2]; 'lenze', [0.005 0.01 0.03]}'
    for v = kr{2}
        if strcmp(kr{1}, 'lenze'), ek = struct('yuzKural', kr{1}, 'kuralU', v);
        else, ek = struct('yuzKural', kr{1}, 'kuralV', v); end
        Y(end+1,:) = {kr{1}, sprintf('%g', v), ek}; %#ok<AGROW>
    end
end
% B1L_SOGUK = 1: soğuk başlangıç, kestiricinin/kuralın başlangıç inancı YANLIŞ (yuz0 = -s0; kol fiziksel
% olarak boşluğun ortasından başlar). Tüm yöntemler + patent kuralları. Normal koşuda (B1L_SOGUK boş)
% patent kuralları atlanır (B1'de zaten var).
soguk = ~isnan(str2double(getenv('B1L_SOGUK'))) && str2double(getenv('B1L_SOGUK')) ~= 0;
pat = ismember(Y(:,1), {'panasonic','toyoda','lenze'});
if soguk, onek = 'b1ls';  else, Y = Y(~pat, :);  onek = 'b1l'; end
% B1L_MOMEK = 1: "olay kipinin farkı yalnız büyük eşik mi?" sorusu için L1'e statik sürtünmeyi (Fs = 0,06)
% aşan eşikler. Yalnız bu girdiler koşulur (B1L_SOGUK ile birleştirilebilir), önek sonuna 'm' eklenir.
if ~isnan(str2double(getenv('B1L_MOMEK'))) && str2double(getenv('B1L_MOMEK')) ~= 0
    Y = {};
    for L = [30 100 300], for E = [0.045 0.06 0.08 0.1 0.15], for v = {'fark', 'gozlemci'}
        Y(end+1,:) = {'momentum', sprintf('L%d e%g %s', L, E, v{1}), struct('yuzKes','momentum','momL',L,'momEsik',E,'momV',v{1})}; %#ok<AGROW>
    end, end, end
    onek = [onek 'm'];
end

parca = str2double(getenv('B1L_PARCA'));  npar = str2double(getenv('B1L_NPAR'));
if isnan(parca), sec = 1:size(Y,1);  dosya = [onek '_sonuc.mat'];
else, sec = parca:npar:size(Y,1);  dosya = sprintf('%s_sonuc_%d.mat', onek, parca); end

istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Yn] = ndgrid(istek, [1 -1]);  I = I(:)';  Yn = Yn(:)';  n = numel(I);
sen = {'temel', 'a1 darbe', 'a2 yük', 'b salınım', 'c yaklaşma', 'd yön değ.'};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
tohum = 1:3;
R = struct([]);  t0 = tic;
for m = sec
 for a = 1:size(sur,1)
  for sc = 1:numel(sen)
   Yf = Yn;  if sc == 6, Yf = -Yn; end
   hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Yf(kay);
   s0 = sign(sind(hedef));  sDog = s0;
   q = p0;  q.Fc = sur{a,2};  q.Fs = sur{a,3};  q.yuz0 = s0*(1 - 2*soguk);  q.adim = 1.1*Yn;
   switch sc
       case 2, q.dA = 0.05*sign(180 - hedef);  q.df = 25;  q.dT0 = tD;  q.dT = tD + 0.02;
       case 3, q.dB = 0.02*s0;  q.dBT0 = tD;  sDog = -s0;
       case 4, q.dA = 0.01*ones(1,n);  q.df = 1;  q.dT0 = tD;  q.dT = Inf;  sDog = nan(1,n);
       case 5, W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
       case 6, W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
   end
   if sc >= 5, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
   for ts = tohum
     p = q;  p.nM = nAS;  p.nTohum = ts;
     ek = Y{m,3};
     if isfield(ek, 'yuzKes'), f = fieldnames(ortak); for j = 1:numel(f), p.(f{j}) = ortak.(f{j}); end, end
     f = fieldnames(ek);  for j = 1:numel(f), p.(f{j}) = ek.(f{j}); end
     o = kol_benzetim(p, hedef, kpv*ones(1,n));
     sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
     gy = sign(o.delta).*(abs(o.delta) >= p0.r);
     yuzS = sign(sum(gy(son,:), 1));
     k = numel(R) + 1;
     R(k).sur = sur{a,1};  R(k).sen = sen{sc};  R(k).yontem = Y{m,1};  R(k).par = Y{m,2};  R(k).tohum = ts;
     R(k).e = mean(sap(son,:), 1);  R(k).emax = max(abs(sap(son,:)), [], 1);
     R(k).h7 = abs(R(k).e) <= 0.5 & R(k).emax <= 1 & yuzS == sDog;
     R(k).App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
     tB = 0.5;  if sc == 4, tB = tD; end
     tm = gy ~= 0 & o.t >= tB;
     if isfield(o, 'shat')
         R(k).b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
         R(k).avl = sum(abs(diff(o.shat(s3,:))) > 0, 1);
     else
         R(k).b12 = nan(1,n);  R(k).avl = o.yuzDegisAn;
     end
     if isfield(o, 'yokKol'), R(k).b13 = rad2deg(o.yokKol); else, R(k).b13 = nan(1,n); end
     if isfield(o, 'staSay'), R(k).uyar = o.staSay; else, R(k).uyar = zeros(1,n); end
   end
  end
 end
 fprintf('%s %s bitti (%.0f s)\n', Y{m,1}, Y{m,2}, toc(t0));
end
save(dosya, 'R', 'sen', 'Y', 'sur', 'tohum', 'istek', 'I', 'Yn');
end
