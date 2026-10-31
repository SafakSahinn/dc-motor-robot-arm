function deney_4a()
% DENEY_4A  Adım 4.1: deney kaynakları sm_motor_model'de (mod 1 gerilim, mod 3 akım döngüsü) çalışıyor mu?
% D düzeneği, P-PI, gerçekçi sensör (dogrula_3 ayarı). Her deney bir koşu; özet tarama_4a_log.txt'ye.
% Deneyler (kaynak tanımı blok_ayrik / sim_param'da):
%   serbest   kol aşağıda (0°), 10° saptırılmış, kontrol kapalı, u = 0
%   tork_bas  kol aşağıda, açık çevrim tork basamağı 0.12 N m (yaklaşık 0.5 mgl), 3 s
%   darbe     90°, r_gs 0.8 kapalı çevrim, tork komutuna 0.2 N m x 5 ms darbe
%   chirp     90°, r_gs 0.8 kapalı çevrim, tork komutuna 0.03 N m log chirp 1 -> 40 Hz, 10 s
%   ref_bas   90°, r_gs 0.8 kapalı çevrim, referansa 2° basamak
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'deney_4a_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 4.1 deney kaynakları, gerçekçi sensör (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('%-9s %3s  %8s %8s %8s %8s  %7s %7s  %6s\n', 'deney', 'mod', 'th0[°]', 'th_ara°', 'phi_ara°', 'f_tep Hz', 'max|u|', 'max|i|', 'süre');

D = struct('ad', {}, 'ac', {}, 'adim', {}, 'rgs', {}, 'T', {}, 'dny', {});
D(1) = struct('ad','serbest',  'ac',0,  'adim',10, 'rgs',0.8, 'T',6,  'dny',struct('yer','acik','A',0,'u0',0));
D(end+1) = struct('ad','serbest30','ac',0,  'adim',30, 'rgs',0.8, 'T',6,  'dny',struct('yer','acik','A',0,'u0',0));
D(end+1) = struct('ad','tork_bas', 'ac',0,  'adim',0,  'rgs',0.8, 'T',5,  'dny',struct('yer','acik','sekil','basamak','A',0.12,'t0',0.5,'Td',3));
D(end+1) = struct('ad','darbe',    'ac',90, 'adim',0,  'rgs',0.8, 'T',3,  'dny',struct('yer','tork','sekil','basamak','A',0.2,'t0',1,'Td',0.005));
D(end+1) = struct('ad','chirp',    'ac',90, 'adim',0,  'rgs',0.8, 'T',11, 'dny',struct('yer','tork','sekil','logchirp','A',0.03,'t0',0.5,'Td',10,'f0',1,'f1',40));
D(end+1) = struct('ad','ref_bas',  'ac',90, 'adim',0,  'rgs',0.8, 'T',3,  'dny',struct('yer','ref','sekil','basamak','A',deg2rad(2),'t0',1));
for k = 1:numel(D)
    for mot = [1 3]
        q = p0;  q.adim = D(k).adim;  q.T = D(k).T;  q.Tan = q.T;  q.dny = D(k).dny;  q.mot = mot;
        q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
        q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;
        kp = D(k).rgs^2*q.Ks/q.KV;
        S = sim_param(q, D(k).ac, kp);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        tic;
        try
            o = sim(in);
        catch err
            yaz('%-9s %3d  HATA: %s\n', D(k).ad, mot, extractBefore([err.message newline], newline));
            continue
        end
        xs = o.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
        t = xs.Time;  th = rad2deg(X(:,3));
        ph = rad2deg(X(:,1));
        t0 = 0;  if isfield(q.dny, 't0'), t0 = q.dny.t0; end
        w = t >= t0;
        us = o.yout{2}.Values;  u = us.Data(us.Time >= t0);      % u ve i kaynak başladıktan sonra
        is = o.yout{3}.Values;  i = is.Data(is.Time >= t0);
        yaz('%-9s %3d  %8.2f %8.2f %8.2f %8.2f  %7.3f %7.3f  %5.1fs\n', D(k).ad, mot, th(1), max(th(w)) - min(th(w)), ...
            max(ph(w)) - min(ph(w)), tepe(t(w), th(w)), max(abs(u(:))), max(abs(i(:))), toc);
    end
end
fclose(fid);
close_system(mdl, 0);
end

function f = tepe(t, y)
% θ'nın baskın frekansı (ortalaması çıkarılmış, Hann pencereli FFT tepesi, 0.5 Hz altı yok sayılır)
y = y(:) - mean(y);  n = numel(y);  dt = t(2) - t(1);
Y = abs(fft(y .* (0.5 - 0.5*cos(2*pi*(0:n-1)'/(n-1)))));  fr = (0:n-1)'/(n*dt);
s = fr > 0.5 & fr < 0.5/dt;
[~, j] = max(Y(s));  fs = fr(s);  f = fs(j);
end
