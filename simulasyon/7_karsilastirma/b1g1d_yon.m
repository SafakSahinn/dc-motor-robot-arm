function b1g1d_yon
% B1-G 1d: temassız koşularda kol, kestiricinin yüzüne göre nerede duruyor? e*s^ > 0: kol inanılan
% yüzün önünde (motor onu itip bırakmış, dayama yetişemiyor); e*s^ < 0: kol yüzün gerisinde.
cd(fileparts(mfilename('fullpath')));
s = load('b1g1d_sonuc.mat');  R = s.R;
fid = fopen('b1g1d_yon_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('Temassız koşular: kol inanılan yüzün önünde (e*s^ > 0) / gerisinde, ort |e| [°]\n');
for m = {'olay', 'olay+yok', 'edilgen'}
    for a = {'sürtünmeli', 'sürtünmesiz'}
        j = strcmp({R.yontem}, m{1}) & strcmp({R.sur}, a{1});
        e = [R(j).e];  yS = [R(j).yuzS];  yK = [R(j).yuzK];
        t = yS == 0;  on = t & e.*yK > 0;
        yaz('%-10s %-11s temassız %4d | önünde %4d (ort |e| %.2f) | gerisinde %4d (ort |e| %.2f)\n', m{1}, a{1}, ...
            nnz(t), nnz(on), mean(abs(e(on))), nnz(t & ~on), mean(abs(e(t & ~on))));
    end
end
fclose(fid);
end
