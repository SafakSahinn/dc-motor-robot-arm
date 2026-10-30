function secenekler(S)
% SECENEKLER  Düzenek seçenekleri A / B1 / B2 / C aynı ölçütlerle (P-PI, hız döngüsü w_a,
% 2r = 3°, ideal sensör; sensör etkileri 7c'de):
%  1) yerçekimsiz: benzetim / tam DF frekansı, kararsızlığın başladığı r_gs
%  2) yerçekimli açı x r_gs haritası (gerçek tork sınırıyla): rejim, başlangıç koşuluna bağlılık
%  3) tepe tork ve doyum oranı
% A : dengeli liste (JGB37 1:30, 20 g çubuk + 20 g uç), R = 0,17
% B1: A + dengelenmiş ek eylemsizlik, R = 1      B2: R = 2   (yerçekimi torku değişmez)
% C : JGB37 1:10 (aynı kol), R = 1,5; tork sınırı 0,49/3 (veri sayfasıyla doğrulanmalı)
% D : A + ağır uç kütlesi (R = 1 olacak kadar, ≈ 153 g): eylemsizlikle birlikte mgl de büyür
% secenekler({'D'}) yalnız verilenleri koşar; kayıt secenekler_<ad>.txt'ye eklenir.
addpath(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1, S = {'A','B1','B2','C','D'}; end
rgs = [0.3 0.5 0.7 0.9 1.1 1.3];
ac  = [0 10 20 30 45 60 90 135 180];               % hedef açı (0 = sarkık, 90 = yatay, 180 = dik)
bas = [0.2 1 5];                                   % başlangıç sapması [der]
sm  = '.sZCX?';                                    % denge, sönümlü, zorlanmış, çevrim, kararsız, düzensiz
fid = fopen('secenekler_log.txt','a');
R = struct();
for i = 1:numel(S)
    p = duzenek(S{i});
    wa = sqrt(p.Ks/p.JL);
    p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
    kp = rgs.^2*p.Ks/p.KV;
    yaz(fid, '=== %s: N = %d, J_M = %.2e, J_L = %.2e, R = %.2f, f_a = %.1f Hz, mgl = %.3f N m, Tmax = %.2f N m (mgl/Tmax = %.2f)\n', ...
        S{i}, p.N, p.JM, p.JL, p.JL/p.JM, wa/2/pi, p.mgl, p.Tmax, p.mgl/p.Tmax);
    % 1) yerçekimsiz, tork sınırı yok
    q = p;  q.mgl = 0;  q.Tmax = Inf;  q.adim = 1;
    o = kol_benzetim(q, zeros(size(kp)), kp);
    r = rejim_sinifla(o.t, rad2deg(o.th), struct('A_min',0.05,'A_max',30,'T_at',0.3));
    g = struct('Jm',p.JM,'Jle',p.JL,'kse',p.Ks,'cm',p.bM,'cle',p.bL,'Ti',1/p.KI,'wa',wa,'fa',wa/2/pi,'delta',p.r);
    d = ghaffari_df(g, kp, p.KV*ones(size(kp)));
    yaz(fid, '  yerçekimsiz  r_gs:   %s\n', num2str(rgs,'%7.2f'));
    yaz(fid, '               sınıf:  %s\n', sprintf('%7s', sm(r.sinif+1)));
    yaz(fid, '               f sim:  %s\n', num2str(r.f,'%7.2f'));
    yaz(fid, '               f DF:   %s\n', num2str(d.f_df,'%7.2f'));
    yaz(fid, '               sim/DF: %s\n', num2str(r.f./d.f_df,'%7.2f'));
    % 2-3) yerçekimli harita, gerçek tork sınırı
    [AC, KP] = meshgrid(ac, kp);
    C = zeros(numel(bas), numel(AC));  F = C;  A = C;  U = C;  D = C;
    for b = 1:numel(bas)
        p.adim = bas(b);
        o = kol_benzetim(p, AC(:)', KP(:)');
        y = rad2deg(o.th) - AC(:)';
        r = rejim_sinifla(o.t, y, struct('A_min',0.05,'A_max',30,'T_at',0.3));
        C(b,:) = r.sinif;  F(b,:) = r.f;  A(b,:) = r.A;
        U(b,:) = max(abs(o.u));  D(b,:) = mean(abs(o.u) >= 0.999*p.Tmax);
    end
    yaz(fid, '  yerçekimli harita (satır r_gs, sütun açı; büyük harf: üç başlangıçta aynı, * : başlangıca bağlı)\n');
    yaz(fid, '       açı: %s\n', sprintf('%5d', ac));
    for k = 1:numel(rgs)
        s = '';
        for j = 1:numel(ac)
            m = sub2ind(size(AC), k, j);  c = C(:,m);
            if all(c == c(1)), s = [s sprintf('%5s', sm(c(1)+1))]; %#ok<AGROW>
            else, s = [s sprintf('%5s', [sm(max(c)+1) '*'])]; end %#ok<AGROW>
        end
        yaz(fid, '  r_gs %.1f: %s\n', rgs(k), s);
    end
    cev = any(C == 3, 1);
    yaz(fid, '  çevrim frekansı aralığı %.1f-%.1f Hz, genlik %.2f-%.2f der; tepe tork %.2f N m (Tmax %.2f), doyumda geçen süre ort. %%%.0f, en çok %%%.0f\n\n', ...
        min(F(C==3)), max(F(C==3)), min(A(C==3)), max(A(C==3)), max(U(:)), p.Tmax, 100*mean(D(:)), 100*max(D(:)));
    R.(S{i}) = struct('p',p,'C',C,'F',F,'A',A,'U',U,'D',D,'AC',AC,'KP',KP,'cev',cev);
end
save(sprintf('secenekler_%s.mat', strjoin(S,'')), 'R', 'rgs', 'ac', 'bas');
fclose(fid);
end

function p = duzenek(ad)
p = parametreler('ideal');
p.N = 30;  Jrot = 4e-6;  p.Tmax = 0.49;
mRod = 0.020;  L = 0.15;  mTip = 0.020;
p.JL  = mRod*L^2/3 + mTip*L^2;
p.mgl = 9.81*(mRod*L/2 + mTip*L);
p.JM  = Jrot*p.N^2;
switch ad
    case 'B1', p.JL = 1*p.JM;                     % dengelenmiş ek eylemsizlik: mgl değişmez
    case 'B2', p.JL = 2*p.JM;
    case 'C',  p.N = 10;  p.JM = Jrot*p.N^2;  p.Tmax = 0.49/3;
    case 'D',  mTip = (p.JM - mRod*L^2/3)/L^2;   % J_L = J_M
               p.JL = mRod*L^2/3 + mTip*L^2;  p.mgl = 9.81*(mRod*L/2 + mTip*L);
end
p.r = deg2rad(1.5);
p.dt = 1e-4;  p.Ts = p.dt;  p.T = 8;  p.Tan = p.T;  p.dec = 5;
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
