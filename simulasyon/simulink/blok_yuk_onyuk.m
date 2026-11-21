function [tm, ta] = yuk(x, u, t, S)
% blok_yuk + makas dişlinin B kolu (B2; sm_model_kur(..., onyuk = true) bu dosyayı kullanır):
%   tau_B = max(S.taup + S.KpB (r - delta), 0), delta = phi - th; kola -tau_B, motora +tau_B (iç kuvvet).
% kol_benzetim p.onYuk modeliyle aynı denklem; A teması ve -r dayanağı ağdaki Hard Stop'ta.
dphi = x(2);  th = x(3);
tf = 0;
if S.Fc > 0
    tf = (S.Fc + (S.Fs - S.Fc)*exp(-(dphi/S.vs)^2)) * tanh(dphi/S.veps);
end
tB = max(S.taup + S.KpB*(S.r - (x(1) - x(3))), 0);
tm = u - tf + tB;
bz = 0;
if t >= S.d0 && t < S.dT
    bz = S.dA*sin(2*pi*S.df*(t - S.d0));
end
ta = -S.mgl*sin(th) + bz - tB;
end
