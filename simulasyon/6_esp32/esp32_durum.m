function d = esp32_durum(sp, sira, tip, yuk)
% ESP32_DURUM  1 kHz döngünün durumunu okur (protokol.h: struct Durum).
%   tip = 17 (0x11, yalnız oku) ya da 16 (0x10, kaydı başlat; yuk gerekli).
if nargin < 3, tip = 17; yuk = uint8([]); end
[y, t] = esp32_istek(sp, tip, sira, yuk, 40);
if t ~= bitor(tip, 128), error("esp32:hata", "kart istegi reddetti (tip %d)", t); end
v = double(typecast(uint8(y), 'uint32'));
ad = ["durum" "kayitN" "hedefN" "tick" "kacan" "yukIter" "perMinCyc" ...
      "perMaxCyc" "gecMaxCyc" "isMaxCyc"];
d = cell2struct(num2cell(v(:)), cellstr(ad), 1);
end
