function tani_Km(kosu)
% TANI_KM  Adım 4.3, ön adım: motor sabiti K_m (ve R_a) zıt EMK denkleminden, firmware kaydıyla.
%   V = R_a i + L_a di/dt + K_m dphi/dt          (kol tarafına indirgenmiş eşdeğer motor, sim_param)
% Kaba enkoderin (0.27°) türevini almamak için denklem pencereler üzerinde integrallenir:
%   int V dt = K_m (phi_son - phi_ilk) + R_a int i dt + c (i_son - i_ilk)
% Her pencere bir satır; en küçük kareler. Üçüncü terim (c) L_a DEĞİL: elektrik zaman sabiti (~0.3 ms)
% Ts'nin (1 ms) altında, kayıt L_a'yı göremiyor. c, V ile i kayıtları arasındaki bir örnekten kısa
% zaman kaymasını (R_a i(t - tau) ~ R_a i - R_a tau di/dt) emen bir rahatsızlık parametresi; değeri
% yorumlanmaz (-12 mH çıkıyor). Atılırsa ideal veride bile K_m %3-9 sapıyor; tutulunca %0.3'ün altında.
% Deneyler:
%   kol    kol takılı, 0°, P-PI r_gs 0.8, referansa sinüs (20° 1 Hz, 25° 1.2 Hz), mod 1 ve 3.
%          Zıt EMK gerilimin ancak ~%10'u (R_a i baskın): K_m küçük bir bileşenden çıkarılıyor.
%   bosta  kol takılmadan (benzetimde boşluk r = 1e4 rad: motor kola hiç değmiyor), açık çevrim
%          mod 1, tork komutuna yavaş sinüs (0.25 Hz). Yük yalnız sürtünme: i küçük, zıt EMK baskın.
%          Mod 3 yok: akım döngüsünde motor boşta sınırsız hızlanır; ayrıca mod 3'te V 10 kHz'de
%          değişir, 1 kHz kayıt onun anlık örneği (V'nin Ts ortalaması kaydedilmeli; bkz. README).
% Girdi yalnız firmware kaydı (K.V, K.i, K.phi); gerçek değerler yalnız karşılaştırma için.
% tani_Km()       benzetimleri koşar, kayıtları tani_Km_kayit.mat'a yazar, analiz eder
% tani_Km(false)  yalnız analiz (kayıtlı veriden)
if nargin < 1, kosu = true; end
kok = fileparts(mfilename('fullpath'));
dosya = fullfile(kok, 'tani_Km_kayit.mat');
if kosu, R = benzet(kok); save(dosya, 'R'); else, L = load(dosya); R = L.R; end
fid = fopen(fullfile(kok, 'tani_Km_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 4.3 ön adım: K_m, R_a zıt EMK denkleminden, 3 terimli uydurma (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('İlk 1 s atılır. "EMK payı" = rms(K_m dphi/dt) / rms(V). Hata %% Km, pencere boyuna göre; Ra 100 ms\n');
Wl = [0.02 0.05 0.1 0.2];
yaz('%-6s %-9s %3s %-10s %6s ', 'deney', 'sensör', 'mod', 'uyarım', 'EMK %');
for W = Wl, yaz(' %4.0fms', 1e3*W); end
yaz('  Ra %%\n');
for k = 1:numel(R)
    K = R(k).K;  S = R(k).S;  s = K.t >= 1;
    w = gradient(K.phi, K.t);                          % yalnız EMK payı bilgisi için (kestirimde yok)
    pay = 100*rms(S.Km*w(s))/rms(K.V(s));
    yaz('%-6s %-9s %3d %-10s %6.0f ', R(k).deney, R(k).duz, R(k).mot, R(k).uyar, pay);
    for W = Wl
        th = km_kestir(K, W, 1.0);
        yaz(' %+6.2f', 100*(th(1) - S.Km)/S.Km);
    end
    th = km_kestir(K, 0.1, 1.0);
    yaz('  %+5.2f\n', 100*(th(2) - S.Ra)/S.Ra);
end
yaz('Gerçek (sim_param): Km %.4f V s/rad, Ra %.3f Ohm\n', R(1).S.Km, R(1).S.Ra);
fclose(fid);
end

function R = benzet(kok)
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
% [deney, uyarım etiketi, mod, dny, T]
ref = @(A, f) struct('yer','ref','sekil','sinus','A',deg2rad(A),'t0',0.5,'Td',Inf,'f0',f);
acik = struct('yer','acik','sekil','sinus','A',0.4,'t0',0,'Td',Inf,'f0',0.25,'u0',0);
D = {'kol',   'ref20/1Hz',   1, ref(20,1),   6;  'kol',   'ref20/1Hz',   3, ref(20,1),   6;
     'kol',   'ref25/1.2Hz', 1, ref(25,1.2), 6;  'kol',   'ref25/1.2Hz', 3, ref(25,1.2), 6;
     'bosta', 'V sin.25Hz',  1, acik,        9};
R = struct('deney', {}, 'duz', {}, 'mot', {}, 'uyar', {}, 'K', {}, 'S', {});
for duz = {'ideal', 'gercekci'}
    for d = 1:size(D, 1)
        q = p0;  q.adim = 0;  q.T = D{d,5};  q.Tan = q.T;  q.mot = D{d,3};  q.dny = D{d,4};
        q.Ts = 1e-3;  q.hiz = 'gozlemci';  q.fv = 50;
        if strcmp(D{d,1}, 'bosta'), q.r = 1e4; end    % kol yok: motor yüke hiç değmiyor
        if strcmp(duz{1}, 'ideal')
            q.qL = 0;  q.gL = 0;  q.qM = 0;  q.qI = 0;  q.iGur = 0;
        else
            q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.qI = 0.46e-3;  q.iGur = 1.4e-3;
        end
        q.iSeed = 100 + d;
        S = sim_param(q, 0, 0.8^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        K.g = [];                                      % gerçek durumlar gerekmiyor, dosya küçük kalsın
        R(end+1) = struct('deney', D{d,1}, 'duz', duz{1}, 'mot', D{d,3}, 'uyar', D{d,2}, 'K', K, 'S', S); %#ok<AGROW>
        fprintf('%s %s mod %d %s bitti\n', D{d,1}, duz{1}, D{d,3}, D{d,2});
    end
end
close_system(mdl, 0);
end
