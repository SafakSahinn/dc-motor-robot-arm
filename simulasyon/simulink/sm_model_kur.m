function sm_model_kur(ad)
% SM_MODEL_KUR  Kolun mekaniğini Simscape fiziksel bloklarıyla kurar (kol_model'den bağımsız çapraz kontrol).
%
% Fiziksel ağ (Simscape, mekanik dönel alan):
%   motor:  Inertia JM + Rotational Damper bM (zemine) + Ideal Torque Source (tm)
%   dişli:  Rotational Hard Stop, R = motor, C = kol; sınırlar +-r, sertlik Ks, sönüm cs,
%           'smooth' model (geçiş bölgesi 'gecis' rad, sıfıra giderken kol_benzetim'in temas yasası)
%   kol:    Inertia JL + Rotational Damper bL (zemine) + Ideal Torque Source (ta)
%   ölçüm:  iki Ideal Rotational Motion Sensor (mutlak açı + hız)
% Simulink tarafı: blok_ayrik (sensör + kontrolcü, kol_model ile aynı hesap, durumlar Unit Delay'de),
%                  blok_yuk (sürtünme, yerçekimi, bozucu).
% Çözücü: global ode4, adım dt (kol_model ile aynı). Çalışma alanında S, Ts, dt, T, dec, gecis gerekir.
if nargin < 1, ad = 'sm_kol_model'; end
kok = fileparts(mfilename('fullpath'));
if bdIsLoaded(ad), close_system(ad, 0); end
new_system(ad);  load_system(ad);
load_system('fl_lib');  load_system('nesl_utility');
fm = 'fl_lib/Mechanical/';

% --- fiziksel bloklar ---
ekle(ad, 'nesl_utility/Solver Configuration', 'cozucu', [40 420]);
ekle(ad, [fm 'Rotational Elements/Mechanical Rotational Reference'], 'zemin', [300 520]);
ekle(ad, [fm 'Rotational Elements/Inertia'], 'JM', [260 300], 'inertia', 'S.JM', 'w_specify', 'on', 'w', 'S.x0(2)');
ekle(ad, [fm 'Rotational Elements/Inertia'], 'JL', [620 300], 'inertia', 'S.JL', 'w_specify', 'on', 'w', 'S.x0(4)');
ekle(ad, [fm 'Rotational Elements/Rotational Damper'], 'bM', [200 420], 'D', 'S.bM');
ekle(ad, [fm 'Rotational Elements/Rotational Damper'], 'bL', [680 420], 'D', 'S.bL');
ekle(ad, [fm 'Rotational Elements/Rotational Hard Stop'], 'dis', [440 300], ...
     'upper_bnd', 'S.r', 'lower_bnd', '-S.r', 'model', 'simscape.enum.hardstop.smooth', ...
     'stiff_up', 'S.Ks', 'stiff_low', 'S.Ks', 'D_up', 'S.cs', 'D_low', 'S.cs', 'transition', 'gecis');
ekle(ad, [fm 'Mechanical Sources/Ideal Torque Source'], 'tork_m', [260 180]);
ekle(ad, [fm 'Mechanical Sources/Ideal Torque Source'], 'tork_L', [620 180]);
ekle(ad, [fm 'Mechanical Sensors/Ideal Rotational Motion Sensor'], 'olc_m', [340 420], ...
     'reference', 'foundation.enum.MeasurementReference.absolute', 'acceleration_port', 'false', ...
     'velocity_port', 'true', 'position_port', 'true', 'offset', 'S.x0(1)');
ekle(ad, [fm 'Mechanical Sensors/Ideal Rotational Motion Sensor'], 'olc_L', [560 420], ...
     'reference', 'foundation.enum.MeasurementReference.absolute', 'acceleration_port', 'false', ...
     'velocity_port', 'true', 'position_port', 'true', 'offset', 'S.x0(3)');
ekle(ad, 'nesl_utility/Simulink-PS Converter', 'sps_m', [180 120], 'Unit', 'N*m');
ekle(ad, 'nesl_utility/Simulink-PS Converter', 'sps_L', [540 120], 'Unit', 'N*m');
c = {'phi','rad'; 'dphi','rad/s'; 'th','rad'; 'dth','rad/s'};
for i = 1:4
    ekle(ad, 'nesl_utility/PS-Simulink Converter', ['ps_' c{i,1}], [820 80+60*i], 'Unit', c{i,2});
end

% --- Simulink blokları ---
add_block('simulink/Signal Routing/Mux', [ad '/mux'], 'Inputs', '4', 'Position', [920 120 925 340]);
add_block('simulink/Sources/Clock', [ad '/saat'], 'Position', [960 20 990 50]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/yuk'], 'Position', [1040 40 1140 120]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/kontrolcu'], 'Position', [1200 220 1300 280]);
add_block('simulink/Discrete/Unit Delay', [ad '/durum'], 'Position', [1200 320 1240 360], ...
          'InitialCondition', 'S.st0', 'SampleTime', 'Ts');
add_block('simulink/Sinks/Out1', [ad '/x_out'], 'Position', [1000 360 1030 380], 'Port', '1');
add_block('simulink/Sinks/Out1', [ad '/u_out'], 'Position', [1360 240 1390 260], 'Port', '2');
kod_yaz([ad '/yuk'],       fullfile(kok, 'blok_yuk.m'),       '');
kod_yaz([ad '/kontrolcu'], fullfile(kok, 'blok_ayrik.m'),     'Ts');   % sensör + kontrolcü, durumlar Unit Delay'de

% --- fiziksel bağlantılar ---
fb(ad, 'cozucu', 'R1', 'zemin', 'L1');
fb(ad, 'JM', 'L1', 'dis', 'L1');            % hard stop R = motor
fb(ad, 'dis', 'R1', 'JL', 'L1');            % hard stop C = kol
fb(ad, 'bM', 'L1', 'JM', 'L1');   fb(ad, 'bM', 'R1', 'zemin', 'L1');
fb(ad, 'bL', 'L1', 'JL', 'L1');   fb(ad, 'bL', 'R1', 'zemin', 'L1');
% Ideal Torque Source: L1, R2 mekanik düğümler, R1 = S (giriş); L1 gövdeye, R2 zemine (pozitif S gövdeyi hızlandırır)
fb(ad, 'tork_m', 'L1', 'JM', 'L1');  fb(ad, 'tork_m', 'R2', 'zemin', 'L1');
fb(ad, 'tork_L', 'L1', 'JL', 'L1');  fb(ad, 'tork_L', 'R2', 'zemin', 'L1');
fb(ad, 'sps_m', 'R1', 'tork_m', 'R1');  fb(ad, 'sps_L', 'R1', 'tork_L', 'R1');
% Motion sensor (mutlak): L1 = R (gövde), R1 = W (hız), R2 = A (açı)
fb(ad, 'olc_m', 'L1', 'JM', 'L1');  fb(ad, 'olc_L', 'L1', 'JL', 'L1');
fb(ad, 'olc_m', 'R2', 'ps_phi', 'L1');  fb(ad, 'olc_m', 'R1', 'ps_dphi', 'L1');
fb(ad, 'olc_L', 'R2', 'ps_th', 'L1');   fb(ad, 'olc_L', 'R1', 'ps_dth', 'L1');

% --- sinyal bağlantıları ---
for i = 1:4, add_line(ad, ['ps_' c{i,1} '/1'], sprintf('mux/%d', i), 'autorouting', 'on'); end
add_line(ad, 'mux/1', 'yuk/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/1', 'yuk/2', 'autorouting', 'on');
add_line(ad, 'saat/1', 'yuk/3', 'autorouting', 'on');
add_line(ad, 'yuk/1', 'sps_m/1', 'autorouting', 'on');
add_line(ad, 'yuk/2', 'sps_L/1', 'autorouting', 'on');
add_line(ad, 'mux/1', 'kontrolcu/1', 'autorouting', 'on');
add_line(ad, 'durum/1', 'kontrolcu/2', 'autorouting', 'on');
add_line(ad, 'kontrolcu/2', 'durum/1', 'autorouting', 'on');
add_line(ad, 'mux/1', 'x_out/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/1', 'u_out/1', 'autorouting', 'on');

set_param(ad, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', 'dt', ...
          'StopTime', 'T', 'SaveOutput', 'on', 'OutputSaveName', 'yout', ...
          'SaveFormat', 'Dataset', 'Decimation', 'dec', 'SaveTime', 'off', ...
          'ReturnWorkspaceOutputs', 'on', 'SaveState', 'off', 'SignalLogging', 'off', ...
          'AlgebraicLoopMsg', 'none');   % Hard Stop'un yapısal döngüsü; gerçek bağımlılık yok
save_system(ad, fullfile(kok, [ad '.slx']));
close_system(ad, 0);
fprintf('%s.slx kuruldu\n', ad);
end

function ekle(ad, lib, ad_blk, xy, varargin)
b = add_block(lib, [ad '/' ad_blk], 'Position', [xy xy + [60 40]]);
if ~isempty(varargin), set_param(b, varargin{:}); end
end

function fb(ad, b1, p1, b2, p2)
% Fiziksel port bağlantısı: 'L1' = LConn(1), 'R2' = RConn(2)
h1 = port(get_param([ad '/' b1], 'PortHandles'), p1);
h2 = port(get_param([ad '/' b2], 'PortHandles'), p2);
add_line(ad, h1, h2, 'autorouting', 'on');
end

function h = port(ph, p)
if p(1) == 'L', h = ph.LConn(str2double(p(2:end))); else, h = ph.RConn(str2double(p(2:end))); end
end

function kod_yaz(blk, dosya, Tsadi)
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
