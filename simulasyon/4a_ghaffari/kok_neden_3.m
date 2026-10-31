function kok_neden_3(parca)
% parca: 'a', 'b' ya da 'ab' (varsayılan)
% KOK_NEDEN_3  Parça 3: hata döngünün hangi kısmında?
% 3a  Doğrusal kısım + yerçekimi doğrusallaştırması. Benzetimde dişli boşluğu kaldırılır (r = 0),
%     yerine DF'nin kararlı çevrimdeki eşdeğeri konur: k_e = s Ks n_req, c_e = cs h(a2).
%     Tork sınırı yok, denge noktasından çok küçük sapmayla başlanır. DF'ye göre s = 1'de döngü
%     tam sınırda (zarf sabit). Benzetimde zarfın büyüme hızı ölçülür ve sınırın geçtiği s bulunur.
% 3b  Tork sınırı ve anti-windup. Parça 1b'nin 92 uyuşmayan hücresi tork sınırsız benzetimle ve
%     tork sınırsız DF'yle yeniden.
if nargin < 1, parca = 'ab'; end
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;  [AC, KP] = meshgrid(B.ac, kp);
dz = yercekimli_df('dz');
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
if any(parca == 'a')
yaz('\n=== Parça 3a: doğrusal kısım, dişli yerine DF eşdeğeri (D, %s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('  hücre      n_req   h     f_DF   | s=1: sönüm oranı  f_sim | sınırın geçtiği s (sim)\n');
hucre = @(a, r) find(AC == a & abs(KP - r^2*p.Ks/p.KV) < 1e-9);
sec = arrayfun(@(a, r) hucre(a, r), [15 30 60 120 150], [0.65 0.80 0.95 0.95 0.80]);
olc_s = [0.7 0.8 0.9 0.95 1 1.05 1.1 1.2 1.3];
for m = sec
    be = p.mgl*sin(deg2rad(AC(m)))/(p.Ks*p.r);
    a2 = K.y.a2(m);  b2 = fzero(@(bb) dz(a2, bb) - be, [0, 1 + be + a2]);
    [~, ~, h] = dz(a2, b2);
    z = zeros(size(olc_s));  fs = z;
    for i = 1:numel(olc_s)
        [z(i), fs(i)] = dogrusal(p, AC(m), KP(m), olc_s(i)*p.Ks*K.y.n_req(m), p.cs*h);
    end
    j = find(z(1:end-1) <= 0 & z(2:end) > 0, 1);       % kararsızdan kararlıya geçiş (s artarken)
    if isempty(j), sk = nan; else, sk = olc_s(j) + z(j)/(z(j)-z(j+1))*(olc_s(j+1)-olc_s(j)); end
    yaz('  %3d°/%.2f  %5.3f  %5.3f  %5.2f  | %+7.4f          %5.2f | %s   sönüm(s): %s\n', AC(m), B.rgs(KP(m)==kp), ...
        K.y.n_req(m), h, K.y.f(m), z(olc_s == 1), fs(olc_s == 1), sy(sk), sprintf('%+.3f ', z));
end
yaz('  (sönüm oranı > 0: zarf sönüyor; DF doğruysa s = 1''de ≈ 0 ve sınır s ≈ 1; s: %s)\n', sprintf('%g ', olc_s));
end

% ---- 3b ----
if any(parca == 'b')
yaz('\n=== Parça 3b: tork sınırı yok, 92 uyuşmayan hücre (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
idx = find(K.uy);
yt = yercekimli_df(p, B.ac, kp);                       % tork sınırsız DF (temas sönümlü)
yaz('  tork sınırsız DF: çevrim %d, kararsız (tam temasta) %d, salınımsız %d\n', ...
    sum(yt.sinif(idx) == 'C'), sum(yt.sinif(idx) == 'X'), sum(yt.sinif(idx) == '.'));
q = p;  q.Tmax = Inf;  q.adim = 0.2;  q.T = 8;  q.df = median(K.y.f(K.uy));  q.dT = 1;
opt = struct('A_min', 0.05, 'A_max', 30, 'T_at', 2);
for dA = [0 0.20]
    q.dA = dA;
    o = kol_benzetim(q, AC(idx)', KP(idx)');
    r = rejim_sinifla(o.t, rad2deg(o.th) - AC(idx)', opt);  c = r.sinif;
    yaz('  benzetim, tork sınırsız, sarsıntı %.2f N m: denge/sönümlü %d, kalıcı çevrim %d, kararsız %d, düzensiz %d\n', ...
        dA, sum(c <= 1), sum(c == 3), sum(c == 4), sum(c == 5));
end
end
fclose(fid);
end

function [zeta, f] = dogrusal(p, ac, kp, ke, ce)
% dişli = doğrusal yay ke + sönümleyici ce (r = 0), denge noktasından 0,01° sapmayla
q = p;  q.r = 0;  q.Ks = ke;  q.cs = ce;  q.Tmax = Inf;  q.T = 6;  q.Tan = q.T;
th0 = deg2rad(ac);  T0 = p.mgl*sin(th0);  e0 = deg2rad(0.01);
q.x0 = [th0 - e0 + T0/ke; 0; th0 - e0; 0];             % dişli ön yükte (gerilmiş yay)
q.z0 = (T0 - p.KV*kp*e0)/p.KI;                         % integratör yükü taşıyor
o = kol_benzetim(q, ac, kp);
y = o.th - mean(o.th(o.t > 3));
% zarf: 1-2 s ve 4-5 s pencerelerindeki tepe genlikleri; frekans sıfır geçişlerinden
A1 = max(abs(y(o.t > 1 & o.t < 2)));  A2 = max(abs(y(o.t > 4 & o.t < 5)));
g = find(y(1:end-1) < 0 & y(2:end) >= 0 & o.t(1:end-1) > 1);
f = (numel(g) - 1)/(o.t(g(end)) - o.t(g(1)));
sig = log(A2/A1)/3;                                    % 1/s
zeta = -sig/(2*pi*f);
end

function s = sy(x)
if isnan(x), s = '-'; else, s = sprintf('%.3f', x); end
end
