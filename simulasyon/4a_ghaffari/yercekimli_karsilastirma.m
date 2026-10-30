function yercekimli_karsilastirma(mod, S)
% YERCEKIMLI_KARSILASTIRMA  4b-2: aynı açı x r_gs düzleminde
%   (a) Ghaffari'nin yerçekimsiz DF'si (açıdan bağımsız), (b) yerçekimli DF (yercekimli_df.m),
%   (c) benzetim (kol_benzetim, secenekler.m ile aynı ayar: P-PI, ideal sensör, gerçek tork sınırı).
% mod = 'benzetim': ince ızgarada benzetim koşar, yercekimli_<ad>.mat'a yazar (uzun).
% mod = 'analiz'  : DF'leri hesaplar, benzetimle karşılaştırır, yercekimli_log.txt'ye yazar.
% Ölçütler (framing B1, B2): her açıda salınımın başladığı kritik r_gs; her r_gs'de bastırma
% bölgesinin açı sınırları.
addpath(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 2, S = {'D','A'}; end
rgs = 0.3:0.05:1.3;
ac  = 0:5:180;
bas = [0.2 1 5];
for i = 1:numel(S)
    p = ayar(S{i});
    kp = rgs.^2*p.Ks/p.KV;
    dosya = sprintf('yercekimli_%s.mat', S{i});
    switch mod
        case 'benzetim'
            [AC, KP] = meshgrid(ac, kp);
            C = zeros(numel(bas), numel(AC));  F = C;  A = C;
            for b = 1:numel(bas)
                p.adim = bas(b);
                o = kol_benzetim(p, AC(:)', KP(:)');
                r = rejim_sinifla(o.t, rad2deg(o.th) - AC(:)', struct('A_min',0.05,'A_max',30,'T_at',0.3));
                C(b,:) = r.sinif;  F(b,:) = r.f;  A(b,:) = r.A;
                fprintf('%s: başlangıç %g° bitti\n', S{i}, bas(b));
            end
            save(dosya, 'C', 'F', 'A', 'AC', 'KP', 'rgs', 'ac', 'bas', 'p');
        case 'analiz'
            analiz(S{i}, p, load(dosya));
    end
end
end

function p = ayar(ad)
p = secenek_duzenek(ad);
wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
end

function analiz(ad, p, B)
fid = fopen('yercekimli_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
rgs = B.rgs;  ac = B.ac;  na = numel(ac);  nr = numel(rgs);
% benzetim: salınım var = çevrim, kararsız ya da düzensiz (sınıf 3, 4, 5) herhangi bir başlangıçta
sal = reshape(any(B.C >= 3, 1), nr, na);
ayni = reshape(all(B.C == B.C(1,:), 1), nr, na);
% DF'ler ince kazanç ızgarasında (benzetim ızgarası da içinde)
rf = unique([0.2:0.005:1.4 rgs]);  kpf = rf.^2*p.Ks/p.KV;
y  = yercekimli_df(p, ac, kpf);                     % (b) kg ile
y0 = yercekimli_df(p, ac, kpf, 'kg', false);        % (b') kg'siz
q = p;  q.mgl = 0;
g  = yercekimli_df(q, ac, kpf, 'kg', false);        % (a) Ghaffari: beta = 0, kg = 0
dfsal = @(d) d.sinif ~= '.';
kr = @(M, r) arrayfun(@(j) ilk(r, M(:,j)), 1:size(M,2));
k_sim = kr(sal, rgs);  k_y = kr(dfsal(y), rf);  k_y0 = kr(dfsal(y0), rf);  k_g = kr(dfsal(g), rf);
yaz('\n=== %s: R = %.2f, mgl = %.3f N m, beta(90°) = mgl/(Ks r) = %.2f, %s\n', ad, p.JL/p.JM, p.mgl, p.mgl/(p.Ks*p.r), datestr(now,'yyyy-mm-dd HH:MM'));
yaz('  harita (satır r_gs, sütun açı 0:15:180). benzetim | yerçekimli DF | Ghaffari.  C/X/? benzetimde salınım, * başlangıca bağlı\n');
js = 1:3:na;  [~, ir] = ismember(round(rgs*1000), round(rf*1000));
for k = 1:nr
    s1 = '';
    for j = js
        c = max(B.C(:, sub2ind([nr na], k, j)));  t = ' ';  if ~ayni(k,j), t = '*'; end
        s1 = [s1 ' ' sm(c) t]; %#ok<AGROW>
    end
    yaz('  %.2f: %s | %s | %s\n', rgs(k), s1, sprintf('%3s', y.sinif(ir(k), js)), sprintf('%3s', g.sinif(ir(k), js)));
end
yaz('  kritik r_gs (salınımın başladığı en küçük kazanç; ızgara dışı: - )\n');
yaz('   açı      : %s\n', sprintf('%6d', ac(js)));
yaz('   benzetim : %s\n', sprintf('%6.2f', k_sim(js)));
yaz('   yerç. DF : %s\n', sprintf('%6.2f', k_y(js)));
yaz('   kg''siz  : %s\n', sprintf('%6.2f', k_y0(js)));
yaz('   Ghaffari : %s\n', sprintf('%6.2f', k_g(js)));
ok = ~isnan(k_sim);
e_y = abs(k_y(ok) - k_sim(ok))./k_sim(ok);  e_g = abs(k_g(ok) - k_sim(ok))./k_sim(ok);
e_y(isnan(e_y)) = 1;  e_g(isnan(e_g)) = 1;          % öngörü yoksa %100 hata
yaz('  B1: kritik kazanç hatası, medyan (en çok): yerçekimli DF %%%.0f (%%%.0f), Ghaffari %%%.0f (%%%.0f)  [%d açı]\n', ...
    100*median(e_y), 100*max(e_y), 100*median(e_g), 100*max(e_g), sum(ok));
% B2: her r_gs'de bastırma bölgesinin açı sınırları (benzetim ve yerçekimli DF)
yaz('  B2: bastırma bölgesi (salınımsız açılar) [alt, üst] derece\n');
e2 = [];
for k = 1:nr
    [l1, u1] = bolge(ac, ~sal(k,:));  [l2, u2] = bolge(ac, y.sinif(ir(k),:) == '.');
    if isnan(l1) && isnan(l2), continue; end
    yaz('   r_gs %.2f: benzetim [%s, %s], DF [%s, %s]\n', rgs(k), sy(l1), sy(u1), sy(l2), sy(u2));
    if ~isnan(l1) && ~isnan(l2), e2 = [e2 abs(l1-l2) abs(u1-u2)]; end %#ok<AGROW>
end
yaz('  B2: açı sınırı hatası medyan %.1f°, en çok %.1f°\n', median(e2), max(e2));
% B3: çevrim frekansı (benzetim çevrimi ve DF çevrimi olan noktalar)
Fs = reshape(median(B.F, 1, 'omitnan'), nr, na);  Fd = y.f(ir, :);
m = reshape(any(B.C == 3, 1), nr, na) & y.sinif(ir,:) == 'C' & Fs > 0;
yaz('  B3: çevrim frekansı sim/DF medyan %.2f (aralık %.2f-%.2f), %d nokta\n', median(Fs(m)./Fd(m)), min(Fs(m)./Fd(m)), max(Fs(m)./Fd(m)), sum(m(:)));
fclose(fid);
end

function k = ilk(r, v)
% v'nin true olduğu ve sonrasında hep true kalan ilk kazanç
j = find(~v(:)', 1, 'last');
if isempty(j), k = r(1); elseif j == numel(v), k = nan; else, k = r(j+1); end
end

function [l, u] = bolge(ac, v)
% v (salınımsız) olan açıların en büyük bitişik parçasının sınırları
l = nan;  u = nan;  if ~any(v), return; end
d = diff([0 v(:)' 0]);  b = find(d == 1);  e = find(d == -1) - 1;
[~, i] = max(e - b);  l = ac(b(i));  u = ac(e(i));
end

function s = sy(x)
if isnan(x), s = '-'; else, s = sprintf('%g', x); end
end

function c = sm(k)
t = '.sZCX?';  c = t(k+1);
end
