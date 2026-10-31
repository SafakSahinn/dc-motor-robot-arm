function kok_neden_1b
% KOK_NEDEN_1B  Parça 1 doğrulaması: DF'nin iki kararlılık dediği, benzetimin salınımsız bulduğu
% 92 hücrede (kok_neden_1.mat) büyük sarsıntıdan sonra kalıcı çevrim var mı?
% Sarsıntı: kola dA sin(2 pi df t) yük torku, t < 1 s; df = DF çevrim frekansının medyanı.
% Sınıflandırma sarsıntı bittikten 1 s sonrasından (zorlanmış cevap karışmasın).
% Ayrıca kontrol: benzetimde zaten salınımlı ve DF'de de çevrimli hücreler aynı sarsıntıyla
% salınımda kalmalı (sarsıntı yöntemi çevrimi bozmuyor mu).
addpath(fileparts(fileparts(mfilename('fullpath'))));
B = load('yercekimli_D.mat');  K = load('kok_neden_1.mat');  p = B.p;
kp = B.rgs.^2*p.Ks/p.KV;
[AC, KP] = meshgrid(B.ac, kp);
f0 = median(K.y.f(K.uy));
p.adim = 0.2;  p.T = 8;  p.df = f0;  p.dT = 1;
opt = struct('A_min', 0.05, 'A_max', 30, 'T_at', 2);
fid = fopen('kok_neden_log.txt', 'a');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('\n=== Parça 1b: uyuşmayan hücrelerde sarsıntı (D, %s), %.2f Hz, t < 1 s\n', datestr(now, 'yyyy-mm-dd HH:MM'), f0);
idx = find(K.uy);
for dA = [0.05 0.10 0.20]
    p.dA = dA;
    o = kol_benzetim(p, AC(idx)', KP(idx)');
    r = rejim_sinifla(o.t, rad2deg(o.th) - AC(idx)', opt);
    c = r.sinif;
    yaz('  dA %.2f N m: %d hücre -> denge/sönümlü %d, kalıcı çevrim %d, kararsız %d, düzensiz %d; çevrim frekansı medyan %.2f Hz\n', ...
        dA, numel(idx), sum(c <= 1), sum(c == 3), sum(c == 4), sum(c == 5), median(r.f(c == 3)));
    if dA == 0.10, c10 = c; end
end
% kalan (sönen) hücreler nerede: açı, r_gs
son = idx(c10 <= 1);
if ~isempty(son)
    yaz('  dA 0,10''da sönen hücreler (açı/r_gs): %s\n', strjoin(arrayfun(@(i) sprintf('%g/%.2f', AC(i), B.rgs(KP(i)==kp)), son', 'uni', 0), ' '));
end
% kontrol: benzetimde de DF'de de çevrim olan hücrelerden 30'u
kon = find(K.sal & K.y.sinif == 'C');  kon = kon(round(linspace(1, numel(kon), min(30, numel(kon)))));
p.dA = 0.10;
o = kol_benzetim(p, AC(kon)', KP(kon)');
r = rejim_sinifla(o.t, rad2deg(o.th) - AC(kon)', opt);
yaz('  kontrol (her ikisinde çevrimli %d hücre, dA 0,10): kalıcı çevrim %d, diğer %d\n', numel(kon), sum(r.sinif == 3), sum(r.sinif ~= 3));
fclose(fid);
end
