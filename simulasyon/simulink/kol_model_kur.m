function kol_model_kur(ad)
% KOL_MODEL_KUR  kol_benzetim.m ile aynı modeli Simulink'te betikle kurar ve <ad>.slx olarak kaydeder.
%
% Bloklar:
%   tesis      (sürekli)  MATLAB Function: iki kütle, ölü bölge + temas yayı/sönümü, yerçekimi,
%                         Stribeck sürtünmesi, yük bozucusu. Betikteki f(x) ile aynı denklemler.
%   x          Integrator, 4 durum [phi; dphi; th; dth], başlangıç S.x0
%   sensor     (ayrık, Ts) nicemleme, gL örnek gecikme, hız kestirimi (fark + 1. derece filtre)
%   kontrolcu  (ayrık, Ts) PID ya da P-PI, tork sınırı, anti-windup, sürücü ölü bandı
% Çözücü ode4 (RK4), adım dt. Çalışma alanında S (sim_param), Ts, dt, T değişkenleri gerekir.
% Kayıt: çıkış portları x, tau_s, u (Dataset, seyreltme dec).
if nargin < 1, ad = 'kol_model'; end
kok = fileparts(mfilename('fullpath'));
if bdIsLoaded(ad), close_system(ad, 0); end
new_system(ad);
load_system(ad);

add_block('simulink/Sources/Clock', [ad '/saat'], 'Position', [40 40 70 70]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/tesis'], 'Position', [300 100 420 180]);
add_block('simulink/Continuous/Integrator', [ad '/x'], 'Position', [480 120 520 160], ...
          'InitialCondition', 'S.x0');
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/sensor'], 'Position', [580 240 680 300]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/kontrolcu'], 'Position', [740 240 840 300]);
add_block('simulink/Sinks/Out1', [ad '/x_out'],   'Position', [620 125 650 145], 'Port', '1');
add_block('simulink/Sinks/Out1', [ad '/tau_s'],   'Position', [480 205 510 225], 'Port', '2');
add_block('simulink/Sinks/Out1', [ad '/u_out'],   'Position', [900 255 930 275], 'Port', '3');

kod_yaz([ad '/tesis'],     fullfile(kok, 'blok_tesis.m'),     '');
kod_yaz([ad '/sensor'],    fullfile(kok, 'blok_sensor.m'),    'Ts');
kod_yaz([ad '/kontrolcu'], fullfile(kok, 'blok_kontrolcu.m'), 'Ts');

add_line(ad, 'x/1', 'tesis/1', 'autorouting', 'on');       % x -> tesis
add_line(ad, 'kontrolcu/1', 'tesis/2', 'autorouting', 'on');
add_line(ad, 'saat/1', 'tesis/3', 'autorouting', 'on');
add_line(ad, 'tesis/1', 'x/1', 'autorouting', 'on');       % dx -> integrator
add_line(ad, 'tesis/2', 'tau_s/1', 'autorouting', 'on');
add_line(ad, 'x/1', 'x_out/1', 'autorouting', 'on');
add_line(ad, 'x/1', 'sensor/1', 'autorouting', 'on');
add_line(ad, 'sensor/1', 'kontrolcu/1', 'autorouting', 'on');
add_line(ad, 'sensor/2', 'kontrolcu/2', 'autorouting', 'on');
add_line(ad, 'kontrolcu/1', 'u_out/1', 'autorouting', 'on');

set_param(ad, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', 'dt', ...
          'StopTime', 'T', 'SaveOutput', 'on', 'OutputSaveName', 'yout', ...
          'SaveFormat', 'Dataset', 'Decimation', 'dec', 'SaveTime', 'off', ...
          'ReturnWorkspaceOutputs', 'on', 'SaveState', 'off', 'SignalLogging', 'off');
save_system(ad, fullfile(kok, [ad '.slx']));
close_system(ad, 0);
fprintf('%s.slx kuruldu\n', ad);
end

function kod_yaz(blk, dosya, Tsadi)
% MATLAB Function bloğunun kodunu dosyadan yükler; S'yi parametre yapar; Tsadi verilirse ayrık örneklenir.
rt = sfroot;
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', blk);
ch.Script = fileread(dosya);
d = ch.find('-isa', 'Stateflow.Data', 'Name', 'S');
d.Scope = 'Parameter';
if ~isempty(Tsadi)
    ch.ChartUpdate = 'DISCRETE';
    ch.SampleTime = Tsadi;
end
end
