% BOLUM3_DOGRUSAL  Birleşik rapor Bölüm 3 (doğrusal sistem analizi) hesapları.
% Her alt bölüm (3.1 ... 3.8) ayrı bir %% hücresidir; sayılar bolum3_dogrusal_log.txt'ye,
% şekiller img/ klasörüne yazılır. Symbolic Toolbox kullanılmaz: Jacobian elle türetilir,
% sayısal sonlu farkla sağlanır (3.2).
% Parametre kaynağı: simulasyon/parametreler.m -> 4a_ghaffari/secenek_duzenek.m ('D'),
% motorun elektrik eşdeğeri kol_benzetim.m'deki varsayılanlar (p.motorElk).

clear; clc;
kok  = fileparts(mfilename('fullpath'));
sim  = fullfile(kok, '..', '..', 'simulasyon');
addpath(sim, fullfile(sim, '4a_ghaffari'));
imgD = fullfile(kok, 'img');  if ~exist(imgD, 'dir'), mkdir(imgD); end
fid  = fopen(fullfile(kok, 'bolum3_dogrusal_log.txt'), 'w');
yaz  = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== bolum3_dogrusal, %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM'));

%% 3.1 Durum uzayı modeli
yaz('--- 3.1 Durum uzayı modeli ---\n\n');

% (a) KT1 modeli: dişlisiz kol, CTMS motoru (README Ek B.8, matlab/acik_cevrim.m)
% Durum x = [theta; omega; i], giriş u = V, çıkış y = theta.
k1.Jm = 0.01;  k1.b = 0.1;  k1.K = 0.01;  k1.R = 1;  k1.L = 0.5;
k1.m = 0.05;   k1.l = 0.1;  k1.g = 9.81;  k1.J = k1.Jm + k1.m*k1.l^2;
k1.mgl = k1.m*k1.g*k1.l;
kt1A = @(th0) [0 1 0;
               -k1.mgl*cosd(th0)/k1.J, -k1.b/k1.J, k1.K/k1.J;
               0, -k1.K/k1.L, -k1.R/k1.L];
kt1B = [0; 0; 1/k1.L];  kt1C = [1 0 0];
A = kt1A(90);
yaz('(a) KT1, 3 durum [theta omega i], giriş V, çıkış theta; theta0 = 90°:\n');
yazMat(yaz, 'A', A);  yazMat(yaz, 'B', kt1B);  yazMat(yaz, 'C', kt1C);
yaz('    özdeğerler: %s\n\n', ozdegerYazi(eig(A)));

% (b) İki kütleli model, Düzenek D. Kol tarafına indirgenmiş büyüklükler.
p = secenek_duzenek('D');
Vs = 12;  Km = Vs/(333*2*pi/60);  Ra = Km*Vs/0.49;  La = 2.5e-3;   % kol_benzetim varsayılanı
yaz('(b) Düzenek D parametreleri (kol tarafı):\n');
yaz('    J_M = %.4g kg m^2, J_L = %.4g kg m^2 (J_L = J_M), mgl = %.4g N m\n', p.JM, p.JL, p.mgl);
yaz('    K_s = %.4g N m/rad, c_s = %.4g N m s/rad, b_M = %.4g, b_L = %.4g N m s/rad, r = %.3g°\n', ...
    p.Ks, p.cs, p.bM, p.bL, rad2deg(p.r));
yaz('    K_m = %.4g V s/rad (= N m/A), R_a = %.4g Ohm, L_a = %.4g H\n', Km, Ra, La);

% Temas hâlinde (sağ yüz, delta = phi - theta > r): tau_s = K_s (delta - r) + c_s delta'.
% Dengeden sapma değişkenlerinde sabit r terimi dengeye gider; kalan doğrusal kısım:
%   phi''   = (tau_m - b_M w_M - K_s(phi-theta) - c_s(w_M-w_L)) / J_M
%   theta'' = (K_s(phi-theta) + c_s(w_M-w_L) - b_L w_L - mgl cos(theta0) theta) / J_L
% 4 durum x = [phi; w_M; theta; w_L], giriş tau_m (akım döngüsü torku izler varsayımı).
A4 = @(th0) iki_kutle_A(p, th0);
B4 = [0; 1/p.JM; 0; 0];
Cm = [1 0 0 0];  Ck = [0 0 1 0];
A = A4(90);
yaz('\n(b1) İki kütle, 4 durum [phi w_M theta w_L], giriş tau_m; theta0 = 90° (yerçekimi türevi 0):\n');
yazMat(yaz, 'A', A);  yazMat(yaz, 'B', B4);
yazMat(yaz, 'C_motor', Cm);  yazMat(yaz, 'C_kol', Ck);
yaz('    özdeğerler: %s\n', ozdegerYazi(eig(A)));

% 5 durum: akım da durum, giriş gerilim. La i' = V - Ra i - Km w_M, tau_m = Km i.
A5 = @(th0) [A4(th0), [0; Km/p.JM; 0; 0]; 0, -Km/La, 0, 0, -Ra/La];
B5 = [0; 0; 0; 0; 1/La];
A = A5(90);
yaz('\n(b2) İki kütle, 5 durum [phi w_M theta w_L i], giriş V; theta0 = 90°:\n');
yazMat(yaz, 'A', A);  yazMat(yaz, 'B', B5);
yaz('    özdeğerler: %s\n', ozdegerYazi(eig(A)));
yaz('    elektrik kutbu ~ -R_a/L_a = %.0f rad/s (%.0f Hz): mekanik kutuplardan çok hızlı;\n', -Ra/La, Ra/La/(2*pi));
yaz('    akım döngüsü (500 Hz) torku izlediği için bundan sonra 4 durumlu model kullanılır.\n');

% Sağlama: dişli rezonans / anti-rezonans frekansları (sönümsüz, yerçekimsiz)
wr = sqrt(p.Ks*(p.JM + p.JL)/(p.JM*p.JL));  wa = sqrt(p.Ks/p.JL);
yaz('\n    Rezonans  sqrt(K_s (J_M+J_L)/(J_M J_L)) = %.1f rad/s = %.2f Hz\n', wr, wr/(2*pi));
yaz('    Anti-rez. sqrt(K_s/J_L)                  = %.1f rad/s = %.2f Hz\n', wa, wa/(2*pi));
p0 = parametreler('ideal');
wr0 = sqrt(p0.Ks*(p0.JM + p0.JL)/(p0.JM*p0.JL));
yaz('    (Not: eski JGA25 parametreleriyle (parametreler.m) rezonans %.2f Hz; belgelerdeki "≈ 18,7 Hz" o düzeneğe ait.)\n\n', wr0/(2*pi));

%% 3.2 Denge noktaları ve Jacobian: theta0 = 0°, 90°, 180°
yaz('--- 3.2 Denge noktaları ve Jacobian ---\n\n');
% Denge (x' = 0): w_M = w_L = 0. Kol denklemi: tau_s = mgl sin(theta0).
% Motor denklemi: tau_m0 = tau_s = mgl sin(theta0) (tutma torku).
% Sağ yüzde temas: K_s (delta0 - r) = mgl sin(theta0)  ->  delta0 = r + mgl sin(theta0)/K_s.
% Elle türetilen Jacobian = iki_kutle_A(p, theta0); tek açıya bağlı terim -mgl cos(theta0)/J_L.
% Sağlama: doğrusal olmayan f'nin (kol_benzetim.m'deki f, sürtünmesiz) merkezi sonlu farkı.
aci = [0 90 180];  h = 1e-6;
yaz('Denge koşulu: tau_m0 = mgl sin(theta0), delta0 = r + mgl sin(theta0)/K_s\n');
yaz('%8s | %12s | %12s | %14s | %s\n', 'theta0', 'tau_m0 [N m]', 'delta0 [°]', 'mgl cos [N m]', 'yerçekimi etkisi');
etki = {'geri getirici (yay gibi)', 'yok (nötr)', 'itici (negatif yay)'};
for k = 1:3
    yaz('%7d° | %12.4f | %12.4f | %14.4f | %s\n', aci(k), p.mgl*sind(aci(k)), ...
        rad2deg(p.r + p.mgl*sind(aci(k))/p.Ks), p.mgl*cosd(aci(k)), etki{k});
end
yaz('\n');
Atab = zeros(4, 4, 3);
for k = 1:3
    th0 = aci(k);
    [x0, u0] = denge(p, th0);
    Ael = iki_kutle_A(p, th0);
    Asf = sonlu_fark(@(x) f_dogrusalOlmayan(x, u0, p, 'temas'), x0, h);
    Atab(:,:,k) = Ael;
    yaz('theta0 = %d°:\n', th0);
    yazMat(yaz, 'A (elle)', Ael);
    yaz('    max |A_elle - A_sonlu fark| = %.2e  (bağıl %.2e)\n', max(abs(Ael - Asf), [], 'all'), ...
        max(abs(Ael - Asf), [], 'all')/max(abs(Ael), [], 'all'));
    yaz('    özdeğerler: %s\n', ozdegerYazi(eig(Ael)));
    if sind(th0) == 0
        % Ön yük sıfır: denge delta0 = r tam boşluk kenarında. Gerçek (ölü bölgeli) f burada
        % türevlenemez: temas tarafına ve boşluk tarafına doğru tek yönlü farklar farklı.
        Asag = tek_yonlu(@(x) f_dogrusalOlmayan(x, u0, p, 'tam'), x0, h, +1);
        Asol = tek_yonlu(@(x) f_dogrusalOlmayan(x, u0, p, 'tam'), x0, h, -1);
        yaz('    Ölü bölgeli gerçek f, delta0 = r kenarında (phi yönünde tek yönlü fark):\n');
        yaz('      dw_M''/dphi temas yönü = %9.1f, boşluk yönü = %9.1f  -> Jacobian tanımsız\n', round(Asag(2,1), 1) + 0, round(Asol(2,1), 1) + 0);
        yaz('      boşluk tarafında A blok köşegen: motor [phi w_M] ile kol [theta w_L] arasında terim yok (bkz. 3.5)\n');
    end
    yaz('\n');
end
% KT1 için aynı üç açıda (karşılaştırma): tek değişen yine A(2,1) = -mgl cos(theta0)/J
yaz('KT1 (3 durum) aynı açılarda: A(2,1) = -mgl cos(theta0)/J\n');
for k = 1:3
    A = kt1A(aci(k));
    yaz('  %3d°: A(2,1) = %8.4f, özdeğerler: %s\n', aci(k), A(2,1) + 0, ozdegerYazi(eig(A)));
end
yaz('\n');

fclose(fid);

%% ---------- yerel fonksiyonlar ----------
function A = iki_kutle_A(p, th0)
% Temas hâlindeki iki kütleli modelin theta0 [derece] çevresindeki A matrisi (4 durum).
kg = p.mgl*cosd(th0);                          % yerçekimi torkunun theta'ya türevi
A = [0, 1, 0, 0;
     -p.Ks/p.JM, -(p.bM + p.cs)/p.JM,  p.Ks/p.JM,  p.cs/p.JM;
     0, 0, 0, 1;
      p.Ks/p.JL,  p.cs/p.JL, -(p.Ks + kg)/p.JL, -(p.bL + p.cs)/p.JL];
end

function [x0, u0] = denge(p, th0)
% Sağ yüzde temas varsayımıyla denge durumu ve tutma torku (theta0 derece).
th = deg2rad(th0);  d0 = p.r + p.mgl*sind(th0)/p.Ks;
x0 = [th + d0; 0; th; 0];  u0 = p.mgl*sind(th0);
end

function dx = f_dogrusalOlmayan(x, u, p, kip)
% kol_benzetim.m'deki f (sürtünmesiz, bozucusuz). kip 'tam': ölü bölge + tek yönlü temas;
% kip 'temas': sağ yüzde temas hiç kopmuyor varsayımı (doğrusallaştırmanın modeli).
phi = x(1); dphi = x(2); th = x(3); dth = x(4);
d = phi - th;  dd = dphi - dth;
switch kip
    case 'temas', ts = p.Ks*(d - p.r) + p.cs*dd;
    case 'tam'
        if d > p.r,      ts = max(p.Ks*(d - p.r) + p.cs*dd, 0);
        elseif d < -p.r, ts = min(p.Ks*(d + p.r) + p.cs*dd, 0);
        else,            ts = 0; end
end
dx = [dphi;
      (u - p.bM*dphi - ts)/p.JM;
      dth;
      (ts - p.bL*dth - p.mgl*sin(th))/p.JL];
end

function A = sonlu_fark(f, x0, h)
% Merkezi sonlu fark Jacobian'ı: A(:,j) = (f(x0 + h e_j) - f(x0 - h e_j)) / 2h.
n = numel(x0);  A = zeros(n);
for j = 1:n
    e = zeros(n,1);  e(j) = h;
    A(:,j) = (f(x0 + e) - f(x0 - e))/(2*h);
end
end

function A = tek_yonlu(f, x0, h, yon)
% Tek yönlü fark: yon = +1 ileri, -1 geri.
n = numel(x0);  A = zeros(n);  f0 = f(x0);
for j = 1:n
    e = zeros(n,1);  e(j) = yon*h;
    A(:,j) = (f(x0 + e) - f0)/(yon*h);
end
end

function yazMat(yaz, ad, M)
M(abs(M) < 1e-12) = 0;                        % cosd(90) yuvarlaması "-0" görünmesin
yaz('    %s =\n', ad);
for i = 1:size(M,1)
    yaz('      ');  yaz('%11.4g ', M(i,:));  yaz('\n');
end
end

function s = ozdegerYazi(e)
e = sort(e, 'ComparisonMethod', 'real');
s = strjoin(arrayfun(@(z) tekOz(z), e(:)', 'UniformOutput', false), ', ');
end

function s = tekOz(z)
if abs(real(z)) < 1e-9, z = 1i*imag(z); end
if abs(imag(z)) < 1e-9, s = sprintf('%.4g', real(z));
else, s = sprintf('%.4g%+.4gj', real(z), imag(z)); end
end
