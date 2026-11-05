function tablo_ilk(ad)
% TABLO_ILK  Açıya göre planlanan kazanç tablosunun ilk sürümü ve dijital ikizde sınanması.
%
% 1) Tablo: her hedef açı th0 için yerçekimli DF'nin kritik r_gs'si (salınımın başladığı en küçük
%    kazanç; yercekimli_df.m, temas sönümü + tork sınırı) bir güvenlik payıyla çarpılır:
%       r_plan(th0) = m * r_DF(th0).
%    0° ve 180° civarında yerçekimi ön yükü yok, DF her kazançta çevrim öngörür (kritik kazanç
%    tanımsız). Orada tablo bir taban değerine iner: ikizde ölçülen kritik r_gs (0°: 0,35,
%    180°: 0,30; yercekimli_kritik_D.csv) çarpı m. Taban, tablonun hiçbir açıda altına inmediği değer.
% 2) Karşılaştırma tabanı: sabit kazanç = tablonun en küçük değeri (bütün açılarda salınımsız
%    kalması gereken en iyi sabit ayar).
% 3) İkiz: her açıda (0:10:180) planlanan ve sabit kazançla, üç başlangıç sapmasıyla (0,2 / 1 / 5°)
%    benzetim. Ölçülen: salınım sınıfı (rejim_sinifla) ve 5° sapmadan yerleşme süresi.
% Kontrolcü Ghaffari'nin P-PI kaskadı (yercekimli_karsilastirma ile aynı ayar); planlanan büyüklük
% konum kazancı kp = r_gs^2 Ks / KV.
if nargin < 1, ad = 'D'; end
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
m = 0.8;                                   % güvenlik payı (DF benzetime göre zaten temkinli)
r_taban_ikiz = 0.30;                       % ikizde 0° / 180° kritik r_gs'lerinin küçüğü
p = secenek_duzenek(ad);
wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;

% --- 1) tablo -----------------------------------------------------------------------------
ac = 0:1:180;
rf = 0.2:0.005:1.4;  kpf = rf.^2*p.Ks/p.KV;
y = yercekimli_df(p, ac, kpf, 'Tmax', true);
r_df = nan(size(ac));
for j = 1:numel(ac)
    k = find(y.sinif(:,j) ~= '.', 1);      % salınımın başladığı ilk kazanç
    if ~isempty(k) && k > 1, r_df(j) = rf(k); end
end
r_taban = m*r_taban_ikiz;
r_plan = max(m*r_df, r_taban);  r_plan(isnan(r_plan)) = r_taban;
r_sabit = min(r_plan);
T = table(ac', round(r_df',3), round(r_plan',3), round((r_plan.^2*p.Ks/p.KV)',2), ...
    'VariableNames', {'aci_deg','r_gs_DF','r_gs_plan','kp_plan_1_s'});
writetable(T, sprintf('tablo_ilk_%s.csv', ad));

% --- 2-3) ikiz ----------------------------------------------------------------------------
at = 0:10:180;  rp = interp1(ac, r_plan, at);
bas = [0.2 1 5];  na = numel(at);
S = zeros(2, numel(bas), na);  Ty = nan(2, na);  Aa = S;
for c = 1:2
    if c == 1, rr = rp; else, rr = r_sabit*ones(1,na); end
    kp = rr.^2*p.Ks/p.KV;
    for b = 1:numel(bas)
        p.adim = bas(b);
        o = kol_benzetim(p, at, kp);
        sap = rad2deg(o.th) - at;
        r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
        S(c,b,:) = r.sinif;  Aa(c,b,:) = r.A;
        if bas(b) == 5, Ty(c,:) = yerlesme(o.t, sap, 0.25); end
    end
end
save(sprintf('tablo_ilk_%s.mat', ad), 'T', 'at', 'rp', 'r_sabit', 'S', 'Ty', 'Aa', 'bas', 'm', 'p');

% --- kayıt --------------------------------------------------------------------------------
fid = fopen('tablo_ilk_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== tablo_ilk %s, %s: m = %.2f, taban = %.3f, sabit r_gs = %.3f (kp %.2f 1/s)\n', ad, ...
    datestr(now,'yyyy-mm-dd HH:MM'), m, r_taban, r_sabit, r_sabit^2*p.Ks/p.KV);
yaz('  sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz (üç başlangıcın en kötüsü)\n');
yaz('  açı | r_DF  r_plan | plan: sınıf  T_yerl[s] | sabit: sınıf  T_yerl[s]\n');
for j = 1:na
    rd = r_df(ac == at(j));
    yaz('  %3d | %5.3f %5.3f | %d  %5.2f | %d  %5.2f\n', at(j), rd, rp(j), ...
        max(S(1,:,j)), Ty(1,j), max(S(2,:,j)), Ty(2,j));
end
sal = squeeze(max(S, [], 2)) >= 3;
yaz('  salınımlı açı sayısı: plan %d / %d, sabit %d / %d\n', sum(sal(1,:)), na, sum(sal(2,:)), na);
ic = at >= 20 & at <= 160;
yaz('  yerleşme süresi medyanı (20-160°): plan %.2f s, sabit %.2f s (oran %.2f)\n', ...
    median(Ty(1,ic),'omitnan'), median(Ty(2,ic),'omitnan'), median(Ty(1,ic)./Ty(2,ic),'omitnan'));
fclose(fid);
end

function ty = yerlesme(t, sap, bant)
% |sapma| < bant'a son kez girdiği an (sonuna kadar içinde kalıyorsa); hiç girmiyorsa NaN
ty = nan(1, size(sap,2));
for j = 1:size(sap,2)
    d = find(abs(sap(:,j)) >= bant, 1, 'last');
    if isempty(d), ty(j) = 0; elseif d < numel(t), ty(j) = t(d+1); end
end
end
