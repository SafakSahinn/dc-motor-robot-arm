function b1d_ozet
% B1-D özet: koşul x yöntem x başlangıç, H7 toplamı (5 senaryo x 14 x 3 = 210 her sürtünme durumu için).
cd(fileparts(mfilename('fullpath')));
onek = getenv('B1D_ONEK');  if isempty(onek), onek = 'b1d'; end
d = dir([onek '_sonuc_*.mat']);  R = struct([]);
for i = 1:numel(d), s = load(d(i).name);  R = [R s.R]; end %#ok<AGROW>
M = s.M;  K = s.K;  save([onek '_sonuc.mat'], 'R', 'M', 'K');
fid = fopen([onek '_log.txt'], 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== B1-D dayanıklılık, %s. Hücre: H7 / 210 (temel, a1, a2, c, d; 3 tohum). doğru/ters = başlangıç inancı.\n', datestr(now,'yyyy-mm-dd HH:MM'));
yaz('Senaryo ayrıntısı köşeli parantezde (temel a1 a2 c d, her biri /42), yalnız 210 olmayanlarda.\n\n');
etk = {'doğru', 'ters '};
sen = {'temel','a1 darbe','a2 yük','c yaklaşma','d yön değ.'};
for kk = 1:size(K,1)
    for a = unique({R(strcmp({R.kosul}, K{kk,1})).sur}, 'stable')
        yaz('%-20s %-11s\n', K{kk,1}, a{1});
        for m = 1:size(M,1)
            if ~any(strcmp({R.kosul}, K{kk,1}) & strcmp({R.yontem}, M{m,1})), continue; end
            yaz('   %-20s', M{m,1});
            for b = [1 -1]
                j = strcmp({R.kosul}, K{kk,1}) & strcmp({R.sur}, a{1}) & strcmp({R.yontem}, M{m,1}) & [R.bas] == b;
                h = nnz([R(j).h7]);
                yaz(' | %s %3d', etk{(3 - b)/2}, h);
                if h < 210
                    hs = arrayfun(@(sc) nnz([R(j & strcmp({R.sen}, sen{sc})).h7]), 1:5);
                    yaz(' %-18s', mat2str(hs));
                else
                    yaz(' %-18s', '');
                end
            end
            yaz('\n');
        end
    end
end
fclose(fid);
end
