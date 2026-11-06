function surtunme_ofset
% SURTUNME_OFSET  Motor tarafı P-PI + açıya göre ofset tablosu, yapışmalı sürtünmeli ikizde
% (Fc 0,04, Fs 0,06 N m, kol tarafına indirgenmiş). Kol hedefe iki yönden gelir
% (1° alttan / 1° üstten). Her koşuda kaydedilen:
%   sınıf, son 1 s ortalama sapma e, kolun son temas yüzü (delta işareti),
%   beklenen yüz sign(sin th_ref), son 1 s ortalama motor torku u (akımın vekili) ve
%   dişli torku tau_s. "Akım yüzü söylüyor mu": sign(u) == gerçek yüz mü?
% Analitik sınır: durgunken u = tau_s + tau_f, |tau_f| <= Fs. sign(u) yüzü ancak
%   |tau_s| = mgl |sin th| > Fs iken kesin söyler -> belirsiz bant |sin th| < Fs/mgl.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Fc = 0.04;  p0.Fs = 0.06;
rg = [0.30 0.50 0.70];  ac = [0 5 10:10:170 175 180];  yon = [1 -1];   % +1: alttan, -1: üstten
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p0.Ks/p0.KV;
th = deg2rad(AC(:)');  s = sign(sin(th));  s(AC(:)' == 180) = 1;  s(AC(:)' == 0) = 0;
bant = asind(p0.Fs/p0.mgl);
fid = fopen('surtunme_ofset_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== surtunme_ofset, %s, D, motor tarafı P-PI + ofset, Fc %.2f Fs %.2f N m, mgl %.3f N m, r %.2f°\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), p0.Fc, p0.Fs, p0.mgl, rad2deg(p0.r));
yaz('Analitik belirsiz bant (sign(u) yüzü kesin söylemez): |sin th| < Fs/mgl = %.3f -> 0° ve 180° çevresinde ±%.1f°\n', ...
    p0.Fs/p0.mgl, bant);
yaz('Açı %s; r_gs %s. Sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz\n', mat2str(ac), mat2str(rg));
enk = {'ideal enkoder', 0; '0,27° enkoder', 2*pi/1320};
for q = 1:size(enk,1)
  for y = yon
    p = p0;  p.qM = enk{q,2};  p.adim = y;
    p.ofset = s*p0.r + p0.mgl*sin(th)/p0.Ks;
    o = kol_benzetim(p, AC(:)', kp);
    sap = rad2deg(o.th) - AC(:)';
    r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    son = o.t > o.t(end)-1;
    E  = mean(sap(son,:), 1);
    dl = mean(o.delta(son,:), 1);   yuz = sign(dl).*(abs(dl) >= p0.r*0.999);
    U  = mean(o.u(son,:), 1);       TS = mean(o.tau_s(son,:), 1);
    akim_dogru = sign(U) == yuz;
    yaz('\n== %s, kol %s geliyor: salınımlı %d/%d; 10–170° |e| en çok %.3f°\n', enk{q,1}, ...
        ternary(y>0,'alttan','üstten'), nnz(ismember(r.sinif,[3 4 5])), numel(r.sinif), ...
        max(abs(E(AC(:)'>=10 & AC(:)'<=170))));
    yaz('  açı | r_gs=0,50: sınıf  e[°]  yüz(beklenen)  u[N m]  tau_s[N m]  sign(u) yüzü söylüyor mu\n');
    for j = find(RG(:)' == 0.50)
        yaz('  %3d |  %d  %+6.2f  %+d(%+d)  %+7.4f  %+7.4f  %s\n', AC(j), r.sinif(j), E(j), yuz(j), s(j), ...
            U(j), TS(j), ternary(akim_dogru(j),'evet','HAYIR'));
    end
    yanlis = yuz ~= s & AC(:)' > 0;
    yaz('  yanlış yüz (tüm r_gs, 0° hariç): %s\n', mat2str(unique(AC(yanlis))));
  end
end
fclose(fid);
end
function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end
