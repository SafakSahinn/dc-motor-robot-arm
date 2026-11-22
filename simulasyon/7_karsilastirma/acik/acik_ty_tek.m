function acik_ty_tek
% ACIK_TY_TEK  θ* hedef kaydırmanın 175° sürtünmesiz a2 0,02 koşusundaki davranışı (tek koşu, teşhis).
%   Kaydırmasız ve kaydırmalı; ayrıca kaydırma ELLE (yükü bilerek) hedefe verilmiş "kâhin" koşusu:
%   net torku tyMin'e çıkaracak kaydırma doğru verilse çevrim kalkar mı?
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'), fullfile(kok, '7_karsilastirma', 'b2'));
cd(fileparts(mfilename('fullpath')));
diary off; if isfile("acik_ty_tek_log.txt"), delete("acik_ty_tek_log.txt"); end
diary("acik_ty_tek_log.txt");
[p0, G] = b2_kurulum();
hedef = 175;  q = p0;  q.Fc = 0;  q.Fs = 0;  q.adim = 1.1;  q.nTohum = 1;  q.dec = 1;
q.dB = 0.02;  q.dBT0 = G.tD;  q.yuz0 = 1;
q.yuzKes = 'olay+yoklama';  q.yokOrta = 0.6;  q.vDurF = 10;
q.tOlc = true;  q.tPen = 0.54e-3;  q.tGec = 0.1e-3;  q.vKaynak = 'gozlemci';
tyMin = p0.mgl*sind(0.5);
for k = 1:6
    p = q;
    switch k
        case 1, ad = 'kaydırmasız';  hd = hedef;
        case 2, ad = 'θ* kaydırma';  hd = hedef;  p.thYildiz = true;
        case 3, n0 = p0.mgl*sind(hedef) - 0.02;  ad = 'kâhin (net = +tyMin)';
                hd = hedef + rad2deg((tyMin - n0)/(p0.mgl*cosd(hedef)));
        case 4, n0 = p0.mgl*sind(hedef) - 0.02;  ad = 'kâhin (net = +3 tyMin)';
                hd = hedef + rad2deg((3*tyMin - n0)/(p0.mgl*cosd(hedef)));
        case 5, ad = 'θ* arama';  hd = hedef;  p.thYildiz = true;  p.tyArama = true;
        case 6, ad = 'θ* arama, 185°';  hd = 185;  p.thYildiz = true;  p.tyArama = true;  p.dB = -0.02;  p.yuz0 = -1;
    end
    ist = hedef;  if k == 6, ist = 185; end
    o = kol_benzetim(p, hd, G.kpv);
    s3 = o.t > o.t(end) - 3;  son = o.t > o.t(end) - 1;
    gy = sign(o.delta).*(abs(o.delta) >= p.r);
    th = rad2deg(o.th);
    net = p0.mgl*sind(th(son)) - p.dB;
    fprintf('%-24s hedef %.3f° | son 1 s e (istenen) %+.3f° | App %.2f° | s^ değişimi %d | gerçek yüz değişimi %d | net tork ort %+.4f N m', ...
        ad, hd, mean(th(son)) - ist, max(th(s3)) - min(th(s3)), nnz(diff(o.shat(s3)) ~= 0), nnz(diff(gy(s3)) ~= 0), mean(net));
    if isfield(o, 'tyD'), fprintf(' | tyD %+.3f°', rad2deg(o.tyD)); end
    fprintf('\n');
end
diary off;
end
