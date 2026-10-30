function yercekimli_df_testleri
% YERCEKIMLI_DF_TESTLERI  yercekimli_df.m sağlamaları:
%  1) kapalı biçim n0, n1 = sayısal integral (rastgele a, b)
%  2) temas kopmuyorsa (a <= b - 1) n1 = 1, n0 = b - 1
%  3) b = 0'da n1 Ghaffari'nin denklem 10'u
%  4) beta = 0, kg = 0: frekans ve n_req ghaffari_df ile aynı (D düzeneği)
addpath(fileparts(fileparts(mfilename('fullpath'))));
dz = yercekimli_df('dz');
ok = true(1,4);
psi = linspace(0, 2*pi, 200001);  psi(end) = [];
rng(1);  e = 0;
for i = 1:200
    a = 10^(2*rand-1)*3;  b = 4*rand - 1;
    x = b + a*sin(psi);  y = (x-1).*(x>1) + (x+1).*(x<-1);
    [n0, n1] = dz(a, b);
    e = max(e, max(abs([n0 - mean(y), n1 - 2*mean(y.*sin(psi))/a])));
end
ok(1) = e < 1e-4;  fprintf('1) kapalı biçim - sayısal: en büyük fark %.1e\n', e);
[n0, n1] = dz(0.4, 1.5);  ok(2) = abs(n1-1) < 1e-12 && abs(n0-0.5) < 1e-12;
fprintf('2) a = 0,4, b = 1,5: n0 = %.6f (0,5), n1 = %.6f (1)\n', n0, n1);
x = [1.5 3 10];  ng = 1 - 2/pi*(asin(1./x) + sqrt(1-1./x.^2)./x);  n1 = arrayfun(@(a) nth(dz, a), x);
ok(3) = max(abs(n1-ng)) < 1e-12;  fprintf('3) b = 0: n1 = %s, Ghaffari dn. 10: %s\n', num2str(n1,'%.6f '), num2str(ng,'%.6f '));
p = secenek_duzenek('D');  wa = sqrt(p.Ks/p.JL);
p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
rgs = [0.3 0.5 0.7 0.9];  kp = rgs.^2*p.Ks/p.KV;
q = p;  q.mgl = 0;
d = yercekimli_df(q, 0, kp, 'kg', false);
g = ghaffari_df(struct('Jm',p.JM,'Jle',p.JL,'kse',p.Ks,'cm',p.bM,'cle',p.bL,'Ti',1/p.KI,'wa',wa,'fa',wa/2/pi,'delta',p.r), kp, p.KV*ones(size(kp)));
ok(4) = max(abs(d.f' - g.f_cr)./g.f_cr) < 1e-3 && max(abs(d.n_req' - g.n)./g.n) < 1e-3;
fprintf('4) f: %s | Ghaffari %s\n   n_req: %s | Ghaffari %s\n', num2str(d.f','%.3f '), num2str(g.f_cr,'%.3f '), num2str(d.n_req','%.4f '), num2str(g.n,'%.4f '));
fprintf('sonuç: %d/4\n', sum(ok));
end

function n1 = nth(dz, a)
[~, n1] = dz(a, 0);
end
