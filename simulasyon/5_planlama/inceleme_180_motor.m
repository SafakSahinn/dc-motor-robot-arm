function inceleme_180_motor
% INCELEME_180_MOTOR  inceleme_180 taramasının aynısı, ama konum hatası motor tarafından
% (p.Pkaynak = 'motor'): kontrolcü kol sensörünü görmez. Karşılaştırma için kol tarafı
% sonuçları inceleme_180_log.txt'de. Ek sütun: kolun son 1 s'deki ortalama kalıcı hatası [°].
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p = secenek_duzenek('D');  wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
p.Pkaynak = 'motor';
rg = 0.10:0.05:0.70;  ac = [0 5 170 175 180];
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p.Ks/p.KV;
fid = fopen('inceleme_180_motor_log.txt', 'w');
fprintf(fid, 'konum kaynağı: motor (phi). boşluk yarı genişliği r = %.2f°\n', rad2deg(p.r));
fprintf(fid, 'sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz\n');
for b = [0.2 1 5]
    p.adim = b;  o = kol_benzetim(p, AC(:)', kp);
    sap = rad2deg(o.th) - AC(:)';
    r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    C = reshape(r.sinif, size(AC));  A = reshape(r.A, size(AC));
    son = o.t > o.t(end) - 1;
    E = reshape(mean(sap(son,:), 1), size(AC));
    fprintf(fid, 'başlangıç %g°: satır r_gs, sütun açı %s\n', b, mat2str(ac));
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f: %s   A[°] %s   e_son[°] %s\n', rg(k), sprintf('%d ', C(k,:)), ...
            sprintf('%.2f ', A(k,:)), sprintf('%+.2f ', E(k,:)));
    end
end
fclose(fid);
end
