function [thm, v] = sensor(x, S)
% Kol açısı ölçümü (nicemleme + gL örnek gecikme) ve hız (gerçek ya da kestirilmiş).
% kol_benzetim.m'deki kontrolcü örneğinin ölçüm kısmı ile aynı sıra.
persistent buf vhat yprev
vi = 3;  qv = S.qL;
if S.motorD > 0, vi = 1;  qv = S.qM; end
if isempty(buf)
    buf = olc(x(3), S.qL)*ones(21,1);
    yprev = olc(x(vi), qv);
    vhat = 0;
end
thm = olc(x(3), S.qL);
if S.gL > 0
    buf = [buf(2:end); thm];
    thm = buf(21 - S.gL);
end
if S.fv_inf > 0
    v = x(vi + 1);
else
    yv = olc(x(vi), qv);
    vhat = vhat + S.aV*((yv - yprev)/S.Ts - vhat);
    yprev = yv;
    v = vhat;
end
end

function y = olc(x, q)
y = x;
if q > 0, y = q*floor(x/q); end
end
