function acik_birlestir
% ACIK_BIRLESTIR  acik_v*.mat → acik_log.txt (yoklama bölgesi varyantlarının karşılaştırması).
cd(fileparts(mfilename('fullpath')));
fid = fopen('acik_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
f = dir('acik_v*.mat');  [~, o] = sort(cellfun(@(s) sscanf(s, 'acik_v%d.mat'), {f.name}));  f = f(o);
S = arrayfun(@(x) load(x.name), f);
yaz('=== acik_birlestir, %s\n', datestr(now, 'yyyy-mm-dd HH:MM'));
yaz('Kestirici (olay+yoklama), yoklama bölgesi p.yokBolge varyantları. Dişlisiz (taup = 0).\n');
yaz('B2 ızgarası: hücre = 108 açı x 2 yön x 3 tohum = 648 koşu; toplam = b salınım hariç 6 senaryo (3888).\n');
yaz('B1 ızgarası: senaryo = 7 istek x 2 yön x 3 tohum = 42 koşu; toplam = b hariç 5 senaryo (210).\n\n');

sen = unique({S(1).B2.sen}, 'stable');  ort = unique({S(1).B2.ortam}, 'stable');
for a = 1:numel(ort)
    yaz('--- B2 ızgarası, %s ---\n%-12s', ort{a}, 'varyant');
    for s = 1:numel(sen), yaz(' | %-11s', sen{s}); end
    yaz(' | toplam    | yoklama ort/en çok | B13 en çok ° | RMS u ort N m | B12 b\n');
    for v = 1:numel(S)
        B = S(v).B2(strcmp({S(v).B2.ortam}, ort{a}));
        yaz('%-12s', S(v).Vv.ad);  top = 0;  N = 0;
        for s = 1:numel(sen)
            r = B(strcmp({B.sen}, sen{s}));  yaz(' | %4d/%-6d', nnz(r.h7), numel(r.h7));
            if ~strcmp(sen{s}, 'b salınım'), top = top + nnz(r.h7);  N = N + numel(r.h7); end
        end
        yk = [B.yok];  b13 = [B.b13];  ur = [B.urms];  rb = B(strcmp({B.sen}, 'b salınım'));
        yaz(' | %4d/%-4d | %5.2f / %-3d        | %6.2f       | %.4f        | %.3f\n', top, N, mean(yk), max(yk), ...
            max(b13, [], 'omitnan'), mean(ur), mean(rb.b12));
    end
    yaz('\n');
end

yaz('--- B2 ızgarası: kaybedilen koşular (b salınım hariç) ---\n');
for v = 1:numel(S)
    yaz('%s:', S(v).Vv.ad);  say = 0;
    for B = S(v).B2
        if strcmp(B.sen, 'b salınım'), continue; end
        j = find(~B.h7);
        if isempty(j), continue; end
        u = unique([B.aci(j)' B.yon(j)'], 'rows');
        for k = 1:size(u,1)
            m = j(B.aci(j) == u(k,1) & B.yon(j) == u(k,2));
            yaz('\n   %-11s %-11s %6.1f° yön %+d: %d tohum, e %+.2f°, App %.2f°', B.ortam, B.sen, u(k,1), u(k,2), ...
                numel(m), mean(B.e(m)), mean(B.App(m)));
            say = say + numel(m);
        end
    end
    if say == 0, yaz(' yok'); end
    yaz('\n');
end

yaz('\n--- Yoklama sayısının açıya göre dağılımı (B2, temel, ortalama yoklama/koşu) ---\n');
for a = 1:numel(ort)
    for v = 1:numel(S)
        B = S(v).B2(strcmp({S(v).B2.ortam}, ort{a}) & strcmp({S(v).B2.sen}, 'temel'));
        aci = unique(B.aci);  ya = arrayfun(@(x) mean(B.yok(B.aci == x)), aci);
        bnt = aci(ya > 0);
        if isempty(bnt), s = 'hiç'; else, s = sprintf('%d açıda (%.1f-%.1f° arası), açı başına en çok %.2f', numel(bnt), min(bnt), max(bnt), max(ya)); end
        yaz('%-11s %-12s yoklama: %s\n', ort{a}, S(v).Vv.ad, s);
    end
end

yaz('\n--- B1 ızgarası (179-181°) ---\n');
sen1 = unique({S(1).B1.sen}, 'stable');  sur = unique({S(1).B1.sur}, 'stable');
for a = 1:numel(sur)
    yaz('%s\n%-12s', sur{a}, 'varyant');
    for s = 1:numel(sen1), yaz(' | %-10s', sen1{s}); end
    yaz(' | toplam H7 | B12 ort | B13 en çok °\n');
    for v = 1:numel(S)
        B = S(v).B1(strcmp({S(v).B1.sur}, sur{a}));  yaz('%-12s', S(v).Vv.ad);  top = 0;  N = 0;
        for s = 1:numel(sen1)
            r = B(strcmp({B.sen}, sen1{s}));  h = [r.h7];
            if strcmp(sen1{s}, 'b salınım'), yaz(' | %-10s', '-');
            else, yaz(' | %3d/%-6d', nnz(h), numel(h));  top = top + nnz(h);  N = N + numel(h); end
        end
        yaz(' | %3d/%-5d | %.3f   | %.2f\n', top, N, mean([B.b12]), max([B.b13], [], 'omitnan'));
    end
end
fclose(fid);
end
