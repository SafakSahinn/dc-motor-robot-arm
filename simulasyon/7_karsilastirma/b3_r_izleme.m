function b3_r_izleme
% B3: tam geçiş yoklamasıyla boşluk izleme (ikinci bildiri adayı; plan tur 70, uygulama tur 71).
% Soru: ofset tablosunun bildiği r zamanla büyürse (aşınma) yalnız motor sinyalleriyle izlenebilir mi?
% Düzen: B1 kanonik ayarı (D, P-PI r_gs 0,5, 1 kHz, AS5600 motor milinde, INA228, akım döngüsü 500 Hz),
% olay+yoklama kestirici; yoklama yerine tam geçiş (kol_benzetim p.rOlc) dik aşağıda (0°/360°).
% Görev döngüsü (16 s, T = 80 s, 5 çevrim): 0-5 s 0°'de bekle (ölçüm), 5-6 s -> 45°, 6-10 s 45°'de tut,
% 10-11 s -> 120°, 11-15 s 120°'de tut, 15-16 s -> 0°. Tutma hatası her tutmanın son 1 s'si (P-PI tutmanın
% ilk ~2 s'sinde oturuyor: 2 s'lik tutmada aşınmasız taban bile -0,06..-0,5° çıkıyordu).
% Aşınma: r(t) = r0 (1 + A min(max((t - 16)/64, 0), 1)) (ilk çevrim aşınmasız: 'fark' başvurusu doğru r'de).
% Kipler: sabit (rN = r0), mutlak, fark (p.rGun), kâhin (rN = r(t)). Hepsinde tam geçiş yoklaması koşar
% (aynı bozucu etki); sabit ve kâhinde ölçüm rN'ye yazılmaz.
% Senaryo (ortam B3_SEN):
%   'ana' : A {0,25; 0,5} x tesis (motor sürtünmeli/sürtünmesiz x kol yatağı FcL {0; 0,004; 0,01}) x 4 kip x 3 tohum
%   'duy' : A 0,5, sürtünmeli, FcL 0,004; kestiricinin bildiği K_sN x0,5/x2, FcN (ve FsN) x0,75/x1,25,
%           AS5600 gürültüsü x3, motor nicemlemesi x4, INA228 gürültüsü 0,005 N m; mutlak/fark x 3 tohum
%   '180' : ölçüm 180°'de (dik yukarı; 0° yerine), A 0,5, 3 tesis, mutlak/fark x 3 tohum
% Paralel: B3_PARCA / B3_NPAR. Özet: b3_ozet (B3_SEN).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.T = 80;  p0.Tan = p0.T;  p0.dec = 10;
p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;  p0.gM = 4e-4;  p0.akimW = 2*pi*500;
kpv = 0.50^2*p0.Ks/p0.KV;
p0.qM = 2*pi/(4096*30);  p0.nM = deg2rad(0.043)/p0.N;  p0.adim = 1.1;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.vKaynak = 'gozlemci';
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;  p0.yokBolge = '180+360';
p0.rOlc = true;  p0.yokMaks = Inf;  p0.yokPer = 6;  p0.rOlcTmax = 4;
sen = getenv('B3_SEN');  if isempty(sen), sen = 'ana'; end
olcA = 0;  if strcmp(sen, '180'), olcA = 180; end
p0.refYol = @(t) deg2rad(gorev(t, olcA));
Tc = 16;  tH = [9 10; 14 15];                         % tutma pencereleri (çevrim içinde) [s]
G = {};                                              % görevler: {ad, A, sürt, FcL, kip, ek struct, tohum}
kipler = {'sabit','mutlak','fark','kahin'};
switch sen
    case 'ana'
        for A = [0.25 0.5], for a = [1 0], for L = [0 0.004 0.01], for k = 1:4, for s = 1:3
            G(end+1,:) = {'ana', A, a, L, kipler{k}, struct(), s}; %#ok<AGROW>
        end, end, end, end, end
    case 'duy'
        D = {'KsN x0,5', struct('KsN', 0.5*p0.Ks); 'KsN x2', struct('KsN', 2*p0.Ks);
             'FcN x0,75', struct('FcN', 0.75*0.04, 'FsN', 0.75*0.06); 'FcN x1,25', struct('FcN', 1.25*0.04, 'FsN', 1.25*0.06);
             'AS5600 gürültü x3', struct('nM', 3*p0.nM); 'nicemleme x4', struct('qM', 4*p0.qM);
             'INA228 gürültü 0,005', struct('tGur', 0.005)};
        for d = 1:size(D,1), for k = 2:3, for s = 1:3
            G(end+1,:) = {D{d,1}, 0.5, 1, 0.004, kipler{k}, D{d,2}, s}; %#ok<AGROW>
        end, end, end
    case '180'
        for c = [1 0.004; 1 0.01; 0 0.004]', for k = 2:3, for s = 1:3
            G(end+1,:) = {'ölçüm 180', 0.5, c(1), c(2), kipler{k}, struct(), s}; %#ok<AGROW>
        end, end, end
    otherwise
        error('bilinmeyen B3_SEN: %s', sen);
end
parca = str2double(getenv('B3_PARCA'));  npar = str2double(getenv('B3_NPAR'));
if isnan(parca), parca = 1;  npar = 1; end
sec = parca:npar:size(G,1);
R = struct([]);
for g = sec
    [ad, A, a, L, kip, ek, s] = G{g,:};
    p = p0;  p.Fc = 0.04*a;  p.Fs = 0.06*a;  p.FcL = L;  p.FsL = 1.5*L;  p.nTohum = s;  p.tTohum = s + 10;
    p.rFn = @(t) 1 + A*min(max((t - Tc)/(p.T - Tc), 0), 1);
    if any(strcmp(kip, {'mutlak','fark'})), p.rGun = kip; end
    if strcmp(kip, 'kahin'), p.rNKahin = true; end
    f = fieldnames(ek);  for j = 1:numel(f), p.(f{j}) = ek.(f{j}); end
    tic;  o = kol_benzetim(p, olcA, kpv);  sure = toc;
    e = rad2deg(o.th) - rad2deg(p.refYol(o.t'))';    % analiz penceresi tüm süre (Tan = T)
    nc = floor(p.T/Tc);  eH = NaN(nc,2);  eM = NaN(nc,2);
    for c = 1:nc
        for h = 1:2
            w = o.t > (c-1)*Tc + tH(h,1) & o.t <= (c-1)*Tc + tH(h,2);
            eH(c,h) = mean(e(w));  eM(c,h) = max(abs(e(w)));
        end
    end
    Q = o.rOlc;  m = 1:min(Q.n, size(Q.rHat,1));
    r = struct('ad', ad, 'A', A, 'sur', a, 'FcL', L, 'kip', kip, 'tohum', s, 'eH', eH, 'eM', eM, ...
        'rT', rad2deg(p.r*arrayfun(p.rFn, Q.t(m))), 'rH', rad2deg(Q.rHat(m)), 'rN', rad2deg(Q.rN(m)), ...
        'tO', Q.t(m), 'kabul', Q.kabul(m), 'gun', Q.gun(m), 'kol', rad2deg(Q.kol(m)), 'nO', Q.n, 'iptal', Q.iptal, ...
        'rNSon', rad2deg(o.rNSon), 'rSon', rad2deg(p.r*p.rFn(p.T)), 'sure', sure);
    R = [R r]; %#ok<AGROW>
    fprintf('%d/%d %s A %.2f sürt %d FcL %.3f %s t%d | %.0f s\n', g, size(G,1), ad, A, a, L, kip, s, sure);
end
save(sprintf('b3_%s_sonuc_%d.mat', sen, parca), 'R');
end

function y = gorev(t, olcA)
% Görev döngüsü [derece]: ölçüm açısı olcA (0 ya da 180), 45° ve 120° tutma.
tc = mod(t, 16);
if olcA == 0, a0 = 0; else, a0 = 180; end
y = interp1([0 5 6 10 11 15 16], [a0 a0 45 45 120 120 a0], tc);
end
