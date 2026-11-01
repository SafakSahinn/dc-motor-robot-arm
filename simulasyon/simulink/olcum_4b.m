function olcum_4b()
% OLCUM_4B  Adım 4.2: sanal ölçüm. Firmware kaydı (olc_out, Ts = 1 ms) gerçek değerlerle karşılaştırılır.
% sm_motor_model, D düzeneği, P-PI, gerçekçi sensör, hız kestirimi gözlemci (firmware kararı).
% IPROPI -> ESP32 ADC: DRV8874 A_IPROPI ~455 uA/A, R_IPROPI 3.6 kOhm (2 A sınırı 3.3 V'a) -> 1.64 V/A;
% ADC 12 bit, ~3.1 V aralık -> basamak 0.46 mA; gürültü std ~3 LSB = 1.4 mA (ortalama almadan).
% Not: modelin akımı kol tarafına indirgenmiş eşdeğer motorun akımı (sim_param); ölçek gerçek motordan
% ~1.6 kat farklı, gürültü/basamak oranı için önemsiz.
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'olcum_4b_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 4.2 sanal ölçüm, gerçekçi sensör, gözlemci (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('%-8s %3s  %9s %9s %9s %9s %9s  %9s\n', 'deney', 'mod', 'thL rms°', 'thL max°', 'phi max°', ...
    'v rms', 'i rms mA', 'u-Km i');
D = struct('ad', {'chirp', 'darbe', 'serbest30'}, 'ac', {90, 90, 0}, 'adim', {0, 0, 30}, 'T', {11, 3, 6}, ...
           'dny', {struct('yer','tork','sekil','logchirp','A',0.03,'t0',0.5,'Td',10,'f0',1,'f1',40), ...
                   struct('yer','tork','sekil','basamak','A',0.2,'t0',1,'Td',0.005), ...
                   struct('yer','acik','A',0,'u0',0)});
for k = 1:numel(D)
    for mot = [1 3]
        q = p0;  q.adim = D(k).adim;  q.T = D(k).T;  q.Tan = q.T;  q.dny = D(k).dny;  q.mot = mot;
        q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
        q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.hiz = 'gozlemci';
        q.qI = 0.46e-3;  q.iGur = 1.4e-3;  q.iSeed = 10*k + mot;
        S = sim_param(q, D(k).ac, 0.8^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', 1).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        K = olcum_oku(sim(in));
        % gerçek değerler kayıt anlarına (gerçek kayıt 2 ms'de, ölçüm 1 ms'de; doğrusal aradeğerleme)
        g = @(c) interp1(K.g.t, K.g.x(:,c), K.t, 'linear', 'extrap');
        thg = g(3);  phig = g(1);  wg = g(2);  ig = interp1(K.g.ti, K.g.i, K.t, 'linear', 'extrap');
        s = K.t > 0.1;                                      % başlangıç geçişi dışarıda
        ethL = rad2deg(K.thL(s) - thg(s));  ephi = rad2deg(K.phi(s) - phig(s));
        ev = K.v(s) - wg(s);  ei = K.i(s) - ig(s);
        tork = NaN;  if mot == 3, tork = rms(K.u(s) - S.Km*K.i(s)); end   % akım döngüsü torku izliyor mu
        yaz('%-8s %3d  %9.3f %9.3f %9.3f %9.3f %9.2f  %9.4f\n', D(k).ad, mot, rms(ethL), max(abs(ethL)), ...
            max(abs(ephi)), rms(ev), 1e3*rms(ei), tork);
        if k == 1 && mot == 3, save(fullfile(kok, 'olcum_4b_ornek.mat'), 'K', 'q'); end
    end
end
fclose(fid);
close_system(mdl, 0);
end
