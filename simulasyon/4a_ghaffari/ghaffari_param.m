function p = ghaffari_param(durum)
% GHAFFARI_PARAM  Ghaffari ve Mohammadiasl 2013 (TMECH) parametre kümeleri.
%   'sekil7' : benzetim, rezonans rejimi (fa = 11 Hz)
%   'sekil8' : benzetim, çarpma rejimi (fa = 99 Hz)
%   'tabla'  : döner tabla (Ek), Şekil 9 ve 11
% Yük tarafı büyüklükler Jl, cl, ks motora yansıtılmış değerlerden türetilir:
%   Jl = R*Jm*kr^2,  ks = kse*kr^2 = wa^2*Jl,  cl = cle*kr^2.
% Kararlar ve kaynaklar: parametreler.md.
if nargin < 1, durum = 'sekil7'; end
switch durum
    case {'sekil7','sekil8'}
        p.Jm = 0.0235;  p.R = 2.12;  p.kr = 766;  p.Ti = 0.010;
        p.delta = deg2rad(0.12);
        p.fa = 11;  if strcmp(durum,'sekil8'), p.fa = 99; end
        p.cm = 0.0421;  p.cle = 0.0982;            % makalede yok: döner tabladan (karar 2)
        p.Fcm = 0;  p.Fcl = 0;                     % Coulomb yok (karar 2)
    case 'tabla'
        p.Jm = 0.0231;  p.R = 0.788;  p.kr = 1211.65;  p.Ti = 0.040;
        p.delta = deg2rad(0.04);
        p.fa = 15.3;
        p.cm = 0.0421;  p.cle = 0.0982;
        p.Fcm = 6;  p.Fcl = 2*p.kr;                % motor 6 N m; yük "2 kr N m" (yük tarafı)
    otherwise
        error('ghaffari_param: bilinmeyen durum %s', durum);
end
p.durum = durum;
p.wa  = 2*pi*p.fa;
p.Jle = p.R*p.Jm;
p.kse = p.wa^2*p.Jle;
p.Jl  = p.Jle*p.kr^2;
p.ks  = p.kse*p.kr^2;
p.cl  = p.cle*p.kr^2;
p.xis = 0.02;                                      % temas sönümü (makalede yok), wa'ya göre
if strcmp(durum,'tabla'), p.xis = 0; end           % döner tabla: makalenin sürtünmesiz benzetimine
                                                   %   ξ = 0 uyuyor (tabla_sonuclar.md)
p.cs  = 2*p.xis*p.ks/p.wa;
p.veps = 0.05;                                     % Coulomb tanh yumuşatma hızı, motor tarafı [rad/s]
%   (RK4 kararlılığı: Fcm/(veps*Jm)*dt < 2; yük tarafında veps/kr, yani aynı göreli kayma)

% Benzetim ayarları
p.dt  = 2e-5;                                      % RK4 adımı [s]
p.T   = 7;                                         % süre [s]
p.Tan = 4;                                         % analiz penceresi (son Tan saniye; 2 Hz'lik çarpma
                                                   %   rejiminde >= 8 periyot için)
p.dec = 5;                                         % kayıt seyreltme
p.th0 = deg2rad(0.5);                              % başlangıçta yükün hedeften sapması [rad]
end
