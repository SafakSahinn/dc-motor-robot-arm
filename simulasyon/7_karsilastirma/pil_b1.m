function pil_b1
% PIL_B1  B1'in sabit hedefli yeni senaryoları (a2 yük, b salınım) adım kilitli PIL'de: kartın C++
%   kontrolcüsü (firmware/src/kontrol.cpp, olay+yoklama) ikizi sürer. Kurulum 6_esp32/pil.m ile aynı
%   (yardımcılar oradan kopya). Referans: aynı senaryo yalnız MATLAB, n = 1, aynı tohum.
%   a2: t >= 3 s kola sabit 0,02 N m, kolu öbür yüze iten yönde (doğru son yüz -s0); H7 ölçülür.
%   b : t >= 3 s kola 0,01 N m 1 Hz sinüs; son yüz tanımsız: B12 (kartın s^'i = gerçek yüz oranı,
%       t >= 3 s, temas örnekleri) ve son 3 s tepeden tepeye genlik.
%   c ve d (zamanla değişen referans) firmware'de her adımda referans alanı olmadığı için burada yok.
%   Çalıştırma (bu klasörden): matlab -batch "pil_b1"   Çıktı: pil_b1_log.txt, pil_b1.mat (gitignore)
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '6_esp32'));
cd(fileparts(mfilename('fullpath')));
diary off; if isfile("pil_b1_log.txt"), delete("pil_b1_log.txt"); end
diary("pil_b1_log.txt");
fprintf("=== pil_b1 %s, a2 yük + b salınım, kart kontrolcüsü (olay+yoklama) ===\n", string(datetime("now")));

p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
p0.vKaynak = 'gozlemci';  p0.ktlKayit = true;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:2);            % B: 1 = a2 yük, 2 = b salınım
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));
n = numel(hedef);
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
senAd = {'a2 yük', 'b salınım'};

PORT = "COM4";  BAUD = 1500000;  F = 240e6;
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
esp32_istek(sp, 4, siraNo(), typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();
sp.ReadTimeout = 2000;
ist0 = esp32_istat(sp, siraNo());

S = struct([]);
for a = 1:size(sur,1)
    fprintf("\n--- %s ---\n", sur{a,1});
    fprintf("%3s %-20s | H7 PIL/ref | e PIL/ref °     | B12 kart/ref    | App PIL/ref °   | ilk ayrışma kart-gölge | max|du| N m | max|dth| ° | tur ms ort/max | kayıp\n", "j", "senaryo");
    for j = 1:n
        p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};  p.adim = 1.1*Y(j);  p.yuz0 = s0(j);
        if B(j) == 1
            p.dB = 0.02*s0(j);  p.dBT0 = tD;  sDog = -s0(j);
        else
            p.dA = 0.01;  p.df = 1;  p.dT0 = tD;  p.dT = Inf;  sDog = NaN;
        end
        oR = kol_benzetim(p, hedef(j), kpv);
        kartAdim('sifirla');
        pK = p;  pK.ktlDis = @(kc, s, v, uo, c0) kartAdim(sp, p, deg2rad(hedef(j)), kpv, s0(j), kc, s, v, uo, c0);
        t1 = tic;  oP = kol_benzetim(pK, hedef(j), kpv);  sure = toc(t1);
        KT = oP.ktl;  KC = KT.kart;
        mR = olcut(oR, p, hedef(j), sDog, oR.shat);  mP = olcut(oP, p, hedef(j), sDog, KC(:,5));
        ayr = find(KC(:,5) ~= KT.sh | KC(:,6) ~= KT.ykF, 1);
        if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
        du = max(abs(KC(:,1) - KT.uM));  dth = max(abs(rad2deg(oP.th - oR.th)));
        rt = KC(:,8)*1e3;  kayip = sum(KC(:,9));
        fprintf("%3d %-20s | %s / %s      | %+.3f / %+.3f | %.3f / %.3f   | %5.2f / %5.2f   | %-22s | %.2e    | %.2e   | %.2f / %.2f | %d\n", ...
            j, sprintf("%.2f>%.1f %s %s", I(j), hedef(j), char('a' + (Y(j) < 0)*('u'-'a')), senAd{B(j)}), ...
            h7s(mP.h7), h7s(mR.h7), mP.e, mR.e, mP.b12, mR.b12, mP.App, mR.App, ayrS, du, dth, mean(rt), max(rt), kayip);
        S(a,j).mP = mP;  S(a,j).mR = mR;  S(a,j).ayr = ayr;  S(a,j).du = du;  S(a,j).dth = dth;
        S(a,j).rt = single(rt);  S(a,j).kayip = kayip;  S(a,j).sure = sure;
    end
end

fprintf("\n=== Özet ===\n");
for a = 1:size(sur,1)
    for b = 1:2
        s = S(a, B == b);  mP = [s.mP];  mR = [s.mR];  ay = arrayfun(@(x) ~isempty(x.ayr), s);
        if b == 1
            fprintf("%s %s: H7 PIL %d/%d, referans %d/%d; ", sur{a,1}, senAd{b}, nnz([mP.h7]), numel(s), nnz([mR.h7]), numel(s));
        else
            fprintf("%s %s: ", sur{a,1}, senAd{b});
        end
        fprintf("B12 kart ort %.3f (en kötü %.3f), ref ort %.3f; App en çok PIL %.2f°, ref %.2f°; kart-gölge kararları aynı %d/%d; max|du| %.2e; kayıp %d\n", ...
            mean([mP.b12]), min([mP.b12]), mean([mR.b12]), max([mP.App]), max([mR.App]), nnz(~ay), numel(s), max([s.du]), sum([s.kayip]));
    end
end
ist = esp32_istat(sp, siraNo());
fprintf("kart sayaçları (bu koşu): paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d\n", ...
    ist.paketOk - ist0.paketOk, ist.crcHata - ist0.crcHata, ist.siraAtlama - ist0.siraAtlama, ...
    ist.copBayt - ist0.copBayt, ist.uzunHata - ist0.uzunHata);
save("pil_b1.mat", "S", "hedef", "I", "Y", "B");
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

function m = olcut(o, p, hedef, sDog, shK)
% H7 (sDog NaN ise yok), B12 = kontrol örneklerinde s^ = gerçek yüz oranı (t >= 3 s, temas), App.
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end)-1;  s3 = o.t > o.t(end)-3;
gy = sign(o.delta).*(abs(o.delta) >= p.r);
m.e = mean(sap(son));  m.emax = max(abs(sap(son)));
if isnan(sDog), m.h7 = NaN;
else, m.h7 = abs(m.e) <= 0.5 && m.emax <= 1 && sign(sum(gy(son))) == sDog; end
nk = numel(shK);  tk = (0:nk-1)'*p.Ts;              % kontrol örneği anları -> kayıt satırı
ik = min(max(round(tk/(o.t(2)-o.t(1))), 1), numel(o.t));
g = gy(ik);  tm = g ~= 0 & tk >= 3;
m.b12 = sum(tm & shK(:) == g)/max(sum(tm), 1);
m.App = max(rad2deg(o.th(s3))) - min(rad2deg(o.th(s3)));
end
