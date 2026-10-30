function sensor_7c(S, duz)
% SENSOR_7C  Sensör ve uygulama etkileri bütün düzeneklerde: yerçekimli açı x r_gs haritası üç düzeyde
%   ideal   : sürekli kontrol, ideal ölçüm (secenekler.m ile aynı)
%   sensor  : 1 kHz kontrol, AS5600 12 bit + 1 örnek gecikme, motor enkoderi 11 darbe x 4 kenar x N,
%             hız = enkoder farkı + 50 Hz alçak geçiren
%   gercekci: sensor + motor tarafı Coulomb/yapışma sürtünmesi (0,04 / 0,06 N m, kol tarafı) + sürücü ölü bandı %3 Tmax
%   kenar   : sensor, ama hız enkoder kenar zamanlamasıyla (gerçek hızın 1 kHz örneği olarak yaklaşık)
%   kenar_g : kenar + gercekci'deki sürtünme ve ölü bant
% Sınıflandırma ölçülen (nicemlenmiş) kol açısı üzerinden (sensörlü düzeylerde).
% sensor_7c(S, duz): S düzenek listesi, duz düzey listesi.
addpath(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1, S = {'A','B1','B2','C','D'}; end
if nargin < 2, duz = {'ideal','sensor','gercekci'}; end
rgs = [0.3 0.5 0.7 0.9 1.1 1.3];
ac  = [0 10 20 30 45 60 90 135 180];
bas = [0.2 1 5];
sm  = '.sZCX?';
fid = fopen('sensor_7c_log.txt','a');
R = struct();
for i = 1:numel(S)
    for dz = 1:numel(duz)
        p = secenek_duzenek(S{i});
        wa = sqrt(p.Ks/p.JL);
        p.kontrol = 'PPI';  p.KV = wa*(p.JM+p.JL);  p.KI = 0.05*wa*p.KV;
        qL = 0;  d = duz{dz};
        if ~strcmp(d,'ideal')
            p.Ts = 1e-3;  p.qL = 2*pi/4096;  qL = p.qL;  p.gL = 1;
            p.qM = 2*pi/(11*4*p.N);  p.fv = 50;
        end
        if startsWith(d,'kenar'), p.fv = Inf; end   % hız: gerçek hızın kontrol örneği
        if any(strcmp(d,{'gercekci','kenar_g'}))
            p.Fc = 0.04;  p.Fs = 0.06;  p.olu = 0.03*p.Tmax;
        end
        kp = rgs.^2*p.Ks/p.KV;
        [AC, KP] = meshgrid(ac, kp);
        C = zeros(numel(bas), numel(AC));  F = C;  A = C;  D = C;
        for b = 1:numel(bas)
            p.adim = bas(b);
            o = kol_benzetim(p, AC(:)', KP(:)');
            th = rad2deg(o.th);
            if qL > 0, th = rad2deg(qL*floor(o.th/qL)); end
            r = rejim_sinifla(o.t, th - AC(:)', struct('A_min',0.05,'A_max',30,'T_at',0.3));
            C(b,:) = r.sinif;  F(b,:) = r.f;  A(b,:) = r.A;  D(b,:) = mean(abs(o.u) >= 0.999*p.Tmax);
        end
        yaz(fid, '=== %s, %s (R = %.2f)\n       açı: %s\n', S{i}, duz{dz}, p.JL/p.JM, sprintf('%5d', ac));
        for k = 1:numel(rgs)
            s = '';
            for j = 1:numel(ac)
                m = sub2ind(size(AC), k, j);  c = C(:,m);
                if all(c == c(1)), s = [s sprintf('%5s', sm(c(1)+1))]; %#ok<AGROW>
                else, s = [s sprintf('%5s', [sm(max(c)+1) '*'])]; end %#ok<AGROW>
            end
            yaz(fid, '  r_gs %.1f: %s\n', rgs(k), s);
        end
        yaz(fid, '  çevrim: %d / %d nokta, frekans %.1f-%.1f Hz; doyum ort. %%%.0f\n\n', nnz(any(C==3,1)), numel(AC), ...
            min([F(C==3); Inf]), max([F(C==3); 0]), 100*mean(D(:)));
        R.(S{i}).(duz{dz}) = struct('C',C,'F',F,'A',A,'D',D);
    end
end
save(sprintf('sensor_7c_%s.mat', strjoin(S,'')), 'R', 'rgs', 'ac', 'bas');
fclose(fid);
end

function yaz(fid, varargin)
fprintf(varargin{:});  fprintf(fid, varargin{:});
end
