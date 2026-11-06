function [K, sure] = esp32_kayit_oku(sp, sira, bas, adet)
% ESP32_KAYIT_OKU  Kayıt tamponunu toplu çeker (T_KAYIT_OKU, 0x12).
%   Kart istenen aralığı art arda paketlerle gönderir (paket başına 30 kayıt,
%   sıra no = parça indisi). K: alanları sütun olan yapı (çevrim cinsinden):
%     K.periyotCyc, K.gecikmeCyc, K.isCyc (= isCyc4*4). sure: s.
KP = 30;  % protokol.h: KAYIT_PAKET
np = ceil(adet / KP);
son = mod(adet, KP); if son == 0, son = KP; end
topBayt = (np - 1) * (8 + KP * 8) + (8 + son * 8);
t0 = tic;
esp32_yaz(sp, prot_paketle(18, sira, [typecast(uint32(bas), 'uint8') typecast(uint32(adet), 'uint8')]));
c = esp32_oku(sp, topBayt);
sure = toc(t0);
ham = zeros(8, adet, 'uint8');
i = 1; k = 0;
for j = 0:np-1
    m = KP; if j == np - 1, m = son; end
    [tip, sq, y, ok] = prot_coz(c(i:i + 7 + m * 8));
    if ~ok || tip ~= 146 || sq ~= j, error("esp32:bozuk", "kayit paketi %d bozuk", j); end
    ham(:, k + 1:k + m) = reshape(y, 8, m);
    i = i + 8 + m * 8; k = k + m;
end
K.periyotCyc = double(typecast(reshape(ham(1:4, :), 1, []), 'uint32')).';
K.gecikmeCyc = double(typecast(reshape(ham(5:6, :), 1, []), 'uint16')).';
K.isCyc = 4 * double(typecast(reshape(ham(7:8, :), 1, []), 'uint16')).';
end
