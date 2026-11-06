function duyarlilik
% DUYARLILIK  İş sırası (4): yük (mgl) ve model parametresi hatasına duyarlılık.
% Gerçekçi koşul: kontrol ve kestirici 1 kHz, AS5600 motor milinde (kol tarafında 0,0029°),
% 0,4 ms ölçüm gecikmesi, 0,043° RMS gürültü (motor milinde), ayarlı olay+yoklama (yokOrta 0,6,
% vDurF 10 Hz, rampa 0,5 s). 42 senaryo yuz_kestirici.m ile aynı.
% Her satırda tek bir büyüklük değişir (öbürleri nominal):
%   ikizin gerçeği değişir, kestirici/ofset nominali bilir : mgl, K_s, r (±%20)
%   ikiz nominal, gözlemcinin bildiği değer yanlış          : F_c, F_s, J_M, b_M (±%20, ±%50)
% Kontrolcü kazançları (K_V, K_I, k_p) her satırda nominal değerlerden. mgl değişirken J_L sabit
% tutulur (yalnız yerçekimi torku değişir). F_c, F_s satırları yalnız sürtünmeli ikizde.
% Ölçüt: H7 (son 1 s |e| <= 0,5° kaydırılmış hedefe, en büyük <= 1°, son yüz doğru = B12) ve B13
% (yoklama + 0,3 s kol hareketi <= 0,5°, darbesiz senaryolar).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
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

% {ad, alan, çarpan, tür}: tür 'ikiz' = ikizin gerçeği değişir (kestirici nominali bilir), 'bilinen' = kestiricinin bildiği
kos = {'nominal', '', 1, ''};
for k = [0.8 1.2]
    kos(end+1,:) = {sprintf('mgl x%.1f', k), 'mgl', k, 'ikiz'};
end
for k = [0.8 1.2]
    kos(end+1,:) = {sprintf('K_s x%.1f', k), 'Ks', k, 'ikiz'};
end
for k = [0.8 0.9 0.95 1.05 1.1 1.2]
    kos(end+1,:) = {sprintf('r x%.2f', k), 'r', k, 'ikiz'};
end
kat = struct('Fc', [0.5 0.8 1.1 1.2 1.3 1.5], 'Fs', [0.5 0.8 1.2 1.5], ...
             'JM', [0.5 0.6 0.7 0.8 1.2 1.3 1.5], 'bM', [0.5 0.8 1.2 1.5]);   % ince adımlar: kırılma eşiği
for ad = {'Fc', 'Fs', 'JM', 'bM'}
    for k = kat.(ad{1})
        kos(end+1,:) = {sprintf('%s^ x%.1f', ad{1}, k), ad{1}, k, 'bilinen'};
    end
end
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
fid = fopen('duyarlilik_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== duyarlilik, %s, D, r_gs 0,50, r %.2f°, mgl %.3f N m, K_s %.1f N m/rad\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), p0.mgl, p0.Ks);
yaz('1 kHz, AS5600 motor milinde, gecikme 0,4 ms, gürültü 0,043° RMS (motor), olay+yoklama ayarlı (yokOrta 0,6, vDurF 10 Hz)\n');
yaz('42 senaryo; H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (B12). B13: yoklama + 0,3 s kol hareketi (darbesiz).\n');
yaz('"ikiz": gerçek değer değişir, kestirici ve ofset nominali bilir; "^": gözlemcinin bildiği değer yanlış, ikiz nominal.\n\n');
yaz('%-11s %-10s | H7 geçen | B12 son yüz | en kötü |e| | ort |e| | B13 en çok | yoklama ort\n', 'sürtünme', 'satır');
for a = 1:size(sur,1)
 for c = 1:size(kos,1)
    if a == 2 && any(strcmp(kos{c,2}, {'Fc', 'Fs'})), continue; end   % sürtünmesiz ikizde anlamsız
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    alan = kos{c,2};  k = kos{c,3};
    switch kos{c,4}
        case 'ikiz'                                % ikiz değişir, ofset nominali bilir
            p.([alan 'N']) = p0.(alan);  p.(alan) = p0.(alan)*k;
        case 'bilinen'                             % gözlemcinin bildiği değer yanlış
            p.([alan 'N']) = p.(alan)*k;
    end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    b12 = yuzS == s0;
    h7 = abs(e) <= 0.5 & emax <= 1 & b12;
    b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
    yaz('%-11s %-10s | %2d/%2d    | %2d/%2d       | %6.2f      | %5.2f   | %5.2f      | %4.1f\n', ...
        sur{a,1}, kos{c,1}, nnz(h7), n, nnz(b12), n, max(abs(e)), mean(abs(e)), max(b13, [], 'omitnan'), mean(o.yokSay));
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
