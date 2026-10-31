function [u, st1, v] = ayrik(x, st, t, S)
% v: kontrolcünün kullandığı hız (sürücünün zıt EMK kompanzasyonu için dışarı verilir)
% Sensör + kontrolcü, durumsuz yazım (Simscape modeli için). blok_sensor + blok_kontrolcu ile aynı hesap;
% durumlar persistent yerine dışarıdaki Unit Delay'de tutulur: st = [tampon(21); vhat; yprev; z].
% Böylece Simscape ağının (Hard Stop yüzünden) yapısal cebirsel döngüsünü Simulink çözebilir.
%
% Deney kaynağı (firmware'in üreteceği sinyal, Ts örneklemeli; sim_param'daki S.dny_*):
%   S.dny_yer = 0  yok (kontrolcü olduğu gibi)
%               1  referansa eklenir:      e = ref + d - thm          (kapalı çevrim konum uyarımı)
%               2  tork komutuna eklenir:  u0 = kontrolcü + d          (kapalı çevrim tork enjeksiyonu)
%               3  açık çevrim:            u0 = dny_u0 + d, kontrolcü kapalı, integral donuk
%   d = dny_A * şekil(t - dny_t0), yalnız dny_t0 <= t < dny_t0 + dny_Td:
%     S.dny_sek = 1 dikdörtgen (basamak; kısa Td ile darbe), 2 doğrusal chirp f0 -> f1,
%                 3 logaritmik chirp f0 -> f1, 4 sinüs (sabit f0)
%   Serbest salınım: dny_yer = 3, dny_A = 0, dny_u0 = 0 ve başlangıç sapması (p.adim / p.x0).
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
% --- deney kaynağı ---
d = 0;
if S.dny_yer > 0, d = kaynak(t, S); end
% --- kontrolcü ---
e = S.ref - thm;
if S.dny_yer == 1, e = e + d; end
if S.ppi > 0
    ev = S.kp*e - v;
    u0 = S.KV*ev + S.KI*z;
    iz = ev;
else
    u0 = S.Kp*e + S.Ki*z - S.Kd*v;
    iz = e;
end
if S.dny_yer == 2, u0 = u0 + d; end
acik = S.dny_yer == 3;
if acik, u0 = S.dny_u0 + d; end
u = min(max(u0, -S.Tmax), S.Tmax);
doy = (u0 > S.Tmax && iz > 0) || (u0 < -S.Tmax && iz < 0);
if ~doy && ~acik, z = z + iz*S.Ts; end
if abs(u) < S.olu, u = 0; end
st1 = [buf; vhat; yprev; z];
end

function y = olc(x, q)
y = x;
if q > 0, y = q*floor(x/q); end
end

function d = kaynak(t, S)
d = 0;
tau = t - S.dny_t0;
if tau < 0 || tau >= S.dny_Td, return; end
switch S.dny_sek
    case 1
        s = 1;
    case 2      % anlık frekans f0 + (f1 - f0) tau / Td
        s = sin(2*pi*(S.dny_f0*tau + (S.dny_f1 - S.dny_f0)*tau^2/(2*S.dny_Td)));
    case 3      % anlık frekans f0 (f1/f0)^(tau/Td)
        k = log(S.dny_f1/S.dny_f0)/S.dny_Td;
        s = sin(2*pi*S.dny_f0*(exp(k*tau) - 1)/k);
    otherwise
        s = sin(2*pi*S.dny_f0*tau);
end
d = S.dny_A*s;
end
