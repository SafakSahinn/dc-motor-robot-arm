function kok_neden_2
% KOK_NEDEN_2  Parça 2: DF'nin varsayımları benzetimde tutuyor mu?
% Dişli sapması x(t) = B + A sin(wt) varsayımı ve buna göre etkin sertlik n1.
% Uyuşmayan hücreler (kok_neden_1: DF çevrim, benzetim salınımsız) 0,20 N m sarsıntıyla
% (DF frekansında, t < 1 s) zorlanır; sarsıntının son 3 tam periyodunda ölçülür. Kontrol olarak
% her ikisinde de çevrimli hücrelerde serbest çevrimin son 1 s'sindeki tam periyotlar.
% Ölçülenler (r ile normalize): a = birinci harmonik genliği, b = ortalama, sinüs dışı pay
% (2.-10. harmoniklerin birinciye oranı), temas oranı; dişli torkunun birinci harmoniğinden
% etkin kazanç N = T1/(Ks X1) (gerçel kısım: etkin sertlik). Karşılaştırma:
%   n1_DF   = DF'nin kullandığı: aynı a, DC dengesinden b_DF(a)
%   n1_b    = sinüs varsayımı, ölçülen b ile (ortalama kayması etkisini ayırır)
%   N_sim   = gerçek (dalga biçimi sinüs değil)
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;  [AC, KP] = meshgrid(B.ac, kp);
dz = yercekimli_df('dz');
hucre = @(a, r) find(AC == a & abs(KP - r^2*p.Ks/p.KV) < 1e-9);
uy = arrayfun(@(a, r) hucre(a, r), [15 30 60 120 150], [0.65 0.80 0.95 0.95 0.80]);
assert(all(K.uy(uy)));
% kontrol: 30° ve 60°'de benzetimde çevrimli (en büyük başlangıçta sınıf 3), DF'de de çevrimli en küçük kazanç
ko = [];
lc = reshape(B.C(end, :) == 3, size(AC));
for a = [30 60]
    j = find(AC == a & lc & K.y.sinif == 'C');
    if isempty(j), continue; end
    [~, i] = min(KP(j));  ko(end+1) = j(i); %#ok<AGROW>
end
f0 = median(K.y.f(K.uy));
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 2: DF varsayımları (D, %s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('  hücre       durum      f Hz   a=A/r  b=B/r  b_DF  sinüs dışı  temas sim/DF  N_sim (Re, Im)  n1_b  n1_DF  beta  ort.tork/mgl sin\n');
q = p;  q.adim = 0.2;  q.T = 1;  q.dA = 0.20;  q.df = f0;  q.dT = 1;
o = kol_benzetim(q, AC(uy)', KP(uy)');
for i = 1:numel(uy)
    olc(o.t, o.delta(:, i), o.tau_s(:, i), f0, 1, uy(i), 'zorlanmış');
end
q = p;  q.adim = 5;  q.T = 8;
o = kol_benzetim(q, AC(ko)', KP(ko)');
for i = 1:numel(ko)
    r = rejim_sinifla(o.t, rad2deg(o.th(:, i)) - AC(ko(i)), struct('A_min', 0.05, 'T_at', 4));
    olc(o.t, o.delta(:, i), o.tau_s(:, i), r.f, q.T, ko(i), 'serbest LC');
end
fclose(fid);

    function olc(t, x, tau, f, tson, m, durum)
        Tp = 1/f;  n = floor(min(3, f*(tson - 0.3)));  w = t >= tson - n*Tp & t < tson;
        tt = t(w);  xx = x(w)/p.r;  ty = tau(w)/(p.Ks*p.r);
        X = @(k, y) 2*mean(y.*exp(-1i*2*pi*k*f*tt));   % k. harmonik (karmaşık genlik)
        X1 = X(1, xx);  a = abs(X1);  b = mean(xx);
        hk = arrayfun(@(k) abs(X(k, xx)), 2:10);
        thd = sqrt(sum(hk.^2))/a;
        N = X(1, ty)/X1;                               % etkin kazanç (Ks ile normalize)
        tem = mean(abs(xx) > 1);
        be = p.mgl*sin(deg2rad(AC(m)))/(p.Ks*p.r);
        bdf = fzero(@(bb) dz(a, bb) - be, [0, 1 + be + a]);
        [~, n1df] = dz(a, bdf);  [~, n1b] = dz(a, b);
        ps = linspace(0, 2*pi, 2001);  temdf = mean(abs(bdf + a*sin(ps)) > 1);
        yaz('  %3d°/%.2f  %-10s %5.2f  %5.2f  %5.2f  %5.2f   %5.2f      %.2f/%.2f    %5.2f %+5.2f   %5.2f  %5.2f  %4.2f  %5.2f\n', ...
            AC(m), sqrt(KP(m)*p.KV/p.Ks), durum, f, a, b, bdf, thd, tem, temdf, real(N), imag(N), n1b, n1df, be, mean(ty)/be);
    end
end
