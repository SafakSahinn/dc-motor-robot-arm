function tani_JM_kol(kosu)
% TANI_JM_KOL  Adım 4.3, Adım 1 yedek yöntemi: kol SÖKÜLEMEZSE J_M (ve F_c) dişli boşluğunun içinde.
% Kol aşağıda asılı (0°). Başlangıç: motor dişlinin bir yüzüne değiyor (donanımda motor yavaşça döndürülür,
% AS5600 kolun kıpırdadığını görünce durulur). Boşluk ortası kullanılmıyor, çünkü r henüz bilinmiyor.
% Önünde 2r = 3° serbest yol var. Mod 3 açık çevrim tork darbesi (A = 0.2 N m, Td = 20 ms) motoru
% karşı yüze doğru itiyor; motor yüke değmeden duruyor (hesap: ~0.044 rad < 2r = 0.052 rad).
% Serbest hareket: J_M dw/dt = K_m i - F_c sgn(w) (- b_M w, burada ihmal: ~60 ms'de etkisi ~%2, ayrılamıyor).
% Enkoder bu harekette ~9 sayım ilerliyor; hız tahmini anlamsız. Motor durgun başladığından denklem
% iki kez integrallenir, hız tamamen düşer:
%   J_M (phi(t) - phi0) + F_c d (t - t0)^2 / 2 = K_m int_t0^t (t - tau) i dtau,    d = darbe yönü
% Hareketin her örneği bir satır; uydurma aralığı t0'dan motor durana ya da kol kıpırdayana kadar.
% Tekrarlar: 10 darbe (5 ileri, 5 geri); gerçekçi düzeyde başlangıç açısı enkoder ızgarasına göre rastgele
% (gerçekte de öyle), böylece nicemleme hatası darbeden darbeye değişiyor.
% K_m: bu senaryoda boşta deneyi yok. Gerçek K_m kullanılır; K_m'deki bağıl hata J_M'ye aynen geçer
% (tani_Km: kol takılı deneyde gerçekçi K_m hatası -%4...-%6, veri sayfası değeri de yaklaşık).
% tani_JM_kol()       benzetimleri koşar, kayıtları tani_JM_kol_kayit.mat'a yazar, analiz eder
% tani_JM_kol(false)  yalnız analiz
if nargin < 1, kosu = true; end
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, 'tani_JM_kol_kayit.mat');
if kosu, R = benzet(kok); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_JM_kol_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
S1 = R(1).S;
yaz('=== Adım 4.3 Adım 1 yedek: J_M kol takılı, boşluk içinde tork darbesi, mod 3 (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Darbe %.2f N m x %.0f ms, başlangıç dişli yüzünde; gerçek JM %.4g, Fc ideal %.3g / gerçekçi %.3g; Km gerçek\n', ...
    R(1).A, 1e3*R(1).Td, S1.JM, R(1).S.Fc, R(end).S.Fc);
yaz('%-9s %3s %4s  %6s %6s %6s %6s  %8s %8s\n', 'sensör', '#', 'yön', 'yol °', 'sayım', 'n', 'kol°', 'JM %', 'Fc');
for duz = {'ideal', 'gercekci'}
    ix = find(strcmp({R.duz}, duz{1}));
    Atum = [];  btum = [];  J = [];
    for k = ix
        [A, b, bil] = satirlar(R(k));
        th = A\b;  J(end+1) = th(1); %#ok<AGROW>
        Atum = [Atum; A]; btum = [btum; b]; %#ok<AGROW>
        yaz('%-9s %3d %+4d  %6.2f %6.1f %6d %6.2f  %+8.2f %8.4f\n', duz{1}, k - ix(1) + 1, R(k).d, bil.yol, ...
            bil.sayim, numel(b), bil.kol, 100*(th(1) - S1.JM)/S1.JM, th(2));
    end
    th = Atum\btum;
    [~, iw] = max(abs(J - S1.JM));
    yaz('%-9s birleşik (%d darbe): JM %+6.2f %%, Fc %.4f; tek darbe JM std %.1f %%, en kötü %+.1f %%\n', duz{1}, ...
        numel(ix), 100*(th(1) - S1.JM)/S1.JM, th(2), 100*std(J)/S1.JM, 100*(J(iw) - S1.JM)/S1.JM);
end
fclose(fid);
end

function [A, b, bil] = satirlar(r)
K = r.K;  S = r.S;  t = K.t;  Ts = t(2) - t(1);
k0 = find(t >= r.t0 - 1e-9, 1);
phi0 = K.phi(k0);  th0 = K.thL(k0);
% bitiş: kol kıpırdadı (AS5600 1.5 basamaktan fazla oynadı) ya da motor durdu (son enkoder değişimi)
kk = k0:numel(t);
kol = find(abs(K.thL(kk) - th0) > 1.5*max(S.qL, 1e-4), 1);
if isempty(kol), kol = numel(kk); end
ds = find(abs(diff(K.phi(kk))) > 0);
if isempty(ds), ds = 1; end
dur = ds(end) + 1;                                      % son değişimin olduğu örnek
if S.qM == 0                                            % ideal: hız ~0'a inince
    w = diff(K.phi(kk))/Ts;  dw = find(abs(w) > 1e-3, 1, 'last');  dur = dw + 1;
end
ke = kk(min(kol - 1, dur));
j = (k0+1):ke;
tau = t(k0:ke) - t(k0);
iK = K.i(k0:ke);
I1 = cumtrapz(tau, iK);  I2 = cumtrapz(tau, I1);       % int (t - tau) i dtau
A = [K.phi(j) - phi0, r.d*tau(2:end).^2/2];
b = S.Km*I2(2:end);
bil.yol = rad2deg(abs(K.phi(ke) - phi0));
bil.sayim = bil.yol/max(rad2deg(S.qM), eps);
if S.qM == 0, bil.sayim = NaN; end
bil.kol = rad2deg(max(abs(K.thL(kk) - th0)));
end

function R = benzet(kok)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
Ad = 0.2;  Td = 0.02;  t0 = 0.1;
rng(7);
R = struct('duz', {}, 'd', {}, 'A', {}, 'Td', {}, 't0', {}, 'K', {}, 'S', {});
for duz = {'ideal', 'gercekci'}
    nTek = 10;  if strcmp(duz{1}, 'ideal'), nTek = 2; end
    for n = 1:nTek
        d = 1 - 2*mod(n + 1, 2);                        % +1, -1, +1, ...
        q = p0;  q.adim = 0;  q.T = 0.4;  q.Tan = q.T;  q.mot = 3;  q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
        q.dny = struct('yer','acik','sekil','basamak','A',d*Ad,'t0',t0,'Td',Td,'u0',0);
        if strcmp(duz{1}, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;  ofs = 0;
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
            ofs = rand*q.qM;                            % başlangıcın enkoder ızgarasına göre konumu
        end
        th0 = ofs;  phi0 = th0 - d*q.r;                 % motor, darbe yönünün tersindeki dişli yüzünde
        q.x0 = [phi0; 0; th0; 0];  q.z0 = 0;
        q.iSeed = 300 + n;
        S = sim_param(q, 0, 0.8^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        K.g = [];
        R(end+1) = struct('duz', duz{1}, 'd', d, 'A', Ad, 'Td', Td, 't0', t0, 'K', K, 'S', S); %#ok<AGROW>
        fprintf('%s darbe %d bitti\n', duz{1}, n);
    end
end
close_system(mdl, 0);
end
