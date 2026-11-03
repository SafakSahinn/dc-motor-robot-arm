function slx_detay(cikis)
% Üç modelin diyagramını, MATLAB Function kodunu, blok/parametre listesini ve
% çözücü ayarlarını <cikis>/detay altına aktarır (raporun Ek A'sı ve Bölüm 9'daki diyagramlar).
repo = 'C:\Users\safak\Desktop\dc-motor-robot-arm\simulasyon';
kok = fullfile(repo, 'simulink');
addpath(repo, kok, fullfile(repo, '4a_ghaffari'));
cd(cikis);
Simulink.fileGenControl('set', 'CacheFolder', cikis, 'CodeGenFolder', cikis);
d = fullfile(cikis, 'detay');  if ~exist(d, 'dir'), mkdir(d); end
mdir = kok;
mdls = {'kol_model', 'sm_kol_model', 'sm_motor_model'};
fid = fopen(fullfile(d, 'bloklar.tsv'), 'w', 'n', 'UTF-8');
fc = fopen(fullfile(d, 'cozucu.tsv'), 'w', 'n', 'UTF-8');
for k = 1:3
    m = mdls{k};
    load_system(fullfile(mdir, [m '.slx']));
    print(['-s' m], '-dpng', '-r200', fullfile(d, [m '__ust.png']));
    fprintf(fc, '%s\tSolver\t%s\n', m, get_param(m, 'Solver'));
    fprintf(fc, '%s\tFixedStep\t%s\n', m, get_param(m, 'FixedStep'));
    fprintf(fc, '%s\tStopTime\t%s\n', m, get_param(m, 'StopTime'));
    fprintf(fc, '%s\tDecimation\t%s\n', m, get_param(m, 'Decimation'));
    b = find_system(m, 'SearchDepth', 1, 'Type', 'Block');
    for j = 1:numel(b)
        y = b{j};  if strcmp(y, m), continue, end
        ad = get_param(y, 'Name');
        tip = get_param(y, 'BlockType');
        ref = '';
        try, ref = get_param(y, 'ReferenceBlock'); catch, end
        if strcmp(tip, 'SubSystem')
            try
                if strcmp(get_param(y, 'SFBlockType'), 'MATLAB Function')
                    tip = 'MATLAB Function';
                    rt = sfroot;  ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', y);
                    if ~isempty(ch)
                        fw = fopen(fullfile(d, sprintf('%s__%s.m.txt', m, regexprep(ad, '\W', '_'))), 'w', 'n', 'UTF-8');
                        fwrite(fw, ch(1).Script, 'char');  fclose(fw);
                    end
                end
            catch, end
        end
        par = '';
        try
            dp = get_param(y, 'DialogParameters');
            if isstruct(dp)
                f = fieldnames(dp);
                for i = 1:numel(f)
                    if endsWith(f{i}, {'_unit', '_conf', '_priority', '_specify'}), continue, end
                    try
                        v = get_param(y, f{i});
                        if ischar(v) && ~isempty(v) && numel(v) < 60
                            par = [par sprintf('%s=%s; ', f{i}, v)]; %#ok<AGROW>
                        end
                    catch, end
                end
            end
        catch, end
        ref = strrep(ref, newline, ' ');  ad = strrep(ad, newline, ' ');
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\n', m, ad, tip, ref, par);
    end
    close_system(m, 0);
end
fclose(fid);  fclose(fc);
disp('tamam');
end
