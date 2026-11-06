function crc = prot_crc16(v)
% PROT_CRC16  CRC16-CCITT-FALSE (poli 0x1021, başlangıç 0xFFFF), tablo ile.
%   Firmware'deki prot::crc16 ile aynı sonucu verir. Sınama: '123456789'
%   için 0x29B1.
persistent T
if isempty(T)
    T = zeros(1, 256);
    for i = 0:255
        c = bitshift(i, 8);
        for k = 1:8
            if bitand(c, 32768)
                c = bitxor(bitand(bitshift(c, 1), 65535), 4129);
            else
                c = bitand(bitshift(c, 1), 65535);
            end
        end
        T(i + 1) = c;
    end
end
crc = 65535;
v = double(v);
for i = 1:numel(v)
    crc = bitxor(bitand(bitshift(crc, 8), 65535), ...
                 T(bitxor(bitshift(crc, -8), v(i)) + 1));
end
end
