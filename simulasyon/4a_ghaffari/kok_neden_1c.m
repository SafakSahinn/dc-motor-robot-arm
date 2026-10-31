function kok_neden_1c
% KOK_NEDEN_1C  Parça 1b'nin geçerliliği: sarsıntı sırasında dişli sapmasının genliği (A/r),
% DF'nin eşik (a1) ve kararlı çevrim (a2) genliklerini aştı mı? Aşmadıysa 1b sonuç vermez.
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;
[AC, KP] = meshgrid(B.ac, kp);
idx = find(K.uy);
p.adim = 0.2;  p.T = 3;  p.df = median(K.y.f(K.uy));  p.dT = 1;
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('  1c: sarsıntı sırasında (0,5-1 s) dişli sapması genliği A/r ile DF eşikleri\n');
for dA = [0.10 0.20]
    p.dA = dA;
    o = kol_benzetim(p, AC(idx)', KP(idx)');
    w = o.t >= 0.5 & o.t < 1;
    d = o.delta(w, :);
    a = (max(d) - min(d))/2/p.r;                       % sapmanın salınım genliği, r ile
    a1 = K.y.a1(idx)';  a2 = K.y.a2(idx)';
    yaz('   dA %.2f: A/r medyan %.2f (aralık %.2f-%.2f); a1''i aşan %d/%d, a2''yi aşan %d/%d (a2 medyan %.2f)\n', ...
        dA, median(a), min(a), max(a), sum(a > a1), numel(a), sum(a > a2), numel(a), median(a2));
end
fclose(fid);
end
