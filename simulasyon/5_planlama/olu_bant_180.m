function olu_bant_180
% OLU_BANT_180  180° önlemi + sürtünme katmanı: integratör ölü bandı / sıfırlama.
% Soru: tam 180°'de (yerçekimi ön yükü yok) r_gs >= 0,20'de çıkan salınım, integratör
% ölü bandı ya da sıfırlamayla ortadan kalkıyor mu; salınımsız kazanç penceresi genişliyor mu?
% Adil karşılaştırma: katman her kazançta (tablo ve sabit taban dahil) aynı şekilde açık.
% Sürtünme: 'yok' (Fc = Fs = 0) ve 'var' (Fc 0,04, Fs 0,06 N m; yapışma > Coulomb).
% Açılar 0 / 90 / 180°, r_gs 0,10:0,05:0,70, üç başlangıç sapması (0,2 / 1 / 5°), en kötü sınıf.
% Ölçülen ayrıca: son 1 s ortalama |sapma| (ölü bandın bedeli: kalıcı hata) ve 5°'den yerleşme.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
rg = 0.10:0.05:0.70;  ac = [0 90 180];
[AC, RG] = meshgrid(ac, rg);  kp = RG(:)'.^2*p0.Ks/p0.KV;
kat = {'yok', 0, false; 'olu 0.25', 0.25, false; 'olu 0.5', 0.5, false; ...
       'olu 1.0', 1.0, false; 'sifirla', 0, true};
bas = [0.2 1 5];
fid = fopen('olu_bant_180_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== olu_bant_180, %s, düzenek D, P-PI\n', datestr(now,'yyyy-mm-dd HH:MM'));
yaz('sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz (üç başlangıcın en kötüsü)\n');
yaz('e_son: son 1 s ortalama |sapma| [°] (5° başlangıç), T: 0,25° bandına yerleşme [s]\n');
R = struct();
for s = 1:2
    p = p0;
    if s == 2, p.Fc = 0.04;  p.Fs = 0.06; end
    for k = 1:size(kat,1)
        p.Iolu = deg2rad(kat{k,2});  p.Isifirla = kat{k,3};
        S = zeros(numel(rg), numel(ac));  E = nan(size(S));  T = nan(size(S));
        for b = bas
            p.adim = b;  o = kol_benzetim(p, AC(:)', kp);
            sap = rad2deg(o.th) - AC(:)';
            r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
            S = max(S, reshape(r.sinif, size(AC)));
            if b == 5
                E = reshape(mean(abs(sap(o.t > o.t(end)-1, :))), size(AC));
                T = reshape(yerlesme(o.t, sap, 0.25), size(AC));
            end
        end
        R(s,k).S = S;  R(s,k).E = E;  R(s,k).T = T;
        yaz('\n--- sürtünme %s, katman %s (ölü bant °)\n', ternary(s==2,'var','yok'), kat{k,1});
        yaz('  r_gs |  sınıf 0/90/180 | e_son[°] 0/90/180   | T[s] 0/90/180\n');
        for i = 1:numel(rg)
            yaz('  %.2f |  %d %d %d  | %5.2f %5.2f %5.2f | %5.2f %5.2f %5.2f\n', rg(i), S(i,:), E(i,:), T(i,:));
        end
        ok = S <= 1;
        yaz('  salınımsız r_gs sayısı (0/90/180): %d %d %d / %d\n', sum(ok), numel(rg));
    end
end
save('olu_bant_180.mat', 'R', 'kat', 'rg', 'ac', 'bas', 'p0');
fclose(fid);
end

function y = ternary(c, a, b)
if c, y = a; else, y = b; end
end

function ty = yerlesme(t, sap, bant)
ty = nan(1, size(sap,2));
for j = 1:size(sap,2)
    d = find(abs(sap(:,j)) >= bant, 1, 'last');
    if isempty(d), ty(j) = 0; elseif d < numel(t), ty(j) = t(d+1); end
end
end
