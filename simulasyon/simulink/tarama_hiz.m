function tarama_hiz()
% TARAMA_HIZ  Hız kestirimi salınım sınırını kaydırıyor mu? (Adım 4 öncesi yan soru)
% sm_motor_model, mod 1 (gerilim), D düzeneği, P-PI, gerçekçi sensör (dogrula_3 ayarı).
% Kestiriciler (blok_ayrik): fark (varsayılan, 5b ile aynı), periyot, gozlemci.
% Hipotez: fark kestiriminin nicemleme gürültüsü (u std ~0.22 N m) titreşim etkisiyle (dither) kısa
% salınımları bastırıyor; gerçekçi sensördeki yüksek kritik r_gs'nin bir kısmı buradan geliyor olabilir.
% Sınır: herhangi bir başlangıç sapmasında sınıf >= 3 ve A > 0.5° (README 5b).
% Çıktı: tarama_hiz.mat, tarama_hiz_log.txt.
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
ac = [30 60 90];  rgs = 0.90:0.05:1.45;  bas = [0.2 1 5];  hz = {'fark', 'periyot', 'gozlemci'};
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'tarama_hiz_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Hız kestirimi - salınım sınırı, mod 1, gerçekçi sensör (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
[AC, RG, BA] = ndgrid(ac, rgs, bas);
B = struct('ac', ac, 'rgs', rgs, 'bas', bas, 'hz', {hz}, 'C', NaN(numel(hz), numel(AC)), ...
           'A', NaN(numel(hz), numel(AC)), 'f', NaN(numel(hz), numel(AC)));
for h = 1:numel(hz)
    tic;
    for j = 1:numel(AC)
        q = p0;  q.adim = BA(j);  q.mot = 1;  q.hiz = hz{h};
        q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
        q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;
        S = sim_param(q, AC(j), RG(j)^2*q.Ks/q.KV);
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
               .setVariable('Tsur', S.Tsur);
        try
            so = sim(in);
        catch err
            yaz('  %s %d°/%.2f/%.1f° HATA: %s\n', hz{h}, AC(j), RG(j), BA(j), extractBefore([err.message newline], newline));
            continue
        end
        xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
        sec = xs.Time > 0.5*q.dt*q.dec;
        r = rejim_sinifla(xs.Time(sec), rad2deg(X(sec,3)) - AC(j), ops);
        B.C(h,j) = r.sinif;  B.A(h,j) = r.A;  B.f(h,j) = r.f;
    end
    save(fullfile(kok, 'tarama_hiz.mat'), 'B');
    C = reshape(B.C(h,:), size(AC));  A = reshape(B.A(h,:), size(AC));
    sal = any(C >= 3 & A > 0.5, 3);
    kr = arrayfun(@(i) ilk(rgs, sal(i,:)), 1:numel(ac));
    yaz('  %-9s kritik r_gs (%s°): %s   (%.0f s)\n', hz{h}, num2str(ac), num2str(kr, '%6.2f'), toc);
end
fclose(fid);
close_system(mdl, 0);
end

function x = ilk(rgs, s)
i = find(s, 1);
if isempty(i), x = NaN; else, x = rgs(i); end
end
