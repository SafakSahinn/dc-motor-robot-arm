function S = sim_param(p, theta0_deg, wc)
% SIM_PARAM  kol_benzetim parametre yapısını (p) Simulink modelinin sayısal S yapısına çevirir.
% Argümanlar kol_benzetim(p, theta0_deg, wc) ile aynı; tek hücre (skaler açı ve kazanç).
% S yalnız sayısal alanlar içerir (MATLAB Function blokları metin alanı kabul etmez).
S.r = p.r;  S.Ks = p.Ks;  S.cs = p.cs;
S.JM = p.JM;  S.JL = p.JL;  S.bM = p.bM;  S.bL = p.bL;  S.mgl = p.mgl;
S.Fc = p.Fc;  S.Fs = p.Fs;  S.vs = p.vs;  S.veps = p.veps;
S.Tmax = p.Tmax;  S.olu = p.olu;  S.Ts = p.Ts;
S.qL = p.qL;  S.qM = p.qM;
S.fv_inf = double(isinf(p.fv));
if isinf(p.fv), S.aV = 1; else, S.aV = 1 - exp(-2*pi*p.fv*p.Ts); end
S.motorD = double(strcmp(p.Dkaynak, 'motor'));
S.gL = 0;  if isfield(p,'gL'), S.gL = p.gL; end
if S.gL > 20, error('gL en fazla 20 (gecikme tamponu boyu)'); end

S.ref = deg2rad(theta0_deg);
S.ppi = double(isfield(p,'kontrol') && strcmp(p.kontrol,'PPI'));
J = p.JM + p.JL;
S.Kp = J*wc^2;  S.Kd = 2*0.7*J*wc;  S.Ki = S.Kp*wc/4;      % PID (S.ppi = 0)
S.kp = wc;  S.KV = 0;  S.KI = 0;                          % P-PI: wc konum kazancı kp olarak okunur
if S.ppi, S.KV = p.KV;  S.KI = p.KI; end

S.dA = 0;  S.df = 0;  S.dT = Inf;
if isfield(p,'dA'), S.dA = p.dA;  S.df = p.df; end
if isfield(p,'dT'), S.dT = p.dT; end

% Başlangıç durumu: kol hedefin p.adim derece altında, durgun, dişli boşluğun ortasında
th0 = S.ref - deg2rad(p.adim);
S.x0 = [th0; 0; th0; 0];
S.z0 = 0;
if isfield(p,'x0'), S.x0 = p.x0(:);  S.z0 = p.z0; end
% Elektrik motoru (sm_model_kur(..., 'elektrik')). p.mot: 1 gerilim, 2 zıt EMK kompanzasyonu, 3 akım döngüsü.
% Kol tarafına indirgenmiş eşdeğer ideal motor (Kt = Ke = Km), JGB37-520 12 V 1:30 veri sayfasından:
%   Km = Vs / w0 (w0 = 333 rpm çıkışta boşta hız), Ra = Km Vs / T_durma (T_durma = 0.49 N m).
%   Böylece durma torku, boşta hız ve zıt EMK sönümü Km^2/Ra = T_durma/w0 veri sayfasıyla aynı. Akım ölçeği
%   veri sayfasından farklı (durma 1.42 A, gerçekte 2.3 A; fark dişli verimi): DRV8874'ün 2 A sınırı tork
%   eşdeğeriyle ölçeklenir, Ilim = (2/2.3) Vs/Ra (yani tork sınırı 0.87 x 0.49 = 0.43 N m).
%   La tahmini 2.5 mH (elektrik zaman sabiti ~0.3 ms). Akım PI: kutup-sıfır sadeleştirme, bant 500 Hz.
S.mot = 0;  S.Vs = 12;  S.Km = 1;  S.Ra = 1;  S.La = 1e-3;  S.Ilim = Inf;  S.Kpi = 0;  S.Kii = 0;  S.Tsur = p.dt;
if isfield(p,'mot') && p.mot > 0
    S.mot = p.mot;
    w0 = 333*2*pi/60;  Td = 0.49;
    S.Km = S.Vs/w0;  S.Ra = S.Km*S.Vs/Td;  S.La = 2.5e-3;
    S.Ilim = (2/2.3)*S.Vs/S.Ra;
    if isfield(p,'Ilim'), S.Ilim = p.Ilim; end
    wi = 2*pi*500;  S.Kpi = S.La*wi;  S.Kii = S.Ra*wi;
    S.Tsur = 1e-4;
end
% blok_ayrik'in Unit Delay başlangıcı: [tampon(21); vhat; yprev; z] (blok_sensor'un ilk çağrısıyla aynı)
olc = @(x, q) (q > 0)*q*floor(x/max(q,eps)) + (q == 0)*x;
if S.motorD > 0, yp = olc(S.x0(1), S.qM); else, yp = olc(S.x0(3), S.qL); end
S.st0 = [olc(S.x0(3), S.qL)*ones(21,1); 0; yp; S.z0];
end
