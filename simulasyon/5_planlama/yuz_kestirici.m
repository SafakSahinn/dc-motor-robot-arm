function yuz_kestirici
% YUZ_KESTIRICI  İş sırası (3): yalnız motor sinyalleriyle (enkoder + u) yüz kestirici.
% Motor tarafı P-PI + ofset = s*r + mgl sin(th)/Ks; s'yi seçen yöntemler:
%   tablo      : s = sign(sin th_hedef) sabit (iş sırası 1)
%   ust_sinir  : ikizin gerçek yüzü, anlık, basamak (p.ofsetYuz='anlik'; HİLE, yalnız referans)
%   edilgen    : motor durgunken s = sign(u)
%   olay       : tork gözlemcisi, sürtünme aralığını aşan dişli torku (çarpma ya da tork aktaran hareket)
%   yoklama    : motor oturunca inanılan boşluğa küçük tork itişi (1 s'de bir tekrar)
%   olay+yok   : ikisi birlikte (yoklama: oturunca bir kez + her yüz değişiminden sonra)
%   olay+yok/p : aynı, ayrıca bant içinde motor oturdukça 2 s'de bir yoklama (sessiz konmalara karşı)
%   olay+yok/b : olay+yok, ofset değişimi basamak (rampa yok), rampa ile karşılaştırma için
% İstekler 179, 179,25, 179,75, 180, 180,25, 180,75, 181°; |istek - 180| < 0,5° ise hedef kaydırma
% kuralı (kolun geldiği tarafa göre 179,5 / 180,5). Kol hedefe ±1,1° uzaktan, iki yönden gelir.
% Bozucu: yok | t = 3 s'de kola 180°'ye doğru yük darbesi (0,05 N m, 20 ms yarım sinüs) | yanlış
% başlangıç yüzü. Enkoder ideal / 0,017° (0,27°/16) / 0,27° / AS5600 motor milinde (12 bit x N = 30,
% kol tarafında 0,0029°; zamanlama ve gürültü yuz_kestirici_as5600.m'de); sürtünmeli (Fc 0,04 Fs 0,06) ve sürtünmesiz.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;

% --- Senaryo listesi (her biri bir benzetim sütunu) ---
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);            % istek x yön (+1 alttan) x bozucu
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;
hedef(kay) = 180 - eps_*Y(kay);                    % alttan gelen 179,5'te, üstten gelen 180,5'te durur
s0 = sign(sind(hedef));                            % doğru yüz (ve başlangıç yüzü)
yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);             % kolu 180°'ye doğru iten darbe
n = numel(hedef);  ac = hedef;  th = deg2rad(ac);
bozAd = {'yok', 'darbe', 'yanlış s0'};

yt  = {'tablo', 'ust_sinir', 'edilgen', 'olay', 'yoklama', 'olay+yok', 'olay+yok/p', 'olay+yok/b'};
enk = {'ideal', 0; '0,017°', 2*pi/1320/16; '0,27°', 2*pi/1320; 'AS5600', 2*pi/(4096*30)};  % AS5600 motor milinde: kol tarafında 0,0029°
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
fid = fopen('yuz_kestirici_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== yuz_kestirici, %s, D, r_gs 0,50, r %.2f°, mgl %.3f N m, eps %.2f°\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), p0.mgl, eps_);
yaz('%d senaryo/koşu: istek %s x yön (alttan/üstten, ±1,1°) x bozucu (yok / t=%g s darbe 0,05 N m 20 ms / yanlış başlangıç yüzü)\n', ...
    n, mat2str(istek), tD);
yaz('e = son 1 s ortalama sapma, KAYDIRILMIŞ hedefe göre [°]. H7: |e| <= 0,5, son 1 s en büyük |sapma| <= 1 (avlanmıyor)\n');
yaz('     ve son yüz doğru (son 1 s temas örneklerinin çoğunluğu).\n');
yaz('B12: kol temastayken s^ = gerçek yüz oranı (t >= 0,5 s). yakala: son |e| > 0,5° anı - olay anı (darbe: 3 s, diğer: 0) [s], yalnız\n');
yaz('      yanlış yüze düşülen koşular. avl: son 3 s yüz seçimi değişimi (en çok). B13: yoklama sırasında + 0,3 s kol hareketi (en çok) [°],\n');
yaz('      darbeli senaryolar hariç (darbe yoklama penceresine denk gelince kolu darbe oynatıyor, yoklama değil).\n');
R = struct([]);
for a = 1:size(sur,1)
 for q = 1:size(enk,1)
  for m = 1:numel(yt)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};  p.qM = enk{q,2};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;
    switch yt{m}
        case 'tablo',      p.ofset = yuz0*p.r + p.mgl*sin(th)/p.Ks;
        case 'ust_sinir',  p.ofsetYuz = 'anlik';  p.yuz0 = yuz0;
        case 'edilgen',    p.yuzKes = 'edilgen';  p.yuz0 = yuz0;
        case 'olay',       p.yuzKes = 'olay';  p.yuz0 = yuz0;
        case 'yoklama',    p.yuzKes = 'yoklama';  p.yuz0 = yuz0;  p.yokPer = 1;  p.yokMaks = Inf;
        case 'olay+yok',   p.yuzKes = 'olay+yoklama';  p.yuz0 = yuz0;
        case 'olay+yok/p', p.yuzKes = 'olay+yoklama';  p.yuz0 = yuz0;  p.yokPer = 2;  p.yokMaks = Inf;
        case 'olay+yok/b', p.yuzKes = 'olay+yoklama';  p.yuz0 = yuz0;  p.yuzRampa = 0;
    end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;
    son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p0.r);   % gerçek temas yüzü (0: boşlukta)
    yuzS = sign(sum(gy(son,:), 1));               % son 1 s temas örneklerinin çoğunluğu (yoklama motoru kısa süre boşluğa alır)
    yanlisOldu = any(gy ~= 0 & gy ~= s0 & o.t >= 0.5, 1);
    k = numel(R) + 1;
    R(k).sur = sur{a,1};  R(k).enk = enk{q,1};  R(k).yontem = yt{m};
    R(k).e = mean(sap(son,:), 1);  R(k).emax = max(abs(sap(son,:)), [], 1);
    R(k).yuz = yuzS;  R(k).h7 = abs(R(k).e) <= 0.5 & R(k).emax <= 1 & yuzS == s0;
    R(k).yanlisOldu = yanlisOldu;
    tOlay = tD*(B == 2);
    yak = nan(1,n);
    for j = 1:n
        kotu = find(abs(sap(:,j)) > 0.5 & o.t >= tOlay(j), 1, 'last');
        if yanlisOldu(j)
            if isempty(kotu), yak(j) = 0; elseif kotu == numel(o.t), yak(j) = Inf;
            else, yak(j) = o.t(kotu) - tOlay(j); end
        end
    end
    R(k).yakala = yak;
    if isfield(o, 'shat')
        tm = gy ~= 0 & o.t >= 0.5;
        R(k).b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
        s3 = o.t > o.t(end) - 3;
        R(k).avl = sum(abs(diff(o.shat(s3,:))) > 0, 1);
    elseif isfield(o, 'yuzDegis')
        R(k).b12 = nan(1,n);  R(k).avl = o.yuzDegisAn;   % üst sınır: yüz zaten gerçek (Tan = T: tüm süre)
    else
        R(k).b12 = nan(1,n);  R(k).avl = zeros(1,n);
    end
    if isfield(o, 'yokKol'), R(k).b13 = rad2deg(o.yokKol);  R(k).b13(B == 2) = NaN;  R(k).yokSay = o.yokSay;
    else, R(k).b13 = nan(1,n);  R(k).yokSay = zeros(1,n); end
    fprintf('.');
  end
 end
end
fprintf('\n');
save('yuz_kestirici.mat', 'R', 'ac', 'hedef', 'istek', 'I', 'Y', 'B', 's0', 'yuz0');

% --- Özet ---
yaz('\n%-11s %-6s %-11s | H7 geçen | en kötü |e| | yanlış yüze düşen | yakala ort/en çok [s] | B12 ort/en kötü | avl | B13 en çok\n', ...
    'sürtünme', 'enk', 'yöntem');
for k = 1:numel(R)
    y = R(k).yakala(~isnan(R(k).yakala));
    if isempty(y), ys = '      -      ';
    elseif any(isinf(y)), ys = sprintf('%d tutmadı   ', nnz(isinf(y)));
    else, ys = sprintf('%5.2f / %5.2f', mean(y), max(y)); end
    if all(isnan(R(k).b12)), bs = '      -     '; else, bs = sprintf('%5.3f/%5.3f', mean(R(k).b12), min(R(k).b12)); end
    if all(isnan(R(k).b13)), b13 = '  -  '; else, b13 = sprintf('%5.2f', max(R(k).b13, [], 'omitnan')); end
    yaz('%-11s %-6s %-11s | %2d/%2d    | %6.2f      | %2d                | %s         | %s     | %3d | %s\n', ...
        R(k).sur, R(k).enk, R(k).yontem, nnz(R(k).h7), n, max(abs(R(k).e)), nnz(R(k).yanlisOldu), ys, bs, max(R(k).avl), b13);
end

% --- Bozucu türüne göre H7 (olay+yok ve edilgen, tablo) ---
yaz('\nBozucu türüne göre H7 geçen (her tür %d senaryo):\n', n/3);
for k = 1:numel(R)
    h = arrayfun(@(b) sprintf('%s %2d', bozAd{b}, nnz(R(k).h7(B == b))), 1:3, 'uni', 0);
    yaz('  %-11s %-6s %-11s | %s\n', R(k).sur, R(k).enk, R(k).yontem, strjoin(h, ' | '));
end

% --- H7'yi geçemeyen koşular (tablo ve üst sınır dışında) ---
yaz('\nGeçemeyenler (yöntem: istek/hedef/yön/bozucu e):\n');
for k = 1:numel(R)
    if any(strcmp(R(k).yontem, {'tablo'})), continue; end
    j = find(~R(k).h7);
    if isempty(j), continue; end
    h = arrayfun(@(jj) sprintf('%.2f>%.1f %s %s %+.2f', I(jj), hedef(jj), char('a' + (Y(jj) < 0)*('u'-'a')), ...
        bozAd{B(jj)}, R(k).e(jj)), j, 'uni', 0);
    yaz('  %s %s %s: %s\n', R(k).sur, R(k).enk, R(k).yontem, strjoin(h, '; '));
end
fclose(fid);
end
