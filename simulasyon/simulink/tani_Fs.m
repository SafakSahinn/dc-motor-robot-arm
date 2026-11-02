function tani_Fs(kosu, mot)
% TANI_FS  Adım 4.3, Adım 4c: motorun statik sürtünmesi F_s, kopma torku deneyiyle (kol sökülü).
% Neden: 4b'de ölçülmeyen tek parametre F_s, kritik r_gs öngörüsünü 60-90°'de bir tarama adımı (0.05) kaydırıyor.
% Deney: Adım 1'in boşta düzeneği (kol yok, r = 1e4 rad), mod 3 (akım döngüsü), açık çevrim. Torka çok yavaş
% sinüs: 0.1 N m, 0.02 Hz (sıfır geçişinde ~0.013 N m/s rampa). Her yarım periyotta motor bir kez kopar.
% Kopma anı: aynı yönde, aralarında <= 50 ms olan iki ardışık enkoder sayımının ilki. Tek sayım yetmez:
% modeldeki Stribeck sürtünmesi tanh(w/veps) ile yumuşatılmış, kopmadan önce de çok yavaş sürünmeye izin
% veriyor (birkaç saniyede bir sayım). Gerçek dişli yapışır; donanımda algılama daha temiz olur.
% F_s kestirimi: kopma anından önceki 20 ms'de K_m i ortalaması (K_m ön adımdan bilinir, burada gerçek).
% Rampa gecikmesi: kopmadan ilk sayıma kadar geçen süre (~30-50 ms) x rampa eğimi (~%1) kadar fazla okur.
% Varyantlar: gerçek F_s 0.06 (varsayılan) ve 0.09 (yöntem F_s'yi izliyor mu).
% tani_Fs()      benzetimleri koşar (tani_Fs_kayit.mat), analiz eder;  tani_Fs(false) yalnız analiz
% tani_Fs(kosu, 1)  mod 1 (gerilim; V = R_a u / K_m, durgunken tork = u) ile, kayıt tani_Fs_mod1_kayit.mat
if nargin < 1, kosu = true; end
if nargin < 2, mot = 3; end                            % sürücü modu (1 gerilim, 3 akım döngüsü)
ekm = '';  if mot ~= 3, ekm = sprintf('_mod%d', mot); end
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, ['tani_Fs' ekm '_kayit.mat']);
if kosu, R = benzet(kok, mot); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_Fs_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
Wb = 0.05;  Wi = 0.02;
yaz('=== Adım 4.3 Adım 4c: F_s kopma torku, boşta, mod %d, tork sinüsü 0.1 N m 0.02 Hz (%s)\n', mot, datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Kopma: aralarında <= %.0f ms olan iki sayımın ilki; tork = K_m i, önceki %.0f ms ortalaması\n', 1e3*Wb, 1e3*Wi);
yaz('%-9s %5s %2s | %8s %8s | %7s %7s | %s\n', 'sensör', 'F_s', '#', 'F_s+ ', 'F_s- ', 'hata+%', 'hata-%', 'sürünme sayımı (+/-)');
T = struct();
for k = 1:numel(R)
    K = R(k).K;  S = R(k).S;
    [fp, np] = kopma(K, S.Km, +1, Wb, Wi);
    [fm, nm] = kopma(K, S.Km, -1, Wb, Wi);
    e = 100*([fp, fm] - S.Fs)/S.Fs;
    yaz('%-9s %5.3f %2d | %8.4f %8.4f | %+7.2f %+7.2f | %d / %d\n', R(k).duz, S.Fs, R(k).n, fp, fm, e, np, nm);
    a = sprintf('%s_%03d', R(k).duz, round(1e3*S.Fs));
    if ~isfield(T, a), T.(a) = []; end
    T.(a) = [T.(a), e];
end
for a = fieldnames(T)'
    yaz('  %-14s hata %+.2f ± %.2f %% (%d kopma)\n', a{1}, mean(T.(a{1}), "omitnan"), std(T.(a{1}), "omitnan"), sum(~isnan(T.(a{1}))));
end
fclose(fid);
end

function [F, nSur] = kopma(K, Km, yon, Wb, Wi)
% yon yönündeki ilk kopma: u o yönde iken, aynı yönde iki sayım <= Wb aralıkla
t = K.t;  Ts = t(2) - t(1);
dp = [0; diff(K.phi)];
ix = find(sign(dp) == yon & sign(K.u) == yon);
F = NaN;  nSur = 0;
for j = 1:numel(ix) - 1
    if t(ix(j+1)) - t(ix(j)) <= Wb
        s = ix(j) - round(Wi/Ts) : ix(j) - 1;
        F = yon*Km*mean(K.i(s));
        return
    end
    nSur = nSur + 1;
end
end

function R = benzet(kok, mot)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
rng(19);
R = struct('duz', {}, 'n', {}, 'K', {}, 'S', {});
V = {'ideal', 0.06, 1;  'gercekci', 0.06, 4;  'gercekci', 0.09, 2};
for v = 1:size(V, 1)
    [duz, Fs, nTek] = V{v, :};
    for n = 1:nTek
        q = p0;  q.adim = 0;  q.T = 36;  q.Tan = q.T;  q.mot = mot;  q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
        q.r = 1e4;                                          % kol yok
        q.dny = struct('yer','acik','sekil','sinus','A',0.1,'t0',0.5,'Td',Inf,'f0',0.02,'u0',0);
        q.Fc = 0.04;  q.Fs = Fs;
        if strcmp(duz, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 2*pi/(11*4*q.N);  q.qI = 0;  q.iGur = 0;  ofs = 0;
            % ideal düzeyde de enkoder nicemli (algılama sayımla); yalnız akım ölçümü kusursuz
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
            ofs = rand*q.qM;
        end
        q.x0 = [ofs; 0; ofs; 0];  q.z0 = 0;  q.iSeed = 950 + n;
        S = sim_param(q, 0, 1);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        K.g = [];
        R(end+1) = struct('duz', duz, 'n', n, 'K', K, 'S', S); %#ok<AGROW>
        fprintf('%s F_s %.2f #%d bitti\n', duz, Fs, n);
    end
end
close_system(mdl, 0);
end
