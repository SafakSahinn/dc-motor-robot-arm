% SERI_OLCUM_CIZ  seri_olcum.mat'tan RTT histogramını çizer (seri_olcum.png).
%   921600 baud (açılış hızı) ve en hızlı başarılı baud yan yana değil alt alta.
S = load("seri_olcum.mat");
ok = S.sonuc([S.sonuc.basari]);
if isempty(ok), return; end
sec = unique([ok(1).baud, ok(end).baud]);
f = figure("Visible", "off", "Color", "w", "Position", [100 100 900 320 * numel(sec)]);
gri = [0.3 0.3 0.3];
for i = 1:numel(sec)
    r = ok([ok.baud] == sec(i));
    x = r.rtt * 1e3;
    ax = subplot(numel(sec), 1, i);
    histogram(ax, x, "BinWidth", 0.01, "FaceColor", [0.231 0.435 0.714], ...
              "EdgeColor", "w", "LineWidth", 0.5, "FaceAlpha", 1);
    hold(ax, "on");
    yl = ylim(ax); ylim(ax, [0 yl(2) * 1.18]);
    q = prctile(x, [50 99]);
    xline(ax, q(1), "-", sprintf("p50 %.2f ms", q(1)), "Color", gri, ...
          "LabelOrientation", "horizontal", "LabelVerticalAlignment", "top", ...
          "LabelHorizontalAlignment", "right", "FontSize", 9);
    xline(ax, q(2), "--", sprintf("p99 %.2f ms", q(2)), "Color", gri, ...
          "LabelOrientation", "horizontal", "LabelVerticalAlignment", "top", ...
          "LabelHorizontalAlignment", "right", "FontSize", 9);
    xlim(ax, [floor(min(x) * 10) / 10, ceil(prctile(x, 99.9) * 10) / 10 + 0.1]);
    ax.Box = "off"; ax.TickDir = "out"; ax.YGrid = "on";
    ax.GridColor = [0.88 0.88 0.88]; ax.GridAlpha = 1;
    ax.XColor = [0.35 0.35 0.35]; ax.YColor = [0.35 0.35 0.35];
    title(ax, sprintf("Gidiş-dönüş süresi, %d baud (32 B paket, N = %d, en uzun %.2f ms)", ...
          r.baud, numel(x), max(x)), "FontWeight", "normal");
    xlabel(ax, "RTT (ms)"); ylabel(ax, "paket sayısı");
end
exportgraphics(f, "seri_olcum.png", "Resolution", 130);
close(f);
