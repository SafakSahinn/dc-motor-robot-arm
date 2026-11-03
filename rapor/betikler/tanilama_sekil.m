function tanilama_sekil(kok, cik)
% Bölüm 10 şekilleri (sistem tanılama): dijital ikizin firmware kayıtlarından (gerçekçi sensör düzeyi).
if ~exist(cik,'dir'), mkdir(cik); end
set(groot,'defaultAxesFontSize',10,'defaultLineLineWidth',1.1,'defaultFigureColor','w');
d = @(x) rad2deg(x);
kaydet = @(f,ad) exportgraphics(f, fullfile(cik,[ad '.png']), 'Resolution', 200);

%% D3: K_s, 90 +- 70 yarı statik tarama
try
L = load(fullfile(kok,'tani_Ks_kayit.mat')); R = L.R;
k = find(strcmp({R.duz},'gercekci'),1); K = R(k).K; S = R(k).S;
f = figure('Position',[0 0 1000 330]);
subplot(1,3,1); plot(K.t, d(K.thL)); grid on; xlabel('t [s]'); ylabel('\theta_L [°]'); title('Kol açısı (AS5600 kaydı)');
dm = d(K.phi - K.thL);
subplot(1,3,2); plot(K.t, dm); grid on; xlabel('t [s]'); ylabel('\delta_m = \phi - \theta_L [°]'); title('Ölçülen dişli sapması');
subplot(1,3,3); sel = K.t > 1; plot(S.Km*K.i(sel), dm(sel), '.', 'MarkerSize', 2); grid on;
xlabel('K_m i [N·m]'); ylabel('\delta_m [°]'); title('Sapma – tork (düzeltmesiz ham)');
kaydet(f,'D3_Ks'); close(f);
catch e, disp(e.message); end

%% D4: r, 0 +- 60 tarama
try
L = load(fullfile(kok,'tani_r_kayit.mat')); R = L.R;
k = find(strcmp({R.duz},'gercekci'),1); K = R(k).K; S = R(k).S;
f = figure('Position',[0 0 1000 360]);
subplot(1,2,1); plot(K.t, d(K.thL)); grid on; xlabel('t [s]'); ylabel('\theta_L [°]'); title('Kol 0° ± 60° taranıyor (r_{gs} 0,5)');
x = d(K.thL); y = d(K.phi - K.thL - S.Km*K.i/S.Ks);
sel = K.t > 1; ic = sel & abs(x) < 10; dis = sel & abs(x) >= 10;
subplot(1,2,2); plot(x(dis), y(dis), '.', 'MarkerSize', 3); hold on; plot(x(ic), y(ic), '.', 'Color', [.75 .75 .75], 'MarkerSize', 3);
yline(d(S.r),'k--'); yline(-d(S.r),'k--'); grid on;
xlabel('\theta_L [°]'); ylabel('\delta_m - K_m i / K_s [°]'); title(sprintf('İki dişli yüzü: kümeler arası 2r (gerçek 2r = %.1f°)', 2*d(S.r)));
legend({'|θ| ≥ 10° (kullanılan)','|θ| < 10° (atılan)','± r'},'Location','northwest');
kaydet(f,'D4_r'); close(f);
catch e, disp(e.message); end

%% D5: c_s, motor kilitli vuruş
try
L = load(fullfile(kok,'tani_cs_kilit_kayit.mat')); R = L.R;
f = figure('Position',[0 0 1000 340]); hold on; ren = lines(4); cl = [0 0.01 0.02 0.04]; h = gobjects(0); et = {};
for j = 1:4
    k = find(strcmp({R.ad},'kilit') & strcmp({R.duz},'gercekci') & abs([R.cs]-cl(j))<1e-9, 1);
    if isempty(k), continue; end
    K = R(k).K; t0 = R(k).d0; sel = K.t >= t0 - 0.05 & K.t <= t0 + 0.6;
    th = d(K.thL(sel)); th = th - mean(d(K.thL(K.t > t0-0.3 & K.t < t0-0.01)));
    h(end+1) = plot(K.t(sel) - t0, th, 'Color', ren(j,:)); et{end+1} = sprintf('c_s = %.2f', cl(j)); %#ok<AGROW>
end
grid on; xlabel('vuruştan sonra t [s]'); ylabel('\theta_L - \theta_{0} [°]'); legend(h, et);
title('Motor dişlisi kilitli, kol 90°: vuruş sonrası sönüm (AS5600 kaydı)');
kaydet(f,'D5_cs'); close(f);
catch e, disp(e.message); end

%% D2: F_s, kol sökülü yavaş tork rampası
try
L = load(fullfile(kok,'tani_Fs_kayit.mat')); R = L.R;
k = find(strcmp({R.duz},'gercekci'),1); K = R(k).K; S = R(k).S;
f = figure('Position',[0 0 1000 340]);
subplot(1,2,1); plot(K.t, S.Km*K.i); hold on; yline(S.Fs,'k--'); yline(-S.Fs,'k--'); grid on;
xlabel('t [s]'); ylabel('K_m i [N·m]'); title('Tork (akımdan): yavaş sinüs, kol sökülü');
q = S.qM; n = round((K.phi - K.phi(1))/q); kb = find(abs(n) >= 2, 1); tb = K.t(kb);
sel = K.t > tb - 1.5 & K.t < tb + 0.5;
subplot(1,2,2); yyaxis left; plot(K.t(sel), S.Km*K.i(sel)); ylabel('K_m i [N·m]'); yline(S.Fs,'--');
yyaxis right; stairs(K.t(sel), n(sel)); ylabel('enkoder sayımı'); xline(tb,':');
grid on; xlabel('t [s]'); title(sprintf('Kopma anı yakın plan (gerçek F_s = %.2f N·m, kesikli)', S.Fs));
kaydet(f,'D2_Fs'); close(f);
catch e, disp(e.message); end

%% c_s duyarlılığı (tarama_cs_log.txt tablosu)
cs = [0 0.01 0.02 0.04];
G = [0.80 1.05 1.05; 0.90 1.20 1.20; 1.00 1.30 1.30; 1.10 1.35 1.40];
f = figure('Position',[0 0 620 360]); plot(cs, G, '-o'); grid on;
xline(0.02,':','varsayılan'); xlabel('c_s [N·m·s/rad]'); ylabel('kritik r_{gs}');
legend({'30°','60°','90°'},'Location','southeast'); title('Öngörünün temas sönümüne duyarlılığı (gerçekçi sensör, gözlemci)');
text(0.001,0.83,'30°, c_s = 0: ≤ 0,80','FontSize',8);
kaydet(f,'cs_duyarlilik'); close(f);

%% Öngörü doğrulaması (tani_dogrula_log.txt tablosu)
a = [30 60 90];
f = figure('Position',[0 0 620 360]); hold on;
plot(a, [1.00 1.30 1.30], 'ks-', 'MarkerSize', 9, 'MarkerFaceColor', 'k');
plot(a, [0.95 1.30 1.30], 'o--', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(a, [0.95 1.25 1.25], '^:', 'MarkerSize', 7);
grid on; xlim([20 100]); ylim([0.85 1.4]); xticks(a); xlabel('kol açısı \theta_0 [°]'); ylabel('kritik r_{gs}');
legend({'gerçek tesis','tanılanan (F_s ölçülmüş)','tanılanan (F_s = F_c)'},'Location','southeast');
title('Tanılanan değerlerle kurulan ikizin öngörüsü (tarama adımı 0,05)');
kaydet(f,'ongoru'); close(f);
end
