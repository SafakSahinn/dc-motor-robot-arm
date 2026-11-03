function mb_model_kur(ad)
% MB_MODEL_KUR  Kolu Simscape Multibody ile 3B olarak kurar (sm_kol_model'in 3B karşılığı).
%
% Multibody tarafı (geometri, kütle, yerçekimi):
%   World Frame + Mechanism Configuration (yerçekimi dünya -Z yönünde, M.g); mekanizma T_eksen ile döndürülmüş
%   çerçevede kurulu (aşağıdaki yerel eksenler o çerçevenin: eklem ekseni Z = dünya -Y, yerel -Y = dünya -Z)
%   rotor: Revolute Joint (eklem_m, Z ekseni) + eşdeğer disk (Izz = S.JM), kol düzleminin M.zrot gerisinde
%   kol:   Revolute Joint (eklem_L, aynı eksen) + çubuk (Brick) + uç kütlesi (Cylinder), kol -Y yönünde uzanır
%          -> açı tanımı 1B modelle aynı: 0 sarkık, 90° yatay (+X), 180° dik; yerçekimi torku -mgl sin(th)
%   gövde: dünyaya sabit motor kutusu (yalnız görüntü)
%   Kütle/eylemsizlikler mb_param'dan "Custom" olarak verilir (J_L ve mgℓ sim_param ile birebir).
% 1B mekanik ağ (Simscape Foundation), iki Rotational Multibody Interface ile eklemlere bağlı:
%   dişli = Rotational Hard Stop (R = motor, C = kol), sm_kol_model ile aynı parametreler
%   bM, bL viskoz sönüm; tork_m (kontrolcü - Stribeck), tork_L (bozucu) Ideal Torque Source
% Eklemler: tork girişi arayüzden, açı ve hız ölçümü kendi algılama portlarından (mutlak açı).
% Simulink tarafı sm_kol_model ile aynı: blok_ayrik (sensör + kontrolcü, durumlar Unit Delay'de), blok_yuk.
%
% ÖNEMLİ: yerçekimi Multibody'den gelir. blok_yuk'taki -S.mgl sin(th) terimi çift sayılmasın diye bu model
% S.mgl = 0 ile koşulur; gerçek mgℓ M (mb_param) üzerinden geometriye girer. Çalışma alanında
% S (mgl = 0), M = mb_param(S_gercek), Ts, dt, T, dec, gecis gerekir. Global çözücü ode4 (adım dt),
% fiziksel ağ yerel Backward Euler (adım dt).
if nargin < 1, ad = 'mb_kol_model'; end
kok = fileparts(mfilename('fullpath'));
if bdIsLoaded(ad), close_system(ad, 0); end
new_system(ad);  load_system(ad);
load_system('fl_lib');  load_system('nesl_utility');  load_system('sm_lib');
fm = 'fl_lib/Mechanical/';
sf = sprintf('sm_lib/Frames and\nTransforms/');
sb = 'sm_lib/Body Elements/';

% --- Multibody: dünya, yerçekimi, gövde ---
ekle(ad, [sf 'World Frame'], 'dunya', [40 700]);
ekle(ad, sprintf('sm_lib/Utilities/Mechanism\nConfiguration'), 'mekanizma', [40 800], ...
     'GravityVector', '[0 0 -M.g]');
% Mekanizma çerçevesi: eklem ekseni (yerel Z) dünya -Y'sine, kolun sarkık yönü (yerel -Y) dünya -Z'sine.
% Mechanics Explorer'ın varsayılan bakışı XZ düzlemi (z yukarı, kamera -Y tarafında) olduğundan kol düzlemi
% ekrana paralel olur; rotor ve gövde (yerel -Z) kolun arkasında kalır. Yerelde yerçekimi -Y yönünde;
% açı tanımı ve denklemler aynı (90° = yatay, dünya +X, ekranda sağ).
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_eksen', [100 700], 'RotationMethod', 'RotationMatrix', ...
     'RotationMatrix', '[1 0 0; 0 0 -1; 0 1 0]');
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_govde', [160 900], 'TranslationMethod', 'Cartesian', ...
     'TranslationCartesianOffset', '[0 0 M.zrot-0.035]');
ekle(ad, [sb 'Brick Solid'], 'govde', [260 900], 'BrickDimensions', '[0.05 0.05 0.05]', ...
     'InertiaType', 'Custom', 'Mass', '0.2', 'MomentsOfInertia', '[1 1 1]*1e-4', ...
     'GraphicDiffuseColor', '[0.25 0.25 0.28]');

% --- rotor eklemi ve eşdeğer disk ---
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_rotor', [160 600], 'TranslationMethod', 'Cartesian', ...
     'TranslationCartesianOffset', '[0 0 M.zrot]');
eklem(ad, 'eklem_m', [280 600], 'S.x0(1)', 'S.x0(2)');
ekle(ad, [sb 'Cylindrical Solid'], 'rotor', [420 600], 'CylinderRadius', 'M.rrot', 'CylinderLength', 'M.hrot', ...
     'InertiaType', 'Custom', 'Mass', 'M.mrot', 'CenterOfMass', '[0 0 0]', 'MomentsOfInertia', 'M.Irot', ...
     'ProductsOfInertia', '[0 0 0]', 'GraphicDiffuseColor', '[0.8 0.45 0.1]');

% rotor işareti: kütlesiz Graphic (dinamiği değiştirmez), kolun ters yönünde diskin ön yüzünde -> φ görünür
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_isaret', [420 520], 'TranslationMethod', 'Cartesian', ...
     'TranslationCartesianOffset', '[0 0.8*M.rrot M.hrot/2]');
ekle(ad, [sb 'Graphic'], 'isaret', [540 520], 'MarkerShape', 'Sphere', 'MarkerSize', '16', ...
     'GraphicDiffuseColor', '[0.05 0.05 0.05]');

% --- kol eklemi, çubuk, uç kütlesi ---
eklem(ad, 'eklem_L', [280 760], 'S.x0(3)', 'S.x0(4)');
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_cubuk', [420 720], 'TranslationMethod', 'Cartesian', ...
     'TranslationCartesianOffset', '[0 -M.L/2 0]');
ekle(ad, [sb 'Brick Solid'], 'cubuk', [540 720], 'BrickDimensions', '[M.w M.L M.t]', ...
     'InertiaType', 'Custom', 'Mass', 'M.mr', 'CenterOfMass', '[0 0 0]', 'MomentsOfInertia', 'M.Ir', ...
     'ProductsOfInertia', '[0 0 0]', 'GraphicDiffuseColor', '[0.75 0.78 0.82]');
ekle(ad, [sf sprintf('Rigid\nTransform')], 'T_uc', [420 820], 'TranslationMethod', 'Cartesian', ...
     'TranslationCartesianOffset', '[0 -M.d 0]');
ekle(ad, [sb 'Cylindrical Solid'], 'uc', [540 820], 'CylinderRadius', 'M.ru', 'CylinderLength', 'M.hu', ...
     'InertiaType', 'Custom', 'Mass', 'M.mu', 'CenterOfMass', '[0 0 0]', 'MomentsOfInertia', 'M.Iu', ...
     'ProductsOfInertia', '[0 0 0]', 'GraphicDiffuseColor', '[0.15 0.35 0.7]');

% çerçeve bağlantıları (Revolute Joint: L1 = B, L2 = t; R1 = F, R2 = q, R3 = w)
fb(ad, 'dunya', 'R1', 'mekanizma', 'R1');   % çözücü bloğu 1B ağda: arayüzler iki tarafı tek ağ yapar
fb(ad, 'dunya', 'R1', 'T_eksen', 'L1');
fb(ad, 'T_eksen', 'R1', 'T_govde', 'L1');   fb(ad, 'T_govde', 'R1', 'govde', 'R1');
fb(ad, 'T_eksen', 'R1', 'T_rotor', 'L1');   fb(ad, 'T_rotor', 'R1', 'eklem_m', 'L1');
fb(ad, 'eklem_m', 'R1', 'rotor', 'R1');
fb(ad, 'eklem_m', 'R1', 'T_isaret', 'L1');  fb(ad, 'T_isaret', 'R1', 'isaret', 'R1');
fb(ad, 'T_eksen', 'R1', 'eklem_L', 'L1');
fb(ad, 'eklem_L', 'R1', 'T_cubuk', 'L1');   fb(ad, 'T_cubuk', 'R1', 'cubuk', 'R1');
fb(ad, 'eklem_L', 'R1', 'T_uc', 'L1');      fb(ad, 'T_uc', 'R1', 'uc', 'R1');

% --- 1B mekanik ağ (dişli, sönüm, tork kaynakları) ---
% Yerel örtük çözücü (Backward Euler, adım dt): Multibody eklemleri + arayüzler ağda cebirsel denklem
% bırakıyor; global açık ode4 bu ağda enerji katıyor (sönümsüz dişli salınımı büyüyor, çevrim genliği
% %40 büyük çıkıyor). Yerel Backward Euler ile 1B modelle aynı sonuç (README, Multibody bölümü).
ekle(ad, 'nesl_utility/Solver Configuration', 'cozucu', [40 420], 'UseLocalSolver', 'on', ...
     'LocalSolverChoice', 'NE_BACKWARD_EULER_ADVANCER', 'LocalSolverSampleTime', 'dt');
ekle(ad, [fm 'Rotational Elements/Mechanical Rotational Reference'], 'zemin', [300 520]);
% Rotational Multibody Interface: L1 = t (eklem torku), L2 = C; R1 = w (eklem hızı), R2 = R
ekle(ad, [fm 'Multibody Interfaces/Rotational Multibody Interface'], 'ara_m', [260 300]);
ekle(ad, [fm 'Multibody Interfaces/Rotational Multibody Interface'], 'ara_L', [620 300]);
ekle(ad, [fm 'Rotational Elements/Rotational Damper'], 'bM', [200 420], 'D', 'S.bM');
ekle(ad, [fm 'Rotational Elements/Rotational Damper'], 'bL', [680 420], 'D', 'S.bL');
ekle(ad, [fm 'Rotational Elements/Rotational Hard Stop'], 'dis', [440 300], ...
     'upper_bnd', 'S.r - (S.x0(1) - S.x0(3))', 'lower_bnd', '-S.r - (S.x0(1) - S.x0(3))', ...
     'model', 'simscape.enum.hardstop.smooth', ...
     'stiff_up', 'S.Ks', 'stiff_low', 'S.Ks', 'D_up', 'S.cs', 'D_low', 'S.cs', 'transition', 'gecis');
ekle(ad, [fm 'Mechanical Sources/Ideal Torque Source'], 'tork_m', [260 180]);
ekle(ad, [fm 'Mechanical Sources/Ideal Torque Source'], 'tork_L', [620 180]);
ekle(ad, 'nesl_utility/Simulink-PS Converter', 'sps_m', [180 120], 'Unit', 'N*m');
ekle(ad, 'nesl_utility/Simulink-PS Converter', 'sps_L', [540 120], 'Unit', 'N*m');

fb(ad, 'cozucu', 'R1', 'zemin', 'L1');
% arayüz: R = ağ düğümü (gövde), C = zemin; t -> eklem torku, eklem hızı -> w
fb(ad, 'ara_m', 'L2', 'zemin', 'L1');   fb(ad, 'ara_L', 'L2', 'zemin', 'L1');
fb(ad, 'ara_m', 'L1', 'eklem_m', 'L2');  fb(ad, 'eklem_m', 'R3', 'ara_m', 'R1');
fb(ad, 'ara_L', 'L1', 'eklem_L', 'L2');  fb(ad, 'eklem_L', 'R3', 'ara_L', 'R1');
fb(ad, 'ara_m', 'R2', 'dis', 'L1');      % hard stop R = motor
fb(ad, 'dis', 'R1', 'ara_L', 'R2');      % hard stop C = kol
fb(ad, 'bM', 'L1', 'ara_m', 'R2');  fb(ad, 'bM', 'R1', 'zemin', 'L1');
fb(ad, 'bL', 'L1', 'ara_L', 'R2');  fb(ad, 'bL', 'R1', 'zemin', 'L1');
fb(ad, 'tork_m', 'L1', 'ara_m', 'R2');  fb(ad, 'tork_m', 'R2', 'zemin', 'L1');
fb(ad, 'tork_L', 'L1', 'ara_L', 'R2');  fb(ad, 'tork_L', 'R2', 'zemin', 'L1');
fb(ad, 'sps_m', 'R1', 'tork_m', 'R1');  fb(ad, 'sps_L', 'R1', 'tork_L', 'R1');

% ölçüm: eklem algılama portları (q mutlak, hedef başlangıç değerinden)
c = {'phi','rad','eklem_m','R2'; 'dphi','rad/s','eklem_m','R3'; 'th','rad','eklem_L','R2'; 'dth','rad/s','eklem_L','R3'};
for i = 1:4
    ekle(ad, 'nesl_utility/PS-Simulink Converter', ['ps_' c{i,1}], [820 80+60*i], 'Unit', c{i,2});
    fb(ad, c{i,3}, c{i,4}, ['ps_' c{i,1}], 'L1');
end

% --- Simulink blokları (sm_kol_model ile aynı) ---
add_block('simulink/Signal Routing/Mux', [ad '/mux'], 'Inputs', '4', 'Position', [920 120 925 340]);
add_block('simulink/Sources/Clock', [ad '/saat'], 'Position', [960 20 990 50]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/yuk'], 'Position', [1040 40 1140 120]);
add_block('simulink/User-Defined Functions/MATLAB Function', [ad '/kontrolcu'], 'Position', [1200 220 1300 280]);
add_block('simulink/Discrete/Unit Delay', [ad '/durum'], 'Position', [1200 320 1240 360], ...
          'InitialCondition', 'S.st0', 'SampleTime', 'Ts');
add_block('simulink/Sinks/Out1', [ad '/x_out'], 'Position', [1000 360 1030 380], 'Port', '1');
add_block('simulink/Sinks/Out1', [ad '/u_out'], 'Position', [1360 240 1390 260], 'Port', '2');
add_block('simulink/Sinks/Out1', [ad '/olc_out'], 'Position', [1360 300 1390 320], 'Port', '3');
add_block('simulink/Sinks/Terminator', [ad '/v_bos'], 'Position', [1340 360 1360 380]);
kod_yaz([ad '/yuk'],       fullfile(kok, 'blok_yuk.m'),   '');
kod_yaz([ad '/kontrolcu'], fullfile(kok, 'blok_ayrik.m'), 'Ts');
for i = 1:4, add_line(ad, ['ps_' c{i,1} '/1'], sprintf('mux/%d', i), 'autorouting', 'on'); end
add_line(ad, 'mux/1', 'yuk/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/1', 'yuk/2', 'autorouting', 'on');
add_line(ad, 'saat/1', 'yuk/3', 'autorouting', 'on');
add_line(ad, 'yuk/1', 'sps_m/1', 'autorouting', 'on');
add_line(ad, 'yuk/2', 'sps_L/1', 'autorouting', 'on');
add_line(ad, 'mux/1', 'kontrolcu/1', 'autorouting', 'on');
add_line(ad, 'durum/1', 'kontrolcu/2', 'autorouting', 'on');
add_line(ad, 'saat/1', 'kontrolcu/3', 'autorouting', 'on');
add_line(ad, 'kontrolcu/2', 'durum/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/3', 'v_bos/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/4', 'olc_out/1', 'autorouting', 'on');
add_line(ad, 'mux/1', 'x_out/1', 'autorouting', 'on');
add_line(ad, 'kontrolcu/1', 'u_out/1', 'autorouting', 'on');

set_param(ad, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', 'dt', ...
          'StopTime', 'T', 'SaveOutput', 'on', 'OutputSaveName', 'yout', ...
          'SaveFormat', 'Dataset', 'Decimation', 'dec', 'SaveTime', 'off', ...
          'ReturnWorkspaceOutputs', 'on', 'SaveState', 'off', 'SignalLogging', 'off', ...
          'AlgebraicLoopMsg', 'none');
save_system(ad, fullfile(kok, [ad '.slx']));
close_system(ad, 0);
fprintf('%s.slx kuruldu\n', ad);
end

function eklem(ad, ad_blk, xy, q0, w0)
% Revolute Joint: tork girişi, açı + hız algılama, başlangıç açısı/hızı yüksek öncelikli hedef.
ekle(ad, 'sm_lib/Joints/Revolute Joint', ad_blk, xy, ...
     'TorqueActuationMode', 'InputTorque', 'SensePosition', 'on', 'SenseVelocity', 'on', ...
     'PositionTargetSpecify', 'on', 'PositionTargetPriority', 'High', ...
     'PositionTargetValue', q0, 'PositionTargetValueUnits', 'rad', ...
     'VelocityTargetSpecify', 'on', 'VelocityTargetPriority', 'High', ...
     'VelocityTargetValue', w0, 'VelocityTargetValueUnits', 'rad/s');
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
