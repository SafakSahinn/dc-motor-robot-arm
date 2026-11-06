function c = esp32_oku(sp, n)
% ESP32_OKU  Tam n bayt okur (uint8 satır). Zaman aşımında hata verir
%   (kimlik "esp32:zamanAsimi"); o ana dek gelen baytlar atılır.
persistent buf N
if isempty(buf) || N < n
    N = max(4096, n);
    buf = NET.createArray('System.Byte', N);
end
got = 0;
try
    while got < n
        got = got + sp.Read(buf, got, n - got);
    end
catch e
    error("esp32:zamanAsimi", "cevap gelmedi (%d/%d bayt): %s", got, n, e.message);
end
c = uint8(buf);
c = c(1:n);
end
