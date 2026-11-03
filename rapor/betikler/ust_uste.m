function ust_uste(cikis)
% Referans hücre 5 ve 1 (ideal sensör): kol_benzetim (referans.mat), kol_model.slx, sm_kol_model.slx
% Çıktı: hucre5.csv, hucre1.csv (t, betik, Simulink, Simscape). Ardından: python grafik.py <cikis>
repo = 'C:\Users\safak\Desktop\dc-motor-robot-arm\simulasyon';
kok = fullfile(repo, 'simulink');
addpath(repo, kok, fullfile(repo, '4a_ghaffari'));
cd(cikis);
Simulink.fileGenControl('set', 'CacheFolder', cikis, 'CodeGenFolder', cikis);
L = load(fullfile(kok, 'referans.mat'));  R = L.R;
mdls = {'kol_model', 'sm_kol_model'};
for m = 1:2, load_system(fullfile(kok, [mdls{m} '.slx'])); end
for k = [5 1]
    h = R.hucre(k);  ref = R.kos(k);
    q = R.p;  q.adim = h.bas;
    if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
    if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end
    S = sim_param(q, h.ac, ref.kp);
    M = [];
    for m = 1:2
        in = Simulink.SimulationInput(mdls{m});
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec);
        if m == 2, in = in.setVariable('gecis', 1e-6); end
        o = sim(in);
        xs = o.yout{1}.Values;  ts = xs.Time;  X = squeeze(xs.Data);
        if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
        sec = ts > 0.5*q.dt*q.dec;
        th = rad2deg(X(sec, 3));
        n = numel(ref.t);
        if isempty(M), M = [ref.t(:), rad2deg(ref.th(:))]; end
        nn = min(n, numel(th));
        M = M(1:nn, :);  M(:, end+1) = th(1:nn);
    end
    writematrix(M, fullfile(cikis, sprintf('hucre%d.csv', k)));
    fprintf('hucre %d: %d satir, max|betik-slx| %.2e, max|betik-ssc| %.2e\n', k, size(M,1), ...
        max(abs(M(:,2)-M(:,3))), max(abs(M(:,2)-M(:,4))));
end
end
