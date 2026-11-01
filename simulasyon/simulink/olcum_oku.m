function K = olcum_oku(so)
% OLCUM_OKU  sm_motor_model koşusundan firmware kaydını (Ts örneklemeli) ve gerçek durumları ayırır.
% K.t, K.thL, K.phi, K.v, K.u, K.V, K.i : firmware'in göreceği sinyaller (açılar rad, hız rad/s,
%                                         tork N m, gerilim V, akım A; hepsi kol tarafına indirgenmiş)
% K.g.t, K.g.x (N x 4: phi, dphi, th, dth), K.g.i : gerçek değerler (dt*dec örneklemeli; doğrulama için)
m = so.yout{5}.Values;  M = squeeze(m.Data);  if size(M,2) ~= 6, M = M'; end
K.t = m.Time;
K.thL = M(:,1);  K.phi = M(:,2);  K.v = M(:,3);  K.u = M(:,4);  K.V = M(:,5);  K.i = M(:,6);
xs = so.yout{1}.Values;  X = squeeze(xs.Data);  if size(X,2) ~= 4, X = X'; end
K.g.t = xs.Time;  K.g.x = X;
is = so.yout{3}.Values;  K.g.ti = is.Time;  K.g.i = squeeze(is.Data);
end
