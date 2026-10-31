function dogrula_2()
% DOGRULA_2  Simulink modelini (kol_model.slx) referans.mat'taki 5 hücrede kol_benzetim ile karşılaştırır.
% Ölçüt: aynı rejim sınıfı, A ve f farkı %1 altında; ayrıca theta(t) en büyük farkı (ilk 1 s ve tümü).
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
if ~isfile(fullfile(kok, 'kol_model.slx')), kol_model_kur('kol_model'); end
L = load(fullfile(kok, 'referans.mat'));  R = L.R;
mdl = 'kol_model';  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'dogrula_2_log.txt'), 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 2: Simulink - kol_benzetim karşılaştırması (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
for k = 1:numel(R.hucre)
    h = R.hucre(k);  ref = R.kos(k);
    q = R.p;  q.adim = h.bas;
    if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
    if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end
    S = sim_param(q, h.ac, ref.kp);
    in = Simulink.SimulationInput(mdl);
    in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
           .setVariable('T', q.T).setVariable('dec', q.dec);
    tic;  o = sim(in);  sure = toc;
    xs = o.yout{1}.Values;  ts = xs.Time;  X = squeeze(xs.Data);
    if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
    sec = ts > 0.5*q.dt*q.dec;                    % betik t = 0 kaydetmiyor
    th = X(sec, 3);  t = ts(sec);
    n = min(numel(t), numel(ref.t));
    e = abs(rad2deg(th(1:n) - ref.th(1:n)));
    r = rejim_sinifla(t, rad2deg(th) - h.ac, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    i1 = ref.t(1:n) <= 1;
    yaz('hucre %d (%d°, r_gs %.2f, bas %.1f°): sinif %d/%d  A %.3f/%.3f°  f %.2f/%.2f Hz  |dtheta| ilk1s %.2e°, tum %.2e°  (%.1f s)\n', ...
        k, h.ac, h.rgs, h.bas, r.sinif, ref.sinif, r.A, ref.A, r.f, ref.f, max(e(i1)), max(e), sure);
end
fclose(fid);
close_system(mdl, 0);
end
