function b1g_ozet
% B1-G özet: koşul x tesis x yöntem x başlangıç inancı, H7 / 120 (5 senaryo x 8 hedef x 3 tohum).
% Parça dosyalarını birleştirir. Ortam B1G_ONEK (varsayılan b1g1). Ek sütunlar (iki başlangıç birlikte, /240):
%   temassız : son 1 s'de gerçek dişli torku hiç yok (kol boşlukta serbest), yuzS = 0
%   yanlış yüz: temas var, kestiricinin yüzü yanlış
%   konum    : temas var, yüz doğru, konum ölçütü geçmiyor
%   ort|e|   : başarısızların ortalama |e| [°]
cd(fileparts(mfilename('fullpath')));
onek = getenv('B1G_ONEK');  if isempty(onek), onek = 'b1g1'; end
d = dir([onek '_sonuc_*.mat']);  R = struct([]);
for i = 1:numel(d), s = load(d(i).name);  R = [R s.R]; end %#ok<AGROW>
if isempty(R), s = load([onek '_sonuc.mat']);  R = s.R; end
M = s.M;  K = s.K;  save([onek '_sonuc.mat'], 'R', 'M', 'K');
fid = fopen([onek '_log.txt'], 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
nH = numel(R(1).e);  N1 = 5*nH*3;
yaz('=== B1-G (%s), %s. Hücre: H7 / %d (5 senaryo x %d hedef x 3 tohum).\n', onek, datestr(now,'yyyy-mm-dd HH:MM'), N1, nH);
yaz('Hedefler: %s. Köşeli parantez: senaryo ayrıntısı (temel a1 a2 c d, her biri /%d), yalnız tam olmayanlarda.\n', mat2str(R(1).hedef(1:nH/2)), nH*3);
yaz('Yüz ölçütü: kestiricinin son yüzü = gerçek son dişli torku işareti (temassız: H7 değil).\n\n');
etk = {'doğru', 'ters '};
sen = {'temel','a1 darbe','a2 yük','c yaklaşma','d yön değ.'};
for kk = 1:size(K,1)
    for a = unique({R(strcmp({R.kosul}, K{kk,1})).sur}, 'stable')
        yaz('%-22s %-11s %38s | %8s %10s %6s %7s\n', K{kk,1}, a{1}, '', 'temassız', 'yanlış yüz', 'konum', 'ort|e|');
        for m = 1:size(M,1)
            yaz('   %-20s', M{m,1});
            jm = strcmp({R.kosul}, K{kk,1}) & strcmp({R.sur}, a{1}) & strcmp({R.yontem}, M{m,1});
            for b = [1 -1]
                j = jm & [R.bas] == b;
                h = nnz([R(j).h7]);  ek = '';
                if h < N1, ek = mat2str(arrayfun(@(sc) nnz([R(j & strcmp({R.sen}, sen{sc})).h7]), 1:5)); end
                yaz(' | %s %3d %-14s', etk{(3 - b)/2}, h, ek);
            end
            r = R(jm);  h7 = [r.h7];  yS = [r.yuzS];  yK = [r.yuzK];  iyi = [r.iyi];  e = abs([r.e]);
            f = ~h7;  ort = 0;  if any(f), ort = mean(e(f)); end
            yaz(' | %8d %10d %6d %7.2f\n', nnz(f & yS == 0), nnz(f & yS ~= 0 & yK ~= yS), ...
                nnz(f & yS ~= 0 & yK == yS & ~iyi), ort);
        end
    end
end
% senaryo x hedef: olay+yok ve her-açı varyantı, temassız sayısı (iki başlangıç, iki tesis birlikte)
yaz('\n--- Temassız koşu sayısı, senaryo x hedef (iki başlangıç x 3 tohum = /6 her tesiste) ---\n');
hh = R(1).hedef;  Y = R(1).Yn;
for mm = {'olay+yok', 'olay+yok her açı', 'edilgen'}
    for a = unique({R.sur}, 'stable')
        yaz('%-18s %-11s', mm{1}, a{1});
        for sc = 1:5
            j = strcmp({R.yontem}, mm{1}) & strcmp({R.sur}, a{1}) & strcmp({R.sen}, sen{sc});
            yS = vertcat(R(j).yuzS);  yaz(' | %-10s %s', sen{sc}(1:min(10,end)), sprintf('%d', sum(yS == 0, 1)));
        end
        yaz('\n');
    end
end
yaz('(sütun sırası: hedef %s önce Yn = +1, sonra Yn = -1)\n', mat2str(hh(Y == 1)));
fclose(fid);
end
