function kok_neden_3e
% KOK_NEDEN_3E  Parça 2 yalnız a ~ 3,2'de ölçtü. DF'nin kararlı çevrimi bu hücrelerde daha küçük
% genlikte (a2). Dişlinin etkin kazancını a2 çevresinde ölçer: tork sınırsız, her hücre kendi DF
% frekansında, farklı sarsıntı genlikleriyle; sarsıntının son 3 periyodu.
% Karşılaştırma: Re N_sim ile n1_DF(a), Im N_sim ile c_s w h_DF(a) / K_s (DF'nin sönüm terimi).
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;  [AC, KP] = meshgrid(B.ac, kp);
dz = yercekimli_df('dz');
hucre = @(a, r) find(AC == a & abs(KP - r^2*p.Ks/p.KV) < 1e-9);
sec = arrayfun(@(a, r) hucre(a, r), [15 30 150], [0.65 0.80 0.80]);
dAs = [0.005 0.01 0.02 0.03 0.05 0.08 0.12];
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 3e: dişlinin etkin kazancı küçük genlikte, tork sınırsız (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
for m = sec
    f = K.y.f(m);  be = p.mgl*sin(deg2rad(AC(m)))/(p.Ks*p.r);
    yaz('  %d°/%.2f: f_DF %.2f Hz, a1 %.2f, a2 %.2f, n_req %.3f\n', AC(m), sqrt(KP(m)*p.KV/p.Ks), f, K.y.a1(m), K.y.a2(m), K.y.n_req(m));
    yaz('     dA     a     b    b_DF  sinüs dışı  Re N_sim  n1_DF   Im N_sim  sönüm_DF\n');
    q = p;  q.Tmax = Inf;  q.adim = 0.2;  q.T = 2;  q.Tan = q.T;  q.df = f;  q.dT = 2;
    for dA = dAs
        q.dA = dA;
        o = kol_benzetim(q, AC(m), KP(m));
        Tp = 1/f;  w = o.t >= q.T - 3*Tp & o.t < q.T;  tt = o.t(w);
        xx = o.delta(w)/p.r;  ty = o.tau_s(w)/(p.Ks*p.r);
        X = @(k, y) 2*mean(y.*exp(-1i*2*pi*k*f*tt));
        X1 = X(1, xx);  a = abs(X1);  b = mean(xx);
        thd = sqrt(sum(arrayfun(@(k) abs(X(k, xx)), 2:10).^2))/a;
        N = X(1, ty)/X1;
        bdf = fzero(@(bb) dz(a, bb) - be, [0, 1 + be + a]);
        [~, n1, h] = dz(a, bdf);
        yaz('    %.3f  %5.2f  %5.2f  %5.2f    %5.2f      %5.3f    %5.3f    %+6.3f    %+6.3f\n', ...
            dA, a, b, bdf, thd, real(N), n1, imag(N), p.cs*2*pi*f*h/p.Ks);
    end
end
fclose(fid);
end
