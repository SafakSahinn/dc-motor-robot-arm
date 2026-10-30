function ghaffari_tabla(sadece_ciz)
% GHAFFARI_TABLA  Döner tabla (Şekil 11): kp ve kv taraması; benzetim (sürtünmeli ve
% sürtünmesiz), tam DF ve denklem 12, deney verisiyle (veri_sekil11.csv) karşılaştırma.
% Her kazanç iki başlangıç sapmasıyla koşulur (çarpma rejiminde sonuç ona bağlı olabilir);
% frekans, salınım bulunan koşuların en büyüğüdür.
% ghaffari_tabla(true): kayıtlı tabla_sonuclar.mat'tan yalnızca çizer.
if nargin > 0 && sadece_ciz
    load('tabla_sonuclar.mat', 'S', 'dA', 'dB');
    ciz(S, dA, dB, readtable('veri_sekil11.csv', 'TextType','string'));
    return
end
kpA = [3.8 5.8 6.2 6.7 8.3 10 10.2 11 11.7 13.3 15 16.7 18.3];   kvA = 20*ones(size(kpA));
kvB = [1.5 2 3 5 10 15 17 17.5 18.5 20 25 30 40 50];             kpB = 11.6*ones(size(kvB));
th0 = [0.05 1 3];
S = struct();
for surt = [1 0]
    p = ghaffari_param('tabla');
    if ~surt, p.Fcm = 0; p.Fcl = 0; end
    for g = 'AB'
        if g == 'A', kp = kpA; kv = kvA; else, kp = kpB; kv = kvB; end
        F = zeros(numel(th0), numel(kp));  A = F;
        for i = 1:numel(th0)
            p.th0 = deg2rad(th0(i));
            o = ghaffari2013(p, kp, kv);
            F(i,:) = o.f_Hz .* (o.A_deg > 2*rad2deg(p.delta)*0.05);   % çok küçük titreşimi sayma
            A(i,:) = o.A_deg;
        end
        S.(sprintf('%s_%d', g, surt)) = struct('kp',kp,'kv',kv,'F',F,'A',A,'f',max(F,[],1));
        fprintf('%s sürtünme=%d tamam\n', g, surt);
    end
end
p = ghaffari_param('tabla');
dA = ghaffari_df(p, kpA, kvA);  dB = ghaffari_df(p, kpB, kvB);
save('tabla_sonuclar.mat', 'S', 'dA', 'dB', 'th0');

% --- Deney verisi ve hata ---
V = readtable('veri_sekil11.csv', 'TextType','string');
fid = fopen('tabla_log.txt','w');
yaz(fid, 'Döner tabla: kse = %.1f N m/rad, fa = %.1f Hz\n\n', p.kse, p.fa);
kols = {'A','kp',dA,'11a'; 'B','kv',dB,'11b'};
for r = 1:2
    g = kols{r,1}; ad = kols{r,2}; d = kols{r,3}; sk = kols{r,4};
    s1 = S.([g '_1']);  s0 = S.([g '_0']);
    if g == 'A', x = s1.kp; else, x = s1.kv; end
    yaz(fid, 'Şekil %s (%s taraması)\n', sk, ad);
    yaz(fid, '%6s %5s | %7s %7s %7s | %7s %7s %7s | %7s %7s\n', ad, 'r_gs', 'deney', 'sim', 'sim(m)', 'sim0', 'sim0(m)', 'DF', 'DF(m)', 'denk12');
    es = []; et = []; e12 = [];
    for j = 1:numel(x)
        v = V(V.sekil==sk & abs(V.(sprintf('%s_%s', ad, ternary(ad=="kp",'1_s','Nms_rad'))) - x(j)) < 1e-9, :);
        fe = nan; fsm = nan; fs0m = nan; fdm = nan;
        if ~isempty(v)
            fe = v.deney_Hz(1); fsm = v.sim_Hz(1); fs0m = v.sim_surtunmesiz_Hz(1); fdm = v.df_Hz(1);
        end
        fdf = d.f_df(j);
        yaz(fid, '%6.1f %5.2f | %7.2f %7.2f %7.2f | %7.2f %7.2f %7.2f | %7.2f %7.2f\n', x(j), d.rgs(j), fe, s1.f(j), fsm, s0.f(j), fs0m, fdf, fdm, d.f_eq12(j));
        if fe > 0
            es(end+1) = 100*(s1.f(j)-fe)/fe; et(end+1) = 100*(fdf-fe)/fe; e12(end+1) = 100*(d.f_eq12(j)-fe)/fe; %#ok<AGROW>
        end
    end
    yaz(fid, 'Ortalama mutlak hata, deneyin salındığı noktalar: sim %.1f%%, DF %.1f%%, denklem 12 %.1f%%\n', mean(abs(es)), mean(abs(et)), mean(abs(e12)));
    yaz(fid, '  (makale, Tablo I: sim %s, DF %s)\n\n', ternary(g=='A','2.4%','3.3%'), ternary(g=='A','19.6%','21.4%'));
end
fclose(fid);
ciz(S, dA, dB, V);
end

function ciz(S, dA, dB, V)
fig = figure('Visible','off','Position',[100 100 1300 520]);
ad = {'kp','kv'};  sk = {'11a','11b'};  d = {dA, dB};  g = 'AB';
for r = 1:2
    subplot(1,2,r); hold on; grid on;
    s1 = S.([g(r) '_1']);  s0 = S.([g(r) '_0']);
    if r == 1, x = s1.kp; vx = V.kp_1_s; else, x = s1.kv; vx = V.kv_Nms_rad; end
    m = V.sekil == sk{r};
    plot(vx(m & ~isnan(V.deney_Hz)), V.deney_Hz(m & ~isnan(V.deney_Hz)), 'ko', 'MarkerFaceColor','k', 'DisplayName','deney (makale)');
    plot(vx(m & ~isnan(V.sim_Hz)), V.sim_Hz(m & ~isnan(V.sim_Hz)), 's', 'Color',[0.45 0.45 0.45], 'MarkerSize',9, 'DisplayName','benzetim, sürtünmeli (makale)');
    plot(vx(m & ~isnan(V.df_Hz)), V.df_Hz(m & ~isnan(V.df_Hz)), 'v', 'Color',[0.45 0.45 0.45], 'MarkerSize',9, 'DisplayName','DF (makale)');
    plot(x, s1.f, 's-', 'Color',[0.80 0.30 0.20], 'MarkerFaceColor',[0.80 0.30 0.20], 'DisplayName','benzetim, sürtünmeli (bu çalışma)');
    plot(x, s0.f, 's--', 'Color',[0.80 0.30 0.20], 'DisplayName','benzetim, sürtünmesiz (bu çalışma)');
    fdf = d{r}.f_df;
    plot(x, fdf, 'v:', 'Color',[0.18 0.42 0.35], 'LineWidth',1.4, 'DisplayName','tam DF (bu çalışma)');
    plot(x, d{r}.f_eq12, '-', 'Color',[0.6 0.6 0.9], 'DisplayName','denklem 12');
    yline(15.3, ':', 'f_a', 'HandleVisibility','off');
    xlabel(sprintf('%s', ternary(r==1,'k_p [1/s]  (k_v = 20)','k_v [N m s/rad]  (k_p = 11,6)')));
    ylabel('çevrim frekansı [Hz]  (0 = salınım yok)'); ylim([-1 25]);
    title(sprintf('Şekil %s', sk{r}));
    if r == 1, legend('Location','northwest','FontSize',8); end
end
sgtitle('Ghaffari 2013, döner tabla: deney, makalenin DF''si ve bu çalışmanın benzetimi/DF''si');
exportgraphics(fig, 'tabla_karsilastirma.png', 'Resolution', 110);
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end

function c = ternary(k, a, b)
if k, c = a; else, c = b; end
end
