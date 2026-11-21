function d = b2_disli_ofset(tau, tp, Kp, r, Ks, s0)
% B2_DISLI_OFSET  Makas dişlinin durağan eğrisinin tersi: tau_s(d) = tau (kol_benzetim p.onYuk modeli).
%   taup = 0 olan elemanlar dişlisiz (Kp = 0): B1 tablosu s0 r + tau/Ks.
d = s0*r + tau/Ks;
j = tp > 0;
t = tau(j);  p = tp(j);  k = Kp(j);  dd = zeros(size(t));
A = t >= -p;                                         % A yüzü: (Ks + Kp)(d - r) - taup
dd(A) = r + (t(A) + p(A))./(Ks + k(A));
Y = ~A & t >= -p - 2*r*k;                            % yay esniyor: -(taup + Kp(r - d))
dd(Y) = r + (t(Y) + p(Y))./k(Y);
B = ~A & ~Y;                                         % B dayanağında
dd(B) = (t(B) + p(B) + k(B)*r - Ks*r)./(Ks + k(B));
d(j) = dd;
end
