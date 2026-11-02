function tani_mgl()
% TANI_MGL  Adım 4.3, Adım 4a: yerçekimi torku mgl ve AS5600 sıfırı, Adım 2 ve 3'ün kayıtlarından.
% Yeni benzetim yok: tani_Ks_kayit.mat (kol 90° +- 70°) ve tani_r_kayit.mat (0° +- 60°) yeniden kullanılır.
% Yarı statik taramada kolun denklemi: tg = J_L dw_L/dt + b_L w_L + mgl sin(th). b_L w_L ~%0.01, ihmal.
% İvme torku küçük (~%0.15) ama sistematik: sinüs taramada dw_L/dt = -W²(th - merkez), yani sin/cos terimiyle
% örtüşüp mgl'yi (0° taraması) ya da sıfırı (90° taraması) kaydırıyor. J_L bu deneyden çıkmaz (geometriden
% alınır); terim J_L ile çıkarılır. Sütunlar: J_L ihmal / J_L doğru / J_L %5 fazla.
% AS5600'ün sıfırı bilinmiyor: th = thm - th0. mgl sin(thm - th0) = a sin(thm) + b cos(thm),
%   a = mgl cos(th0), b = -mgl sin(th0)  ->  mgl = sqrt(a² + b²), th0 = atan2(-b, a).
% Pencere ortalaması (100 ms) Adım 2/3 ile aynı; tg motor tarafından Adım 1 kestirimleriyle; kol hızı AS5600'den
% (±10 örnek yerel eğim). Yukarı ve aşağı ayrı uydurulup ortalanır. AS5600 okumasına keyfi 7.3° ofset eklenir.
kok = fileparts(mfilename('fullpath'));
fid = fopen(fullfile(kok, 'tani_mgl_log.txt'), 'a', 'n', 'UTF-8');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
W = 0.1;  m = 10;  vmin = 0.1;  tbas = 1.0;  ofsL = deg2rad(7.3);  jl = [0 1 1.05];
yaz('=== Adım 4.3 Adım 4a: mgl ve AS5600 sıfırı, J_L terimiyle (%s)\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Eklenen AS5600 ofseti %.1f°. (yukarı + aşağı)/2. Sütunlar J_L × [%s]. mgl hatası %%, th0 hatası °\n', ...
    rad2deg(ofsL), num2str(jl));
yaz('%-8s %-9s %2s | %7s %7s %7s | %7s %7s %7s\n', 'kayıt', 'sensör', '#', 'mgl 0', '1', '1.05', 'th0 0', '1', '1.05');
for kay = {'tani_Ks', 'tani_r'}
    L = load(fullfile(kok, [kay{1} '_kayit.mat']));  R = L.R;
    for duz = {'ideal', 'gercekci'}
        ix = find(strcmp({R.duz}, duz{1}));  T = [];
        for k = ix
            K = R(k).K;  S = R(k).S;
            K.thL = K.thL + ofsL;                           % AS5600 sıfırı kaymış
            P = struct('Km', S.Km*1.0002, 'JM', S.JM*(1 - 0.0021), 'bM', S.bM*1.0135, 'Fc', 0.0396);
            if S.qM == 0, P = struct('Km', S.Km, 'JM', S.JM, 'bM', S.bM, 'Fc', S.Fc); end
            satir = zeros(1, 2*numel(jl));
            for j = 1:numel(jl)
                P.JL = jl(j)*S.JL;
                gy = kestir(K, P, W, tbas, m, vmin, 1);
                ga = kestir(K, P, W, tbas, m, vmin, -1);
                g = (gy + ga)/2;
                satir(j) = 100*(g(1) - S.mgl)/S.mgl;  satir(numel(jl) + j) = rad2deg(g(2) - ofsL);
            end
            T(end+1, :) = satir; %#ok<AGROW>
            yaz('%-8s %-9s %2d | %+7.2f %+7.2f %+7.2f | %+7.3f %+7.3f %+7.3f\n', kay{1}, duz{1}, k - ix(1) + 1, satir);
        end
        if numel(ix) > 1
            yaz('%-8s %-9s %2s | %+7.2f %+7.2f %+7.2f | %+7.3f %+7.3f %+7.3f\n', kay{1}, duz{1}, 'or', mean(T));
            yaz('%-8s %-9s %2s | %7.2f %7.2f %7.2f | %7.3f %7.3f %7.3f\n', kay{1}, duz{1}, 'sd', std(T));
        end
    end
end
fclose(fid);
end

function g = kestir(K, P, W, tbas, m, vmin, yon)
% g = [mgl, th0]
t = K.t;  Ts = t(2) - t(1);  n = round(W/Ts);
c = (-m:m)'/(Ts*sum((-m:m).^2));
w = conv(K.phi, flipud(c), 'same');  w([1:m, end-m+1:end]) = NaN;
wL = conv(K.thL, flipud(c), 'same');  wL([1:m, end-m+1:end]) = NaN;
s0 = find(t >= tbas, 1);  nP0 = floor((numel(t) - s0)/n);
A = zeros(nP0, 2);  b = zeros(nP0, 1);  ok = false(nP0, 1);
for k = 1:nP0
    j = s0 + (k-1)*n + (0:n);
    wj = w(j);
    if any(isnan(wj)) || any(isnan(wL(j))) || min(abs(wj)) < vmin || any(sign(wj) ~= sign(wj(1))), continue; end
    if yon ~= 0 && sign(wj(1)) ~= yon, continue; end
    b(k) = (P.Km*trapz(K.i(j))*Ts - P.JM*(wj(end) - wj(1)) - P.bM*(K.phi(j(end)) - K.phi(j(1))) ...
            - P.Fc*sign(wj(1))*W - P.JL*(wL(j(end)) - wL(j(1))))/W;
    A(k, :) = [trapz(sin(K.thL(j)))*Ts/W, trapz(cos(K.thL(j)))*Ts/W];
    ok(k) = true;
end
x = A(ok, :)\b(ok);
g = [hypot(x(1), x(2)), atan2(-x(2), x(1))];
end
