function r = rejim_sinifla(t, y, o)
% REJIM_SINIFLA  Bir zaman serisinin (benzetim ya da deney) rejimini sınıflar.
% t: zaman [s] (sütun), y: hedeften sapma (sütun; matris ise her sütun ayrı sınıflanır).
% o (isteğe bağlı alanlar):
%   A_min   salınım sayılacak en küçük genlik (y'nin biriminde); deneyde sensör çözünürlüğü
%   A_max   bunun üstü kararsız sayılır (güvenlik sınırı)                    [Inf]
%   f_z     dış zorlama frekansı [Hz]; 0 = zorlama yok                       [0]
%   T_at    baştan atılacak süre [s] (başlangıç geçişi)                       [0]
%   s_esik  zarf değişimi eşiği: analiz penceresi boyunca |ln(A_son/A_ilk)|   [0.05]
%   cv_esik periyot ve genlik tekrarlanabilirliği eşiği (değişim katsayısı)   [0.1]
%   z_esik  zorlama frekansı ve harmoniklerindeki güç payı eşiği             [0.8]
%
% Sınıflar (r.sinif):
%   0 denge             salınım yok (A < A_min başından sonuna)
%   1 sönümlü titreşim  başlangıçta en az iki yarım periyot A_min'in üstünde salınım var,
%                       zarf küçülüyor / A_min altına iniyor (salınımsız dönüş: denge)
%   2 zorlanmış cevap   kalıcı salınım, gücün >= z_esik'i zorlama frekansı ve harmoniklerinde
%   3 kalıcı çevrim     zorlama olmadan (ya da zorlamadan bağımsız) kendini sürdüren,
%                       zarfı sabit ve periyodik salınım
%   4 kararsız          zarf üstel büyüyor (son iki çeyrekte büyüme hızı düşmüyor) ya da A_max aşılıyor;
%                       büyüme yavaşlıyorsa bir çevrime yaklaşılıyordur (r.yakinsiyor), kararsız sayılmaz
%   5 düzensiz          sürüyor, zarf sabit, ama periyodik değil
% Ölçütler yarım periyot genliklerinden: y'nin ortalamasının iki yanındaki ardışık
% geçişler arasında |y - m|'nin en büyüğü (a_i, t_i). Zarf eğimi s = ln a'nın t'ye göre
% eğimi (son yarıda), değişim = s * pencere süresi. İlk genlik T_at kesilmeden önceki
% sinyalden ölçülür (sönüm genellikle başlangıç geçişinde olur).
if nargin < 3, o = struct(); end
d = struct('A_min',NaN,'A_max',Inf,'f_z',0,'T_at',0,'s_esik',0.05,'cv_esik',0.1,'z_esik',0.8);
for k = fieldnames(d)', if ~isfield(o,k{1}), o.(k{1}) = d.(k{1}); end, end
ad = {'denge','sönümlü titreşim','zorlanmış cevap','kalıcı çevrim','kararsız','düzensiz'};
n = size(y,2);
r = struct('sinif',zeros(1,n),'ad',{cell(1,n)},'A',zeros(1,n),'f',zeros(1,n),'degisim',zeros(1,n), ...
           'cvT',nan(1,n),'cvA',nan(1,n),'zpay',nan(1,n),'ofset',zeros(1,n),'yakinsiyor',false(1,n));
t_tum = t;  y_tum = y;
m0 = t >= t(1) + o.T_at;  t = t(m0);  y = y(m0,:);
for j = 1:n
    yj = y(:,j);
    Amin = o.A_min;  if isnan(Amin), Amin = 1e-3*max(abs(yj)); end
    son = t >= t(1) + 0.75*(t(end)-t(1));
    m = mean(yj(son));  r.ofset(j) = m;
    [a, ta, Th] = yarim_periyot(t, yj - m);
    A_son = 0;  if any(son), A_son = (max(yj(son)) - min(yj(son)))/2; end
    a0 = yarim_periyot(t_tum, y_tum(:,j) - m);
    n_ilk = nnz(a0 > Amin);                        % başlangıçta eşik üstü yarım periyot sayısı
    r.A(j) = A_son;
    % zarf değişimi (son yarı), frekans
    yari = ta >= t(1) + 0.5*(t(end)-t(1));
    g3 = NaN;  g4 = NaN;
    if nnz(yari) >= 4
        q = polyfit(ta(yari), log(a(yari)), 1);
        r.degisim(j) = q(1)*(t(end) - t(1))/2;
        c3 = yari & ta < t(1) + 0.75*(t(end)-t(1));  c4 = ta >= t(1) + 0.75*(t(end)-t(1));
        if nnz(c3) >= 2 && nnz(c4) >= 2
            q3 = polyfit(ta(c3), log(a(c3)), 1);  q4 = polyfit(ta(c4), log(a(c4)), 1);  g3 = q3(1);  g4 = q4(1);
        end
        r.f(j) = 1/(2*mean(Th(yari)));
        r.cvT(j) = std(Th(yari))/mean(Th(yari));
        r.cvA(j) = std(a(yari))/mean(a(yari));
    end
    % karar
    buyuyor = r.degisim(j) > o.s_esik && A_son > Amin;
    r.yakinsiyor(j) = buyuyor && ~isnan(g4) && g4 < 0.5*g3;
    if max(abs(yj)) > o.A_max || (buyuyor && ~r.yakinsiyor(j))
        c = 4;
    elseif A_son < Amin
        c = 0;  if n_ilk >= 2, c = 1; end
    elseif r.degisim(j) < -o.s_esik
        c = 1;
    else
        if o.f_z > 0
            r.zpay(j) = zorlama_payi(t(son), yj(son) - m, o.f_z);
        end
        if o.f_z > 0 && r.zpay(j) >= o.z_esik
            c = 2;
        elseif r.cvT(j) < o.cv_esik && (r.cvA(j) < o.cv_esik || r.yakinsiyor(j))
            c = 3;
        else
            c = 5;
        end
    end
    r.sinif(j) = c;  r.ad{j} = ad{c+1};
end
end

function [a, ta, Th] = yarim_periyot(t, y)
% Ardışık sıfır geçişleri arasındaki en büyük |y|, zamanı ve yarım periyot süresi.
z = find(y(1:end-1).*y(2:end) < 0);
a = []; ta = []; Th = [];
for k = 1:numel(z)-1
    s = z(k)+1:z(k+1);
    [a(end+1), i] = max(abs(y(s))); %#ok<AGROW>
    ta(end+1) = t(s(i)); %#ok<AGROW>
    Th(end+1) = t(z(k+1)) - t(z(k)); %#ok<AGROW>
end
a = a(:); ta = ta(:); Th = Th(:);
end

function p = zorlama_payi(t, y, fz)
% Gücün zorlama frekansı ve ilk 5 harmoniği çevresindeki (±%3) payı (Hann pencereli FFT).
N = numel(y);  dt = mean(diff(t));
Y = abs(fft(y(:).*hann_(N))).^2;  f = (0:N-1)'/(N*dt);
yari = f > 0 & f < 0.5/dt;
pay = false(size(f));
for h = 1:5, pay = pay | abs(f - h*fz) <= max(0.03*h*fz, 1.5/(N*dt)); end
p = sum(Y(yari & pay))/sum(Y(yari));
end

function w = hann_(N)
w = 0.5 - 0.5*cos(2*pi*(0:N-1)'/(N-1));
end
