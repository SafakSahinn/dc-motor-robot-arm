function kok_neden_3f
% KOK_NEDEN_3F  3e: kısmi temasta benzetimdeki etkin sönüm (dişli torkunun birinci harmoniğinin
% sanal kısmı) DF'ninkinin 1,2-2 katı; sapma sinüs olmadığı için yay teriminin harmonikleri de
% temel bileşene faz kayması katıyor. Bu fazla sönüm kritik kazanç hatasının ne kadarını açıklar?
% DF'de temas sönümü c_s bir katsayıyla büyütülür (tam DF: tork sınırı dahil), B1 yeniden hesaplanır.
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  p = B.p;
ac = B.ac;  rf = 0.30:0.01:1.30;  kpf = rf.^2*p.Ks/p.KV;
sal = reshape(any(B.C >= 3, 1), numel(B.rgs), numel(ac));
k_sim = kritik(sal, B.rgs);
ok = ~isnan(k_sim) & abs(sin(deg2rad(ac))) > 1e-9;
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 3f: DF''de temas sönümü büyütülürse kritik kazanç hatası (D, tork sınırlı DF, %s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
for c = [1 1.5 2 3]
    q = p;  q.cs = c*p.cs;
    y = yercekimli_df(q, ac, kpf, 'Tmax', true);
    k = kritik(y.sinif ~= '.', rf);
    e = min(1, abs(k(ok) - k_sim(ok))./k_sim(ok) + isnan(k(ok)));
    s = (k(ok) - k_sim(ok))./k_sim(ok);
    yaz('  c_s x %.1f: B1 medyan %%%.0f (en çok %%%.0f), işaretli medyan %+.0f%% (- : DF düşük)\n', c, 100*median(e), 100*max(e), 100*median(s, 'omitnan'));
end
fclose(fid);
end

function k = kritik(v, r)
% salınımın başladığı ve sonra hep sürdüğü en küçük kazanç (yercekimli_karsilastirma ile aynı)
k = nan(1, size(v, 2));
for j = 1:size(v, 2)
    i = find(~v(:, j), 1, 'last');
    if isempty(i), k(j) = r(1); elseif i < numel(r), k(j) = r(i+1); end
end
end
