function b2_sekil
% B2_SEKIL  B2 şekilleri (b2_sonuc.mat, b2_bedel.mat):
%   b2_harita.png : dişli tablosu, açı x ön yük hücresinde H7 kayıp oranı (b hariç 6 senaryo x 2 yön
%                   x 3 tohum = 36 koşu), 6 ortam; siyah çizgi durağan yüz değişimi th* (mgl sin th* = -taup).
%   b2_disliz.png : dişlisiz (taup = 0) açıya göre kayıp oranı: tablo, kestirici, üst sınır.
%   b2_bedel.png  : hareket bedeli taup'a göre (sürtünmeli taban, muP 0 / 0,25 / 0,5): RMS akım, enerji,
%                   son 3 s salınım; profil başına bir sütun.
cd(fileparts(mfilename('fullpath')));
load('b2_sonuc.mat', 'D', 'G');
mgl = 0.0;  p0 = b2_kurulum();  mgl = p0.mgl;
mavi = hex(["#ffffff" "#cde2fb" "#9ec5f4" "#6da7ec" "#3987e5" "#256abf" "#184f95" "#0d366b"]);
km = interp1(linspace(0,1,size(mavi,1)), mavi, linspace(0,1,256));
renk = hex(["#2a78d6" "#eb6834" "#1baf7a" "#eda100" "#e87ba4"]);
ink = [0.2 0.2 0.2];  ana = find(~strcmp(G.sen, 'b salınım'));
nO = size(G.ortam,1);  nT = numel(G.taup);  nA = numel(G.aci);

% --- 1. harita ---
f = figure('Visible','off','Color','w','Position',[0 0 1500 760]);
tl = tiledlayout(f, 2, 3, 'TileSpacing','compact', 'Padding','compact');
for a = 1:nO
    M = zeros(nT, nA);
    for sc = ana
        Rm = D{a,sc}.disli_tablo;
        for it = 1:nT
            for ia = 1:nA
                j = Rm.taup == G.taup(it) & Rm.aci == G.aci(ia);
                M(it,ia) = M(it,ia) + nnz(~Rm.h7(j));
            end
        end
    end
    M = M/(numel(ana)*6);
    ax = nexttile(tl);
    imagesc(ax, G.aci, 1:nT, M, [0 1]);  set(ax, 'YDir','normal');  colormap(ax, km);  hold(ax, 'on');
    for it = 1:nT
        if G.taup(it) <= mgl
            ts = 180 + asind(G.taup(it)/mgl);
            plot(ax, [ts ts], it + [-0.45 0.45], '-', 'Color', ink, 'LineWidth', 2);
            plot(ax, 540 - [ts ts], it + [-0.45 0.45], '-', 'Color', ink, 'LineWidth', 2);
        end
    end
    set(ax, 'YTick', 1:nT, 'YTickLabel', compose('%.2f', G.taup), 'XTick', 90:45:360, 'TickDir','out', ...
        'Box','off', 'FontSize', 10, 'XColor', ink, 'YColor', ink);
    title(ax, sprintf('%s, \\mu_p = %.2f', G.ortam{a,1}, G.ortam{a,4}), 'FontWeight','normal', 'FontSize', 11);
    if mod(a-1,3) == 0, ylabel(ax, '\tau_p [N m]  (0 = dişlisiz)'); end
    if a > 3, xlabel(ax, 'hedef açı [°]  (180 = dik yukarı)'); end
end
cb = colorbar(ax);  cb.Layout.Tile = 'east';  cb.Label.String = 'H7 kayıp oranı (36 koşu/hücre)';
title(tl, 'Ön yüklü dişli + durağan tablo: konum hatası nerede kalıyor (çizgi: durağan yüz değişimi \theta^*)', 'FontSize', 12);
exportgraphics(f, 'b2_harita.png', 'Resolution', 130);  close(f);

% --- 2. dişlisiz satır: tablo / kestirici / üst sınır ---
f = figure('Visible','off','Color','w','Position',[0 0 1300 420]);
tl = tiledlayout(f, 1, 2, 'TileSpacing','compact', 'Padding','compact');
kt = {'disli_tablo', 'kestirici', 'ust_sinir'};  ad = {'tablo (B1)', 'önerilen kestirici', 'üst sınır'};
rr = [2 1 3];
for a = [1 4]
    ax = nexttile(tl);  hold(ax, 'on');
    for m = 1:3
        v = zeros(1, nA);
        for sc = ana
            Rm = D{a,sc}.(kt{m});
            for ia = 1:nA
                j = Rm.taup == 0 & Rm.aci == G.aci(ia);  v(ia) = v(ia) + nnz(~Rm.h7(j));
            end
        end
        plot(ax, G.aci, v/(numel(ana)*6), '-', 'Color', renk(rr(m),:), 'LineWidth', 2, 'DisplayName', ad{m});
    end
    set(ax, 'XTick', 90:45:360, 'YLim', [0 1], 'TickDir','out', 'Box','off', 'XColor', ink, 'YColor', ink, ...
        'YGrid','on', 'GridColor', [0.85 0.85 0.85], 'GridAlpha', 1);
    title(ax, sprintf('dişlisiz, %s', G.ortam{a,1}), 'FontWeight','normal');
    xlabel(ax, 'hedef açı [°]');  ylabel(ax, 'H7 kayıp oranı');
    legend(ax, 'Location','northeast', 'Box','off');
end
exportgraphics(f, 'b2_disliz.png', 'Resolution', 130);  close(f);

% --- 3. bedel ---
if ~isfile('b2_bedel.mat'), return; end
S = load('b2_bedel.mat');  B = S.B;
olc = {'Irms_har', 'RMS akım, hareket [A]';  'E_har', 'sürücü enerjisi, hareket [J]';  'App', 'son 3 s salınım t-t [°]'};
for taban = ["sürtünmeli" "sürtünmesiz"]
    f = figure('Visible','off','Color','w','Position',[0 0 1400 900]);
    tl = tiledlayout(f, size(olc,1), numel(S.prof), 'TileSpacing','compact', 'Padding','compact');
    for io = 1:size(olc,1)
        for pr = 1:numel(S.prof)
            ax = nexttile(tl);  hold(ax, 'on');
            mus = [0 0.25 0.5];
            for im = 1:3
                k = find(arrayfun(@(b) strcmp(b.ortam{1}, taban) && b.ortam{4} == mus(im) && ...
                    strcmp(b.prof, S.prof{pr}) && strcmp(b.ktl, 'disli_tablo'), B));
                v = arrayfun(@(tp) mean(B(k).(olc{io,1})(B(k).taup == tp)), G.taup);
                plot(ax, G.taup, v, '-o', 'Color', renk(im,:), 'MarkerFaceColor', renk(im,:), 'MarkerSize', 4, ...
                    'LineWidth', 2, 'DisplayName', sprintf('dişli + tablo, \\mu_p = %.2f', mus(im)));
            end
            k = find(arrayfun(@(b) strcmp(b.ortam{1}, taban) && b.ortam{4} == 0 && ...
                strcmp(b.prof, S.prof{pr}) && strcmp(b.ktl, 'kestirici'), B));
            v0 = mean(B(k).(olc{io,1})(B(k).taup == 0));
            plot(ax, 0, v0, 'p', 'Color', renk(4,:), 'MarkerFaceColor', renk(4,:), 'MarkerSize', 12, ...
                'DisplayName', 'dişlisiz + kestirici');
            set(ax, 'TickDir','out', 'Box','off', 'XColor', ink, 'YColor', ink, 'YGrid','on', ...
                'GridColor', [0.85 0.85 0.85], 'GridAlpha', 1);
            if io == 1, title(ax, S.prof{pr}, 'FontWeight','normal'); end
            if pr == 1, ylabel(ax, olc{io,2}); end
            if io == size(olc,1), xlabel(ax, '\tau_p [N m]'); end
            if io == 1 && pr == 1, legend(ax, 'Location','northwest', 'Box','off'); end
        end
    end
    title(tl, sprintf('Ön yükün hareket bedeli (%s taban; 4 açı x 2 yön x 3 tohum ortalaması)', taban), 'FontSize', 12);
    exportgraphics(f, sprintf('b2_bedel_%s.png', char(replace(taban, ["ü" "ı"], ["u" "i"]))), 'Resolution', 130);  close(f);
end
end

function c = hex(h)
c = zeros(numel(h), 3);
for i = 1:numel(h), s = char(h(i));  c(i,:) = sscanf(s(2:end), '%2x%2x%2x')'/255; end
end
