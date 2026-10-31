function [u, st1] = ayrik(x, st, S)
% Sensör + kontrolcü, durumsuz yazım (Simscape modeli için). blok_sensor + blok_kontrolcu ile aynı hesap;
% durumlar persistent yerine dışarıdaki Unit Delay'de tutulur: st = [tampon(21); vhat; yprev; z].
% Böylece Simscape ağının (Hard Stop yüzünden) yapısal cebirsel döngüsünü Simulink çözebilir.
buf = st(1:21);  vhat = st(22);  yprev = st(23);  z = st(24);
vi = 3;  qv = S.qL;
if S.motorD > 0, vi = 1;  qv = S.qM; end
% --- sensör ---
thm = olc(x(3), S.qL);
if S.gL > 0
    buf = [buf(2:end); thm];
    thm = buf(21 - S.gL);
end
if S.fv_inf > 0
    v = x(vi + 1);
else
    yv = olc(x(vi), qv);
    vhat = vhat + S.aV*((yv - yprev)/S.Ts - vhat);
    yprev = yv;
    v = vhat;
end
% --- kontrolcü ---
e = S.ref - thm;
if S.ppi > 0
    ev = S.kp*e - v;
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
st1 = [buf; vhat; yprev; z];
end

function y = olc(x, q)
y = x;
if q > 0, y = q*floor(x/q); end
end
