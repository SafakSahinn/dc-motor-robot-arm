function out = ghaffari2013(p, kp, kv)
% GHAFFARI2013  Ghaffari ve Mohammadiasl 2013, Şekil 4'teki servo eksenin benzetimi.
% kp ve kv aynı boyutlu diziler olabilir: her eleman ayrı bir benzetim; hepsi
% vektör halinde aynı anda çözülür (sabit adımlı RK4).
%
% Durumlar:
%   thm, wm : motor açısı ve hızı (motor tarafı)
%   thl, wl : yük açısı ve hızı (yük tarafı)
%   z       : hız hatasının integrali (PI)
% Fark açısı (yük tarafı): thd = thm/kr - thl. Boşluk +-delta içinde tork iletilmez:
%   tau_s = ks (thd - delta) + cs dthd   (thd >  delta, yalnız iterek)
%   tau_s = ks (thd + delta) + cs dthd   (thd < -delta)
% Kontrolcü (akım döngüsü 1 alınır, Şekil 4):
%   wc  = kp (th_ref - thl)                konum P, yük sensörü
%   e_v = kr wc - wm                       hız hatası, motor enkoderi
%   tau_m = kv e_v + z/Ti,  dz/dt = e_v    "kv + 1/(s Ti)" (denklem 5 ile aynı biçim)
%   tau_m +-p.Tmax ile sınırlanır (makalede yok; varsayılan Inf); doyumda integral durur.
% th_ref = 0; başlangıçta yük p.th0 kadar sapmış, motor boşluğun ortasında, durgun.

kp = kp(:)';  kv = kv(:)';  n = numel(kp);
x = zeros(5,n);
x(3,:) = p.th0;  x(1,:) = p.kr*p.th0;

nStep = round(p.T/p.dt);
iAn   = round((p.T-p.Tan)/p.dt);
nRec  = floor((nStep-iAn)/p.dec);
THD = zeros(nRec,n);  TS = zeros(nRec,n);  WC = zeros(nRec,n);  WMr = zeros(nRec,n);  WL = zeros(nRec,n);
k = 0;
for i = 0:nStep-1
    k1 = f(x);  k2 = f(x+0.5*p.dt*k1);  k3 = f(x+0.5*p.dt*k2);  k4 = f(x+p.dt*k3);
    x = x + p.dt/6*(k1+2*k2+2*k3+k4);
    ii = i+1;
    if ii > iAn && mod(ii-iAn,p.dec)==0
        k = k+1;
        [~,ts,thd,wc] = f(x);
        THD(k,:) = thd;  TS(k,:) = ts;  WC(k,:) = wc;  WMr(k,:) = x(2,:)/p.kr;  WL(k,:) = x(4,:);
    end
end

t = (iAn + (1:nRec)'*p.dec)*p.dt;
out.t = t;  out.thd = THD;  out.tau_s = TS;
out.burulma = TS/p.ks;                             % yayın burulma açısı (Şekil 7b/8b) [rad]
out.wc = WC;  out.wm_kr = WMr;  out.wl = WL;       % Şekil 7c/8c: komut, motor/kr, yük [rad/s]
out.kp = kp;  out.kv = kv;
out.rgs = sqrt(kp.*kv/p.kse);
out.f_eq12 = sqrt(kp.*kv/p.Jle)/(2*pi);            % denklem 12 [Hz]

% --- Analiz: thd'nin salınım frekansı ve genliği (analiz penceresinde) ---
out.A_deg = rad2deg(max(THD)-min(THD))/2;
out.f_Hz = zeros(1,n);
for j = 1:n
    y = THD(:,j) - mean(THD(:,j));
    s = find(y(1:end-1) < 0 & y(2:end) >= 0);      % yukarı yönlü sıfır geçişleri
    if numel(s) >= 3 && out.A_deg(j) > 1e-3*rad2deg(p.delta)
        out.f_Hz(j) = (numel(s)-1)/((s(end)-s(1))*p.dt*p.dec);
    end
end

    function [dx, ts, thd, wc] = f(x)
        thm = x(1,:); wm = x(2,:); thl = x(3,:); wl = x(4,:); z = x(5,:);
        thd = thm/p.kr - thl;  dthd = wm/p.kr - wl;
        ts = zeros(size(thd));
        sag = thd > p.delta;  sol = thd < -p.delta;
        ts(sag) = max(p.ks*(thd(sag)-p.delta) + p.cs*dthd(sag), 0);
        ts(sol) = min(p.ks*(thd(sol)+p.delta) + p.cs*dthd(sol), 0);
        wc  = kp.*(0 - thl);
        ev  = p.kr*wc - wm;
        tm0 = kv.*ev + z/p.Ti;
        tm  = min(max(tm0, -p.Tmax), p.Tmax);
        doy = (tm0 > p.Tmax & ev > 0) | (tm0 < -p.Tmax & ev < 0);
        tfm = p.Fcm*tanh(wm/p.veps);
        tfl = p.Fcl*tanh(wl*p.kr/p.veps);
        dx = [wm;
              (tm - p.cm*wm - tfm - ts/p.kr)/p.Jm;
              wl;
              (ts - p.cl*wl - tfl)/p.Jl;
              ev.*~doy];
    end
end
