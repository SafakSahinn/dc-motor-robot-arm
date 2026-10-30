function tork_siniri(Tm)
% TORK_SINIRI  Döner tablada sürtünmeli benzetimin yüksek kazançta deneyden (~13 Hz)
% ayrılmasını motor tork sınırı açıklıyor mu? Tmax taranır; sürtünme makaledeki gibi.
% Her kazanç iki başlangıç sapmasıyla (1°, 3°) koşulur; frekans salınım bulunanların en büyüğü.
kpA = [10 11.7 13.3 15 16.7 18.3];  kvA = 20*ones(size(kpA));
kvB = [17.5 20 25 30 40 50];         kpB = 11.6*ones(size(kvB));
feA = [0 10.94 12.02 12.50 13.04 13.06];  feB = [0 10.95 11.49 12.48 12.79 12.68];   % deney (veri_sekil11.csv)
if nargin < 1, Tm = [Inf 640 320 160 80 40 20 10 5]; end
fid = fopen('tork_siniri_log.txt','w');
yaz(fid, 'Deney 11a (kp %s): %s\n', num2str(kpA), num2str(feA,'%7.2f'));
yaz(fid, 'Deney 11b (kv %s): %s\n\n', num2str(kvB), num2str(feB,'%7.2f'));
R = struct();
for i = 1:numel(Tm)
    p = ghaffari_param('tabla');  p.Tmax = Tm(i);
    [fA, aA, uA] = kos(p, kpA, kvA);  [fB, aB, uB] = kos(p, kpB, kvB);
    eA = hata(fA, feA);  eB = hata(fB, feB);
    yaz(fid, 'Tmax = %g N m\n  11a f: %s   A: %s   |tm|maks: %s  hata %.1f%%\n  11b f: %s   A: %s   |tm|maks: %s  hata %.1f%%\n', Tm(i), ...
        num2str(fA,'%7.2f'), num2str(aA,'%7.2f'), num2str(uA,'%6.1f'), eA, num2str(fB,'%7.2f'), num2str(aB,'%7.2f'), num2str(uB,'%6.1f'), eB);
    R(i).Tmax = Tm(i); R(i).fA = fA; R(i).fB = fB; R(i).aA = aA; R(i).aB = aB; R(i).eA = eA; R(i).eB = eB;
end
fclose(fid);
save('tork_siniri.mat', 'R', 'kpA', 'kvB', 'feA', 'feB');
end

function [f, A, U] = kos(p, kp, kv)
f = zeros(1,numel(kp)); A = f; U = f;
for a = [1 3]
    p.th0 = deg2rad(a);
    o = ghaffari2013(p, kp, kv);
    ok = o.A_deg > 0.1*rad2deg(p.delta);
    f = max(f, o.f_Hz.*ok);  A = max(A, o.A_deg.*ok);
    U = max(U, max(abs(kv.*(p.kr*o.wc - o.wm_kr*p.kr))));   % P kısmının tepe değeri (yaklaşık talep)
end
end

function e = hata(f, fe)
m = fe > 0;  e = mean(abs(f(m)-fe(m))./fe(m))*100;
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
