function dogrula_mb(kur)
% DOGRULA_MB  Simscape Multibody 3B modeli (mb_kol_model) ile 1B Simscape modeli (sm_kol_model)
% ve kol_benzetim çapraz kontrolü. Aynı 5 referans hücre (referans.mat), iki düzey: ideal ve gerçekçi sensör
% (dogrula_5a ile aynı ayar). Ölçüt: rejim sınıfı aynı; salınan hücrelerde (genlik >= 0,05°) genlik ve
% frekans farkı %1'in altında (sönmüş hücrelerde dA/df NaN yazılır, yalnız sınıf ve θ(t) farkı).
% Çıktılar: dogrula_mb_log.txt (eklenir), dogrula_mb_izler.mat (θ(t) izleri, grafik için).
% kur = true (varsayılan): mb_kol_model.slx'i mb_model_kur ile yeniden kurar.
if nargin < 1, kur = true; end
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
mb = 'mb_kol_model';  sm = 'sm_kol_model';  gecis = 1e-6;
if kur, mb_model_kur(mb); end
L = load(fullfile(kok, 'referans.mat'));  R = L.R;
load_system(fullfile(kok, [mb '.slx']));  load_system(fullfile(kok, [sm '.slx']));
fid = fopen(fullfile(kok, 'dogrula_mb_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Multibody 3B (mb) - Simscape 1B (sm) - kol_benzetim (kb), %s, geçiş %.0e rad\n', datestr(now, 'yyyy-mm-dd HH:MM'), gecis);
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
iz = struct();  gecti = true;
for duz = {'ideal', 'gercekci'}
    yaz('-- %s sensör\n', duz{1});
    for k = 1:numel(R.hucre)
        h = R.hucre(k);
        q = R.p;  q.adim = h.bas;
        if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
        if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end
        if strcmp(duz{1}, 'gercekci')
            q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;
            q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
            q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*min(q.Tmax, 0.49);
        end
        kp = R.kos(k).kp;
        ref = kol_benzetim(q, h.ac, kp);
        rk = rejim_sinifla(ref.t, rad2deg(ref.th) - h.ac, ops);
        S = sim_param(q, h.ac, kp);
        M = mb_param(S);
        S0 = S;  S0.mgl = 0;                       % yerçekimi Multibody'den; blok_yuk'ta çift sayılmasın
        [t_s, th_s, ~] = kos(sm, S, [], q, gecis);
        [t_m, th_m, sure] = kos(mb, S0, M, q, gecis);
        rs = rejim_sinifla(t_s, rad2deg(th_s) - h.ac, ops);
        rm = rejim_sinifla(t_m, rad2deg(th_m) - h.ac, ops);
        n = min(numel(t_m), numel(t_s));
        e = max(abs(rad2deg(th_m(1:n) - th_s(1:n))));
        % yüzde ölçütü yalnız salınan hücrelerde (genlik >= A_min); sönmüş sinyalin "frekansı" gürültü
        sal = max(rm.A, rs.A) >= ops.A_min;
        [dA, df] = deg_fark(rm, rs);
        if ~sal, dA = NaN;  df = NaN; end
        ok = rm.sinif == rs.sinif && (~sal || (dA < 1 && df < 1));
        gecti = gecti && ok;
        yaz('hucre %d (%d°, r_gs %.2f, bas %.1f°): sinif mb/sm/kb %d/%d/%d  A %.3f/%.3f/%.3f°  f %.2f/%.2f/%.2f Hz  dA %.2f%% df %.2f%%  max|th_mb-th_sm| %.2e°  %s  (%.1f s)\n', ...
            k, h.ac, h.rgs, h.bas, rm.sinif, rs.sinif, rk.sinif, rm.A, rs.A, rk.A, rm.f, rs.f, rk.f, dA, df, e, ...
            ternary(ok, 'GECTI', 'KALDI'), sure);
        iz.(duz{1})(k) = struct('t', t_m(1:n), 'th_mb', th_m(1:n), 'th_sm', th_s(1:n), 'ac', h.ac, ...
                                 'sinif', [rm.sinif rs.sinif rk.sinif], 'A', [rm.A rs.A rk.A], 'f', [rm.f rs.f rk.f]);
    end
end
yaz('Sonuç: %s\n', ternary(gecti, 'tüm hücreler ölçütü sağladı', 'en az bir hücre ölçütü sağlamadı'));
fclose(fid);
save(fullfile(kok, 'dogrula_mb_izler.mat'), 'iz', '-v7');
close_system(mb, 0);  close_system(sm, 0);
end

function [t, th, sure] = kos(mdl, S, M, q, gecis)
in = Simulink.SimulationInput(mdl);
in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt).setVariable('T', q.T) ...
       .setVariable('dec', q.dec).setVariable('gecis', gecis);
if ~isempty(M), in = in.setVariable('M', M); end
tic;  o = sim(in);  sure = toc;
xs = o.yout{1}.Values;  ts = xs.Time;  X = squeeze(xs.Data);
if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
sec = ts > 0.5*q.dt*q.dec;
t = ts(sec);  th = X(sec, 3);
end

function [dA, df] = deg_fark(a, b)
% Bağıl fark [%]; ikisi de sıfırsa (salınım yok) 0. Mutlak taban: genlik 1e-3°, frekans 1e-2 Hz.
dA = 100*abs(a.A - b.A)/max(max(abs(b.A), abs(a.A)), 1e-3);
if max(a.A, b.A) < 1e-3, dA = 0; end
df = 100*abs(a.f - b.f)/max(max(abs(b.f), abs(a.f)), 1e-2);
if max(a.f, b.f) < 1e-2, df = 0; end
end

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
