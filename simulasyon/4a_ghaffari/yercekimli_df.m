function d = yercekimli_df(p, th0_deg, kp, varargin)
% YERCEKIMLI_DF  Yerçekimli eklemde iki girişli tanımlama fonksiyonu (DIDF) ile çevrim öngörüsü.
% Ghaffari 2013 çerçevesinin (ghaffari_df.m) yerçekimi ön yüküyle genişletilmesi.
%
% Dişli sapması x = B + A sin(wt) (B: ön yükten gelen ortalama, A: salınım genliği).
% Ölü bölge (yarı genişlik r, sertlik Ks), r ile normalize: b = B/r, a = A/r.
%   (i)  DC dengesi:      n0(a,b) = beta,  beta = mgl sin(th0) / (Ks r)    -> b(a)
%        (beta, framing.md'deki gamma ile aynı oran; kodda d.beta adıyla)
%   (ii) birinci harmonik: n1(a,b(a)) * L(jw) = -1                           -> w, a
% L(s) = Ks (C kp + P + M) / (M P), M = Jm s^2 + cm s + C s, P = Jl s^2 + cl s + kg,
% C = KV + KI/s.  kg = 0 iken L Ghaffari'nin G H'si (denklem 5-6) ile aynı.
% kg = mgl cos(th0): yerçekiminin doğrusallaştırılmış "yayı" (seçenek 'kg', true/false).
% n1 gerçel olduğundan döngü, sabit kazanç n'li doğrusal döngü gibi incelenir (kapalı çevrim
% kökleri; kg > 0 iken L'nin sarkaç modu da -180°'yi kestiği için tek faz geçişi yetmez):
%   n = 1'de kararsız                      -> 'X' (DF tork sınırını bilmez)
%   [n1min(beta), 1) içinde kararsız n var -> 'C'; n_req = bu kümenin üst sınırı (kararlı
%                                             çevrim, Ghaffari'nin -1/Re{GH}'si), f = sınırdaki kök
%                                             beta > 0 ise denge de yerel kararlı (iki kararlılık)
%   yoksa                                  -> '.'
% Temas sönümü (seçenek 'cs', true/false; varsayılan true): temas torku Ks dz(x) + cs x' yalnız
% temasta. Sönüm teriminin ortalaması ve sinüs bileşeni sıfır, kosinüs bileşeni cs w A h(a,b),
% h = (1/pi) int_temas cos^2. Dişli eşdeğer yay + sönümleyici olur: k_e = Ks n1, c_e = cs h;
% kararlılık n yerine genlik eğrisi a boyunca (k_e(a), c_e(a)) ile taranır:
%   tam temasta (Ks, cs) kararsız -> 'X';  eğride kararsız a var -> 'C' (kararlı çevrim, kararlıya
%   dönülen en büyük a; a1 = ilk kararsız a, beta > 0 ise eşik);  yoksa '.'.
%   n_req bu durumda kararlı çevrimdeki n1.
% Tork sınırı (seçenek 'Tmax', true/false; varsayılan false; yalnız temas sönümlü yolda):
% ön yüklü doyumun DF'si (doyumda_kararsiz). Dişli eğrisindeki kararsız genliklerin hiçbirinde
% gerçek doyum kazancıyla döngü kararsız kalmıyorsa çevrim söner ('.'); tam temasta kararsızlık
% doyumla sınırlanır ('S'). Benzetimdeki anti-windup DF'de yok. f, a2, A_th doyumsuz değerler.
% Çıktı alanları th0 x kp boyutunda (satır kp, sütun açı; secenekler.m'deki AC, KP ile aynı).
if ischar(p) && strcmp(p, 'dz'), d = @dz_harmonik; return; end   % testler için
o = struct('kg', true, 'cs', true, 'Tmax', false);
for i = 1:2:numel(varargin), o.(varargin{i}) = varargin{i+1}; end
cs = o.cs*p.cs;
doy = o.Tmax && isfinite(p.Tmax) && cs > 0;      % tork sınırı yalnız temas sönümlü yolda
th0 = deg2rad(th0_deg(:)');  kp = kp(:);
[TH, KP] = meshgrid(th0, kp);
beta = p.mgl*sin(TH)/(p.Ks*p.r);
kg = o.kg*p.mgl*cos(TH);
d.beta = beta;  d.n_req = nan(size(TH));  d.f = nan(size(TH));
d.n1min = nan(size(TH));  d.a1 = nan(size(TH));  d.a2 = nan(size(TH));
d.A_th = nan(size(TH));   d.sinif = repmat('.', size(TH));
% Kontrolcü iki polinomla: u = -(cv(s)/s) s phi - (pc(s)/s) th  (hata = -th, hedef 0)
%   P-PI: cv = [KV KI], pc = kp [KV KI]      PID (p.kontrol ~= 'PPI', üçüncü argüman wc):
%   cv = [Kd 0], pc = [Kp Ki], Kp = J wc^2, Kd = 1,4 J wc, Ki = Kp wc / 4 (kol_benzetim ile aynı)
ppi = isfield(p,'kontrol') && strcmp(p.kontrol,'PPI');
d.rgs = nan(size(TH));
for m = 1:numel(TH)
    if ppi
        cv = [p.KV p.KI];  pc = KP(m)*[p.KV p.KI];
    else
        J = p.JM + p.JL;  Kp = J*KP(m)^2;
        cv = [1.4*J*KP(m) 0];  pc = [Kp Kp*KP(m)/4];
    end
    d.rgs(m) = sqrt(pc(1)/p.Ks);
    M = [p.JM, p.bM + cv(1), cv(2)];               % M(s) = Jm s^2 + cm s + cv(s)
    P = [p.JL, p.bL, kg(m)];
    % dişli eşdeğeri (k + c s) için karakteristik polinom: s M P + (k + c s) Q,
    % Q = pc(s) + s (P + M)
    c0 = conv([1 0], conv(M, P));
    Q  = [0 0 pc] + conv([1 0], P + M);
    kok = @(k, c) roots(c0 + conv([0 c k], Q));
    kar = @(k, c) any(real(kok(k, c)) > 1e-9);     % kararsız mı
    [a, n1, h] = n1_egrisi(beta(m));
    d.n1min(m) = min(n1);
    if kar(p.Ks, cs)
        d.sinif(m) = 'X';  if doy, d.sinif(m) = 'S'; end   % S: doyumla sınırlanan salınım
        continue;
    end
    if cs == 0
        % (0, 1) aralığındaki kararsız kazançların üst sınırı = kararlı çevrimin n'i (n_req);
        % çevrim için n_req > n1min gerekir (n_req yerçekiminden bağımsız hesaplanır, sınır için)
        ng = [linspace(1e-6, 0.05, 50) linspace(0.05, 1, 400)];
        u = arrayfun(@(n) kar(n*p.Ks, 0), ng);
        if ~any(u), continue; end
        j = find(u, 1, 'last');  lo = ng(j);  hi = ng(j+1);
        for it = 1:40, mid = (lo+hi)/2; if kar(mid*p.Ks, 0), lo = mid; else, hi = mid; end, end
        d.n_req(m) = hi;  ce = 0;
        z = kok(lo*p.Ks, 0);  [~, i0] = max(real(z));  wc = abs(imag(z(i0)));
        d.f(m) = wc/2/pi;
        if d.n_req(m) <= d.n1min(m), continue; end
        [~, j0] = min(n1);
        d.a1(m) = 0;                                                     % kararsız çevrim (eşik)
        if j0 > 1, d.a1(m) = ters(n1(1:j0), a(1:j0), d.n_req(m)); end
        d.a2(m) = ters(n1(j0:end), a(j0:end), d.n_req(m));               % kararlı çevrim
    else
        u = arrayfun(@(i) kar(p.Ks*n1(i), cs*h(i)), 1:numel(a));
        if ~any(u), continue; end
        d.a1(m) = a(find(u, 1))*(beta(m) > 0);
        j = find(u, 1, 'last');
        if j == numel(a), d.sinif(m) = 'X';  if doy, d.sinif(m) = 'S'; end, continue; end
        if doy && ~doyumda_kararsiz(p, P, cv, pc, sin(TH(m)), a, n1, h, cs, find(u))
            continue;                              % doyum kazancı çevrimi söndürüyor
        end
        % a_j ile a_j+1 arasında doğrusal ara değerle kararlılık sınırı
        ara = @(t) deal(n1(j) + t*(n1(j+1)-n1(j)), h(j) + t*(h(j+1)-h(j)));
        lo = 0;  hi = 1;
        for it = 1:30
            mid = (lo+hi)/2;  [nn, hh] = ara(mid);
            if kar(p.Ks*nn, cs*hh), lo = mid; else, hi = mid; end
        end
        [nn, hh] = ara(lo);
        d.n_req(m) = nn;  ce = cs*hh;  d.a2(m) = a(j) + hi*(a(j+1)-a(j));
        z = kok(p.Ks*nn, cs*hh);  [~, i0] = max(real(z));  wc = abs(imag(z(i0)));
        d.f(m) = wc/2/pi;
    end
    d.sinif(m) = 'C';
    % kol açısının genliği: th = (k_e + c_e s) x / P
    d.A_th(m) = rad2deg(abs(p.Ks*d.n_req(m) + 1i*wc*ce)*d.a2(m)*p.r/abs(polyval(P, 1i*wc)));
end
d.TH = TH;  d.KP = KP;
end

function var = doyumda_kararsiz(p, P, cv, pc, sth, a, n1, h, cs, iu)
% Tork sınırı: sat(u) = u - dz_Tmax(u), ön yük u0 (ortalama tork = mgl sin th0).
% Doyum kazancı n_s kontrolcü çıkışını ölçekler. Dişli eğrisindeki kararsız her a için:
% n_s'nin kararlılık sınırı ns_m (ikiye bölme), sınırdaki w'de motor komutu genliği
% U = |T_ux(jw)| A, T_ux = (pc/s) E/P + cv (1 + E/P), E = k_e + c_e jw; gerçek doyum kazancı
% n_s(U) > ns_m olan bir a varsa doyum çevrimi söndüremez (var = true).
var = false;
[ups, ns] = sat_egrisi(p.mgl*sth/p.Tmax);
karN = @(k, c, g) any(real(kokN(p, P, cv, pc, k, c, g)) > 1e-9);
iu = iu(unique(round(linspace(1, numel(iu), min(numel(iu), 60)))));
gs = linspace(0.01, 1, 40);
for i = iu
    kk = p.Ks*n1(i);  cc = cs*h(i);
    % g = 1'deki kararsızlığa bitişik kararlı aralığın üst sınırı ns_m (çok küçük g'de yük
    % serbest kalır, 90° üstünde yerçekimiyle kararsızdır: o uç kullanılmaz)
    st = ~arrayfun(@(g) karN(kk, cc, g), gs);
    j = find(st, 1, 'last');
    if isempty(j), var = true; return; end         % hiçbir doyum kazancı kararlı kılmıyor
    if j == numel(gs), continue; end
    lo = gs(j);  hi = gs(j+1);                     % lo kararlı, hi kararsız
    for it = 1:20, mid = (lo+hi)/2; if karN(kk, cc, mid), hi = mid; else, lo = mid; end, end
    z = kokN(p, P, cv, pc, kk, cc, hi);  [~, i0] = max(real(z));  w = abs(imag(z(i0)));
    s = 1i*w;  E = kk + cc*s;  Pw = polyval(P, s);
    U = abs(polyval(pc, s)/s*E/Pw + polyval(cv, s)*(1 + E/Pw))*a(i)*p.r;
    if interp1(ups, ns, min(max(U/p.Tmax, ups(1)), ups(end))) > lo, var = true; return; end
end
end

function z = kokN(p, P, cv, pc, k, c, g)
% doyum kazancı g ile karakteristik polinom:
% s Mg (P + E) + E g pc(s) + s E P,  Mg = Jm s^2 + cm s + g cv(s)
Mg = [p.JM, p.bM + g*cv(1), g*cv(2)];  E = [c k];
z = roots(conv([1 0], conv(Mg, P + [0 E])) + [0 0 0 conv(E, g*pc)] ...
          + [0 conv([1 0], conv(E, P))]);
end

function [ups, ns] = sat_egrisi(gam)
% Ön yüklü doyumun temel harmonik kazancı: normalize genlik ups = U/Tmax, ortalama
% u0/Tmax = m, DC dengesi m - n0_dz(ups, m) = gam (gam = mgl sin th0 / Tmax), ns = 1 - n1_dz.
persistent tab
key = round(gam*1e6);
if isempty(tab), tab = containers.Map('KeyType','double','ValueType','any'); end
if isKey(tab, key), v = tab(key); [ups, ns] = v{:}; return; end
ups = logspace(-3, 2, 300);  ns = zeros(size(ups));
for i = 1:numel(ups)
    if gam == 0, m = 0;
    else, m = fzero(@(m) m - dz_harmonik(ups(i), m) - gam, [0, gam + ups(i) + 2]); end
    [~, n1] = dz_harmonik(ups(i), m);  ns(i) = 1 - n1;
end
tab(key) = {ups, ns};
end

function x = ters(y, x, y0)
% tekdüze parçada y(x) = y0'ın tersi (eşit y değerleri atılır)
[y, u] = unique(y);  x = interp1(y, x(u), y0);
end

function [a, n1, h] = n1_egrisi(beta)
% DC dengesi boyunca n1(a), h(a): her a için n0(a,b) = beta çözülür (n0, b'de artan).
persistent tab
key = round(beta*1e6);
if isempty(tab), tab = containers.Map('KeyType','double','ValueType','any'); end
if isKey(tab, key), v = tab(key); [a, n1, h] = v{:}; return; end
a = [logspace(-3, 0, 60) linspace(1.02, 60, 400)];
n1 = zeros(size(a));  h = n1;
for i = 1:numel(a)
    if beta == 0
        b = 0;
    else
        b = fzero(@(b) dz_harmonik(a(i), b) - beta, [0, 1 + beta + a(i)]);
    end
    [~, n1(i), h(i)] = dz_harmonik(a(i), b);
end
tab(key) = {a, n1, h};
end

function [n0, n1, h] = dz_harmonik(a, b)
% Birim yarı genişlikli, birim eğimli ölü bölge; giriş b + a sin(psi).
% n0 = ortalama çıkış, n1 = temel harmonik (sinüs bileşeni) / a. Kapalı biçim (kesim açıları).
% h = (1/pi) int_temas cos^2(psi): temasta etkili sönümün kosinüs bileşeni (sürekli temasta 1).
n0 = 0;  n1 = 0;  h = 0;
% sağ kenar (x > 1) katkısı: y = x - 1, sol kenar (x < -1): y = x + 1
for sgn = [1 -1]
    c = (sgn*1 - b)/a;                       % x = sgn olduğu yerde sin(psi) = c
    % temas bölgesi: sgn*(b + a sin psi) > 1  <=>  sgn*sin psi > sgn*c
    if sgn*c >= 1, continue; end             % hiç temas yok
    if sgn*c <= -1                           % sürekli temas
        I0 = 2*pi*(b - sgn);  I1 = pi*a;  H = pi;
    else
        p1 = asin(c);                        % sin psi = c'nin iki kökü: p1, pi - p1
        if sgn == 1, lo = p1; hi = pi - p1; else, lo = pi - p1; hi = 2*pi + p1; end
        % int (b - sgn + a sin psi) dpsi ve int (b - sgn + a sin psi) sin psi dpsi, [lo, hi]
        I0 = (b - sgn)*(hi - lo) - a*(cos(hi) - cos(lo));
        I1 = -(b - sgn)*(cos(hi) - cos(lo)) + a*((hi - lo)/2 - (sin(2*hi) - sin(2*lo))/4);
        H  = (hi - lo)/2 + (sin(2*hi) - sin(2*lo))/4;
    end
    n0 = n0 + I0/(2*pi);
    n1 = n1 + I1/(pi*a);
    h  = h + H/pi;
end
end
