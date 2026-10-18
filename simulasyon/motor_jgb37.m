% MOTOR_JGB37  JGB37-520 12V 1:30 (direnc.net veri sayfası): durma 5 kg cm = 0.49 N m,
% nominal 3.5 kg cm = 0.34 N m @ 1 A. 37 mm motor, rotor eylemsizliği tahmini 4e-6 kg m^2
% (JGA25 tahmininin ~2.7 katı). Tork yeterliliği ve boşluk salınımı korunuyor mu?
ac = [0 15 30 60 90];
for Jrot = [1.5e-6 4e-6]
  for wc = [35 45]
    p = parametreler('gercekci');  p.N = 30;  p.JM = Jrot*p.N^2;  p.Tmax = 0.49;
    mRod = 0.020; L = 0.15; mTip = 0.020;
    p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);  p.r = deg2rad(1.5);
    p.qM = 2*pi/(11*4*p.N);
    wr = sqrt(p.Ks/(p.JM*p.JL/(p.JM+p.JL)));
    o = kol_benzetim(p, ac, wc*ones(size(ac)));
    fprintf('\nJrot=%.1e  JM/JL=%.1f  w_rez=%.0f  wc=%d (r_s=%.2f)\n', Jrot, p.JM/p.JL, wr, wc, wc/wr);
    fprintf('%6s %9s %9s %8s %6s\n','aci','tepe[Nm]','RMS[Nm]','A[der]','sinif');
    for j = 1:numel(ac)
      u = o.u(:,j); fprintf('%6g %9.3f %9.3f %8.2f %6d\n', ac(j), max(abs(u)), rms(u), o.A_deg(j), o.sinif(j));
    end
  end
end
