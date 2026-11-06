% KTL_ESDEGER  Adım 4 doğrulaması: kartın C++ algoritması (firmware/src/kontrol.cpp) ile
%   kol_benzetim.m'nin kontrolcüsü aynı girdide aynı çıktıyı veriyor mu (AÇIK DÖNGÜ).
%   1) İkiz 42 senaryoyu (akim_gurultu.m'deki "INA228 taban": 1 kHz, AS5600 motor milinde,
%      0,4 ms gecikme, 0,043° gürültü, gözlemci torku INA228 ölçümünden, akım döngüsü 500 Hz,
%      olay+yoklama, yokOrta 0,6, vDurF 10 Hz) sürtünmeli ve sürtünmesiz koşar; her kontrol
%      örneğinin girdisini (motor sayımı, motor hızı, ölçülen tork) ve çıktısını kaydeder.
%   2) Her senaryo için kart aynı ayarla başlatılır, kaydedilen girdiler 12'şer örneklik
%      paketlerle (T_KTL_ADIM) beslenir, kartın u, w^, d^, s_of, s^, yoklama evresi ve hesap
%      süresi okunur. Kart kendi durumuyla koşar (ikizin durumu kopyalanmaz): ilk ayrışma
%      sonrası da ayrık kararlar ayrı yollara gidebilir, bu yüzden ilk ayrışma örneği raporlanır.
%   3) 1 kHz görevde gerçek algoritmanın hesap süresi (yukIter = 0, sentetik girdi, 10 000 tur).
%   Çalıştırma (bu klasörden):  matlab -batch "ktl_esdeger"
%   Çıktı: ktl_esdeger_log.txt, ktl_esdeger.mat
clear; clc;
diary off; if isfile("ktl_esdeger_log.txt"), delete("ktl_esdeger_log.txt"); end
diary("ktl_esdeger_log.txt");
fprintf("=== ktl_esdeger %s ===\n", string(datetime("now")));
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));

% --- senaryolar (akim_gurultu.m ile aynı kurulum, "INA228 taban" satırı) ---
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.nM = deg2rad(0.043)/p0.N;
p0.yuzKes = 'olay+yoklama';  p0.yokOrta = 0.6;  p0.vDurF = 10;
p0.tOlc = true;  p0.tPen = 0.54e-3;  p0.tGec = 0.1e-3;  p0.akimW = 2*pi*500;
p0.ktlKayit = true;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));  yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);
n = numel(hedef);
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};

PORT = "COM4";  BAUD = 1500000;  F = 240e6;  NP = 12;   % paket başına örnek
sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
sira = 1;  esp32_istek(sp, 4, sira, typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD;  pause(0.1);  sp.DiscardInBuffer();

alan = {'u', 'wh', 'dh', 'sOf'};
S = struct([]);
for a = 1:size(sur,1)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;  p.yuz0 = yuz0;
    t1 = tic;  o = kol_benzetim(p, hedef, kpv*ones(1,n));  KT = o.ktl;
    fprintf("\n--- %s: ikiz %.1f s, %d örnek x %d senaryo ---\n", sur{a,1}, toc(t1), size(KT.u,1), n);
    fprintf("%3s %-22s | ilk ayrışma (s^/evre) | max|du| N m | max|dw^| | max|dd^| N m | max|ds_of| | yokSay ikiz/kart | adım µs ort/p99/max\n", "j", "senaryo");
    for j = 1:n
        % kartı başlat
        sira = sira + 1;
        [y, t] = esp32_istek(sp, 32, sira, ktl_ayar_paketle(p, deg2rad(hedef(j)), KT.ilkSayim(j), kpv, yuz0(j)), 24);
        if t ~= 160, error("T_KTL_BASLAT reddedildi"); end
        % girdileri hazırla: ham (uint16) + v, uo (float)
        N = size(KT.u, 1);
        ham = uint16(mod(KT.sayim(:,j), 4096));
        hb = reshape(typecast(ham(:)', 'uint8'), 2, []);
        fb = reshape(typecast(reshape(single([KT.v(:,j) KT.uo(:,j)])', 1, []), 'uint8'), 8, []);
        G = [hb; fb];                                  % 10 x N
        C = zeros(20, N, 'uint8');
        for b0 = 1:NP:N
            r = b0:min(b0+NP-1, N);
            sira = sira + 1;
            [y, t] = esp32_istek(sp, 33, sira, reshape(G(:,r), 1, []), 20*numel(r));
            if t ~= 161, error("T_KTL_ADIM reddedildi"); end
            C(:, r) = reshape(y, 20, []);
        end
        cf = reshape(typecast(reshape(C(1:16,:), 1, []), 'single'), 4, []);
        K.u = double(cf(1,:))';  K.wh = double(cf(2,:))';  K.dh = double(cf(3,:))';  K.sOf = double(cf(4,:))';
        K.sh = double(typecast(C(17,:), 'int8'))';  K.ykF = double(C(18,:))';
        K.cyc = double(typecast(reshape(C(19:20,:), 1, []), 'uint16'))';
        % karşılaştır
        ayr = find(K.sh ~= KT.sh(:,j) | K.ykF ~= KT.ykF(:,j), 1);
        if isempty(ayr), ayrS = "yok"; else, ayrS = sprintf("%d (%.3f s)", ayr, (ayr-1)*p.Ts); end
        fark = zeros(1, numel(alan));
        for q = 1:numel(alan), fark(q) = max(abs(K.(alan{q}) - KT.(alan{q})(:,j))); end
        ykI = sum(diff([0; KT.ykF(:,j)]) ~= 0 & KT.ykF(:,j) == 1);
        ykK = sum(diff([0; K.ykF]) ~= 0 & K.ykF == 1);
        us = K.cyc / F * 1e6;
        fprintf("%3d %-22s | %-21s | %.2e    | %.2e | %.2e     | %.2e   | %d / %d            | %.2f / %.2f / %.2f\n", j, ...
            sprintf("%.2f>%.1f %s B%d", I(j), hedef(j), char('a' + (Y(j) < 0)*('u'-'a')), B(j)), ...
            ayrS, fark(1), fark(2), fark(3), fark(4), ykI, ykK, mean(us), prctile(us, 99), max(us));
        S(a,j).ayr = ayr;  S(a,j).fark = fark;  S(a,j).us = us;  S(a,j).ykI = ykI;  S(a,j).ykK = ykK;
        S(a,j).u = single([KT.u(:,j) K.u]);
    end
    fprintf('\n');
end

% --- özet ---
fprintf("\n=== Özet ===\n");
for a = 1:size(sur,1)
    ay = arrayfun(@(s) ~isempty(s.ayr), S(a,:));
    fk = vertcat(S(a,:).fark);  us = vertcat(S(a,:).us);
    fprintf("%s: ayrık kararları (s^, evre) tümüyle aynı: %d/%d senaryo; en büyük |du| %.2e N m, |dw^| %.2e rad/s, |dd^| %.2e N m, |ds_of| %.2e\n", ...
        sur{a,1}, nnz(~ay), n, max(fk(:,1)), max(fk(:,2)), max(fk(:,3)), max(fk(:,4)));
    fprintf("   kartta adım süresi (çekirdek 0, PIL bağlamı): ort %.2f µs, p99 %.2f, en uzun %.2f\n", mean(us), prctile(us,99), max(us));
    ilkO = false(size(S(a,1).us));  ilkO(1:NP:end) = true;  ilkO = repmat(ilkO, n, 1);   % paketin ilk örneği
    fprintf("   paketin ilk örneği: ort %.2f µs, en uzun %.2f | diğerleri: ort %.2f, p99 %.2f, en uzun %.2f\n", ...
        mean(us(ilkO)), max(us(ilkO)), mean(us(~ilkO)), prctile(us(~ilkO),99), max(us(~ilkO)));
end

% --- 1 kHz görevde gerçek algoritma (çekirdek 1) ---
fprintf("\n--- 1 kHz görev: gerçek algoritma, sentetik girdi, 10 000 tur ---\n");
sira = sira + 1;  esp32_istek(sp, 32, sira, ktl_ayar_paketle(p, deg2rad(hedef(1)), KT.ilkSayim(1), kpv, yuz0(1)), 24);
sira = sira + 1;
d = esp32_durum(sp, sira, 16, [typecast(uint32(10000), 'uint8') typecast(uint32(0), 'uint8')]);
t0 = tic;
while d.durum ~= 2
    pause(0.5);  sira = sira + 1;  d = esp32_durum(sp, sira);
    if toc(t0) > 30, error("kayit bitmedi"); end
end
sira = sira + 1;  RT = esp32_kayit_oku(sp, sira, 0, d.kayitN);
is = RT.isCyc / F * 1e6;  per = RT.periyotCyc / F * 1e6;
[~, ib] = maxk(is, 5);
fprintf("en uzun 5 tur (tur: µs): %s\n", strjoin(compose("%d: %.1f", ib, is(ib)), ", "));
fprintf("adım süresi µs: ort %.2f, p50 %.2f, p99 %.2f, en uzun %.2f (bütçe ~980); periyot sapması en büyük %.2f µs; kaçan kesme %d\n", ...
    mean(is), median(is), prctile(is, 99), max(is), max(abs(per - 1000)), d.kacan);
sira = sira + 1;  ist = esp32_istat(sp, sira);
fprintf("kart sayaçları: paketOk %d, crcHata %d, siraAtlama %d, copBayt %d\n", ist.paketOk, ist.crcHata, ist.siraAtlama, ist.copBayt);

save("ktl_esdeger.mat", "S", "RT", "hedef", "I", "Y", "B");
diary off;
