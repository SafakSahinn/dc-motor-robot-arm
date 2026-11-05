function konum_kaynagi_karsilastir
% KONUM_KAYNAGI_KARSILASTIR  Konum hatası kol açısından mı (eski) motor açısından mı alınmalı?
% 0–180° × r_gs 0,20–0,70 × başlangıç 1°, P–PI (secenek_duzenek 'D').
% Üç durum: kol (ideal), motor (ideal), motor (nicemli, 1320 sayım/tur = 0,27°).
% Her hücre: sınıf (0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz) ve kolun kalıcı hatası.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;  p0.adim = 1;
rg = 0.20:0.10:0.70;  ac = 0:10:180;
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p0.Ks/p0.KV;
durum = {'kol (ideal)', 'kol', 0;  'motor (ideal)', 'motor', 0;  'motor (0,27°)', 'motor', 2*pi/1320};
fid = fopen('konum_kaynagi_karsilastir_log.txt', 'w');
fprintf(fid, 'r = %.2f° (yarı boşluk). Satır r_gs, sütun açı %s\n', rad2deg(p0.r), mat2str(ac));
for d = 1:size(durum,1)
    p = p0;  p.Pkaynak = durum{d,2};  p.qM = durum{d,3};
    o = kol_benzetim(p, AC(:)', kp);
    sap = rad2deg(o.th) - AC(:)';
    r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    C = reshape(r.sinif, size(AC));  A = reshape(r.A, size(AC));
    E = reshape(mean(sap(o.t > o.t(end)-1, :), 1), size(AC));
    sal = ismember(C, [3 4 5]);
    fprintf(fid, '\n== %s: salınımlı hücre %d / %d, |e_son| ort %.2f° en çok %.2f°\n', durum{d,1}, ...
        nnz(sal), numel(C), mean(abs(E(:))), max(abs(E(:))));
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f sınıf: %s\n', rg(k), sprintf('%d ', C(k,:)));
    end
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f e_son: %s\n', rg(k), sprintf('%+.1f ', E(k,:)));
    end
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f A[°]:  %s\n', rg(k), sprintf('%.2f ', A(k,:)));
    end
end
fclose(fid);
end
