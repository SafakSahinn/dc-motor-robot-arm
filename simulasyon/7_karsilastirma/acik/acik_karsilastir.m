function acik_karsilastir(v)
% ACIK_KARSILASTIR  Kestiricinin B2'de bulunan açıkları için yoklama bölgesi seçeneklerinin karşılaştırması.
%   Varyantlar (p.yokBolge): 1 '180' (eski), 2 '180+360', 3-5 'tork' (p.yokTorkEsik = mgl sin 1°/2°/3°).
%   Bölüm 1, B2 ızgarası (dişlisiz, taup = 0): 108 açı (90-357,5°) x 2 yön x 3 tohum x 7 senaryo x
%     {sürtünmeli, sürtünmesiz}; b2_harita/kos ile aynı kurulum ve H7 (son 1 s |e| <= 0,5°, en büyük <= 1°).
%   Bölüm 2, B1 ızgarası: 7 istek (179-181°) x 2 yön x 3 tohum x 6 senaryo x 2 sürtünme;
%     b1_kural_karsilastirma ile aynı (H7 son yüz dahil, B12, B13).
%   Bedel: yoklama sayısı, B13 (yoklamada kol hareketi), son 1 s RMS u.
%   v: varyant numarası (boşsa ortam ACIK_VARYANT). Çıktı acik_v<v>.mat; özet acik_birlestir.m.
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '7_karsilastirma', 'b2'));
cd(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(v), v = str2double(getenv('ACIK_VARYANT')); end
[p0, G] = b2_kurulum();
V = acik_varyant(p0);
fprintf('varyant %d: %s\n', v, V(v).ad);
t0 = tic;

% ---- Bölüm 1: B2 ızgarası, dişlisiz ----
ort = [1 4];                                        % b2_kurulum: 1 sürtünmeli muP 0, 4 sürtünmesiz muP 0
B2 = struct([]);
for ia = 1:numel(ort)
    a = ort(ia);
    for sc = 1:numel(G.sen)
        [TH, Yv, Bv] = ndgrid(G.aci, [1 -1], G.tohum);
        TH = TH(:)';  Yv = Yv(:)';  Bv = Bv(:)';
        r = struct('e',[],'emax',[],'h7',[],'App',[],'urms',[],'yok',[],'b13',[],'b12',[]);
        idx = [];
        for ts = G.tohum
            j = find(Bv == ts);  idx = [idx j]; %#ok<AGROW>
            o = kos2(p0, G, V(v), a, sc, TH(j), Yv(j), ts);
            for f = fieldnames(o)', r.(f{1}) = [r.(f{1}) o.(f{1})]; end
        end
        [~, ord] = sort(idx);
        for f = fieldnames(r)', r.(f{1}) = r.(f{1})(ord); end
        r.aci = TH;  r.yon = Yv;  r.tohum = Bv;  r.ortam = G.ortam{a,1};  r.sen = G.sen{sc};
        B2 = [B2 r]; %#ok<AGROW>
        fprintf('  B2 %s %-12s H7 %3d/%d  %.0f s\n', G.ortam{a,1}, G.sen{sc}, nnz(r.h7), numel(r.h7), toc(t0));
    end
end

% ---- Bölüm 2: B1 ızgarası ----
istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y] = ndgrid(istek, [1 -1]);  I = I(:)';  Y = Y(:)';  n = numel(I);
sen1 = {'temel', 'a1 darbe', 'a2 yük', 'b salınım', 'c yaklaşma', 'd yön değ.'};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
q0 = p0;  q0.dec = 10;  tD = 3;
B1 = struct([]);
for a = 1:2
    for sc = 1:numel(sen1)
        Yf = Y;  if sc == 6, Yf = -Y; end
        hedef = I;  kay = abs(I - 180) < G.eps_;  hedef(kay) = 180 - G.eps_*Yf(kay);
        s0 = sign(sind(hedef));  sDog = s0;
        q = q0;  q.Fc = sur{a,2};  q.Fs = sur{a,3};  q.yuz0 = s0;  q.adim = 1.1*Y;
        switch sc
            case 2, q.dA = 0.05*sign(180 - hedef);  q.df = 25;  q.dT0 = tD;  q.dT = tD + 0.02;
            case 3, q.dB = 0.02*s0;  q.dBT0 = tD;  sDog = -s0;
            case 4, q.dA = 0.01*ones(1,n);  q.df = 1;  q.dT0 = tD;  q.dT = Inf;  sDog = nan(1,n);
            case 5, W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
            case 6, W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
        end
        if sc >= 5, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
        q = kestirici(q, V(v));
        for ts = G.tohum
            p = q;  p.nTohum = ts;  r = struct();
            o = kol_benzetim(p, hedef, G.kpv*ones(1,n));
            sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
            gy = sign(o.delta).*(abs(o.delta) >= p.r);  yuzS = sign(sum(gy(son,:), 1));
            r.sur = sur{a,1};  r.sen = sen1{sc};  r.tohum = ts;
            r.e = mean(sap(son,:), 1);  r.emax = max(abs(sap(son,:)), [], 1);
            r.h7 = abs(r.e) <= 0.5 & r.emax <= 1 & yuzS == sDog;
            r.App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
            tB = 0.5;  if sc == 4, tB = tD; end
            tm = gy ~= 0 & o.t >= tB;
            r.b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
            r.b13 = rad2deg(o.yokKol);  if any(sc == [2 3 4]), r.b13(:) = NaN; end
            r.yok = o.yokSay;
            B1 = [B1 r]; %#ok<AGROW>
        end
    end
end
fprintf('  B1 bitti, %.0f s\n', toc(t0));
Vv = V(v);  sure = toc(t0); %#ok<NASGU>
save(sprintf('acik_v%d.mat', v), 'B2', 'B1', 'Vv', 'sure');
end

function q = kestirici(q, Vv)
q.yuzKes = 'olay+yoklama';  q.yokOrta = 0.6;  q.vDurF = 10;
q.tOlc = true;  q.tPen = 0.54e-3;  q.tGec = 0.1e-3;  q.vKaynak = 'gozlemci';
q.yokBolge = Vv.bolge;
if ~isnan(Vv.esik), q.yokTorkEsik = Vv.esik; end
end

function r = kos2(p0, G, Vv, a, sc, aci, Y, ts)
% b2_harita/kos'un kestirici, taup = 0 hali (+ yoklama sayısı, B13, B12).
n = numel(aci);
Yf = Y;  if sc == 7, Yf = -Y; end
hedef = aci;  kay = abs(aci - 180) < G.eps_;  hedef(kay) = 180 - G.eps_*Yf(kay);
tg = p0.mgl*sind(hedef);  sF = sign(tg);  sF(sF == 0) = 1;
s0 = sign(sind(hedef));
q = p0;  q.Fc = G.ortam{a,2};  q.Fs = G.ortam{a,3};  q.adim = 1.1*Y;  q.nTohum = ts;
switch G.sen{sc}
    case 'a1 darbe',    q.dA = 0.05*sF;  q.df = 25;  q.dT0 = G.tD;  q.dT = G.tD + 0.02;
    case 'a2 yük 0,02', q.dB = 0.02*sF;  q.dBT0 = G.tD;
    case 'a2 yük 0,06', q.dB = 0.06*sF;  q.dBT0 = G.tD;
    case 'b salınım',   q.dA = 0.01*ones(1,n);  q.df = 1;  q.dT0 = G.tD;  q.dT = Inf;
    case 'c yaklaşma',  W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
    case 'd yön değ.',  W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
end
if sc >= 6, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
q.yuz0 = s0;  q = kestirici(q, Vv);
o = kol_benzetim(q, hedef, G.kpv*ones(1,n));
sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
r.e = mean(sap(son,:), 1);  r.emax = max(abs(sap(son,:)), [], 1);
r.h7 = abs(r.e) <= 0.5 & r.emax <= 1;
r.App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
r.urms = sqrt(mean(o.u(son,:).^2, 1));
r.yok = o.yokSay;
r.b13 = rad2deg(o.yokKol);  if any(sc == [2 3 4 5]), r.b13(:) = NaN; end   % bozucu kolu oynatıyor
gy = sign(o.delta).*(abs(o.delta) >= q.r);  tB = 0.5;  if sc == 5, tB = G.tD; end
tm = gy ~= 0 & o.t >= tB;
r.b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
end
