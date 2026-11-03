function mb_kareler(hucre, cikis)
% MB_KARELER  mb_kol_model'i bir referans hücrede koşar ve 3B geometriyi (mb_param boyutları) koşudan gelen
% φ(t), θ(t) ile MATLAB figüründe çizer. Mechanics Explorer'a gerek yok (-batch'te çalışır).
% Çıktılar (cikis klasörüne): mb_3b_gorunum.png (tek büyük görünüm), mb_kareler.png (bir çevrim, 6 kare).
% hucre: referans.mat hücre numarası (varsayılan 5: 90°, 5° başlangıç, kalıcı çevrim)
if nargin < 1, hucre = 5; end
kok = fileparts(mfilename('fullpath'));
if nargin < 2, cikis = fullfile(fileparts(fileparts(kok)), 'rapor', 'img'); end
addpath(fileparts(kok), fullfile(fileparts(kok), '4a_ghaffari'));
L = load(fullfile(kok, 'referans.mat'));  R = L.R;  h = R.hucre(hucre);
q = R.p;  q.adim = h.bas;
if ~isempty(h.Tmax), q.Tmax = h.Tmax; end
if h.dA > 0, q.dA = h.dA;  q.df = 6.31;  q.dT = 1; end
S = sim_param(q, h.ac, R.kos(hucre).kp);
M = mb_param(S);  S0 = S;  S0.mgl = 0;
mdl = 'mb_kol_model';
load_system(fullfile(kok, [mdl '.slx']));
in = Simulink.SimulationInput(mdl);
in = in.setVariable('S', S0).setVariable('M', M).setVariable('Ts', q.Ts).setVariable('dt', q.dt) ...
       .setVariable('T', 4).setVariable('dec', 1).setVariable('gecis', 1e-6);
o = sim(in);
X = squeeze(o.yout{1}.Values.Data);  if size(X,1) == 4 && size(X,2) ~= 4, X = X'; end
t = o.yout{1}.Values.Time;
close_system(mdl, 0);

% salınımın son tam çevrimi: θ'nın son iki yukarı sıfır geçişi (ortalama etrafında)
th = X(:,3);  ph = X(:,1);
son = t > 2;  m = mean(th(son));
g = find(son(1:end-1) & th(1:end-1) < m & th(2:end) >= m);
i0 = g(end-1);  i1 = g(end);
sec = round(linspace(i0, i1, 7));  sec = sec(1:6);

% tek büyük görünüm (çevrimin en yüksek noktası)
[~, ib] = max(th(i0:i1));  ib = ib + i0 - 1;
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 620]);
tl = tiledlayout(f, 1, 1, 'Padding', 'compact');  ax = nexttile(tl);
ciz(ax, M, ph(ib), th(ib), true);
title(tl, sprintf('mb\\_kol\\_model: \\theta = %.1f°, \\phi = %.1f° (hücre %d, t = %.3f s)', ...
      rad2deg(th(ib)), rad2deg(ph(ib)), hucre, t(ib)), 'FontSize', 12);
exportgraphics(f, fullfile(cikis, 'mb_3b_gorunum.png'), 'Resolution', 160);
close(f);

% bir çevrim boyunca 6 kare
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1500 700]);
tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:6
    ax = nexttile(tl);  i = sec(k);
    ciz(ax, M, ph(i), th(i), false);
    text(ax, -0.11, 0.075, 0, sprintf('t = %.3f s\n\\theta = %.2f°\n\\phi - \\theta = %+.2f°', t(i) - t(i0), ...
         rad2deg(th(i)), rad2deg(ph(i) - th(i))), 'FontSize', 10, 'VerticalAlignment', 'top');
end
title(tl, sprintf('Bir çevrim (%.0f ms): kol \\theta ve rotor \\phi; boşluk 2r = %.1f°', ...
      1e3*(t(i1) - t(i0)), rad2deg(2*S.r)), 'FontSize', 12);
exportgraphics(f, fullfile(cikis, 'mb_kareler.png'), 'Resolution', 130);
close(f);
fprintf('mb_3b_gorunum.png, mb_kareler.png yazıldı (çevrim %.3f-%.3f s, θ %.2f..%.2f°)\n', ...
        t(i0), t(i1), rad2deg(min(th(i0:i1))), rad2deg(max(th(i0:i1))));
end

function ciz(ax, M, ph, th, etiket)
% Model ile aynı yerleşim: eksen Z, kol (çubuk + uç) θ ile döner (θ = 0 sarkık, -Y);
% rotor diski z = M.zrot'ta φ ile döner (üstündeki işaret çizgisi φ'yi gösterir); gövde dünyaya sabit.
hold(ax, 'on');  axis(ax, 'equal');  grid(ax, 'on');
Rz = @(a) [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
% gövde
kutu(ax, eye(3), [0 0 M.zrot-0.035], [0.05 0.05 0.05], [0.25 0.25 0.28], 1);
% rotor diski + işaret
silindir(ax, Rz(ph), [0 0 M.zrot], M.rrot, M.hrot, [0.85 0.5 0.15]);
p = Rz(ph)*[0; -M.rrot; 0];
plot3(ax, [0 p(1)], [0 p(2)], (M.zrot + M.hrot/2 + 1e-3)*[1 1], 'k-', 'LineWidth', 2.5);
% mil
silindir(ax, Rz(th), [0 0 M.zrot/2], 0.004, abs(M.zrot), [0.5 0.5 0.5]);
% kol
kutu(ax, Rz(th), (Rz(th)*[0; -M.L/2; 0])', [M.w M.L M.t], [0.72 0.75 0.8], 1);
silindir(ax, Rz(th), (Rz(th)*[0; -M.d; 0])', M.ru, M.hu, [0.15 0.35 0.75]);
% referans: sarkık (0°) ve yatay (90°) kesik çizgiler
plot3(ax, [0 0], [0 -0.07], [0 0], ':', 'Color', [0.6 0.6 0.6]);
plot3(ax, [0 0.18], [0 0], [0 0], ':', 'Color', [0.6 0.6 0.6]);
if etiket
    quiver3(ax, -0.1, 0.07, 0, 0, -0.05, 0, 0, 'Color', [0.2 0.5 0.2], 'LineWidth', 1.5, 'MaxHeadSize', 0.6);
    text(ax, -0.095, 0.045, 0, ' g', 'Color', [0.2 0.5 0.2], 'FontSize', 11);
    text(ax, 0.18, 0.005, 0, '90° (yatay)', 'Color', [0.45 0.45 0.45]);
    text(ax, 0.005, -0.07, 0, '0° (sarkık)', 'Color', [0.45 0.45 0.45]);
    text(ax, 0.02, 0.055, M.zrot, 'rotor (φ)', 'Color', [0.55 0.3 0.05]);
    text(ax, 0.155, -0.04, 0, 'uç kütlesi', 'Color', [0.15 0.3 0.6]);
end
axis(ax, 'off');
xlim(ax, [-0.12 0.21]);  ylim(ax, [-0.09 0.09]);  zlim(ax, [-0.11 0.04]);
% kamera: +Y yukarı (yerçekimi aşağı), kol düzleminin önünden hafif yandan; rotor ve gövde kolun arkasında
camtarget(ax, [0.045 0 -0.03]);  campos(ax, [0.6 0.3 0.75]);  camup(ax, [0 1 0]);
camva(ax, 15);  camlight(ax, 'headlight');  lighting(ax, 'gouraud');
end

function kutu(ax, Rm, c, d, renk, alfa)
[x, y, z] = ndgrid([-1 1]*d(1)/2, [-1 1]*d(2)/2, [-1 1]*d(3)/2);
V = (Rm*[x(:) y(:) z(:)]')' + c;
F = [1 2 4 3; 5 6 8 7; 1 2 6 5; 3 4 8 7; 1 3 7 5; 2 4 8 6];
patch(ax, 'Vertices', V, 'Faces', F, 'FaceColor', renk, 'EdgeColor', renk*0.6, 'FaceAlpha', alfa, ...
      'FaceLighting', 'gouraud');
end

function silindir(ax, Rm, c, r, hh, renk)
[x, y, z] = cylinder(r, 40);  z = (z - 0.5)*hh;
P = Rm*[x(:) y(:) z(:)]';
X = reshape(P(1,:), size(x)) + c(1);  Y = reshape(P(2,:), size(x)) + c(2);  Z = reshape(P(3,:), size(x)) + c(3);
surf(ax, X, Y, Z, 'FaceColor', renk, 'EdgeColor', 'none');
for s = [1 2]
    fill3(ax, X(s,:), Y(s,:), Z(s,:), renk, 'EdgeColor', 'none');
end
end
