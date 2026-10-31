function kok_neden_3d
% KOK_NEDEN_3D  1b ve 3b'deki sarsıntı tek frekansta (6,31 Hz) verildi; hücrelerin DF frekansı
% 5-7,2 Hz. Karıştırıcı etken sınaması: her hücre kendi DF frekansında, tork sınırlı ve sınırsız.
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;  [AC, KP] = meshgrid(B.ac, kp);
idx = find(K.uy);
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 3d: her hücre kendi DF frekansında sarsılıyor (%.2f-%.2f Hz), 92 hücre (%s)\n', ...
    min(K.y.f(idx)), max(K.y.f(idx)), datestr(now, 'yyyy-mm-dd HH:MM'));
opt = struct('A_min', 0.05, 'A_max', 30, 'T_at', 2);
for Tm = [p.Tmax Inf]
    for dA = [0.10 0.20]
        q = p;  q.Tmax = Tm;  q.adim = 0.2;  q.T = 8;  q.df = K.y.f(idx)';  q.dT = 1;  q.dA = dA;
        o = kol_benzetim(q, AC(idx)', KP(idx)');
        c = rejim_sinifla(o.t, rad2deg(o.th) - AC(idx)', opt).sinif;
        yaz('  Tmax %-4g, sarsıntı %.2f N m: denge/sönümlü %d, kalıcı çevrim %d, kararsız %d, düzensiz %d\n', ...
            Tm, dA, sum(c <= 1), sum(c == 3), sum(c == 4), sum(c == 5));
        if isinf(Tm) && dA == 0.20, cInf = c; end
    end
end
% tork sınırsızda bile salınım başlamayan hücrelerin açı ve kazanç dağılımı
kal = idx(cInf <= 1);  rg = sqrt(KP(kal)*p.KV/p.Ks);
yaz('  tork sınırsız, 0,20 N m''de de salınımsız %d hücre: açı %s; r_gs %.2f-%.2f\n', numel(kal), ...
    mat2str(unique(AC(kal))'), min(rg), max(rg));
% bu hücreler kritik kazancın ne kadar altında? (benzetimdeki tork sınırsız salınımın başladığı kazanç bilinmiyor;
% DF kritik kazancına göre konum: r_gs / r_gs,kritik,DF)
fclose(fid);
end
