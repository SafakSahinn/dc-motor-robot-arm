function acik_teshis
% ACIK_TESHIS  B2'de kestiricinin (olay+yoklama, taup = 0, dişlisiz) kaybettiği koşuların teşhisi.
%   1) b2_parca_*.mat'ten kayıp hücreleri listeler (sürtünmeli ve sürtünmesiz, muP 0).
%   2) Her kayıp koşuyu b2_harita'nın ayarıyla yeniden koşar ve kestiricinin iç kayıtlarını
%      (s^, d^, gerçek yüz, yoklama sayısı) özetler; net durağan tork mgl sin(hedef) + d ile karşılaştırır.
%   Çıktı: acik_teshis_log.txt, acik_teshis.mat (zaman serileri).
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '7_karsilastirma', 'b2'));
cd(fileparts(mfilename('fullpath')));
diary off; if isfile("acik_teshis_log.txt"), delete("acik_teshis_log.txt"); end
diary("acik_teshis_log.txt");
fprintf("=== acik_teshis %s ===\n", string(datetime("now")));
[p0, G] = b2_kurulum();
b2d = fullfile(kok, '7_karsilastirma', 'b2');

K = [];   % [a sc aci yon tohum e emax App]
for a = [1 4]
    for sc = 1:numel(G.sen)
        s = load(fullfile(b2d, sprintf('b2_parca_%02d.mat', sub2ind([6 7], a, sc))));
        R = s.R.kestirici;  j = find(R.taup == 0 & ~R.h7);
        for k = j
            K(end+1,:) = [a sc R.aci(k) R.yon(k) R.tohum(k) R.e(k) R.emax(k) R.App(k)]; %#ok<AGROW>
        end
    end
end
fprintf("Kayıp koşular (kestirici, taup = 0): %d\n", size(K,1));
fprintf("%-12s %-12s %7s %4s %5s %8s %8s %8s\n", "ortam", "senaryo", "açı", "yön", "tohum", "e °", "emax °", "App °");
for i = 1:size(K,1)
    fprintf("%-12s %-12s %7.1f %+4d %5d %+8.3f %8.3f %8.3f\n", G.ortam{K(i,1),1}, G.sen{K(i,2)}, K(i,3:8));
end

% Benzersiz (ortam, senaryo, açı, yön) durumlarını tohum 1 ile yeniden koş, iç kayıtları incele
[~, iu] = unique(K(:,1:4), 'rows', 'stable');
T = struct([]);
fprintf("\n--- Yeniden koşu (tohum = ilk kayıp tohum), son 3 s özeti ---\n");
fprintf("%-12s %-12s %6s %4s | %8s %8s | %6s %6s %6s | %7s %7s %7s | %5s %5s\n", "ortam", "senaryo", "açı", "yön", ...
    "tg N m", "net N m", "s^ son", "gerçek", "s0", "s^ değ.", "gy değ.", "d^ ort", "yokl.", "App");
for i = iu'
    a = K(i,1);  sc = K(i,2);  aci = K(i,3);  Y = K(i,4);  ts = K(i,5);
    [q, hedef, sF, s0, dY] = kur(p0, G, a, sc, aci, Y, ts);
    q.dec = 1;
    o = kol_benzetim(q, hedef, G.kpv);
    s3 = o.t > o.t(end) - 3;
    gy = sign(o.delta).*(abs(o.delta) >= q.r);       % gerçek yüz (boşlukta 0)
    sh = o.shat(:);  dh = o.dhat(:);
    tg = p0.mgl*sind(hedef);
    net = tg + dY;                                    % dış yükle net durağan tork (yük sF yönünde)
    nSh = nnz(diff(sh(s3)) ~= 0);  g3 = gy(s3);  g3 = g3(g3 ~= 0);  nGy = nnz(diff(g3) ~= 0);
    App = max(rad2deg(o.th(s3))) - min(rad2deg(o.th(s3)));
    fprintf("%-12s %-12s %6.1f %+4d | %+8.4f %+8.4f | %+6d %+6d %+6d | %7d %7d %+7.4f | %5d %5.2f\n", ...
        G.ortam{a,1}, G.sen{sc}, aci, Y, tg, net, sh(end), sign(sum(gy(o.t > o.t(end)-1))), s0, ...
        nSh, nGy, mean(dh(s3)), o.yokSay, App);
    T(end+1).a = a;  T(end).sc = sc;  T(end).aci = aci;  T(end).Y = Y;  T(end).t = o.t; %#ok<AGROW>
    T(end).th = rad2deg(o.th) - hedef;  T(end).gy = gy;  T(end).sh = sh;  T(end).dh = dh;
    T(end).u = o.u;  T(end).hedef = hedef;  T(end).sF = sF;  T(end).dY = dY;
end
save("acik_teshis.mat", "K", "T");
diary off;
end

function [q, hedef, sF, s0, dY] = kur(p0, G, a, sc, aci, Y, ts)
% b2_harita/kos ile aynı kurulum, kestirici, taup = 0, tek koşu.
Yf = Y;  if sc == 7, Yf = -Y; end
hedef = aci;  if abs(aci - 180) < G.eps_, hedef = 180 - G.eps_*Yf; end
tg = p0.mgl*sind(hedef);  sF = sign(tg);  if sF == 0, sF = 1; end
s0 = sign(sind(hedef));
q = p0;  q.Fc = G.ortam{a,2};  q.Fs = G.ortam{a,3};  q.adim = 1.1*Y;  q.nTohum = ts;
dY = 0;
switch G.sen{sc}
    case 'a1 darbe',    q.dA = 0.05*sF;  q.df = 25;  q.dT0 = G.tD;  q.dT = G.tD + 0.02;
    case 'a2 yük 0,02', q.dB = 0.02*sF;  q.dBT0 = G.tD;  dY = -0.02*sF;
    case 'a2 yük 0,06', q.dB = 0.06*sF;  q.dBT0 = G.tD;  dY = -0.06*sF;
    case 'b salınım',   q.dA = 0.01;  q.df = 1;  q.dT0 = G.tD;  q.dT = Inf;
    case 'c yaklaşma',  W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
    case 'd yön değ.',  W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
end
if sc >= 6, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
q.yuz0 = s0;  q.yuzKes = 'olay+yoklama';  q.yokOrta = 0.6;  q.vDurF = 10;
q.tOlc = true;  q.tPen = 0.54e-3;  q.tGec = 0.1e-3;  q.vKaynak = 'gozlemci';
end
