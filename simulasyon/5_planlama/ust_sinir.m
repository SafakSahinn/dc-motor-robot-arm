function ust_sinir
% UST_SINIR  İş sırası (2): yüz KUSURSUZ bilinse 180° düzelir mi? (üst sınır deneyi)
% Motor tarafı P-PI + ofset; ofsetin işareti üç yolla seçilir:
%   tablo   : sign(sin th_ref) (iş sırası 1'deki yöntem, 180'de +1)
%   anlik   : ikizin gerçek temas yüzü sign(delta), her kontrol örneğinde (p.ofsetYuz='anlik')
%   durunca : aynı, ama yalnız kol durgunken güncellenir (p.ofsetYuz='durunca')
% Hedef 175–185° (0,25° adım), kol 1,1° alttan / 1,1° üstten gelir (1° değil: 179°/181° hedefinde
% kol tam 180°'den, boşluk ortasından başlayıp kararsız dengede asılı kalıyordu, yapay durum),
% enkoder ideal / 0,27°, sürtünmeli (Fc 0,04 Fs 0,06) ve sürtünmesiz. Kaydedilen: son 1 s
% ortalama sapma e, son 1 s en büyük |e|, son temas yüzü, yüz seçiminin değişim sayısı
% (tüm süre / son 6 s = "avlanma"), sınıf (rejim_sinifla), 180° hedefinin zaman serisi.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = 6;
ac = 175:0.25:185;  kpv = 0.50^2*p0.Ks/p0.KV;  th = deg2rad(ac);
sT = sign(sin(th));  sT(ac == 180) = 1;
yon = {'alttan', 1.1; 'üstten', -1.1};
enk = {'ideal', 0; '0,27°', 2*pi/1320};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
yt  = {'tablo', ''; 'anlik', 'anlik'; 'durunca', 'durunca'};
i180 = find(ac == 180);
fid = fopen('ust_sinir_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== ust_sinir, %s, D, r_gs 0,50, r %.2f°, mgl %.3f N m, Ks %.2f N m/rad\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), p0.mgl, p0.Ks);
yaz('Hedef 175–185° (0,25°), kol ±1,1° uzaktan gelir. e = son 1 s ortalama sapma [°], emax = son 1 s en büyük |sapma|\n');
yaz('yüz = son temas yüzü (0: boşlukta), deg/avl = yüz seçimi değişimi tüm süre / son 6 s (avlanma)\n');
R = struct([]);
for a = 1:size(sur,1)
 for q = 1:size(enk,1)
  for y = 1:size(yon,1)
   for m = 1:size(yt,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};  p.qM = enk{q,2};  p.adim = yon{y,2};
    if isempty(yt{m,2})
        p.ofset = sT*p0.r + p0.mgl*sin(th)/p0.Ks;
    else
        p.ofsetYuz = yt{m,2};
    end
    o = kol_benzetim(p, ac, kpv*ones(size(ac)));
    sap = rad2deg(o.th) - ac;
    rs = rejim_sinifla(o.t, sap, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    son = o.t > o.t(end)-1;
    dl = mean(o.delta(son,:), 1);  yuz = sign(dl).*(abs(dl) >= 0.999*p0.r);
    k = numel(R) + 1;
    R(k).sur = sur{a,1};  R(k).enk = enk{q,1};  R(k).yon = yon{y,1};  R(k).yontem = yt{m,1};
    R(k).e = mean(sap(son,:), 1);  R(k).emax = max(abs(sap(son,:)), [], 1);
    R(k).yuz = yuz;  R(k).sinif = rs.sinif;
    if isfield(o, 'yuzDegis'), R(k).deg = o.yuzDegis;  R(k).avl = o.yuzDegisAn;
    else, R(k).deg = zeros(size(ac));  R(k).avl = R(k).deg; end
    R(k).iz = struct('t', o.t, 'th', rad2deg(o.th(:,i180)), 'delta', rad2deg(o.delta(:,i180)), 'u', o.u(:,i180));
   end
  end
 end
end
save('ust_sinir.mat', 'R', 'ac');

% --- Özet: her koşu türü için ---
bant = abs(ac - 180) <= 1 & ac ~= 180;
yaz('\n%-11s %-6s %-7s %-8s | 180°: e     emax  yüz deg/avl | 179–181 (180 hariç): en kötü |e|, emax | 175–185 en kötü |e| | avlanan açı | salınımlı\n', ...
    'sürtünme','enk','yön','yöntem');
for k = 1:numel(R)
    yaz('%-11s %-6s %-7s %-8s |      %+6.2f %5.2f %+d %3d/%-3d | %6.2f %6.2f | %6.2f | %2d | %d\n', R(k).sur, R(k).enk, ...
        R(k).yon, R(k).yontem, R(k).e(i180), R(k).emax(i180), R(k).yuz(i180), R(k).deg(i180), R(k).avl(i180), ...
        max(abs(R(k).e(bant))), max(R(k).emax(bant)), max(abs(R(k).e)), nnz(R(k).avl > 0), ...
        nnz(ismember(R(k).sinif, [3 4 5])));
end

% --- Ayrıntı: 178,5–181,5°, açı açı (dışında üç yöntem aynı yüzü seçiyor) ---
for a = 1:size(sur,1)
 for q = 1:size(enk,1)
    yaz('\nAyrıntı (%s, %s enkoder). Hücre: e[°] emax yüz deg/avl\n', sur{a,1}, enk{q,1});
    sec = find(strcmp({R.sur},sur{a,1}) & strcmp({R.enk},enk{q,1}));
    yaz('  açı   | %s\n', strjoin(arrayfun(@(k) sprintf('%-24s', [R(k).yon ' ' R(k).yontem]), sec, 'uni', 0), ' '));
    for j = find(abs(ac - 180) <= 1.5)
        h = arrayfun(@(k) sprintf('%-24s', sprintf('%+5.2f %4.2f %+d %d/%d', R(k).e(j), R(k).emax(j), R(k).yuz(j), ...
            R(k).deg(j), R(k).avl(j))), sec, 'uni', 0);
        yaz('  %6.2f | %s\n', ac(j), strjoin(h, ' '));
    end
 end
end
fclose(fid);
end
