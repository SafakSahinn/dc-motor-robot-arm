function [K, sure] = esp32_ikiz_oku(sp, sira, bas, adet)
% ESP32_IKIZ_OKU  Kart içi ikizin kaydını toplu çeker (T_IKIZ_OKU, 0x23).
%   Paket başına 18 örnek (ikiz::Kayit 13 B), sıra no = parça indisi. K alanları (sütun):
%     K.eTh (th - thRef, rad), K.dl (phi - th, rad), K.u (N m), K.sh (+1/-1), K.ykF (0..4).
%   Her satır bir kontrol örneğinin (1 ms) SONUNDAKİ durum ve o örneğin kontrol çıktısıdır
%   (kol_benzetim dec = 10 kaydıyla aynı anlar). sure: s.
KP = 18;  B = 13;
np = ceil(adet / KP);
son = mod(adet, KP); if son == 0, son = KP; end
topBayt = (np - 1) * (8 + KP * B) + (8 + son * B);
t0 = tic;
esp32_yaz(sp, prot_paketle(35, sira, [typecast(uint32(bas), 'uint8') typecast(uint32(adet), 'uint8')]));
c = esp32_oku(sp, topBayt);
sure = toc(t0);
ham = zeros(B, adet, 'uint8');
i = 1; k = 0;
for j = 0:np-1
    m = KP; if j == np - 1, m = son; end
    [tip, sq, y, ok] = prot_coz(c(i:i + 7 + m * B));
    if ~ok || tip ~= 163 || sq ~= j, error("esp32:bozuk", "ikiz kayıt paketi %d bozuk", j); end
    ham(:, k + 1:k + m) = reshape(y, B, m);
    i = i + 8 + m * B; k = k + m;
end
fl = @(r) double(typecast(reshape(ham(r, :), 1, []), 'single')).';
K.eTh = fl(1:4);  K.dl = fl(5:8);  K.u = fl(9:12);
b = double(ham(13, :)).';
K.sh = 2*bitand(b, 1) - 1;  K.ykF = bitshift(b, -1);
end
