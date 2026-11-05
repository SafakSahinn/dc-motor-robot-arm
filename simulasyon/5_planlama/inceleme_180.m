function inceleme_180
% INCELEME_180  0° ve 180° civarında (yerçekimi ön yükü yok ya da çok küçük) kazanç taraması:
% hangi r_gs'de salınım yok? tablo_ilk'te 180°'de taban kazançta (0,24) düzensiz salınım çıktı.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p = secenek_duzenek('D');  wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
rg = 0.10:0.05:0.70;  ac = [0 5 170 175 180];
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p.Ks/p.KV;
fid = fopen('inceleme_180_log.txt', 'w');
fprintf(fid, 'sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz\n');
for b = [0.2 1 5]
    p.adim = b;  o = kol_benzetim(p, AC(:)', kp);
    sap = rad2deg(o.th) - AC(:)';
    r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    C = reshape(r.sinif, size(AC));  A = reshape(r.A, size(AC));
    fprintf(fid, 'başlangıç %g°: satır r_gs, sütun açı %s\n', b, mat2str(ac));
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f: %s   A[°] %s\n', rg(k), sprintf('%d ', C(k,:)), sprintf('%.2f ', A(k,:)));
    end
end
fclose(fid);
end
