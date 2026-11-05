function tablo_surtunme
% TABLO_SURTUNME  İlk kazanç tablosunu (tablo_ilk_D.mat) yapışmalı sürtünmeli ikizde sınar
% (Fc 0,04, Fs 0,06 N m), integratör ölü bandı kapalı / 0,25° / 0,5°. Adil karşılaştırma:
% ölü bant planlanan ve sabit kazançta aynı. Ölçülen: en kötü sınıf (3 başlangıç),
% 5° başlangıçtan son 1 s ortalama |sapma| ve 0,5° bandına yerleşme.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
L = load('tablo_ilk_D.mat', 'at', 'rp', 'r_sabit', 'p');
p = L.p;  p.Fc = 0.04;  p.Fs = 0.06;
at = L.at;  na = numel(at);  bas = [0.2 1 5];  ob = [0 0.25 0.5];
fid = fopen('tablo_surtunme_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== tablo_surtunme, %s, D, Fc 0.04 Fs 0.06, sabit r_gs %.3f\n', datestr(now,'yyyy-mm-dd HH:MM'), L.r_sabit);
yaz('sınıf: 0 denge, 1 sönümlü, 3 çevrim, 4 kararsız, 5 düzensiz; A: en kötü salınım genliği [°]; e: son 1 s |sapma| [°]; T: 0,5° bandı [s]\n');
for q = ob
    p.Iolu = deg2rad(q);
    S = zeros(2,na);  E = nan(2,na);  T = nan(2,na);  A = zeros(2,na);
    for c = 1:2
        if c == 1, rr = L.rp; else, rr = L.r_sabit*ones(1,na); end
        kp = rr.^2*p.Ks/p.KV;
        for b = bas
            p.adim = b;  o = kol_benzetim(p, at, kp);
            sap = rad2deg(o.th) - at;
            r = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
            S(c,:) = max(S(c,:), r.sinif);  A(c,:) = max(A(c,:), r.A);
            if b == 5
                E(c,:) = mean(abs(sap(o.t > o.t(end)-1, :)));
                for j = 1:na
                    d = find(abs(sap(:,j)) >= 0.5, 1, 'last');
                    if isempty(d), T(c,j) = 0; elseif d < numel(o.t), T(c,j) = o.t(d+1); end
                end
            end
        end
    end
    yaz('\n--- ölü bant %.2f°\n  açı | plan: sınıf A e T | sabit: sınıf A e T\n', q);
    for j = 1:na
        yaz('  %3d | %d %4.2f %5.2f %5.2f | %d %4.2f %5.2f %5.2f\n', at(j), S(1,j), A(1,j), E(1,j), T(1,j), ...
            S(2,j), A(2,j), E(2,j), T(2,j));
    end
    ic = at >= 20 & at <= 160;
    yaz('  salınımlı (sınıf>=3) açı: plan %d, sabit %d / %d;  T medyanı 20-160°: plan %.2f, sabit %.2f s\n', ...
        sum(S(1,:)>=3), sum(S(2,:)>=3), na, median(T(1,ic),'omitnan'), median(T(2,ic),'omitnan'));
end
fclose(fid);
end
