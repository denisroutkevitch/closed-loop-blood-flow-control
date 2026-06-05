% Purpose: Curate data from real-time feedback control experiments
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

clear, close all;

%% Step 0: Define color palette and other parameters

load('plot_colors.mat')

fig_pos = [360,463,160,150];
alpha_lbnp = 0.1;

load('repo_path.mat');

% Choose save path
save_fig_path = fullfile(repo_path, 'Saved Figures');
data_path = fullfile(repo_path, 'Feedback Control');


%% Step 1: Load Data


% filter for only data
exp_files = {dir(data_path).name};
exp_files = exp_files(contains(exp_files, '25') & contains(exp_files, '.mat'));

% select subject extract individual challenge
subject_num = length(exp_files);

fprintf('%s\n', exp_files{subject_num});
subject_name = erase(exp_files{subject_num}, '.mat');
fname1 = fullfile(data_path,sprintf("%s.mat", subject_name));

% load file and concatenate (needed due to old file structure)
load(fname1);

% concatenate pre and post injury
t_BP = [t_BPpre; t_BPpost];
BP = [BPpre; BPpost];

t_US = [US.TimePre; US.TimePost];
US = [US.USPre; US.USPost];

t_CO2 = [t_CO2pre; t_CO2post];
CO2 = [CO2pre; CO2post];

% remove empty BP values
t_BP(isnan(BP)) = [];
BP(isnan(BP)) = [];

% If there is no vacuum trace, create empty trace
if ~exist('V', 'var') | max(t_V)<min(t_BP)
    t_V = datetime([],[],[]);
    V = [];
end


%% Step 2: Get target curve from data

    
% deal with if there are repeated time values
[t_BL, ia, ~] = unique(t_BL);
Flow_BL = Flow_BL(ia);

% find parts of baseline curve without averaging artifact for each switch
inds_keep = [(~(diff(Flow_BL)~=0) | diff(t_BL)>seconds(3)) & ~(diff(t_BL)==0);true];

% resample to target signal
Flow_BL_resamp = interp1(t_BL(inds_keep), Flow_BL(inds_keep), t_target, "previous");

% In real-time code, actual target was set as multiple of baseline
Flow_target = Flow_BL_resamp.*target;


%% Step 3: Plot entire trace for reference

figure(1)
set(figure(1), 'Position', [88,90,1357,739])

alpha_lbnp = 1;


% MAP
ax2 = subplot(3,1,1); plot(t_BP, movmean(BP, 5000), 'LineStyle','none', 'Marker','.','MarkerEdgeColor', MAP_color);
hold on;
ylabel('BP (mmHg)');
ylim([50 150])
% area(t_V, (V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
title('Mean Arterial Pressure')
set(ax2,'FontWeight','bold')
set(ax2,'LineWidth',1.5)
hold off

% % CO2 (for CO2 challenges)
% ax2 = subplot(3,1,1); plot(t_CO2, movmax(CO2, 5000), 'LineStyle','none', 'Marker','.','MarkerEdgeColor', MAP_color);
% hold on;
% ylabel('etCO2 (mmHg)');
% ylim([30 75])
% % area(t_V, (V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
% title('Mean Arterial Pressure')
% set(ax2,'FontWeight','bold')
% set(ax2,'LineWidth',1.5)
% hold off

% MFV
ax3 = subplot(3,1,2); plot(t_US, robust_butter_median(t_US, US, 5,0.05), 'LineStyle','none', 'Marker','.','MarkerEdgeColor',Flow_color);
hold on;
plot(t_target, Flow_target, 'LineStyle',':', 'LineWidth',2,'Color',Flow_color)
ylim([ax3.YLim])
ylim([2 8.5])
title('Spinal Cord Blood Flow Velocity')
ylabel({'Flow Velocity','(cm/s)'});
set(ax3,'FontWeight','bold')
set(ax3,'LineWidth',1.5)
xlim([ax2.XLim])
% area(t_V, (V>0)*(ax3.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
hold off

% infusion rate
ax1 = subplot(3,1,3); plot(t_DR, DR*60, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color);
hold on;
title('Infusion Rate');
ylabel({'Infusion Rate','(\mug/kg/min)'})
set(ax1,'FontWeight','bold')
set(ax1,'LineWidth',1.5)
% ax1.YLim(1)=-1;
% ylim([ax1.YLim])
ylim([-0.1 3])
xlim([ax2.XLim])
% area(t_V, (2*(V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
hold off

disp('Inspect the full trace above. To save and continue, re-run the script starting from Step 3.1.')
return


%% Step 3.1: Save overall trace

if ~isfile(fullfile(data_path,'Traces',sprintf("%s.png", subject_name)))
    exportgraphics(figure(1), fullfile(data_path,'Traces',sprintf("%s.png", subject_name)), 'Resolution',600);
end


%% Step 4: Export specific time period as figure and save time for mat generation


alpha_lbnp = 0.05;
alpha_trace = 0.01;

%%% USE THIS VARIABLE TO PERUSE THE SIGNAL %%%
time_inds = datetime(2000+str2double(subject_name(1:2)), str2double(subject_name(3:4)), str2double(subject_name(5:6)),...
                        17, 06, 0, 'Format','yyyyMMdd HHmmss') + minutes([0 6]);  % OL


% separate times
min_time = time_inds(1);
max_time = time_inds(2);

%find indices
[~,I_cc(1)] = min(abs(t_cc-min_time));
[~,I_cc(2)] = min(abs(t_cc-max_time));

%nfind controller used
[cc_string, ia,~] = unique([controller_choice(I_cc(1):I_cc(2))]);

% in case multiple controllers were done in time selection
if length(cc_string)>1
    warning("Multiple Controller Types")
    cc_string= "Mixed Controller";
    fprintf('%8s %8s\n', t_cc(I_cc(1)+ia)-min_time, controller_choice(I_cc(1)+ia))
end

if isempty(max_time)
    max_time = max(t_pre-inj_time)/60;
end

% synchronized windows
window = [min_time, max_time];
lineint = minutes(10);

% figure for easy reference
figure(1)
set(figure(1), 'Position', [60,360,185, 175])


% infusion
ax1 = subplot(3,1,1); plot(t_DR-min_time, DR*60, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color);
hold on;
xlim([min_time, max_time]-min_time)
% title('Infusion Rate');
ylabel({'I_{NE}','(\mug/kg/min)'})
ax1.YLim(1)=-0.05;
ylim([ax1.YLim])
area(t_V-min_time, (2*(V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
area(t_V-min_time, (2*(V>30)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp*2, BaseValue=-10);
set(ax1,'FontSize',7);
set(ax1,'LineWidth',1.5)
set(ax1,'xticklabel',{[]})
hold off

% MAP
ax2 = subplot(3,1,2); plot(t_BP-min_time, movmean(BP, 5000), 'LineStyle','none', 'Marker','.','MarkerEdgeColor', MAP_color);
hold on;
xlim([min_time, max_time]-min_time)
bp_lims = ax2.YLim+[-10 10];
plot(t_BP-min_time, BP, 'Color', [hex2rgb(MAP_color), alpha_trace], 'LineWidth',1.25);
ylabel({'MAP', '(mmHg)'})
ylim(bp_lims)
area(t_V-min_time, (V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
% title('Mean Arterial Pressure')
set(ax2,'FontSize',7);
set(ax2,'LineWidth',1.5)
set(ax2,'xticklabel',{[]})
hold off

% % CO2 (for CO2 challenges)
% ax2 = subplot(3,1,2); plot(t_CO2-min_time, movmax(CO2, 5000), 'LineStyle','none', 'Marker','.','MarkerEdgeColor', MAP_color);
% hold on;
% xlim([min_time, max_time]-min_time)
% bp_lims = ax2.YLim+[-5 5];
% % plot(t_BP-min_time, BP, 'Color', [hex2rgb(MAP_color), alpha_trace], 'LineWidth',1.25);
% ylabel({'etCO_2', '(mmHg)'})
% ylim(bp_lims)
% area(t_V-min_time, (V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
% % title('Mean Arterial Pressure')
% set(ax2,'FontSize',7);
% set(ax2,'LineWidth',1.5)
% set(ax2,'xticklabel',{[]})
% hold off

% MFV
ax3 = subplot(3,1,3); plot(t_US-min_time, robust_butter_median(t_US, US, 5,0.05), 'LineStyle','none', 'Marker','.','MarkerEdgeColor',Flow_color); 
% ax3 = subplot(3,1,3); plot(t_US-min_time, US, 'LineStyle','none', 'Marker','.','MarkerEdgeColor',Flow_color); % NIRS
hold on;
plot(t_target-min_time, Flow_target, 'LineStyle',':', 'LineWidth',1.25,'Color',Flow_color)
xlim([min_time, max_time]-min_time)
ylim([ax3.YLim]+[-0.1 0.1])
% ylim([5 10])
plot(t_US-min_time, US, 'Color', [hex2rgb(Flow_color), alpha_trace]);
% title('Spinal Cord Blood Flow Velocity')
ylabel({'MFV','(cm/s)'})
set(ax3,'FontSize',7);
set(ax3,'LineWidth',1.5)
ax3.XTickLabel = minutes(ax3.XTick);
xlabel('Time (min)')
area(t_V-min_time, (V>0)*(ax3.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
hold off


%% Step 5: Save

%%% extract and store data from all challenges %%%
% create overarching directory if needed 
if ~isfolder(fullfile(data_path,'Challenge Trials'))
    mkdir(fullfile(data_path,'Challenge Trials'));
end

% get existing challenge categories
chal_folders = {dir(fullfile(data_path,'Challenge Trials')).name};
chal_folders = chal_folders(2:end);
[indx,tf] = listdlg('PromptString',{'Select Challenge Type', '(select ".." for new type)'},...
        'SelectionMode','single','ListString',chal_folders);

% option to create new category if ".." is chosen
if indx == 1
    foldername = inputdlg('Enter New Challenge Type');
    foldername = foldername{1};
    mkdir(fullfile(data_path,'Challenge Trials', foldername))
else
    foldername = chal_folders{indx};
end

if cc_string == "Mixed Controller"
    cc_string = inputdlg('Both controllers in set, enter controller type:');
    cc_string = cc_string{1};
end


exportgraphics(figure(1), ...
    fullfile(data_path,'Challenge Trials', foldername, sprintf('%s %s.png',min_time, cc_string)), 'Resolution', 1200);

% print(figure(1), '-vector', '-depsc', fullfile(data_path,'Challenge Trials', foldername, sprintf('%s %s.eps',min_time, cc_string)));

writecell({time_inds(1), time_inds(2)}, fullfile(data_path,'Challenge Trials', foldername, 'Trace Timings.txt'), 'WriteMode', 'append')


%% Final Step: Generate mat files from all times that have not yet been generated

files_from_times(fullfile(data_path,'Challenge Trials'))
