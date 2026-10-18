% MOTOR_KONTROL  Seçilecek motor yeterli mi? Gerçekçi model, hedef çalışma bölgesi.
% JGA25-370 1:34 için tedarikçi verisi: durma torku ~4.2 kg cm = 0.41 N m (12 V).
% Sürekli güvenli tork kabaca durma torkunun 1/4-1/3'ü: ~0.10-0.14 N m.
% Rapor: tepe tork, RMS tork (ısınma), doyumda geçen süre oranı.
ac = [0 15 30 60 90];
durum = { 'uc 50 g, 2r 1.5 der', 50, 1.5;
          'uc 50 g, 2r 3 der',   50, 3;
          'uc 20 g, 2r 3 der',   20, 3;
          'uc 0 g, 2r 3 der',     0, 3 };
for wc = [35 45]
  for d = 1:size(durum,1)
    p = parametreler('gercekci');  p.Tmax = 0.41;  p.adim = 5;
    mRod = 0.020; L = 0.15; mTip = durum{d,2}/1000;
    p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);
    p.r  = deg2rad(durum{d,3}/2);
    o = kol_benzetim(p, ac, wc*ones(size(ac)));
    fprintf('\nwc=%d  %s  (mgl = %.3f N m)\n', wc, durum{d,1}, p.mgl);
    fprintf('%6s %9s %9s %9s %8s %6s\n','aci','tepe[Nm]','RMS[Nm]','doyum%','A[der]','sinif');
    for j = 1:numel(ac)
        u = o.u(:,j);
        fprintf('%6g %9.3f %9.3f %9.1f %8.2f %6d\n', ac(j), max(abs(u)), rms(u), 100*mean(abs(u) >= 0.999*p.Tmax), o.A_deg(j), o.sinif(j));
    end
  end
end
