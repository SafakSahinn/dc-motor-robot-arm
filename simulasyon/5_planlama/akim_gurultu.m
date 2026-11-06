function akim_gurultu
% AKIM_GURULTU  İş sırası (5), ilk adım: gözlemcinin gördüğü tork INA228 ölçümünden gelirse.
% Şimdiye kadar tork gözlemcisi uygulanan torku (komut u) hatasız görüyordu. Donanımda tork
% k_t * i, i Adafruit INA228'den (15 mΩ şant, I²C-0). Burada gözlemcinin girdisi:
%   tKaz * ort(gerçek tork, dönüşüm penceresi tPen, tGec önce biten) + tOfs + tGur*randn
% Ayrıca p.akimW: tesise uygulanan torkun komutu birinci derece izlemesi (mod 3 akım döngüsü).
% Koşul duyarlilik.m ile aynı (1 kHz, AS5600 motor milinde, gM 0,4 ms, nM, ayarlı olay+yoklama).
% Her satırda tek bir büyüklük değişir; gerçekçi taban: tPen 0,54 ms, tGec 0,1 ms, akim 500 Hz.
% Sayılar (veri sayfası, TI SBOSA20): dönüşüm 50 µs - 4,12 ms; ofset ≤ ±1 µV (15 mΩ'da 67 µA);
% kazanç hatası ≤ ±%0,05. Gürültü veri sayfasında yalnız grafikte: TARANIYOR, doğrulanmadı.
% k_t kol tarafında K_m = 12 V / 333 rpm = 0,344 N m/A (sim_param'daki eşdeğer motor).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
Km = 12/(333*2*pi/60);                             % kol tarafı N m/A

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

ger = struct('tOlc', true, 'tPen', 0.54e-3, 'tGec', 0.1e-3, 'akimW', 2*pi*500);   % gerçekçi taban
% {ad, alanlar (struct)}: ger'in üstüne yazılır; 'kapalı' satırı eski davranış
kos = {'kapalı (u)', struct('tOlc', false);
       'açık, hatasız', struct('tOlc', true)};
kos(end+1,:) = {'INA228 taban', struct()};
for g = [1e-3 3e-3 0.01 0.02 0.03 0.05]
    kos(end+1,:) = {sprintf('gürültü %.3f', g), struct('tGur', g)};
end
for d = [1 2 5]*1e-3
    kos(end+1,:) = {sprintf('gecikme %.0f ms', d*1e3), struct('tGec', d)};
end
for w = [4.2 16.8]*1e-3
    kos(end+1,:) = {sprintf('pencere %.1f ms', w*1e3), struct('tPen', w)};
end
for f = [100 50]
    kos(end+1,:) = {sprintf('akım bandı %d Hz', f), struct('akimW', 2*pi*f)};
end
for o = [-0.02 -0.01 -0.005 0.005 0.01 0.02]
    kos(end+1,:) = {sprintf('ofset %+.3f', o), struct('tOfs', o)};
end
for k = [0.8 0.9 1.1 1.2]
    kos(end+1,:) = {sprintf('kazanç x%.1f', k), struct('tKaz', k)};
end
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
fid = fopen('akim_gurultu_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== akim_gurultu, %s, D, r_gs 0,50, r %.2f°, k_t (kol tarafı) %.3f N m/A\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), Km);
yaz('1 kHz, AS5600 motor milinde, gecikme 0,4 ms, gürültü 0,043° RMS (motor), olay+yoklama ayarlı (yokOrta 0,6, vDurF 10 Hz)\n');
yaz('Taban: gözlemci torku INA228''den (pencere 0,54 ms, okuma gecikmesi 0,1 ms), akım döngüsü 500 Hz; satırlar tabandan tek değişiklik.\n');
yaz('Ölçek: 0,001 N m = %.1f mA; veri sayfası ofseti 1 µV / 15 mΩ = 67 µA = %.1e N m; kazanç ±%%0,05.\n', 1e-3/Km*1e3, 67e-6*Km);
yaz('42 senaryo; H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (B12). B13: yoklama + 0,3 s kol hareketi (darbesiz).\n\n');
yaz('%-11s %-17s | H7 geçen | B12 son yüz | en kötü |e| | ort |e| | B13 en çok | yoklama ort | temas ort\n', 'sürtünme', 'satır');
for a = 1:size(sur,1)
 for c = 1:size(kos,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    if c > 2, ek = ger; else, ek = struct(); end
    for ad = fieldnames(kos{c,2})', ek.(ad{1}) = kos{c,2}.(ad{1}); end
    for ad = fieldnames(ek)', p.(ad{1}) = ek.(ad{1}); end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    b12 = yuzS == s0;
    h7 = abs(e) <= 0.5 & emax <= 1 & b12;
    b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
    yaz('%-11s %-17s | %2d/%2d    | %2d/%2d       | %6.2f      | %5.2f   | %5.2f      | %4.1f        | %4.1f\n', ...
        sur{a,1}, kos{c,1}, nnz(h7), n, nnz(b12), n, max(abs(e)), mean(abs(e)), max(b13, [], 'omitnan'), ...
        mean(o.yokSay), mean(o.yokTemas));
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
