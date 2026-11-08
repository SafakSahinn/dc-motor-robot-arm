function dogrula_elk
% DOGRULA_ELK  İş sırası 5c: kol_benzetim'in elektrik modu (p.motorElk) Simscape elektrik modeline
% (sm_motor_model, sm_model_kur(..., 'elektrik')) karşı. D düzeneği, P-PI, tarama_5b ile aynı ayar.
% Hücreler: 30/60/90° x r_gs 0,9 / 1,3 x başlangıç sapması 1°, iki sensör düzeyi (ideal, gerçekçi), mod 1, 2, 3.
% Ölçüt (dogrula_mb gibi): rejim sınıfı aynı; salınan hücrelerde (genlik >= 0,05°) genlik ve frekans farkı
% %1'in altında. Çıktı: dogrula_elk_log.txt (eklenir).
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'dogrula_elk_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Elektrik modu: Simscape (sm) - kol_benzetim motorElk (kb), %s\n', datestr(now, 'yyyy-mm-dd HH:MM'));
gecti = true;
for duz = {'ideal', 'gercekci'}
    yaz('-- %s sensör\n', duz{1});
    for mot = 1:3
        for ac = [30 60 90]
            for rgs = [0.9 1.3]
                q = p0;  q.adim = 1;
                if strcmp(duz{1}, 'gercekci')
                    q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;
                    q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
                    q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;
                end
                kp = rgs^2*q.Ks/q.KV;
                qk = q;  qk.motorElk = mot;
                tic;  o = kol_benzetim(qk, ac, kp);  sk = toc;
                q.mot = mot;  S = sim_param(q, ac, kp);
                in = Simulink.SimulationInput(mdl);
                in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
                       .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
                       .setVariable('Tsur', S.Tsur);
                tic;  so = sim(in);  ss = toc;
                xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
                sec = xs.Time > 0.5*q.dt*q.dec;  t_s = xs.Time(sec);  th_s = X(sec, 3);
                rk = rejim_sinifla(o.t, rad2deg(o.th) - ac, ops);
                rs = rejim_sinifla(t_s, rad2deg(th_s) - ac, ops);
                m = min(numel(t_s), numel(o.t));
                e = max(abs(rad2deg(th_s(1:m) - o.th(1:m))));
                sal = max(rk.A, rs.A) >= ops.A_min;
                dA = 100*abs(rk.A - rs.A)/max(rs.A, eps);  df = 100*abs(rk.f - rs.f)/max(rs.f, eps);
                if ~sal, dA = NaN;  df = NaN; end
                ok = rk.sinif == rs.sinif && (~sal || (dA < 1 && df < 1));
                gecti = gecti && ok;
                yaz('mod %d %2d° r_gs %.1f: sinif sm/kb %d/%d  A %.3f/%.3f°  f %.2f/%.2f Hz  dA %.2f%% df %.2f%%  max|dth| %.2e°  i_tepe %.2f A  V doyum %.1f%%  %s  (sm %.0f s, kb %.1f s)\n', ...
                    mot, ac, rgs, rs.sinif, rk.sinif, rs.A, rk.A, rs.f, rk.f, dA, df, e, o.iTepe, 100*o.Vdoy, ...
                    secim(ok, 'GECTI', 'KALDI'), ss, sk);
            end
        end
    end
end
yaz('Sonuç: %s\n\n', secim(gecti, 'tüm hücreler ölçütü sağladı', 'en az bir hücre ölçütü sağlamadı'));
fclose(fid);
close_system(mdl, 0);
end

function s = secim(k, a, b)
if k, s = a; else, s = b; end
end
