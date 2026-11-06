function esp32_yaz(sp, p)
% ESP32_YAZ  uint8 vektörü seri porta yazar.
p = uint8(p(:).');
sp.Write(p, 0, numel(p));
end
