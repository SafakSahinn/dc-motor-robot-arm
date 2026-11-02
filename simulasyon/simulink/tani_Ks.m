function tani_Ks(kosu)
% TANI_KS  Adım 4.3, Adım 2: dişli sertliği K_s, yarı statik taramayla (kol takılı).
% Neden rezonans değil: kol 90°'de, kapalı çevrimde torka chirp (2-30 Hz) denendi. Gerçekçi düzeyde motorun
% statik sürtünmesi (F_s = 0.06 N m) küçük uyarımı yutuyor, motor kıpırdamıyor. Dişlinin temasta kalması için
% dinamik sapma en fazla +-mgl/K_s = +-1.4° (enkoderde ~5 sayım) olabiliyor; ölçülen dinamik sapma 1 enkoder
% sayımının altında kaldı. Rezonans (ve c_s) bu sensörlerle görülemiyor.
% Yöntem: P-PI kapalı çevrim, mod 3, referansa yavaş sinüs 90° +- 70° (0.05 Hz, 20 s). Kol 20°-160° arasında
% dönerken yerçekimi dişliyi hep aynı yüze yaslıyor (temas sürekli), dişli torku mgl sin(th) ile değişiyor,
% sapma d = phi - thL da onunla. Dişli torku motor tarafından (K_m, J_M, b_M, F_c Adım 1'den bilinir):
%   tg = K_m i - J_M dw/dt - b_M w - F_c sgn(w),       tg = K_s (d - r) + c_s dd/dt
% Pencere ortalaması (100 ms, örtüşmesiz; dw/dt yerine pencere uçlarındaki hız, ±10 örnek yerel eğim):
%   mean(tg) = K_s mean(d) - K_s r [+ c_s (d_son - d_ilk)/W]
% Hız pencere içinde yön değiştiriyor ya da |w| < vmin ise pencere atılır (Stribeck bölgesi, sgn belirsiz).
% Kol sürekli döndüğünden phi ve thL her pencerede birçok sayım geçer; nicemleme hatası ortalamada küçülür.
% Kesişim (K_s r / K_s) r'yi vermez: gerçek donanımda enkoder ve AS5600 sıfırları bağımsız (bilinmeyen ofset).
% Burada yalnız benzetimde kontrol için yazılır; r Adım 3'te. c_s yarı statik harekette görünmez (dd/dt ~ 0).
% Parametre takımları: "gerçek" (sim_param) ve "Adım 1" (tani_JM gerçekçi, V sinüsü, 100 ms kestirimleri:
% K_m +%0.02, J_M -%0.21, b_M +%1.35, F_c 0.0396).
% tani_Ks()       benzetimleri koşar, kayıtları tani_Ks_kayit.mat'a yazar, analiz eder
% tani_Ks(false)  yalnız analiz
if nargin < 1, kosu = true; end
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, 'tani_Ks_kayit.mat');
if kosu, R = benzet(kok); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_Ks_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
W = 0.1;  m = 10;  vmin = 0.1;  tbas = 1.0;
yaz('=== Adım 4.3 Adım 2: K_s yarı statik tarama, kol 90° +- 70°, 0.05 Hz, P-PI, mod 3 (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Pencere %.0f ms, hız ±%d örnek eğim, |w| < %.2f rad/s atılır, ilk %.0f s atılır. Gerçek Ks %.3g, r %.3f°, cs %.3g\n', ...
    1e3*W, m, vmin, tbas, R(1).S.Ks, rad2deg(R(1).S.r), R(1).S.cs);
yaz('Ks hatası %%. tümü = bütün pencereler; y/a = yalnız yukarı/aşağı; ort = (y + a)/2. r_k = kesişim, r_k* = (qM - qL)/2 eklenmiş\n');
yaz('%-9s %2s %4s | %7s %7s %7s %7s %7s | %13s %7s | %6s %6s %6s\n', 'sensör', '#', 'n', 'tüm+cs', 'tümü', 'y', 'a', ...
    'ort', 'Adım1: tümü', 'ort', 'r_k°', 'r_k*°', 'cs');
for duz = {'ideal', 'gercekci'}
    ix = find(strcmp({R.duz}, duz{1}));
    T = [];
    for k = ix
        K = R(k).K;  S = R(k).S;
        P = struct('Km', S.Km, 'JM', S.JM, 'bM', S.bM, 'Fc', S.Fc);
        P1 = struct('Km', S.Km*1.0002, 'JM', S.JM*(1 - 0.0021), 'bM', S.bM*1.0135, 'Fc', 0.0396);
        if S.qM == 0, P1.Fc = S.Fc; end                     % ideal düzeyde Adım 1 F_c'yi doğru bulmuştu
        e = @(th) 100*(th(1) - S.Ks)/S.Ks;
        [tc, n] = ks_kestir(K, P, W, tbas, m, vmin, 0, true);
        t0 = ks_kestir(K, P, W, tbas, m, vmin, 0, false);
        ty = ks_kestir(K, P, W, tbas, m, vmin, 1, false);
        ta = ks_kestir(K, P, W, tbas, m, vmin, -1, false);
        u0 = ks_kestir(K, P1, W, tbas, m, vmin, 0, false);
        uy = ks_kestir(K, P1, W, tbas, m, vmin, 1, false);
        ua = ks_kestir(K, P1, W, tbas, m, vmin, -1, false);
        rk = rad2deg(t0(2)/t0(1));  rk2 = rk + rad2deg(S.qM - S.qL)/2;
        satir = [e(tc), e(t0), e(ty), e(ta), (e(ty) + e(ta))/2, e(u0), (e(uy) + e(ua))/2, rk, rk2, tc(3)];
        T(end+1, :) = satir; %#ok<AGROW>
        yaz('%-9s %2d %4d | %+7.2f %+7.2f %+7.2f %+7.2f %+7.2f | %13.2f %+7.2f | %6.3f %6.3f %6.3f\n', ...
            duz{1}, k - ix(1) + 1, n, satir);
    end
    if numel(ix) > 1
        yaz('%-9s %7s | %+7.2f %+7.2f %+7.2f %+7.2f %+7.2f | %13.2f %+7.2f | %6.3f %6.3f %6.3f\n', duz{1}, 'ortalama', mean(T));
        yaz('%-9s %7s | %7.2f %7.2f %7.2f %7.2f %7.2f | %13.2f %7.2f | %6.3f %6.3f %6.3f\n', duz{1}, 'std', std(T));
    end
end
fclose(fid);
end

function [th, nP] = ks_kestir(K, P, W, tbas, m, vmin, yon, csli)
% yon: 0 hepsi, +1 yalnız yukarı (w > 0), -1 yalnız aşağı. th = [Ks, Ks r, cs] (csli = false ise cs = NaN)
t = K.t;  Ts = t(2) - t(1);  n = round(W/Ts);
c = (-m:m)'/(Ts*sum((-m:m).^2));
w = conv(K.phi, flipud(c), 'same');  w([1:m, end-m+1:end]) = NaN;
d = K.phi - K.thL;
s = find(t >= tbas, 1);  nP0 = floor((numel(t) - s)/n);
A = zeros(nP0, 3);  b = zeros(nP0, 1);  ok = false(nP0, 1);
for k = 1:nP0
    j = s + (k-1)*n + (0:n);
    wj = w(j);
    if any(isnan(wj)) || min(abs(wj)) < vmin || any(sign(wj) ~= sign(wj(1))), continue; end
    if yon ~= 0 && sign(wj(1)) ~= yon, continue; end
    b(k) = (P.Km*trapz(K.i(j))*Ts - P.JM*(wj(end) - wj(1)) - P.bM*(K.phi(j(end)) - K.phi(j(1))) ...
            - P.Fc*sign(wj(1))*W)/W;
    A(k, :) = [trapz(d(j))*Ts/W, -1, (d(j(end)) - d(j(1)))/W];
    ok(k) = true;
end
A = A(ok, :);  b = b(ok);  nP = numel(b);
if csli, th = A\b; else, th = [A(:, 1:2)\b; NaN]; end
end

function R = benzet(kok)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
rng(11);
R = struct('duz', {}, 'K', {}, 'S', {});
for duz = {'ideal', 'gercekci'}
    nTek = 5;  if strcmp(duz{1}, 'ideal'), nTek = 1; end
    for n = 1:nTek
        q = p0;  q.adim = 0;  q.T = 21;  q.Tan = q.T;  q.mot = 3;  q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
        q.dny = struct('yer','ref','sekil','sinus','A',deg2rad(70),'t0',1,'Td',20,'f0',0.05);
        if strcmp(duz{1}, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;  ofs = 0;
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
            ofs = rand*q.qM;                                % başlangıcın sensör ızgaralarına göre konumu
        end
        % başlangıç: kol 90°'de durgun, yerçekimi dişliyi yaslamış (ön yüklü yay), integral yükü taşıyor
        th0 = pi/2 + ofs;
        S = sim_param(q, 90, 0.8^2*q.Ks/q.KV);
        q.x0 = [th0 + q.r + q.mgl*sin(th0)/q.Ks; 0; th0; 0];  q.z0 = q.mgl*sin(th0)/S.KI;
        q.iSeed = 700 + n;
        S = sim_param(q, 90, 0.8^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        X = K.g.x;  s = K.g.t > 1;  dg = X(s,1) - X(s,3);
        fprintf('%s %d: temas payı (d - r) en az %.3f°, thL %.1f..%.1f°\n', duz{1}, n, rad2deg(min(dg) - q.r), ...
            rad2deg(min(X(s,3))), rad2deg(max(X(s,3))));
        K.g = [];
        R(end+1) = struct('duz', duz{1}, 'K', K, 'S', S); %#ok<AGROW>
    end
end
close_system(mdl, 0);
end
