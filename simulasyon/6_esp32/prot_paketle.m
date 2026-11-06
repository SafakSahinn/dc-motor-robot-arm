function p = prot_paketle(tip, sira, yuk)
% PROT_PAKETLE  ESP32 ikili paketini çerçeveler (firmware/src/protokol.h).
%   [A5 5A][tip][sira L H][uzunluk][yük][crc L H], crc = CRC16-CCITT-FALSE
%   (tip..yük üzerinden). yuk: uint8 satır vektörü (boş olabilir).
if nargin < 3, yuk = uint8([]); end
yuk = uint8(yuk(:).');
sira = uint16(mod(sira, 65536));
govde = [uint8(tip), typecast(sira, 'uint8'), uint8(numel(yuk)), yuk];
crc = prot_crc16(govde);
p = [uint8([165 90]), govde, typecast(uint16(crc), 'uint8')];
end
