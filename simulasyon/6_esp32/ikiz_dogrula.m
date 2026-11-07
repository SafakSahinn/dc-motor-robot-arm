function ikiz_dogrula
% IKIZ_DOGRULA  Adım 6: kart içi gerçek zamanlı ikiz. Tesis ikizi (firmware/src/ikiz.cpp, float,
%   hedefe göre fark durumu) ve kontrolcü (kontrol.cpp) aynı 1 kHz görevde koşar; MATLAB yalnız
%   kurar (T_KTL_BASLAT + T_IKIZ_BASLAT), bekler, kaydı okur (T_KAYIT_OKU zamanlama, T_IKIZ_OKU durum).
%   Kurulum pil.m ile aynı (INA228 taban, hız = gözlemci w^, 42 senaryo x sürtünmeli/suz).
%   Referans: aynı senaryo yalnız MATLAB'da (kol_benzetim, n = 1, double).
%   Kip (ortam değişkeni IKIZ_GURULTU):
%     0 (varsayılan) gürültüsüz: nM = 0 (tGur zaten 0). Birebir karşılaştırma: ayrık kararlar
%       (s^, ykF), |du|, kol açısı farkı. Beklenen fark float - double kadar; boşluk geçişlerinde
%       geçici ayrışma olabilir (PIL'deki gibi).
%     1 gürültülü: nM = pil.m'deki değer. Kart kendi RNG'si (xorshift + Box–Muller), MATLAB randn:
%       diziler farklı, yalnız istatistiksel karşılaştırma (H7 sayısı, B13 dağılımı).
%   Ölçütler pil.m'deki olcut ile aynı (H7, B12, B13). B13 (yoklama + 0,3 s kol hareketi) kartın
%   s^ / ykF / th kaydından yeniden kurulur (yokKolKur); kurgu referansta out.yokKol ile sınanır.
%   Zamanlama: 1 kHz görevin adım süresi (ikiz + kontrolcü), periyot sapması, kaçan kesme.
%   Çalıştırma (bu klasörden):  matlab -batch "ikiz_dogrula"   (IKIZ_N=k: her sürtünmede ilk k senaryo)
%   Çıktı: ikiz_dogrula_log.txt / .mat (gürültülüde ikiz_gurultu_log.txt / .mat)
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
gur = str2double(getenv("IKIZ_GURULTU"));  gur = ~isnan(gur) && gur ~= 0;
if gur, ad = "ikiz_gurultu"; else, ad = "ikiz_dogrula"; end
diary off; if isfile(ad + "_log.txt"), delete(ad + "_log.txt"); end
diary(ad + "_log.txt");
fprintf("=== %s %s, kip: %s ===\n", ad, string(datetime("now")), ternar(gur, "gürültülü (kart RNG)", "gürültüsüz"));

% --- senaryolar (pil.m ile aynı) ---
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
if ~gur, p0.nM = 0; end
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
p0.vKaynak = 'gozlemci';  p0.ktlKayit = true;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));  yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);
n = numel(hedef);
nK = str2double(getenv("IKIZ_N"));  if isnan(nK), nK = n; end
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
bozAd = {'yok', 'darbe', 'yanlış s0'};
N = round(p0.T/p0.Ts);

PORT = "COM4";  BAUD = 1500000;  F = 240e6;
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
esp32_istek(sp, 4, siraNo(), typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();
sp.ReadTimeout = 3000;
ist0 = esp32_istat(sp, siraNo());

S = struct([]);
for a = 1:size(sur,1)
    fprintf("\n--- %s ---\n", sur{a,1});
    fprintf("%3s %-22s | H7 kart/ref | e kart/ref °    | en büyük kart/ref | B13 kart/ref °  | yokSay K/R | ilk ayrışma kart-ref   | max|du| N m | max|dth| ° | son|dth| ° | adım µs ort/p99/max | per sapma µs | kaçan\n", "j", "senaryo");
    for j = 1:nK
        p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
        p.adim = 1.1*Y(j);  p.dA = dA(j);  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0(j);
        thR = deg2rad(hedef(j));
        oR = kol_benzetim(p, hedef(j), kpv);  KT = oR.ktl;
        x0 = [thR - deg2rad(p.adim); 0; thR - deg2rad(p.adim); 0];   % kol_benzetim başlangıcı
        [Ki, Kz, d] = kartKos(sp, p, thR, x0, KT.ilkSayim, kpv, yuz0(j), N);

        oK.t = oR.t;  oK.th = thR + Ki.eTh;  oK.delta = Ki.dl;
        [oK.yokKol, oK.yokSay] = yokKolKur(oK.th, x0(3), Ki.sh, Ki.ykF, p);
        [ykR, ysR] = yokKolKur(oR.th, x0(3), KT.sh, KT.ykF, p);   % kurgunun sınaması
        mR = olcut(oR, p, hedef(j), s0(j), B(j));  mK = olcut(oK, p, hedef(j), s0(j), B(j));
        ayr = find(Ki.sh ~= KT.sh | Ki.ykF ~= KT.ykF, 1);
        if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
        du = max(abs(Ki.u - KT.u));
        dth = abs(rad2deg(oK.th - oR.th));
        is = Kz.isCyc/F*1e6;  per = abs(Kz.periyotCyc - F*p.Ts)/F*1e6;
        fprintf("%3d %-22s | %d / %d       | %+.3f / %+.3f | %.3f / %.3f     | %5.3f / %5.3f   | %d / %d      | %-22s | %.2e    | %.2e   | %.2e   | %.1f / %.1f / %.1f | %.1f        | %d\n", ...
            j, sprintf("%.2f>%.1f %s %s", I(j), hedef(j), char('a' + (Y(j) < 0)*('u'-'a')), bozAd{B(j)}), ...
            mK.h7, mR.h7, mK.e, mR.e, mK.emax, mR.emax, mK.b13, mR.b13, mK.yok, mR.yok, ayrS, du, max(dth), dth(end), ...
            mean(is), prctile(is, 99), max(is), max(per), d.kacan);
        S(a,j).mK = mK;  S(a,j).mR = mR;  S(a,j).ayr = ayr;  S(a,j).du = du;  S(a,j).dth = max(dth);
        S(a,j).dthSon = dth(end);  S(a,j).is = single(is);  S(a,j).per = single(per);  S(a,j).kacan = d.kacan;
        S(a,j).kurgu = [max(abs(ykR - oR.yokKol)), ysR - oR.yokSay];
        S(a,j).th = single([oK.th oR.th]);  S(a,j).u = single([Ki.u KT.u]);
    end
end

% --- özet ---
fprintf("\n=== Özet ===\n");
for a = 1:size(sur,1)
    s = S(a,1:nK);  mK = [s.mK];  mR = [s.mR];
    ay = arrayfun(@(x) ~isempty(x.ayr), s);
    is = vertcat(s.is);  per = vertcat(s.per);  kr = vertcat(s.kurgu);
    fprintf("%s: H7 kart %d/%d, referans %d/%d; B12 kart %d, ref %d; en kötü |e| kart %.3f°, ref %.3f°; B13 en çok kart %.3f°, ref %.3f°\n", ...
        sur{a,1}, nnz([mK.h7]), nK, nnz([mR.h7]), nK, nnz([mK.b12]), nnz([mR.b12]), ...
        max(abs([mK.e])), max(abs([mR.e])), max([mK.b13], [], 'omitnan'), max([mR.b13], [], 'omitnan'));
    fprintf("   kart-ref ayrık kararlar tümüyle aynı: %d/%d; en büyük |du| %.2e N m; en büyük |dth| %.3e°, son anda en büyük %.3e°\n", ...
        nnz(~ay), nK, max([s.du]), max([s.dth]), max([s.dthSon]));
    fprintf("   1 kHz adım (ikiz + kontrolcü) µs: ort %.1f, p99 %.1f, en uzun %.1f; periyot sapması en çok %.1f µs; kaçan kesme %d\n", ...
        mean(is), prctile(is, 99), max(is), max(per), sum([s.kacan]));
    fprintf("   B13 kurgusu (referansta out.yokKol ile): en büyük fark %.2e rad, yokSay farkı en çok %d\n", max(kr(:,1)), max(abs(kr(:,2))));
end
ist = esp32_istat(sp, siraNo());
fprintf("kart sayaçları (bu koşu): paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d\n", ...
    ist.paketOk - ist0.paketOk, ist.crcHata - ist0.crcHata, ist.siraAtlama - ist0.siraAtlama, ...
    ist.copBayt - ist0.copBayt, ist.uzunHata - ist0.uzunHata);
save(ad + ".mat", "S", "hedef", "I", "Y", "B", "nK");
diary off;
end

function [Ki, Kz, d] = kartKos(sp, p, thR, x0, c0, kpv, yuz0, N)
% Kontrolcü + ikiz ayarı, 1 kHz kayıt, bitişi bekle, iki kaydı oku. Tek seferlik aksamaya karşı 3 deneme.
for dn = 1:3
    try
        [~, t] = esp32_istek(sp, 32, siraNo(), ktl_ayar_paketle(p, thR, c0, kpv, yuz0), 24);
        if t ~= 160, error("esp32:tip", "T_KTL_BASLAT reddedildi"); end
        esp32_durum(sp, siraNo(), 34, [typecast(uint32(N), 'uint8'), ikiz_ayar_paketle(p, thR, x0)]);
        pause(N*p.Ts + 0.05);
        for k = 1:50
            d = esp32_durum(sp, siraNo());
            if d.durum == 2, break; end
            pause(0.05);
        end
        if d.durum ~= 2 || d.kayitN ~= N, error("esp32:bitmedi", "kayıt bitmedi (%d/%d)", d.kayitN, N); end
        Kz = esp32_kayit_oku(sp, siraNo(), 0, N);
        Ki = esp32_ikiz_oku(sp, siraNo(), 0, N);
        return
    catch e
        fprintf("   ! deneme %d: %s\n", dn, e.message);
        if dn == 3, rethrow(e); end
        pause(0.2);  sp.DiscardInBuffer();
    end
end
end

function [yokKol, yokSay] = yokKolKur(th, th0, sh, ykF, p)
% kol_benzetim'in out.yokKol / out.yokSay'ini kontrol örneği kaydından kurar.
% Kontrol örneği k'de kol açısı = (k-1). örneğin sonundaki açı (k = 1: başlangıç).
% Yoklamanın bitişi: ykF > 0 -> 0. Temasla (bT) bitişte s^ değişir (s^ = itiş yönü = -s^);
% serbest yol / zaman aşımıyla bitişte s^ aynı kalır ve kol 0,3 s daha izlenir.
thS = [th0; th(1:end-1)];
yokKol = 0;  yokSay = 0;  izBit = -Inf;  thB = 0;  Fo = 0;  so = sh(1);
for k = 1:numel(ykF)
    tt = ((k-1)*round(p.Ts/p.dt))*p.dt;
    F = ykF(k);
    if Fo > 0 && F == 0 && sh(k) == so, izBit = tt + 0.3; end   % bitiş, temas değil
    if Fo == 0 && F > 0, thB = thS(k);  yokSay = yokSay + 1; end
    if F > 0 || tt <= izBit, yokKol = max(yokKol, abs(thS(k) - thB)); end
    Fo = F;  so = sh(k);
end
end

function s = siraNo()
persistent k
if isempty(k), k = 0; end
k = mod(k + 1, 65536);  s = k;
end

function m = olcut(o, p, hedef, s0, B)
% H7 / B12 / B13 (pil.m ile aynı tanımlar), tek senaryo.
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end)-1;
gy = sign(o.delta).*(abs(o.delta) >= p.r);
m.b12 = sign(sum(gy(son))) == s0;
m.e = mean(sap(son));  m.emax = max(abs(sap(son)));
m.h7 = abs(m.e) <= 0.5 && m.emax <= 1 && m.b12;
m.b13 = rad2deg(o.yokKol);  if B == 2, m.b13 = NaN; end
m.yok = o.yokSay;
end

function y = ternar(c, a, b)
if c, y = a; else, y = b; end
end
