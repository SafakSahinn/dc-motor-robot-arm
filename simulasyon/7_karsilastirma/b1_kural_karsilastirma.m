function b1_kural_karsilastirma
% B1_KURAL_KARSILASTIRMA  Komut tabanlı yüz kuralları (önceki patentler) ile yalnız motor sinyalli
% yüz kestiricinin (olay+yoklama) karşılaştırılması, 179-181°.
% Yöntemler (hepsi aynı ofset tablosu: s*r + mgl sin(th_ref)/Ks, aynı rampa 0,5 s):
%   tablo        : s = sign(sin th_hedef) sabit (yerçekimi işareti; Toyoda kuralının eşik = 0 hali)
%   panasonic    : WO2026074901A1 türü, s = sign(hız komutu) (|tau_g| küçükken), ölü bant kuralV
%   toyoda       : JPH07200018A türü, s = sign(tau_g), küçükse dönüş yönü sign(motor hızı)
%   lenze        : US12259034B2 türü, tork sıfır geçişi, s = sign(u), histerezis kuralU
%   olay+yok     : bizim kestirici (ikiz_dogrula.m'nin kanonik ayarı: 1 kHz, AS5600 motor milinde,
%                  gecikme + gürültü, INA228 torku, gözlemci hızı)
%   ust_sinir    : ikizin gerçek yüzü (hile, yalnız referans)
% Taban kurallar kendi lehlerine: ideal motor hızı görürler (bizimki gözlemci hızı), ölü bant /
% histerezis üç değerle taranır, en iyisi özetlenir.
% Senaryolar (7 istek x 2 geliş yönü = 14 koşu her biri, T = 8 s):
%   temel   : hedefe ±1,1° uzaktan basamak, bozucu yok
%   a1 darbe: t = 3 s'de kola 180°'ye doğru 0,05 N m, 20 ms yarım sinüs
%   a2 yük  : t = 3 s'den sonra kola sabit 0,02 N m, kolu öbür yüze iten yönde (doğru son yüz = -s0)
%   b salınım: t = 3 s'den sonra kola 0,01 N m, 1 Hz sinüs (yerçekimi torkundan büyük; yüz değişir,
%             komut yönü değişmez). Son yüz tanımsız: H7 yok, B12 ve genlik
%   c yaklaşma: referans hedefin 5° gerisinden 2°/s rampayla gelip durur
%   d yön değiştirme: referans hedefi 1,5° aşar, geri döner (2°/s), durur
% 180°'ye yakın isteklerde hedef kaydırma kuralı SON yaklaşma yönüne göre (179,5 / 180,5).
kok = fileparts(fileparts(mfilename('fullpath')));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 10;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.akimW = 2*pi*500;
nAS = deg2rad(0.043)/p0.N;
kpv = 0.50^2*p0.Ks/p0.KV;  eps_ = 0.5;  tD = 3;

istek = [179 179.25 179.75 180 180.25 180.75 181];
[I, Y] = ndgrid(istek, [1 -1]);  I = I(:)';  Y = Y(:)';  n = numel(I);
sen = {'temel', 'a1 darbe', 'a2 yük', 'b salınım', 'c yaklaşma', 'd yön değ.'};
yt = {'tablo', 'panasonic', 'toyoda', 'lenze', 'olay+yok', 'ust_sinir'};
izgara = {[], [0.01 0.05 0.2], [0.01 0.05 0.2], [0.005 0.01 0.03], [], []};   % kuralV / kuralU
sur = {'sürtünmeli', 0.04, 0.06; 'sürtünmesiz', 0, 0};
tohum = 1:3;

fid = fopen('b1_log.txt', 'w');
yaz = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];
yaz('=== b1_kural_karsilastirma, %s, D, r_gs 0,50, r %.2f°, mgl %.3f N m\n', datestr(now,'yyyy-mm-dd HH:MM'), rad2deg(p0.r), p0.mgl);
yaz('Her senaryo 14 koşu (7 istek x 2 yön) x %d tohum (AS5600 gürültüsü). H7: son 1 s |e| <= 0,5°, en büyük <= 1°, son yüz doğru.\n', numel(tohum));
yaz('B12: kol temastayken s^ = gerçek yüz oranı (t >= 0,5 s; b''de t >= 3 s). App: son 3 s kol tepeden tepeye [°]. avl: son 3 s s^ değişimi.\n\n');

R = struct([]);
for a = 1:size(sur,1)
 for sc = 1:numel(sen)
  Yf = Y;  if sc == 6, Yf = -Y; end                % son yaklaşma yönü
  hedef = I;  kay = abs(I - 180) < eps_;  hedef(kay) = 180 - eps_*Yf(kay);
  s0 = sign(sind(hedef));  sDog = s0;
  q = p0;  q.Fc = sur{a,2};  q.Fs = sur{a,3};  q.yuz0 = s0;  q.adim = 1.1*Y;
  switch sc
      case 2, q.dA = 0.05*sign(180 - hedef);  q.df = 25;  q.dT0 = tD;  q.dT = tD + 0.02;
      case 3, q.dB = 0.02*s0;  q.dBT0 = tD;  sDog = -s0;
      case 4, q.dA = 0.01*ones(1,n);  q.df = 1;  q.dT0 = tD;  q.dT = Inf;  sDog = nan(1,n);
      case 5, W = [hedef - 5*Yf; hedef];  tk = [0 2.5];
      case 6, W = [hedef + 3*Yf; hedef - 1.5*Yf; hedef];  tk = [0 2.25 3];
  end
  if sc >= 5, q.adim = 0;  q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
  for m = 1:numel(yt)
   pv = izgara{m};  if isempty(pv), pv = NaN; end
   for g = 1:numel(pv)
    for ts = tohum
      p = q;  p.nM = nAS;  p.nTohum = ts;
      switch yt{m}
          case 'tablo',     p.ofset = s0*p.r + p.mgl*sind(hedef)/p.Ks;
          case 'panasonic', p.yuzKural = 'panasonic';  p.kuralV = pv(g);
          case 'toyoda',    p.yuzKural = 'toyoda';     p.kuralV = pv(g);
          case 'lenze',     p.yuzKural = 'lenze';      p.kuralU = pv(g);
          case 'olay+yok',  p.yuzKes = 'olay+yoklama';  p.yokOrta = 0.6;  p.vDurF = 10;
                            p.tOlc = true;  p.tPen = 0.54e-3;  p.tGec = 0.1e-3;  p.vKaynak = 'gozlemci';
          case 'ust_sinir', p.ofsetYuz = 'anlik';
      end
      o = kol_benzetim(p, hedef, kpv*ones(1,n));
      sap = rad2deg(o.th) - hedef;  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
      gy = sign(o.delta).*(abs(o.delta) >= p0.r);
      yuzS = sign(sum(gy(son,:), 1));
      k = numel(R) + 1;
      R(k).sur = sur{a,1};  R(k).sen = sen{sc};  R(k).yontem = yt{m};  R(k).par = pv(g);  R(k).tohum = ts;
      R(k).e = mean(sap(son,:), 1);  R(k).emax = max(abs(sap(son,:)), [], 1);
      R(k).h7 = abs(R(k).e) <= 0.5 & R(k).emax <= 1 & yuzS == sDog;
      R(k).App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
      tB = 0.5;  if sc == 4, tB = tD; end
      tm = gy ~= 0 & o.t >= tB;
      if isfield(o, 'shat')
          R(k).b12 = sum(tm & o.shat == gy, 1)./max(sum(tm, 1), 1);
          R(k).avl = sum(abs(diff(o.shat(s3,:))) > 0, 1);
      elseif strcmp(yt{m}, 'tablo')
          R(k).b12 = sum(tm & gy == s0, 1)./max(sum(tm, 1), 1);  R(k).avl = zeros(1,n);
      else
          R(k).b12 = nan(1,n);  R(k).avl = o.yuzDegisAn;
      end
      if isfield(o, 'yokKol'), R(k).b13 = rad2deg(o.yokKol); else, R(k).b13 = nan(1,n); end
      if sc == 2 || sc == 3 || sc == 4, R(k).b13(:) = NaN; end   % bozucu kolu oynatıyor, yoklama değil
      fprintf('.');
    end
   end
  end
 end
end
fprintf('\n');
save('b1_sonuc.mat', 'R', 'sen', 'yt', 'izgara', 'sur', 'tohum', 'istek');

% --- Ayrıntılı tablo: her yöntem/parametre, senaryo başına H7 (3 tohum toplamı / 42) ve B12 ort ---
yaz('%-11s %-10s %-13s', 'sürtünme', 'yöntem', 'parametre');
for sc = 1:numel(sen), yaz(' | %-15s', sen{sc}); end
yaz(' | toplam H7\n');
yaz('%37s', '');  for sc = 1:numel(sen), yaz(' | %-15s', 'H7   B12  App'); end;  yaz('\n');
anah = unique(arrayfun(@(r) sprintf('%s|%s|%g', r.sur, r.yontem, r.par), R, 'uni', 0), 'stable');
ozet = struct([]);
for u = 1:numel(anah)
    pr = strsplit(anah{u}, '|');
    yaz('%-11s %-10s %-13s', pr{1}, pr{2}, pr{3});
    top = 0;  topN = 0;  b12t = [];
    for sc = 1:numel(sen)
        kk = strcmp({R.sur}, pr{1}) & strcmp({R.yontem}, pr{2}) & arrayfun(@(r) isequaln(r.par, str2double(pr{3})), R) & strcmp({R.sen}, sen{sc});
        h = [R(kk).h7];  b = [R(kk).b12];  A = [R(kk).App];
        if sc == 4, hs = '  - '; else, hs = sprintf('%2d/%d', nnz(h), numel(h));  top = top + nnz(h);  topN = topN + numel(h); end
        if all(isnan(b)), bs = '  -  '; else, bs = sprintf('%.2f', mean(b, 'omitnan'));  b12t = [b12t b]; end %#ok<AGROW>
        yaz(' | %s %s %4.2f', hs, bs, max(A));
    end
    yaz(' | %3d/%d\n', top, topN);
    ozet(u).sur = pr{1};  ozet(u).yontem = pr{2};  ozet(u).par = str2double(pr{3});  ozet(u).h7 = top;  ozet(u).N = topN;
    ozet(u).b12 = mean(b12t, 'omitnan');
end

% --- Özet: her taban kuralın en iyi parametresi (toplam H7, eşitlikte B12) ---
yaz('\nÖzet (taban kurallar en iyi parametreyle; H7 temel+a1+a2+c+d, %d koşu):\n', topN);
for a = 1:size(sur,1)
    for m = 1:numel(yt)
        j = find(strcmp({ozet.sur}, sur{a,1}) & strcmp({ozet.yontem}, yt{m}));
        [~, en] = max([ozet(j).h7] + 1e-3*[ozet(j).b12]);  j = j(en);
        yaz('  %-11s %-10s par %-6g | H7 %3d/%d | B12 ort %s\n', ozet(j).sur, ozet(j).yontem, ozet(j).par, ozet(j).h7, ozet(j).N, ...
            num2str(ozet(j).b12, '%.3f'));
    end
end

% --- olay+yok: B13 ve geçemeyenler ---
for a = 1:size(sur,1)
    kk = strcmp({R.sur}, sur{a,1}) & strcmp({R.yontem}, 'olay+yok');
    yaz('\n%s olay+yok B13 en çok: %.2f°\n', sur{a,1}, max([R(kk).b13], [], 'omitnan'));
    for k = find(kk)
        if strcmp(R(k).sen, 'b salınım'), continue; end
        j = find(~R(k).h7);
        if ~isempty(j)
            yaz('  geçemeyen %s tohum %d: %s\n', R(k).sen, R(k).tohum, strjoin(arrayfun(@(jj) sprintf('%.2f/%s e %+.2f', ...
                I(jj), char('a' + (Y(jj) < 0)*('u'-'a')), R(k).e(jj)), j, 'uni', 0), '; '));
        end
    end
end
fclose(fid);
end
