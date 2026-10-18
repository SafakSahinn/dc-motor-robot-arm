% Animasyondan film seridi: theta(0) = 100 derece durumunun
% secilen anlari yan yana (PDF'e konacak sabit resim)

clear; clc; close all;

Jm = 0.01; b = 0.1; K = 0.01; R = 1; L = 0.5;
m = 0.05; l = 0.1; g = 9.81;
J = Jm + m*l^2;
f = @(t,x,u) [ x(2);
               (K*x(3) - b*x(2) - m*g*l*sin(x(1)))/J;
               (u - R*x(3) - K*x(2))/L ];
ieq = m*g*l/K;  ueq = R*ieq;

anlar = [0 15 22 24 27 45];          % s
x0 = [deg2rad(100); 0; ieq];
[~,x] = ode45(@(t,x) f(t,x,ueq), [0 1e-3 anlar(2:end)], x0);
th = x([1 3:end],1);

fig = figure('Color','w','Position',[100 100 1200 260]);
for k = 1:numel(anlar)
    subplot(1,numel(anlar),k); hold on; axis equal; axis off;
    axis([-0.13 0.13 -0.13 0.13]);
    plot(0.1*cos(linspace(0,2*pi,100)), 0.1*sin(linspace(0,2*pi,100)), ':', 'Color',[.7 .7 .7]);
    plot([0 0.12],[0 0],'--','Color',[.5 .5 .5]);
    xu = l*sin(th(k));  yu = -l*cos(th(k));
    plot([0 xu],[0 yu],'r-','LineWidth',4);
    plot(xu,yu,'ro','MarkerSize',9,'MarkerFaceColor','r');
    plot(0,0,'ks','MarkerSize',9,'MarkerFaceColor',[.3 .3 .3]);
    title(sprintf('t = %d s', anlar(k)), 'FontWeight','normal');
    text(0,-0.135,sprintf('\\theta = %.0f^\\circ', rad2deg(th(k))), ...
         'HorizontalAlignment','center','FontSize',10);
    fprintf('t = %2d s -> theta = %.1f derece\n', anlar(k), rad2deg(th(k)));
end
sekil = fullfile(fileparts(fileparts(mfilename('fullpath'))),'sekiller');
exportgraphics(fig, fullfile(sekil,'model_filmseridi.png'), 'Resolution', 150);
