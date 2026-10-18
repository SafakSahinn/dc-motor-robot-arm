% INCE_TARAMA  Gerçekçi modelde 0-30 ve 150-180 derece arası 1 derecelik adımla:
% boşluk salınımının (sınıf 2-3) hangi açıya kadar sürdüğü.
ac  = [0:1:30, 150:1:180];
wcs = 10:5:50;
[AC, WC] = meshgrid(ac, wcs);
for sev = {'surtunme','gercekci'}
    c = cell(1,2); k = 0;
    for adim = [1 20]
        k = k+1;  p = parametreler(sev{1});  p.adim = adim;
        o = kol_benzetim(p, AC(:)', WC(:)');
        c{k} = reshape(o.sinif, size(AC));
    end
    bos = (c{1}==2 | c{1}==3) | (c{2}==2 | c{2}==3);     % herhangi bir başlangıçta boşluk salınımı
    fprintf('\n[%s] boşluk salınımı olan en büyük açı (0 tarafı) / en küçük açı (180 tarafı)\n', sev{1});
    fprintf('%6s %10s %10s   %s\n','wc','0 tarafi','180 tarafi','satir (0..30 | 150..180), B=bosluk');
    for i = 1:numel(wcs)
        a0 = ac(ac<=30 & bos(i,:));  a1 = ac(ac>=150 & bos(i,:));
        m0 = '-'; if ~isempty(a0), m0 = sprintf('%g', max(a0)); end
        m1 = '-'; if ~isempty(a1), m1 = sprintf('%g', min(a1)); end
        satir = repmat('.',1,numel(ac)); satir(bos(i,:)) = 'B';
        fprintf('%6g %10s %10s   %s | %s\n', wcs(i), m0, m1, satir(1:31), satir(32:end));
    end
    save(sprintf('ince_tarama_%s.mat', sev{1}), 'ac', 'wcs', 'c', 'bos');
end
