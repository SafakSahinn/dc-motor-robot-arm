function sta_tespit
% B1-L, L2 için tespit edilebilirlik: Ruderman-Fridman 2019 STA hatası e = y - x^ çarpma anında
% gürültü/titreşim tabanından ayrılıyor mu? Kapalı çevrimden bağımsız, çevrimdışı ve kestirici kendi lehine
% (eşik yok, oran raporlanır). Ölçüt: oran = çarpma ±10 ms içindeki max|e| / geçişlerden >= 50 ms uzak
% örneklerin %99 |e|'si. Oran ~1: ayırt edilemez.
% A) Pozitif kontrol: makalenin §III-D örneği (Umax 0,5, Km 0,172, m1 8,78e-4, d1 6,2e-2,
%    g2 = -0,035 x2' - 0,05 sgn x2' ivme düzeyinde, u = 0,5 sin(0,2π t)). Makalede verilmeyenler (kaynak [9]):
%    m2 = m1, 2β = 0,019 rad (makalenin deneyi), temas sertliği wc = sqrt(k/m1) taranır, sönüm oranı 0,05.
% B) Bizim tesis (D düzeneği, sqrt(Ks/JM) = 52,7 rad/s): B1'in b salınım, a2 yük, d yön değiştirme
%    senaryoları (tablo ofseti), kayıttan phi = th + delta; Ts, enkoder biti ve AS5600 gürültüsü taranır.
% Not: makalede k1 = 2,028 k2 diye okunan ifade birim gereği k1 = 2,028 sqrt(k2) (metin çıkarımında kök kaybı).
cd(fileparts(mfilename('fullpath')));
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'));
diary off;  if isfile('sta_tespit_log.txt'), delete('sta_tespit_log.txt'); end
diary('sta_tespit_log.txt');
fprintf('=== sta_tespit %s\n', datestr(now, 'yyyy-mm-dd HH:MM'));
fprintf('\n--- A) Pozitif kontrol (makale örneği), sütunlar: ilk 4 çarpmanın oranı\n');
m1 = 8.78e-4;  m2 = m1;  d1 = 6.2e-2;  Km = 0.172;  b = 0.019/2;
for wc = [75 750 7500]
    k = wc^2*m1;  c = 2*0.05*wc*m1;  dt = min(1e-5, 0.05/wc);  T = 12;  N = round(T/dt);
    x = zeros(4,1);  X = zeros(N,1);  Dl = zeros(N,1);
    for i = 1:N
        u = 0.5*sin(0.1*2*pi*i*dt);
        dl = x(1) - x(3);  dz = (dl - b)*(dl > b) + (dl + b)*(dl < -b);
        tc = (k*dz + c*(x(2) - x(4)))*(dz ~= 0);
        a1 = (-d1*x(2) + Km*u - tc)/m1;  a2 = tc/m2 - 0.035*x(4) - 0.05*sign(x(4));
        x = x + dt*[x(2); a1; x(4); a2];  X(i) = x(1);  Dl(i) = dl;
    end
    tt = (1:N)'*dt;
    for Ts = [1e-4 1e-3]
        for q = [0 2*pi/2^20 2*pi/2^12]
            for L = [40 100]
                [o, ~] = oran(X, Dl, b, tt, Ts, q, 0, L, 1);
                fprintf('wc %5d rad/s  Ts %.0e  nicem %-7s L %3d: %s\n', wc, Ts, num2str(q,'%.2g'), L, mat2str(o(1:min(4,end))', 2));
            end
        end
    end
end
fprintf('\n--- B) Bizim tesis, sütunlar: çarpma oranlarının ortancası / en büyüğü (n çarpma)\n');
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 1;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.gM = 4e-4;  p0.akimW = 2*pi*500;
kpv = 0.50^2*p0.Ks/p0.KV;
hedef = [179.5 180.5];  s0 = sign(sind(hedef));
S = {};
q = p0;  q.ofset = s0*q.r + q.mgl*sind(hedef)/q.Ks;  q.adim = [1.1 -1.1];
q.dA = 0.01*[1 1];  q.df = 1;  q.dT0 = 3;  q.dT = Inf;  S{end+1} = {'b salınım', q};
q = p0;  q.ofset = s0*q.r + q.mgl*sind(hedef)/q.Ks;  q.adim = [1.1 -1.1];
q.dB = 0.02*s0;  q.dBT0 = 3;  S{end+1} = {'a2 yük', q};
q = p0;  q.ofset = s0*q.r + q.mgl*sind(hedef)/q.Ks;  q.adim = 0;
W = [hedef + 3; hedef - 1.5; hedef];  tk = [0 2.25 3];
q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end))));  S{end+1} = {'d yön değ.', q};
nAS = deg2rad(0.043)/p0.N;  lbl = {'sürtünmeli', 'sürtünmesiz'};
for sr = 1:2
    for s = 1:numel(S)
        q = S{s}{2};  if sr == 1, q.Fc = 0.04;  q.Fs = 0.06; else, q.Fc = 0;  q.Fs = 0; end
        o = kol_benzetim(q, hedef, kpv*ones(1,2));
        phi = o.th + o.delta;
        for Ts = [1e-4 1e-3]
            for bit = [12 16 20]
                for gur = [0 1]
                    if gur && bit > 12, continue; end
                    for L = [10 30 100]
                        oo = [];
                        for j = 1:2
                            oo = [oo; oran(phi(:,j), o.delta(:,j), p0.r, o.t, Ts, 2*pi/(2^bit*30), gur*nAS, L, j)]; %#ok<AGROW>
                        end
                        fprintf('%-11s %-10s Ts %.0e %2d bit gür %d L %3d: ortanca %.2f en büyük %.2f (n %d)\n', ...
                            lbl{sr}, S{s}{1}, Ts, bit, gur, L, ...
                            median(oo), max([oo; NaN]), numel(oo));
                    end
                end
            end
        end
    end
end
diary off;
end

function [o, gir] = oran(X, Dl, b, tt, Ts, q, nG, L, tohum)
dt = tt(2) - tt(1);  st = max(1, round(Ts/dt));  idx = (st:st:numel(tt))';  ti = tt(idx);
gy = sign(Dl).*(abs(Dl) >= b);
g = find(gy(2:end) ~= gy(1:end-1)) + 1;  gec = tt(g);  gir = tt(g(gy(g) ~= 0));  gir = gir(gir > 1);
y = X(idx);
if nG > 0, rng(tohum);  y = y + nG*randn(size(y)); end
if q > 0, y = round(y/q)*q; end
e = sta(y, Ts, L);
if isempty(gec), uz = ti > 1; else, uz = ti > 1 & arrayfun(@(s) min(abs(s - gec)), ti) > 0.05; end
tb = sort(abs(e(uz)));  n99 = tb(max(1, round(0.99*end)));
o = arrayfun(@(gg) max(abs(e(abs(ti - gg) <= 0.01))), gir)/n99;  o = o(:);
end

function e = sta(y, Ts, L)
k2 = 1.1*L;  k1 = 2.028*sqrt(k2);  x = y(1);  w = 0;  e = zeros(size(y));
for i = 1:numel(y)
    ee = y(i) - x;  e(i) = ee;
    x = x + Ts*(w + k1*sqrt(abs(ee))*sign(ee));  w = w + Ts*k2*sign(ee);
end
end
