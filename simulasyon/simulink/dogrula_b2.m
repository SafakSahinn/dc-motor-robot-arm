function dogrula_b2
% DOGRULA_B2  B2: kol_benzetim'in makas dişli modeli (p.onYuk) Simscape ağına karşı
% (sm_model_kur(..., 'ideal', true): Hard Stop ağı + B kolunun torku blok_yuk_onyuk'ta).
% D düzeneği, P-PI (referans.mat ayarı, kol tarafı geri besleme, ideal sensör), r_gs 0,5, sürtünmeli
% (F_c 0,04, F_s 0,06). Hücreler: açı {135 200 225 250 300}° x taup {0,06 0,24 0,48} N m x muP {0 0,5}
% x bozucu {yok, kola 0,05 N m 1 Hz sinüs t >= 3 s (yüz değişimini ve yay bölgesini zorlar)}. Kp = 0,1 Ks.
% Ölçüt (dogrula_elk gibi): rejim sınıfı aynı; salınan hücrelerde genlik ve frekans farkı %1'in altında.
% Ayrıca max |dth| ve son konum farkı. Çıktı: dogrula_b2_log.txt
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
p0.T = 8;  p0.Fc = 0.04;  p0.Fs = 0.06;  p0.adim = 1;
mdl = 'sm_onyuk_model';
sm_model_kur(mdl, 'ideal', true);  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'dogrula_b2_log.txt'), 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== B2 makas dişli: Simscape (sm) - kol_benzetim onYuk (kb), %s. Kp = 0,1 Ks, sürtünmeli, r_gs 0,5\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM'));
gecti = true;  nH = 0;  nG = 0;
for boz = 0:1
  for mu = [0 0.5]
    for tp = [0.06 0.24 0.48]
      for ac = [135 200 225 250 300]
        q = p0;  q.onYuk = 1;  q.taup = tp;  q.Kp = 0.1*q.Ks;  q.muP = mu;
        if boz, q.dA = 0.05;  q.df = 1;  q.d0 = 3;  q.dT0 = 3; end
        kp = 0.5^2*q.Ks/q.KV;
        tic;  o = kol_benzetim(q, ac, kp);  sk = toc;
        S = sim_param(q, ac, kp);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6);
        tic;  so = sim(in);  ss = toc;
        xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
        sec = xs.Time > 0.5*q.dt*q.dec;  t_s = xs.Time(sec);  th_s = X(sec, 3);
        rk = rejim_sinifla(o.t, rad2deg(o.th) - ac, ops);
        rs = rejim_sinifla(t_s, rad2deg(th_s) - ac, ops);
        m = min(numel(t_s), numel(o.t));
        e = max(abs(rad2deg(th_s(1:m) - o.th(1:m))));
        son = rad2deg(mean(th_s(end-100:end)) - mean(o.th(end-100:end)));
        sal = max(rk.A, rs.A) >= ops.A_min;
        dA = 100*abs(rk.A - rs.A)/max(rs.A, eps);  df = 100*abs(rk.f - rs.f)/max(rs.f, eps);
        if ~sal, dA = NaN;  df = NaN; end
        ok = rk.sinif == rs.sinif && (~sal || (dA < 1 && df < 1));
        gecti = gecti && ok;  nH = nH + 1;  nG = nG + ok;
        yaz('bozucu %d muP %.1f taup %.2f %3d°: sinif sm/kb %d/%d  A %.3f/%.3f°  f %.2f/%.2f Hz  dA %.2f%% df %.2f%%  max|dth| %.2e°  son fark %+.1e°  %s  (sm %.0f s, kb %.1f s)\n', ...
            boz, mu, tp, ac, rs.sinif, rk.sinif, rs.A, rk.A, rs.f, rk.f, dA, df, e, son, secim(ok, 'GECTI', 'KALDI'), ss, sk);
      end
    end
  end
end
yaz('Sonuç: %d/%d hücre geçti (%s)\n', nG, nH, secim(gecti, 'hepsi', 'en az biri kaldı'));
fclose(fid);
close_system(mdl, 0);
end

function s = secim(k, a, b)
if k, s = a; else, s = b; end
end
