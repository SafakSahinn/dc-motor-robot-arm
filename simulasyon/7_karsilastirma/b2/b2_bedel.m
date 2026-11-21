function b2_bedel
% B2_BEDEL  Mekanik ön yükün bedeli: hareket profillerinde akım, enerji, izleme ve salınım.
% Tesis b2_kurulum ile aynı; motorun elektrik tarafı açık (p.motorElk = 3, akım döngüsü 500 Hz,
%   DRV8874 akım sınırı, 12 V; akimW yerine). Kayıt p.kayitEk (motor hızı, akım, gerilim).
% Profiller (son hedef aci; geliş yönü Y):
%   P1 basamak 30° : başlangıç hedef - 30 Y, referans basamak
%   P2 rampa 30°   : referans 30°'yi 10°/s ile alır (3 s), durur
%   P3 c yaklaşma  : B1'deki gibi 5°, 2°/s
% Açılar {135 200 225 270}° x 2 yön x taup ızgarası x 3 tohum; ortamlar b2_kurulum'daki 6 ortam.
% Kontrolcü: disli_tablo (tüm taup) ve kestirici (tüm taup; anlamlı satırı taup = 0).
% Ölçütler: hareket penceresi [0, Thar] ve tutma penceresi (son 1 s):
%   Irms_har, Irms_tut [A], Itepe [A], E_har [J] = int V i dt (sürücüden çekilen, geri besleme
%   eksi), Ecu_har [J] = int Ra i^2 dt, Ts05 [s] (|e| <= 0,5°'de kalıcı oturma), e_son [°],
%   App [°] (son 3 s tepeden tepeye), H7.
% Çıktı: b2_bedel.mat, b2_bedel_log.txt
kok = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(kok, fullfile(kok, '4a_ghaffari'));
cd(fileparts(mfilename('fullpath')));
[p0, G] = b2_kurulum();
p0 = rmfield(p0, 'akimW');  p0.motorElk = 3;  p0.kayitEk = true;  p0.dec = 10;
Vs = 12;  Km = Vs/(333*2*pi/60);  Ra = Km*Vs/0.49;
aci = [135 200 225 270];  prof = {'P1 basamak 30', 'P2 rampa 30', 'P3 c yaklaşma'};  Thar = [3 4 4];
[TH, TP, Yv, Bv] = ndgrid(aci, G.taup, [1 -1], G.tohum);
TH = TH(:)';  TP = TP(:)';  Yv = Yv(:)';  Bv = Bv(:)';  n = numel(TH);
B = struct([]);  t0 = tic;
for a = 1:size(G.ortam,1)
 for pr = 1:numel(prof)
  for m = 1:2
    ktl = G.ktl{m};
    hedef = TH;  kay = abs(TH - 180) < G.eps_;  hedef(kay) = 180 - G.eps_*Yv(kay);
    tg = p0.mgl*sind(hedef);  s0 = sign(sind(hedef));
    q = p0;  q.Fc = G.ortam{a,2};  q.Fs = G.ortam{a,3};
    Kp = G.KpOran*q.Ks*(TP > 0);
    q.onYuk = 1;  q.taup = TP;  q.Kp = Kp;  q.muP = G.ortam{a,4};
    switch pr
        case 1, q.adim = 30*Yv;
        case 2, q.adim = 0;  W = [hedef - 30*Yv; hedef];  tk = [0 3];
        case 3, q.adim = 0;  W = [hedef - 5*Yv; hedef];  tk = [0 2.5];
    end
    if pr >= 2, q.refYol = @(t) deg2rad(interp1(tk, W, min(t, tk(end)))); end
    O = cell(1, numel(G.tohum));
    for ts = G.tohum
        j = Bv == ts;  qq = q;
        for f = {'taup','Kp','adim'}, if numel(qq.(f{1})) == n, qq.(f{1}) = qq.(f{1})(j); end, end
        if pr >= 2, Wj = W(:,j);  qq.refYol = @(t) deg2rad(interp1(tk, Wj, min(t, tk(end)))); end
        qq.nTohum = ts;
        if m == 1
            qq.ofset = b2_disli_ofset(tg(j), TP(j), Kp(j), q.r, q.Ks, s0(j));
        else
            qq.yuz0 = s0(j);  qq.yuzKes = 'olay+yoklama';  qq.yokOrta = 0.6;  qq.vDurF = 10;
            qq.tOlc = true;  qq.tPen = 0.54e-3;  qq.tGec = 0.1e-3;  qq.vKaynak = 'gozlemci';  qq.elkV = 'kontrol';
        end
        o = kol_benzetim(qq, hedef(j), G.kpv*ones(1,nnz(j)));
        dt = o.t(2) - o.t(1);  har = o.t <= Thar(pr);  son = o.t > o.t(end) - 1;  s3 = o.t > o.t(end) - 3;
        sap = rad2deg(o.th) - hedef(j);
        r.Irms_har = sqrt(mean(o.i(har,:).^2, 1));  r.Irms_tut = sqrt(mean(o.i(son,:).^2, 1));
        r.Itepe = o.iTepe;  r.E_har = sum(o.V(har,:).*o.i(har,:), 1)*dt;  r.Ecu_har = sum(Ra*o.i(har,:).^2, 1)*dt;
        disari = abs(sap) > 0.5;  ilk = zeros(1, size(sap,2));
        for c = 1:size(sap,2)
            k = find(disari(:,c), 1, 'last');  if isempty(k), k = 0; end
            if k == size(sap,1), ilk(c) = NaN; else, ilk(c) = k*dt; end
        end
        r.Ts05 = ilk;  r.e_son = mean(sap(son,:), 1);  r.emax = max(abs(sap(son,:)), [], 1);
        r.h7 = abs(r.e_son) <= 0.5 & r.emax <= 1;
        r.App = max(rad2deg(o.th(s3,:))) - min(rad2deg(o.th(s3,:)));
        r.Vdoy = o.Vdoy;
        O{ts} = r;
    end
    k = numel(B) + 1;
    B(k).ortam = G.ortam(a,:);  B(k).prof = prof{pr};  B(k).ktl = ktl;
    for f = fieldnames(O{1})'
        v = zeros(1, n);
        for ts = G.tohum, v(Bv == ts) = O{ts}.(f{1}); end
        B(k).(f{1}) = v;
    end
    B(k).aci = TH;  B(k).taup = TP;  B(k).yon = Yv;  B(k).tohum = Bv;
    fprintf('%s muP %.2f | %s | %s  (%.0f s)\n', G.ortam{a,1}, G.ortam{a,4}, prof{pr}, ktl, toc(t0));
  end
 end
end
save('b2_bedel.mat', 'B', 'aci', 'prof', 'Thar', 'G', 'Km', 'Ra');
end
