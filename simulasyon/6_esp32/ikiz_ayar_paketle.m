function y = ikiz_ayar_paketle(p, thRef, x0, tohum)
% IKIZ_AYAR_PAKETLE  kol_benzetim parametrelerinden kartın ikiz::Ayar yükünü (180 B) kurar.
%   Alan sırası firmware/src/ikiz.h'deki struct Ayar ile birebir; tamsayıya çevirmeler
%   (alt adım, gecikme, INA228 penceresi) kol_benzetim.m'deki round(...) ifadeleriyle aynı.
%   p    : kol_benzetim'e verilen yapı (tek senaryo)
%   thRef: hedef [rad]
%   x0   : başlangıç durumu [phi; dphi; th; dth] (kol_benzetim'in x'i, mutlak)
%   tohum: [enkoder, tork] gürültü RNG tohumları (kartın xorshift'i; varsayılan [1 2])
%   T_IKIZ_BASLAT yükü = [typecast(uint32(N),'uint8'), y].
if nargin < 4, tohum = [1 2]; end
dA = 0;  df = 0;  dT = Inf;  dT0 = 0;
if isfield(p,'dA'), dA = p.dA;  df = p.df; end
if isfield(p,'dT'), dT = p.dT; end
if isfield(p,'dT0'), dT0 = p.dT0; end
tOlc = al(p,'tOlc',false);
if tOlc
    tG = round(al(p,'tGec',0)/p.dt);  tP = max(1, round(al(p,'tPen',p.Ts)/p.dt));
else
    tG = 0;  tP = 1;
end
dbl = [thRef, p.dt, p.qM, x0(1), x0(2), x0(3), x0(4), dT0, dT, al(p,'akimW',Inf)];
i32 = [max(1, round(p.Ts/p.dt)), round(al(p,'gM',0)/p.dt), tG, tP];
f = [p.JM, p.JL, p.bM, p.bL, p.Ks, p.cs, p.r, p.Fc, p.Fs, p.vs, p.veps, p.mgl, dA, df, ...
     al(p,'nM',0), al(p,'tGur',0), al(p,'tOfs',0), al(p,'tKaz',1)];
y = [typecast(double(dbl), 'uint8'), typecast(int32(i32), 'uint8'), typecast(uint32(tohum), 'uint8'), ...
     uint8([tOlc 0 0 0]), typecast(single(f), 'uint8')];
if numel(y) ~= 180, error('ikiz Ayar boyu %d (180 olmalı)', numel(y)); end
end

function v = al(p, ad, vars)
if isfield(p, ad), v = p.(ad); else, v = vars; end
end
