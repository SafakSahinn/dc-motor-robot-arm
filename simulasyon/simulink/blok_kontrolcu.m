function u = kontrolcu(thm, v, S)
% PID ya da P-PI kaskat + tork sınırı + basit anti-windup + sürücü ölü bandı.
persistent z
if isempty(z), z = S.z0; end
e = S.ref - thm;
if S.ppi > 0
    ev = S.kp*e - v;                 % hız hatası (kol tarafı)
    u0 = S.KV*ev + S.KI*z;
    iz = ev;
else
    u0 = S.Kp*e + S.Ki*z - S.Kd*v;
    iz = e;
end
u = min(max(u0, -S.Tmax), S.Tmax);
doy = (u0 > S.Tmax && iz > 0) || (u0 < -S.Tmax && iz < 0);
if ~doy, z = z + iz*S.Ts; end
if abs(u) < S.olu, u = 0; end
end
