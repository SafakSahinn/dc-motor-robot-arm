function dogrula_b2_dt
% DOGRULA_B2_DT  dogrula_b2'de ayrışan hücrelerin adım boyutu yakınsaması: kol_benzetim ve Simscape
% dt, dt/2, dt/4 ile; her ikisinin genliği, frekansı ve son konumu. Hücre: muP 0, taup 0,06, 200°
% (yumuşak yay bölgesi) ve kontrol için 135°. Çıktı: dogrula_b2_log.txt'ye eklenir.
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
p0.T = 8;  p0.Fc = 0.04;  p0.Fs = 0.06;  p0.adim = 1;
mdl = 'sm_onyuk_model';
if ~isfile(fullfile(kok, [mdl '.slx'])), sm_model_kur(mdl, 'ideal', true); end
load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'dogrula_b2_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n--- adım boyutu yakınsaması (Ts sabit, dec dt ile ölçeklenir) ---\n');
for ac = [200 135]
  for k = [1 2 4]
    q = p0;  q.onYuk = 1;  q.taup = 0.06;  q.Kp = 0.1*q.Ks;  q.muP = 0;
    q.dt = p0.dt/k;  q.dec = p0.dec*k;  if q.Ts < q.dt*k, q.Ts = p0.Ts; end
    kp = 0.5^2*q.Ks/q.KV;
    o = kol_benzetim(q, ac, kp);
    S = sim_param(q, ac, kp);
    in = Simulink.SimulationInput(mdl);
    in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
           .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6);
    so = sim(in);
    xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
    sec = xs.Time > 0.5*q.dt*q.dec;  t_s = xs.Time(sec);  th_s = X(sec, 3);
    rk = rejim_sinifla(o.t, rad2deg(o.th) - ac, ops);  rs = rejim_sinifla(t_s, rad2deg(th_s) - ac, ops);
    m = min(numel(t_s), numel(o.t));
    yaz('%3d° dt/%d: kb sinif %d A %.3f° f %.2f Hz son %+.3f° | sm sinif %d A %.3f° f %.2f Hz son %+.3f° | max|dth| %.2e°\n', ...
        ac, k, rk.sinif, rk.A, rk.f, rad2deg(mean(o.th(end-100:end))) - ac, rs.sinif, rs.A, rs.f, ...
        rad2deg(mean(th_s(end-100:end))) - ac, max(abs(rad2deg(th_s(1:m) - o.th(1:m)))));
  end
end
fclose(fid);
close_system(mdl, 0);
end
