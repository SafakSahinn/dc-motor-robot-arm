function b2_bedel_ozet
% B2_BEDEL_OZET  b2_bedel.mat özeti -> b2_bedel_log.txt. Her satır 4 açı x 2 yön x 3 tohum = 24 koşu.
% Sütunlar: Irms hareket / tutma [A] (ort), Itepe [A] (en büyük), E hareket [J] (ort), Ecu hareket [J] (ort),
%   Ts05 [s] (medyan; oturmayan NaN sayısı ayrıca), App son 3 s [°] (en büyük), H7 (/24).
cd(fileparts(mfilename('fullpath')));
S = load('b2_bedel.mat');  B = S.B;  G = S.G;
fid = fopen('b2_bedel_log.txt', 'w');  temiz = onCleanup(@() fclose(fid));
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== b2_bedel özeti, %s. motorElk 3 (akım döngüsü 500 Hz), açılar %s°, satır başına 24 koşu.\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM'), mat2str(S.aci));
for k = 1:numel(B)
    b = B(k);
    if k == 1 || ~isequal(b.ortam, B(k-1).ortam) || ~strcmp(b.prof, B(k-1).prof)
        yaz('\n--- %s, muP %.2f | %s ---\n', b.ortam{1}, b.ortam{4}, b.prof);
        yaz('%-11s %-5s | %-8s %-8s | %-6s | %-7s %-7s | %-11s | %-6s | %s\n', 'kontrolcü', 'taup', 'Irms_har', 'Irms_tut', ...
            'Itepe', 'E_har', 'Ecu_har', 'Ts05 (otur.)', 'App', 'H7');
    end
    for tp = G.taup
        j = b.taup == tp;  ts = b.Ts05(j);
        yaz('%-11s %-5.2f | %8.3f %8.3f | %6.2f | %7.3f %7.3f | %5.2f (%2d) | %6.2f | %2d/%d\n', b.ktl, tp, ...
            mean(b.Irms_har(j)), mean(b.Irms_tut(j)), max(b.Itepe(j)), mean(b.E_har(j)), mean(b.Ecu_har(j)), ...
            median(ts, 'omitnan'), nnz(~isnan(ts)), max(b.App(j)), nnz(b.h7(j)), nnz(j));
    end
end
end
