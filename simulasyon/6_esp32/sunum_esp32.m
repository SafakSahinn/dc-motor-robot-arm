function sunum_esp32(port)
% SUNUM_ESP32  Sunumda canlı kart gösterimi: ESP32'ye bağlanır, 1 kHz döngünün
%   çalıştığını gösterir (2 s arayla iki durum okuması), portu kapatır. Dosya yazmaz.
%   Kullanım (bu klasörden):  sunum_esp32          % varsayılan COM4
%                             sunum_esp32("COM5")
if nargin < 1, port = "COM4"; end
sp = esp32_ac(port);
temizle = onCleanup(@() esp32_kapat(sp));      % hata olsa da port kilidi kalmasın
d1 = esp32_durum(sp, 1);  t1 = tic;
pause(2);
d2 = esp32_durum(sp, 2);  dt = toc(t1);
hiz = (d2.tick - d1.tick) / dt;
fprintf('\nESP32 bağlı (%s, 921600 baud)\n', port);
fprintf('  döngü sayacı: %d -> %d  (%.2f s içinde)\n', d1.tick, d2.tick, dt);
fprintf('  ölçülen döngü hızı: %.0f Hz  (hedef 1000 Hz)\n', hiz);
fprintf('  kaçan kesme: %d\n', d2.kacan);
fprintf(['\nKart üstü doğrulama sonuçları (önceden koşuldu):\n' ...
         '  ikiz_dogrula_log.txt : ikiz + kontrolcü kartta, 42/42 senaryo, kaçan kesme 0\n' ...
         '  dongu_olcum_log.txt  : yüz kestiricinin kartta adım süresi\n']);
end
