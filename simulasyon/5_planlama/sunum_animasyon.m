function sunum_animasyon(cikis)
% SUNUM_ANIMASYON  README ve sunum için görseller üretir (sunum_demo.m'nin benzetimiyle).
%   sonuc_42senaryo.png : sunum_demo'nun 6 grafikli şekli
%   yuz_kestirici.gif   : kol 180°'de, iki yöntem yan yana (sapma 10x büyütülmüş) + zaman ekseni
%   bosluk_salinimi.gif : 3B fiziksel modelde boşluk salınımı (rapor/img/mb_animasyon.mp4'ten)
% cikis varsayılan: <repo>/sunum/img. kol_benzetim.m'ye dokunmaz.
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1, cikis = fullfile(kok, 'sunum', 'img'); end
if ~exist(cikis, 'dir'), mkdir(cikis); end

S = sunum_demo;
exportgraphics(S.sekil, fullfile(cikis, 'sonuc_42senaryo.png'), 'Resolution', 120);
close(S.sekil);

% --- yüz kestirici animasyonu: edilgenin kaybettiği ilk senaryo (bozucu yok) ---
j = S.sec(1);  hedef = S.ac(j);  b = 10;  L = 1;
renk = [0.80 0.25 0.20; 0.15 0.40 0.75];
t = S.O{1}.t;  idx = 1:round(0.1/(t(2)-t(1))):numel(t);
sap = [rad2deg(S.O{1}.th(:,j)) rad2deg(S.O{2}.th(:,j))] - hedef;
f = figure('Visible', 'off', 'Color', 'w', 'Position', [0 0 860 520]);
dosya = fullfile(cikis, 'yuz_kestirici.gif');
for k = 1:numel(idx)
    n = idx(k);  clf(f);
    for m = 1:2
        ax = axes(f, 'Position', [0.04 + 0.5*(m-1) 0.40 0.42 0.52]);  hold(ax, 'on');  axis(ax, 'equal', 'off');
        xlim(ax, [-1.25 1.25]);  ylim(ax, [-0.35 1.25]);
        plot(ax, [0 0], [0 1.15], 'k:', 'LineWidth', 1);             % hedef (180°, dik yukarı)
        plot(ax, [-0.6 0.6], [0 0], 'Color', [0.6 0.6 0.6], 'LineWidth', 3);
        a = deg2rad(b*sap(n,m));                                       % dikeyden sapma, büyütülmüş
        plot(ax, [0 L*sin(a)], [0 L*cos(a)], 'Color', renk(m,:), 'LineWidth', 7);
        plot(ax, L*sin(a), L*cos(a), 'o', 'MarkerSize', 16, 'MarkerFaceColor', renk(m,:), 'MarkerEdgeColor', 'none');
        rectangle(ax, 'Position', [-0.12 -0.12 0.24 0.24], 'Curvature', 1, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
        ok = abs(sap(n,m)) <= 0.5;
        if ok, durum = 'hedefte'; dr = [0.1 0.5 0.2]; else, durum = 'yanlış yüz, hedeften uzak'; dr = [0.75 0.2 0.15]; end
        text(ax, 0, -0.24, sprintf('sapma %+.2f°  (%s)', sap(n,m), durum), 'HorizontalAlignment', 'center', ...
            'FontSize', 11, 'Color', dr, 'FontWeight', 'bold');
        title(ax, S.ad{m}, 'Color', renk(m,:), 'FontSize', 12, 'Visible', 'on');
    end
    ax = axes(f, 'Position', [0.08 0.09 0.88 0.22]);  hold(ax, 'on');  grid(ax, 'on');  box(ax, 'on');
    for m = 1:2, plot(ax, t, sap(:,m), 'Color', renk(m,:), 'LineWidth', 1.5); end
    yline(ax, [-0.5 0.5], 'k:');  xline(ax, t(n), 'k-', 'LineWidth', 1);
    xlim(ax, [0 t(end)]);  ylim(ax, [-3.6 1]);  xlabel(ax, 't [s]');  ylabel(ax, 'sapma [°]');
    annotation(f, 'textbox', [0 0.93 1 0.07], 'String', sprintf(['Kol dik yukarıda (istek %.2f°), kontrolcü kolu görmüyor  ·  ' ...
        't = %.1f s  ·  çizimde sapma %dx büyütüldü'], S.istek(j), t(n), b), 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'FontSize', 11);
    im = print(f, '-RGBImage', '-r72');
    [A, cm] = rgb2ind(im, 64, 'nodither');
    if k == 1
        imwrite(A, cm, dosya, 'gif', 'LoopCount', Inf, 'DelayTime', 0.1);
    else
        imwrite(A, cm, dosya, 'gif', 'WriteMode', 'append', 'DelayTime', 0.1);
    end
end
imwrite(A, cm, dosya, 'gif', 'WriteMode', 'append', 'DelayTime', 2);   % sonda bekle
close(f);

% --- 3B fiziksel modelde boşluk salınımı (videodan gif) ---
v = VideoReader(fullfile(kok, 'rapor', 'img', 'mb_animasyon.mp4'));
dosya = fullfile(cikis, 'bosluk_salinimi.gif');  k = 0;
while hasFrame(v)
    fr = readFrame(v);  k = k + 1;
    if mod(k, 2), continue; end
    s = 560/size(fr,2);                                   % araç kutusu gerektirmeyen küçültme
    fr = fr(max(1, round((1:round(size(fr,1)*s))/s)), max(1, round((1:560)/s)), :);
    [A, cm] = rgb2ind(fr, 64, 'nodither');
    if k == 2
        imwrite(A, cm, dosya, 'gif', 'LoopCount', Inf, 'DelayTime', 2/v.FrameRate);
    else
        imwrite(A, cm, dosya, 'gif', 'WriteMode', 'append', 'DelayTime', 2/v.FrameRate);
    end
end
fprintf('Görseller yazıldı: %s\n', cikis);
end
