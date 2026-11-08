function kayan_surtunme
% KAYAN_SURTUNME  İş sırası (5b): gerçek sürtünme zamanla kayarken ve hatalar birleşince yüz kestirici.
% İş sırası (4): F̂_c %30 fazla bilinince yoklama bozuluyordu, eksik bilinmesi zararsızdı -> öneri
% "F̂_c bilerek ≈ ×0,9". Burada kestirici F̂_c = 0,9·F_c(nominal) ile sabit tutulur, ikizin gerçek
% F_c ve F_s'si (p.FcKay) değişir:
%   (A) sabit sapma ×0,7 … ×1,3 (koşunun başından beri, ör. ısınmış ya da soğuk motor);
%   (B) koşu boyunca rampa (8 s'de 1 -> ×k; darbe 3 s'de, yani darbede kayma yarı yolda);
%   (C) birleşik köşeler: gerçek r ×0,9 / ×1,1, Ĵ_M ×0,8 / ×1,2, gerçek F_c ×0,7 / ×1,3; hepsinde
%       gerçek mgl ×1,2 ve K_s ×0,8 (tek başına etkisizdi); ikinci takımda ayrıca INA228 ofseti
%       +0,005 N m ve gürültü 0,003 N m;
%   (D) gerçekçi köşeler: gerçek r ×0,95 / ×1,05, Ĵ_M ×0,9 / ×1,1, gerçek F_c ×0,7 / ×1,3; INA hatasız ve +INA;
%   (E) sürtünmesiz ikizde r ve Ĵ_M köşeleri.
% Taban koşul akim_gurultu.m "INA228 taban" ile aynı (1 kHz, AS5600 motor milinde, gM 0,4 ms, nM,
% ayarlı olay+yoklama, gözlemci torku INA228'den: pencere 0,54 ms, gecikme 0,1 ms, akım 500 Hz).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
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

% Satır: {ad, struct}. Alanlar: Fcn (F̂_c / F_c nominal), kay (gerçek F_c, F_s çarpanı), kayT (rampa
% süresi; 0 = baştan sabit), r, JMN, mgl, Ks (gerçek ya da bilinen çarpanları), tOfs, tGur.
kos = {'F^c x1,0, gerçek x1,0', struct('Fcn', 1)};
for k = [0.7 0.8 0.9 1.0 1.1 1.2 1.3]
    kos(end+1,:) = {sprintf('sabit, gerçek x%.1f', k), struct('kay', k, 'kayT', 0)};
end
for k = [0.5 0.7 1.3 1.5]
    kos(end+1,:) = {sprintf('rampa 8 s -> x%.1f', k), struct('kay', k, 'kayT', p0.T)};
end
for ek = [false true]
    for kr = [0.9 1.1], for kj = [0.8 1.2], for kf = [0.7 1.3]
        s = struct('r', kr, 'JMN', kj, 'kay', kf, 'kayT', 0, 'mgl', 1.2, 'Ks', 0.8);
        ad = sprintf('köşe r%.1f J%.1f F%.1f', kr, kj, kf);
        if ek, s.tOfs = 0.005;  s.tGur = 0.003;  ad = [ad ' +INA']; end
        kos(end+1,:) = {ad, s};
    end, end, end
end
for kr = [0.95 1.05], for kj = [0.9 1.1], for kf = [0.7 1.3]   % gerçekçi köşe: tanılama payının ≈ 10–25 katı
    s = struct('r', kr, 'JMN', kj, 'kay', kf, 'kayT', 0, 'mgl', 1.2, 'Ks', 0.8);
    kos(end+1,:) = {sprintf('gerçekçi r%.2f J%.1f F%.1f', kr, kj, kf), s};
    s.tOfs = 0.005;  s.tGur = 0.003;
    kos(end+1,:) = {sprintf('gerçekçi r%.2f J%.1f F%.1f +INA', kr, kj, kf), s};
end, end, end
kosD = {'taban', struct()};
for kr = [0.9 1.1], for kj = [0.8 1.2]
    kosD(end+1,:) = {sprintf('köşe r%.1f J%.1f', kr, kj), struct('r', kr, 'JMN', kj, 'mgl', 1.2, 'Ks', 0.8)};
end, end

fid = fopen('kayan_surtunme_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== kayan_surtunme, %s, D, r_gs 0,50, r %.2f°, F_c %.2f, F_s %.2f N m (nominal)\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), 0.04, 0.06);
yaz('Taban: 1 kHz, AS5600 motor milinde (0,4 ms, 0,043° RMS), olay+yoklama ayarlı, gözlemci torku INA228 (0,54 ms / 0,1 ms), akım 500 Hz.\n');
yaz('Kestirici F^c = 0,9 x nominal (ilk satır hariç), F^s nominal. "gerçek x": ikizin F_c ve F_s''si; "köşe": gerçek r, J^M, gerçek F_c çarpanları + gerçek mgl x1,2, K_s x0,8.\n');
yaz('42 senaryo; H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru (B12). B13: yoklama + 0,3 s kol hareketi (darbesiz).\n\n');
yaz('%-11s %-28s | H7 geçen | B12 son yüz | en kötü |e| | ort |e| | B13 en çok | yoklama ort\n', 'sürtünme', 'satır');
sur = {'sürtünmeli', 0.04, 0.06, kos; 'sürtünmesiz', 0, 0, kosD};
for a = 1:2
 K = sur{a,4};
 for c = 1:size(K,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    p.FcN = 0.9*p.Fc;  s = K{c,2};
    if isfield(s,'Fcn'), p.FcN = s.Fcn*p.Fc; end
    if isfield(s,'kay')
        p.FcKay = s.kay;  p.FcKayT = max(s.kayT, 1e-9);
    end
    for ad = {'r', 'mgl', 'Ks'}                    % gerçek değer değişir, ofset nominali bilir
        if isfield(s, ad{1}), p.([ad{1} 'N']) = p0.(ad{1});  p.(ad{1}) = p0.(ad{1})*s.(ad{1}); end
    end
    if isfield(s,'JMN'), p.JMN = p0.JM*s.JMN; end
    if isfield(s,'tOfs'), p.tOfs = s.tOfs; end
    if isfield(s,'tGur'), p.tGur = s.tGur; end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    b12 = yuzS == s0;
    h7 = abs(e) <= 0.5 & emax <= 1 & b12;
    b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
    yaz('%-11s %-28s | %2d/%2d    | %2d/%2d       | %6.2f      | %5.2f   | %5.2f      | %4.1f\n', ...
        sur{a,1}, K{c,1}, nnz(h7), n, nnz(b12), n, max(abs(e)), mean(abs(e)), max(b13, [], 'omitnan'), ...
        mean(o.yokSay));
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
