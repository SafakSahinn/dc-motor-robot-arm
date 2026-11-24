function b3_ozet
% B3 özeti: parçaları birleştirir (b3_<sen>_sonuc.mat), b3_<sen>_log.txt yazar. Ortam B3_SEN.
cd(fileparts(mfilename('fullpath')));
sen = getenv('B3_SEN');  if isempty(sen), sen = 'ana'; end
d = dir(sprintf('b3_%s_sonuc_*.mat', sen));
if ~isempty(d)
    R = struct([]);
    for k = 1:numel(d), s = load(d(k).name);  R = [R s.R]; end %#ok<AGROW>
    save(sprintf('b3_%s_sonuc.mat', sen), 'R');
else
    s = load(sprintf('b3_%s_sonuc.mat', sen));  R = s.R;
end
fid = fopen(sprintf('b3_%s_log.txt', sen), 'w', 'n', 'UTF-8');
yaz = @(varargin) fprintf(fid, varargin{:});
yaz('B3 r izleme, senaryo %s, %d koşu (b3_r_izleme.m, b3_ozet.m)\n', sen, numel(R));
yaz('Ölçüt (tohum x tutma 45°/120° x çevrim): her tutmanın son 1 s ortalama hatası e.\n');
yaz('  ç1 |e|      : aşınmasız ilk çevrim ortalaması (taban)\n');
yaz('  son |e|     : son iki çevrim (aşınmanın %%75-100''ü) ortalama |e|, en büyük |e|\n');
yaz('  H7 son      : son iki çevrimde |e ort| <= 0,5° ve |e| en büyük <= 1° olan tutma sayısı / toplam\n');
yaz('  r^ - r      : kabul edilen ölçümlerin ortalama ve std sapması [°]; ilk ölçüm (aşınmasız) ayrı\n');
yaz('  rN - r son  : benzetim sonunda kestiricinin bildiği r ile gerçek r farkı (tohum ortalaması)\n');
yaz('  ölç/kab/gün/ipt : ölçüm, tutarlı (|yolA-yolB| <= 0,75°), akla yatkın (yenilik <= 0,3 rN; rN''ye yazılabilir), iptal sayıları (toplam); kol: yoklamada kolun en büyük hareketi ort [°]\n\n');
anah = arrayfun(@(r) sprintf('%s|%.2f|%d|%.3f', r.ad, r.A, r.sur, r.FcL), R, 'UniformOutput', false);
[ua, ~, ia] = unique(anah, 'stable');
kipler = {'sabit','mutlak','fark','kahin'};
for g = 1:numel(ua)
    Rg = R(ia == g);  r0 = Rg(1);
    yaz('== %s | A %.2f | motor sürt. %d | FcL %.3f\n', r0.ad, r0.A, r0.sur, r0.FcL);
    for k = 1:numel(kipler)
        Rk = Rg(strcmp({Rg.kip}, kipler{k}));  if isempty(Rk), continue; end
        E1 = [];  Es = [];  Ms = [];  dR = [];  dR1 = [];  dN = [];  nO = 0;  nK = 0;  nG = 0;  nI = 0;  KL = [];
        for r = Rk
            nc = size(r.eH, 1);  son = nc-1:nc;
            E1 = [E1 abs(r.eH(1,:))]; %#ok<AGROW>
            Es = [Es reshape(r.eH(son,:), 1, [])];  Ms = [Ms reshape(r.eM(son,:), 1, [])]; %#ok<AGROW>
            kb = r.kabul(:)';  d = (r.rH(:) - r.rT(:))';
            if ~isempty(d), dR1 = [dR1 d(1)]; end %#ok<AGROW>
            dR = [dR d(kb & (1:numel(d)) > 1)]; %#ok<AGROW>
            dN = [dN r.rNSon - r.rSon]; %#ok<AGROW>
            nO = nO + r.nO;  nK = nK + nnz(kb);  nG = nG + nnz(r.gun);  nI = nI + r.iptal;  KL = [KL r.kol(:)']; %#ok<AGROW>
        end
        h7 = nnz(abs(Es) <= 0.5 & Ms <= 1);
        yaz('  %-6s | ç1 |e| %.3f | son |e| ort %.3f max %.3f | H7 son %2d/%2d | r^-r ilk %+.3f, sonra %+.3f ± %.3f | rN-r son %+.3f | ölç/kab/gün/ipt %d/%d/%d/%d | kol %.2f\n', ...
            kipler{k}, mean(E1), mean(abs(Es)), max(abs(Es)), h7, numel(Es), mean(dR1), mean(dR), std(dR), mean(dN), nO, nK, nG, nI, mean(KL));
    end
end
fclose(fid);
type(sprintf('b3_%s_log.txt', sen));
end
