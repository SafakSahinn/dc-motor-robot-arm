% TEK_DENEME  0, 45, 90, 135, 180 derecede aynı kazançla, üç model seviyesinde.
ac = [0 45 90 135 180];
wc = 20;
sev = {'ideal','surtunme','gercekci'};
fig = figure('Visible','off','Position',[100 100 1000 820]);
tiledlayout(3,2,'TileSpacing','compact');
for s = 1:numel(sev)
    p = parametreler(sev{s});
    o = kol_benzetim(p, ac, wc*ones(size(ac)));
    fprintf('\n[%s] wc = %g rad/s\n', sev{s}, wc);
    fprintf('%6s %9s %7s %7s %9s %9s\n','aci','A[der]','gecis','f[Hz]','bosluk%','kararsiz');
    for j = 1:numel(ac)
        fprintf('%6g %9.3f %7d %7.2f %9.1f %9d\n', ac(j), o.A_deg(j), o.gecis(j), o.f_Hz(j), 100*o.bosluk_orani(j), o.kararsiz(j));
    end
    nexttile; plot(o.t, rad2deg(o.th) - ac); ylabel('\theta - \theta_0 [der]'); title(sprintf('%s: kol açısı sapması', sev{s}));
    if s == 1, legend(compose('%g°',ac),'Location','northeast','NumColumns',5); end
    nexttile; plot(o.t, rad2deg(o.delta)); yline(rad2deg(p.r)*[-1 1],'k--'); ylabel('\phi - \theta [der]'); title(sprintf('%s: boşluk içindeki konum', sev{s}));
end
xlabel('t [s] (son 3 s)');
exportgraphics(fig, 'tek_deneme.png', 'Resolution', 120);
