clear; close all;
% Purpose: To manually generate signal "trials" for each transfer
% function with proper documentation
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

%% Step 1: Label the trials for a test subject and extract data

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

% run dataset extraction and synchronization
[time, Flow_freq, BP, CO2, ts, zero_times] = datasets_from_file(fname1, 'PWD Frequency');

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

% conversion from frequency to flow velocity
Flow = 0.01*Flow_freq + 1; % Hz --> cm/s

fprintf('Challenge start at %s \n', zero_times)


%% Step 2: Extract drug infusion rate

% load infusion for back compatibility
% (datasets_from_file does not return DR)
DR_full = load(fname1).DR;
t_DR_full = load(fname1).t_DR;

% find bounds within infusion curve
[~, inds(1)] = min(abs(t_DR_full - (seconds(time(1))+zero_times)));
[~, inds(2)] = min(abs(t_DR_full - (seconds(time(end))+zero_times)));
inds = inds(1):inds(2);

% extract DR
DR = interp1(t_DR_full, DR_full, seconds(time)+zero_times);


% allow user option to autocalculate the sync point from infusion
answer = questdlg('Autocalculate sync point from signal?', "Sync", ...
    "Infusion", "No", "No");

switch answer
    case 'Infusion'
        % determine first change in infusion rate
        zero_ind = find(diff(DR)~=0, 1);
        new_zero = time(zero_ind);
        
        % reorient to that point being time 0
        zero_times = zero_times - seconds(new_zero);
        time = time - new_zero;

    case 'No'

end

% plot confirmation
figure(1)
set(figure(1), 'Position', [360,100,450,480])
subplot(3,1,1), plot(zero_times(1) + seconds(time), DR, 'LineWidth',1.25);
set(gca,'LineWidth',1.5);
ylabel('Infusion Rate (mg/kg/min)')
% ylim([0 3*CRI_rate+0.0001])

subplot(3,1,2), plot(zero_times(1) + seconds(time), BP);
set(gca,'LineWidth',1.5);
ylabel('BP (mmHg)')

subplot(3,1,3), plot(zero_times(1) + seconds(time), Flow);
set(gca,'LineWidth',1.5);
ylabel('Flow Velocity (cm/s)')


%% Step 3: Save the traces

% create overarching directory if needed
if ~isfolder(fullfile(data_path,'TF by Challenge Type'))
    mkdir(fullfile(data_path,'TF by Challenge Type'));
end

% get existing challenge categories
TF_folders = {dir(fullfile(data_path,'TF by Challenge Type')).name};
TF_folders = TF_folders(2:end);
[indx,tf] = listdlg('PromptString','Select Challenge Type',...
        'SelectionMode','single','ListString',TF_folders);

% option to create new category if ".." is chosen
if indx == 1
    foldername = inputdlg('Enter New Challenge Type');
    mkdir(fullfile(data_path,'TF by Challenge Type', foldername{1}))
else
    foldername = TF_folders{indx};
end

% choose save name for this challenge
prompt = 'Enter save name';
dlgtitle = '';
answer = inputdlg(prompt,dlgtitle);
this_save = sprintf('%s %s', subject_name(1:6), answer{1});

% add title to plot
subplot(3,1,1), title(this_save)

% export data and plot
save(fullfile(data_path, 'TF by Challenge Type', foldername, sprintf("%s.mat", this_save)), ...
            'time', 'Flow', 'BP', 'CO2', 'DR', 'ts', 'zero_times') 

% save(fullfile(data_path, 'TF by Challenge Type', foldername, sprintf("%s.mat", this_save)), ...
%             'time', 'Flow', 'BP', 'CO2', 'DR', 'ts', 'zero_times',...
%             'time_end', 'bolus_rate', 'bolus_volume', "CRI_rate", "drug_conc", "subj_weight") 


exportgraphics(figure(1), fullfile(data_path, 'TF by Challenge Type', foldername, sprintf("%s.png", this_save)), 'Resolution', '600') 



