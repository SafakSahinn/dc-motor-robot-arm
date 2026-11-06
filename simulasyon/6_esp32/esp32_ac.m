function sp = esp32_ac(port, baud)
% ESP32_AC  Seri portu .NET SerialPort ile açar, kartı EN'den sıfırlar.
%   Neden serialport() değil: MATLAB serialport'un okuma iş parçacığı
%   Windows'un 15,6 ms'lik zamanlayıcı adımıyla uyanıyor; her cevap ~15,6 ms
%   gecikiyor (seri_olcum_log.txt). .NET SerialPort engelleyici ReadFile
%   kullanır, cevap ~1,5 ms'de gelir. Ek toolbox gerekmez (yalnız Windows).
%   Kart açılışta 921600 baud. İş bitince: esp32_kapat(sp) (port kilidi!).
if nargin < 1, port = "COM4"; end
if nargin < 2, baud = 921600; end
NET.addAssembly('System');
sp = System.IO.Ports.SerialPort(char(port), baud);
sp.ReadTimeout = 1000;          % ms
sp.WriteTimeout = 1000;
sp.ReadBufferSize = 65536;
sp.WriteBufferSize = 65536;
sp.Open();
% CP210x: RTS → EN. Kısa darbe = donanım sıfırlaması (DTR → IO0, bırakılı).
sp.DtrEnable = false;
sp.RtsEnable = true; pause(0.05); sp.RtsEnable = false;
pause(1.0);                     % ROM çıktısı (115200 baud) + setup()
sp.DiscardInBuffer();
end
