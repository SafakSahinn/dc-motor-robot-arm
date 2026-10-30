function kopru_7b_R
% KOPRU_7B_R  Eylemsizlik oranı R = JL/JM rejimi değiştiriyor mu? (yerçekimsiz, P-PI, hız döngüsü 1 wa,
% 2r = 3°, başlangıç 1°). Üç düzenek: (a) dengeli liste (N = 30, R = 0,17); (b) aynı motor + dengelenmiş
% ek eylemsizlik (JL = 2 JM, R = 2; yerçekimi torku eklemez); (c) daha düşük dişli oranı N = 10 (R = 1,5).
addpath(fileparts(fileparts(mfilename('fullpath'))));
rgs = [0.3 0.5 0.7 0.9 1.0 1.1 1.3 1.5];
ad = {'denge','sönümlü','zorlanmış','ÇEVRİM','KARARSIZ','düzensiz'};
fid = fopen('kopru_7b_R_log.txt','w');
for durum = 1:3
    p = parametreler('ideal');  p.N = 30;  p.JM = 4e-6*p.N^2;  p.Tmax = Inf;
    p.JL = 0.020*0.15^2/3 + 0.020*0.15^2;  p.mgl = 0;  p.r = deg2rad(1.5);
    switch durum
        case 2, p.JL = 2*p.JM;          ad_ = 'ek dengeli eylemsizlik, JL = 2 JM';
        case 3, p.N = 10;  p.JM = 4e-6*p.N^2;  ad_ = 'N = 10';
        otherwise, ad_ = 'dengeli liste, N = 30';
    end
    wa = sqrt(p.Ks/p.JL);
    p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
    p.dt = 1e-4;  p.Ts = p.dt;  p.T = 6;  p.Tan = p.T;  p.dec = 5;  p.adim = 1;
    kp = rgs.^2*p.Ks/p.KV;
    o = kol_benzetim(p, zeros(size(kp)), kp);
    r = rejim_sinifla(o.t, rad2deg(o.th), struct('A_min',0.05,'A_max',30,'T_at',0.3));
    g = struct('Jm',p.JM,'Jle',p.JL,'kse',p.Ks,'cm',p.bM,'cle',p.bL,'Ti',1/p.KI,'wa',wa,'fa',wa/2/pi,'delta',p.r);
    d = ghaffari_df(g, kp, p.KV*ones(size(kp)));
    temas = mean(abs(o.delta(o.t > 3,:)) > p.r);
    yaz(fid, '%s: R = %.2f, f_a = %.1f Hz\n', ad_, p.JL/p.JM, wa/2/pi);
    yaz(fid, '%6s %-10s %8s %8s %8s %7s\n', 'r_gs', 'sınıf', 'f sim', 'f DF', 'sim/DF', 'temas');
    for j = 1:numel(rgs)
        yaz(fid, '%6.2f %-10s %8.2f %8.2f %8.2f %7.2f\n', rgs(j), ad{r.sinif(j)+1}, r.f(j), d.f_df(j), r.f(j)/d.f_df(j), temas(j));
    end
    yaz(fid, '\n');
end
fclose(fid);
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
