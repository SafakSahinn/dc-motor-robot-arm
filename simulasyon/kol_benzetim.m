function out = kol_benzetim(p, theta0_deg, wc)
% KOL_BENZETIM  İki kütleli kol + dişli boşluğu + yerçekimi + PID benzetimi.
% theta0_deg ve wc aynı boyutlu diziler olabilir: her eleman ayrı bir
% benzetim; hepsi vektör halinde aynı anda çözülür (sabit adımlı RK4).
%
% Durumlar (kol tarafına indirgenmiş):
%   phi  : motor açısı / N           dphi : hızı
%   th   : kol açısı (0 = dik aşağı)  dth  : hızı
% Dişli torku tau_s, phi - th farkı boşluk yarı genişliği r'yi aşınca oluşur.
%
% Kontrolcü her p.Ts saniyede bir çalışır, arada tork sabit tutulur:
%   tau = Kp e + Ki z - Kd v,   e = th_ref - th_ölçülen,  z = sum(e)*Ts
%   v   = motor hızı (p.Dkaynak='motor') ya da kol hızı ('kol');
%   p.gL > 0 ise kol açısı ölçümü gL kontrol örneği gecikmeli kullanılır (AS5600 filtresi + I2C okuması).
%         p.fv sonluysa nicemlenmiş açının farkından + birinci derece filtreyle kestirilir.
% Ardından doyum (+-Tmax) ve sürücü ölü bandı (|tau| < olu -> 0).
% Kazançlar rijit model (J = JM + JL) için kapalı çevrim hızı wc'ye göre:
%   Kp = J wc^2,  Kd = 2*0.7*J*wc,  Ki = Kp*wc/4.
%
% p.kontrol = 'PPI' ise Ghaffari 2013 kaskadı (kol tarafı büyüklüklerle); bu durumda
% üçüncü argüman wc yerine konum kazancı kp [1/s] olarak okunur:
%   wcmd = kp e,  tau = KV (wcmd - v) + KI z,  z = sum(wcmd - v)*Ts,  v = motor hızı
%   KV = kv kr^2, KI = kr^2/Ti (Ghaffari'nin motor tarafı kv, Ti'sinden); r_gs = sqrt(kp KV / Ks).

th_ref = deg2rad(theta0_deg(:)');
wc     = wc(:)';
n      = numel(th_ref);
J      = p.JM + p.JL;
Kp = J*wc.^2;  Kd = 2*0.7*J*wc;  Ki = Kp.*wc/4;
ppi = isfield(p,'kontrol') && strcmp(p.kontrol,'PPI');
if ppi, kpP = wc;  KV = p.KV.*ones(1,n);  KI = p.KI.*ones(1,n); end
motorD = strcmp(p.Dkaynak,'motor');

% Başlangıç: kol hedefin p.adim derece altında, durgun, dişli boşluğun ortasında
x = zeros(4,n);
x(3,:) = th_ref - deg2rad(p.adim);
x(1,:) = x(3,:);
z = zeros(1,n);  u = zeros(1,n);
if isfield(p,'x0'), x = p.x0;  z = p.z0; end        % önceki benzetimin son durumundan sürdür
gL = 0;  if isfield(p,'gL'), gL = p.gL; end
thBuf = repmat(olc(x(3,:), p.qL), gL+1, 1);        % gecikme tamponu (en eski satır kullanılır)
if motorD, qv = p.qM; else, qv = p.qL; end
yv_prev = olc(x(1+2*~motorD,:), qv);  vhat = zeros(1,n);
aV = 1 - exp(-2*pi*p.fv*p.Ts);                     % filtre katsayısı (fv=Inf -> 1)

nStep = round(p.T/p.dt);
kCtl  = max(1, round(p.Ts/p.dt));
iAn   = round((p.T-p.Tan)/p.dt);
nRec  = floor((nStep-iAn)/p.dec);
TH = zeros(nRec,n);  DEL = zeros(nRec,n);  TAU = zeros(nRec,n);  U = zeros(nRec,n);
k = 0;

for i = 0:nStep-1
    if mod(i,kCtl) == 0                            % ---- kontrolcü örneği ----
        thm = olc(x(3,:), p.qL);
        if gL > 0, thBuf = [thBuf(2:end,:); thm];  thm = thBuf(1,:); end
        if isinf(p.fv)
            v = motorD*x(2,:) + ~motorD*x(4,:);
        else
            yv = olc(x(1+2*~motorD,:), qv);
            vhat = vhat + aV*((yv - yv_prev)/p.Ts - vhat);
            yv_prev = yv;  v = vhat;
        end
        e  = th_ref - thm;
        if ppi
            ev = kpP.*e - v;                       % hız hatası (kol tarafı)
            u0 = KV.*ev + KI.*z;
            iz = ev;
        else
            u0 = Kp.*e + Ki.*z - Kd.*v;
            iz = e;
        end
        u  = min(max(u0,-p.Tmax),p.Tmax);
        doy = (u0 > p.Tmax & iz > 0) | (u0 < -p.Tmax & iz < 0);
        z  = z + iz*p.Ts .* ~doy;                  % basit anti-windup
        u(abs(u) < p.olu) = 0;                     % sürücü ölü bandı
    end
    k1 = f(x);  k2 = f(x+0.5*p.dt*k1);  k3 = f(x+0.5*p.dt*k2);  k4 = f(x+p.dt*k3);
    x = x + p.dt/6*(k1+2*k2+2*k3+k4);
    ii = i+1;
    if ii > iAn && mod(ii-iAn,p.dec)==0
        k = k+1;
        [~,ts] = f(x);
        TH(k,:) = x(3,:);  DEL(k,:) = x(1,:)-x(3,:);  TAU(k,:) = ts;  U(k,:) = u;
    end
end

t = (1:nRec)'*p.dt*p.dec;
out.t = t;  out.th = TH;  out.delta = DEL;  out.tau_s = TAU;  out.u = U;
out.theta0_deg = theta0_deg;  out.wc = wc;
out.x_son = x;  out.z_son = z;                     % p.x0, p.z0 ile sürdürmek için

% --- Analiz ---
thd = rad2deg(TH);
out.A_deg = (max(thd)-min(thd))/2;                 % salınım genliği [derece]
side = sign(DEL) .* (abs(DEL) >= p.r);             % +1 / -1 temas kenarı, 0 boşlukta
out.gecis = zeros(1,n);  out.bosluk_orani = mean(side==0);
for j = 1:n
    s = side(:,j);  s = s(s~=0);
    out.gecis(j) = sum(abs(diff(s))>0);            % kenar değiştirme sayısı (analiz penceresinde)
end
out.f_Hz = out.gecis/2/p.Tan;
% Sınıflar (A esigi 0.05 der ~ AS5600 cozunurlugunun yarisi):
%   0 denge | 1 dişli bastırılı salınım (sürtünme/nicemleme) | 2 tek kenarlı boşluk salınımı
%   3 iki kenarlı boşluk salınımı | 4 kararsız
sal = out.A_deg > 0.05;
out.sinif = zeros(1,n);
out.sinif(sal & out.bosluk_orani <= 0.02) = 1;
out.sinif(sal & out.bosluk_orani >  0.02 & out.gecis < 2) = 2;
out.sinif(sal & out.gecis >= 2) = 3;
out.LC = out.sinif == 3;                           % geriye uyumluluk
sapma = abs(thd - theta0_deg(:)');
out.kararsiz = mean(sapma(end-round(end/3):end,:)) > 10 | max(sapma) > 45;
out.sinif(out.kararsiz) = 4;

    function [dx, ts] = f(x)
        phi = x(1,:); dphi = x(2,:); th = x(3,:); dth = x(4,:);
        d = phi - th;  dd = dphi - dth;
        ts = zeros(size(d));
        sag = d >  p.r;  sol = d < -p.r;
        ts(sag) = max(p.Ks*(d(sag)-p.r) + p.cs*dd(sag), 0);
        ts(sol) = min(p.Ks*(d(sol)+p.r) + p.cs*dd(sol), 0);
        if p.Fc > 0                                % yumuşatılmış Stribeck sürtünmesi
            tf = (p.Fc + (p.Fs-p.Fc)*exp(-(dphi/p.vs).^2)) .* tanh(dphi/p.veps);
        else
            tf = 0;
        end
        dx = [dphi;
              (u - p.bM*dphi - tf - ts)/p.JM;
              dth;
              (ts - p.bL*dth - p.mgl*sin(th))/p.JL];
    end
end

function y = olc(x, q)
% Nicemleme: q = 0 ise ideal.
if q > 0, y = q*floor(x/q); else, y = x; end
end
