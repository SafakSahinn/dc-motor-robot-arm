function tarama_5b(duzeyler)
% TARAMA_5B  Motorun elektrik tarafı salınım sınırını kaydırıyor mu? D düzeneği, P-PI.
% Her açıda kritik r_gs (herhangi bir başlangıç sapmasında kalıcı çevrim / düzensiz salınım, sınıf >= 3).
% Varyantlar:
%   ideal      kol_benzetim, ideal tork kaynağı, Tmax 0.49 N m (şimdiye kadarki model)
%   ideal_lim  kol_benzetim, ideal tork kaynağı, Tmax = DRV8874 akım sınırının tork eşdeğeri (0.43 N m)
%   mot1..3    Simscape elektrik motoru: 1 gerilim modu, 2 zıt EMK kompanzasyonu, 3 akım döngüsü
% duzeyler: {'ideal'} ve/veya {'gercekci'} (sensör düzeyi; gerçekçi = dogrula_3 ayarı).
% Çıktı: tarama_5b_<duzey>.mat (her varyanttan sonra yazılır), tarama_5b_log.txt.
if nargin < 1, duzeyler = {'ideal', 'gercekci'}; end
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
warning('off', 'all');
ac = [30 60 90];  rgs = 0.70:0.05:1.40;  bas = [0.2 1 5];
ops = struct('A_min',0.05,'A_max',30,'T_at',0.3);
L = load(fullfile(kok, 'referans.mat'));  p0 = L.R.p;           % D, P-PI, T = 8 s
mdl = 'sm_motor_model';
sm_model_kur(mdl, 'elektrik');  load_system(fullfile(kok, [mdl '.slx']));
fid = fopen(fullfile(kok, 'tarama_5b_log.txt'), 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
var = {'ideal', 'ideal_lim', 'mot1', 'mot2', 'mot3'};
[AC, RG, BA] = ndgrid(ac, rgs, bas);
for d = 1:numel(duzeyler)
    duz = duzeyler{d};
    dosya = fullfile(kok, sprintf('tarama_5b_%s.mat', duz));
    B = struct('ac', ac, 'rgs', rgs, 'bas', bas, 'var', {var}, 'C', NaN(numel(var), numel(AC)), ...
               'A', NaN(numel(var), numel(AC)), 'f', NaN(numel(var), numel(AC)));
    yaz('=== Tarama 5b, %s sensör (%s)\n', duz, datestr(now, 'yyyy-mm-dd HH:MM'));
    for v = 1:numel(var)
        tic;
        for j = 1:numel(AC)
            q = p0;  q.adim = BA(j);
            if strcmp(duz, 'gercekci')
                q.Ts = 1e-3;  q.qL = 2*pi/4096;  q.gL = 1;
                q.qM = 2*pi/(11*4*q.N);  q.fv = 50;
                q.Fc = 0.04;  q.Fs = 0.06;  q.olu = 0.03*q.Tmax;
            end
            kp = RG(j)^2*q.Ks/q.KV;
            if v <= 2
                if v == 2, q.Tmax = (2/2.3)*q.Tmax; end
                o = kol_benzetim(q, AC(j), kp);
                t = o.t;  th = o.th;
            else
                q.mot = v - 2;  S = sim_param(q, AC(j), kp);
                in = Simulink.SimulationInput(mdl);
                in = in.setVariable('S', S).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
                       .setVariable('T', q.T).setVariable('dec', q.dec).setVariable('gecis', 1e-6) ...
                       .setVariable('Tsur', S.Tsur);
                try
                    so = sim(in);
                    xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
                    sec = xs.Time > 0.5*q.dt*q.dec;  t = xs.Time(sec);  th = X(sec, 3);
                catch err
                    yaz('  %s %d°/%.2f/%.1f° HATA: %s\n', var{v}, AC(j), RG(j), BA(j), extractBefore([err.message newline], newline));
                    continue
                end
            end
            r = rejim_sinifla(t, rad2deg(th) - AC(j), ops);
            B.C(v,j) = r.sinif;  B.A(v,j) = r.A;  B.f(v,j) = r.f;
        end
        save(dosya, 'B');
        C = reshape(B.C(v,:), size(AC));                    % açı × r_gs × başlangıç
        sal = any(C >= 3, 3);
        kr = arrayfun(@(i) ilk(rgs, sal(i,:)), 1:numel(ac));
        yaz('  %-9s kritik r_gs (%s°): %s   (%.0f s)\n', var{v}, num2str(ac), num2str(kr, '%6.2f'), toc);
    end
end
fclose(fid);
close_system(mdl, 0);
end

function x = ilk(rgs, s)
i = find(s, 1);
if isempty(i), x = NaN; else, x = rgs(i); end
end
