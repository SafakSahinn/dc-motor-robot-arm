function tani_r(kosu, rg, mot)
% TANI_R  Adım 4.3, Adım 3: dişli boşluğu r (yarı genişlik), kol takılı, yarı statik tarama.
% Fikir (Yamada 2016'nın yön değişimi sıçraması, yarı statik hâli): kol 0° +- 60° taranır. Yerçekimi torku
% mgl sin(th) 0°'da işaret değiştirir; kol th > 0'da dişliyi + yüze, th < 0'da - yüze yaslar. Ölçülen sapma
%   dm = phi_enc - thL_AS5600 = d + o   (o: iki sensörün bağımsız sıfırları + nicemleme yuvarlaması)
%   tg = K_s (d - s r),   s = sign(th)   (temas varken)
% Pencere ortalamasıyla (Adım 2'deki gibi): mean(tg) = K_s mean(dm) - K_s r s - K_s o.
% İki yüzün kümeleri arasındaki fark 2r'dir; o iki kümede aynı olduğundan sadeleşir.
% tg motor tarafından (Adım 2 ile aynı): tg = K_m i - J_M dw/dt - b_M w - F_c sgn(w).
% Yüz geçişi (kol boşluktan düşerken) dinamik; |th| < thmin olan pencereler atılır.
% Gerçek donanımı taklit için analizde AS5600 okumasına keyfi bir sıfır ofseti eklenir (yöntemin ofsete
% duyarsız olduğunu göstermek için; benzetimde iki sensörün sıfırı aynı).
% Uydurmalar:  A) K_s, r, o birlikte;  B) K_s Adım 2'den sabit (-%0.24), yalnız r, o.
% Yukarı / aşağı ayrı uydurulup ortalanır (Adım 2'deki yöne bağlı hata).
% tani_r()       benzetimleri koşar, kayıtları tani_r_kayit.mat'a yazar, analiz eder
% tani_r(false)  yalnız analiz
if nargin < 1, kosu = true; end
if nargin < 3, mot = 3; end                            % sürücü modu (1 gerilim, 3 akım döngüsü)
ekm = '';  if mot ~= 3, ekm = sprintf('_mod%d', mot); end
if nargin < 2 || isempty(rg), rg = 0.5; end                           % r_gs; 0.8 küçük açıda salınıyordu (bkz. README)
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, ['tani_r' ekm '_kayit.mat']);
if kosu, R = benzet(kok, rg, mot); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_r_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
W = 0.1;  m = 10;  vmin = 0.1;  tbas = 1.0;  thmin = deg2rad(10);  ofsL = deg2rad(7.3);
yaz('=== Adım 4.3 Adım 3: boşluk r, yarı statik tarama, kol 0° +- 60°, 0.05 Hz, P-PI r_gs %.2f, mod %d (%s)\n', ...
    sqrt(R(1).S.kp*R(1).S.KV/R(1).S.Ks), mot, datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Pencere %.0f ms, |th| < %.0f° atılır, AS5600 ofseti %.1f° eklendi. Gerçek r %.3f°, Ks %.3g\n', ...
    1e3*W, rad2deg(thmin), rad2deg(ofsL), rad2deg(R(1).S.r), R(1).S.Ks);
yaz('r hatası %% (r_A: Ks serbest, r_B: Ks Adım 2). y/a = yalnız yukarı/aşağı, ort = (y + a)/2. Ks_A hatası %%, o_A° (ofset, gerçek %.1f° + yuvarlama)\n', rad2deg(ofsL));
yaz('%-9s %2s %4s %4s | %7s %7s %7s %7s | %7s %7s %7s %7s | %7s %7s\n', 'sensör', '#', 'n+', 'n-', ...
    'r_A', 'y', 'a', 'ort', 'r_B', 'y', 'a', 'ort', 'Ks_A', 'o_A°');
for duz = {'ideal', 'gercekci'}
    ix = find(strcmp({R.duz}, duz{1}));
    T = [];
    for k = ix
        K = R(k).K;  S = R(k).S;
        K.ofs = ofsL;                                    % yalnız sapmaya; yüz seçimi gerçek açıyla
        P = struct('Km', S.Km*1.0002, 'JM', S.JM*(1 - 0.0021), 'bM', S.bM*1.0135, 'Fc', 0.0396);  % Adım 1
        if S.qM == 0, P = struct('Km', S.Km, 'JM', S.JM, 'bM', S.bM, 'Fc', S.Fc); end
        Ks2 = S.Ks*(1 - 0.0024);  if S.qM == 0, Ks2 = S.Ks; end                              % Adım 2
        e = @(x) 100*(x - S.r)/S.r;
        [a0, np, nm] = r_kestir(K, P, W, tbas, m, vmin, thmin, 0, NaN);
        ay = r_kestir(K, P, W, tbas, m, vmin, thmin, 1, NaN);
        aa = r_kestir(K, P, W, tbas, m, vmin, thmin, -1, NaN);
        b0 = r_kestir(K, P, W, tbas, m, vmin, thmin, 0, Ks2);
        by = r_kestir(K, P, W, tbas, m, vmin, thmin, 1, Ks2);
        ba = r_kestir(K, P, W, tbas, m, vmin, thmin, -1, Ks2);
        satir = [e(a0(2)), e(ay(2)), e(aa(2)), (e(ay(2)) + e(aa(2)))/2, ...
                 e(b0(2)), e(by(2)), e(ba(2)), (e(by(2)) + e(ba(2)))/2, ...
                 100*(a0(1) - S.Ks)/S.Ks, rad2deg(a0(3))];
        T(end+1, :) = satir; %#ok<AGROW>
        yaz('%-9s %2d %4d %4d | %+7.2f %+7.2f %+7.2f %+7.2f | %+7.2f %+7.2f %+7.2f %+7.2f | %+7.2f %7.3f\n', ...
            duz{1}, k - ix(1) + 1, np, nm, satir);
    end
    if numel(ix) > 1
        yaz('%-9s %12s | %+7.2f %+7.2f %+7.2f %+7.2f | %+7.2f %+7.2f %+7.2f %+7.2f | %+7.2f %7.3f\n', duz{1}, 'ortalama', mean(T));
        yaz('%-9s %12s | %7.2f %7.2f %7.2f %7.2f | %7.2f %7.2f %7.2f %7.2f | %7.2f %7.3f\n', duz{1}, 'std', std(T));
    end
end
fclose(fid);
end

function [th, np, nm] = r_kestir(K, P, W, tbas, m, vmin, thmin, yon, Ks)
% th = [K_s, r, o]. Ks NaN ise K_s de uydurulur, değilse sabit.
t = K.t;  Ts = t(2) - t(1);  n = round(W/Ts);
c = (-m:m)'/(Ts*sum((-m:m).^2));
w = conv(K.phi, flipud(c), 'same');  w([1:m, end-m+1:end]) = NaN;
d = K.phi - (K.thL - K.ofs);
s0 = find(t >= tbas, 1);  nP0 = floor((numel(t) - s0)/n);
G = zeros(nP0, 1);  D = zeros(nP0, 1);  Sg = zeros(nP0, 1);  ok = false(nP0, 1);
for k = 1:nP0
    j = s0 + (k-1)*n + (0:n);
    wj = w(j);  thj = K.thL(j);
    if any(isnan(wj)) || min(abs(wj)) < vmin || any(sign(wj) ~= sign(wj(1))), continue; end
    if yon ~= 0 && sign(wj(1)) ~= yon, continue; end
    if min(abs(thj)) < thmin || any(sign(thj) ~= sign(thj(1))), continue; end
    G(k) = (P.Km*trapz(K.i(j))*Ts - P.JM*(wj(end) - wj(1)) - P.bM*(K.phi(j(end)) - K.phi(j(1))) ...
            - P.Fc*sign(wj(1))*W)/W;
    D(k) = trapz(d(j))*Ts/W;  Sg(k) = sign(thj(1));  ok(k) = true;
end
G = G(ok);  D = D(ok);  Sg = Sg(ok);
np = sum(Sg > 0);  nm = sum(Sg < 0);
if isnan(Ks)
    x = [D, -Sg, -ones(size(D))] \ G;                  % G = Ks D - (Ks r) s - (Ks o)
    th = [x(1); x(2)/x(1); x(3)/x(1)];
else
    x = [Sg, ones(size(D))] \ (D - G/Ks);              % D - G/Ks = r s + o
    th = [Ks; x(1); x(2)];
end
end

function R = benzet(kok, rg, mot)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
rng(13);
R = struct('duz', {}, 'K', {}, 'S', {});
for duz = {'ideal', 'gercekci'}
    nTek = 5;  if strcmp(duz{1}, 'ideal'), nTek = 1; end
    for n = 1:nTek
        q = p0;  q.adim = 0;  q.T = 21;  q.Tan = q.T;  q.mot = mot;  q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
        q.dny = struct('yer','ref','sekil','sinus','A',deg2rad(60),'t0',1,'Td',20,'f0',0.05);
        if strcmp(duz{1}, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;  ofs = 0;
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
            ofs = rand*q.qM;                                % başlangıcın sensör ızgaralarına göre konumu
        end
        % başlangıç: kol 0°'da durgun asılı, dişli boşluğun ortasında
        q.x0 = [ofs; 0; ofs; 0];  q.z0 = 0;
        q.iSeed = 800 + n;
        S = sim_param(q, 0, rg^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        X = K.g.x;  s = K.g.t > 1 & abs(X(:,3)) > deg2rad(10);
        dg = (X(s,1) - X(s,3)).*sign(X(s,3));
        fprintf('%s %d: |th| > 10° iken temas payı (s d - r) en az %.3f°, thL %.1f..%.1f°\n', duz{1}, n, ...
            rad2deg(min(dg) - q.r), rad2deg(min(X(:,3))), rad2deg(max(X(:,3))));
        K.g = [];
        R(end+1) = struct('duz', duz{1}, 'K', K, 'S', S); %#ok<AGROW>
    end
end
close_system(mdl, 0);
end
