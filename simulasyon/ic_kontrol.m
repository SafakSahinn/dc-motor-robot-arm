% IC_KONTROL  Başlangıç sapmasına duyarlılık: aynı parametrelerde hem denge
% hem limit cycle var mı (iki kararlılık)?
ac = [0 5 10 15 20 30 45 60 90];
for adim = [1 5 20]
  for wc = [20 40]
    p = parametreler(); p.adim = adim;
    o = kol_benzetim(p, ac, wc*ones(size(ac)));
    fprintf('adim=%2d wc=%2d  A: %s\n', adim, wc, sprintf('%6.2f', o.A_deg));
  end
end
fprintf('acilar:          %s\n', sprintf('%6g', ac));
