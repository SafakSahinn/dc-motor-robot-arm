function kok_neden_3c
% KOK_NEDEN_3C  3a'daki doğrusal kısım farkının (benzetimde sınır s = 0,93-0,98 n_req) kritik
% kazanca etkisi. Tork sınırsız DF: çevrim koşulu n_req(kp) > n1min(beta). Benzetimin doğrusal
% kısmı DF'ninkinden biraz kararlı: etkin n_req ~ s n_req. Kritik r_gs'nin s ile kayması.
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  p = B.p;
ac = 5:5:175;  rg = 0.30:0.01:1.30;  kp = rg.^2*p.Ks/p.KV;
y = yercekimli_df(p, ac, kp);                  % tork sınırsız, temas sönümlü
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 3c: doğrusal kısım farkının kritik kazanca etkisi (tork sınırsız DF, %s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
k0 = kritik(y.sinif ~= '.');                  % C ya da X (tam temasta kararsız)
for s = [0.98 0.955 0.93]
    % temas sönümlü yolda n_req kararlı çevrimdeki n1; sınır s ile ölçeklenmiş gerekli kazanç
    c = (y.sinif == 'C' & s*y.n_req > y.n1min) | y.sinif == 'X';
    k = kritik(c);
    ok = ~isnan(k0) & ~isnan(k);
    yaz('  s = %.3f: kritik r_gs medyan %+.1f%% kayma (aralık %+.1f / %+.1f%%)\n', s, ...
        100*median(k(ok)./k0(ok) - 1), 100*min(k(ok)./k0(ok) - 1), 100*max(k(ok)./k0(ok) - 1));
end
fclose(fid);

    function k = kritik(c)
        k = nan(1, numel(ac));
        for j = 1:numel(ac)
            i = find(~c(:, j), 1, 'last');
            if isempty(i), k(j) = rg(1); elseif i < numel(rg), k(j) = rg(i+1); end
        end
    end
end
