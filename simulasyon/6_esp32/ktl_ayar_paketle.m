function y = ktl_ayar_paketle(p, thRef, c0, kp, yuz0)
% KTL_AYAR_PAKETLE  kol_benzetim parametrelerinden kartın kontrol::Ayar yükünü (180 B) kurar.
%   Alan sırası firmware/src/kontrol.h'deki struct Ayar ile birebir. Varsayılanlar
%   kol_benzetim.m'deki al(...) varsayılanlarıyla aynı.
%   p    : kol_benzetim'e verilen yapı (yuzKes açık, kontrol 'PPI', Pkaynak 'motor')
%   thRef: hedef [rad] (tek senaryo), c0: başlangıç motor sayımı (out.ktl.ilkSayim)
%   kp   : konum kazancı [1/s] (kol_benzetim'in 3. argümanı), yuz0: başlangıç yüzü (+1/-1)
%   Hız kaynağı HIZ_GIRDI (ikizde p.fv = Inf: kontrolcü gerçek motor hızını görür).
if ~(isfield(p,'kontrol') && strcmp(p.kontrol,'PPI')), error('yalnız PPI'); end
if ~(isfield(p,'Pkaynak') && strcmp(p.Pkaynak,'motor')), error('yalnız motor tarafı konum'); end
if ~strcmp(p.Dkaynak,'motor') || ~isinf(p.fv), error('yalnız gerçek motor hızı (fv = Inf)'); end
kes = find(strcmp(p.yuzKes, {'edilgen','olay','yoklama','olay+yoklama'}));
wo = al(p,'gozW', 2*pi*40);
dbl = [thRef, p.Ts, p.qM, al(p,'yokTmin',3/wo), al(p,'yokTmax',0.3), al(p,'yokBekle',0.5), ...
       al(p,'yokPer',Inf), al(p,'yokBant',deg2rad(1))];
i32 = [c0, al(p,'Nper',100), al(p,'yuzN',200), al(p,'yokMaks',6)];
u8 = [kes, 0, al(p,'tOlc',false), isfield(p,'Isifirla') && p.Isifirla];
f = [kp, p.KV, p.KI, p.Tmax, p.olu, al(p,'Iolu',0), ...
     al(p,'rN',p.r), al(p,'mglN',p.mgl), al(p,'KsN',p.Ks), al(p,'yuzRampa',0.5), yuz0, ...
     wo, al(p,'JMN',p.JM), al(p,'bMN',p.bM), al(p,'FcN',p.Fc), al(p,'FsN',p.Fs), ...
     al(p,'tauEsik',0.015), al(p,'vEsik',0.05), al(p,'vDur',0.01), ...
     al(p,'yokA',0.12), al(p,'yokD',deg2rad(0.5)), al(p,'yokEsik',0.04), al(p,'yokOrta',0.5), al(p,'vDurF',Inf)];
y = [typecast(double(dbl), 'uint8'), typecast(int32(i32), 'uint8'), uint8(u8), typecast(single(f), 'uint8')];
if numel(y) ~= 180, error('Ayar boyu %d (180 olmalı)', numel(y)); end
end

function v = al(p, ad, vars)
if isfield(p, ad), v = p.(ad); else, v = vars; end
end
