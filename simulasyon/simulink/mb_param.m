function M = mb_param(S, g)
% MB_PARAM  Simscape Multibody 3B modelinin (mb_kol_model) geometri ve kütle parametreleri.
% Kütle ve eylemsizlikler 1B modelin topaklanmış değerlerinden türetilir; böylece 3B model
% J_L'yi ve mgℓ'yi sim_param ile birebir aynı görür (çapraz doğrulama için şart):
%   g (m_r L/2 + m_u d) = S.mgl                          (yerçekimi momenti)
%   Izz_çubuk + m_r (L/2)^2 + Izz_uç + m_u d^2 = S.JL    (eksene göre eylemsizlik)
% -> uç kütlesi m_u ve eksene uzaklığı d. Katılar "Custom" eylemsizlikle verilir (geometriyle tutarlı formüller).
% Motor rotoru: kol tarafına indirgenmiş eşdeğer disk (Izz = S.JM), kütle merkezi eksende (yerçekimi torku yok).
if nargin < 2, g = 9.81; end
M.g  = g;
M.L  = 0.15;   M.w = 0.02;   M.t = 0.005;    % çubuk: boy (kol ekseni), en, kalınlık [m]
M.mr = 0.02;                                 % çubuk kütlesi [kg]
M.Ir = M.mr*[(M.L^2 + M.t^2), (M.w^2 + M.t^2), (M.L^2 + M.w^2)]/12;   % çubuk, kendi merkezinde
M.ru = 0.012;  M.hu = 0.03;                   % uç kütlesi: silindir (ekseni Z = eklem ekseni) [m]
% Uç kütlesi m_u ve eksene uzaklığı d iki koşuldan birlikte çözülür (d tam L'ye sabitlenirse
% J_L ile mgℓ birlikte sağlanamıyor):  m_u d = a,  m_u d^2 = b,  b = J_L - (çubuk) - Izz_u(m_u);
% silindirin kendi ekseni eklem eksenine paralel olduğundan Izz_u = m_u r^2 / 2.
a = S.mgl/g - M.mr*M.L/2;
if a <= 0, error('mb_param: mgl, çubuk kütlesi için fazla küçük'); end
M.mu = a/M.L;
for i = 1:20                                  % sabit nokta (Izz_u, m_u'nun küçük bir kesri)
    b = S.JL - M.Ir(3) - M.mr*(M.L/2)^2 - M.mu*M.ru^2/2;
    d = b/a;  M.mu = a/d;
end
if b <= 0, error('mb_param: J_L = %.3g bu kütle dağılımıyla tutarsız', S.JL); end
M.d  = d;                                     % uç kütlesinin merkezi, eksenden [m]
M.Iu = M.mu*[(3*M.ru^2 + M.hu^2)/12, (3*M.ru^2 + M.hu^2)/12, M.ru^2/2];
M.mrot = 0.05;  M.Irot = S.JM*[1 1 1];        % rotor eşdeğer diski (Ixx + Iyy >= Izz)
M.rrot = 0.03;  M.hrot = 0.008;  M.zrot = -0.04;   % rotor görseli ve kol düzleminden uzaklığı [m]
M.mgl = S.mgl;  M.JL = S.JL;  M.JM = S.JM;   % sağlama için
end
