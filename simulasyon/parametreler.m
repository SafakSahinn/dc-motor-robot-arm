function p = parametreler(seviye)
% PARAMETRELER  Dişli DC motorlu tek eklemli kolun tahmini parametreleri.
% Tüm büyüklükler KOL TARAFINA (dişli çıkışına) indirgenmiştir.
% Değerler JGA25-370 sınıfı motor + hafif alüminyum kol için tahmindir;
% gerçek düzenekte sistem tanılamayla ölçülecek.
%
% seviye: 'ideal'    sürtünmesiz, ideal sensör, (neredeyse) sürekli kontrol  [varsayılan]
%         'surtunme' ideal + Coulomb/yapışma sürtünmesi
%         'gercekci' sürtünme + nicemleme + 1 kHz ayrık kontrol + sürücü ölü bandı
if nargin < 1, seviye = 'ideal'; end

% --- Dişli ve motor ---
p.N    = 34;                 % dişli oranı (bilgi amaçlı; aşağıdakiler zaten indirgenmiş)
Jrot   = 1.5e-6;             % motor rotor eylemsizliği [kg m^2] (motor milinde)
p.JM   = Jrot*p.N^2;         % kol tarafına yansıyan motor eylemsizliği [kg m^2]
p.bM   = 2e-3;               % motor tarafı viskoz sürtünme [N m s/rad]
p.Tmax = 0.6;                % motorun dişli çıkışındaki en büyük torku [N m]

% --- Kol ---
mRod = 0.020; L = 0.15;      % alüminyum çubuk [kg], boy [m]
mTip = 0.050;                % uç kütlesi [kg]
p.JL   = mRod*L^2/3 + mTip*L^2;          % kolun mil etrafındaki eylemsizliği
p.mgl  = 9.81*(mRod*L/2 + mTip*L);       % yerçekimi torkunun genliği [N m]
p.bL   = 1e-4;               % kol yatağı viskoz sürtünme [N m s/rad]

% --- Dişli teması ---
p.Ks   = 10;                 % dişli (temas) sertliği [N m/rad]
p.cs   = 0.02;               % temas sönümü [N m s/rad]
p.r    = deg2rad(0.75);      % boşluk yarı genişliği; toplam boşluk 2r = 1.5 derece

% --- Motor tarafı Coulomb + yapışma sürtünmesi (0 = yok) ---
p.Fc   = 0;                  % Coulomb sürtünmesi [N m]
p.Fs   = 0;                  % yapışma (statik) sürtünmesi [N m]
p.vs   = 0.05;               % Stribeck hızı [rad/s]
p.veps = 2e-3;               % sıfır hız yumuşatması [rad/s] (sabit adımlı RK4'ün kararlılığı için)

% --- Kontrolcü ---
p.Dkaynak = 'motor';         % türev (sönüm) hangi hızdan: 'motor' enkoderi ya da 'kol' sensörü
p.adim    = 5;               % başlangıçta kolun hedefin kaç derece altında olduğu
p.Ts   = 1e-4;               % kontrol periyodu [s] (dt'ye eşitse neredeyse sürekli)
p.qL   = 0;                  % kol sensörü nicemleme basamağı [rad] (0 = ideal)
p.qM   = 0;                  % motor enkoderi nicemleme basamağı, kol tarafında [rad] (0 = ideal)
p.fv   = Inf;                % hız kestirimi alçak geçiren filtre kesimi [Hz] (Inf = gerçek hız)
p.olu  = 0;                  % sürücü ölü bandı, tork cinsinden [N m]

% --- Benzetim ---
p.dt   = 1e-4;               % RK4 adımı [s]
p.T    = 20;                 % toplam süre [s]
p.Tan  = 10;                 % analiz penceresi: son 10 s
p.dec  = 20;                 % kayıt seyreltme

switch seviye
    case 'ideal'
    case 'surtunme'
        p.Fc = 0.04;  p.Fs = 0.06;
    case 'gercekci'
        p.Fc = 0.04;  p.Fs = 0.06;
        p.Ts = 1e-3;
        p.qL = 2*pi/4096;                 % AS5600, 12 bit
        p.qM = 2*pi/(11*4*p.N);           % 11 darbe/tur, 4 kenar, dişliden sonra
        p.fv = 50;
        p.olu = 0.03*p.Tmax;
    otherwise
        error('bilinmeyen seviye: %s', seviye);
end
p.seviye = seviye;
end
