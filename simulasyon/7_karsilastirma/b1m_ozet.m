function b1m_ozet
% B1-M özet: koşul x tesis x yöntem x başlangıç inancı, H7 / 210. Parça dosyalarını birleştirir.
% Ek: denetim satırında yüz ölçütü (dişli torku) ile eski delta ölçütünün aynı sonucu verdiği kontrolü,
% ve iyi (konum ölçütü) ama yanlış yüzde kalan koşu sayısı.
cd(fileparts(mfilename('fullpath')));
onek = getenv('B1M_ONEK');  if isempty(onek), onek = 'b1m'; end
d = dir([onek '_sonuc_*.mat']);  R = struct([]);
for i = 1:numel(d), s = load(d(i).name);  R = [R s.R]; end %#ok<AGROW>
M = s.M;  K = s.K;  save([onek '_sonuc.mat'], 'R', 'M', 'K');
fid = fopen([onek '_log.txt'], 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== B1-M model dışı etkiler, %s. Hücre: H7 / 210 (temel, a1, a2, c, d; 3 tohum, tohuma bağlı faz).\n', datestr(now,'yyyy-mm-dd HH:MM'));
yaz('doğru/ters = başlangıç inancı. Köşeli parantez: senaryo ayrıntısı (temel a1 a2 c d, her biri /42), yalnız 210 olmayanlarda.\n');
yaz('Yüz ölçütü dişli torkunun işareti; d: eski delta ölçütüyle farklıysa onun sonucu.\n\n');
etk = {'doğru', 'ters '};
sen = {'temel','a1 darbe','a2 yük','c yaklaşma','d yön değ.'};
for kk = 1:size(K,1)
    for a = unique({R(strcmp({R.kosul}, K{kk,1})).sur}, 'stable')
        yaz('%-22s %-11s\n', K{kk,1}, a{1});
        for m = 1:size(M,1)
            yaz('   %-20s', M{m,1});
            for b = [1 -1]
                j = strcmp({R.kosul}, K{kk,1}) & strcmp({R.sur}, a{1}) & strcmp({R.yontem}, M{m,1}) & [R.bas] == b;
                h = nnz([R(j).h7]);  hd = nnz([R(j).h7d]);
                yaz(' | %s %3d', etk{(3 - b)/2}, h);
                ek = '';
                if h < 210, ek = mat2str(arrayfun(@(sc) nnz([R(j & strcmp({R.sen}, sen{sc})).h7]), 1:5)); end
                if hd ~= h, ek = sprintf('%s d%d', ek, hd); end
                yaz(' %-22s', ek);
            end
            yaz('\n');
        end
    end
end
% olay+yok eşik tablosu: her koşul için en kötü (tesis, başlangıç) değeri
yaz('\n--- olay+yok ve momentum: koşul başına en kötü hücre (tesis x başlangıç) ---\n');
for kk = 1:size(K,1)
    yaz('%-22s', K{kk,1});
    for mm = {'olay+yok', 'momentum L100 e0.06', 'lenze 0.03'}
        en = 210;
        for a = unique({R(strcmp({R.kosul}, K{kk,1})).sur})
            for b = [1 -1]
                j = strcmp({R.kosul}, K{kk,1}) & strcmp({R.sur}, a{1}) & strcmp({R.yontem}, mm{1}) & [R.bas] == b;
                en = min(en, nnz([R(j).h7]));
            end
        end
        yaz(' | %s %3d', mm{1}(1:min(8,end)), en);
    end
    yaz('\n');
end
fclose(fid);
end
