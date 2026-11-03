function mb_animasyon(hucre, cikis, kapat)
% MB_ANIMASYON  mb_kol_model'i bir referans hücrede koşar, Mechanics Explorer'dan video alır,
% videonun son çevriminden 6 kareyi rapor görseli olarak yazar.
%
% Arayüzlü MATLAB gerekir (Mechanics Explorer -batch'te açılmıyor):
%   matlab -r "addpath('simulasyon/simulink'); mb_animasyon(5, [], true)"
% Önemli: smwritevideo videoyu hemen kapatmıyor; dosya ancak MATLAB boşta kalınca tamamlanıyor
% (fonksiyon içinde pause ile beklemek işe yaramıyor, moov bölümü yazılmıyor). Bu yüzden fonksiyon
% videoyu başlatıp döner, bir zamanlayıcı dosya okunabilir olunca kareleri çıkarır (ve kapat = true ise
% MATLAB'ı kapatır).
% Çıktılar (cikis, varsayılan rapor/img): mb_animasyon.mp4, mb_me_kareler.png
if nargin < 1 || isempty(hucre), hucre = 5; end
kok = fileparts(mfilename('fullpath'));
if nargin < 2 || isempty(cikis), cikis = fullfile(fileparts(fileparts(kok)), 'rapor', 'img'); end
if nargin < 3, kapat = false; end
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
L = load(fullfile(kok, 'referans.mat'));  R = L.R;  h = R.hucre(hucre);
q = R.p;  q.adim = h.bas;
if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end
S = sim_param(q, h.ac, R.kos(hucre).kp);
M = mb_param(S);  S.mgl = 0;                 % yerçekimi Multibody'den
Tsim = 1.5;  oran = 0.2;  fps = 30;
for v = {'S', S; 'M', M; 'Ts', q.Ts; 'dt', q.dt; 'T', Tsim; 'dec', q.dec; 'gecis', 1e-6}'
    assignin('base', v{1}, v{2});
end
mdl = 'mb_kol_model';
load_system(fullfile(kok, [mdl '.slx']));
set_param(mdl, 'SimMechanicsOpenEditorOnUpdate', 'on');
sim(mdl);
pause(20);                                    % Mechanics Explorer'ın yüklenmesi
dosya = fullfile(cikis, 'mb_animasyon.mp4');
if exist(dosya, 'file'), delete(dosya); end
smwritevideo(mdl, dosya(1:end-4), 'PlaybackSpeedRatio', oran, 'FrameRate', fps, 'VideoFormat', 'mpeg-4');
t0 = tic;
zm = timer('StartDelay', 5, 'Period', 5, 'ExecutionMode', 'fixedSpacing', 'TimerFcn', @(tm, ~) kontrol(tm));
start(zm);

    function kontrol(tm)
        try
            vr = VideoReader(dosya);
        catch
            if toc(t0) > 300
                fprintf(2, 'mb_animasyon: video 300 s içinde tamamlanmadı\n');
                stop(tm);  delete(tm);  if kapat, quit('force'); end
            end
            return
        end
        stop(tm);  delete(tm);
        kareler(vr);
        fprintf('mb_animasyon: %s (%d kare, %.1f s), mb_me_kareler.png yazıldı\n', dosya, vr.NumFrames, vr.Duration);
        if kapat, quit('force'); end
    end

    function kareler(vr)
        % benzetim zamanı -> kare: her kare oran/fps s benzetim. Son çevrim: θ(t)'den bulunur.
        in = Simulink.SimulationInput(mdl);
        in = in.setVariable('S', S).setVariable('M', M).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
               .setVariable('T', Tsim).setVariable('dec', 1).setVariable('gecis', 1e-6);
        o = sim(in);
        X = squeeze(o.yout{1}.Values.Data);  if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
        t = o.yout{1}.Values.Time;  th = X(:,3);  ph = X(:,1);
        son = t > 0.6;  m = mean(th(son));
        g = find(son(1:end-1) & th(1:end-1) < m & th(2:end) >= m);
        ts = linspace(t(g(end-1)), t(g(end)), 7);  ts = ts(1:6);
        k = min(vr.NumFrames, round(ts*fps/oran) + 1);
        F = cell(1, 6);
        for i = 1:6, F{i} = read(vr, k(i)); end
        G = cat(4, F{:});  b = min(G, [], 4);  icerik = rgb2gray(b) < 200;   % arka plan alta doğru hafif koyulaşıyor
        icerik(end-130:end, :) = false;              % alt köşedeki eksen/zaman göstergesi sayılmasın
        rr = find(any(icerik, 2));  cc = find(any(icerik, 1));
        rr = max(1, rr(1) - 10):min(size(b,1) - 131, rr(end) + 10);
        cc = max(1, cc(1) - 10):min(size(b,2), cc(end) + 10);
        H = round(2*(500*numel(rr)/numel(cc) + 30) + 40);   % 3 sütun × 500 px, satır başına başlık payı
        f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1500 H]);
        tl = tiledlayout(f, 2, 3, 'TileSpacing', 'tight', 'Padding', 'compact');
        for i = 1:6
            ax = nexttile(tl);  image(ax, F{i}(rr, cc, :));  axis(ax, 'image', 'off');
            [~, j] = min(abs(t - (k(i) - 1)*oran/fps));
            title(ax, sprintf('t = %.3f s   \\theta = %.2f°   \\phi - \\theta = %+.2f°', t(j), ...
                  rad2deg(th(j)), rad2deg(ph(j) - th(j))), 'FontWeight', 'normal', 'FontSize', 10);
        end
        title(tl, sprintf('Mechanics Explorer, hücre %d: bir çevrim (%.0f ms)', hucre, 1e3*(ts(2) - ts(1))*6), 'FontSize', 12);
        exportgraphics(f, fullfile(cikis, 'mb_me_kareler.png'), 'Resolution', 110);
        close(f);
    end
end
