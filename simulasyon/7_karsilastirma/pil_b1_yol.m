function pil_b1_yol
% PIL_B1_YOL  B1'in zamanla değişen referanslı senaryoları (c yaklaşma, d yön değiştirme) adım kilitli
%   PIL'de. Her kontrol örneğinde referans thr = refYol(t) karta T_KTL_ADIM_REF (0x24) ile ölçümle
%   birlikte gider; kart önce hedefAyarla(thr) (hedef + ofsetin yerçekimi terimi), sonra adim() koşar.
%   Kurulum 6_esp32/pil.m ve pil_b1.m ile aynı. Referans: yalnız MATLAB, n = 1, aynı tohum.
%   c: referans hedefin 5° gerisinden 2°/s rampayla gelip durur.
%   d: hedefi 1,5° aşar, geri döner (2°/s), durur. Hedef kaydırma SON yaklaşma yönüne göre.
%   Çalıştırma (bu klasörden): matlab -batch "pil_b1_yol"   Çıktı: pil_b1_yol_log.txt, pil_b1_yol.mat
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '6_esp32'));
cd(fileparts(mfilename('fullpath')));
diary off; if isfile("pil_b1_yol_log.txt"), delete("pil_b1_yol_log.txt"); end
diary("pil_b1_yol_log.txt");
fprintf("=== pil_b1_yol %s, c yaklaşma + d yön değiştirme, kart kontrolcüsü (olay+yoklama), T_KTL_ADIM_REF ===\n", string(datetime("now")));

p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
p0.vKaynak = 'gozlemci';  p0.ktlKayit = true;  p0.adim = 0;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:2);            % B: 1 = c yaklaşma, 2 = d yön değiştirme
I = I(:)';  Y = Y(:)';  B = B(:)';
Yf = Y;  Yf(B == 2) = -Y(B == 2);                   % son yaklaşma yönü
hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Yf(kay);
s0 = sign(sind(hedef));
n = numel(hedef);
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
senAd = {'c yaklaşma', 'd yön değ.'};

PORT = "COM4";  BAUD = 1500000;
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
esp32_istek(sp, 4, siraNo(), typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();
sp.ReadTimeout = 2000;
ist0 = esp32_istat(sp, siraNo());

S = struct([]);
for a = 1:size(sur,1)
    fprintf("\n--- %s ---\n", sur{a,1});
    fprintf("%3s %-22s | H7 PIL/ref | e PIL/ref °     | en büyük PIL/ref | B13 PIL/ref °   | ilk ayrışma kart-gölge | max|du| N m | max|dth| ° | tur ms ort/max | kayıp\n", "j", "senaryo");
    for j = 1:n
        p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};  p.yuz0 = s0(j);
        if B(j) == 1, W = [hedef(j) - 5*Yf(j); hedef(j)];  tk = [0 2.5];
        else, W = [hedef(j) + 3*Yf(j); hedef(j) - 1.5*Yf(j); hedef(j)];  tk = [0 2.25 3]; end
        p.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end))));
        oR = kol_benzetim(p, hedef(j), kpv);
        kartAdimRef('sifirla');
        pK = p;  pK.ktlDis = @(kc, s, v, uo, c0) kartAdimRef(sp, p, deg2rad(hedef(j)), kpv, s0(j), kc, s, v, uo, c0);
        t1 = tic;  oP = kol_benzetim(pK, hedef(j), kpv);  sure = toc(t1);
        KT = oP.ktl;  KC = KT.kart;
        mR = olcut(oR, p, hedef(j), s0(j));  mP = olcut(oP, p, hedef(j), s0(j));
        ayr = find(KC(:,5) ~= KT.sh | KC(:,6) ~= KT.ykF, 1);
        if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
        du = max(abs(KC(:,1) - KT.uM));  dth = max(abs(rad2deg(oP.th - oR.th)));
        rt = KC(:,8)*1e3;  kayip = sum(KC(:,9));
        fprintf("%3d %-22s | %d / %d      | %+.3f / %+.3f | %.3f / %.3f    | %5.3f / %5.3f   | %-22s | %.2e    | %.2e   | %.2f / %.2f | %d\n", ...
            j, sprintf("%.2f>%.1f %s %s", I(j), hedef(j), char('a' + (Yf(j) < 0)*('u'-'a')), senAd{B(j)}), ...
            mP.h7, mR.h7, mP.e, mR.e, mP.emax, mR.emax, mP.b13, mR.b13, ayrS, du, dth, mean(rt), max(rt), kayip);
        S(a,j).mP = mP;  S(a,j).mR = mR;  S(a,j).ayr = ayr;  S(a,j).du = du;  S(a,j).dth = dth;
        S(a,j).rt = single(rt);  S(a,j).kayip = kayip;  S(a,j).sure = sure;
    end
end

fprintf("\n=== Özet ===\n");
for a = 1:size(sur,1)
    for b = 1:2
        s = S(a, B == b);  mP = [s.mP];  mR = [s.mR];  ay = arrayfun(@(x) ~isempty(x.ayr), s);
        fprintf("%s %s: H7 PIL %d/%d, referans %d/%d; en kötü |e| PIL %.3f°, ref %.3f°; B13 en çok PIL %.3f°, ref %.3f°; kart-gölge kararları aynı %d/%d; max|du| %.2e; max|dth| %.3f°; kayıp %d\n", ...
            sur{a,1}, senAd{b}, nnz([mP.h7]), numel(s), nnz([mR.h7]), numel(s), max(abs([mP.e])), max(abs([mR.e])), ...
            max([mP.b13], [], 'omitnan'), max([mR.b13], [], 'omitnan'), nnz(~ay), numel(s), max([s.du]), max([s.dth]), sum([s.kayip]));
    end
end
ist = esp32_istat(sp, siraNo());
fprintf("kart sayaçları (bu koşu): paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d\n", ...
    ist.paketOk - ist0.paketOk, ist.crcHata - ist0.crcHata, ist.siraAtlama - ist0.siraAtlama, ...
    ist.copBayt - ist0.copBayt, ist.uzunHata - ist0.uzunHata);
save("pil_b1_yol.mat", "S", "hedef", "I", "Y", "Yf", "B");
diary off;
end

function [u, c] = kartAdimRef(sp, p, thRef, kpv, yuz0, kc, sayim, v, uo, c0)
% pil.m'deki kartAdim'in referanslı hali: kc == 1'de T_KTL_BASLAT (son hedefle; yoklama bandı ona
% göre), her örnekte T_KTL_ADIM_REF = double refYol(t) + Girdi, t = (kc-1) Ts (kol_benzetim ile aynı an).
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
thr = p.refYol((kc-1)*p.Ts);
g = [typecast(double(thr), 'uint8'), typecast(uint16(mod(sayim, 4096)), 'uint8'), typecast(single([v uo]), 'uint8')];
t0 = tic;
try
    [y, t] = esp32_istek(sp, 36, siraNo(), g, 20);
    if t ~= 164, error("esp32:tip", "T_KTL_ADIM_REF reddedildi"); end
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

function m = olcut(o, p, hedef, s0)
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end)-1;
gy = sign(o.delta).*(abs(o.delta) >= p.r);
m.e = mean(sap(son));  m.emax = max(abs(sap(son)));
m.h7 = abs(m.e) <= 0.5 && m.emax <= 1 && sign(sum(gy(son))) == s0;
m.b13 = rad2deg(o.yokKol);
end
