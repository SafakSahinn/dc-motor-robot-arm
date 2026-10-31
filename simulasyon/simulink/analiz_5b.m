function analiz_5b()
% ANALIZ_5B  tarama_5b sonuçlarından kritik r_gs, genlik eşiğiyle.
% Neden: gerçekçi sensörde (AS5600, 0.088° çözünürlük) nicemleme titreşimi ~0.05° genlikle
% rejim_sinifla'nın A_min = 0.05° eşiğine takılıp sınıf 5 ("düzensiz") olarak sayılabiliyor.
% Bu, gerçek salınım değil; gerçek çevrimler >1° genlikli. Sınır tanımı: sınıf >= 3 VE A > 0.5°.
kok = fileparts(mfilename('fullpath'));
fid = fopen(fullfile(kok, 'tarama_5b_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Analiz 5b: kritik r_gs, sınıf >= 3 ve A > 0.5° (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
for dz = {'ideal', 'gercekci'}
    L = load(fullfile(kok, ['tarama_5b_' dz{1} '.mat']));  B = L.B;
    n = [numel(B.ac), numel(B.rgs), numel(B.bas)];
    yaz('  %s sensör (%s°)\n', dz{1}, num2str(B.ac));
    for v = 1:numel(B.var)
        C = reshape(B.C(v,:), n);  A = reshape(B.A(v,:), n);
        s = any(C >= 3 & A > 0.5, 3);
        k = NaN(1, n(1));
        for i = 1:n(1)
            j = find(s(i,:), 1);
            if ~isempty(j), k(i) = B.rgs(j); end
        end
        yaz('    %-9s %s\n', B.var{v}, num2str(k, '%6.2f'));
    end
end
fclose(fid);
end
