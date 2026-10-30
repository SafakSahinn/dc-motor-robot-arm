function kopru_7a
% KOPRU_7A  Bu çalışmanın kol modeli (kol_benzetim.m, kol tarafına indirgenmiş, PID/P-PI)
% Ghaffari 2013 modeliyle (ghaffari2013.m) aynı şeyi hesaplıyor mu?
% Ghaffari parametreleri kol tarafına çevrilir, yerçekimi kapatılır, P-PI seçilir:
%   JM = Jm kr^2, JL = Jl, Ks = ks, cs = cs, r = delta, bM = cm kr^2, bL = cl,
%   KV = kv kr^2, KI = kr^2/Ti; kontrol sürekli (Ts = dt), sensörler ideal, Coulomb yok.
addpath(fileparts(fileparts(mfilename('fullpath'))));   % simulasyon/ (kol_benzetim, parametreler)
D = {
 'Şekil 7 (kalibre)'          'sekil7' {'cm',0,'cle',0,'cl',0,'xis',0.0135}  11.67  20
 'Şekil 8 (kalibre)'          'sekil8' {'cm',0,'cle',0,'cl',0,'xis',0.0135}  11.67  20
 'tabla, sürtünmesiz, kp 8,3' 'tabla'  {'Fcm',0,'Fcl',0}                      8.3   20
 'tabla, sürtünmesiz, kp 11,7' 'tabla' {'Fcm',0,'Fcl',0}                      11.7  20
};
fid = fopen('kopru_7a_log.txt','w');
yaz(fid, '%-28s | %-28s | %-28s\n', 'durum', 'ghaffari2013: f [Hz], A_thd, A_thl [der]', 'kol_benzetim (P-PI, g = 0)');
for i = 1:size(D,1)
    g = ghaffari_param(D{i,2});
    a = D{i,3};  for k = 1:2:numel(a), g.(a{k}) = a{k+1}; end
    g.cs = 2*g.xis*g.ks/g.wa;  g.T = 7;  g.Tan = 4;
    og = ghaffari2013(g, D{i,4}, D{i,5});

    p = parametreler('ideal');
    p.JM = g.Jm*g.kr^2;  p.JL = g.Jl;  p.Ks = g.ks;  p.cs = g.cs;  p.r = g.delta;
    p.bM = g.cm*g.kr^2;  p.bL = g.cl;  p.mgl = 0;  p.Fc = 0;  p.Fs = 0;  p.Tmax = Inf;
    p.kontrol = 'PPI';  p.KV = D{i,5}*g.kr^2;  p.KI = g.kr^2/g.Ti;
    p.dt = g.dt;  p.Ts = g.dt;  p.T = g.T;  p.Tan = g.Tan;  p.dec = g.dec;
    p.adim = -rad2deg(g.th0);                      % kol hedefin 0,5° üstünde (Ghaffari ile aynı)
    ok = kol_benzetim(p, 0, D{i,4});
    rg = sqrt(D{i,4}*p.KV/p.Ks);
    % aynı ölçütlerle: thd ve kol açısının genliği, thd'nin frekansı
    Ad = rad2deg(max(ok.delta)-min(ok.delta))/2;  Al = rad2deg(max(ok.th)-min(ok.th))/2;
    fk = frekans(ok.t, ok.delta);
    Agl = rad2deg(max(og.thl)-min(og.thl))/2;
    yaz(fid, '%-28s | %6.2f %8.3f %8.3f (r_gs %.2f) | %6.2f %8.3f %8.3f (r_gs %.2f)\n', D{i,1}, ...
        og.f_Hz, og.A_deg, Agl, og.rgs, fk, Ad, Al, rg);
end
fclose(fid);
end

function f = frekans(t, y)
y = y - mean(y);  s = find(y(1:end-1) < 0 & y(2:end) >= 0);
f = 0;  if numel(s) >= 3, f = (numel(s)-1)/(t(s(end)) - t(s(1))); end
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
