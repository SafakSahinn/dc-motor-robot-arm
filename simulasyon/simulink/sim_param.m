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
end
