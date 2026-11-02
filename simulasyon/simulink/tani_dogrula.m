function tani_dogrula(takimlar)
% TANI_DOGRULA  Adım 4.3, Adım 4b: tanılanan parametre takımı asıl soruyu doğru öngörüyor mu?
% "Gerçek" tesis: gerçekçi düzey (tarama_hiz / tarama_cs ile aynı: F_c 0.04, F_s 0.06, gözlemci).
% Tanılanan takım: 4.3 adımlarının gerçekçi koşu ortalamaları (README):
%   J_M -%0.21, b_M +%1.35, F_c 0.0396 (Adım 1, boşta); K_s -%0.24 (Adım 2); c_s 0.0195 (Adım 2b, kilitli);
%   r -%0.11 (Adım 3); mgl +%0.01 (Adım 4a). K_m (+%0.02) ve R_a (<%0.1) modelde sim_param içinde
%   veri sayfasından hesaplanıyor ve kontrolcü de kullanıyor; hata ihmal edilebilir olduğundan değiştirilmedi.
%   Ölçülmeyenler: J_L, b_L nominal (geometri); F_s iki varsayımla: 'tanili_FsFc' F_s = F_c (Stribeck tepesi
%   yok, saf varsayım), 'tanili_Fs06' F_s = 0.06 (doğru değer, F_s'nin etkisini ayırmak için).
% Karşılaştırma (sensörler, kontrolcü ve kestirici aynı; yalnız tesis parametreleri farklı):
%   1) kritik r_gs (30/60/90°): tarama_cs ile aynı hızlı tarama (aşağıdan yukarı, ilk salınanda dur)
%   2) sınırın üstünde, 90°: salınım genliği ve frekansı (r_gs 1.45, 1.60; başlangıç sapması 1°)
% takimlar: hücre dizisi, varsayılan {'gercek', 'tanili_FsFc', 'tanili_Fs06'}
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
if nargin < 1, takimlar = {'gercek', 'tanili_FsFc', 'tanili_Fs06'}; end
ac = [30 60 90];  bas = [0.2 1 5];
rg0 = {0.80:0.05:1.45, 1.00:0.05:1.60, 1.00:0.05:1.60};
rgc = [1.45 1.60];
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'tani_dogrula_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== Adım 4.3 Adım 4b: tanılanan takımla öngörü, mod 1, gerçekçi sensör, gözlemci (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
for h = 1:numel(takimlar)
    tic;  kr = NaN(1, numel(ac));  alt = false(1, numel(ac));
    for a = 1:numel(ac)
        rg = rg0{a};
        for k = 1:numel(rg)
            sal = false;
            for b = 1:numel(bas)
                r = kos(mdl, p0, takimlar{h}, ac(a), rg(k), bas(b), ops);
                if r.sinif >= 3 && r.A > 0.5, sal = true;  break, end
            end
            if sal, kr(a) = rg(k);  alt(a) = (k == 1);  break, end
        end
    end
    s = arrayfun(@(a) sprintf('%s%.2f', repmat('<=', 1, alt(a)), kr(a)), 1:numel(ac), 'uni', 0);
    yaz('  %-12s kritik r_gs (%s°): %s\n', takimlar{h}, num2str(ac), strjoin(s, '  '));
    for g = rgc
        r = kos(mdl, p0, takimlar{h}, 90, g, 1, ops);
        yaz('  %-12s 90°, r_gs %.2f: sınıf %d, A %.3f°, f %.2f Hz\n', takimlar{h}, g, r.sinif, r.A, r.f);
    end
    yaz('  %-12s (%.0f s)\n', takimlar{h}, toc);
end
fclose(fid);
close_system(mdl, 0);
end

function r = kos(mdl, p0, takim, ac, rg, bas, ops)
q = p0;  q.adim = bas;  q.mot = 1;
q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;  q.qM = 2*pi/(11*4*q.N);  q.fv = 50;  q.hiz = 'gozlemci';
q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;
KV = q.KV;
if startsWith(takim, 'tanili')
    q.JM = q.JM*(1 - 0.0021);  q.bM = q.bM*1.0135;  q.Fc = 0.0396;
    q.Ks = q.Ks*(1 - 0.0024);  q.cs = 0.0195;  q.r = q.r*(1 - 0.0011);  q.mgl = q.mgl*1.0001;
    if strcmp(takim, 'tanili_FsFc'), q.Fs = q.Fc; end
end
% kazanç gerçek K_s ve KV ile (kontrolcü aynı; r_gs ekseni takımdan bağımsız)
S = sim_param(q, ac, rg^2*p0.Ks/KV);
in = Simulink.SimulationInput(mdl);
in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
       .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
       .setVariable('Tsur', S.Tsur);
try
    so = sim(in);
catch
    r = struct('sinif', NaN, 'A', NaN, 'f', NaN);  return
end
xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
sec = xs.Time > 0.5*q.dt*q.dec;
r = rejim_sinifla(xs.Time(sec), rad2deg(X(sec,3)) - ac, ops);
end
