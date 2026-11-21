function b2_harita(isler)
% B2_HARITA  Mekanik ön yük (makas dişli) ile yazılım kestiricisinin açı x ön yük haritası.
% Tesis: D düzeneği, kanonik B1 ayarı (P-PI r_gs 0,5, 1 kHz, AS5600 motor milinde, 0,4 ms gecikme,
%   0,043° RMS gürültü, akım döngüsü 500 Hz). Makas dişli kol_benzetim'in p.onYuk modeli:
%   ön yük taup, B yayı Kp = 0,1 K_s; sürtünme bedeli F_c, F_s += muP*taup.
% Izgara: hedef açı 90:2,5:357,5° x taup {0 0,03 0,06 0,12 0,18 0,24 0,36 0,48} N m
%   (taup = 0 satırı dişlisiz: Kp = 0, saf boşluk) x 2 geliş yönü x 3 gürültü tohumu.
% Ortam: taban sürtünme {sürtünmeli F_c 0,04 / F_s 0,06; sürtünmesiz} x muP {0 0,25 0,5}.
% Senaryolar (B1'in genellemesi; bozucu yönü kolu durağan yüzünden öbür yüze iten yön):
%   temel, a1 darbe (0,05 N m, 20 ms), a2 yük 0,02 N m, a2 yük 0,06 N m, b salınım (0,01 N m, 1 Hz),
%   c yaklaşma (5°, 2°/s rampa), d yön değiştirme (1,5° aşma).
% Kontrolcüler:
%   disli_tablo : ofset = dişli durağan eğrisinin tersi (taup, Kp, r, K_s, mgl bilinir; dış yük
%                 bilinmez). taup = 0'da B1 tablosu (s0 r + mgl sin/K_s). Ön yüklü dişliyle mühendisin
%                 yazacağı en iyi kestiricisiz kod.
%   kestirici   : olay+yoklama (ikiz_dogrula kanonik ayarı). Ön yükü BİLMEZ: anlamlı satırı taup = 0.
%   ust_sinir   : ikizin gerçek yüzü (yalnız taup = 0).
% H7 (konum): son 1 s ortalama |e| <= 0,5° ve en büyük |e| <= 1°. Yanlış yüz 2r ~ 3° hata verir.
% Bedel (aynı koşudan): son 1 s RMS u [N m] (tutma torku).
% isler: çalıştırılacak iş numaraları (1..42 = ortam (6) x senaryo (7)); boşsa ortam B2_ISLER.
% Çıktı: b2_parca_<iş>.mat (birleştirme: b2_birlestir.m).
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(isler), isler = str2num(getenv('B2_ISLER')); end %#ok<ST2NM>

[p0, G] = b2_kurulum();
for is = isler
    [a, sc] = ind2sub([size(G.ortam,1), numel(G.sen)], is);
    dosya = sprintf('b2_parca_%02d.mat', is);
    if isfile(dosya), fprintf('%s var, atlandı\n', dosya); continue; end
    t0 = tic;
    R = struct();
    for m = 1:numel(G.ktl)
        if strcmp(G.ktl{m}, 'ust_sinir'), tpL = 1; else, tpL = 1:numel(G.taup); end
        [TH, TP, Yv, Bv] = ndgrid(G.aci, G.taup(tpL), [1 -1], G.tohum);
        TH = TH(:)';  TP = TP(:)';  Yv = Yv(:)';  Bv = Bv(:)';
        Rm = struct('e',[],'emax',[],'App',[],'h7',[],'urms',[],'yuzSon',[]);
        for ts = G.tohum                            % tohum başına bir çağrı (bellek)
            j = Bv == ts;
            o = kos(p0, G, a, sc, G.ktl{m}, TH(j), TP(j), Yv(j), ts);
            for f = fieldnames(o)', Rm.(f{1}) = [Rm.(f{1}) o.(f{1})]; end
        end
        idx = zeros(1, numel(TH));  k0 = 0;
        for ts = G.tohum, j = find(Bv == ts);  idx(j) = k0 + (1:numel(j));  k0 = k0 + numel(j); end
        for f = fieldnames(Rm)', Rm.(f{1}) = Rm.(f{1})(idx); end   % ndgrid sırasına geri
        Rm.aci = TH;  Rm.taup = TP;  Rm.yon = Yv;  Rm.tohum = Bv;
        R.(G.ktl{m}) = Rm;
    end
    ortam = G.ortam(a,:);  sen = G.sen{sc};  sure = toc(t0); %#ok<NASGU>
    save(dosya, 'R', 'ortam', 'sen', 'a', 'sc', 'sure');
    fprintf('iş %2d (%s, muP %.2f, %s) %.0f s\n', is, G.ortam{a,1}, G.ortam{a,4}, sen, sure);
end
end

function r = kos(p0, G, a, sc, ktl, aci, tp, Y, ts)
n = numel(aci);
Yf = Y;  if sc == 7, Yf = -Y; end                   % son yaklaşma yönü
hedef = aci;  kay = abs(aci - 180) < G.eps_;  hedef(kay) = 180 - G.eps_*Yf(kay);
tg = p0.mgl*sind(hedef);                            % durağan dişli torku
sF = sign(tg + tp);  sF(sF == 0) = 1;               % durağan yüz (taup = 0: yerçekimi yüzü)
s0 = sign(sind(hedef));
q = p0;  q.Fc = G.ortam{a,2};  q.Fs = G.ortam{a,3};  q.adim = 1.1*Y;  q.nTohum = ts;
Kp = G.KpOran*q.Ks*(tp > 0);
if any(tp > 0), q.onYuk = 1;  q.taup = tp;  q.Kp = Kp;  q.muP = G.ortam{a,4}; end
switch G.sen{sc}
    case 'a1 darbe',   q.dA = 0.05*sF;  q.df = 25;  q.dT0 = G.tD;  q.dT = G.tD + 0.02;
    case 'a2 yük 0,02', q.dB = 0.02*sF;  q.dBT0 = G.tD;
    case 'a2 yük 0,06', q.dB = 0.06*sF;  q.dBT0 = G.tD;
    case 'b salınım',  q.dA = 0.01*ones(1,n);  q.df = 1;  q.dT0 = G.tD;  q.dT = Inf;
    case 'c yaklaşma', W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
    case 'd yön değ.', W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
end
if sc >= 6, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
switch ktl
    case 'disli_tablo'
        q.ofset = b2_disli_ofset(tg, tp, Kp, q.r, q.Ks, s0);
    case 'kestirici'
        q.yuz0 = s0;  q.yuzKes = 'olay+yoklama';  q.yokOrta = 0.6;  q.vDurF = 10;
        q.tOlc = true;  q.tPen = 0.54e-3;  q.tGec = 0.1e-3;  q.vKaynak = 'gozlemci';
    case 'ust_sinir'
        q.yuz0 = s0;  q.ofsetYuz = 'anlik';
end
o = kol_benzetim(q, hedef, G.kpv*ones(1,n));
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
r.e = mean(sap(son,:), 1);  r.emax = max(abs(sap(son,:)), [], 1);
r.h7 = abs(r.e) <= 0.5 & r.emax <= 1;
r.App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
r.urms = sqrt(mean(o.u(son,:).^2, 1));
dl = o.delta(son,:);                                 % son yüz: +1 A (d >= r), -1 B (d <= -r), 0 arada
r.yuzSon = sign(mean(sign(dl).*(abs(dl) >= q.r), 1));
end
