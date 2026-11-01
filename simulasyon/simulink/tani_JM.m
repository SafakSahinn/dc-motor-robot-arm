function tani_JM(kosu)
% TANI_JM  Adım 4.3, Adım 1: motor eylemsizliği J_M, viskoz sürtünme b_M, Coulomb sürtünmesi F_c.
% Kol takılmadan (tani_Km ile aynı düzenek; benzetimde boşluk r = 1e4 rad, motor yüke hiç değmiyor),
% açık çevrim mod 1. Mekanik denklem (kol tarafına indirgenmiş eşdeğer motor):
%   J_M dw/dt = K_m i - b_M w - F_c sgn(w)          (Stribeck kısmı düşük hızda; o pencereler atılır)
% Pencere [a, b] üzerinde integral:
%   J_M (w_b - w_a) + b_M (phi_b - phi_a) + F_c sgn(w) W = K_m int i dt
% w yalnız pencere uçlarında gerekiyor: enkoderden çevrim dışı, ±m örnekli yerel doğru uydurmasının
% eğimi (türev değil, 2m+1 noktanın en küçük kareler eğimi). Pencere içinde |w| < vmin olan pencereler
% atılır (yön değişimi ve Stribeck bölgesi; orada sürtünme sabit F_c sgn(w) değil).
% K_m aynı kayıttan km_kestir ile (donanımda tek koşu ikisini birden verir); gerçek K_m ile de
% karşılaştırılır ki K_m hatasının J_M'ye ne kadar geçtiği görülsün.
% Uyarımlar: V sinüsü 0.25 Hz (tani_Km ile aynı) ve log chirp 0.5 -> 5 Hz (ivme zengin).
% tani_JM()       benzetimleri koşar, kayıtları tani_JM_kayit.mat'a yazar, analiz eder
% tani_JM(false)  yalnız analiz (kayıtlı veriden)
if nargin < 1, kosu = true; end
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, 'tani_JM_kayit.mat');
if kosu, R = benzet(kok); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_JM_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
m = 10;  vmin = 2;                                     % eğim uydurması ±10 ms; |w| eşiği [rad/s]
yaz('=== Adım 4.3 Adım 1: J_M, b_M, F_c, kol takılmadan, mod 1 açık çevrim (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Hız: ±%d örnekli yerel doğru eğimi; |w| < %g rad/s içeren pencereler atılır; ilk 1 s atılır\n', m, vmin);
S1 = R(1).S;
yaz('Gerçek: JM %.4g, bM %.3g, Fc ideal %.3g / gerçekçi %.3g N m, Km %.4f\n', S1.JM, S1.bM, R(1).S.Fc, R(end).S.Fc, S1.Km);
yaz('%-9s %-10s %5s %6s %3s  %8s %8s %8s  | gerçek Km ile: %8s %8s\n', 'sensör', 'uyarım', 'W ms', 'Km %', ...
    'n', 'JM %', 'bM %', 'Fc', 'JM %', 'bM %');
for k = 1:numel(R)
    K = R(k).K;  S = R(k).S;
    thK = km_kestir(K, 0.1, 1.0);
    for W = [0.02 0.05 0.1]
        [th, n] = jm_kestir(K, W, 1.0, m, vmin, thK(1));
        tg = jm_kestir(K, W, 1.0, m, vmin, S.Km);
        yaz('%-9s %-10s %5.0f %+6.2f %3d  %+8.2f %+8.2f %8.4f  |                %+8.2f %+8.2f\n', R(k).duz, R(k).uyar, ...
            1e3*W, 100*(thK(1) - S.Km)/S.Km, n, 100*(th(1) - S.JM)/S.JM, 100*(th(2) - S.bM)/S.bM, th(3), ...
            100*(tg(1) - S.JM)/S.JM, 100*(tg(2) - S.bM)/S.bM);
    end
end
fclose(fid);
end

function R = benzet(kok)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
D = {'V sin.25Hz', struct('yer','acik','sekil','sinus','A',0.4,'t0',0,'Td',Inf,'f0',0.25,'u0',0), 9;
     'chirp.5-5', struct('yer','acik','sekil','logchirp','A',0.4,'t0',0.5,'Td',10,'f0',0.5,'f1',5,'u0',0), 11};
R = struct('duz', {}, 'uyar', {}, 'K', {}, 'S', {});
for duz = {'ideal', 'gercekci'}
    for d = 1:size(D, 1)
        q = p0;  q.adim = 0;  q.T = D{d,3};  q.Tan = q.T;  q.mot = 1;  q.dny = D{d,2};
        q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;  q.r = 1e4;     % kol yok
        if strcmp(duz{1}, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
        end
        q.iSeed = 200 + d;
        S = sim_param(q, 0, 0.8^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        K.g = [];
        R(end+1) = struct('duz', duz{1}, 'uyar', D{d,1}, 'K', K, 'S', S); %#ok<AGROW>
        fprintf('%s %s bitti (vs %.3g, veps %.3g, Fc %.3g)\n', duz{1}, D{d,1}, S.vs, S.veps, S.Fc);
    end
end
close_system(mdl, 0);
end

function [th, nP] = jm_kestir(K, W, tbas, m, vmin, Km)
% th = [JM bM Fc]; nP kullanılan pencere sayısı.
t = K.t;  Ts = t(2) - t(1);  n = round(W/Ts);
c = (-m:m)'/(Ts*sum((-m:m).^2));                       % yerel doğru eğimi çekirdeği
w = conv(K.phi, flipud(c), 'same');
w([1:m, end-m+1:end]) = NaN;
s = find(t >= tbas, 1);
nW = floor((numel(t) - s - m)/n);
A = zeros(nW, 3);  b = zeros(nW, 1);  ok = false(nW, 1);
for k = 1:nW
    j = s + (k-1)*n + (0:n);
    wj = w(j);
    if any(isnan(wj)) || min(abs(wj)) < vmin || any(sign(wj) ~= sign(wj(1))), continue; end
    ok(k) = true;
    A(k,:) = [wj(end) - wj(1), K.phi(j(end)) - K.phi(j(1)), sign(wj(1))*W];
    b(k) = Km*trapz(K.i(j))*Ts;
end
nP = sum(ok);
th = A(ok,:)\b(ok);
end
