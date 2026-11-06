% DONGU_OLCUM_CIZ  dongu_olcum.mat'tan periyot sapması ve uyanma gecikmesi
%   histogramları (koşul B: trafik altında hafif yük, PIL'e en yakın durum).
S = load("dongu_olcum.mat");
r = S.sonuc(2);
mavi = [0.231 0.435 0.714]; gri = [0.3 0.3 0.3];
f = figure("Visible", "off", "Color", "w", "Position", [100 100 900 640]);
veri = {r.per - 1000, r.gec};
baslik = {sprintf("Periyot sapması (1000 µs'den), N = %d, en büyük |sapma| %.3f µs", ...
                  numel(r.per), max(abs(r.per - 1000))), ...
          sprintf("Kesme → görev uyanma gecikmesi, en uzun %.2f µs", max(r.gec))};
xet = {"sapma (µs)", "gecikme (µs)"};
for i = 1:2
    ax = subplot(2, 1, i);
    x = veri{i};
    histogram(ax, x, 80, "FaceColor", mavi, "EdgeColor", "w", "LineWidth", 0.5, "FaceAlpha", 1);
    ax.YScale = "log";
    yl = ylim(ax); ylim(ax, [0.8 yl(2) * 3]);
    q = prctile(x, 99);
    if i == 1, q = prctile(abs(x), 99); end
    xline(ax, q, "--", "Color", gri);
    yl = ylim(ax);
    text(ax, q, yl(2) / 4, sprintf("  p99 %.2f µs", q), "Color", gri, "FontSize", 9);
    ax.Box = "off"; ax.TickDir = "out"; ax.YGrid = "on"; ax.YMinorGrid = "off";
    ax.GridColor = [0.88 0.88 0.88]; ax.GridAlpha = 1;
    ax.XColor = [0.35 0.35 0.35]; ax.YColor = [0.35 0.35 0.35];
    title(ax, baslik{i}, "FontWeight", "normal");
    xlabel(ax, xet{i}); ylabel(ax, "tur sayısı (log)");
end
sgtitle(f, "ESP32 1 kHz kontrol görevi, koşul B (seri trafik altında, sahte adım ~20 µs)", ...
        "FontSize", 11);
exportgraphics(f, "dongu_olcum.png", "Resolution", 130);
close(f);
