function [tm, ta] = yuk(x, u, t, S)
% Simscape modelinde fiziksel ağa verilen torklar (Simulink tarafında hesaplanır):
%   tm: motor eylemsizliğine etkiyen net tork = kontrolcü torku - Stribeck sürtünmesi
%   ta: kola etkiyen dış tork = yerçekimi + yük bozucusu
% Viskoz sürtünmeler (bM, bL) ve dişli teması Simscape bloklarındadır.
dphi = x(2);  th = x(3);
tf = 0;
if S.Fc > 0
    tf = (S.Fc + (S.Fs - S.Fc)*exp(-(dphi/S.vs)^2)) * tanh(dphi/S.veps);
end
tm = u - tf;
bz = 0;
if t < S.dT
    bz = S.dA*sin(2*pi*S.df*t);
end
ta = -S.mgl*sin(th) + bz;
end
