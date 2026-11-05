function ofset_tablosu
% OFSET_TABLOSU  Motor tarafı geri besleme + açıya göre statik ofset tablosu.
% Kol hedefte dururken dişli torku yerçekimini taşır: tau_s = mgl sin(th).
% Kol boşluğun yerçekimi tarafındaki yüzüne yaslanır, phi - th = s (r + mgl |sin th| / Ks),
% s = sign(sin th). Bu yüzden motor hedefi phi_ref = th_ref + s r + mgl sin(th_ref)/Ks.
% 180°'de (ve 0°'de) sin = 0: hangi yüze yaslanacağı belli değil (s belirsiz).
% Duyarlılık: tabloyu yanlış tanılanmış r ve Ks ile kurunca kalıcı hata ne olur?
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;  p0.adim = 1;
p0.Pkaynak = 'motor';
rg = [0.30 0.50 0.70];  ac = [0 5 10:10:170 175 180];
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p0.Ks/p0.KV;
th = deg2rad(AC(:)');
% durum: ad, r çarpanı, Ks çarpanı, enkoder adımı
durum = {'ofsetsiz', NaN, NaN, 0;  'tam model', 1, 1, 0;  'tam model, 0,27° enkoder', 1, 1, 2*pi/1320;
         'r %20 fazla', 1.2, 1, 0;  'r %20 eksik', 0.8, 1, 0;  'Ks %20 fazla', 1, 1.2, 0;  'Ks %20 eksik', 1, 0.8, 0};
fid = fopen('ofset_tablosu_log.txt', 'w');
fprintf(fid, 'Motor tarafı P-PI, D düzeneği, r = %.2f°, Ks = %.3g N m/rad, mgl/Ks = %.2f°. Başlangıç 1° altta.\n', ...
    rad2deg(p0.r), p0.Ks, rad2deg(p0.mgl/p0.Ks));
fprintf(fid, 'Sütun açı %s; satır r_gs %s. sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz\n', mat2str(ac), mat2str(rg));
fprintf(fid, 'Özet |e| 10–170° ve 0/5/175/180° için ayrı (son 1 s ortalaması).\n');
ic = ac >= 10 & ac <= 170;
for d = 1:size(durum,1)
    p = p0;  p.qM = durum{d,4};
    if isnan(durum{d,2})
        p.ofset = 0;
    else
        p.ofset = sign(sin(th))*p0.r*durum{d,2} + p0.mgl*sin(th)/(p0.Ks*durum{d,3});
    end
    o = kol_benzetim(p, AC(:)', kp);
    sap = rad2deg(o.th) - AC(:)';
    r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    C = reshape(r.sinif, size(AC));
    E = reshape(mean(sap(o.t > o.t(end)-1, :), 1), size(AC));
    Ei = abs(E(:,ic));
    fprintf(fid, '\n== %s: salınımlı %d / %d; 10–170°: |e| ort %.3f° en çok %.3f°\n', durum{d,1}, ...
        nnz(ismember(C,[3 4 5])), numel(C), mean(Ei(:)), max(Ei(:)));
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f sınıf: %s\n', rg(k), sprintf('%d ', C(k,:)));
    end
    for k = 1:numel(rg)
        fprintf(fid, '  %.2f e[°]:  %s\n', rg(k), sprintf('%+.2f ', E(k,:)));
    end
end
fclose(fid);
end
