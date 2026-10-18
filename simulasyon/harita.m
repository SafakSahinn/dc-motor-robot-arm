% HARITA  Çalışma açısı x kapalı çevrim hızı düzleminde salınım haritası,
% üç model seviyesinde (ideal, sürtünmeli, gerçekçi).
% Her nokta iki başlangıç koşuluyla (hedefin 1 ve 20 derece altı) çözülür.
% Sınıflar:
%   0 durgun denge
%   1 dişli bastırılı salınım (sürtünme / nicemleme; dişli boşluğa girmiyor)
%   2 tek kenarlı boşluk salınımı (dişli ayrılıp aynı kenara dönüyor)
%   3 iki kenarlı boşluk salınımı (klasik boşluk limit cycle'ı)
%   4 kararsız (kol hedefte tutulamıyor)
%   5 başlangıca bağlı (bir başlangıçta boşluk salınımı var, diğerinde yok)
ac  = 0:5:180;
wcs = 5:2.5:50;
[AC, WC] = meshgrid(ac, wcs);
sev = {'ideal','surtunme','gercekci'};
bas = {'ideal: sürtünmesiz, ideal sensör', 'sürtünmeli: + Coulomb/yapışma', 'gerçekçi: + nicemleme, 1 kHz, ölü bant'};
renk = [0.88 0.94 0.91;   % 0 denge
        0.62 0.78 0.90;   % 1 bastırılı salınım
        0.98 0.80 0.45;   % 2 tek kenarlı
        0.80 0.30 0.20;   % 3 iki kenarlı
        0.45 0.45 0.50;   % 4 kararsız
        0.93 0.60 0.75];  % 5 başlangıca bağlı
etiket = {'durgun denge','dişli bastırılı salınım (sürtünme/nicemleme)','tek kenarlı boşluk salınımı', ...
          'iki kenarlı boşluk salınımı','kararsız','başlangıca bağlı'};
S = struct();
fig = figure('Visible','off','Position',[50 50 1500 560]);
tl = tiledlayout(1,3,'TileSpacing','compact');
for s = 1:numel(sev)
    c = cell(1,2);  A = cell(1,2);  k = 0;
    for adim = [1 20]
        k = k+1;
        p = parametreler(sev{s});  p.adim = adim;
        tic; o = kol_benzetim(p, AC(:)', WC(:)'); fprintf('%s, adim %2d: %.1f s\n', sev{s}, adim, toc);
        c{k} = reshape(o.sinif, size(AC));  A{k} = reshape(o.A_deg, size(AC));
    end
    sinif = max(c{1}, c{2});
    fark  = xor(c{1} >= 2 & c{1} <= 3, c{2} >= 2 & c{2} <= 3) & sinif ~= 4;
    sinif(fark) = 5;
    S.(sev{s}).sinif = sinif;  S.(sev{s}).A1 = A{1};  S.(sev{s}).A20 = A{2};
    S.(sev{s}).c1 = c{1};  S.(sev{s}).c20 = c{2};

    nexttile;
    imagesc(ac, wcs, sinif); set(gca,'YDir','normal'); colormap(renk); clim([-0.5 5.5]);
    title(bas{s}); xticks(0:30:180); xlabel('\theta_0 [derece]');
    if s == 1, ylabel('kapalı çevrim hızı \omega_c [rad/s]'); end
end
cb = colorbar; cb.Layout.Tile = 'east'; cb.Ticks = 0:5; cb.TickLabels = etiket;
title(tl, 'Salınım haritası (0 = dik aşağı, 90 = yatay, 180 = dik yukarı; boşluk 1.5°)');
exportgraphics(fig, 'harita.png', 'Resolution', 120);
save harita.mat ac wcs S

for s = 1:numel(sev)
    fprintf('\n[%s] sinif satirlari (aci 0..180 /5)\n', sev{s});
    for i = 1:2:numel(wcs)
        fprintf('%6g  %s\n', wcs(i), sprintf('%d', S.(sev{s}).sinif(i,:)));
    end
end
