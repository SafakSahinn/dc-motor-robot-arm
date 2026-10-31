function dogrula_5a(gecis)
% DOGRULA_5A  Simscape mekanik modeli (sm_kol_model.slx) ile kol_benzetim çapraz kontrolü.
% Aynı 5 hücre, iki düzey: ideal sensör ve gerçekçi sensör (dogrula_3 ayarı).
% gecis: Hard Stop geçiş bölgesi [rad] (varsayılan 1e-6; r = 2.6e-2 rad).
if nargin < 1, gecis = 1e-6; end
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
mdl = 'sm_kol_model';
sm_model_kur(mdl);
L = load(fullfile(kok, 'referans.mat'));  R = L.R;
load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'dogrula_5a_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 5a: Simscape mekanik model - kol_benzetim (%s), geçiş %.0e rad\n', datestr(now, 'yyyy-mm-dd HH:MM'), gecis);
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
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
        rr = rejim_sinifla(ref.t, rad2deg(ref.th) - h.ac, ops);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', sim_param(q, h.ac, kp)).setVariable('Ts', q.Ts) ...
               .setVariable('dt', q.dt).setVariable('T', q.T).setVariable('dec', q.dec) ...
               .setVariable('gecis', gecis);
        tic;  o = sim(in);  sure = toc;
        xs = o.yout{1}.Values;  ts = xs.Time;  X = squeeze(xs.Data);
        if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
        sec = ts > 0.5*q.dt*q.dec;
        th = X(sec, 3);  t = ts(sec);
        n = min(numel(t), numel(ref.t));
        e = abs(rad2deg(th(1:n) - ref.th(1:n)));
        r = rejim_sinifla(t, rad2deg(th) - h.ac, ops);
        i1 = ref.t(1:n) <= 1;
        yaz('hucre %d (%d°, r_gs %.2f, bas %.1f°): sinif %d/%d  A %.3f/%.3f°  f %.2f/%.2f Hz  |dtheta| ilk1s %.2e°, tum %.2e°  (%.1f s)\n', ...
            k, h.ac, h.rgs, h.bas, r.sinif, rr.sinif, r.A, rr.A, r.f, rr.f, max(e(i1)), max(e), sure);
    end
end
fclose(fid);
close_system(mdl, 0);
end
