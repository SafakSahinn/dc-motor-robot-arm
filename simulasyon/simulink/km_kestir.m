function th = km_kestir(K, W, tbas)
% KM_KESTIR  Zıt EMK denkleminden K_m, R_a (tani_Km). th = [Km Ra c].
%   int V dt = K_m (phi_son - phi_ilk) + R_a int i dt + c (i_son - i_ilk)
% Pencereler örtüşmesiz, boy W [s]; tbas öncesi atılır. c ~ L_a + R_a tau (L_a ile V/i kayıtları arasındaki
% örnekten kısa zaman kaymasının toplamı; bkz. tani_Km). Kayıt 1 kHz olmalı (dec = 1).
% V kaydı ZOH: örnek anındaki komut bir Ts boyunca tutuluyor (mod 1'de doğru). i anlık örnek, yamuk kuralı.
t = K.t;  Ts = t(2) - t(1);  n = round(W/Ts);
s = find(t >= tbas, 1);
nP = floor((numel(t) - s)/n);
A = zeros(nP, 3);  b = zeros(nP, 1);
for k = 1:nP
    j = s + (k-1)*n + (0:n);
    b(k) = Ts*sum(K.V(j(1:end-1)));
    A(k,:) = [K.phi(j(end)) - K.phi(j(1)), trapz(K.i(j))*Ts, K.i(j(end)) - K.i(j(1))];
end
th = A\b;
end
