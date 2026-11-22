function b1l_ozet
% B1-L özet: b1l_sonuc_*.mat parçalarını birleştirir, b1l_log.txt'yi yazar.
% H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (b salınım hariç: 5 senaryo x 14 x 3 = 210).
cd(fileparts(mfilename('fullpath')));
onek = getenv('B1L_ONEK');  if isempty(onek), onek = 'b1l'; end
d = dir([onek '_sonuc_*.mat']);  R = struct([]);
for i = 1:numel(d), s = load(d(i).name);  R = [R s.R]; end %#ok<AGROW>
sen = s.sen;  sur = s.sur;  I = s.I;  Yn = s.Yn;
save([onek '_sonuc.mat'], 'R', 'sen', 'sur', 'I', 'Yn');
fid = fopen([onek '_log.txt'], 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== B1-L literatür tabanları, %s. Senaryolar/ölçütler B1 ile aynı (%d kayıt).\n', datestr(now,'yyyy-mm-dd HH:MM'), numel(R));
yaz('Hücre: H7 (3 tohum, /42), B12 ort, App en büyük [°]. b salınımda H7 yok. avl: son 3 s s^ değişimi (ort).\n\n');
yaz('%-11s %-12s %-22s', 'sürtünme', 'yöntem', 'parametre');
for sc = 1:numel(sen), yaz(' | %-15s', sen{sc}); end;  yaz(' | toplam | avl\n');
anah = unique(arrayfun(@(r) sprintf('%s|%s|%s', r.sur, r.yontem, r.par), R, 'uni', 0), 'stable');
O = struct([]);
for u = 1:numel(anah)
    pr = strsplit(anah{u}, '|');
    kk0 = strcmp({R.sur}, pr{1}) & strcmp({R.yontem}, pr{2}) & strcmp({R.par}, pr{3});
    yaz('%-11s %-12s %-22s', pr{:});
    top = 0;  topN = 0;  b12t = [];  avt = [];  hs7 = zeros(1, numel(sen));
    for sc = 1:numel(sen)
        kk = kk0 & strcmp({R.sen}, sen{sc});
        h = [R(kk).h7];  b = [R(kk).b12];  A = [R(kk).App];  avt = [avt R(kk).avl]; %#ok<AGROW>
        if sc == 4, hs = '  - '; else, hs = sprintf('%2d/%d', nnz(h), numel(h));  top = top + nnz(h);  topN = topN + numel(h);  hs7(sc) = nnz(h); end
        if all(isnan(b)), bs = '  -  '; else, bs = sprintf('%.2f', mean(b, 'omitnan'));  b12t = [b12t b]; end %#ok<AGROW>
        yaz(' | %s %s %4.2f', hs, bs, max(A));
    end
    yaz(' | %3d/%d | %.1f\n', top, topN, mean(avt));
    O(u).sur = pr{1};  O(u).yontem = pr{2};  O(u).par = pr{3};  O(u).h7 = top;  O(u).N = topN;
    O(u).b12 = mean(b12t, 'omitnan');  O(u).hs = hs7;  O(u).avl = mean(avt);
    O(u).App = max([R(kk0).App]);  O(u).uyar = mean([R(kk0).uyar]);
end
yontemler = unique({O.yontem}, 'stable');
yaz('\nÖzet: her yöntemin EN İYİ ayarı (toplam H7, eşitlikte B12), ve en kötü ayarı:\n');
for a = 1:size(sur,1)
    for m = 1:numel(yontemler)
        j = find(strcmp({O.sur}, sur{a,1}) & strcmp({O.yontem}, yontemler{m}));
        sk = [O(j).h7] + 1e-3*[O(j).b12];  [~, en] = max(sk);  [~, ek] = min(sk);
        yaz('  %-11s %-12s en iyi %-22s H7 %3d/%d (temel %d a1 %d a2 %d c %d d %d) B12 %.3f avl %.1f', O(j(en)).sur, ...
            yontemler{m}, O(j(en)).par, O(j(en)).h7, O(j(en)).N, O(j(en)).hs([1 2 3 5 6]), O(j(en)).b12, O(j(en)).avl);
        if strcmp(yontemler{m}, 'sta+uyarim'), yaz(' uyarım/koşu %.2f', O(j(en)).uyar); end
        if numel(j) > 1, yaz(' | en kötü %s H7 %d', O(j(ek)).par, O(j(ek)).h7); end
        yaz('\n');
    end
end
fclose(fid);
end
