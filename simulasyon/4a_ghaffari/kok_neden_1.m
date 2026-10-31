function kok_neden_1
% KOK_NEDEN_1  DF'nin kritik kazancı neden sistematik düşük? Parça 1: tanım farkı.
% Yerçekimli DF (temas sönümü + tork sınırı) "çevrim var" derken iki kararlılık bölgesini de
% sayar (denge küçük sarsıntıya kararlı, eşik genliği a1 > 0). Benzetim yalnız üç başlangıç
% sapmasıyla (0,2 / 1 / 5°) salınım başlarsa "var" der. Uyuşmayan hücrelerde (DF çevrim,
% benzetim salınımsız) DF eşiği a1 sıfır mı (kendiliğinden başlamalı) yoksa büyük mü?
% Veri: yercekimli_D.mat (yercekimli_karsilastirma 'benzetim'). Yeni benzetim yok.
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  p = B.p;
rgs = B.rgs;  ac = B.ac;  nr = numel(rgs);  na = numel(ac);
kp = rgs.^2*p.Ks/p.KV;
y = yercekimli_df(p, ac, kp, 'Tmax', true);
sal  = reshape(any(B.C >= 3, 1), nr, na);          % herhangi bir başlangıçta salınım
hep  = reshape(all(B.C >= 3, 1), nr, na);          % her başlangıçta salınım
ic   = abs(sin(deg2rad(ac))) > 1e-9;  IC = repmat(ic, nr, 1);
dfC  = y.sinif == 'C';
uy   = dfC & ~sal & IC;                            % DF çevrim, benzetim salınımsız
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 1: tanım farkı (D, %s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('  hücre (0° ve 180° hariç): DF çevrim %d; bunların benzetimde salınımlı %d, salınımsız %d\n', ...
    sum(dfC(:) & IC(:)), sum(dfC(:) & sal(:) & IC(:)), sum(uy(:)));
yaz('  benzetimde salınım başlangıca bağlı (bazı başlangıçlarda var): %d hücre; bunların DF''de çevrim %d\n', ...
    sum(sal(:) & ~hep(:) & IC(:)), sum(sal(:) & ~hep(:) & dfC(:) & IC(:)));
a1 = y.a1(uy);  a2 = y.a2(uy);
yaz('  uyuşmayan hücrelerde DF eşiği a1 = A_eşik/r: sıfır (kendiliğinden başlamalı) %d, > 0 %d\n', sum(a1 == 0), sum(a1 > 0));
if any(a1 > 0)
    yaz('    a1 > 0 olanlarda a1 medyan %.2f (aralık %.2f-%.2f), kararlı çevrim a2 medyan %.2f\n', ...
        median(a1(a1>0)), min(a1(a1>0)), max(a1(a1>0)), median(a2(a1>0)));
end
% açıya göre: uyuşmayan hücre sayısı ve a1 medyanı (15° adımlı özet)
yaz('  açı        : %s\n', sprintf('%6d', ac(1:3:end)));
yaz('  uyuşmayan  : %s\n', sprintf('%6d', sum(uy(:, 1:3:end), 1)));
m1 = nan(1, na);
for j = 1:na, v = y.a1(uy(:,j), j); if ~isempty(v), m1(j) = median(v); end, end
yaz('  a1 medyan  : %s\n', sprintf('%6.2f', m1(1:3:end)));
fclose(fid);
save('kok_neden_1.mat', 'y', 'uy', 'sal', 'hep');
end
