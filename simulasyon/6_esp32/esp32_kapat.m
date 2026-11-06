function esp32_kapat(sp)
% ESP32_KAPAT  .NET seri portu kapatır (hata vermez).
try
    if sp.IsOpen, sp.Close(); end
    sp.Dispose();
catch
end
end
