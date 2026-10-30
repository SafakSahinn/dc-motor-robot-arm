function p = secenek_duzenek(ad)
% SECENEK_DUZENEK  Düzenek seçenekleri (secenekler_sonuclar.md): 'A', 'B1', 'B2', 'C', 'D'.
% Kol tarafı büyüklükler; yerçekimi açık; ideal sensör ve sürekli kontrol varsayılan.
p = parametreler('ideal');
p.N = 30;  Jrot = 4e-6;  p.Tmax = 0.49;
mRod = 0.020;  L = 0.15;  mTip = 0.020;
p.JL  = mRod*L^2/3 + mTip*L^2;
p.mgl = 9.81*(mRod*L/2 + mTip*L);
p.JM  = Jrot*p.N^2;
switch ad
    case 'B1', p.JL = 1*p.JM;                     % dengelenmiş ek eylemsizlik: mgl değişmez
    case 'B2', p.JL = 2*p.JM;
    case 'C',  p.N = 10;  p.JM = Jrot*p.N^2;  p.Tmax = 0.49/3;
    case 'D',  mTip = (p.JM - mRod*L^2/3)/L^2;   % J_L = J_M
               p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);
end
p.r = deg2rad(1.5);
p.dt = 1e-4;  p.Ts = p.dt;  p.T = 8;  p.Tan = p.T;  p.dec = 5;
end
