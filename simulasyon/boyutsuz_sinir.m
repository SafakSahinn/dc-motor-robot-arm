function boyutsuz_sinir(seviye)
% BOYUTSUZ_SINIR  boyutsuz_harita çıktısından her düzenek ve her rs için
% 0 dereceden başlayan kesintisiz boşluk salınımı bandının bittiği gamma
% değerini (gamma_sinir) bulur; düzenekler arası dağılımı raporlar ve çizer.
if nargin < 1, seviye = 'ideal'; end
S = load(sprintf('boyutsuz_%s.mat', seviye));
bos = S.C == 2 | S.C == 3;
na = numel(S.ac);  nr = numel(S.rsL);  nd = max(S.ID);
gs = nan(nd, nr);  gmax = nan(nd,1);
for d = 1:nd
    k = find(S.ID == d);                    % bu düzeneğin noktaları (meshgrid: rs satır, açı sütun)
    B = reshape(bos(k), nr, na);  Gm = reshape(S.G(k), nr, na);
    gmax(d) = max(Gm(:));
    for i = 1:nr
        j = find(~B(i,:), 1);               % ilk salınımsız açı
        if isempty(j), gs(d,i) = Inf;       % taranan tüm açılarda salınım
        elseif j == 1, gs(d,i) = 0;         % 0 derecede bile yok
        else, gs(d,i) = Gm(i, j-1);
        end
    end
end
fprintf('\n[%s] gamma_sinir: düzenekler arası dağılım (Inf = 90 dereceye kadar salınım)\n', seviye);
fprintf('%6s %9s %9s %9s %9s   %s\n','rs','min','medyan','max','max/min','sonlu duzenek sayisi');
for i = 1:nr
    g = gs(:,i);  f = g(isfinite(g) & g > 0);
    if isempty(f), fprintf('%6.2f %9s\n', S.rsL(i), '-'); continue; end
    fprintf('%6.2f %9.3f %9.3f %9.3f %9.1f   %d/%d (Inf: %d, 0: %d)\n', S.rsL(i), min(f), median(f), max(f), ...
            max(f)/min(f), numel(f), nd, sum(isinf(g)), sum(g==0));
end

fig = figure('Visible','off','Position',[100 100 900 600]);
renk = lines(4);  isim = {};
for d = 1:nd
    mi = find(S.kutle == kutleOf(d, S));
    g = gs(d,:);  g(isinf(g)) = gmax(d);  g(g==0) = NaN;
    semilogx(g, S.rsL, '-o', 'Color', renk(mi,:), 'MarkerSize', 4); hold on;
end
for mi = 1:numel(S.kutle), h(mi) = plot(NaN,NaN,'-o','Color',renk(mi,:)); isim{mi} = sprintf('uç kütlesi %g g', S.kutle(mi)); end %#ok<AGROW>
legend(h, isim, 'Location', 'northwest');
xlabel('\gamma_{sınır}  (bandın bittiği \gamma = mgl sin\theta_0 / (K_s r))', 'Interpreter', 'tex');
ylabel('r_s = \omega_c / \omega_{rez}');
title(sprintf('Boşluk salınımı sınırı, %s model, %d düzenek', seviye, nd));
grid on;
exportgraphics(fig, sprintf('boyutsuz_sinir_%s.png', seviye), 'Resolution', 130);
end

function m = kutleOf(d, S)
% düzenek sırası: kütle > boşluk > sertlik (boyutsuz_harita ile aynı döngü)
nb = numel(S.bosluk)*numel(S.sertlk);
m = S.kutle(ceil(d/nb));
end
