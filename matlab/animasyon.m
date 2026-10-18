% Robot kolunun 2D animasyonu (acik cevrim, u = ueq sabit)
% Uc durum yan yana: theta(0) = 80, 90, 100 derece
% Ekranda oynatir ve sekiller/model_animasyon.gif olarak kaydeder

clear; clc; close all;

% Parametreler (acik_cevrim.m ile ayni)
Jm = 0.01; b = 0.1; K = 0.01; R = 1; L = 0.5;
m = 0.05; l = 0.1; g = 9.81;
J = Jm + m*l^2;
f = @(t,x,u) [ x(2);
               (K*x(3) - b*x(2) - m*g*l*sin(x(1)))/J;
               (u - R*x(3) - K*x(2))/L ];
ieq = m*g*l/K;  ueq = R*ieq;   % theta0 = 90 derece

% Simulasyon: esit aralikli zamanlarda cozum (her kare 0.2 s)
baslangic = [80 90 100];
renk = {'b','k','r'};
t = (0:0.2:60)';
th = zeros(numel(t), 3);
for k = 1:3
    x0 = [deg2rad(baslangic(k)); 0; ieq];
    [~,x] = ode45(@(t,x) f(t,x,ueq), t, x0);
    th(:,k) = x(:,1);
end

% Cizim: theta dik asagidan olculuyor -> uc nokta (l sin, -l cos)
fig = figure('Color','w','Position',[100 100 900 340]);
for k = 1:3
    ax(k) = subplot(1,3,k); hold on; axis equal; axis off;
    axis([-0.13 0.13 -0.13 0.13]);
    plot(0.1*cos(linspace(0,2*pi,100)), 0.1*sin(linspace(0,2*pi,100)), ':', 'Color',[.7 .7 .7]);
    plot([0 0.12],[0 0],'--','Color',[.5 .5 .5]);        % 90 derece (yatay)
    text(0.105,0.012,'90^\circ','Color',[.5 .5 .5],'FontSize',8);
    kol(k)  = plot([0 0],[0 -l],'-','Color',renk{k},'LineWidth',4);
    uc(k)   = plot(0,-l,'o','MarkerSize',10,'MarkerFaceColor',renk{k},'Color',renk{k});
    plot(0,0,'ks','MarkerSize',10,'MarkerFaceColor',[.3 .3 .3]);   % motor
    title(sprintf('\\theta(0) = %d^\\circ', baslangic(k)));
    yazi(k) = text(-0.12,-0.125,'','FontSize',9);
end
zaman = annotation('textbox',[0.42 0.01 0.2 0.06],'String','', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',11);

gif = fullfile(fileparts(fileparts(mfilename('fullpath'))),'sekiller','model_animasyon.gif');
for n = 1:numel(t)
    for k = 1:3
        xu = l*sin(th(n,k));  yu = -l*cos(th(n,k));
        set(kol(k),'XData',[0 xu],'YData',[0 yu]);
        set(uc(k),'XData',xu,'YData',yu);
        set(yazi(k),'String',sprintf('\\theta = %.1f^\\circ', rad2deg(th(n,k))));
    end
    set(zaman,'String',sprintf('t = %.1f s', t(n)));
    drawnow;
    [img,cmap] = rgb2ind(frame2im(getframe(fig)), 64);
    if n == 1
        imwrite(img,cmap,gif,'gif','LoopCount',Inf,'DelayTime',0.05);
    else
        imwrite(img,cmap,gif,'gif','WriteMode','append','DelayTime',0.05);
    end
end
fprintf('GIF kaydedildi: %s\n', gif);
