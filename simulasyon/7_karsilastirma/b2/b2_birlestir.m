function b2_birlestir
% B2_BIRLESTIR  b2_parca_*.mat dosyalarını birleştirir, özet logu yazar (b2_log.txt, b2_sonuc.mat).
% Bölümler:
%   1. Her ortam: kontrolcü x taup x senaryo H7 sayısı (hücre başına 108 açı x 2 yön x 3 tohum = 648).
%   2. Dişli tablosunun kaybettiği açı bantları (b salınım hariç senaryolar), kestirim ile:
%      bozucu d kolu öbür yüze iter <=> |mgl sin(th) + taup| < d (durağan model). d = 0,02 / 0,06 N m.
%   3. Tutma torku (temel, son 1 s RMS u) taup'a göre.
cd(fileparts(mfilename('fullpath')));
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'));
[p0, G] = b2_kurulum();
nO = size(G.ortam,1);  nS = numel(G.sen);
D = cell(nO, nS);
for is = 1:nO*nS
    f = sprintf('b2_parca_%02d.mat', is);
    if ~isfile(f), error('%s yok', f); end
    s = load(f);  D{s.a, s.sc} = s.R;
end
save('b2_sonuc.mat', 'D', 'G');
fid = fopen('b2_log.txt', 'w');  temiz = onCleanup(@() fclose(fid));
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== b2_harita özeti, %s\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('D düzeneği, r %.2f°, K_s %g, Kp %g N m/rad, mgl %.3f N m. Hücre: 108 açı (90-357,5°) x 2 yön x 3 tohum = 648 koşu.\n', ...
    rad2deg(p0.r), p0.Ks, G.KpOran*p0.Ks, p0.mgl);
yaz('H7 (konum): son 1 s ort |e| <= 0,5° ve en büyük <= 1°. Toplam = b salınım hariç 6 senaryo (3888 koşu).\n');
H = @(Rm, tp) Rm.h7(Rm.taup == tp);
anaSen = find(~strcmp(G.sen, 'b salınım'));

% --- 1 ---
for a = 1:nO
    yaz('\n--- %s, muP %.2f ---\n', G.ortam{a,1}, G.ortam{a,4});
    yaz('%-12s %-6s', 'kontrolcü', 'taup');
    for sc = 1:nS, yaz(' | %-11s', G.sen{sc}); end
    yaz(' | toplam\n');
    for m = 1:numel(G.ktl)
        k = G.ktl{m};
        tpL = unique(D{a,1}.(k).taup);
        for tp = tpL
            yaz('%-12s %-6.2f', k, tp);  top = 0;  topN = 0;
            for sc = 1:nS
                h = H(D{a,sc}.(k), tp);
                yaz(' | %4d/%-6d', nnz(h), numel(h));
                if any(sc == anaSen), top = top + nnz(h);  topN = topN + numel(h); end
            end
            yaz(' | %4d/%d\n', top, topN);
        end
    end
end

% --- 2 ---
yaz('\n=== Dişli tablosunun kaybettiği açılar (hücrede en az bir koşu H7 kaybı), kestirimle ===\n');
yaz('Kestirim bandı |mgl sin th + taup| < d; durağan yüz değişimi th* (mgl sin th* = -taup).\n');
for a = 1:nO
    yaz('\n%s, muP %.2f\n', G.ortam{a,1}, G.ortam{a,4});
    for tp = G.taup
        if tp <= p0.mgl, ts = 180 + asind(tp/p0.mgl);  yaz('  taup %.2f  th* %.1f° / %.1f°\n', tp, ts, 540 - ts);
        else, yaz('  taup %.2f  th* yok (taup > mgl)\n', tp); end
        for sc = anaSen
            Rm = D{a,sc}.disli_tablo;  j = Rm.taup == tp;
            kay = unique(Rm.aci(j & ~Rm.h7));
            yaz('    %-12s kayıp %3d/648 | açılar: %s\n', G.sen{sc}, nnz(j & ~Rm.h7), bantlar(kay));
        end
        for d = [0.02 0.06]
            th = G.aci(abs(p0.mgl*sind(G.aci) + tp) < d);
            yaz('    %-12s kestirim d = %.2f: %s\n', '', d, bantlar(th));
        end
    end
end

% --- 3 ---
yaz('\n=== Tutma torku (temel, son 1 s RMS u, N m): ortalama / en büyük, açılar üzerinden ===\n');
yaz('%-24s', 'ortam');  for tp = G.taup, yaz(' | %-13s', sprintf('taup %.2f', tp)); end;  yaz('\n');
for a = 1:nO
    yaz('%-24s', sprintf('%s muP %.2f', G.ortam{a,1}, G.ortam{a,4}));
    Rm = D{a,1}.disli_tablo;
    for tp = G.taup, u = Rm.urms(Rm.taup == tp);  yaz(' | %.3f / %.3f', mean(u), max(u)); end
    yaz('\n');
end
yaz('Kestirici (taup = 0) aynı ölçüt:\n');
for a = [1 4]
    Rm = D{a,1}.kestirici;  u = Rm.urms(Rm.taup == 0);
    yaz('  %-11s %.3f / %.3f\n', G.ortam{a,1}, mean(u), max(u));
end
end

function s = bantlar(th)
% Ardışık (2,5° adımlı) açıları aralık olarak yazar.
if isempty(th), s = '-'; return; end
th = sort(th);  k = [0 find(diff(th) > 2.5 + 1e-9) numel(th)];  c = cell(1, numel(k)-1);
for i = 1:numel(k)-1
    a = th(k(i)+1);  b = th(k(i+1));
    if a == b, c{i} = sprintf('%g', a); else, c{i} = sprintf('%g-%g', a, b); end
end
s = strjoin(c, ', ');
end
