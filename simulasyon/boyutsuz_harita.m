function boyutsuz_harita(seviye)
% BOYUTSUZ_HARITA  Farklı fiziksel düzenekler (uç kütlesi, boşluk, dişli sertliği)
% aynı boyutsuz noktaya düştüğünde aynı sonucu veriyor mu?
%   gamma = mgl*sin(theta0) / (Ks*r)   yerçekimi torku / boşluğu kapatan dişli torku
%   rs    = wc / w_rez,  w_rez = sqrt(Ks/Jeff),  Jeff = JM*JL/(JM+JL)
% Her düzenekte açı ve wc taranır, her nokta (gamma, rs) düzlemine işlenir.
if nargin < 1, seviye = 'ideal'; end
kutle  = [0 20 50 100];          % uç kütlesi [g]
bosluk = [1.5 3 5];              % toplam boşluk [der]
sertlk = [10 30];                % dişli sertliği [N m/rad]
ac  = 0:3:90;                    % 0 tarafı yeterli (90'a göre simetriye yakın; 180 tarafı ayrıca)
rsL = 0.08:0.05:0.48;            % hedef rs değerleri

G = []; RS = []; C = []; ID = [];
id = 0;
for m = kutle
  for b = bosluk
    for K = sertlk
      id = id + 1;
      p = parametreler(seviye);
      mRod = 0.020; L = 0.15; mTip = m/1000;
      p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);
      p.r  = deg2rad(b/2);  p.Ks = K;  p.cs = 0.02*sqrt(K/10);
      Jeff = p.JM*p.JL/(p.JM+p.JL);  wr = sqrt(p.Ks/Jeff);
      wcs = rsL*wr;
      [AC, WC] = meshgrid(ac, wcs);
      c = zeros(size(AC));
      for adim = [1 20]
          p.adim = adim;
          o = kol_benzetim(p, AC(:)', WC(:)');
          c = max(c, reshape(o.sinif, size(AC)));
      end
      g  = p.mgl*sind(AC)/(p.Ks*p.r);
      G  = [G; g(:)];  RS = [RS; WC(:)/wr];  C = [C; c(:)];  ID = [ID; id*ones(numel(c),1)]; %#ok<AGROW>
      fprintf('%2d: m=%3g g, 2r=%g der, Ks=%g -> w_rez=%.0f rad/s, gamma_max=%.2f\n', id, m, b, K, wr, p.mgl/(p.Ks*p.r));
    end
  end
end
save(sprintf('boyutsuz_%s.mat', seviye), 'G', 'RS', 'C', 'ID', 'kutle', 'bosluk', 'sertlk', 'ac', 'rsL');

% Çizim: (gamma, rs) düzleminde sınıflar; boşluk salınımı (2-3) kırmızı
bos = C == 2 | C == 3;
fig = figure('Visible','off','Position',[100 100 900 600]);
semilogx(max(G(~bos),1e-3), RS(~bos), 'o', 'MarkerSize', 4, 'Color', [0.55 0.75 0.65]); hold on;
semilogx(max(G(bos),1e-3),  RS(bos),  'o', 'MarkerSize', 5, 'MarkerFaceColor', [0.80 0.30 0.20], 'MarkerEdgeColor', 'none');
xlabel('\gamma = mgl sin\theta_0 / (K_s r)   (0 değerleri 10^{-3}e çekildi)');
ylabel('r_s = \omega_c / \omega_{rez}');
title(sprintf('Boyutsuz harita, %s model, %d düzenek (kırmızı: boşluk salınımı)', seviye, id));
legend({'boşluk salınımı yok','boşluk salınımı var'}, 'Location','northwest');
grid on;
exportgraphics(fig, sprintf('boyutsuz_%s.png', seviye), 'Resolution', 130);

% Çakışma testi: (gamma, rs) hücrelerine böl, her hücrede düzenekler aynı sonucu mu veriyor?
ge = [0 logspace(-2, 1.5, 15) Inf];
[~,~,gi] = histcounts(G, ge);
[~,~,ri] = histcounts(RS, [rsL-0.025, rsL(end)+0.025]);
hucre = gi*100 + ri;
u = unique(hucre);  tutarli = 0;  karisik = 0;
for h = u'
    s = bos(hucre == h);
    if numel(unique(ID(hucre == h))) < 2, continue; end
    if all(s) || ~any(s), tutarli = tutarli + 1; else, karisik = karisik + 1; end
end
fprintf('\nBirden fazla düzeneğin düştüğü hücreler: %d tutarlı, %d karışık (%.0f%% tutarlı)\n', ...
        tutarli, karisik, 100*tutarli/max(1,tutarli+karisik));
end
