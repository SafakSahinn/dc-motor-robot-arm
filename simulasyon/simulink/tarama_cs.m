function tarama_cs(csl, duzey)
% TARAMA_CS  Kritik r_gs öngörüsü dişli sönümü c_s'ye ne kadar duyarlı? (4.3, Adım 2 sonrası)
% c_s yarı statik taramadan ölçülemiyor (README 4.3 Adım 2); bu yüzden varsayım olarak kalıyor.
% Kurulum tarama_hiz ile aynı: sm_motor_model, mod 1, P-PI, gözlemci kestiricisi.
% csl:   c_s değerleri [N m s/rad] (varsayılan [0 0.01 0.02 0.04]; referans 0.02).
% duzey: 'gercekci' (varsayılan, dogrula_3 ayarı) ya da 'ideal' (sürekli ölçüm, gerçek hız).
% Sınır: herhangi bir başlangıç sapmasında sınıf >= 3 ve A > 0.5° (README 5b).
% Hızlandırma: her açıda r_gs aşağıdan yukarı taranır; ilk salınan r_gs'de durulur (tarama_hiz'in
% 'ilk' tanımıyla aynı sonuç). Bir r_gs'de de ilk salınan başlangıç sapmasında durulur.
% Çıktı: tarama_cs_<duzey>.mat, tarama_cs_log.txt.
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
if nargin < 1 || isempty(csl), csl = [0 0.01 0.02 0.04]; end
if nargin < 2, duzey = 'gercekci'; end
ac = [30 60 90];  bas = [0.2 1 5];
if strcmp(duzey, 'ideal')
    rg0 = {0.70:0.05:1.40, 0.80:0.05:1.40, 0.80:0.05:1.40};
else
    rg0 = {0.80:0.05:1.45, 1.00:0.05:1.60, 1.00:0.05:1.60};
end
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'tarama_cs_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== c_s duyarlılığı, mod 1, %s sensör%s (%s), referans c_s = %.3g\n', ...
    duzey, repmat(', gözlemci', 1, strcmp(duzey, 'gercekci')), datestr(now, 'yyyy-mm-dd HH:MM'), p0.cs);
B = struct('ac', ac, 'bas', bas, 'cs', csl, 'duzey', duzey, 'kr', NaN(numel(csl), numel(ac)), ...
           'alt', false(numel(csl), numel(ac)), 'kayit', {{}});
for c = 1:numel(csl)
    tic;  ns = 0;
    for a = 1:numel(ac)
        rg = rg0{a};
        for k = 1:numel(rg)
            sal = false;
            for b = 1:numel(bas)
                q = p0;  q.adim = bas(b);  q.mot = 1;  q.cs = csl(c);
                if strcmp(duzey, 'gercekci')            % ideal: referans.mat'taki p olduğu gibi
                    q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
                    q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;  q.hiz = 'gozlemci';
                end
                S = sim_param(q, ac(a), rg(k)^2*q.Ks/q.KV);
                in = Simulink.SimulationInput(mdl);
                in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
                       .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
                       .setVariable('Tsur', S.Tsur);
                try
                    so = sim(in);  ns = ns + 1;
                catch err
                    yaz('  c_s %.3g %d°/%.2f/%.1f° HATA: %s\n', csl(c), ac(a), rg(k), bas(b), ...
                        extractBefore([err.message newline], newline));
                    continue
                end
                xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
                sec = xs.Time > 0.5*q.dt*q.dec;
                r = rejim_sinifla(xs.Time(sec), rad2deg(X(sec,3)) - ac(a), ops);
                B.kayit(end+1,:) = {csl(c), ac(a), rg(k), bas(b), r.sinif, r.A, r.f};
                if r.sinif >= 3 && r.A > 0.5, sal = true;  break, end
            end
            if sal
                B.kr(c,a) = rg(k);  B.alt(c,a) = (k == 1);
                break
            end
        end
    end
    save(fullfile(kok, sprintf('tarama_cs_%s.mat', duzey)), 'B');
    s = arrayfun(@(a) sprintf('%s%.2f', repmat('<=', 1, B.alt(c,a)), B.kr(c,a)), 1:numel(ac), 'uni', 0);
    yaz('  c_s %-5.3g kritik r_gs (%s°): %s   (%d koşu, %.0f s)\n', csl(c), num2str(ac), ...
        strjoin(s, '  '), ns, toc);
end
fclose(fid);
close_system(mdl, 0);
end
