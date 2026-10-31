function [dx, ts] = tesis(x, u, t, S)
% İki kütle + dişli teması (kol tarafına indirgenmiş). kol_benzetim.m / f(x) ile aynı.
phi = x(1);  dphi = x(2);  th = x(3);  dth = x(4);
d = phi - th;  dd = dphi - dth;
ts = 0;
if d > S.r
    ts = max(S.Ks*(d - S.r) + S.cs*dd, 0);     % temas yalnız iter, çekmez
elseif d < -S.r
    ts = min(S.Ks*(d + S.r) + S.cs*dd, 0);
end
tf = 0;
if S.Fc > 0                                    % yumuşatılmış Stribeck sürtünmesi
    tf = (S.Fc + (S.Fs - S.Fc)*exp(-(dphi/S.vs)^2)) * tanh(dphi/S.veps);
end
bz = 0;
if t < S.dT
    bz = S.dA*sin(2*pi*S.df*t);                % yük bozucusu
end
dx = [dphi;
      (u - S.bM*dphi - tf - ts)/S.JM;
      dth;
      (ts - S.bL*dth - S.mgl*sin(th) + bz)/S.JL];
end
