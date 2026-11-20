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

%% Ortak: şekil renkleri (dataviz başvuru paleti, açık tema) ve kapalı çevrim
R.s1 = hex2rgb('#2a78d6');  R.s2 = hex2rgb('#eb6834');  R.s3 = hex2rgb('#1baf7a');
R.yazi = hex2rgb('#0b0b0b');  R.yazi2 = hex2rgb('#52514e');  R.izgara = hex2rgb('#e4e3df');
R.sirali = @(t) (1 - t(:))*hex2rgb('#bcd4f2') + t(:)*hex2rgb('#0d3a73');   % tek ton, açık -> koyu

% Koddaki motor tarafı P-PI (hiz_gozlemci.m ve yuz_kestirici*.m ile aynı kazançlar):
%   w_cmd = kp (theta_ref - phi),  tau = KV (w_cmd - w_M) + KI z,  z' = w_cmd - w_M
wa = sqrt(p.Ks/p.JL);
KV = wa*(p.JM + p.JL);  KI = 0.05*wa*KV;  kp = 0.50^2*p.Ks/KV;
Acl = @(th0) [A4(th0) + B4*[-KV*kp, -KV, 0, 0], B4*KI;
              -kp, -1, 0, 0, 0];

%% 3.3 Özdeğerlerin açıya göre değişimi
yaz('--- 3.3 Özdeğerlerin açıya göre değişimi ---\n\n');
yaz('Kapalı çevrim: motor tarafı P-PI, KV = %.4f N m s/rad, KI = %.4f N m/rad, kp = %.3f 1/s (r_gs = 0,50)\n', KV, KI, kp);
yaz('Durum [phi w_M theta w_L z]; konum hatası motor açısından (ofset dengeye gider, A''yı değiştirmez).\n\n');
tara = 0:1:180;  EA = zeros(4, numel(tara));  EK = zeros(5, numel(tara));
for k = 1:numel(tara)
    EA(:,k) = eig(A4(tara(k)));  EK(:,k) = eig(Acl(tara(k)));
end
maxA = max(real(EA));  maxK = max(real(EK));
iSif = find(maxA > 1e-9, 1);
yaz('%8s | %-44s | %-56s\n', 'theta0', 'açık çevrim özdeğerleri', 'kapalı çevrim özdeğerleri');
for th0 = [0 30 60 90 120 150 170 180]
    k = th0 + 1;
    yaz('%7d° | %-44s | %-56s\n', th0, ozdegerYazi(EA(:,k)), ozdegerYazi(EK(:,k)));
end
yaz('\nAçık çevrim en sağdaki özdeğer 0''ı ilk geçtiği açı: %d° (90°''de tam 0; >90° yerçekimi itici)\n', tara(iSif));
yaz('Açık çevrim 180°: pozitif reel özdeğer %.3f 1/s -> ters sarkaç, zaman sabiti %.0f ms\n', maxA(end), 1e3/maxA(end));
yaz('  rijit tahmin sqrt(mgl/(J_M+J_L)) = %.3f 1/s (dişli rijit sayılırsa)\n', sqrt(p.mgl/(p.JM + p.JL)));
yaz('Kapalı çevrim: en sağdaki gerçel kısım tüm açılarda <= %.3f 1/s (en kötü açı %d°) -> doğrusal modelde kararlı\n', ...
    max(maxK), tara(find(maxK == max(maxK), 1)));
yaz('Dişli rezonansı çifti açıyla neredeyse sabit: |Im| %.1f ... %.1f rad/s (%.2f ... %.2f Hz)\n', ...
    min(max(imag(EA))), max(max(imag(EA))), min(max(imag(EA)))/(2*pi), max(max(imag(EA)))/(2*pi));

% B1 bağlantısı: eski PID (rijit model kazançları), türev kol hızından mı motor hızından mı?
yaz('\nB1 bağlantısı (boşluksuz, theta0 = 90°): PID Kp = J wc^2, Kd = 1,4 J wc, Ki = Kp wc/4, J = J_M + J_L,\n');
yaz('konum kol açısından, türev ya kol hızından ya motor hızından. İlk kararsız wc [rad/s]:\n');
wcT = 1:0.5:120;
for ps = {{'eski JGA25 (parametreler.m)', parametreler('ideal')}, {'Düzenek D', p}}
    q = ps{1}{2};  sinir = [NaN NaN];
    for kay = 1:2
        for wc = wcT
            Acp = pid_kapali(q, 90, wc, kay);
            if max(real(eig(Acp))) > 0, sinir(kay) = wc; break; end
        end
    end
    wr_q = sqrt(q.Ks*(q.JM + q.JL)/(q.JM*q.JL));
    yaz('  %-28s rezonans %5.1f rad/s (%5.2f Hz): türev kol hızından %s, motor hızından %s\n', ps{1}{1}, ...
        wr_q, wr_q/(2*pi), sinirYazi(sinir(1)), sinirYazi(sinir(2)));
end
yaz('  (Benzetimdeki B1 sonucu: eski düzenekte kol hızıyla ~20 rad/s, motor hızıyla 60 rad/s''ye kadar kararlı.)\n\n');

% Şekil 3.2: (a) açık çevrim yavaş özdeğerlerin yolu, (b) en sağdaki gerçel kısım - theta0
f = yeniSekil(17, 7.2);
ax = subplot(1, 2, 1);  hold(ax, 'on');
renk = R.sirali(tara/180);
yavas = EA;  yavas(abs(EA) > 30) = NaN;                       % rezonans çiftini (|s| ~ 74) ayır
for k = 1:numel(tara)
    v = yavas(:,k);  v = v(~isnan(v));
    scatter(ax, real(v), imag(v), 10, renk(k,:), 'filled', 'MarkerEdgeColor', 'none');
end
xline(ax, 0, 'Color', R.yazi2, 'LineWidth', 0.8);
for th0 = [0 90 180]
    v = yavas(:, th0+1);  v = v(~isnan(v));
    plot(ax, real(v), imag(v), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', R.yazi, 'LineWidth', 1);
end
text(ax, 0.5, 5.76, '0°', 'Color', R.yazi, 'FontSize', 8);
text(ax, 0.5, -0.9, '90°', 'Color', R.yazi, 'FontSize', 8);
text(ax, 5.65, 0.9, '180°', 'Color', R.yazi, 'HorizontalAlignment', 'center', 'FontSize', 8);
text(ax, -5.94, 0.9, '180°', 'Color', R.yazi, 'HorizontalAlignment', 'center', 'FontSize', 8);
colormap(ax, R.sirali(linspace(0,1,181)'));  clim(ax, [0 180]);
cb = colorbar(ax, 'Location', 'southoutside');  cb.Label.String = '\theta_0 [°]';  cb.Ticks = 0:45:180;
cb.Color = R.yazi2;  cb.Box = 'off';
xlabel(ax, 'Gerçel kısım [1/s]');  ylabel(ax, 'Sanal kısım [rad/s]');
title(ax, '(a) Açık çevrim: kolun yavaş özdeğerleri', 'FontWeight', 'normal');
stil(ax, R);  xlim(ax, [-7 7]);  ylim(ax, [-7 7]);  axis(ax, 'square');
ax = subplot(1, 2, 2);  hold(ax, 'on');
yline(ax, 0, 'Color', R.yazi2, 'LineWidth', 0.8);
plot(ax, tara, maxA, '-', 'Color', R.s1, 'LineWidth', 2);
plot(ax, tara, maxK, '-', 'Color', R.s2, 'LineWidth', 2);
legend(ax, {'', 'açık çevrim', 'kapalı çevrim (motor tarafı P-PI)'}, 'Location', 'northwest', 'Box', 'off', 'TextColor', R.yazi2);
xlabel(ax, '\theta_0 [°]');  ylabel(ax, 'max Re(\lambda) [1/s]');  xticks(ax, 0:30:180);
title(ax, '(b) En sağdaki özdeğerin gerçel kısmı', 'FontWeight', 'normal');
stil(ax, R);  xlim(ax, [0 180]);
kaydet(f, fullfile(imgD, 'b3_ozdeger_aci.png'));

%% 3.4 Transfer fonksiyonu ve frekans yanıtı
yaz('--- 3.4 Transfer fonksiyonu ve frekans yanıtı ---\n\n');
% Elle: tau_m -> phi ve tau_m -> theta (temas, theta0). Payda ortak, paylar farklı:
%   G_M(s) = (J_L s^2 + (c_s + b_L) s + K_s + kg) / D(s)      (eşyerleşimli: tork ve ölçüm aynı kütlede)
%   G_L(s) = (c_s s + K_s) / D(s)                               (eşyerleşimsiz: ölçüm yayın öbür ucunda)
th0 = 90;  kg = p.mgl*cosd(th0);
D  = poly(A4(th0));
NM = [p.JL, p.cs + p.bL, p.Ks + kg]/(p.JM*p.JL);
NL = [p.cs, p.Ks]/(p.JM*p.JL);
sysM = ss(A4(th0), B4, Cm, 0);  sysL = ss(A4(th0), B4, Ck, 0);
gM = tf(sysM);  gL = tf(sysL);
yaz('theta0 = 90°, elle türetilen paylar ile ss -> tf karşılaştırması:\n');
yaz('  G_M pay (elle) : %s\n', strjoin(compose('%.5g', NM), '  '));
yaz('  G_M pay (tf)   : %s\n', strjoin(compose('%.5g', gM.Numerator{1}(end-2:end)), '  '));
yaz('  G_L pay (elle) : %s\n', strjoin(compose('%.5g', NL), '  '));
yaz('  G_L pay (tf)   : %s\n', strjoin(compose('%.5g', gL.Numerator{1}(end-1:end)), '  '));
yaz('  ortak payda    : %s\n', strjoin(compose('%.5g', D), '  '));
zM = roots(NM);  zL = roots(NL);
yaz('  G_M sıfırları (anti-rezonans): %s  -> |z| = %.1f rad/s = %.2f Hz\n', ozdegerYazi(zM), abs(zM(1)), abs(zM(1))/(2*pi));
yaz('  G_L sıfırı: %s (tek, reel, uzakta: -K_s/c_s)\n', ozdegerYazi(zL));
yaz('  kutuplar: %s\n', ozdegerYazi(roots(D)));
w = logspace(log10(2*pi*0.3), log10(2*pi*80), 1500);
[mM, fM] = bode(sysM, w);  [mL, fL] = bode(sysL, w);
mM = 20*log10(squeeze(mM));  mL = 20*log10(squeeze(mL));  fM = squeeze(fM);  fL = squeeze(fL);
fM = fM - 360*round((fM(1) + 180)/360);  fL = fL - 360*round((fL(1) + 180)/360);
bant = w > 2*pi*3 & w < 2*pi*30;  wB = w(bant);  mB = mL(bant);  [~, iR] = max(mB - interp1(log(w([1 end])), mL([1 end]), log(wB))');
[~, iA] = min(mM(w > 10 & w < 70));  wA = w(w > 10 & w < 70);
yaz('  Bode: rezonans tepesi ~%.2f Hz, G_M anti-rezonans çukuru ~%.2f Hz\n', wB(iR)/(2*pi), wA(iA)/(2*pi));
yaz('  Faz (rezonans üstü, 40 Hz): G_M %.0f°, G_L %.0f° -> eşyerleşimli faz -180°''ye geri döner,\n', ...
    interp1(w, fM, 2*pi*40), interp1(w, fL, 2*pi*40));
yaz('  eşyerleşimsiz -360°''ye iner (kol açısıyla kapatılan hızlı döngüde ek -180° faz: B1''in nedeni).\n\n');
f = yeniSekil(17, 9.5);
hz = w/(2*pi);
ax = subplot(2, 1, 1);  hold(ax, 'on');
semilogx(ax, hz, mM, '-', 'Color', R.s1, 'LineWidth', 2);
semilogx(ax, hz, mL, '-', 'Color', R.s2, 'LineWidth', 2);
xline(ax, wr/(2*pi), ':', 'Color', R.yazi2);  xline(ax, wa/(2*pi), ':', 'Color', R.yazi2);
text(ax, wr/(2*pi)*1.04, max(mM) - 2, strrep(sprintf('rezonans %.1f Hz', wr/(2*pi)), '.', ','), 'Color', R.yazi2, 'FontSize', 8);
text(ax, wa/(2*pi)/1.04, min(mM(hz > 3 & hz < 20)) - 3, strrep(sprintf('anti-rezonans %.1f Hz', wa/(2*pi)), '.', ','), ...
    'Color', R.yazi2, 'FontSize', 8, 'HorizontalAlignment', 'right');
set(ax, 'XScale', 'log');  ylabel(ax, 'Genlik [dB rad/(N m)]');
title(ax, 'Tork \rightarrow açı frekans yanıtı, \theta_0 = 90°, temas hâli', 'FontWeight', 'normal');
stil(ax, R);  xlim(ax, hz([1 end]));  set(ax, 'XTickLabel', []);
ax = subplot(2, 1, 2);  hold(ax, 'on');
semilogx(ax, hz, fM, '-', 'Color', R.s1, 'LineWidth', 2);
semilogx(ax, hz, fL, '-', 'Color', R.s2, 'LineWidth', 2);
xline(ax, wr/(2*pi), ':', 'Color', R.yazi2);  xline(ax, wa/(2*pi), ':', 'Color', R.yazi2);
set(ax, 'XScale', 'log');  yticks(ax, -360:90:0);  ylim(ax, [-380 10]);
xlabel(ax, 'Frekans [Hz]');  ylabel(ax, 'Faz [°]');
legend(ax, {'\tau_m \rightarrow \phi  (motor açısı, eşyerleşimli)', '\tau_m \rightarrow \theta  (kol açısı, eşyerleşimsiz)'}, ...
    'Location', 'southwest', 'Box', 'off', 'TextColor', R.yazi2);
stil(ax, R);  xlim(ax, hz([1 end]));
set(ax, 'XTick', [0.3 1 3 10 30 80], 'XTickLabel', {'0,3', '1', '3', '10', '30', '80'});
kaydet(f, fullfile(imgD, 'b3_bode.png'));

%% 3.5 Kontrol edilebilirlik ve gözlenebilirlik
yaz('--- 3.5 Kontrol edilebilirlik ve gözlenebilirlik ---\n\n');
% Sayısal ölçek: zaman rezonansla boyutsuzlaştırılır (A/wr, B/wr), yoksa A^3'ün elemanları ~1e10 olur
% ve rank kararı tolerans seçimine bağlı kalır. Rank kararı tekil değer oranıyla (1e-9).
pB = p;  pB.Ks = 0;  pB.cs = 0;                                 % boşluk: dişli torku yok
yaz('Durum [phi w_M theta w_L]; zaman 1/w_rez ile ölçeklendi; rank: sigma_i/sigma_1 > 1e-9 sayısı.\n');
yaz('%-8s %-8s | %-8s | %-30s | %-8s\n', 'hâl', 'theta0', 'rank O', 'O''nun tekil değerleri / sigma_1', 'rank Ctr');
durumlar = {'temas', p; 'boşluk', pB};
SV = zeros(4, 2);
for d = 1:2
    for th0 = [0 90 180]
        A = iki_kutle_A(durumlar{d,2}, th0)/wr;  B = B4/wr;
        O = obsvElle(A, Cm);  Ct = ctrbElle(A, B);
        so = svd(O);  sc = svd(Ct);
        rO = sum(so/so(1) > 1e-9);  rC = sum(sc/sc(1) > 1e-9);
        yaz('%-8s %7d° | %8d | %-30s | %8d\n', durumlar{d,1}, th0, rO, ...
            strjoin(compose('%.2e', so/so(1)), ' '), rC);
        if th0 == 180, SV(:,d) = so/so(1); end
        assert(rO == rank(obsv(A, Cm)) && rC == rank(ctrb(A, B)), 'elle obsv/ctrb ile araç kutusu uyuşmuyor');
    end
end
yaz('Boşlukta A blok köşegen: A = [A_motor 0; 0 A_kol], C_motor = [1 0 | 0 0], B = [0 1/J_M | 0 0]''.\n');
yaz('  -> kolun (theta, w_L) durumları ne motor ölçümünden görülür ne de motor torkuyla etkilenir.\n');
yaz('  Kol ölçümüyle (C_kol) boşlukta: rank O = %d (kol görülür, motor görülmez).\n', ...
    rank(obsvElle(iki_kutle_A(pB, 180)/wr, Ck)));
% Süreklilik: temas sertliğini k ile ölçekle (K_s k, c_s k), k -> 0 boşluğa yaklaşır.
kap = logspace(-8, 0, 161);  oran = zeros(size(kap));
for k = 1:numel(kap)
    q = p;  q.Ks = p.Ks*kap(k);  q.cs = p.cs*kap(k);
    so = svd(obsvElle(iki_kutle_A(q, 180)/wr, Cm));  oran(k) = so(end)/so(1);
end
yaz('Temas sertliği ölçeklenirse (180°): sigma_min/sigma_max = %.2e (k = 1), %.2e (k = 1e-4), %.2e (k = 1e-8)\n', ...
    oran(end), interp1(log10(kap), oran, -4), oran(1));
yaz('  -> gözlenebilirlik bağ zayıfladıkça sürekli kaybolur; boşlukta (k = 0) sıfır.\n');
yaz('180°''de ön yük sıfır (tau_m0 = 0, delta0 = r): kol boşluğun içinde kalabilir; bu durumda hangi yüze dayandığı\n');
yaz('(delta işareti) motor ölçümünden çıkarılamaz. Yüz belirsizliği = boşluktaki gözlenemezlik (Bölüm 6).\n\n');
f = yeniSekil(17, 7);
ax = subplot(1, 2, 1);  hold(ax, 'on');
xs = 1:4;
SVp = SV;  SVp(SVp < 1e-17) = 1e-17;                            % log eksende sıfırı tabana yasla
plot(ax, xs, SVp(:,1), '-o', 'Color', R.s1, 'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', R.s1, 'MarkerEdgeColor', 'w');
plot(ax, xs, SVp(:,2), '-o', 'Color', R.s2, 'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', R.s2, 'MarkerEdgeColor', 'w');
yline(ax, 1e-9, '--', 'Color', R.yazi2);
text(ax, 4.45, 1e-9, 'rank eşiği', 'Color', R.yazi2, 'FontSize', 8, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
text(ax, 3.5, 1e-16, 'boşlukta 0', 'Color', R.yazi2, 'FontSize', 8, 'VerticalAlignment', 'bottom');
set(ax, 'YScale', 'log');  ylim(ax, [1e-17 10]);  xlim(ax, [0.5 4.5]);  xticks(ax, 1:4);
xlabel(ax, 'tekil değer sırası i');  ylabel(ax, '\sigma_i / \sigma_1');
legend(ax, {'temas: rank 4', 'boşluk: rank 2'}, 'Location', 'east', 'Box', 'off', 'TextColor', R.yazi2);
title(ax, '(a) Gözlenebilirlik matrisi, C_{motor}, \theta_0 = 180°', 'FontWeight', 'normal');
stil(ax, R);
ax = subplot(1, 2, 2);  hold(ax, 'on');
loglog(ax, kap, oran, '-', 'Color', R.s1, 'LineWidth', 2);
set(ax, 'XScale', 'log', 'YScale', 'log');
xlabel(ax, 'temas sertliği çarpanı  \kappa  (K_s\kappa, c_s\kappa)');  ylabel(ax, '\sigma_{min} / \sigma_{max}');
text(ax, 1, oran(end)/100, 'gerçek temas (\kappa = 1)', 'Color', R.yazi2, 'FontSize', 8, 'HorizontalAlignment', 'right');
text(ax, 1e-8*1.5, oran(1)*3, '\kappa \rightarrow 0: boşluk', 'Color', R.yazi2, 'FontSize', 8);
title(ax, '(b) Bağ zayıfladıkça kaybolur', 'FontWeight', 'normal');
stil(ax, R);  xlim(ax, kap([1 end]));
kaydet(f, fullfile(imgD, 'b3_gozlenebilirlik.png'));

%% 3.6 Ayrıklaştırma: c2d, Ts = 1 ms
yaz('--- 3.6 Ayrıklaştırma: c2d (ZOH), Ts = 1 ms ---\n\n');
Ts = 1e-3;
% ZOH tam çözümü: aralık boyunca u sabitse x[k+1] = e^{A Ts} x[k] + (int_0^Ts e^{A t} dt) B u[k].
% İkisi tek bir matris üstelinden: expm([A B; 0 0] Ts) = [A_d B_d; 0 I].
for th0 = [90 180]
    A = A4(th0);  M = expm([A, B4; zeros(1, 5)]*Ts);
    Ad = M(1:4, 1:4);  Bd = M(1:4, 5);
    sd = c2d(ss(A, B4, Cm, 0), Ts, 'zoh');
    yaz('theta0 = %d°: max|A_d(elle) - A_d(c2d)| = %.1e, max|B_d farkı| = %.1e\n', th0, ...
        max(abs(Ad - sd.A), [], 'all'), max(abs(Bd - sd.B)));
    zd = sort(eig(Ad));  ze = sort(exp(eig(A)*Ts));
    yaz('  eig(A_d)       : %s\n', ozdegerYazi(zd));
    yaz('  exp(eig(A) Ts) : %s   (z = e^{s Ts} eşlemesi)\n', ozdegerYazi(ze));
    yaz('  |z| = %s\n', strjoin(compose('%.5f', abs(zd)), ', '));
end
yaz('Rezonans: w_rez Ts = %.4f rad/örnek -> periyot başına %.0f örnek (Nyquist %.0f Hz >> %.1f Hz)\n', ...
    wr*Ts, 2*pi/(wr*Ts), 1/(2*Ts), wr/(2*pi));
yaz('180° kararsız kutup s = %.3f -> z = %.5f (birim çemberin dışında, |z| > 1)\n', maxA(end), exp(maxA(end)*Ts));
zcl = exp(eig(Acl(180))*Ts);
yaz('Kapalı çevrim 180° (sürekli tasarımın ZOH karşılığı): |z| en büyük %.5f (< 1)\n', max(abs(zcl)));
Acl_d = expm(Acl(180)*Ts);
yaz('  (gerçek ayrık döngü için: kontrolcü örneklemesi + ZOH ile kapalı çevrim aşağıda 3.7''de gözlemciyle birlikte)\n\n');

%% 3.7 Luenberger gözlemcisi
yaz('--- 3.7 Luenberger gözlemcisi ---\n\n');
% Koddaki tork gözlemcisi (kol_benzetim.m, kartta kontrol.cpp): yalnız motor kütlesinin modeli,
% dişli torku + sürtünme bilinmeyen bozucu d olarak duruma eklenir (genişletilmiş durum):
%   x_o = [phi; w_M; d],  phi' = w_M,  w_M' = (u - b_M w_M - d)/J_M,  d' = 0,  y = phi
%   x_o^' = A_o x_o^ + B_o u + L (y - C_o x_o^),   L = [3 w_o; 3 w_o^2; -J_M w_o^3]
% Koddaki işaret: d^ = d^ - Ts l3 e  ->  L(3) = -l3 = -J_M w_o^3.
wo = 2*pi*40;
Ao = [0 1 0; 0 -p.bM/p.JM -1/p.JM; 0 0 0];  Bo = [0; 1/p.JM; 0];  Co = [1 0 0];
Lo = [3*wo; 3*wo^2; -p.JM*wo^3];
yaz('w_o = 2 pi 40 = %.1f rad/s, L = [%.4g; %.4g; %.4g]\n', wo, Lo);
yaz('rank O(A_o, C_o) = %d (3 durum): temas ya da boşluk fark etmez, çünkü dişli torku modelin dışında, d''de\n', ...
    rank(obsvElle(Ao/wo, Co)));
eo = eig(Ao - Lo*Co);
yaz('Sürekli hata dinamiği eig(A_o - L C_o) = %s  (hedef üçlü kutup -w_o = %.1f; fark b_M''den)\n', ozdegerYazi(eo), -wo);
Phi = eye(3) + Ts*(Ao - Lo*Co);                               % kodun ileri Euler güncellemesi
zo = eig(Phi);
yaz('Kodun ayrık (ileri Euler, Ts = 1 ms) hata dinamiği eig = %s, |z| <= %.4f\n', ozdegerYazi(zo), max(abs(zo)));
yaz('  ZOH karşılığı e^{-w_o Ts} = %.4f; w_o Ts = %.3f küçük olduğu için Euler yeterli\n', exp(-wo*Ts), wo*Ts);
yaz('Kestirim süresi ~ 3/w_o = %.0f ms (kodda yoklama itişinin en kısa süresi yokTmin = 3/gozW ile aynı)\n', 3e3/wo);

% Benzetim: gerçek tesis (ölü bölgeli doğrusal olmayan f, RK4 0,1 ms), kol aşağıda (theta0 = 0°, ön yük 0),
% motor torku u = 0,15 sin(2 pi 1,5 t): motor boşluğu her yarım periyotta geçer. Gözlemci 1 kHz, ölçüm
% motor milindeki AS5600 nicemlemesiyle (2 pi/(4096 N)), yanlış başlangıçla: phi^ +0,5°, w^ = 0, d^ = 0,05 N m.
dt = 1e-4;  T = 1.5;  nA = round(Ts/dt);  qM = 2*pi/(4096*p.N);
x = [0; 0; 0; 0];  xo = [deg2rad(0.5); 0; 0.05];
nK = round(T/Ts);  kay = zeros(nK, 7);
for k = 1:nK
    t = (k - 1)*Ts;  u = 0.15*sin(2*pi*1.5*t);
    y = qM*round(x(1)/qM);
    xo = xo + Ts*(Ao*xo + Bo*u + Lo*(y - Co*xo));             % kodla aynı sıra: önce ölçüm, sonra güncelle
    for j = 1:nA
        fx = @(z) f_dogrusalOlmayan(z, u, p, 'tam');
        k1 = fx(x); k2 = fx(x + dt/2*k1); k3 = fx(x + dt/2*k2); k4 = fx(x + dt*k3);
        x = x + dt/6*(k1 + 2*k2 + 2*k3 + k4);
    end
    [~, ts] = dis_tork(x, p);
    kay(k,:) = [t + Ts, x(2), xo(2), ts, xo(3), x(1) - x(3), u];
end
tt = kay(:,1);
e0 = find(abs(kay(:,5) - kay(:,4)) < 0.005 & tt > 0.002, 1);
bosl = abs(kay(:,6)) < p.r;
yaz('\nBenzetim (theta0 = 0°, u = 0,15 sin(2 pi 1,5 t), AS5600 nicemlemesi, 1 kHz):\n');
yaz('  d^ hatası ilk kez < 0,005 N m: %.0f ms\n', 1e3*tt(e0));
yaz('  t > 0,1 s: |d^ - tau_s| RMS %.4f N m, en büyük %.4f N m; |w^ - w_M| RMS %.3f rad/s\n', ...
    rms(kay(tt > 0.1,5) - kay(tt > 0.1,4)), max(abs(kay(tt > 0.1,5) - kay(tt > 0.1,4))), rms(kay(tt > 0.1,3) - kay(tt > 0.1,2)));
yaz('  zamanın %%%.0f''inde boşlukta (tau_s = 0); boşlukta |d^| RMS %.4f N m -> gözlemci boşluğu da görüyor\n\n', ...
    100*mean(bosl), rms(kay(bosl & tt > 0.1, 5)));
f = yeniSekil(17, 10);
ax = subplot(3, 1, 1);  hold(ax, 'on');
golgele(ax, tt, bosl, [-0.2 0.2], R);
plot(ax, tt, kay(:,4), '-', 'Color', R.s2, 'LineWidth', 2);
plot(ax, tt, kay(:,5), '-', 'Color', R.s1, 'LineWidth', 1.2);
ylabel(ax, 'tork [N m]');  ylim(ax, [-0.2 0.2]);
legend(ax, {'boşlukta (\tau_s = 0)', 'gerçek dişli torku \tau_s', 'gözlemci kestirimi'}, 'Location', 'eastoutside', 'Box', 'off', 'TextColor', R.yazi2);
title(ax, 'Tork gözlemcisi: \theta_0 = 0°, u = 0,15 sin(2\pi 1,5 t), AS5600 nicemlemesi, 1 kHz', 'FontWeight', 'normal');
stil(ax, R);  set(ax, 'XTickLabel', []);  xlim(ax, [0 T]);
ax = subplot(3, 1, 2);  hold(ax, 'on');
golgele(ax, tt, bosl, 1.1*[-1 1]*max(abs(kay(:,2))), R);
plot(ax, tt, kay(:,2), '-', 'Color', R.s2, 'LineWidth', 2);
plot(ax, tt, kay(:,3), '-', 'Color', R.s1, 'LineWidth', 1.2);
ylabel(ax, 'hız [rad/s]');  ylim(ax, 1.1*[-1 1]*max(abs(kay(:,2))));
legend(ax, {'boşlukta', 'gerçek \omega_M', 'gözlemci kestirimi'}, 'Location', 'eastoutside', 'Box', 'off', 'TextColor', R.yazi2);
stil(ax, R);  set(ax, 'XTickLabel', []);  xlim(ax, [0 T]);
ax = subplot(3, 1, 3);  hold(ax, 'on');
ilk = tt <= 0.06;
semilogy(ax, 1e3*tt(ilk), abs(kay(ilk,5) - kay(ilk,4)), '-', 'Color', R.s1, 'LineWidth', 2);
set(ax, 'YScale', 'log');  ylim(ax, [1e-5 1]);  yticks(ax, 10.^(-5:0));
xlabel(ax, 'zaman [ms] (ilk 60 ms)');  ylabel(ax, 'tork hatası [N m]');
legend(ax, {'|kestirim - \tau_s|'}, 'Location', 'eastoutside', 'Box', 'off', 'TextColor', R.yazi2);
stil(ax, R);
kaydet(f, fullfile(imgD, 'b3_gozlemci.png'));

% Şekil 3.5 (c2d): s-düzlemi ve z-düzlemi, 180°: açık çevrim + kapalı çevrim + gözlemci
f = yeniSekil(17, 7.5);
sA = eig(A4(180));  sK = eig(Acl(180));  sO = eo;
ax = subplot(1, 2, 1);  hold(ax, 'on');
xline(ax, 0, 'Color', R.yazi2);  yline(ax, 0, 'Color', R.izgara);
plot(ax, real(sA), imag(sA), 'x', 'Color', R.s2, 'MarkerSize', 9, 'LineWidth', 2);
plot(ax, real(sK), imag(sK), 'o', 'Color', R.s1, 'MarkerSize', 7, 'LineWidth', 1.5);
plot(ax, real(sO), imag(sO), 's', 'Color', R.s3, 'MarkerSize', 7, 'LineWidth', 1.5);
xlabel(ax, 'Re(s) [1/s]');  ylabel(ax, 'Im(s) [rad/s]');
legend(ax, {'', '', 'açık çevrim (180°)', 'kapalı çevrim P-PI (180°)', 'gözlemci (-\omega_o)'}, 'Location', 'southwest', 'Box', 'off', 'TextColor', R.yazi2);
title(ax, '(a) s-düzlemi', 'FontWeight', 'normal');  stil(ax, R);
xlim(ax, [-280 20]);  ylim(ax, [-100 100]);
ax = subplot(1, 2, 2);  hold(ax, 'on');
fi = linspace(0, 2*pi, 400);
plot(ax, cos(fi), sin(fi), '-', 'Color', R.yazi2, 'LineWidth', 1);
zA = exp(sA*Ts);  zK = exp(sK*Ts);  zO = exp(sO*Ts);
plot(ax, real(zA), imag(zA), 'x', 'Color', R.s2, 'MarkerSize', 9, 'LineWidth', 2);
plot(ax, real(zK), imag(zK), 'o', 'Color', R.s1, 'MarkerSize', 7, 'LineWidth', 1.5);
plot(ax, real(zO), imag(zO), 's', 'Color', R.s3, 'MarkerSize', 7, 'LineWidth', 1.5);
text(ax, 0.995, 0.088, 'birim çember', 'Color', R.yazi2, 'FontSize', 8, 'HorizontalAlignment', 'right');
xlabel(ax, 'Re(z)');  ylabel(ax, 'Im(z)');
title(ax, '(b) z-düzlemi, z = e^{sT_s}, T_s = 1 ms (yakın görünüm)', 'FontWeight', 'normal');
stil(ax, R);  xlim(ax, [0.74 1.02]);  ylim(ax, [-0.1 0.1]);
kaydet(f, fullfile(imgD, 'b3_c2d.png'));

%% 3.8 Doğrusal olmayana uzanım: hesap adım 4 raporunda (§5), burada yok.
yaz('--- 3.8 Tanımlama fonksiyonu: hesap adım 4 raporunda (rapor/adim4_simulasyon_ve_dogrulama.pdf §5) ---\n');

fclose(fid);

%% ---------- yerel fonksiyonlar ----------
function A = pid_kapali(q, th0, wc, kay)
% Eski PID (rijit model kazançları), konum kol açısından; türev kol (kay 1) ya da motor (kay 2) hızından.
% Durum [phi w_M theta w_L z], z' = -theta (ref 0), tau = -Kp theta + Ki z - Kd v.
J = q.JM + q.JL;  Kp = J*wc^2;  Kd = 1.4*J*wc;  Ki = Kp*wc/4;
A0 = iki_kutle_A(q, th0);  B = [0; 1/q.JM; 0; 0];
if kay == 1, K = [0 0 -Kp -Kd]; else, K = [0 -Kd -Kp 0]; end
A = [A0 + B*K, B*Ki; 0 0 -1 0 0];
end

function s = sinirYazi(w)
if isnan(w), s = '120''ye kadar kararlı'; else, s = sprintf('%.1f', w); end
end

function O = obsvElle(A, C)
n = size(A,1);  O = zeros(n*size(C,1), n);  M = C;
for i = 1:n, O((i-1)*size(C,1) + (1:size(C,1)), :) = M;  M = M*A; end
end

function Ct = ctrbElle(A, B)
n = size(A,1);  Ct = zeros(n, n*size(B,2));  M = B;
for i = 1:n, Ct(:, (i-1)*size(B,2) + (1:size(B,2))) = M;  M = A*M; end
end

function [d, ts] = dis_tork(x, p)
d = x(1) - x(3);  dd = x(2) - x(4);
if d > p.r,      ts = max(p.Ks*(d - p.r) + p.cs*dd, 0);
elseif d < -p.r, ts = min(p.Ks*(d + p.r) + p.cs*dd, 0);
else,            ts = 0; end
end

function c = hex2rgb(h)
c = sscanf(h(2:end), '%2x%2x%2x', [1 3])/255;
end

function f = yeniSekil(gen, yuk)
f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2 2 gen yuk]);
set(f, 'DefaultAxesFontName', 'Arial', 'DefaultTextFontName', 'Arial', 'DefaultAxesFontSize', 8.5);
end

function stil(ax, R)
set(ax, 'Box', 'off', 'TickDir', 'out', 'XColor', R.yazi2, 'YColor', R.yazi2, 'LineWidth', 0.6, ...
    'XGrid', 'on', 'YGrid', 'on', 'GridColor', R.izgara, 'GridAlpha', 1, 'MinorGridLineStyle', 'none', ...
    'FontName', 'Arial', 'FontSize', 8.5);
ax.Title.Color = R.yazi;  ax.Title.FontSize = 9;
end

function golgele(ax, t, m, yl, R)
% m = true olan zaman aralıklarını açık gri bant olarak çizer (ilk bant lejanta girer).
d = diff([0; m(:); 0]);  bas = find(d == 1);  son = find(d == -1) - 1;
for i = 1:numel(bas)
    h = patch(ax, t([bas(i) son(i) son(i) bas(i)]), yl([1 1 2 2]), R.izgara, 'EdgeColor', 'none');
    if i > 1, h.HandleVisibility = 'off'; end
end
if isempty(bas), patch(ax, NaN(1,4), NaN(1,4), R.izgara, 'EdgeColor', 'none'); end
end

function kaydet(f, yol)
exportgraphics(f, yol, 'Resolution', 200, 'BackgroundColor', 'white');
close(f);
end

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
