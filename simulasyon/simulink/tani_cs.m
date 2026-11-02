function tani_cs(kosu, mod, mot)
% TANI_CS  Adım 4.3, c_s denemesi: kol tarafına darbe (çekiç testi), sönüm AS5600'den.
% Neden: c_s yarı statik taramadan ölçülemiyor (Adım 2), ama kritik r_gs öngörüsü ona duyarlı
% (tarama_cs: her 0.02 N m s/rad ~0.10 r_gs). Adım 2'deki chirp'te sapma enkoderin bir sayımının altında
% kalmıştı; burada yalnız kolun açısına (AS5600, enkoderden 3 kat ince) bakılır.
% Deney: kol 90°'de, P-PI (r_gs 0.5) tutuyor, mod 3. t = 1 s'de kola yarım sinüs tork darbesi
% (10 ms, aşağı, yani dişliyi daha çok sıkıştıran yönde). Genlik, dişli temasta kalacak kadar küçük
% (dinamik dişli torku ön yükü mgl aşmamalı).
% Analiz: darbe bittikten sonraki θ_L kaydına (AS5600) sönümlü sinüs uydurulur:
%   θ(t) = c0 + c1 t + e^{-σ t}(a cos ωt + b sin ωt);  ζ_göz = σ / sqrt(σ² + ω²)
% (σ, ω fminsearch ile; c0, c1, a, b doğrusal). c_s ile ζ_göz arasındaki eğri benzetimden bulunur; c_s
% ölçülebilir mi sorusu: ζ_göz'ün c_s'ye göre değişimi, gerçekçi koşular arasındaki dağınıklıktan büyük mü?
% mod 'cs'    (varsayılan) c_s 0/0.01/0.02/0.04, ideal + gerçekçi
% mod 'dayan' sağlamlık: gerçekçi, c_s 0.02, modelin bilinmeyenleri (F_s, F_c, darbe, kazanç, J_L) tek tek
%             değiştirilir; ζ_göz kayması, c_s hatasına eğimle çevrilir
% tani_cs(true|false, mod)  true: benzetimleri koşar (kayıt tani_cs[_dayan]_kayit.mat), false: yalnız analiz
if nargin < 1, kosu = true; end
if nargin < 2, mod = 'cs'; end
if nargin < 3, mot = 3; end                            % sürücü modu (1 gerilim, 3 akım döngüsü)
kok = fileparts(mfilename('fullpath'));
ek = '';  if ~strcmp(mod, 'cs'), ek = ['_' mod]; end
if mot ~= 3, ek = sprintf('%s_mod%d', ek, mot); end
dosya = fullfile(kok, ['tani_cs' ek '_kayit.mat']);
if kosu, R = benzet(kok, varyantlar(mod), mot); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_cs_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
Tu = 0.6;                                               % uydurma penceresi: darbe sonu + Tu s
yaz('=== Adım 4.3 c_s denemesi (%s): kola darbe, kol 90°, mod %d (%s)\n', mod, mot, datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Varsayılan: darbe -0.42 N m × 10 ms yarım sinüs, P-PI r_gs 0.5; uydurma %.1f s. AS5600 sayımı %.3f°\n', Tu, rad2deg(2*pi/4096));
yaz('%-14s %5s %2s | %8s %8s %7s | %7s %7s | %6s %6s\n', 'varyant', 'c_s', '#', 'temas°', 'θ_L pp', 'φ say', ...
    'f Hz', 'ζ_göz', 'σ 1/s', 'rms°');
for k = 1:numel(R)
    K = R(k).K;  t = K.t;
    t1 = R(k).d0 + R(k).Td;  s = t >= t1 & t <= t1 + Tu;
    tt = t(s) - t1;  y = rad2deg(K.thL(s));
    [sg, om, rm] = sonumlu(tt, y);
    R(k).z = sg/sqrt(sg^2 + om^2);  R(k).f = om/(2*pi);
    pp = (max(y) - min(y))/rad2deg(2*pi/4096);
    sp = round((max(K.phi(s)) - min(K.phi(s)))/R(k).qM);
    yaz('%-14s %5.3f %2d | %8.3f %8.1f %7d | %7.2f %7.4f | %6.2f %6.3f\n', R(k).ad, R(k).cs, R(k).n, ...
        R(k).temas, pp, sp, R(k).f, R(k).z, sg, rm);
end
yaz('Özet: ζ_göz ortalama ± std\n');
ad = unique({R.ad}, 'stable');
egim = 2.61;                                            % dζ_göz/dc_s, gerçekçi 'cs' koşusundan (0.01 -> 0.04)
z0 = NaN;
for a = ad
    ix = strcmp({R.ad}, a{1});
    for c = unique([R(ix).cs])
        z = [R(ix & [R.cs] == c).z];
        if strcmp(mod, 'dayan') && strcmp(a{1}, 'taban'), z0 = mean(z); end
        if strcmp(mod, 'dayan') && ~isnan(z0)
            yaz('  %-14s c_s %.3f: ζ_göz %.4f ± %.4f (%d)  -> c_s kestirimi %.4f (hata %+.4f)\n', a{1}, c, ...
                mean(z), std(z), numel(z), 0.02 + (mean(z) - z0)/egim, (mean(z) - z0)/egim);
        elseif strcmp(mod, 'kilit')
            % kilitli motor: kol dişli yayı üzerinde tek kütle, ζ = (c_s + b_L)/(2 sqrt(K_s J_L)); J_L x1.05
            % varyantında bile formül nominal J_L ile (J_L'deki hata kestirime böyle yansır)
            ce = 2*sqrt(R(1).Ks*R(1).JL)*mean(z) - R(1).bL;
            yaz('  %-14s c_s %.3f: ζ_göz %.4f ± %.4f (%d)  -> formülle c_s %.4f (hata %+.4f)\n', a{1}, c, ...
                mean(z), std(z), numel(z), ce, ce - c);
        else
            yaz('  %-14s c_s %.3f: ζ_göz %.4f ± %.4f (%d koşu)\n', a{1}, c, mean(z), std(z), numel(z));
        end
    end
end
fclose(fid);
end

function V = varyantlar(mod)
% her satır: {ad, düzey, c_s listesi, koşu sayısı, alan/değer çiftleri}
if strcmp(mod, 'cs')
    V = {'ideal', 'ideal', [0 0.01 0.02 0.04], 1, {};
         'gercekci', 'gercekci', [0 0.01 0.02 0.04], 3, {}};
elseif strcmp(mod, 'kilit')
    k = {'JMx', 1e4};
    V = {'kilit',          'gercekci', [0 0.01 0.02 0.04], 2, k;
         'kilit Fs 0.04',  'gercekci', 0.02, 2, [k, {'Fs', 0.04}];
         'kilit Fs 0.09',  'gercekci', 0.02, 2, [k, {'Fs', 0.09}];
         'kilit r_gs 0.6', 'gercekci', 0.02, 2, [k, {'rg', 0.6}];
         'kilit darbe-.21','gercekci', 0.02, 2, [k, {'dA', -0.21}];
         'kilit darbe-.63','gercekci', 0.02, 2, [k, {'dA', -0.63}];
         'kilit JL x1.05', 'gercekci', 0.02, 2, [k, {'JLx', 1.05}];
         'kilit ideal',    'ideal',    [0 0.02 0.04], 1, k};
else
    V = {'taban',        'gercekci', 0.02, 2, {};
         'Fs 0.04',      'gercekci', 0.02, 2, {'Fs', 0.04};
         'Fs 0.09',      'gercekci', 0.02, 2, {'Fs', 0.09};
         'Fc 0.03',      'gercekci', 0.02, 2, {'Fc', 0.03};
         'Fc 0.05',      'gercekci', 0.02, 2, {'Fc', 0.05};
         'darbe -0.21',  'gercekci', 0.02, 2, {'dA', -0.21};
         'darbe -0.63',  'gercekci', 0.02, 2, {'dA', -0.63};
         'r_gs 0.4',     'gercekci', 0.02, 2, {'rg', 0.4};
         'r_gs 0.6',     'gercekci', 0.02, 2, {'rg', 0.6};
         'JL x1.05',     'gercekci', 0.02, 2, {'JLx', 1.05};
         'bL x10',       'gercekci', 0.02, 2, {'bLx', 10}};
end
end

function [sg, om, rm] = sonumlu(t, y)
% θ = c0 + c1 t + e^{-σt}(a cos ωt + b sin ωt); σ, ω doğrusal olmayan, gerisi en küçük kareler
f0 = baskin(t, y);
mal = @(v) norm(artik(v, t, y));
v = fminsearch(mal, [log(5), 2*pi*f0], optimset('Display', 'off', 'TolX', 1e-8, 'TolFun', 1e-12, 'MaxFunEvals', 4000));
sg = exp(v(1));  om = v(2);  rm = sqrt(mean(artik(v, t, y).^2));
end

function e = artik(v, t, y)
sg = exp(v(1));  om = v(2);  E = exp(-sg*t);
A = [ones(size(t)), t, E.*cos(om*t), E.*sin(om*t)];
e = y - A*(A\y);
end

function f = baskin(t, y)
% kaba başlangıç: doğrusal eğilim çıkarılmış sinyalin sıfır geçişlerinden frekans
y = y - polyval(polyfit(t, y, 1), t);
g = find(diff(sign(y)) ~= 0);
if numel(g) < 3, f = 10; else, f = (numel(g) - 1)/(2*(t(g(end)) - t(g(1)))); end
end

function R = benzet(kok, V, mot)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
rng(17);
R = struct('ad', {}, 'duz', {}, 'cs', {}, 'n', {}, 'K', {}, 'temas', {}, 'd0', {}, 'Td', {}, 'qM', {}, ...
           'Ks', {}, 'JL', {}, 'bL', {}, 'z', {}, 'f', {});
for v = 1:size(V, 1)
    [ad, duz, csl, nTek, ayar] = V{v, :};
    for c = csl
        for n = 1:nTek
            o = struct('rg', 0.5, 'd0', 1, 'Td', 0.01, 'dA', -0.42, 'Fs', 0.06, 'Fc', 0.04, 'JLx', 1, 'bLx', 1, 'JMx', 1);
            for a = 1:2:numel(ayar), o.(ayar{a}) = ayar{a+1}; end
            q = p0;  q.adim = 0;  q.T = 2;  q.Tan = q.T;  q.mot = mot;  q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
            q.cs = c;  q.dA = o.dA;  q.df = 1/(2*o.Td);  q.d0 = o.d0;  q.dT = o.d0 + o.Td;
            q.JL = q.JL*o.JLx;  q.bL = q.bL*o.bLx;  q.JM = q.JM*o.JMx;
            if strcmp(duz, 'ideal')
                q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;  ofs = 0;
            else
                q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
                q.Fc = o.Fc;  q.Fs = o.Fs;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
                ofs = rand*q.qL;                            % başlangıcın AS5600 ızgarasına göre konumu
            end
            th0 = pi/2 + ofs;
            S = sim_param(q, 90, o.rg^2*q.Ks/q.KV);
            q.x0 = [th0 + q.r + q.mgl*sin(th0)/q.Ks; 0; th0; 0];  q.z0 = q.mgl*sin(th0)/S.KI;
            q.iSeed = 900 + n;
            S = sim_param(q, 90, o.rg^2*q.Ks/q.KV);
            in = Simulink.SimulationInput(mdl);
            in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
                   .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
                   .setVariable('Tsur', S.Tsur);
            K = olcum_oku(sim(in));
            X = K.g.x;  s = K.g.t > o.d0;
            temas = rad2deg(min(X(s,1) - X(s,3)) - q.r);
            fprintf('%s c_s %.3f #%d: temas payı en az %.3f°\n', ad, c, n, temas);
            K.g = [];
            R(end+1) = struct('ad', ad, 'duz', duz, 'cs', c, 'n', n, 'K', K, 'temas', temas, 'd0', o.d0, ...
                              'Td', o.Td, 'qM', 2*pi/(11*4*q.N), 'Ks', q.Ks, ...
                              'JL', q.JL/o.JLx, 'bL', q.bL, 'z', NaN, 'f', NaN); %#ok<AGROW>
        end
    end
end
close_system(mdl, 0);
end
