function yasa_df
% YASA_DF  Yerçekimli DF, 2026-10-18 boyutsuz haritasının (boyutsuz_harita.m, ideal model, PID)
% 24 düzeneğindeki gamma_sınır(rho) değerlerini öngörüyor mu? (gamma_sınır ≈ 3 rho^3 yasası)
% gamma_sınır: 0°'dan başlayan kesintisiz salınım bandının bittiği gamma (boyutsuz_sinir.m ile aynı).
% Benzetim: boyutsuz_ideal.mat. DF: aynı düzenek, aynı açı ve wc ızgarası; tork sınırlı ve sınırsız.
% Kayıt: yasa_df_log.txt
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok);
S = load(fullfile(kok, 'boyutsuz_ideal.mat'));
bos = S.C == 2 | S.C == 3;
na = numel(S.ac);  nr = numel(S.rsL);  nd = max(S.ID);
gs = nan(nd, nr);  gd = nan(nd, nr);  gt = nan(nd, nr);  Rr = nan(nd, 1);
id = 0;
for m = S.kutle
  for b = S.bosluk
    for K = S.sertlk
      id = id + 1;
      p = parametreler('ideal');
      mRod = 0.020; L = 0.15; mTip = m/1000;
      p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);
      p.r  = deg2rad(b/2);  p.Ks = K;  p.cs = 0.02*sqrt(K/10);
      Jeff = p.JM*p.JL/(p.JM+p.JL);  wr = sqrt(p.Ks/Jeff);  Rr(id) = p.JL/p.JM;
      k = find(S.ID == id);
      B = reshape(bos(k), nr, na);  Gm = reshape(S.G(k), nr, na);
      gs(id,:) = sinir(B, Gm);
      d  = yercekimli_df(p, S.ac, S.rsL*wr, 'Tmax', true);
      dt = yercekimli_df(p, S.ac, S.rsL*wr);
      gd(id,:) = sinir(d.sinif ~= '.', Gm);
      gt(id,:) = sinir(dt.sinif ~= '.', Gm);
      fprintf('%2d/%d bitti\n', id, nd);
    end
  end
end
fid = fopen('yasa_df_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('gamma_sınır: medyan (düzenekler arası max/min), yalnız sonlu ve > 0 olanlar\n');
yaz('%5s | %18s | %18s | %18s | %7s | %s\n', 'rho', 'benzetim', 'DF (Tmax ile)', 'DF (Tmax yok)', '3 rho^3', 'DF/benzetim (düzenek bazında medyan, en çok sapma)');
for i = 1:nr
    [a1, s1] = ozet(gs(:,i));  [a2, s2] = ozet(gd(:,i));  [a3, s3] = ozet(gt(:,i));
    ok = isfinite(gs(:,i)) & gs(:,i) > 0 & isfinite(gd(:,i)) & gd(:,i) > 0;
    q = gd(ok,i)./gs(ok,i);
    if isempty(q), qs = '-'; else, qs = sprintf('%.2f (%.2f-%.2f, %d düzenek)', median(q), min(q), max(q), numel(q)); end
    yaz('%5.2f | %7.3f (%5.1fx)    | %7.3f (%5.1fx)    | %7.3f (%5.1fx)    | %7.4f | %s\n', S.rsL(i), a1, s1, a2, s2, a3, s3, 3*S.rsL(i)^3, qs);
end
% üs: log gamma_sınır = log c + n log rho (rho <= 0,33, sonlu medyanlar)
for t = {'benzetim', gs; 'DF (Tmax ile)', gd; 'DF (Tmax yok)', gt}'
    md = arrayfun(@(i) ozet(t{2}(:,i)), 1:nr);
    u = S.rsL <= 0.34 & isfinite(md) & md > 0;
    c = polyfit(log(S.rsL(u)), log(md(u)), 1);
    yaz('%-14s: gamma_sınır ≈ %.2f rho^%.2f  (rho %.2f-%.2f)\n', t{1}, exp(c(2)), c(1), min(S.rsL(u)), max(S.rsL(u)));
end
yaz('R = J_L/J_M aralığı: %.2f-%.2f\n', min(Rr), max(Rr));
fclose(fid);
save('yasa_df.mat', 'gs', 'gd', 'gt', 'Rr', 'S');
end

function g = sinir(B, Gm)
% her rho satırında 0°'dan başlayan salınım bandının bittiği gamma
g = nan(1, size(B,1));
for i = 1:size(B,1)
    j = find(~B(i,:), 1);
    if isempty(j), g(i) = Inf; elseif j == 1, g(i) = 0; else, g(i) = Gm(i, j-1); end
end
end

function [m, s] = ozet(g)
f = g(isfinite(g) & g > 0);
if isempty(f), m = nan; s = nan; else, m = median(f); s = max(f)/min(f); end
end
