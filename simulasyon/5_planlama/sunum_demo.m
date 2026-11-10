function sunum_demo
% SUNUM_DEMO  Danışman sunumu için tek komutluk gösterim (11 Kasım 2026).
% yuz_kestirici_as5600.m'nin gerçekçi koşusu (AS5600 motor milinde, 1 kHz, 0,4 ms gecikme,
% veri sayfası gürültüsü, sürtünmeli ikiz): 42 senaryo, iki yöntem:
%   edilgen      : motor durunca yüz = sign(u)  ("akımın işaretine bak", basit yöntem)
%   olay+yoklama : tork gözlemcisi çarpmayı yakalar + küçük tork itişiyle yoklama (katkı)
% Komut penceresine H7 sayısını yazar (edilgen 20/42 civarı, kestirici 42/42) ve üç bozucu
% türünden (yok / darbe / yanlış başlangıç yüzü) edilgenin kaybettiği birer senaryoyu çizer.
% Kol açısı yalnız hakem (gerçek yüz = ikizin boşluk içi konumu); kontrolcü kolu görmez.
% Sonuçlar kayıt etmez; kol_benzetim.m'ye dokunmaz.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);
p0.Fc = 0.04;  p0.Fs = 0.06;
p0.Ts = 1e-3;  p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.Nper = 10;  p0.yuzN = 20;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;

istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;
hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));
yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);
n = numel(hedef);  ac = hedef;

yt = {'edilgen', 'olay+yoklama'};
ad = {'Basit yöntem (akımın işareti)', 'Yüz kestirici (olay + yoklama)'};
O = cell(1, 2);  H7 = false(2, n);  E = zeros(2, n);
fprintf('\n=== Yüz kestirici gösterimi: 42 senaryo, AS5600 + 1 kHz + gecikme + gürültü, sürtünmeli ikiz\n');
for m = 1:2
    p = p0;
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;
    p.yuzKes = yt{m};  p.yuz0 = yuz0;
    if m == 2, p.yokOrta = 0.6;  p.vDurF = 10; end
    tic;  o = kol_benzetim(p, ac, kpv*ones(1,n));  sure = toc;
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p0.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    H7(m,:) = abs(e) <= 0.5 & emax <= 1 & yuzS == s0;
    E(m,:) = e;  O{m} = o;
    fprintf('  %-32s : %2d / %d senaryo geçti   (en kötü kalıcı hata %.2f°, %.0f s)\n', ...
        ad{m}, nnz(H7(m,:)), n, max(abs(e)), sure);
end
fprintf('  Ölçüt (H7): son 1 s ortalama |hata| <= 0,5°, en büyük <= 1°, kol doğru yüzde.\n');

% Edilgenin kaybettiği, kestiricinin geçtiği senaryolardan her bozucu türüne bir tane
bozAd = {'bozucu yok', 'kola darbe (t = 3 s)', 'yanlış başlangıç yüzü'};
sec = [];
for b = 1:3
    j = find(~H7(1,:) & H7(2,:) & B == b, 1);
    if isempty(j), j = find(B == b, 1); end
    sec(end+1) = j; %#ok<AGROW>
end

f = figure('Name', 'Yüz kestirici: 180° çevresi', 'Color', 'w', 'Position', [60 60 1250 780]);
tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('180° çevresi, gerçekçi sensör: basit yöntem %d/42, yüz kestirici %d/42', ...
    nnz(H7(1,:)), nnz(H7(2,:))), 'FontWeight', 'bold');
renk = [0.80 0.25 0.20; 0.15 0.40 0.75];
for k = 1:3
    j = sec(k);
    yon = 'alttan';  if Y(j) < 0, yon = 'üstten'; end
    ax = nexttile(tl, k);  hold(ax, 'on');  grid(ax, 'on');
    for m = 1:2
        o = O{m};
        plot(ax, o.t, rad2deg(o.th(:,j)) - ac(j), 'Color', renk(m,:), 'LineWidth', 1.4);
    end
    yline(ax, [-0.5 0.5], 'k:');  yline(ax, 0, 'k-');
    ylabel(ax, 'kol açısı - hedef [°]');
    title(ax, sprintf('istek %.2f° (%s), %s', I(j), yon, bozAd{B(j)}), 'FontWeight', 'normal');
    if k == 1, legend(ax, ad, 'Location', 'best'); end
    xlim(ax, [0 o.t(end)]);

    ax = nexttile(tl, k + 3);  hold(ax, 'on');  grid(ax, 'on');
    o = O{2};
    gy = sign(o.delta(:,j)).*(abs(o.delta(:,j)) >= p0.r);
    stairs(ax, o.t, gy, 'Color', [0.45 0.45 0.45], 'LineWidth', 2.2);
    stairs(ax, o.t, o.shat(:,j), 'Color', renk(2,:), 'LineWidth', 1.2);
    yline(ax, s0(j), 'g--', 'doğru yüz', 'LabelHorizontalAlignment', 'left');
    ylim(ax, [-1.4 1.4]);  yticks(ax, [-1 0 1]);  yticklabels(ax, {'− yüz', 'boşlukta', '+ yüz'});
    xlabel(ax, 't [s]');  xlim(ax, [0 o.t(end)]);
    if k == 1, legend(ax, {'gerçek temas (kol sensörü, yalnız hakem)', 'kestiricinin tahmini'}, 'Location', 'best'); end
    title(ax, sprintf('kalıcı hata: basit %.2f°, kestirici %.2f°', E(1,j), E(2,j)), 'FontWeight', 'normal');
end
end
