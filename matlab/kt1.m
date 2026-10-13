% KT1 - DC motorlu tek eklemli robot kolu: acik cevrim simulasyonu
% Durumlar: x1 = theta (rad, dik asagidan), x2 = omega (rad/s), x3 = i (A)
% Giris: u = V (motor gerilimi), cikis: y = theta

clear; clc; close all;

% Parametreler (CTMS motoru + bizim kol)
Jm = 0.01; b = 0.1; K = 0.01; R = 1; L = 0.5;
m = 0.05; l = 0.1; g = 9.81;
J = Jm + m*l^2;

% Durum denklemleri
f = @(t,x,u) [ x(2);
               (K*x(3) - b*x(2) - m*g*l*sin(x(1)))/J;
               (u - R*x(3) - K*x(2))/L ];

% Calisma noktasi: theta0 = 90 derece
th0 = pi/2;
ieq = m*g*l*sin(th0)/K;   % dengedeki akim
ueq = R*ieq;              % dengedeki gerilim
fprintf('Denge: theta = 90 derece, i = %.4f A, u = %.4f V\n', ieq, ueq);

% Denge noktasinda dogrusallastirma (ozdegerler)
A = [0 1 0;
     -m*g*l*cos(th0)/J  -b/J  K/J;
     0  -K/L  -R/L];
fprintf('Ozdegerler (theta0 = 90):\n'); disp(eig(A));

% Simulasyon: u sabit = ueq, kolu 90 derecenin biraz altindan,
% tam ustunden ve biraz ustunden birakiyoruz
baslangic = [80 90 100];      % derece
renk = {'b','k','r'};
tson = 60;
figure('Position',[100 100 800 420]); hold on; grid on;
for k = 1:numel(baslangic)
    x0 = [deg2rad(baslangic(k)); 0; ieq];
    [t,x] = ode45(@(t,x) f(t,x,ueq), [0 tson], x0);
    plot(t, rad2deg(x(:,1)), renk{k}, 'LineWidth', 1.5);
    fprintf('theta(0) = %3d -> theta(%d s) = %.2f derece\n', ...
            baslangic(k), tson, rad2deg(x(end,1)));
end
yline(90,'--','90^\circ (denge)');
xlabel('t (s)'); ylabel('\theta (derece)');
title(sprintf('Acik cevrim, u = %.3f V sabit', ueq));
legend('\theta(0) = 80^\circ','\theta(0) = 90^\circ','\theta(0) = 100^\circ', ...
       'Location','best');
ylim([60 460]); yticks(0:45:450);

sekil = fullfile(fileparts(fileparts(mfilename('fullpath'))),'sekiller');
exportgraphics(gcf, fullfile(sekil,'kt1_acik_cevrim.png'), 'Resolution', 150);
