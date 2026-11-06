function hiz_gozlemci
% HIZ_GOZLEMCI  Kontrolcünün hız terimi ideal motor hızı yerine gözlemcinin w^'si olursa (p.vKaynak).
% Şimdiye kadarki 42 senaryo sonuçlarında p.fv = Inf: P-PI motor hızını HATASIZ görüyordu. Donanımda
% hız tork gözlemcisinden gelecek (mimari.md §4.1, kartta kontrol::HIZ_GOZLEMCI).
% Kurulum akim_gurultu.m'nin "INA228 taban" satırı (1 kHz, AS5600 motor milinde, gM 0,4 ms,
% nM 0,043°, olay+yoklama, yokOrta 0,6, vDurF 10 Hz, gözlemci torku INA228: tPen 0,54 ms,
% tGec 0,1 ms, akım döngüsü 500 Hz). Kazançlar (KV, KI, kp = 0,50²·Ks/KV) değişmez.
% Satırlar: ideal hız (eski sonuç, karşılaştırma) | w^ (gozW 40 Hz, taban) | bilgi için gozW
% 20 / 30 / 50 / 80 Hz, her biri ideal hızla ve w^ ile (gozW yüz kestiriciyi de değiştirir:
% yokTmin = 3/gozW, d^ bandı; ideal hızlı satır bu etkiyi hız kaynağından ayırır).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;   % INA228 taban
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
bozAd = {'yok', 'darbe', 'yanlış s0'};

% {ad, alanlar}: p0'ın üstüne yazılır
kos = {'ideal hız',        struct('vKaynak', 'olcum');
       'w^ (gozW 40 Hz)',  struct('vKaynak', 'gozlemci')};
for f = [20 30 50 80]     % gozW payı; ideal hızlı satır, bozulmanın hızdan mı kestiriciden mi geldiğini ayırır
    kos(end+1,:) = {sprintf('ideal (gozW %d)', f), struct('vKaynak', 'olcum', 'gozW', 2*pi*f)};
    kos(end+1,:) = {sprintf('w^ (gozW %d Hz)', f), struct('vKaynak', 'gozlemci', 'gozW', 2*pi*f)};
end
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
fid = fopen('hiz_gozlemci_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== hiz_gozlemci, %s, D, r_gs 0,50, r %.2f°\n', datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r));
yaz('Kurulum akim_gurultu "INA228 taban" (1 kHz, AS5600 motor milinde 0,4 ms / 0,043°, olay+yoklama yokOrta 0,6 vDurF 10 Hz,\n');
yaz('gözlemci torku INA228 0,54 ms + 0,1 ms, akım döngüsü 500 Hz). Kazançlar aynı. Satır: kontrolcünün hız kaynağı.\n');
yaz('42 senaryo; H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (B12). B13: yoklama + 0,3 s kol hareketi (darbesiz).\n');
yaz('u RMS / |u| doyumda: son 1 s, tüm senaryolar (hız gürültüsünün torka yansıması).\n\n');
yaz('%-11s %-17s | H7 geçen | B12 son yüz | en kötü |e| | ort |e| | en büyük | B13 en çok | yoklama ort | temas ort | u RMS son 1 s | doyum %%\n', 'sürtünme', 'satır');
for a = 1:size(sur,1)
 for c = 1:size(kos,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    for ad = fieldnames(kos{c,2})', p.(ad{1}) = kos{c,2}.(ad{1}); end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    b12 = yuzS == s0;
    h7 = abs(e) <= 0.5 & emax <= 1 & b12;
    b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
    us = o.u(son,:);
    yaz('%-11s %-17s | %2d/%2d    | %2d/%2d       | %6.2f      | %5.2f   | %5.2f    | %5.2f      | %4.1f        | %4.1f      | %.4f         | %.2f\n', ...
        sur{a,1}, kos{c,1}, nnz(h7), n, nnz(b12), n, max(abs(e)), mean(abs(e)), max(emax), ...
        max(b13, [], 'omitnan'), mean(o.yokSay), mean(o.yokTemas), sqrt(mean(us(:).^2)), ...
        100*mean(abs(us(:)) >= p.Tmax - 1e-9));
    j = find(~h7);
    if ~isempty(j)
        h = arrayfun(@(jj) sprintf('%.2f>%.1f %s %s %+.2f/%.2f', I(jj), hedef(jj), char('a' + (Y(jj) < 0)*('u'-'a')), ...
            bozAd{B(jj)}, e(jj), emax(jj)), j, 'uni', 0);
        yaz('      geçemeyen (e/en büyük): %s\n', strjoin(h, '; '));
    end
    fprintf('.');
 end
end
fprintf('\n');
fclose(fid);
end
