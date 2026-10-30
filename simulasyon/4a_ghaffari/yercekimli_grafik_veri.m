function yercekimli_grafik_veri(ad)
% YERCEKIMLI_GRAFIK_VERI  Site grafiği için kritik r_gs - açı verisi (yercekimli_karsilastirma ile
% aynı tanım): benzetim (yercekimli_<ad>.mat), yerçekimli DF (tam), tork sınırsız DF.
% Çıktı: yercekimli_kritik_<ad>.csv (aci, benzetim, df, df_tmaxsiz; NaN = tanımsız)
if nargin < 1, ad = 'D'; end
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load(sprintf('yercekimli_%s.mat', ad));
p = B.p;  rgs = B.rgs;  ac = B.ac;  nr = numel(rgs);  na = numel(ac);
sal = reshape(any(B.C >= 3, 1), nr, na);
rf = 0.2:0.01:1.4;  kpf = rf.^2*p.Ks/p.KV;
y  = yercekimli_df(p, ac, kpf, 'Tmax', true);
yt = yercekimli_df(p, ac, kpf);
T = [ac(:), ilk(rgs, sal)', ilk(rf, y.sinif ~= '.')', ilk(rf, yt.sinif ~= '.')'];
T(abs(sind(ac)) < 1e-9, 3:4) = NaN;                % gamma = 0: DF her kazançta çevrim
writematrix(T, sprintf('yercekimli_kritik_%s.csv', ad));
end

function k = ilk(r, M)
% her sütunda salınımın başladığı ve sonra hep süren ilk kazanç
k = nan(1, size(M,2));
for j = 1:size(M,2)
    i = find(~M(:,j), 1, 'last');
    if isempty(i), k(j) = r(1); elseif i < numel(r), k(j) = r(i+1); end
end
end
