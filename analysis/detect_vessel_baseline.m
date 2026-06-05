% Function: detect_vessel_baseline
%
% Purpose: Find baseline MFV at 85 mmHg for all experiments in folder
%
% Input parameters: 
%       data_path: string (path to peruse for any ungenerated mat files)
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


function detect_vessel_baseline(data_path)
    
    % filter for only data
    exp_files = {dir(data_path).name};
    exp_files = exp_files(contains(exp_files, ".mat") & ~contains(exp_files, "Trace Log") & ~contains(exp_files, "Baselines"));
    
    if isfile(fullfile(data_path, "Flow Baselines.mat"))
        load(fullfile(data_path, "Flow Baselines.mat"));
    else
        bl_table = struct('Experiment', {});
    end
    
    % find flow baseline for each subject in the table
    for subject_num = 1:length(exp_files)
        
        fprintf('%s\n', exp_files{subject_num});
        subject_name = erase(exp_files{subject_num}, '.mat');
        fname1 = fullfile(data_path,sprintf("%s.mat", subject_name));
        
        % skip any files that have already been done
        if ismember(subject_name, {bl_table.Experiment})
            continue;
        end

        load(fname1)
        
        
        US_ind = find(ismember({US.Label}, 'PWD Frequency'));

        % store experiment name
        bl_table(subject_num).Experiment = subject_name;

        % if no blood flow, ignore
        if isempty(US_ind)
            continue;
        end
    
        % removes nan for easier sync
        t_BP = [t_BPpre; t_BPpost];
        BP_full = [BPpre; BPpost];
        t_BP = t_BP(~isnan(BP_full));
        BP_full = BP_full(~isnan(BP_full));
        
        % removes nan for easier sync
        t_US = [US(US_ind).TimePre; US(US_ind).TimePost];
        US_full = [US(US_ind).USPre; US(US_ind).USPost];
        t_US = t_US(~isnan(US_full));
        US_full = US_full(~isnan(US_full));
        
        % convert datetime to seconds
        t_BP = hour(t_BP)*3600+minute(t_BP)*60+second(t_BP);
        t_US = hour(t_US)*3600+minute(t_US)*60+second(t_US);
        inj_time = hour(inj_time)*3600+minute(inj_time)*60+second(inj_time);
        
        % synchronize
        [t_full, BP_full, US_full] = samplesync(t_BP-inj_time, BP_full, t_US-inj_time, US_full, 500);
        fs = 1/(t_full(2)-t_full(1));
        
        % conversion from frequency to flow velocity and transpose
        t_full = t_full';
        BP_full = BP_full';
        Flow_full = 0.01*US_full' + 1; % Hz --> cm/s
        warning("check Flow conversion Hz --> cm/s")
        
        % filter the signals
        BP_filt = robust_butter(t_full, BP_full, 2, 0.05);
        Flow_filt = robust_butter(t_full, Flow_full, 2,0.05);
    
        % if pre injury exists, normalize to pre
        % otherwise normalize to post
        if(sum(t_full<0))
            % average all BP and Flow where MAP is within 3 mmHg of 85 mmHg
            inds = find(abs(BP_filt-85)<3 & t_full<0);
        else
            % average all BP and Flow where MAP is within 3 mmHg of 85 mmHg
            inds = find(abs(BP_filt-85)<3);
        end
    
        % store mean MAP and Flow as calculated
        bl_table(subject_num).MeanBP = mean(BP_filt(inds));
        bl_table(subject_num).StdBP = std(BP_filt(inds));
        bl_table(subject_num).MeanFlow = mean(Flow_filt(inds));
        bl_table(subject_num).StdFlow = std(Flow_filt(inds));
    
        
    end
    
    save(fullfile(data_path, 'Flow Baselines.mat'), 'bl_table')
end