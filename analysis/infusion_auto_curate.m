clear all, close all

% Purpose: To automatically standardly generate signal "trials" for each 
% function with proper documentation when DR already exists
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

%% Step 1: Choose experiment to sync

% Choose data path (folder with mat files from preprocessing pipeline)
load('repo_path.mat')
data_path = fullfile(repo_path, 'Sample Processed Directory');


% filter for only data
exp_files = {dir(data_path).name};
exp_files = exp_files(contains(exp_files, '.mat'));

% select subject extract individual challenge
subject_num = length(exp_files);

fprintf('%s\n', exp_files{subject_num});
subject_name = erase(exp_files{subject_num}, '.mat');
fname1 = fullfile(data_path,sprintf("%s.mat", subject_name));

% export trace preview of entire experiment
if ~isfile(fullfile(data_path,'Traces', sprintf("%s.png", subject_name)))
    trace_plot_from_file(fname1, 'PWD Frequency');
    if ~isfolder(fullfile(data_path,'Traces'))
        mkdir(fullfile(data_path,'Traces'))
    end
    savefig(figure(2), fullfile(data_path,'Traces',sprintf("%s.fig", subject_name)));
    exportgraphics(figure(2), fullfile(data_path,'Traces',sprintf("%s.png", subject_name)), 'Resolution',600);
    close(figure(2))
end

load(fname1)


%% Step 2: Synchronize data

% zeropadding for DR to add usable length for challenges
t_DR = [t_DR(end-500000:end-1)-(t_DR(end)-t_DR(1)); t_DR; t_DR(2:1000001)+(t_DR(end)-t_DR(1))];
DR_full = [zeros(500000,1); DR; zeros(1000000,1)];  % ug/kg/s

% removes nan for easier sync
t_BP = [t_BPpre; t_BPpost];
BP_full = [BPpre; BPpost];
t_BP = t_BP(~isnan(BP_full));
BP_full = BP_full(~isnan(BP_full));

% removes nan for easier sync
t_US = [US.TimePre; US.TimePost];
US_full = [US.USPre; US.USPost];
t_US = t_US(~isnan(US_full));
US_full = US_full(~isnan(US_full));

% Remove corrupted leading samples and enforce monotonically increasing timestamps.
% Uncomment and adjust the index offset if your recording starts with invalid data.
% t_US = t_US(1000:end);
% US_full = US_full(1000:end);
% US_full = US_full((t_US(2:end)-t_US(1:end-1))>0);
% t_US = t_US((t_US(2:end)-t_US(1:end-1))>0);



% save for later storage of time
inj_time_dt = inj_time;

% convert datetime to seconds
t_BP = hour(t_BP)*3600+minute(t_BP)*60+second(t_BP);
t_US = hour(t_US)*3600+minute(t_US)*60+second(t_US);
t_DR = hour(t_DR)*3600+minute(t_DR)*60+second(t_DR);
inj_time = hour(inj_time)*3600+minute(inj_time)*60+second(inj_time);

% synchronize
[t_full, BP_full, US_full, DR_full] = samplesync(t_BP-inj_time, BP_full, t_US-inj_time, US_full, t_DR-inj_time, DR_full, 500);
fs = 1/(t_full(2)-t_full(1));

% conversion from frequency to flow velocity and transpose
t_full = t_full';
BP_full = BP_full';
Flow_full = 0.01*US_full' + 1; % Hz --> cm/s
DR_full = DR_full';


%% Step 2.9: Manually figure out basal drug infusion rate

% Inspect the drug infusion trace to identify the baseline (basal) rate.
% Set basal_DR in Step 3, then re-run from Step 3 onward.
plot(DR_full)
disp('Inspect the drug infusion trace above, then set basal_DR in Step 3 and re-run from Step 3.')
return


%% Step 3: Save each impulse

close all

%%% add basal rate variable
% (challenges determined by change in infusion rate from this value)
basal_DR = DR_full(1244240); % SAMPLE-SPECIFIC index; re-read from Step 2 for new data. (single baseline)
% basal_DR = DR_full([780855, 2181260]); % if two baselines at different times


%%% find all impulses from experiment %%%
imp_locs = bwconncomp(abs(DR_full-basal_DR(1))>0.0001).PixelIdxList; % small changes exist
% imp_locs = bwconncomp(abs(DR_full-basal_DR(1))>0.001).PixelIdxList; % only large changes

% additional locations if basal rate changes
% imp_locs = [imp_locs, bwconncomp(abs(DR_full-basal_DR(2))>0.001).PixelIdxList]; % if basal_rate changes
% imp_locs = [imp_locs, bwconncomp(abs(DR_full-basal_DR(2))>0.001).PixelIdxList, bwconncomp(abs(DR_full-basal_DR(3))>0.001).PixelIdxList]; % if basal_rate changes twice


%%% the following can enable you to skip experimental calibration steps %%%
imp_locs = imp_locs(1:end);

%%% extract and store data from all challenges %%%
% create overarching directory if needed
if ~isfolder(fullfile(data_path,'TF by Challenge Type'))
    mkdir(fullfile(data_path,'TF by Challenge Type'));
end

% get existing challenge categories
TF_folders = {dir(fullfile(data_path,'TF by Challenge Type')).name};
TF_folders = TF_folders(2:end);
[indx,tf] = listdlg('PromptString',{'Select Challenge Type', '(select ".." for new type)'},...
        'SelectionMode','single','ListString',TF_folders);

% option to create new category if ".." is chosen
if indx == 1
    foldername = inputdlg('Enter New Challenge Type');
    mkdir(fullfile(data_path,'TF by Challenge Type', foldername{1}))
else
    foldername = TF_folders{indx};
end

% Stop button to check abort data collection.
[stopFig.f, stopFig.h] = stopButton();   
flag = 1; % Use flag variable to indicate if stop button has been clicked (0)
setappdata(stopFig.f, 'run', flag);

% go through all challenges
for id = fliplr(1:length(imp_locs))
    inds = [];
    imp_inds = imp_locs{id};
    
    % find impulse time
    imp_start = t_full(imp_inds(1));
    imp_end = t_full(imp_inds(end));
    zero_times = inj_time_dt + seconds(imp_start);
    
    % uncomment for easier determination of good recordings (imp_locs sub-indices)
%     fprintf('Index: %d, Time: %s\n', id, zero_times)
%     continue
    
    % bounds on each impulse
    [~, inds(1)] = min(abs(t_full - imp_start + 60));
    [~, inds(2)] = min(abs(t_full - imp_end - 120));
    inds = inds(1):inds(2);
    
    % extract each needed signal
    time = t_full(inds)-imp_start;
    DR = DR_full(inds)*60/1000;  % mg/kg/min
    BP = BP_full(inds);
    Flow = Flow_full(inds);
    ts = 1/fs;
    
    % calculate dose for drug bounds determination
    dose = max(DR)*length(imp_locs{id})/(fs*60);  % mg/kg
    
    % save name
    this_save = sprintf('%s Impulse %02d - %.2f ugperkg', subject_name(1:6), id, dose*1000);
    

    % plot for export
    figure(2)
    set(figure(2), 'Position', [360,100,450,480])
    subplot(3,1,1), plot(zero_times(1) + seconds(time), DR, 'LineWidth',1.25);
    set(gca,'LineWidth',1.5);
    ylabel('Infusion Rate (mg/kg/min)')
    title(this_save)
    % ylim([0 3*CRI_rate])
    
    subplot(3,1,2), plot(zero_times(1) + seconds(time), BP);
    set(gca,'LineWidth',1.5);
    ylabel('BP (mmHg)')
    
    subplot(3,1,3), plot(zero_times(1) + seconds(time), Flow);
    set(gca,'LineWidth',1.5);
    ylabel('Flow Velocity (cm/s)')

    
    % save data and plot
    save(fullfile(data_path, 'TF by Challenge Type', foldername, sprintf("%s.mat", this_save)), ...
            'time', 'Flow', 'BP', 'DR', 'ts', 'zero_times', 'dose') 

    exportgraphics(figure(2), fullfile(data_path, 'TF by Challenge Type', foldername, sprintf("%s.png", this_save)), 'Resolution', '600') 


    % Check if 'STOP' button has been pressed.
    flag = getappdata(stopFig.f, 'run');
    drawnow;
    if(flag == 0)
        disp('STOP button clicked - aborting data collection.');
        break;        
    end

end

close(stopFig.f)
