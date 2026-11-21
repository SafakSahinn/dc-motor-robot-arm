function [p0, G] = b2_kurulum()
% B2_KURULUM  B2 haritası ve bedel betiklerinin ortak düzeneği (B1 kanonik ayarı) ve ızgarası.
p0 = secenek_duzenek('D');  wa = sqrt(p0.Ks/p0.JL);
p0.kontrol = 'PPI';  p0.KV = wa*(p0.JM+p0.JL);  p0.KI = 0.05*wa*p0.KV;
p0.Pkaynak = 'motor';  p0.Tan = p0.T;  p0.dec = 40;
p0.qM = 2*pi/(4096*30);  p0.Ts = 1e-3;  p0.Nper = 10;  p0.yuzN = 20;
p0.gM = 4e-4;  p0.akimW = 2*pi*500;  p0.nM = deg2rad(0.043)/p0.N;
G.kpv = 0.50^2*p0.Ks/p0.KV;  G.eps_ = 0.5;  G.tD = 3;
G.aci = 90:2.5:357.5;
G.taup = [0 0.03 0.06 0.12 0.18 0.24 0.36 0.48];
G.KpOran = 0.1;
G.tohum = 1:3;
G.ortam = {'sürtünmeli', 0.04, 0.06, 0;  'sürtünmeli', 0.04, 0.06, 0.25;  'sürtünmeli', 0.04, 0.06, 0.5;
           'sürtünmesiz', 0, 0, 0;       'sürtünmesiz', 0, 0, 0.25;       'sürtünmesiz', 0, 0, 0.5};
G.sen = {'temel', 'a1 darbe', 'a2 yük 0,02', 'a2 yük 0,06', 'b salınım', 'c yaklaşma', 'd yön değ.'};
G.ktl = {'disli_tablo', 'kestirici', 'ust_sinir'};
end
