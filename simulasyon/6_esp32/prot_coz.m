function [tip, sira, yuk, tamam] = prot_coz(p)
% PROT_COZ  Tek bir tam paketi (uint8 vektör) çözer ve doğrular.
%   tamam = başlık, uzunluk ve CRC doğruysa true.
p = uint8(p(:).');
tip = 0; sira = 0; yuk = uint8([]); tamam = false;
if numel(p) < 8 || p(1) ~= 165 || p(2) ~= 90, return; end
n = double(p(6));
if numel(p) ~= 8 + n, return; end
crc = double(typecast(p(end-1:end), 'uint16'));
if crc ~= prot_crc16(p(3:end-2)), return; end
tip = double(p(3));
sira = double(typecast(p(4:5), 'uint16'));
yuk = p(7:6+n);
tamam = true;
end
