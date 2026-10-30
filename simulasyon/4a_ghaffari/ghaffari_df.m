function d = ghaffari_df(p, kp, kv)
% GHAFFARI_DF  Tanımlama fonksiyonu (DF) ile kalıcı çevrim öngörüsü (Ghaffari 2013, Bölüm VI-A).
% Şekil 5: thd/thref = G/(1 + n(thd) G H). n gerçel ve 0..1 olduğundan çevrim,
% G(jw)H(jw) gerçel eksenin -1'den solunu kestiği frekansta (faz -180) oluşur:
%   n = -1/Re{GH(jw_cr)}   (0 < n < 1 ise çevrim var; n -> thd/delta denklem 10'dan)
% G H (denklem 5, 6; kp(kv Ti s + 1) sadeleşir):
%   GH = [Ti Jt s^3 + Ti(ct+kv) s^2 + (kp kv Ti + 1) s + kp] /
%        [(Ti Jm s^3 + Ti(cm+kv) s^2 + s) ((s/wa)^2 + 2 xil s/wa)]
% Re{GH} >= -1 ise n = 1'de bile döngü kararsız: makaledeki gibi "mekanik rezonans",
% frekans wa (d.rez). Coulomb sürtünme DF'de yok (makaledeki gibi). Denklem 12 de raporlanır.
kp = kp(:)';  kv = kv(:)';  n = numel(kp);
Jt = p.Jm + p.Jle;  ct = p.cm + p.cle;
xil = p.cle*p.wa/(2*p.kse);                        % cl s/ks = 2 xil s/wa
w = linspace(0.2, 3, 60000)*p.wa;                  % arama aralığı
s = 1i*w;
d.f_cr = nan(1,n);  d.n = nan(1,n);  d.A_deg = nan(1,n);  d.ReGH = nan(1,n);
for j = 1:n
    N  = p.Ti*Jt*s.^3 + p.Ti*(ct+kv(j))*s.^2 + (kp(j)*kv(j)*p.Ti+1)*s + kp(j);
    D  = (p.Ti*p.Jm*s.^3 + p.Ti*(p.cm+kv(j))*s.^2 + s) .* ((s/p.wa).^2 + 2*xil*s/p.wa);
    GH = N./D;
    k  = find(imag(GH(1:end-1)).*imag(GH(2:end)) < 0 & real(GH(1:end-1)) < 0);
    if isempty(k), continue; end
    % en düşük faz geçişi; doğrusal ara değer
    k = k(1);  a = imag(GH(k))/(imag(GH(k))-imag(GH(k+1)));
    wc = w(k) + a*(w(k+1)-w(k));  re = real(GH(k)) + a*(real(GH(k+1))-real(GH(k)));
    d.ReGH(j) = re;  d.f_cr(j) = wc/(2*pi);
    if re < -1
        d.n(j) = -1/re;
        d.A_deg(j) = rad2deg(p.delta*ters_n(d.n(j)));
    end
end
d.var = d.n > 0 & d.n < 1;                          % DF çevrim öngörüyor mu
d.rez = ~isnan(d.ReGH) & d.ReGH >= -1;             % mekanik rezonans (kararsız)
d.f_df = zeros(1,n);  d.f_df(d.var) = d.f_cr(d.var);  d.f_df(d.rez) = p.fa;
d.f_eq12 = sqrt(kp.*kv/p.Jle)/(2*pi);
d.rgs = sqrt(kp.*kv/p.kse);
end

function x = ters_n(nn)
% Denklem 10'un tersi: n(x) = 1 - (2/pi)(asin(1/x) + (1/x)sqrt(1-1/x^2)), x = thd/delta > 1
x = fzero(@(x) 1 - 2/pi*(asin(1/x) + sqrt(1-1/x^2)/x) - nn, [1+1e-12 1e8]);
end
