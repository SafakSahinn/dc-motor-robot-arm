function ist = esp32_istat(s, sira)
% ESP32_ISTAT  Kartın sayaçlarını okur (protokol.h: struct Istat, 9 x uint32).
yuk = esp32_istek(s, 2, sira, uint8([]), 36);
v = double(typecast(uint8(yuk), 'uint32'));
ad = ["paketOk" "crcHata" "siraAtlama" "copBayt" "uzunHata" "baud" ...
      "islemMaksUs" "calismaMs" "txDurtme"];
ist = cell2struct(num2cell(v(:)), cellstr(ad), 1);
end
