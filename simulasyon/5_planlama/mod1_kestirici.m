function mod1_kestirici(kume)
% MOD1_KESTIRICI  İş sırası (5c): yüz kestirici (olay + yoklama) motorun elektrik tarafıyla, özellikle
% mod 1 (gerilim sürüşü, V = Ra u / Km; D7 protokolü bu modda). Şimdiye kadarki bütün kestirici sonuçları
% tork girişli ikizdeydi (tesis torku = komut, akım döngüsü 500 Hz birinci derece). Mod 1'de:
%   - tesis torku u - (Km^2/Ra) phi' olur: zıt EMK ek bir sönüm (~7 b_M), yoklama itişi hızlandıkça zayıflar;
%   - INA228 gerçek akımı ölçer; gözlemci INA228'i görürse zıt EMK kendiliğinden hesaba girer,
%     komutu görürse (tOlc kapalı) Km^2/Ra phi' farkı d^'ye karışır.
% Satırlar (her biri 42 senaryo, taban kayan_surtunme.m ile aynı; kestirici F^c = 0,9 x nominal):
%   tork referans | mod 1 | mod 2 | mod 3 (PI, 10 kHz) ; mod 1'de ayrıca gözlemci komutu görür, INA228 hatası,
%   firmware'in Ra'sı eksik (sargı ısındı: gerçek Ra x1,25), gerçekçi köşeler; sürtünmesiz ikizde 4 mod.
% kume = 'kose': yalnız F1.3 köşeleri (r0.95, J0.9 / J1.1, +INA), 4 mod x 3 gürültü tohumu (motor nM ve INA228
%   akışları birlikte); mod 1'deki 2-4 senaryoluk fark moddan mı tohumdan mı? Ayrıca mod 2'nin kartta
%   uygulanabilir biçimi: zıt EMK kompanzasyonu gözlemcinin w^'siyle (p.elkV). Log mod1_kestirici_kose_log.txt.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;
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

% Satır alanları: mot (0 = tork girişli, akimW 500 Hz), tOlc, tOfs, tGur, RaN (firmware Ra / gerçek),
% r, JMN, kay (gerçek F_c, F_s çarpanı; köşelerde mgl x1,2, K_s x0,8 ile).
ina = struct('tOfs', 0.005, 'tGur', 0.003);
kos = {'tork referans (akım 500 Hz)', struct('mot', 0);
       'mod 1 gerilim',               struct('mot', 1);
       'mod 2 zıt EMK komp.',         struct('mot', 2);
       'mod 2, kompanzasyon w^ ile',  struct('mot', 4);
       'mod 3 akım döngüsü',          struct('mot', 3);
       'mod 1, gözlemci u görür',     struct('mot', 1, 'tOlc', false);
       'tork ref., gözlemci u görür', struct('mot', 0, 'tOlc', false);
       'mod 1 +INA',                  struct('mot', 1, 'tOfs', ina.tOfs, 'tGur', ina.tGur);
       'mod 3 +INA',                  struct('mot', 3, 'tOfs', ina.tOfs, 'tGur', ina.tGur);
       'mod 1, Ra x1,25 (ısınmış)',   struct('mot', 1, 'RaN', 1/1.25);
       'mod 1, Ra x0,9',              struct('mot', 1, 'RaN', 1/0.9)};
for m = [0 1]
    for kr = [0.95 1.05], for kj = [0.9 1.1], for kf = [0.7 1.3]
        s = struct('mot', m, 'r', kr, 'JMN', kj, 'kay', kf, 'mgl', 1.2, 'Ks', 0.8, 'tOfs', ina.tOfs, 'tGur', ina.tGur);
        if m == 0, on = 'tork'; else, on = 'mod 1'; end
        kos(end+1,:) = {sprintf('%s r%.2f J%.1f F%.1f +INA', on, kr, kj, kf), s}; %#ok<AGROW>
    end, end, end
end
if nargin < 1, kume = 'ana'; end
logAd = 'mod1_kestirici_log.txt';
kosD = {'tork referans (akım 500 Hz)', struct('mot', 0);
        'mod 1 gerilim',               struct('mot', 1);
        'mod 2 zıt EMK komp.',         struct('mot', 2);
        'mod 3 akım döngüsü',          struct('mot', 3);
        'mod 1, gözlemci u görür',     struct('mot', 1, 'tOlc', false)};

if strcmp(kume, 'kose')
    kos = cell(0,2);  kosD = cell(0,2);  logAd = 'mod1_kestirici_kose_log.txt';
    mAd = {'tork', 'mod 1', 'mod 2', 'mod 3', 'mod 2 w^'};
    for kj = [0.9 1.1], for m = 0:4, for tH = 1:3
        s = struct('mot', m, 'r', 0.95, 'JMN', kj, 'kay', 1.3, 'mgl', 1.2, 'Ks', 0.8, ...
                   'tOfs', ina.tOfs, 'tGur', ina.tGur, 'tohum', tH);
        kos(end+1,:) = {sprintf('%s r0.95 J%.1f F1.3 +INA t%d', mAd{m+1}, kj, tH), s}; %#ok<AGROW>
    end, end, end
end
fid = fopen(logAd, 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== mod1_kestirici, %s, D, r_gs 0,50, r %.2f°, F_c %.2f, F_s %.2f N m (nominal)\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), 0.04, 0.06);
yaz('Taban kayan_surtunme ile aynı (1 kHz, AS5600 motor milinde, olay+yoklama ayarlı, gözlemci torku INA228 0,54 ms / 0,1 ms, F^c = 0,9 x nominal).\n');
yaz('Motor: tork ref. = tesis torku komutu 500 Hz birinci derece izler; mod 1-3 = kol_benzetim p.motorElk (sim_param eşdeğer motoru,\n');
yaz('  Km 0,344 V s/rad, Ra 8,43 Ohm, La 2,5 mH, akım sınırı 1,24 A (0,43 N m), +-12 V; zıt EMK sönümü Km^2/Ra = %.4f N m s/rad = %.1f b_M).\n', ...
    (12/(333*2*pi/60))^2/((12/(333*2*pi/60))*12/0.49), ((12/(333*2*pi/60))^2/((12/(333*2*pi/60))*12/0.49))/p0.bM);
yaz('"köşe": gerçek r, J^M, gerçek F_c çarpanları + gerçek mgl x1,2, K_s x0,8; +INA: ofset 0,005 N m, gürültü 0,003 N m.\n');
yaz('42 senaryo; H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (B12). B13: yoklama + 0,3 s kol hareketi (darbesiz).\n\n');
yaz('%-11s %-30s | H7 geçen | B12 son yüz | en kötü |e| | ort |e| | B13 en çok | yoklama ort | i tepe [A] | V doyum\n', 'sürtünme', 'satır');
sur = {'sürtünmeli', 0.04, 0.06, kos; 'sürtünmesiz', 0, 0, kosD};
for a = 1:2
 K = sur{a,4};
 for c = 1:size(K,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    p.FcN = 0.9*p.Fc;  s = K{c,2};
    if s.mot == 0, p.akimW = 2*pi*500; elseif s.mot == 4, p.motorElk = 2;  p.elkV = 'gozlemci'; else, p.motorElk = s.mot; end
    if isfield(s,'tOlc'), p.tOlc = s.tOlc; end
    if isfield(s,'RaN'), p.RaN = s.RaN*(12/(333*2*pi/60))*12/0.49; end
    if isfield(s,'kay'), p.FcKay = s.kay;  p.FcKayT = 1e-9; end
    for ad = {'r', 'mgl', 'Ks'}                    % gerçek değer değişir, ofset nominali bilir
        if isfield(s, ad{1}), p.([ad{1} 'N']) = p0.(ad{1});  p.(ad{1}) = p0.(ad{1})*s.(ad{1}); end
    end
    if isfield(s,'JMN'), p.JMN = p0.JM*s.JMN; end
    if isfield(s,'tOfs'), p.tOfs = s.tOfs; end
    if isfield(s,'tGur'), p.tGur = s.tGur; end
    if isfield(s,'tohum'), p.nTohum = s.tohum;  p.tTohum = s.tohum + 1; end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    b12 = yuzS == s0;
    h7 = abs(e) <= 0.5 & emax <= 1 & b12;
    b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
    if isfield(o,'iTepe'), it = sprintf('%5.2f', max(o.iTepe));  vd = sprintf('%5.2f%%', 100*max(o.Vdoy));
    else, it = '    -';  vd = '     -'; end
    yaz('%-11s %-30s | %2d/%2d    | %2d/%2d       | %6.2f      | %5.2f   | %5.2f      | %4.1f        | %s      | %s\n', ...
        sur{a,1}, K{c,1}, nnz(h7), n, nnz(b12), n, max(abs(e)), mean(abs(e)), max(b13, [], 'omitnan'), ...
        mean(o.yokSay), it, vd);
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
