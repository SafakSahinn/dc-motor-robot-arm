function R = referans_uret()
% REFERANS_URET  Simulink modelinin birebir doğrulanacağı referans koşuları üretir.
% Kaynak: kol_benzetim.m (vektörize RK4), D düzeneği, P-PI kaskat, ideal sensör.
% Hücreler, modelin her parçasını çalıştıracak şekilde seçildi:
%   1) 90°, r_gs 1.20, başlangıç 1°                -> kalıcı çevrim (tork sınırı açık)
%   2) 60°, r_gs 0.50, başlangıç 1°                -> denge (kontrol hücresi)
%   3) 30°, r_gs 0.80, başlangıç 0.2° + sarsıntı   -> DF ile uyuşmayan hücre; bozucu girişi sınanır
%   4,5) 90°, r_gs 0.95, tork sınırsız, 0.2° ve 5° -> iki kararlılık adayı
% Çıktı: referans.mat (t, th, delta, tau_s, u ve rejim_sinifla sonucu, her hücre için).
kok = fileparts(mfilename('fullpath'));
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));

hucre = struct('ac',   {90,   60,   30,   90,   90}, ...
               'rgs',  {1.20, 0.50, 0.80, 0.95, 0.95}, ...
               'bas',  {1,    1,    0.2,  0.2,  5}, ...
               'Tmax', {[],   [],   [],   Inf,  Inf}, ...
               'dA',   {0,    0,    0.10, 0,    0});
p = ayar_D();
R = struct('p', p, 'hucre', hucre, 'kos', []);
for k = 1:numel(hucre)
    h = hucre(k);
    q = p;  q.adim = h.bas;
    if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
    if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end   % kok_neden_1b sarsıntısı
    kp = h.rgs^2*q.Ks/q.KV;
    o = kol_benzetim(q, h.ac, kp);
    r = rejim_sinifla(o.t, rad2deg(o.th) - h.ac, struct('A_min',0.05,'A_max',30,'T_at',0.3));
    R.kos(k).kp = kp;
    R.kos(k).t = o.t;  R.kos(k).th = o.th;  R.kos(k).delta = o.delta;
    R.kos(k).tau_s = o.tau_s;  R.kos(k).u = o.u;
    R.kos(k).sinif = r.sinif;  R.kos(k).A = r.A;  R.kos(k).f = r.f;
    fprintf('hucre %d: %3d deg  r_gs %.2f  bas %.1f deg -> sinif %d  A %.3f deg  f %.2f Hz\n', ...
            k, h.ac, h.rgs, h.bas, r.sinif, r.A, r.f);
end
save(fullfile(kok, 'referans.mat'), 'R');
end

function p = ayar_D()
% yercekimli_karsilastirma.m / ayar ile aynı: D düzeneği, P-PI, wa = sqrt(Ks/JL).
p = secenek_duzenek('D');
wa = sqrt(p.Ks/p.JL);
p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
end
