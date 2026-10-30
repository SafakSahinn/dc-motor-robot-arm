function rejim_testleri
% REJIM_TESTLERI  rejim_sinifla'yı sonucu bilinen durumlarla sınar ve her durumu
% birden fazla başlangıç sapmasıyla koşarak birlikte var olan rejimleri raporlar.
% Sinyal: yük açısının hedeften sapması (deneyde AS5600'ün ölçtüğü büyüklük).
T = {
 % ad                                  durum     ayar                         kp     kv   beklenen
 'denge: tabla, düşük kazanç'          'tabla'   {}                           3.8    20   'denge'
 'sönümlü: boşluksuz, kararlı kazanç'  'tabla'   {'delta',0,'Fcm',0,'Fcl',0}  8.3    20   'sönümlü titreşim'
 'zorlanmış: boşluksuz + 3 Hz bozucu'  'tabla'   {'delta',0,'Fcm',0,'Fcl',0,'dA',2e5,'df',3}  8.3  20  'zorlanmış cevap'
 'kalıcı çevrim: Şekil 7 (kalibre)'    'sekil7'  {'cm',0,'cle',0,'cl',0,'xis',0.0135}           11.67 20  'kalıcı çevrim'
 'kalıcı çevrim: tabla, Tmax 360'      'tabla'   {'Tmax',360}                 15     20   'kalıcı çevrim'
 'kararsız: tabla, sürtünmesiz, kp 18' 'tabla'   {'Fcm',0,'Fcl',0}            18.3   20   'kararsız'
 'çarpma: Şekil 8 (kalibre)'           'sekil8'  {'cm',0,'cle',0,'cl',0,'xis',0.0135}           11.67 20  'kalıcı çevrim'
};
th0 = [0.05 0.5 2];                                % başlangıç sapmaları [der]
fid = fopen('rejim_testleri_log.txt','w');
yaz(fid, '%-38s %-17s | %s\n', 'durum', 'beklenen', 'başlangıç sapması 0,05° / 0,5° / 2°: sınıf (A [der], f [Hz], zarf değişimi)');
for i = 1:size(T,1)
    p = ghaffari_param(T{i,2});
    a = T{i,3};
    for k = 1:2:numel(a), p.(a{k}) = a{k+1}; end
    if isfield(p,'xis'), p.cs = 2*p.xis*p.ks/p.wa; end
    p.T = 7;  p.Tan = p.T;  p.dec = 10;            % baştan kaydet: sönümü görebilmek için
    opt.A_min = 0.1*rad2deg(p.delta);               % deg; boşluğun %10'u
    if p.delta == 0, opt.A_min = 0.005; end         % boşluksuz: en küçük başlangıç sapmasının %10'u
    opt.A_max = 30;  opt.T_at = 0.3;  opt.f_z = p.df;
    s = '';  siniflar = [];
    for b = th0
        p.th0 = deg2rad(b);
        o = ghaffari2013(p, T{i,4}, T{i,5});
        r = rejim_sinifla(o.t, rad2deg(o.thl), opt);
        yk = '';  if r.yakinsiyor, yk = ', yakınsıyor'; end
        s = [s sprintf('%s (%.3g, %.3g, %+.2f%s) / ', r.ad{1}, r.A, r.f, r.degisim, yk)]; %#ok<AGROW>
        siniflar(end+1) = r.sinif; %#ok<AGROW>
    end
    not = '';
    if numel(unique(siniflar)) > 1, not = '  <- başlangıç koşuluna bağlı'; end
    yaz(fid, '%-38s %-17s | %s%s\n', T{i,1}, T{i,6}, s(1:end-3), not);
end
fclose(fid);
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
