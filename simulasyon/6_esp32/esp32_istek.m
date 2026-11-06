function [yuk, tip] = esp32_istek(sp, tip, sira, yuk, cevapUzun)
% ESP32_ISTEK  Bir paket gönderir, cevabı bekler ve doğrular (adım kilitli).
%   sp: esp32_ac'ın döndürdüğü .NET SerialPort.
%   cevapUzun: cevaptaki yük baytı (bilinmeli; okuma tek seferde yapılır).
esp32_yaz(sp, prot_paketle(tip, sira, yuk));
c = esp32_oku(sp, 8 + cevapUzun);
[tip, sira2, yuk, tamam] = prot_coz(c);
if ~tamam, error("esp32:bozuk", "cevap paketi bozuk"); end
if sira2 ~= mod(sira, 65536), error("esp32:sira", "sıra no tutmadı"); end
end
