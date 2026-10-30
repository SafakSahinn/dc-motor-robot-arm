function kopru_7b
% KOPRU_7B  Bu çalışmanın düzeneği (JGB37-520 1:30, hafif kol) yerçekimsiz, ideal sensörle:
%  (1) P-PI ile r_gs taraması: rejim sınırları Ghaffari'nin eşikleriyle (0,4 / 1) ve tam DF ile
%      uyumlu mu? Yalnız kp*KV çarpımı mı belirliyor (hız döngüsü bant genişliği iki değerde)?
%  (2) PID ile rho taraması: r_gs = rho (JM+JL)/sqrt(JM JL) eşlemesi rejim sınırlarını taşıyor mu?
% Her nokta üç başlangıç sapmasıyla koşulur ve rejim_sinifla ile sınıflanır (A_min 0,05°).
% Tabloda A: kol açısının genliği (benzetim); DF Ad: DF'nin öngördüğü fark açısı (thd) genliği.
addpath(fileparts(fileparts(mfilename('fullpath'))));
rgs  = 0.1:0.1:1.6;
rho  = 0.05:0.05:0.60;
ikiR = [1.5 3 5];                                  % toplam boşluk [der] (kaplin ayarları)
bas  = [0.1 1 5];                                  % başlangıç sapması [der]
ad   = {'denge','sönümlü','zorlanmış','ÇEVRİM','KARARSIZ','düzensiz'};
fid = fopen('kopru_7b_log.txt','w');
p0 = jgb37(20, 3);
k = (p0.JM+p0.JL)/sqrt(p0.JM*p0.JL);
wa = sqrt(p0.Ks/p0.JL);  wrez = sqrt(p0.Ks*(p0.JM+p0.JL)/(p0.JM*p0.JL));
yaz(fid, 'JGB37 düzeneği (kol tarafı): JM = %.2e, JL = %.2e kg m^2 (R = JL/JM = %.3f), Ks = %g N m/rad\n', p0.JM, p0.JL, p0.JL/p0.JM, p0.Ks);
yaz(fid, 'f_a = %.1f Hz (kol karşı-rezonansı), f_rez = %.1f Hz; r_gs = %.2f * rho\n\n', wa/2/pi, wrez/2/pi, k);
S = struct();
% ---------- (1) P-PI ----------
for wv = [1 5]                                     % hız döngüsü bant genişliği / wa
    for b = ikiR
        p = jgb37(20, b);  p.kontrol = 'PPI';
        p.KV = wv*wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;     % PI sıfırı 0,05 wa (Ghaffari'de 0,013-0,07 wa)
        kp = rgs.^2*p.Ks/p.KV;
        [C, F, A] = tara(p, kp, bas);
        df = ghaffari_df(ghaffari_esdeger(p), kp, p.KV*ones(size(kp)));
        S.(sprintf('ppi_w%d_b%g', wv, 10*b)) = struct('C',C,'F',F,'A',A,'df',df);
        yaz(fid, 'P-PI, hız döngüsü %g wa, 2r = %g°\n', wv, b);
        rapor(fid, 'r_gs', rgs, C, F, A, df, ad);
    end
end
% ---------- (2) PID ----------
for b = ikiR
    p = jgb37(20, b);
    wc = rho*wrez;
    [C, F, A] = tara(p, wc, bas);
    S.(sprintf('pid_b%g', 10*b)) = struct('C',C,'F',F,'A',A);
    yaz(fid, 'PID, 2r = %g°  (r_gs = %.2f rho)\n', b, k);
    rapor(fid, 'rho', rho, C, F, A, [], ad);
end
save('kopru_7b.mat', 'S', 'rgs', 'rho', 'ikiR', 'bas', 'k');
fclose(fid);
end

function p = jgb37(mTip_g, ikiR_der)
% Dengeli listedeki düzenek: JGB37-520 1:30 (rotor eylemsizliği tahmini 4e-6 kg m^2),
% 20 g / 150 mm alüminyum çubuk + uç kütlesi; Ks ve sönüm parametreler.m'deki tahminler.
p = parametreler('ideal');
p.N = 30;  p.JM = 4e-6*p.N^2;  p.Tmax = Inf;      % tork sınırı 7c'de
mRod = 0.020;  L = 0.15;  m = mTip_g/1000;
p.JL = mRod*L^2/3 + m*L^2;  p.mgl = 0;             % yerçekimi kapalı (Ghaffari ile karşılaştırma)
p.r = deg2rad(ikiR_der/2);
p.dt = 1e-4;  p.Ts = p.dt;  p.T = 6;  p.Tan = p.T;  p.dec = 5;
end

function g = ghaffari_esdeger(p)
% Kol tarafı P-PI modeli = Ghaffari modeli, kr = 1: Jm = JM, Jle = JL, kse = Ks, kv = KV, 1/Ti = KI.
g.Jm = p.JM;  g.Jle = p.JL;  g.kse = p.Ks;  g.cm = p.bM;  g.cle = p.bL;
g.Ti = 1/p.KI;  g.wa = sqrt(p.Ks/p.JL);  g.fa = g.wa/2/pi;  g.delta = p.r;
end

function [C, F, A] = tara(p, g, bas)
% Her kazanç ve başlangıç sapması için rejim sınıfı, frekans, genlik (kol açısı, der).
n = numel(g);  C = zeros(numel(bas), n);  F = C;  A = C;
opt = struct('A_min',0.05,'A_max',30,'T_at',0.3);
for i = 1:numel(bas)
    p.adim = bas(i);
    o = kol_benzetim(p, zeros(1,n), g);
    r = rejim_sinifla(o.t, rad2deg(o.th), opt);
    C(i,:) = r.sinif;  F(i,:) = r.f;  A(i,:) = r.A;
end
end

function rapor(fid, xad, x, C, F, A, df, ad)
yaz(fid, '%6s | %-44s | %7s %7s', xad, 'sınıf (başlangıç 0,1° / 1° / 5°)', 'f [Hz]', 'A [der]');
if ~isempty(df), yaz(fid, ' | %7s %7s', 'DF f', 'DF Ad'); end
yaz(fid, '\n');
for j = 1:numel(x)
    s = strjoin(ad(C(:,j)+1), ' / ');
    [~, i] = max(A(:,j));
    yaz(fid, '%6.2f | %-44s | %7.2f %7.3f', x(j), s, F(i,j), A(i,j));
    if ~isempty(df)
        fd = df.f_df(j);  ad_ = df.A_deg(j);
        yaz(fid, ' | %7.2f %7.3f', fd, ad_);
    end
    yaz(fid, '\n');
end
yaz(fid, '\n');
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
