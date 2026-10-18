% KARARLILIK_KONTROL  Boşluksuz (r = 0) sistemde, iki türev seçeneği için
% hangi kapalı çevrim hızlarının doğrusal olarak kararlı olduğunu gösterir.
% Boşluksuz sistemde kalıcı salınım olmamalı; olursa döngünün kendisi kararsız.
wcs = 5:5:60;
for src = {'kol','motor'}
    p = parametreler();  p.r = 0;  p.Dkaynak = src{1};
    o = kol_benzetim(p, 90*ones(size(wcs)), wcs);
    fprintf('\nTurev kaynagi: %s  (bosluksuz, 90 derece)\n', src{1});
    fprintf('%6s %10s %8s\n','wc','A [der]','f [Hz]');
    for j = 1:numel(wcs)
        % boşluksuzda kenar değişimi anlamsız; frekansı kol açısının sıfır geçişinden bul
        y = rad2deg(o.th(:,j)) - mean(rad2deg(o.th(:,j)));
        fz = sum(abs(diff(sign(y)))>0)/2/p.Tan;
        fprintf('%6g %10.4f %8.2f\n', wcs(j), o.A_deg(j), fz);
    end
end
