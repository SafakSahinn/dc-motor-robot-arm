function pil_acik
% PIL_ACIK  θ* arama (p.thYildiz + p.tyArama) kartta: adım kilitli PIL, kartın C++ kontrolcüsü
%   (firmware/src/kontrol.cpp, olay+yoklama + θ* arama, T_KTL_BASLAT 180 + 24 B AyarEk) ikizi sürer.
%   Kurulum pil_b1.m ile aynı (yardımcılar oradan kopya). Referans: aynı senaryo yalnız MATLAB, n = 1.
%   Koşular (sabit hedef, a2 = t >= 3 s kola sabit yük, kolu durağan yüzünden öbür yüze iten yönde):
%     açık   : 175°, 185°, 0,02 N m, sürtünmesiz ve sürtünmeli (B2'de sürtünmesizde 7,2° çevrim)
%     sınır  : 347,5°, 0,06 N m, sürtünmeli (kalan sınır; kart da kaybetmeli)
%     kontrol: 179,25 / 179,5 / 180,75° temel (B1; kaydırma devreye girmemeli)
%   Çalıştırma (bu klasörden): matlab -batch "pil_acik"   Çıktı: pil_acik_log.txt, pil_acik.mat
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '6_esp32'));
cd(fileparts(mfilename('fullpath')));
diary off; if isfile("pil_acik_log.txt"), delete("pil_acik_log.txt"); end
diary("pil_acik_log.txt");
fprintf("=== pil_acik %s, θ* arama kartta ===\n", string(datetime("now")));

p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
p0.vKaynak = 'gozlemci';  p0.ktlKayit = true;
p0.thYildiz = true;  p0.tyArama = true;
kpv = 0.50^2*p0.Ks/p0.KV;  tD = 3;
% [hedef yön Fc Fs yük]
K = [175 1 0 0 0.02; 175 -1 0 0 0.02; 185 1 0 0 0.02; 185 -1 0 0 0.02;
     175 1 0.04 0.06 0.02; 175 -1 0.04 0.06 0.02; 185 1 0.04 0.06 0.02; 185 -1 0.04 0.06 0.02;
     347.5 1 0.04 0.06 0.06; 347.5 -1 0.04 0.06 0.06;
     179.25 1 0.04 0.06 0; 179.5 1 0.04 0.06 0; 180.75 -1 0.04 0.06 0;
     179.25 1 0 0 0; 179.5 1 0 0 0; 180.75 -1 0 0 0];
n = size(K,1);

PORT = "COM4";  BAUD = 1500000;
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
esp32_istek(sp, 4, siraNo(), typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();
sp.ReadTimeout = 2000;
ist0 = esp32_istat(sp, siraNo());

S = struct([]);
fprintf("%3s %-30s | H7 PIL/ref | e PIL/ref °     | App PIL/ref °   | MATLAB tyD ° | ilk ayrışma kart-gölge | max|du| N m | max|dth| ° | kayıp\n", "j", "koşu");
for j = 1:n
    hd = K(j,1);  s0 = sign(sind(hd));  tg = p0.mgl*sind(hd);  sF = sign(tg);
    p = p0;  p.Fc = K(j,3);  p.Fs = K(j,4);  p.adim = 1.1*K(j,2);  p.yuz0 = s0;
    if K(j,5) > 0, p.dB = K(j,5)*sF;  p.dBT0 = tD; end
    oR = kol_benzetim(p, hd, kpv);
    kartAdim('sifirla');
    pK = p;  pK.ktlDis = @(kc, s, v, uo, c0) kartAdim(sp, p, deg2rad(hd), kpv, s0, kc, s, v, uo, c0);
    oP = kol_benzetim(pK, hd, kpv);
    KT = oP.ktl;  KC = KT.kart;
    mR = olcut(oR, hd);  mP = olcut(oP, hd);
    ayr = find(KC(:,5) ~= KT.sh | KC(:,6) ~= KT.ykF, 1);
    if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
    du = max(abs(KC(:,1) - KT.uM));  dth = max(abs(rad2deg(oP.th - oR.th)));  kayip = sum(KC(:,9));
    ad = sprintf("%.2f° yön %+d Fs %.2f yük %.2f", hd, K(j,2), K(j,4), K(j,5));
    fprintf("%3d %-30s | %d / %d      | %+.3f / %+.3f | %5.2f / %5.2f   | %+.3f       | %-22s | %.2e    | %.2e   | %d\n", ...
        j, ad, mP.h7, mR.h7, mP.e, mR.e, mP.App, mR.App, rad2deg(oR.tyD), ayrS, du, dth, kayip);
    S(j).mP = mP;  S(j).mR = mR;  S(j).ayr = ayr;  S(j).du = du;  S(j).dth = dth;  S(j).kayip = kayip;
end
ay = arrayfun(@(x) isempty(x.ayr), S);  mP = [S.mP];  mR = [S.mR];
fprintf("\n=== Özet ===\nH7 PIL %d/%d, MATLAB %d/%d; kart-gölge kararları aynı %d/%d; max|du| %.2e N m; max|dth| %.3f°; kayıp %d\n", ...
    nnz([mP.h7]), n, nnz([mR.h7]), n, nnz(ay), n, max([S.du]), max([S.dth]), sum([S.kayip]));
ist = esp32_istat(sp, siraNo());
fprintf("kart sayaçları (bu koşu): paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d\n", ...
    ist.paketOk - ist0.paketOk, ist.crcHata - ist0.crcHata, ist.siraAtlama - ist0.siraAtlama, ...
    ist.copBayt - ist0.copBayt, ist.uzunHata - ist0.uzunHata);
save("pil_acik.mat", "S", "K");
diary off;
end

function s = h7s(h)
if isnan(h), s = "-"; else, s = string(double(h)); end
end

function [u, c] = kartAdim(sp, p, thRef, kpv, yuz0, kc, sayim, v, uo, c0)
% 6_esp32/pil.m ile aynı. Bir kontrol örneği kartta; kc == 1'de kart senaryonun ayarıyla başlatılır.
persistent uSon
if ischar(sp), uSon = 0; return; end
if kc == 1
    for dn = 1:3
        try
            [~, t] = esp32_istek(sp, 32, siraNo(), ktl_ayar_paketle(p, thRef, c0, kpv, yuz0), 24);
            if t ~= 160, error("esp32:tip", "T_KTL_BASLAT reddedildi"); end
            break
        catch e
            fprintf("   ! başlatma denemesi %d: %s\n", dn, e.message);
            if dn == 3, rethrow(e); end
            pause(0.1);  sp.DiscardInBuffer();
        end
    end
end
g = [typecast(uint16(mod(sayim, 4096)), 'uint8'), typecast(single([v uo]), 'uint8')];
t0 = tic;
try
    [y, t] = esp32_istek(sp, 33, siraNo(), g, 20);
    if t ~= 161, error("esp32:tip", "T_KTL_ADIM reddedildi"); end
    rtt = toc(t0);
    f = double(typecast(y(1:16), 'single'));
    u = f(1);  uSon = u;
    c = [f, double(typecast(y(17), 'int8')), double(y(18)), double(typecast(y(19:20), 'uint16')), rtt, 0];
catch e
    rtt = toc(t0);
    fprintf("   ! örnek %d: %s\n", kc, e.message);
    sp.DiscardInBuffer();
    u = uSon;  c = [u, NaN(1, 6), rtt, 1];
end
end

function s = siraNo()
persistent k
if isempty(k), k = 0; end
k = mod(k + 1, 65536);  s = k;
end

function m = olcut(o, hedef)
% B2 H7 (son 1 s ort |e| <= 0,5°, en büyük <= 1°; istenen hedefe göre) ve son 3 s tepeden tepeye.
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end)-1;  s3 = o.t > o.t(end)-3;
m.e = mean(sap(son));  m.emax = max(abs(sap(son)));
m.h7 = abs(m.e) <= 0.5 && m.emax <= 1;
m.App = max(rad2deg(o.th(s3))) - min(rad2deg(o.th(s3)));
end
