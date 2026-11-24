function b3_sekil
% B3 şekli: (a) temsilci koşuda r(t), r^ ve rN; (b) çevrim başına tutma hatası |e|, 4 kip.
% Tesis: motor sürtünmeli, FcL 0,004, A 0,5. Renkler: dataviz varsayılan kategorik paleti (sabit sıra).
cd(fileparts(mfilename('fullpath')));
s = load('b3_ana_sonuc.mat');  R = s.R;
kip = {'sabit','mutlak','fark','kahin'};  ad = {'sabit r_N','mutlak','fark','kâhin'};
C = [42 120 214; 235 104 52; 27 175 122; 237 161 0]/255;  ink = [11 11 11]/255;  ink2 = [82 81 78]/255;
sec = @(r) r.A == 0.5 && r.sur == 1 && abs(r.FcL - 0.004) < 1e-9;
Rs = R(arrayfun(sec, R));
f = figure('Color', [252 252 251]/255, 'Position', [100 100 1000 400], 'Visible', 'off');
ax = subplot(1,2,1);  hold on;  box off;
tt = linspace(0, 80, 400);  plot(tt, 1.5*(1 + 0.5*min(max((tt - 16)/64, 0), 1)), '-', 'Color', ink, 'LineWidth', 2);
for k = 2:3
    r = Rs(strcmp({Rs.kip}, kip{k}) & [Rs.tohum] == 1);
    stairs([0; r.tO(:); 80], [1.5; r.rN(:); r.rN(end)], '-', 'Color', C(k,:), 'LineWidth', 2);
    plot(r.tO, r.rH, 'o', 'MarkerSize', 7, 'MarkerFaceColor', C(k,:), 'MarkerEdgeColor', [1 1 1]*0.99, 'LineWidth', 1.5);
end
xlabel('t [s]');  ylabel('r [°]');  title('(a) gerçek r(t), ölçüm (nokta), r_N (basamak); tohum 1', 'FontWeight', 'normal');
legend({'gerçek r', 'mutlak r_N', 'mutlak ölçüm', 'fark r_N', 'fark ölçüm'}, 'Location', 'northwest', 'Box', 'off');
stil(ax, ink2);
ax = subplot(1,2,2);  hold on;  box off;
for k = 1:4
    Rk = Rs(strcmp({Rs.kip}, kip{k}));  E = cat(3, Rk.eH);   % çevrim x tutma x tohum
    m = squeeze(mean(mean(abs(E), 2), 3));
    plot(1:numel(m), m, '-o', 'Color', C(k,:), 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', C(k,:), 'MarkerEdgeColor', [1 1 1]*0.99);
    text(numel(m) + 0.1, m(end), ad{k}, 'Color', ink, 'FontSize', 9, 'VerticalAlignment', 'middle');
end
yline(0.5, ':', 'H7 sınırı 0,5°', 'Color', ink2, 'LabelHorizontalAlignment', 'center');
xlim([0.8 5.9]);  xlabel('çevrim (16 s; aşınma 2.''den itibaren)');  ylabel('|e| tutma ort. [°]');
title('(b) 45°/120° tutma hatası, 3 tohum', 'FontWeight', 'normal');
legend(ad, 'Location', 'northwest', 'Box', 'off');  ylim([0 0.65]);  stil(ax, ink2);
exportgraphics(f, 'b3_r_izleme.png', 'Resolution', 150);
end

function stil(ax, c)
ax.XColor = c;  ax.YColor = c;  ax.GridColor = c;  ax.GridAlpha = 0.15;  grid(ax, 'on');  ax.FontSize = 10;
end
