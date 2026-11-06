% DONGU_OLCUM  Adım 3: kartın 1 kHz kontrol görevi, döngü süresi ve jitter.
%   Firmware: kontrol görevi çekirdek 1'de (donanım zamanlayıcısı kesmesiyle
%   uyanır), haberleşme çekirdek 0'da. Her tur için periyot, kesme → görev
%   uyanma gecikmesi ve kontrol adımının süresi CPU çevrimiyle (240 MHz)
%   kaydedilir; kayıt tamponu MATLAB'a toplu çekilir (esp32_kayit_oku).
%   Çalıştırma (bu klasörden):  matlab -batch "dongu_olcum"
%   Çıktı: dongu_olcum_log.txt, dongu_olcum.mat, dongu_olcum.png
%
%   Koşullar (her biri 10 000 tur = 10 s):
%     A) hafif yük (sahte adım ~20 µs), seri hat sessiz
%     B) hafif yük, kayıt boyunca kesintisiz yankı trafiği (PIL benzeri)
%     C) ağır yük (sahte adım ~300 µs), kesintisiz yankı trafiği
clear; clc;
diary off; if isfile("dongu_olcum_log.txt"), delete("dongu_olcum_log.txt"); end
diary("dongu_olcum_log.txt");
fprintf("=== dongu_olcum %s ===\n", string(datetime("now")));

PORT = "COM4"; BAUD = 1500000; F = 240e6;   % CPU çevrim frekansı
N = 10000;
kos = struct("ad", {"A sessiz, hafif", "B trafik, hafif", "C trafik, agir"}, ...
             "iter", {300, 300, 4800}, "trafik", {false, true, true});

sp = esp32_ac(PORT, 921600);
temizle = onCleanup(@() esp32_kapat(sp));
sira = 1; esp32_istek(sp, 4, sira, typecast(uint32(BAUD), 'uint8'), 4);
sp.BaudRate = BAUD; pause(0.1); sp.DiscardInBuffer();
yuk = typecast(single(randn(1, 6)), 'uint8');
sonuc = struct([]);

for c = kos
    fprintf("\n--- %s (iter %d) ---\n", c.ad, c.iter);
    sira = sira + 1;
    d = esp32_durum(sp, sira, 16, [typecast(uint32(N), 'uint8') typecast(uint32(c.iter), 'uint8')]);
    nYanki = 0; rtt = zeros(0, 1); t0 = tic;
    while d.durum ~= 2
        if c.trafik
            for k = 1:200     % adım kilitli yankı, PIL'deki gibi
                sira = sira + 1; t1 = tic;
                esp32_istek(sp, 1, sira, yuk, numel(yuk));
                rtt(end + 1, 1) = toc(t1); %#ok<SAGROW>
            end
            nYanki = nYanki + 200;
        else
            pause(0.5);
        end
        sira = sira + 1; d = esp32_durum(sp, sira);
        if toc(t0) > 30, error("kayit bitmedi"); end
    end
    sira = sira + 1;
    [K, sure] = esp32_kayit_oku(sp, sira, 0, d.kayitN);
    sira = sira + 1; ist = esp32_istat(sp, sira);
    fprintf("kart sayaclari: paketOk %d, crcHata %d, siraAtlama %d, copBayt %d\n", ...
            ist.paketOk, ist.crcHata, ist.siraAtlama, ist.copBayt);
    sira = sira + 1; esp32_istek(sp, 3, sira, uint8([]), 0);  % sayaçları sıfırla
    kB = d.kayitN * 8 / 1e3;
    fprintf("kayit cekme: %d kayit (%.1f kB) %.3f s, %.1f kB/s\n", d.kayitN, kB, sure, kB / sure);

    per = K.periyotCyc / F * 1e6; gec = K.gecikmeCyc / F * 1e6; is = K.isCyc / F * 1e6;
    sap = per - 1000;
    fprintf("periyot us: ort %.4f  min %.3f  max %.3f  | sapma p99 %.3f  max|.| %.3f\n", ...
            mean(per), min(per), max(per), prctile(abs(sap), 99), max(abs(sap)));
    fprintf("uyanma gecikmesi us: p50 %.2f  p99 %.2f  max %.2f\n", prctile(gec, [50 99 100]));
    fprintf("kontrol adimi us: p50 %.2f  p99 %.2f  max %.2f\n", prctile(is, [50 99 100]));
    fprintf("kacan kesme: %d,  karttaki maks: per %.3f us, gec %.2f us, is %.2f us\n", ...
            d.kacan, d.perMaxCyc / F * 1e6, d.gecMaxCyc / F * 1e6, d.isMaxCyc / F * 1e6);
    if c.trafik
        fprintf("es zamanli yanki: %d paket, RTT p50 %.3f ms p99 %.3f ms\n", ...
                nYanki, prctile(rtt * 1e3, [50 99]));
    end
    r = struct("ad", c.ad, "iter", c.iter, "trafik", c.trafik, "per", per, ...
               "gec", gec, "is", is, "kacan", d.kacan, "nYanki", nYanki, ...
               "rtt", rtt, "cekmeSure", sure);
    sonuc = [sonuc r]; %#ok<AGROW>
end
clear temizle

% --- Özet ---
fprintf("\n=== ozet (1 kHz, N = %d tur/kosul) ===\n", N);
fprintf("%-18s %10s %10s %10s %10s %10s %6s\n", "kosul", "|sap|p99", "|sap|max", ...
        "gec p99", "gec max", "is max", "kacan");
for r = sonuc
    fprintf("%-18s %8.3fus %8.3fus %8.2fus %8.2fus %8.1fus %6d\n", r.ad, ...
            prctile(abs(r.per - 1000), 99), max(abs(r.per - 1000)), ...
            prctile(r.gec, 99), max(r.gec), max(r.is), r.kacan);
end
save("dongu_olcum.mat", "sonuc", "N", "F");
dongu_olcum_ciz;
fprintf("\nbitti.\n");
diary off;
