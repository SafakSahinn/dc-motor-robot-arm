function yuz_kestirici_as5600
% YUZ_KESTIRICI_AS5600  İş sırası (3) eki: AS5600 motor milinde, gerçekçi zamanlamayla.
% yuz_kestirici.m'nin 42 senaryosu ve H7 ölçütü; enkoder AS5600 (12 bit x N = 30, kol tarafında
% 0,0029°). yuz_kestirici.m'de kontrolcü ve kestirici 10 kHz'te (p.Ts = p.dt = 0,1 ms) çalışıyordu;
% ESP32 döngüsü 1 kHz. Burada sırayla eklenir:
%   10 kHz        : yuz_kestirici.m'deki AS5600 satırı (karşılaştırma)
%   1 kHz         : p.Ts = 1 ms; örnek sayısıyla verilen süreler (Nper 10 ms, yuzN 20 ms) aynı tutulur
%   + gecikme     : p.gM = 0,4 ms (SF = 11 filtresi 0,286 ms + iç örnekleme ~0,075 ms + I2C ~0,05 ms)
%   + gürültü     : p.nM = 0,043° RMS motor milinde (SF = 11, veri sayfası) -> kol tarafında /30
%   zor           : gecikme 1 ms (bir tam örnek) + gürültü x3
% Yöntemler: edilgen (taban), olay+yoklama (yuz_kestirici.m ayarı, rampa 0,5 s) ve olay+yok ayarlı
% (1 kHz için: p.yokOrta = 0,6, yoklamanın geri dönüşü başlangıcın biraz önünde durur; p.vDurF = 10 Hz,
% durgunluk kararı süzülmüş hız kestirimiyle, enkoder gürültüsü yoklamayı engellemesin).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;

istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y, B] = ndgrid(istek, [1 -1], 1:3);
I = I(:)';  Y = Y(:)';  B = B(:)';
hedef = I;  kay = abs(I - 180) < eps_;
hedef(kay) = 180 - eps_*Y(kay);
s0 = sign(sind(hedef));
yuz0 = s0;  yuz0(B == 3) = -s0(B == 3);
dA = 0.05*sign(180 - hedef).*(B == 2);
n = numel(hedef);  ac = hedef;

nAS = deg2rad(0.043)/p0.N;                         % kol tarafına indirgenmiş RMS gürültü
kos = {'10 kHz',          1e-4, 0,    0;
       '1 kHz',           1e-3, 0,    0;
       '1 kHz+gecikme',   1e-3, 4e-4, 0;
       '1 kHz+gec+gürültü', 1e-3, 4e-4, nAS;
       'zor (1 ms, 3x)',  1e-3, 1e-3, 3*nAS};
yt  = {'edilgen', 'olay+yoklama', 'olay+yok ayarlı'};
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
fid = fopen('yuz_kestirici_as5600_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== yuz_kestirici_as5600, %s, D, r_gs 0,50, AS5600 motor milinde (kol tarafında %.4f°)\n', ...
    datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.qM));
yaz('42 senaryo (yuz_kestirici.m ile aynı); H7: son 1 s |e| <= 0,5° (kaydırılmış hedefe), en büyük <= 1°, son yüz doğru.\n');
yaz('Gürültü 1x = %.4f° RMS kol tarafında (0,043° motor milinde). B12: temas varken s^ doğru oranı; B13: yoklama + 0,3 s\n', rad2deg(nAS));
yaz('kol hareketi (darbesiz senaryolar).\n\n');
yaz('%-11s %-18s %-15s | H7 geçen | en kötü |e| | B12 ort/en kötü | avl | B13 en çok | yoklama ort\n', 'sürtünme', 'koşu', 'yöntem');
for a = 1:size(sur,1)
 for c = 1:size(kos,1)
  for m = 1:numel(yt)
    p = p0;  p.Fc = sur{a,2};  p.Fs = sur{a,3};
    p.Ts = kos{c,2};  p.gM = kos{c,3};  p.nM = kos{c,4};
    p.Nper = round(0.01/p.Ts);  p.yuzN = round(0.02/p.Ts);
    p.adim = 1.1*Y;  p.dA = dA;  p.df = 25;  p.dT0 = tD;  p.dT = tD + 0.02;
    p.yuzKes = strrep(yt{m}, 'olay+yok ayarlı', 'olay+yoklama');  p.yuz0 = yuz0;
    if m == 3, p.yokOrta = 0.6;  p.vDurF = 10; end
    o = kol_benzetim(p, ac, kpv*ones(1,n));
    sap = rad2deg(o.th) - ac;  son = o.t > o.t(end)-1;
    gy = sign(o.delta).*(abs(o.delta) >= p0.r);
    yuzS = sign(sum(gy(son,:), 1));
    e = mean(sap(son,:), 1);  emax = max(abs(sap(son,:)), [], 1);
    h7 = abs(e) <= 0.5 & emax <= 1 & yuzS == s0;
    tm = gy ~= 0 & o.t >= 0.5;
    b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
    s3 = o.t > o.t(end) - 3;  avl = sum(abs(diff(o.shat(s3,:))) > 0, 1);
    if isfield(o, 'yokKol')
        b13 = rad2deg(o.yokKol);  b13(B == 2) = NaN;
        b13s = sprintf('%5.2f', max(b13, [], 'omitnan'));  ys = sprintf('%4.1f', mean(o.yokSay));
    else, b13s = '  -  ';  ys = '  - '; end
    yaz('%-11s %-18s %-15s | %2d/%2d    | %6.2f      | %5.3f/%5.3f     | %3d | %s      | %s\n', ...
        sur{a,1}, kos{c,1}, yt{m}, nnz(h7), n, max(abs(e)), mean(b12), min(b12), max(avl), b13s, ys);
    j = find(~h7);
    if ~isempty(j) && m >= 2
        bozAd = {'yok', 'darbe', 'yanlış s0'};
        h = arrayfun(@(jj) sprintf('%.2f>%.1f %s %s %+.2f', I(jj), hedef(jj), char('a' + (Y(jj) < 0)*('u'-'a')), ...
            bozAd{B(jj)}, e(jj)), j, 'uni', 0);
        yaz('      geçemeyen: %s\n', strjoin(h, '; '));
    end
    fprintf('.');
  end
 end
end
fprintf('\n');
fclose(fid);
end
