% SERI_OLCUM  Adım 2: ESP32 ikili protokolünün gecikme ve hız ölçümü.
%   Kartta firmware/ yankı modu yüklü olmalı. Çalıştırma (bu klasörden):
%     matlab -batch "seri_olcum"
%   Çıktı: seri_olcum_log.txt, seri_olcum.mat, seri_olcum.png
%
%   0) Karşılaştırma: MATLAB serialport() ile kısa RTT ölçümü (N = 300).
%   Her baud için (.NET SerialPort ile, bkz. esp32_ac.m):
%   1) Gidiş-dönüş (RTT): PIL büyüklüğünde yük (6 float = 24 B, paket 32 B)
%      gönder → aynı paketi geri bekle. N = 5000. Adım kilitli PIL'in bir
%      turunun alt sınırı budur (kartın hesap süresi ve ikizin adımı hariç).
%   2) Akış hızı: 64 paket tek seferde yazılır, 64 cevap okunur (boru hattı).
%   3) Kart sayaçları: CRC hatası, sıra atlama, çöp bayt.
clear; clc;
diary off; if isfile("seri_olcum_log.txt"), delete("seri_olcum_log.txt"); end
diary("seri_olcum_log.txt");
fprintf("=== seri_olcum %s ===\n", string(datetime("now")));

% --- CRC öz sınaması (standart sınama vektörü) ---
c = prot_crc16(uint8('123456789'));
fprintf("CRC16('123456789') = 0x%04X (beklenen 0x29B1)\n", c);
assert(c == hex2dec('29B1'));

PORT = "COM4";
BAUDLAR = [921600 1000000 1500000 2000000];  % 3 M: .NET/CP210x sürücüsü üst sınırı 2,19 M
N = 5000;            % RTT örnek sayısı
NF = 6;              % yükteki float sayısı (PIL: birkaç sensör + durum)
BLOK = 64; TEKRAR = 40;
rng(1);

% --- MATLAB tarafının kendi yükü (I/O yok): paketle + çöz ---
yuk = typecast(single(randn(1, NF)), 'uint8');
t = tic; for k = 1:2000, p = prot_paketle(1, k, yuk); [~,~,~,ok] = prot_coz(p); end
matlabUs = toc(t) / 2000 * 1e6;
fprintf("MATLAB paketle+coz (I/O'suz): %.1f us/tur\n", matlabUs);

% --- 0) serialport() karşılaştırması ---
fprintf("\n--- karsilastirma: MATLAB serialport(), 921600 baud ---\n");
s = serialport(PORT, 921600, "Timeout", 1);
setDTR(s, false); setRTS(s, true); pause(0.05); setRTS(s, false);
pause(1.0); flush(s);
rttSP = zeros(300, 1);
for k = 1:300
    p = prot_paketle(1, k, yuk);
    t0 = tic; write(s, p, "uint8"); read(s, numel(p), "uint8"); rttSP(k) = toc(t0);
end
clear s
q = prctile(rttSP * 1e3, [0 50 99 100]);
fprintf("serialport RTT ms: min %.3f  p50 %.3f  p99 %.3f  max %.3f\n", q);
fprintf("(Windows zamanlayici adimi 15.625 ms; serialport okuma is parcacigi bu adimla uyaniyor)\n");

% --- .NET SerialPort ile asıl ölçümler ---
sp = esp32_ac(PORT, 921600);
sira = 0;
sonuc = struct([]);

for b = BAUDLAR
    fprintf("\n--- baud %d ---\n", b);
    r = struct("baud", b, "basari", false, "rtt", [], "pps", NaN, ...
               "Bps", NaN, "ist", [], "uyusmaz", 0, "kayip", 0, "not", "");
    try
        % Baud geçişi: onay eski hızda gelir, sonra iki taraf da değişir.
        if sp.BaudRate ~= b
            sira = sira + 1;
            esp32_istek(sp, 4, sira, typecast(uint32(b), 'uint8'), 4);
            sp.BaudRate = b;
            pause(0.1); sp.DiscardInBuffer();
        end
        sira = sira + 1; esp32_istek(sp, 3, sira, uint8([]), 0);  % sayaç sıfırla

        % 1) RTT
        rtt = nan(N, 1);
        for k = 1:N
            sira = sira + 1;
            yuk = typecast(single(randn(1, NF)), 'uint8');
            p = prot_paketle(1, sira, yuk);
            t0 = tic;
            try
                esp32_yaz(sp, p);
                cv = esp32_oku(sp, numel(p));
            catch
                % Kayıp: gecikmiş baytları at, senkronu yeniden kur
                r.kayip = r.kayip + 1;
                pause(0.01); sp.DiscardInBuffer();
                continue
            end
            rtt(k) = toc(t0);
            [tp, sq, yk, okc] = prot_coz(cv);   % süre ölçümünün dışında
            if ~okc || tp ~= 129 || sq ~= mod(sira, 65536) || ~isequal(yk, yuk)
                r.uyusmaz = r.uyusmaz + 1;
            end
        end
        rtt = rtt(~isnan(rtt));
        r.rtt = rtt;
        q = prctile(rtt * 1e3, [0 50 90 99 99.9 100]);
        fprintf("RTT ms: min %.3f  p50 %.3f  p90 %.3f  p99 %.3f  p99.9 %.3f  max %.3f\n", q);
        fprintf("kayip (zaman asimi): %d, bozuk/uyusmayan cevap: %d  (N = %d)\n", ...
                r.kayip, r.uyusmaz, N);

        % 2) Akış hızı (boru hattı)
        pl = cell(1, BLOK);
        topBayt = 0; tt = 0;
        for j = 1:TEKRAR
            for k = 1:BLOK
                sira = sira + 1;
                pl{k} = prot_paketle(1, sira, yuk);
            end
            tum = [pl{:}];
            t0 = tic;
            esp32_yaz(sp, tum);
            cv = esp32_oku(sp, numel(tum));
            tt = tt + toc(t0);
            if ~isequal(cv(7:30), tum(7:30)), r.uyusmaz = r.uyusmaz + 1; end
            topBayt = topBayt + numel(tum);
        end
        r.pps = TEKRAR * BLOK / tt; r.Bps = topBayt / tt;
        fprintf("akis: %.0f paket/s, %.1f kB/s her yon (teorik %.1f kB/s)\n", ...
                r.pps, r.Bps / 1e3, b / 10 / 1e3);

        % 3) Kart sayaçları
        sira = sira + 1;
        r.ist = esp32_istat(sp, sira);
        fprintf("kart: paketOk %d, crcHata %d, siraAtlama %d, copBayt %d, uzunHata %d, baud %d, islemMaks %d us\n", ...
            r.ist.paketOk, r.ist.crcHata, r.ist.siraAtlama, r.ist.copBayt, ...
            r.ist.uzunHata, r.ist.baud, r.ist.islemMaksUs);
        r.basari = true;
    catch e
        r.not = string(e.message);
        fprintf("BASARISIZ: %s\n", e.message);
        % Kartı sıfırla, açılış hızına dön
        esp32_kapat(sp); pause(0.3);
        sp = esp32_ac(PORT, 921600);
        sira = 0;
    end
    sonuc = [sonuc r]; %#ok<AGROW>
end
esp32_kapat(sp);

% --- Özet tablo ---
fprintf("\n=== ozet (.NET SerialPort, 32 B paket) ===\n");
fprintf("%9s %8s %8s %8s %8s %9s %8s %6s %6s\n", "baud", "p50 ms", "p99 ms", ...
        "max ms", "Hz@p50", "paket/s", "kB/s", "kayip", "hata");
for r = sonuc
    if ~r.basari, fprintf("%9d  BASARISIZ (%s)\n", r.baud, strtrim(r.not)); continue; end
    q = prctile(r.rtt * 1e3, [50 99 100]);
    hk = r.uyusmaz + r.ist.crcHata + r.ist.uzunHata;
    fprintf("%9d %8.3f %8.3f %8.3f %8.0f %9.0f %8.1f %6d %6d\n", r.baud, q, ...
            1e3 / q(1), r.pps, r.Bps / 1e3, r.kayip, hk);
end
save("seri_olcum.mat", "sonuc", "N", "NF", "matlabUs", "rttSP");

% --- Histogram (921600 ve en hızlı başarılı baud) ---
seri_olcum_ciz;
fprintf("\nbitti.\n");
diary off;
