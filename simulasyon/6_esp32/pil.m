function pil
% PIL  Adım 5: adım kilitli işlemci-döngüde (PIL) benzetim. İkiz (kol_benzetim.m) MATLAB'da koşar;
%   her kontrol örneğinde (1 ms) motor ölçümü T_KTL_ADIM (n = 1) ile karta gider, kartın C++
%   kontrolcüsünün (firmware/src/kontrol.cpp) u'su ikize uygulanır (p.ktlDis kancası). MATLAB
%   kontrolcüsü aynı ölçümlerle gölge olarak koşar: kapalı döngüde her örnekte karşılaştırılır.
%   Kurulum ktl_esdeger.m / akim_gurultu.m "INA228 taban", kontrolcü hızı = gözlemcinin w^'si
%   (p.vKaynak = 'gozlemci', kartta HIZ_GOZLEMCI: donanımdaki seçim). 42 senaryo x sürtünmeli/suz.
%   Referans: aynı senaryo YALNIZ MATLAB ile, yine n = 1 ve aynı tohumla (enkoder gürültüsü tek
%   randn akışından gelir, n'ye bağlıdır; 42'lik vektör koşusuyla karşılaştırma adil olmaz).
%   Ölçütler: H7 (son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru = B12), B13 (yoklama +
%   0,3 s kol hareketi), kart-gölge ayrık karar ayrışması ve |du|, PIL - referans kol açısı farkı,
%   tur süresi (MATLAB'dan bakınca gidiş-dönüş), zaman aşımı / CRC sayaçları.
%   Çalıştırma (bu klasörden):  matlab -batch "pil"     (ortam değişkeni PIL_N=k: her sürtünmede ilk k senaryo)
%   Çıktı: pil_log.txt, pil.mat
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
diary off; if isfile("pil_log.txt"), delete("pil_log.txt"); end
diary("pil_log.txt");
fprintf("=== pil %s, hız kaynağı: gözlemci w^ ===\n", string(datetime("now")));

% --- senaryolar (ktl_esdeger.m ile aynı) ---
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
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));  yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);
n = numel(hedef);
nK = str2double(getenv("PIL_N"));  if isnan(nK), nK = n; end
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
bozAd = {'yok', 'darbe', 'yanlış s0'};

PORT = "COM4";  BAUD = 1500000;  F = 240e6;
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
esp32_istek(sp, 4, siraNo(), typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();
sp.ReadTimeout = 2000;   % ms. Cevap ~1 ms, ama Windows/USB ara sıra ~200 ms takılıyor (ilk koşuda 672k
                         % pakette bir kez; kart örneği almış, cevap PC'de gecikmiş). Adım kilitli: bekle, atma.
ist0 = esp32_istat(sp, siraNo());

S = struct([]);
for a = 1:size(sur,1)
    fprintf("\n--- %s ---\n", sur{a,1});
    fprintf("%3s %-22s | H7 PIL/ref | e PIL/ref °     | en büyük PIL/ref | B13 PIL/ref °   | yokSay P/R | ilk ayrışma kart-gölge | max|du| N m | max|dth| ° | tur ms ort/p99/max | kayıp | süre s\n", "j", "senaryo");
    for j = 1:nK
        p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
        p.adim = 1.1*Y(j);  p.dA = dA(j);  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0(j);
        % referans: yalnız MATLAB, n = 1
        oR = kol_benzetim(p, hedef(j), kpv);
        % PIL: kart kontrolcüsü tesisi sürer
        kartAdim('sifirla');
        pK = p;  pK.ktlDis = @(kc, s, v, uo, c0) kartAdim(sp, p, deg2rad(hedef(j)), kpv, yuz0(j), kc, s, v, uo, c0);
        t1 = tic;  oP = kol_benzetim(pK, hedef(j), kpv);  sure = toc(t1);
        KT = oP.ktl;  KC = KT.kart;                  % KC: [u wh dh sOf sh ykF cyc rtt_s hata]
        mR = olcut(oR, p, hedef(j), s0(j), B(j));  mP = olcut(oP, p, hedef(j), s0(j), B(j));
        ayr = find(KC(:,5) ~= KT.sh | KC(:,6) ~= KT.ykF, 1);
        if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
        du = max(abs(KC(:,1) - KT.uM));
        dth = max(abs(rad2deg(oP.th - oR.th)));
        rt = KC(:,8)*1e3;  kayip = sum(KC(:,9));
        fprintf("%3d %-22s | %d / %d      | %+.3f / %+.3f | %.3f / %.3f    | %5.3f / %5.3f   | %d / %d      | %-22s | %.2e    | %.2e   | %.2f / %.2f / %.2f | %d     | %.1f\n", ...
            j, sprintf("%.2f>%.1f %s %s", I(j), hedef(j), char('a' + (Y(j) < 0)*('u'-'a')), bozAd{B(j)}), ...
            mP.h7, mR.h7, mP.e, mR.e, mP.emax, mR.emax, mP.b13, mR.b13, mP.yok, mR.yok, ayrS, du, dth, ...
            mean(rt), prctile(rt, 99), max(rt), kayip, sure);
        S(a,j).mP = mP;  S(a,j).mR = mR;  S(a,j).ayr = ayr;  S(a,j).du = du;  S(a,j).dth = dth;
        S(a,j).rt = single(rt);  S(a,j).cyc = single(KC(:,7));  S(a,j).kayip = kayip;  S(a,j).sure = sure;
        S(a,j).u = single([KC(:,1) KT.uM]);
    end
end

% --- özet ---
fprintf("\n=== Özet ===\n");
for a = 1:size(sur,1)
    s = S(a,1:nK);  mP = [s.mP];  mR = [s.mR];
    ay = arrayfun(@(x) ~isempty(x.ayr), s);
    rt = vertcat(s.rt);  cy = vertcat(s.cyc)/F*1e6;
    fprintf("%s: H7 PIL %d/%d, referans %d/%d; B12 PIL %d, ref %d; en kötü |e| PIL %.3f°, ref %.3f°; B13 en çok PIL %.3f°, ref %.3f°\n", ...
        sur{a,1}, nnz([mP.h7]), nK, nnz([mR.h7]), nK, nnz([mP.b12]), nnz([mR.b12]), ...
        max(abs([mP.e])), max(abs([mR.e])), max([mP.b13], [], 'omitnan'), max([mR.b13], [], 'omitnan'));
    fprintf("   kart-gölge ayrık kararlar tümüyle aynı: %d/%d; en büyük |du| %.2e N m; en büyük |th PIL - th ref| %.3f°\n", ...
        nnz(~ay), nK, max([s.du]), max([s.dth]));
    fprintf("   tur (MATLAB gidiş-dönüş) ms: ort %.3f, p50 %.3f, p99 %.3f, en uzun %.2f, > 10 ms %d tur; kart adımı µs: ort %.2f, en uzun %.2f; kayıp %d; senaryo başına %.1f s\n", ...
        mean(rt), median(rt), prctile(rt, 99), max(rt), nnz(rt > 10), mean(cy, 'omitnan'), max(cy), sum([s.kayip]), mean([s.sure]));
end
ist = esp32_istat(sp, siraNo());
fprintf("kart sayaçları (bu koşu): paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d\n", ...
    ist.paketOk - ist0.paketOk, ist.crcHata - ist0.crcHata, ist.siraAtlama - ist0.siraAtlama, ...
    ist.copBayt - ist0.copBayt, ist.uzunHata - ist0.uzunHata);
save("pil.mat", "S", "hedef", "I", "Y", "B", "nK");
diary off;
end

function [u, c] = kartAdim(sp, p, thRef, kpv, yuz0, kc, sayim, v, uo, c0)
% Bir kontrol örneği kartta. kc == 1'de kart bu senaryonun ayarıyla başlatılır.
% Zaman aşımı / bozuk cevapta son u tutulur, hata bayrağı 1 (kayıp sayılır).
persistent uSon
if ischar(sp), uSon = 0; return; end               % 'sifirla'
if kc == 1                                          % başlatma: tek seferlik aksamaya karşı 3 deneme
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

function m = olcut(o, p, hedef, s0, B)
% H7 / B12 / B13 (hiz_gozlemci.m ile aynı tanımlar), tek senaryo.
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end)-1;
gy = sign(o.delta).*(abs(o.delta) >= p.r);
m.b12 = sign(sum(gy(son))) == s0;
m.e = mean(sap(son));  m.emax = max(abs(sap(son)));
m.h7 = abs(m.e) <= 0.5 && m.emax <= 1 && m.b12;
m.b13 = rad2deg(o.yokKol);  if B == 2, m.b13 = NaN; end
m.yok = o.yokSay;
end
