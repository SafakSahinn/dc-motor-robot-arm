function T = duyarlilik(grup)
% DUYARLILIK  Boşluk salınımı bandının parametrelere duyarlılığı (gerçekçi model).
%   grup: 'kutle' | 'bosluk' | 'sertlik'
% Her parametre değeri için, 0-40 ve 140-180 derece arası 1 derece adımla,
% üç kapalı çevrim hızında boşluk salınımının (sınıf 2-3) sürdüğü bant bulunur.
% Ayrıca boşluksuz (r = 0) aynı sistem 90 derecede denenir: orada salınım varsa
% döngünün kendisi doğrusal olarak kararsızdır ve bant sonucu anlamsızdır.
ac  = [0:1:40, 140:1:180];
wcs = [20 35 45];
switch grup
    case 'kutle',   ad = 'uç kütlesi [g]';     deg = [0 20 50 100];
    case 'bosluk',  ad = 'toplam boşluk [der]'; deg = [0.5 1.5 3 5];
    case 'sertlik', ad = 'dişli sertliği [N m/rad]'; deg = [3 10 30];
end
[AC, WC] = meshgrid(ac, wcs);
T = table();
for v = deg
    p = parametreler('gercekci');
    p = ayarla(p, grup, v);
    bos = false(size(AC));
    for adim = [1 20]
        p.adim = adim;
        o = kol_benzetim(p, AC(:)', WC(:)');
        c = reshape(o.sinif, size(AC));
        bos = bos | c == 2 | c == 3;
    end
    pl = ayarla(parametreler('ideal'), grup, v);  pl.r = 0;  pl.adim = 5;  % doğrusal kararlılık: sürtünmesiz, boşluksuz
    ol = kol_benzetim(pl, 90*ones(size(wcs)), wcs);
    for i = 1:numel(wcs)
        a0 = ac(ac <= 40 & bos(i,:));  a1 = ac(ac >= 140 & bos(i,:));
        u0 = NaN; if ~isempty(a0), u0 = max(a0); end
        u1 = NaN; if ~isempty(a1), u1 = 180 - min(a1); end
        dk = ol.A_deg(i) > 0.05;                       % boşluksuz, sürtünmesiz sistemde salınım = döngü kararsız
        T = [T; table(v, wcs(i), u0, u1, p.mgl, dk, 'VariableNames', ...
             {'deger','wc','bant0','bant180','mgl','dogrusal_salinim'})]; %#ok<AGROW>
    end
    fprintf('%s = %g bitti\n', ad, v);
end
disp(ad); disp(T);
save(sprintf('duyarlilik_%s.mat', grup), 'T', 'ad', 'grup');
end

function p = ayarla(p, grup, v)
switch grup
    case 'kutle'
        mRod = 0.020; L = 0.15; mTip = v/1000;
        p.JL  = mRod*L^2/3 + mTip*L^2;
        p.mgl = 9.81*(mRod*L/2 + mTip*L);
    case 'bosluk'
        p.r = deg2rad(v/2);
    case 'sertlik'
        p.Ks = v;  p.cs = 0.02*sqrt(v/10);       % sönüm oranını yaklaşık sabit tut
end
end
