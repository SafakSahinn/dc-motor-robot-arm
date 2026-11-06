function belirsiz_bant
% BELIRSIZ_BANT  180° çevresinde kolun yanlış yüze düştüğü bandı ince tarar.
% Motor tarafı P-PI + ofset (yüz = sign(sin th_ref)), sürtünmeli ikiz (Fc 0,04 Fs 0,06),
% kol hedefe iki yönden ve iki başlangıç uzaklığından gelir (1° ve 5°), enkoder ideal / 0,27°.
% Kaydedilen: son yüz doğru mu, yüz kaç kez değişti (devrilme olayı), son 1 s sapma,
% son 1 s motor torku u. Ayrıca devrilme anında motor tarafında iz var mı diye
% devrilen bir koşunun zaman serisi belirsiz_bant.mat'a yazılır.
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Fc = 0.04;  p0.Fs = 0.06;  p0.Tan = 6;
ac = 170:0.25:180;  kpv = 0.50^2*p0.Ks/p0.KV;
s = ones(size(ac));                         % 170–180°: yerçekimi yüzü +1 (180'de seçim +1)
th = deg2rad(ac);
of = s*p0.r + p0.mgl*sin(th)/p0.Ks;
kosu = {'ideal, 1° alttan', 0, 1;  'ideal, 1° üstten', 0, -1;  'ideal, 5° alttan', 0, 5;
        '0,27°, 1° alttan', 2*pi/1320, 1;  '0,27°, 1° üstten', 2*pi/1320, -1;  '0,27°, 5° alttan', 2*pi/1320, 5};
fid = fopen('belirsiz_bant_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== belirsiz_bant, %s, D, r_gs 0,50, r %.2f°, mgl %.3f, Fc %.2f Fs %.2f\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), p0.mgl, p0.Fc, p0.Fs);
yaz('Her satır bir açı; sütunlar koşular. Hücre: Y = doğru yüz, X = yanlış yüz; parantezde son |e| [°]\n');
yaz('Kolu yüzde tutan yerçekimi torku mgl sin(180-th) [N m] son sütunda (Fc ile karşılaştır)\n\n');
YZ = zeros(size(kosu,1), numel(ac));  EE = YZ;  GC = YZ;
for k = 1:size(kosu,1)
    p = p0;  p.qM = kosu{k,2};  p.adim = kosu{k,3};  p.ofset = of;
    o = kol_benzetim(p, ac, kpv*ones(size(ac)));
    son = o.t > o.t(end)-1;
    dl = mean(o.delta(son,:), 1);  yuz = sign(dl).*(abs(dl) >= 0.999*p0.r);
    YZ(k,:) = yuz == s;  EE(k,:) = mean(rad2deg(o.th(son,:)), 1) - ac;  GC(k,:) = o.gecis;
    if k == 1
        j = find(~YZ(k,:), 1);                 % ilk devrilen açı: zaman serisini sakla
        if ~isempty(j)
            iz = struct('aci', ac(j), 't', o.t, 'th', rad2deg(o.th(:,j)), 'delta', rad2deg(o.delta(:,j)), ...
                        'u', o.u(:,j), 'tau_s', o.tau_s(:,j));
            save('belirsiz_bant.mat', 'iz');
        end
    end
end
yaz('  açı  | %s | tutma torku\n', strjoin(cellfun(@(c) sprintf('%-17s', c), kosu(:,1)', 'uni', 0), ' '));
for j = 1:numel(ac)
    h = arrayfun(@(k) sprintf('%-17s', sprintf('%s (%.2f)', char('X' + YZ(k,j)*('Y'-'X')), abs(EE(k,j)))), ...
        1:size(kosu,1), 'uni', 0);
    yaz('  %6.2f | %s | %.4f\n', ac(j), strjoin(h, ' '), p0.mgl*sind(180-ac(j)));
end
for k = 1:size(kosu,1)
    yanlis = ac(~YZ(k,:));
    if isempty(yanlis), yaz('%s: yanlış yüz yok\n', kosu{k,1});
    else, yaz('%s: yanlış yüz açıları %s\n', kosu{k,1}, mat2str(yanlis)); end
end
fclose(fid);
end
