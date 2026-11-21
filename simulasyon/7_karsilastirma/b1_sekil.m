function b1_sekil
% B1_SEKIL  b1_sonuc.mat'tan karşılaştırma şekli (sürtünmeli ve sürtünmesiz, taban kurallar en iyi
% parametreleriyle). Üst: H7 geçen oranı, alt: B12 (yüz doğruluğu). Sayısal tablo b1_log.txt'te.
cd(fileparts(mfilename('fullpath')));
load('b1_sonuc.mat', 'R', 'sen', 'sur');
ym = {'tablo', 'panasonic', 'toyoda', 'lenze', 'olay+yok'};
ad = {'Tablo (yerçekimi işareti)', 'Panasonic türü (hız komutu)', 'Toyoda türü (dönüş yönü)', ...
      'Lenze türü (tork işareti)', 'Önerilen kestirici'};
renk = hex2rgb({'#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4'});
yazi = [0.17 0.17 0.16];  ikincil = [0.42 0.42 0.40];  izgara = [0.88 0.88 0.86];
sH = [1 2 3 5 6];                                  % H7 tanımlı senaryolar (b'de son yüz tanımsız)
f = figure('Color', [0.988 0.988 0.984], 'Position', [80 80 1300 760], 'Visible', 'off');
tl = tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for a = 1:size(sur,1)
    H = zeros(numel(sH), numel(ym));  B = zeros(numel(sen), numel(ym));
    for m = 1:numel(ym)
        par = enIyi(R, sur{a,1}, ym{m}, sen, sH);
        for c = 1:numel(sen)
            kk = strcmp({R.sur}, sur{a,1}) & strcmp({R.yontem}, ym{m}) & ...
                 arrayfun(@(r) isequaln(r.par, par), R) & strcmp({R.sen}, sen{c});
            B(c,m) = mean([R(kk).b12]);
            i = find(sH == c);  if ~isempty(i), H(i,m) = 100*mean([R(kk).h7]); end
        end
    end
    cub(nexttile(tl, a), H, sen(sH), renk, [0 100], 'H7 geçen [%]', sprintf('%s: konum ölçütü H7', sur{a,1}), yazi, ikincil, izgara);
    cub(nexttile(tl, a+2), B, sen, renk, [0 1], 'B12 (yüz doğruluğu)', sprintf('%s: kestirilen yüz = gerçek yüz oranı', sur{a,1}), yazi, ikincil, izgara);
end
lg = legend(nexttile(tl, 1), ad, 'Orientation', 'horizontal', 'Box', 'off', 'TextColor', yazi, 'FontSize', 10);
lg.Layout.Tile = 'north';
title(tl, 'B1: komut tabanlı yüz kuralları ile yalnız motor sinyalli kestirici (179–181°, 42 koşu/senaryo)', ...
    'Color', yazi, 'FontSize', 13, 'FontWeight', 'normal');
exportgraphics(f, 'b1_karsilastirma.png', 'Resolution', 150);
end

function par = enIyi(R, s, y, sen, sH)
% Taban kuralın toplam H7'si en yüksek parametresi (eşitlikte B12 ortalaması).
kk = strcmp({R.sur}, s) & strcmp({R.yontem}, y);
pv = unique([R(kk).par]);  if all(isnan(pv)), par = NaN; return; end
sk = zeros(size(pv));
for g = 1:numel(pv)
    jj = kk & [R.par] == pv(g);
    hj = jj & ismember({R.sen}, sen(sH));
    sk(g) = nnz([R(hj).h7]) + 1e-3*mean([R(jj).b12]);
end
[~, i] = max(sk);  par = pv(i);
end

function cub(ax, V, et, renk, yl, ye, bas, yazi, ikincil, izgara)
b = bar(ax, V, 0.82, 'EdgeColor', [0.988 0.988 0.984], 'LineWidth', 1.5);
for m = 1:numel(b), b(m).FaceColor = renk(m,:); end
ax.XTickLabel = et;  ax.YLim = yl;  ax.Box = 'off';  ax.TickLength = [0 0];
ax.YGrid = 'on';  ax.GridColor = izgara;  ax.GridAlpha = 1;  ax.XColor = ikincil;  ax.YColor = ikincil;
ax.Color = 'none';  ax.FontSize = 10;
ylabel(ax, ye, 'Color', ikincil);  title(ax, bas, 'Color', yazi, 'FontWeight', 'normal', 'FontSize', 11);
end

function c = hex2rgb(h)
c = cell2mat(cellfun(@(s) sscanf(s(2:end), '%2x%2x%2x')'/255, h(:), 'uni', 0));
end
