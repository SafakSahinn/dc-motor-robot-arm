function [u, st1, v, m] = ayrik(x, st, t, S)
% m: firmware'in Ts'de kaydedeceği ölçümler [th_L (AS5600, gecikmeli); phi (enkoder); v (kestirim); u]
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
%
% Hız kestirimi (S.hiz; fv = Inf ise hepsi yerine gerçek hız):
%   0 fark      (y_k - y_{k-1})/Ts + birinci dereceden alçak geçiren (kesim fv)        [varsayılan]
%   1 periyot   son iki enkoder kenarı arasındaki süre: v = n q / (t_kenar - t_önceki_kenar).
%               Kenar zamanı donanımda GPIO kesmesi + µs sayaçla damgalanır; burada iki örnek arasında
%               gerçek açının doğrusal aradeğerlemesiyle bulunur. Yön değişince v = 0. Kenar gelmezse
%               |v| <= q / (t - t_son_kenar) (yavaşlayınca sıfıra iner). Filtre yok.
%   2 gozlemci  ikinci dereceden izleme gözlemcisi (Euler, Ts): e = y - th_hat,
%               th_hat += Ts (w_hat + 2 wo e), w_hat += Ts wo^2 e, wo = 2 pi fv (kritik sönümlü)
% Ek durumlar st(25:28): periyot [phi_önceki (gerçek), t_son_kenar, yön, v]; gozlemci [th_hat, w_hat, 0, 0].
buf = st(1:21);  vhat = st(22);  yprev = st(23);  z = st(24);  ek = st(25:28);
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
elseif S.hiz == 1
    [v, ek] = periyot(x(vi), t, ek, qv, S.Ts);
    yprev = olc(x(vi), qv);
elseif S.hiz == 2
    yv = olc(x(vi), qv);
    wo = 2*pi*S.fv;
    e_o = yv - ek(1);
    ek(1) = ek(1) + S.Ts*(ek(2) + 2*wo*e_o);
    ek(2) = ek(2) + S.Ts*wo^2*e_o;
    v = ek(2);
    yprev = yv;
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
st1 = [buf; vhat; yprev; z; ek];
m = [thm; olc(x(1), S.qM); v; u];   % firmware kaydı: AS5600 (gecikmeli), enkoder, hız kestirimi, tork komutu
end

function [v, ek] = periyot(phi, t, ek, q, Ts)
% ek = [phi_önceki, t_son_kenar, yön, v]. t_son_kenar < 0: henüz kenar yok.
phip = ek(1);  tl = ek(2);  yon = ek(3);  v = ek(4);
n1 = floor(phi/q);  n0 = floor(phip/q);
if n1 ~= n0
    d = sign(n1 - n0);
    if d > 0, sev = n1*q; else, sev = (n1 + 1)*q; end         % son geçilen kenar
    a = (sev - phip)/(phi - phip);  a = min(max(a, 0), 1);
    te = t - Ts + a*Ts;                                        % kenar zamanı (aradeğerleme)
    if d == yon && tl >= 0 && te > tl
        v = d*abs(n1 - n0)*q/(te - tl);
    else
        v = 0;                                                 % ilk kenar ya da yön değişimi
    end
    tl = te;  yon = d;
elseif tl >= 0 && t > tl
    vs = q/(t - tl);                                           % kenar gelmedikçe hız sınırı düşer
    if abs(v) > vs, v = sign(v)*vs; end
end
ek = [phi; tl; yon; v];
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
