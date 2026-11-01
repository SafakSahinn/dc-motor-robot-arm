function y = akim(i, n, S)
% IPROPI akım ölçümü, firmware kaydı (Ts örneklemeli): ADC gürültüsü + nicemleme.
%   i: ADC'nin gördüğü akım (i_adc, bir Tsur gecikmeli), n: birim varyanslı gürültü (Random Number bloğu)
%   S.iGur: gürültü std [A], S.qI: ADC basamağı akım cinsinden [A] (0 = ideal)
y = i + S.iGur*n;
if S.qI > 0, y = S.qI*round(y/S.qI); end
end
