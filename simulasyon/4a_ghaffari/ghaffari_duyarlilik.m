function ghaffari_duyarlilik
% GHAFFARI_DUYARLILIK  Şekil 7/8 ile bu modelin farkını hangi varsayım açıklıyor?
% Her satırda tek bir şey değişir; frekans ve thd genliği raporlanır.
% Makaleden okunan: Şekil 7 ~10,3 Hz / 1,05 der; Şekil 8 ~2,4 Hz / 0,10 der.
kp0 = 11.67;  kv0 = 20;
fid = fopen('duyarlilik_log.txt','w');
yaz(fid, '%-9s %-34s %7s %8s %9s\n', 'durum', 'değişiklik', 'r_gs', 'f [Hz]', 'A [der]');
for d = {'sekil7','sekil8'}
    durum = d{1};
    % 1) taban; 2) uzun süre (geçici rejim); 3) son 1 s ile önceki 1 s aynı mı
    kos(fid, durum, 'taban (T=7 s, son 4 s)', ghaffari_param(durum), kp0, kv0);
    p = ghaffari_param(durum); p.T = 20; p.Tan = 4;
    kos(fid, durum, 'T=20 s, son 4 s', p, kp0, kv0);
    % 4) başlıktaki r_gs: kv sabit, kp ölçeklenir
    p = ghaffari_param(durum);
    rgs_b = 0.9;  if strcmp(durum,'sekil8'), rgs_b = 0.17; end
    kpb = rgs_b^2*p.kse/kv0;
    kos(fid, durum, sprintf('başlık r_gs=%.2f (kp=%.2f)', rgs_b, kpb), p, kpb, kv0);
    kvb = rgs_b^2*p.kse/kp0;
    kos(fid, durum, sprintf('başlık r_gs=%.2f (kv=%.2f)', rgs_b, kvb), p, kp0, kvb);
    % 5) sönüm
    for xi = [0 0.1]
        p = ghaffari_param(durum); p.xis = xi; p.cs = 2*xi*p.ks/p.wa;
        kos(fid, durum, sprintf('temas sönümü xi=%g', xi), p, kp0, kv0);
    end
    p = ghaffari_param(durum); p.cm = 0; p.cle = 0; p.cl = 0;
    kos(fid, durum, 'viskoz sürtünme yok', p, kp0, kv0);
    p.xis = 0; p.cs = 0;
    kos(fid, durum, 'viskoz yok + temas sönümü yok', p, kp0, kv0);
    % 6) başlangıç sapması
    for a = [0.05 0.2 1 2 5]
        p = ghaffari_param(durum); p.th0 = deg2rad(a);
        kos(fid, durum, sprintf('başlangıç sapması %g der', a), p, kp0, kv0);
    end
    % 7) Ti
    p = ghaffari_param(durum); p.Ti = 1e3;
    kos(fid, durum, 'integral yok (Ti -> sonsuz)', p, kp0, kv0);
end
fclose(fid);
end

function kos(fid, durum, ad, p, kp, kv)
o = ghaffari2013(p, kp, kv);
yaz(fid, '%-9s %-34s %7.3f %8.2f %9.3f\n', durum, ad, o.rgs, o.f_Hz, o.A_deg);
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
