function ghaffari_sekil78(ayar)
% GHAFFARI_SEKIL78  Şekil 7 (rezonans) ve Şekil 8'in (çarpma) bu modelle üretimi.
% Makaledeki düzen: (a) fark açısı + birinci harmonik, (b) burulma açısı + birinci
% harmonik, (c) komut hızı, motor sensörü (wm/kr), yük sensörü; hepsi yük tarafı, rpm.
%   ayar = 'taban'    : ghaffari_param varsayımları (viskoz cm/cle, temas sönümü 0,02)
%   ayar = 'kalibre'  : viskoz sürtünme sıfır, temas sönümü 0,0135 (Şekil 7'ye uyan değer,
%                       sonum_tarama_log.txt)
if nargin < 1, ayar = 'taban'; end
rpm = 60/(2*pi);
fig = figure('Visible','off','Position',[100 100 1300 900]);
durumlar = {'sekil7','sekil8'};
for c = 1:2
    p = ghaffari_param(durumlar{c});
    if strcmp(ayar,'kalibre'), p.cm = 0; p.cle = 0; p.cl = 0; p.xis = 0.0135; p.cs = 2*p.xis*p.ks/p.wa; end
    p.T = 7; p.Tan = 4;
    o = ghaffari2013(p, 11.67, 20);
    w = o.t >= o.t(end)-1;                         % son 1 s çizilir (makale: 4-5 s)
    t = o.t(w) - o.t(find(w,1)) + 4;
    [h1, A1] = harmonik(o.t(w), o.thd(w), o.f_Hz);
    [h2, A2] = harmonik(o.t(w), o.burulma(w), o.f_Hz);
    subplot(3,2,c);
    plot(t, rad2deg(o.thd(w)), 'k-', t, rad2deg(h1), 'k:'); grid on;
    ylabel('fark açısı [der]');
    title(sprintf('%s: kp=%.2f, kv=%g, f_a=%g Hz, r_{gs}=%.2f -> %.2f Hz, A=%.3f der (1. harm. %.3f)', ...
        durumlar{c}, o.kp, o.kv, p.fa, o.rgs, o.f_Hz, o.A_deg, rad2deg(A1)), 'FontSize', 9);
    subplot(3,2,c+2);
    plot(t, rad2deg(o.burulma(w)), 'k-', t, rad2deg(h2), 'k:'); grid on;
    ylabel('burulma [der]');
    title(sprintf('burulma tepe %.2g der, 1. harmonik %.2g der', rad2deg(max(abs(o.burulma(w)))), rad2deg(A2)), 'FontSize', 9);
    subplot(3,2,c+4);
    plot(t, o.wc(w)*rpm, 'k:', t, o.wm_kr(w)*rpm, 'k--', t, o.wl(w)*rpm, 'k-'); grid on;
    ylabel('hız [rpm]'); xlabel('zaman [s]');
    legend({'komut','motor sensörü','yük sensörü'}, 'Location','southeast', 'FontSize', 8);
end
sgtitle(sprintf('Ghaffari 2013, Şekil 7 ve 8: bu modelle üretim (%s)', ayar));
exportgraphics(fig, sprintf('sekil78_%s.png', ayar), 'Resolution', 110);
end

function [h, A] = harmonik(t, y, f)
% En küçük kareler ile f frekansındaki birinci harmonik (ortalama dahil).
if f <= 0, h = zeros(size(y)); A = 0; return; end
M = [ones(size(t)) sin(2*pi*f*t) cos(2*pi*f*t)];
b = M\y;  h = M*b;  A = hypot(b(2), b(3));
end
