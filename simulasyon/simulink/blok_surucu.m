function [V, zi1] = surucu(u, v, i, w, zi, S)
% Firmware'in tork komutunu (u) motor gerilimine çevirmesi + DRV8874 (ortalama model, PWM anahtarlaması yok).
% Örnekleme Tsur (akım döngüsü / PWM güncelleme hızı). Durumsuz yazım: akım PI integrali zi dışarıda (Unit Delay).
%   S.mot = 1  gerilim modu:            V = Ra u / Km               (zıt EMK sönümü devrede)
%   S.mot = 2  zıt EMK kompanzasyonu:   V = Ra u / Km + Km v        (v: kontrolcünün kullandığı motor hızı)
%   S.mot = 3  akım döngüsü:            i_ref = u / Km (sınırlı), PI (IPROPI ölçümü, Tsur hızında)
%              i girişi bir Tsur gecikmeli gelir (ADC örneği -> hesap -> PWM; sm_model_kur'daki i_adc)
% Donanım: besleme +-Vs ile doyum; DRV8874 akım sınırı Ilim (kıyıcı akımı Ilim'de tutar; ortalama
% modelde gerilim, kararlı akımı Ilim'i aşmayacak şekilde sınırlanır: |V - Km w| <= Ra Ilim).
% Km, Ra, Ilim kol tarafına indirgenmiş eşdeğer motor büyüklükleridir (sim_param).
zi1 = zi;  e = 0;
if S.mot == 3
    iref = min(max(u/S.Km, -S.Ilim), S.Ilim);
    e = iref - i;
    Vc = S.Kpi*e + zi;
elseif S.mot == 2
    Vc = S.Ra*u/S.Km + S.Km*v;
else
    Vc = S.Ra*u/S.Km;
end
V = min(max(Vc, S.Km*w - S.Ra*S.Ilim), S.Km*w + S.Ra*S.Ilim);   % akım sınırı
V = min(max(V, -S.Vs), S.Vs);                                    % besleme
if S.mot == 3
    if V == Vc || (V < Vc && e < 0) || (V > Vc && e > 0)         % anti-windup
        zi1 = zi + S.Kii*S.Tsur*e;
    end
end
end
