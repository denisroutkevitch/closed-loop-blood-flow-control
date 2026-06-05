% Purpose: To compile the data from the real-time experiments
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
%
% To use, run the whole script. You will need to update surgery_data.mat
% with your experiment
% 
% sample injury time set
% surgery_data(27).InjuryTime = datetime('20230613 15:52:58.000', 'InputFormat','yyyyMMdd HH:mm:ss.SSS');

clear, close all;

%% Step 1: Initialize data to compile

% Load paths saved by setup_paths.m (run that script once to configure).
load('raw_path.mat');
load('processed_path.mat');

root_path = raw_path;
save_path = processed_path;

root_dir = dir(root_path);
rootexpsets = {root_dir(~contains({root_dir.name}, '.') & ~contains({root_dir.name}, 'mat') & ~contains({root_dir.name}, 'yyMMdd')).name};

% create processed directory if it does not yet exist
if ~isfolder(save_path)
    mkdir(save_path);
end

% load surgery metadata (expected one level above raw_path)
load(fullfile(fileparts(raw_path), 'surgery_data.mat'));

version_num = 1;


%% Step 2: Compile CO2 data


for rat = 1:length(rootexpsets)
    
    % extract some indexing info
    ratname = rootexpsets{rat};
    surg_date = ratname(1:6);
    inj_time = surgery_data(strcmp({surgery_data.date}, surg_date)).InjuryTime;

    
    % check if the data has been analyzed yet
    if isfile(fullfile(save_path, sprintf('%s.mat',ratname)))
        fprintf('%s has already been compiled\n', ratname)
        continue
    else
        fprintf('Now compiling %s\n', ratname)
    end
    
    % find CO2 file name
    CO2file = surgery_data(strcmp({surgery_data.date}, surg_date)).CO2file;
    
    %%%%%%%%%% CO2 LOADING %%%%%%%%%%
    if ~isempty(CO2file)
        disp('Loading Temp/CO2 data...')
        
        % import CO2 and set correct timing
        [t_CO2, Temp, CO2, startCO2] = import_time_temp_CO2(fullfile(root_path, rootexpsets{rat},'CO2-Temp', CO2file),[]);
        
        % split signal
        [~,inj_CO2] = min(abs(t_CO2-inj_time));    
        t_CO2pre = t_CO2(1:inj_CO2);
        t_CO2post = t_CO2(inj_CO2+1:end);    
        CO2pre = CO2(1:inj_CO2);
        CO2post = CO2(inj_CO2+1:end);

    else
        % create empty vectors if no CO2 data
        [t_CO2pre, t_CO2post, CO2pre, CO2post, Temp] = deal([]);
    end
    

    % Initialize ultrasound structure
    % (allows for multiple simultaneous blood flow recordings to be stored)
    US = struct();
    
    % save variables
    disp('Saving...')
    save(fullfile(save_path, sprintf('%s.mat',ratname)), ...
        "t_CO2post", "t_CO2pre", "CO2post", "CO2pre", "Temp", ...
        "inj_time", "US");

end



%% Step 5: Load real-time data


for rat = 1:length(rootexpsets)

    % extract some indexing info
    ratname = rootexpsets{rat};
    surg_date = ratname(1:6);
    inj_time = surgery_data(strcmp({surgery_data.date}, surg_date)).InjuryTime;
    RT_folder = fullfile(root_path, rootexpsets{rat},  sprintf("Real Time %s", ratname(1:6)), 'Data');

    % load existing US structure
    load(fullfile(save_path, sprintf('%s.mat',ratname)), "US");

    % find number of real-time runs
    max_file_num = {dir(RT_folder).name};
    max_file_num = max_file_num{end};
    max_file_num = str2double(max_file_num(9:11));
    
    % initialize variables
    [t_US, vel, t_BP, BP, t_target, target, t_BL, I_BL, BP_BL, Flow_BL, t_cc, controller_choice] = deal([]);
    
    % cycle through each real-time run
    for fn = 1:max_file_num
        
        fprintf('Loading Run %g out of %g\n', fn, max_file_num);
        
        % read BP
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- BP.txt", surg_date, fn)), 'r');
        BP_chunk = textscan(fid, '%f', inf);
        BP_chunk = BP_chunk{1,1};
        fclose(fid);
        
        % read BP time
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- t_BP.txt", surg_date, fn)), 'r');
        t_BP_chunk = textscan(fid, '%{yyyy-MM-dd HH:mm:ss.SSS}D', inf, 'Delimiter', '\t');
        t_BP_chunk = t_BP_chunk{1,1};
        fclose(fid);
        
        % read audio recording start time
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- US start time.txt", surg_date, fn)), 'r');
        US_meta = textscan(fid, '%s', inf, 'Delimiter', {',',': '});
        US_meta = US_meta{1,1};
        t_US_start = datetime(US_meta{1,1}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        thresh = str2double(US_meta{3,1});
        fclose(fid);
        
        % read MFV_target
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- MFV ideal.txt", surg_date, fn)), 'r');
        target_scan = textscan(fid, '%{yyyy-MM-dd HH:mm:ss.SSS}D%f', inf, 'Delimiter', {',',': '}, 'HeaderLines', 1);
        t_target_chunk = target_scan{1,1};
        target_chunk = target_scan{1,2};
        fclose(fid);
        
        % read the baseline (MFV calculated as fraction of baseline)
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- BL values.txt", surg_date, fn)), 'r');
        target_scan = textscan(fid, '%{dd-MMM-uuuu HH:mm:ss}D%f%f%f', inf, 'Delimiter', {',',': '}, 'HeaderLines', 1);
        t_BL_chunk = target_scan{1,1};
        I_BL_chunk = target_scan{1,4};
        BP_BL_chunk = target_scan{1,2};
        Flow_BL_chunk = target_scan{1,3};
        fclose(fid);
        
        % reda controller choice (if loaded multiple controllers)
        try
            fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- controller choice.txt", surg_date, fn)), 'r');
            controller_chunk = textscan(fid, '%{dd-MMM-uuuu HH:mm:ss}D%s', inf, 'Delimiter', {',',': '}, 'HeaderLines', 1);
            fclose(fid);
    
            t_cc = [t_cc; controller_chunk{1,1}];
            controller_choice = [controller_choice; string(controller_chunk{1,2})];
        end
        

        % read MFV time (this was used for controller if closed-loop)
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- t_US.txt", surg_date, fn)), 'r');
        target_scan = textscan(fid, '%D', inf, 'Delimiter', {',',': '}, 'HeaderLines', 1);
        t_US_chunk = target_scan{1,1};
        fclose(fid);

        % read MFV (this was used for controller if closed-loop)
        fid = fopen(fullfile(RT_folder, sprintf("%s -%03g- US.txt", surg_date, fn)), 'r');
        target_scan = textscan(fid, '%f', inf, 'Delimiter', {',',': '}, 'HeaderLines', 1);
        US_chunk = target_scan{1,1};
        fclose(fid);
        
        % concatenate this real-time run with entire trace
        t_US = [t_US; t_US_chunk];
        vel = [vel; US_chunk];
        t_BP = [t_BP; t_BP_chunk];
        BP = [BP; BP_chunk];
        t_target = [t_target; t_target_chunk];
        target = [target; target_chunk];
        t_BL = [t_BL; t_BL_chunk];
        I_BL = [I_BL; I_BL_chunk];
        BP_BL = [BP_BL; BP_BL_chunk];
        Flow_BL = [Flow_BL; Flow_BL_chunk];

        
    end
    
    % apply averaging filter for vertical resolution enhancement
    filt_size = 32;
    avfilt = ones(filt_size,1)/filt_size;
    BP = conv(BP, avfilt, 'valid');
    t_BP = t_BP(filt_size/2:end-filt_size/2);
    
    % split signal into pre and post injury
    [~,inj_BP] = min(abs(t_BP-inj_time));    
    t_BPpre = t_BP(1:inj_BP);
    t_BPpost = t_BP(inj_BP+1:end);    
    BPpre = BP(1:inj_BP);
    BPpost = BP(inj_BP+1:end);

    [~,inj_US] = min(abs(t_US-inj_time));            
    t_USpre = t_US(1:inj_US);
    t_USpost = t_US(inj_US+1:end);            
    velpre = vel(1:inj_US);
    velpost = vel(inj_US+1:end);
    
    % load blood flow into structure
    US(end+1,:).Label = 'PWD Frequency';
    US(end).AnalysisDate = datetime('today');
    US(end).TimePre = t_USpre;
    US(end).USPre = velpre;
    US(end).TimePost = t_USpost;
    US(end).USPost = velpost;

    if isempty(US(1).Label)
        US = US(2:end);
    end
    
    % save results
    save(fullfile(save_path, sprintf('%s.mat',ratname)), "US", "t_BPpost", "t_BPpre", "BPpost", "BPpre",...
            "target", "t_target", "t_BL", "I_BL", "BP_BL", "Flow_BL",...
            "t_cc", "controller_choice", "-append");
end


%% Step 7: Load syringe pump data



for rat = 1:length(rootexpsets)
    
    % extract some indexing info
    ratname = rootexpsets{rat};
    surg_date = ratname(1:6);
    
    % check for syringe pump traces
    if isfile(fullfile(root_path, rootexpsets{rat}, sprintf("Real Time %s", ratname(1:6)),...
                       sprintf('%s Infusion.txt', datetime(surg_date, 'InputFormat', 'yyMMdd'))))
        
        % this is to cap end of eventual syringe pump trace
        try
            end_time = load(fullfile(save_path, sprintf('%s.mat',ratname))).t_BPpost(end);
        catch
            end_time = load(fullfile(save_path, sprintf('%s.mat',ratname))).t_BPpre(end);
        end
        
        fprintf('Compiling syringe pump traces for %s\n', ratname)
        
        % import time and dose as recorded by pump
        [time, dose_rate] = import_drug_data(fullfile(root_path, rootexpsets{rat},sprintf("Real Time %s", ratname(1:6)),...
                       sprintf('%s Infusion.txt', datetime(surg_date, 'InputFormat', 'yyMMdd'))));
        
        % interpolate into proper sampling rate
        t_DR = linspace(time(1), end_time, 10000000)';
        if time(end)==datetime(Inf, 'ConvertFrom', 'datenum')
            time(end) = end_time;
        end
        DR = interp1(time,dose_rate,t_DR, 'previous');  % ug/kg/s

        save(fullfile(save_path, sprintf('%s.mat',ratname)), "t_DR", "DR", "-append");

    else
        fprintf('Syringe pump traces do not exist for %s\n', ratname)
    end


end



%% Step 7: Load vacuum pump data


for rat = 1:length(rootexpsets)
    
    % extract some indexing info
    ratname = rootexpsets{rat};
    surg_date = ratname(1:6);
        
    % check for vacuum pump traces
    if isfile(fullfile(root_path, rootexpsets{rat},sprintf("Real Time %s", ratname(1:6)),...
                       sprintf('%s Ratcuum.txt', datetime(surg_date, 'InputFormat', 'yyMMdd'))))
        
        fprintf('Compiling vacuum traces for %s\n', ratname)

        
        % import time and setting as recorded by pump
        [time, vac_setting] = import_ratcuum(fullfile(root_path, rootexpsets{rat},sprintf("Real Time %s", ratname(1:6)),...
                       sprintf('%s Ratcuum.txt', datetime(surg_date, 'InputFormat', 'yyMMdd'))));
        
        % interpolate to proper sampling rate
        t_V = linspace(time(1), time(end),10000000)';
        V = interp1(time,vac_setting,t_V, 'previous');

        save(fullfile(save_path, sprintf('%s.mat',ratname)), "t_V", "V", "-append");

    else
        fprintf('Vacuum traces do not exist for %s\n', ratname)
    end
end