function zorlanmis_cevap
% ZORLANMIS_CEVAP  Yerçekimli düzenekte (D) zorlanmış cevap ve rejim ayrımı (rejim_sinifla, f_z ile):
%  1) 90°, küçük bozucu (ön yük temas kopmasını önler)     -> doğrusal zorlanmış cevap
%  2) 90°, ön yükü aşan bozucu (temas kopar)                -> boşluklu zorlanmış cevap
%  3) 0°, aynı küçük bozucu (çevrim zaten var)              -> çevrim bozucudan ayrılmalı
%  4) iki kararlılık: 90°, tork sınırsız, DF'nin iki kararlılık öngördüğü kazançta bozucu
%     3 s uygulanıp kesilir; küçük bozucuda dengeye, büyükte kalıcı çevrime dönmeli.
% Kayıt: zorlanmis_cevap_log.txt
addpath(fileparts(fileparts(mfilename('fullpath'))));
p = secenek_duzenek('D');  wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
p.T = 10;  p.Tan = 10;  p.adim = 0.2;
kp = @(rg) rg^2*p.Ks/p.KV;
fid = fopen('zorlanmis_cevap_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('D: mgl = %.3f N m, gamma(90°) = %.2f, Tmax = %.2f N m\n', p.mgl, p.mgl/(p.Ks*p.r), p.Tmax);
% 1-3: bozucu sürekli
D = {90, 0.6, 0.03, 3, '1) 90°, küçük bozucu'
     90, 0.6, 0.30, 3, '2) 90°, ön yükü aşan bozucu'
      0, 0.6, 0.03, 3, '3) 0°, küçük bozucu (çevrim bölgesi)'
      0, 0.6, 0,    3, '3b) 0°, bozucusuz'
      0, 0.9, 0.03, 3, '3c) 0°, güçlü çevrim + küçük bozucu'
      0, 0.9, 0.03, 4.5, '3e) 3c, bozucu 4,5 Hz (harmonik çevrimden uzak)'
      0, 0.9, 0,    3, '3d) 0°, güçlü çevrim, bozucusuz'};
for i = 1:size(D,1)
    q = p;  q.dA = D{i,3};  q.df = D{i,4};
    o = kol_benzetim(q, D{i,1}, kp(D{i,2}));
    r = rejim_sinifla(o.t, rad2deg(o.th) - D{i,1}, struct('A_min',0.05,'A_max',30,'T_at',2,'f_z',q.df));
    yaz('%-40s r_gs %.2f, bozucu %.2f N m @ %g Hz: %s, genlik %.3f°, f %.2f Hz, zorlama payı %.2f, boşlukta geçen süre %%%.0f\n', ...
        D{i,5}, D{i,2}, q.dA, q.df, r.ad{1}, r.A, r.f, r.zpay, 100*o.bosluk_orani);
end
% 4: iki kararlılık. DF (tork sınırsız) bu kazançta çevrim ve eşik genliği öngörüyor.
for rg = [0.88 0.95 1.0]
    q = p;  q.Tmax = Inf;
    d = yercekimli_df(q, 90, kp(rg));
    yaz('4) iki kararlılık, 90°, r_gs %.2f, tork sınırsız. DF: %s, f %.2f Hz, eşik a1 = %.2f r, çevrim a2 = %.2f r\n', ...
        rg, d.sinif, d.f, d.a1, d.a2);
    for dA = [0 0.02 0.05 0.1 0.2 0.4]
        q.dA = dA;  q.df = d.f;  q.dT = 3;
        o = kol_benzetim(q, 90, kp(rg));
        r = rejim_sinifla(o.t, rad2deg(o.th) - 90, struct('A_min',0.05,'A_max',30,'T_at',4));
        yaz('   bozucu %.2f N m @ %.2f Hz, 3 s sonra kesildi -> %s (genlik %.2f°, f %.2f Hz)\n', dA, q.df, r.ad{1}, r.A, r.f);
    end
end
fclose(fid);
end
