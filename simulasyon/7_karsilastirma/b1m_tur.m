function b1m_tur(yontem)
% B1-M başarısızlık türü: her koşul x tesis için H7'yi geçemeyen koşular (iki başlangıç birlikte, /420).
%   yüz izi : |e| > 1,5°  (son 1 s ortalaması; kol yanlış yüzün ofsetinde)
%   kayma   : 0,5° < |e| <= 1,5°
%   salınım : |e| <= 0,5° ama e_max > 1°  (emax kaydı yoksa: konum ölçütünü geçemeyen ve |e| <= 0,5°)
%   yanlış yüz (konum iyi) : konum ölçütü geçiyor, son dişli torku yüzü yanlış
% Ortam: B1M_ONEK (varsayılan b1m). Sonuç <onek>_log.txt sonuna eklenir. yontem varsayılan 'olay+yok'.
if nargin < 1, yontem = 'olay+yok'; end
cd(fileparts(mfilename('fullpath')));
onek = getenv('B1M_ONEK');  if isempty(onek), onek = 'b1m'; end
s = load([onek '_sonuc.mat']);  R = s.R;  K = s.K;
fid = fopen([onek '_log.txt'], 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n--- Başarısızlık türü (%s, iki başlangıç birlikte, /420) ---\n', yontem);
yaz('%-26s %-11s %5s %8s %6s %8s %10s %8s\n', 'koşul', 'tesis', 'H7', 'yüz izi', 'kayma', 'salınım', 'yanlış yüz', 'ort|e|');
emVar = isfield(R, 'emax');
for kk = 1:size(K,1)
    jk = strcmp({R.kosul}, K{kk,1}) & strcmp({R.yontem}, yontem);
    for a = unique({R(jk).sur}, 'stable')
        r = R(jk & strcmp({R.sur}, a{1}));
        h7 = [r.h7];  iyi = [r.iyi];  e = abs([r.e]);
        if emVar, em = [r.emax]; else, em = Inf(size(e)); end
        f = ~h7;
        yi = f & e > 1.5;  ky = f & e > 0.5 & e <= 1.5;  sa = f & ~iyi & e <= 0.5 & em > 1;
        yy = f & iyi;
        ort = mean(e(f));  if ~any(f), ort = 0; end
        yaz('%-26s %-11s %5d %8d %6d %8d %10d %8.2f\n', K{kk,1}, a{1}, nnz(h7), nnz(yi), nnz(ky), nnz(sa), nnz(yy), ort);
    end
end
fclose(fid);
end
