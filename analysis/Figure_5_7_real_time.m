% Purpose: Generate system ID plots for figures 5 and 7
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

clear, close all;

%% Step 0: Define color palette and other parameters

load('plot_colors.mat')

fig_pos = [698,211,185, 175];

load('repo_path.mat');

% Choose save path
save_fig_path = fullfile(repo_path, 'Saved Figures');
data_path = fullfile(repo_path, 'Feedback Control', 'Challenge Trials');


%% Step 1: Choose challenge for comparison

% Run one of the sections labeled Step 1_, corresponding to the labeled
% challenge type / figure number


%% Step 1A: Target Change in the Rat (Figure 5b/e)

chal_type = "Rat";

%%% Target Change %%%
data_path_CL = fullfile(data_path, "Rat Target Change");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%% Step 1A: Rapid Decrease in the Rat (Figure 5c/f)

chal_type = "Step";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Rat Step Closed Loop");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Rat Step Open Loop");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 1C: Gradual Decrease in the Rat (Figure 5d/g)

chal_type = "Slope";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Rat Slope Closed Loop");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Rat Slope Open Loop");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 1D: Target Change in the Pig (Figure 7b/d)

chal_type = "Pig Target Change";

%%% Target Change %%%
data_path_CL = fullfile(data_path, "Pig Target Change");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%% Step 1E: Rapid Decrease in the Pig (Figure 7c/e)

chal_type = "Pig Hem";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Pig Hemorrhage CL");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Pig Hemorrhage OL");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 1Fi: Intraspinal Pressure in the Pig (Supplementary Fig 24b)

chal_type = "Pig ISP Chain";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Pig ISP CL Chain");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Pig ISP OL Chain");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 1Fii: Intraspinal Pressure in the Pig (Individual Challenges for Supplementary Fig 24c)

chal_type = "Pig ISP";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Pig ISP CL");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Pig ISP OL");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 1G: CO2 in the Pig (Supplementary Fig 25)

chal_type = "Pig CO2";

%%% Closed Loop %%%
data_path_CL = fullfile(data_path, "Pig CO2 CL");

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


%%% Open Loop %%%
data_path_OL = fullfile(data_path, "Pig CO2 OL");

% find all challenges
chal_files_OL = {dir(data_path_OL).name};
chal_files_OL = chal_files_OL(contains(chal_files_OL, ".mat"));


%% Step 2: Load data

try
    clear trials_CL
    clear trials_OL
end

% initialize storage variables
doses = [];
subjects = [];
NVs = [];
TFs_per_chal = {};
data_sets = {};
time_sets = {};

% load closed-loop data
for chal_CL = 1:length(chal_files_CL)  
    
    % load individual challenge
    chal_name_CL = chal_files_CL{chal_CL};    
    fprintf('%s\n', chal_name_CL);
    trials_CL(chal_CL) = load(fullfile(data_path_CL, chal_name_CL));
    
end

% load open-loop data if it exists
try 
    for chal_OL = 1:length(chal_files_OL)  
        
        % load individual challenge
        chal_name_OL = chal_files_OL{chal_OL};    
        fprintf('%s\n', chal_name_OL);
        trials_OL(chal_OL) = load(fullfile(data_path_OL, chal_name_OL));

    end
end


%% Step 2i: determine zero_times for a challenge set
%%% ONLY DO ONCE PER CHALLENGE SET %%%

% Serially plot the challenges, waiting for user to switch to next
% Use the data tips function to determine the zero time as the point of
% input switch (ie LBNP/hemorrhage start or infusion change)

% Closed Loop
for chal_CL = 1:length(trials_CL) 

    plot(trials_CL(chal_CL).t_BP, movmean(trials_CL(chal_CL).BP, 10000))
    plot(trials_CL(chal_CL).t_US, movmean(trials_CL(chal_CL).US, 100))
    plot(trials_CL(chal_CL).t_DR,trials_CL(chal_CL).DR)
    % plot(trials_CL(chal_CL).t_CO2, movmax(trials_CL(chal_CL).CO2, 1000))

    input(chal_files_CL{chal_CL});

end

% Open Loop
for chal_OL = 1:length(trials_OL) 

    plot(trials_OL(chal_OL).t_BP, movmean(trials_OL(chal_OL).BP, 10000))
    plot(trials_OL(chal_OL).t_US, movmean(trials_OL(chal_OL).US, 100))
    plot(trials_OL(chal_OL).t_DR,trials_OL(chal_OL).DR)
    % plot(trials_OL(chal_OL).t_CO2, movmax(trials_OL(chal_OL).CO2, 1000))

    input(chal_files_OL{chal_OL});
end


%% Step 2ii: Save zero times
%%% ONLY DO ONCE PER CHALLENGE SET %%%

% Record the zero times in this vector
zero_times_CL = ["20250327 221919";...
                 "20250327 230337";...
                 "20250617 140950";...
                 "20250617 141959";...
                 "20250617 145054";...
                 "20250617 150145";...
                 "20250624 151243";...
                 "20250624 152514";...
                 "20250624 153649";...
                 "20250624 155043";...
                 "20250624 160423";...
                 "20250624 161645";...
                 "20250624 193435"];

zero_times_OL = ["20250327 213312";...
                 "20250327 214328";...
                 "20250327 215346";...
                 "20250624 164052";...
                 "20250624 165158";...
                 "20250624 173348";...
                 "20250624 174541";...
                 "20250624 175653"];

% convert to datetime
zero_times_CL = datetime(zero_times_CL, InputFormat="yyyyMMdd HHmmss");
zero_times_OL = datetime(zero_times_OL, InputFormat="yyyyMMdd HHmmss");

% save
save(fullfile(data_path, '..','Zero Times', "challengeNameHere zero times.mat"), "zero_times_OL","zero_times_CL")


%% Step 3/4: Representative Plots and Performance Analysis

% Step 3 is to plot representative traces
% Step 4 is to analyze the traces for performance metrics

% A is for challenges with only closed-loop trials
% B is for challenges with open- and closed-loop trials

% If you have not yet created a zero_times file and you do not have a
% reference trace to obtain challenge times, go down to Step 5 first


%% Step 3A: Target Change Traces (Figs. 5b and 7b)

% choose representative traces (zero times come from target curve)
if chal_type == "Rat"
    repr_CL = 10;
elseif chal_type == "Pig Target Change"
    repr_CL = 3;
end

% reload to get the full struct (trials_CL only stores a subset of fields)
CL_data = load(fullfile(data_path_CL, chal_files_CL{repr_CL}));


% plot in my style
try
    close(figure(1))
end

figure(1)
set(figure(1), 'Position', fig_pos)

% for waveform background
alpha_lbnp = 1;
alpha_trace = 0.95;

% standardize axis limits
min_time = min(CL_data.t_BP);
max_time = max(CL_data.t_BP);
zero_time_CL = CL_data.t_target(find(diff(CL_data.Flow_target)>0, 1));

% infusion
ax1 = subplot(3,1,1); plot(CL_data.t_DR-zero_time_CL, CL_data.DR*60, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color, 'MarkerSize',2);
hold on;
xlim([min_time, max_time]-zero_time_CL)
ylabel({'I_{NE}','(\mug/kg/min)'})
ax1.YLim(1)=-0.05;
ylim([ax1.YLim])
% area(CL_data.t_V-zero_time, (2*(CL_data.V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
set(ax1,'FontSize',7);
set(ax1,'LineWidth',1.5)
set(ax1,'xticklabel',{[]})
hold off

% MAP
ax2 = subplot(3,1,2); plot(CL_data.t_BP-zero_time_CL, robust_butter_median(CL_data.t_BP, CL_data.BP, 2,0.05),  'LineWidth',1.25,'Color', MAP_color);
hold on;
xlim([min_time, max_time]-zero_time_CL)
bp_lims = ax2.YLim;%+[-10 10];
% fill([CL_data.t_BP(1:50:end)-zero_time; flipud(CL_data.t_BP(1:50:end)-zero_time)], [movmin(CL_data.BP(1:50:end), 50); flipud(movmax(CL_data.BP(1:50:end), 50))], hex2rgb(MAP_color), 'FaceAlpha',alpha_trace, 'LineStyle','none');
ylabel({'MAP', '(mmHg)'})
ylim(bp_lims)
% area(CL_data.t_V-zero_time, (CL_data.V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
set(ax2,'FontSize',7);
set(ax2,'LineWidth',1.5)
set(ax2,'xticklabel',{[]})
hold off
try
    ax2.Children = ax2.Children([3 1 2]);
end

% MFV
ax3 = subplot(3,1,3); plot(CL_data.t_US-zero_time_CL, 100*robust_butter_median(CL_data.t_US, CL_data.US, 2,0.05)/CL_data.Flow_target(1),  'LineWidth',1.25,'Color', Flow_color);
hold on;
plot(CL_data.t_target-zero_time_CL, 100*CL_data.Flow_target/CL_data.Flow_target(1), 'LineStyle',':', 'LineWidth',1.25,'Color',Flow_color)
xlim([min_time, max_time]-zero_time_CL)
ylim([ax3.YLim]);%+[-10 10])
% fill([CL_data.t_US-zero_time; flipud(CL_data.t_US-zero_time)], 100*[movmin(CL_data.US, 100); flipud(movmax(CL_data.US, 100))]/CL_data.Flow_target(1), hex2rgb(Flow_color), 'FaceAlpha',alpha_trace, 'LineStyle','none');
ylabel({'MFV','(%)'})
set(ax3,'FontSize',7);
set(ax3,'LineWidth',1.5)
ax3.XTickLabel = minutes(ax3.XTick);
xlabel('Time (min)')
% area(CL_data.t_V-zero_time, (CL_data.V>0)*(ax3.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
hold off
try
    ax3.Children = ax3.Children([4 3 1 2]);
end

% save
% exportgraphics(figure(1), ...
%     fullfile(save_fig_path, sprintf('%s.png',min_time)), 'Resolution', 1200);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s.eps',erase(chal_files_CL{repr_CL}, '.mat'))));



%% Step 4Ai: RMS, rise time, settle time for target change  (Figs. 5e and 7d)

% initialize performance vectors
[error_CL, rise_time_CL, settle_time_CL] = deal(nan(length(trials_CL),1));

% parameters for the modified FC parameters
settle_time_permitted = 20; % s
settle_bounds = 0.35;

% determine parameters for each trial
for chal_CL = 1:length(trials_CL)  
    
    % detect start time of the challenge (from target change)
    start_time = trials_CL(chal_CL).t_target(find(trials_CL(chal_CL).Flow_target~=trials_CL(chal_CL).Flow_target(1), 1));
    end_time = trials_CL(chal_CL).t_US(end);
    
    % find indices of this time in each vector
    [~, start_ind_US] = min(abs(trials_CL(chal_CL).t_US - start_time));
    [~, end_ind_US] = min(abs(trials_CL(chal_CL).t_US - end_time));

    [~, start_ind_TARG] = min(abs(trials_CL(chal_CL).t_target - start_time));
    [~, end_ind_TARG] = min(abs(trials_CL(chal_CL).t_target - end_time));
    
    % determine target and baseline values
    FV_BL = trials_CL(chal_CL).Flow_target(1);
    FV_TARG = trials_CL(chal_CL).Flow_target(end_ind_TARG);
    
    % detect that target change is a true step
    if ~sum(trials_CL(chal_CL).Flow_target(start_ind_TARG+100:end_ind_TARG)-FV_TARG)
        
        % generate MFV from waveform
        MFV_CL = robust_butter_median(trials_CL(chal_CL).t_US(start_ind_US:end_ind_US), trials_CL(chal_CL).US(start_ind_US:end_ind_US), 5,0.05);

        % calculate RMS error as percent of baseline
        error_CL(chal_CL) = rms(100*MFV_CL/FV_BL-100);
        
        % calculate thresholds for times
        rise_upper_thresh = 0.9*(FV_TARG-FV_BL)+FV_BL;
        rise_lower_thresh = 0.1*(FV_TARG-FV_BL)+FV_BL;
        settle_upper_thresh = FV_TARG-settle_bounds;%(1+settle_percent)*(FV_TARG-FV_BL)+FV_BL;
        settle_lower_thresh = FV_TARG+settle_bounds;%(1-settle_percent)*(FV_TARG-FV_BL)+FV_BL;
        
        % since MFV fluctuates naturally, remove times it fluctuates after
        % settling
        settle_del_inds = find(trials_CL(chal_CL).t_US-trials_CL(chal_CL).t_US(1)>seconds(settle_time_permitted), 1,'first');
        
        % calculate differently if its a step up or down
        if FV_TARG>FV_BL

            % times for rise time
            upper_cross_ind = find(MFV_CL>rise_upper_thresh, 1)+start_ind_US-1;
            lower_cross_ind = find(MFV_CL>rise_lower_thresh, 1)+start_ind_US-1;
            
            % find when signal settles within limits
            outside_settle = imopen((MFV_CL>FV_TARG+settle_bounds | MFV_CL<FV_TARG-settle_bounds), strel("line", settle_del_inds,90));
            settle_ind = find(outside_settle, 1, 'last')+start_ind_US-1;
        else
            upper_cross_ind = find(MFV_CL<rise_upper_thresh, 1)+start_ind_US-1;
            lower_cross_ind = find(MFV_CL<rise_lower_thresh, 1)+start_ind_US-1;

            % outside_settle = imopen((MFV_CL<settle_upper_thresh | MFV_CL>settle_lower_thresh), strel("line", settle_del_inds,90));
            outside_settle = imopen((MFV_CL<FV_TARG-settle_bounds | MFV_CL>FV_TARG+settle_bounds), strel("line", settle_del_inds,90));

            settle_ind = find(outside_settle, 1, 'last')+start_ind_US-1;
        end
        
        % since settle thresholds were outside rise, this ensures settle
        % time greater than rise time
        settle_ind = max(settle_ind, upper_cross_ind);

        
        % plot times for verification (uncomment the pause to evaluate)
        if ~isempty(upper_cross_ind) & ~isempty(settle_ind)
            rise_time_CL(chal_CL) = seconds(trials_CL(chal_CL).t_US(upper_cross_ind)-trials_CL(chal_CL).t_US(lower_cross_ind));

            plot(trials_CL(chal_CL).t_US(start_ind_US:end_ind_US), MFV_CL)
            hold on
            yline(FV_BL)
            yline(FV_TARG)
            yline(settle_upper_thresh, 'LineWidth',2)
            yline(settle_lower_thresh, 'LineWidth',2, 'LineStyle',":")
            xline(trials_CL(chal_CL).t_US(settle_ind), 'LineWidth', 2)
            xline(trials_CL(chal_CL).t_US(upper_cross_ind))
            xline(trials_CL(chal_CL).t_US(lower_cross_ind))
            % xline(trials_CL(chal_CL).t_US(start_ind_US))
            hold off
            % pause(1)
        end
        
        % store settle time
        if settle_ind-start_ind_US+1<length(MFV_CL)
            settle_time_CL(chal_CL) = seconds(trials_CL(chal_CL).t_US(settle_ind)-trials_CL(chal_CL).t_US(start_ind_US));
        end

    end
end


%% Step 4Aii: Average per subject and save

% determine trials from same subject
exp_dates_CL = cellfun(@(x) x(1:8), chal_files_CL, 'UniformOutput', false);
[exp_dates_CL, ~, exp_inds_CL] = unique(exp_dates_CL);

mean_rise_time_CL = nan(max(exp_inds_CL), 1);
mean_set_time_CL = nan(max(exp_inds_CL), 1);

% average per subject
for idx_CL = 1:max(exp_inds_CL)
    mean_rise_time_CL(idx_CL) = mean(rise_time_CL(exp_inds_CL==idx_CL), 'omitmissing');
    mean_set_time_CL(idx_CL) = mean(settle_time_CL(exp_inds_CL==idx_CL), 'omitmissing');
end

% save
save(fullfile(save_fig_path, sprintf('%s Target Change Vars.mat', datetime("today", "Format","yyMMdd"))), ...
    'settle_time_CL',"rise_time_CL","error_CL", "chal_files_CL", ...
    "exp_dates_CL", "mean_set_time_CL", "mean_rise_time_CL");


%% Break between figure types


%% Step 3B: OL vs CL of MAP decrease  (Figs. 5c,d and 7c)

% choose representative files and load the time at which the challenge
% starts
if chal_type == "Step"
    repr_CL = 10;
    repr_OL = 10;
    max_min = 6;
    clear zero_time_CL

elseif chal_type == "Slope"
    repr_CL = 13;
    repr_OL = 15;
    max_min = 8;
    clear zero_time_CL

elseif chal_type == "Pig Hem"
    repr_CL = length(trials_CL);
    repr_OL = length(trials_OL);
    max_min = 3;
    zero_time_CL = datetime(2024, 9, 19, 20, 55, 46.382);
    zero_time_OL = datetime(2024, 9, 19, 20, 47, 25.645);

elseif chal_type == "Pig ISP Chain"
    repr_CL = 1;
    repr_OL = 1;
    max_min = 11;
    zero_time_CL = datetime(2025, 6, 24, 19, 4, 44);
    zero_time_OL = datetime(2025, 6, 24, 19, 17, 5);

elseif chal_type == "Pig CO2"
    repr_CL = 1;
    repr_OL = 1;
    max_min = 7;
    
    load(fullfile(data_path, '..','Zero Times', "CO2 zero times.mat"))

    zero_time_CL = zero_times_CL(repr_CL);
    zero_time_OL = zero_times_OL(repr_OL);

end

% reload to get the full struct (trials_CL only stores a subset of fields)
OL_data = load(fullfile(data_path_OL, chal_files_OL{repr_OL}));
CL_data = load(fullfile(data_path_CL, chal_files_CL{repr_CL}));


% plot in my style
try
    close(figure(1))
end

figure(1)
set(figure(1), 'Position', fig_pos)

% for waveform background
alpha_lbnp = 1;
alpha_trace = 0.95;

% standardize axis limits
min_time = min(CL_data.t_BP);
max_time = max(CL_data.t_BP);
min_time_OL = min(OL_data.t_BP);
max_time_OL = max(OL_data.t_BP);

% detect zero times from LBNP trace
if ~exist('zero_time_CL', 'var')
    zero_time_CL = CL_data.t_V(find(CL_data.V>0, 1));
    zero_time_OL = OL_data.t_V(find(OL_data.V>0, 1));
end

% recorded the wrong drug concentration
if chal_type == "Pig CO2"
    CL_data.DR = CL_data.DR/10;
    OL_data.DR = OL_data.DR/10;
end

% Open-loop start time to synchronize plots
[~, start_ind_OL] = min(abs((OL_data.t_US-zero_time_OL)));
target_OL = mean(OL_data.US(1:start_ind_OL));

% infusion
ax1 = subplot(3,1,1); plot(CL_data.t_DR-zero_time_CL, CL_data.DR*60, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color, 'MarkerSize',2);
hold on;
plot(OL_data.t_DR-zero_time_OL, OL_data.DR*60, 'LineStyle','--', 'Color', inf_color, 'LineWidth',1.25);
% xlim([min_time, max_time]-zero_time)
xlim([min_time-zero_time_CL, minutes(max_min)])
if chal_type == "Pig Hem"
    xlim([min_time_OL-zero_time_OL, minutes(max_min)])
end
ylabel({'I_{NE}','(\mug/kg/min)'})
% ax1.YLim(1)=2;
ylim([ax1.YLim])
% area(CL_data.t_V-zero_time, (2*(CL_data.V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
% area(OL_data.t_V-zero_time_OL, (2*(OL_data.V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
set(ax1,'FontSize',7);
set(ax1,'LineWidth',1.5)
set(ax1,'xticklabel',{[]})
hold off

% Second subplot is MAP unless its a CO2 challenge
if chal_type == "Pig CO2"
    ax2 = subplot(3,1,2); plot(CL_data.t_CO2-zero_time_CL, movmax(CL_data.CO2, 1000),'Color', MAP_color, 'LineWidth',1.25);
    hold on;
    plot(OL_data.t_CO2-zero_time_OL, movmax(OL_data.CO2, 1000), 'LineStyle','--', 'Color', MAP_color, 'LineWidth',1.25);
    % xlim([min_time, max_time]-zero_time)
    xlim([min_time-zero_time_CL, minutes(max_min)])
    CO2_lims = ax2.YLim;%+[-10 10];
    ylabel({'etCO2', '(mmHg)'})
    ylim(CO2_lims)
    set(ax2,'FontSize',7);
    set(ax2,'LineWidth',1.5)
    set(ax2,'xticklabel',{[]})
    hold off
    try
        ax2.Children = ax2.Children([5 4 1 2 3]);
    end

else
    ax2 = subplot(3,1,2); plot(CL_data.t_BP-zero_time_CL, robust_butter_median(CL_data.t_BP, CL_data.BP, 2,0.05),'Color', MAP_color, 'LineWidth',1.25);
    hold on;
    plot(OL_data.t_BP-zero_time_OL, robust_butter_median(OL_data.t_BP, OL_data.BP, 2,0.05), 'LineStyle','--', 'Color', MAP_color, 'LineWidth',1.25);
    % xlim([min_time, max_time]-zero_time)
    xlim([min_time-zero_time_CL, minutes(max_min)])
    if chal_type == "Pig Hem"
        xlim([min_time_OL-zero_time_OL, minutes(max_min)])
    end
    bp_lims = ax2.YLim;%+[-10 10];
    fill([CL_data.t_BP(1:50:end)-zero_time_CL; flipud(CL_data.t_BP(1:50:end)-zero_time_CL)], [movmin(CL_data.BP(1:50:end), 50); flipud(movmax(CL_data.BP(1:50:end), 50))], hex2rgb(MAP_color), 'FaceAlpha',alpha_trace, 'LineStyle','none');
    fill([OL_data.t_BP(1:50:end)-zero_time_OL; flipud(OL_data.t_BP(1:50:end)-zero_time_OL)], [movmin(OL_data.BP(1:50:end), 50); flipud(movmax(OL_data.BP(1:50:end), 50))], hex2rgb(MAP_color), 'FaceAlpha',alpha_trace*0.99, 'LineStyle','none');
    ylabel({'MAP', '(mmHg)'})
    ylim(bp_lims)
    % area(CL_data.t_V-zero_time_CL, (CL_data.V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
    % area(OL_data.t_V-zero_time_OL, (2*(OL_data.V>0)-1)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
    set(ax2,'FontSize',7);
    set(ax2,'LineWidth',1.5)
    set(ax2,'xticklabel',{[]})
    hold off
    try
        ax2.Children = ax2.Children([5 4 1 2 3]);
    end
end

% MFV
ax3 = subplot(3,1,3); plot(CL_data.t_US-zero_time_CL, 100*robust_butter_median(CL_data.t_US, CL_data.US, 2,0.05)/CL_data.Flow_target(1), 'LineWidth',1.25,'Color',Flow_color);
hold on;
plot(OL_data.t_US-zero_time_OL, 100*robust_butter_median(OL_data.t_US, OL_data.US/target_OL, 2,0.05), 'LineStyle','--', 'LineWidth',1.25,'Color',Flow_color);
plot(CL_data.t_target-zero_time_CL, 100*CL_data.correction*ones(size(CL_data.Flow_target)), 'LineStyle',':', 'LineWidth',1.25,'Color',Flow_color)
% plot(OL_data.t_target-zero_time_OL, OL_data.correction*OL_data.Flow_target/target_OL, 'LineStyle',':', 'LineWidth',1.25,'Color',Flow_color)
% xlim([min_time, max_time]-zero_time)
xlim([min_time-zero_time_CL, minutes(max_min)])
if chal_type == "Pig Hem"
    xlim([min_time_OL-zero_time_OL, minutes(max_min)])
end
ylim([ax3.YLim]);%+[-0.2 0.2])
fill([CL_data.t_US-zero_time_CL; flipud(CL_data.t_US-zero_time_CL)], 100*[movmin(CL_data.US, 100); flipud(movmax(CL_data.US, 100))]/CL_data.Flow_target(1), hex2rgb(Flow_color), 'FaceAlpha',alpha_trace, 'LineStyle','none');
fill([OL_data.t_US-zero_time_OL; flipud(OL_data.t_US-zero_time_OL)], 100*[movmin(OL_data.US, 100); flipud(movmax(OL_data.US, 100))]/target_OL, hex2rgb(Flow_color), 'FaceAlpha',alpha_trace*0.99, 'LineStyle','none');
ylabel({'MFV','(%)'})
set(ax3,'FontSize',7);
set(ax3,'LineWidth',1.5)
ax3.XTickLabel = minutes(ax3.XTick);
xlabel('Time (min)')
% area(CL_data.t_V-zero_time, (CL_data.V>0)*(ax3.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
% area(OL_data.t_V-zero_time_OL, (2*(OL_data.V>0)-1)*(ax3.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
hold off
try
    ax3.Children = ax3.Children([7 6 5 4 1 2 3]);
end

% Save
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s and %s.eps',erase(chal_files_CL{repr_CL}, '.mat'), erase(chal_files_OL{repr_OL}, '.mat'))));


%% Step 4Bi: RMS for Open Loop   (Figs. 5f,g and 7e)

% load zero times for pigs
if chal_type == "Pig Target Change"
    load(fullfile(data_path, '..','Zero Times', "hemorrhage zero times.mat"))
end

if chal_type == "Pig ISP"
    load(fullfile(data_path, '..','Zero Times', "ISP zero times.mat"))
end

if chal_type == "Pig CO2"
    load(fullfile(data_path, '..','Zero Times', "CO2 zero times.mat"))
end

% initialize performance vector
error_OL = nan(length(trials_OL),1);

% determine parameters for each trial
for chal_OL = 1:length(trials_OL)  
    
    % detect start time of the challenge (from available signal)
    if ~isempty(trials_CL(chal_CL).V)
        start_time = trials_OL(chal_OL).t_V(find(trials_OL(chal_OL).V>0, 1));
        end_time = trials_OL(chal_OL).t_V(find(trials_OL(chal_OL).V>0, 1, "last"));
    elseif chal_type == "Pig CO2"
        start_time = zero_times_OL(chal_OL);
        end_time = start_time+minutes(4);
    else
        start_time = zero_times_OL(chal_OL);
        end_time = start_time+minutes(2);
    end
    
    % find indices of the start time in each vector
    [~, start_ind_US] = min(abs(trials_OL(chal_OL).t_US - start_time));
    [~, end_ind_US] = min(abs(trials_OL(chal_OL).t_US - end_time));
    
    % find target value
    target_OL = mean(trials_OL(chal_OL).US(1:start_ind_US));

    % generate MFV from waveform
    MFV_OL = robust_butter_median(trials_OL(chal_OL).t_US(start_ind_US:end_ind_US), trials_OL(chal_OL).US(start_ind_US:end_ind_US), 5,0.05);

    % calculate RMS error as percent of baseline
    error_OL(chal_OL) = rms(100*MFV_OL/target_OL-100);
    
    % plot times for verification (uncomment the pause to evaluate)
    plot(trials_OL(chal_OL).t_US(start_ind_US:end_ind_US), MFV_OL)
    hold on
    xline([start_time; end_time])
    yline(target_OL);
    hold off
    % pause(1)
    
end


%% Step 4Bii: RMS, rise time, settle time for closed loop  (Figs. 5f,g and 7e)

%%% NOTE: RISE AND SETTLE TIMES NOT UPDATED IN THIS SECTION, AS THEY WERE
%%% NOT USED IN THE PAPER
%%% REFER TO STEP 4Ai FOR ANALYSIS OF RISE AND SETTLE TIMES

% load zero times for pigs
if chal_type == "Pig Target Change"
    load(fullfile(data_path, '..','Zero Times', "hemorrhage zero times.mat"))
end

if chal_type == "Pig ISP"
    load(fullfile(data_path, '..','Zero Times', "ISP zero times.mat"))
end

if chal_type == "Pig CO2"
    load(fullfile(data_path, '..','Zero Times', "CO2 zero times.mat"))
end

% parameters for the modified FC parameters
[error_CL, rise_time_CL, settle_time_CL] = deal(nan(length(trials_CL),1));

for chal_CL = 1:length(trials_CL)  
        
    % detect start time of the challenge (from available signal)
    if ~isempty(trials_CL(chal_CL).V)
        start_time = trials_CL(chal_CL).t_V(find(trials_CL(chal_CL).V>0, 1));
        end_time = trials_CL(chal_CL).t_V(find(trials_CL(chal_CL).V>0, 1, "last"));
    elseif chal_type == "Pig CO2"
        start_time = zero_times_CL(chal_CL);
        end_time = start_time+minutes(4);
    else
        start_time = zero_times_CL(chal_CL);
        end_time = start_time+minutes(2);
    end
    
    
    % find indices of the start time in each vector
    [~, start_ind_US] = min(abs(trials_CL(chal_CL).t_US - start_time));
    [~, end_ind_US] = min(abs(trials_CL(chal_CL).t_US - end_time));
    
    [~, start_ind_TARG] = min(abs(trials_CL(chal_CL).t_target - start_time));
    [~, end_ind_TARG] = min(abs(trials_CL(chal_CL).t_target - end_time));
    
    
    % determine baseline values
    FV_BL = trials_CL(chal_CL).Flow_target(start_ind_TARG);

    % detect that no target change occurred
    if ~sum(trials_CL(chal_CL).Flow_target(start_ind_TARG:end_ind_TARG)-FV_BL)
                
        % generate MFV from waveform
        MFV_CL = robust_butter_median(trials_CL(chal_CL).t_US(start_ind_US:end_ind_US), trials_CL(chal_CL).US(start_ind_US:end_ind_US), 5,0.05);

        % calculate RMS error as percent of baseline
        error_CL(chal_CL) = rms(100*MFV_CL/FV_BL-100);
        
       
    end
end



%% Step 4Biii: Average per subject and save

% determine trials from same subject
exp_dates_OL = cellfun(@(x) x(1:8), chal_files_OL, 'UniformOutput', false);
[exp_dates_OL, ~, exp_inds_OL] = unique(exp_dates_OL);


mean_RMS_OL = nan(max(exp_inds_OL), 1);

% average per subject
for idx_OL = 1:max(exp_inds_OL)
    mean_RMS_OL(idx_OL) = mean(error_OL(exp_inds_OL==idx_OL));
end

% determine trials from same subject
exp_dates_CL = cellfun(@(x) x(1:8), chal_files_CL, 'UniformOutput', false);
[exp_dates_CL, ~, exp_inds_CL] = unique(exp_dates_CL);


mean_RMS_CL = nan(max(exp_inds_CL), 1);

% average per subject
for idx_CL = 1:max(exp_inds_CL)
    mean_RMS_CL(idx_CL) = mean(error_CL(exp_inds_CL==idx_CL));
end

% save
save(fullfile(save_fig_path, sprintf('%s %s Comparison Vars.mat', datetime("today", "Format","yyMMdd"), chal_type)), ...
    'settle_time_CL',"rise_time_CL","error_CL", "error_OL", "chal_files_OL", "chal_files_CL", ...
    "mean_RMS_CL", "exp_dates_CL", "mean_RMS_OL", "exp_dates_OL");



%% Step 6: Create video (Supplementary Video 1/2)

vid_folder = save_fig_path;

% load zero times and traces to create video for
if chal_type == "Pig Hem"
    repr_CL = length(trials_CL);
    repr_OL = length(trials_OL);
    max_min = 3;
    zero_time_CL = datetime(2024, 9, 19, 20, 55, 46.382);
    zero_time_OL = datetime(2024, 9, 19, 20, 47, 25.645);

elseif chal_type == "Pig Target Change"
    repr_CL = 3;
end

% Choose open or closed loop
% trial_data = load(fullfile(data_path_OL, chal_files_OL{repr_OL}));
% trial_name = chal_files_OL{repr_OL};

trial_data = load(fullfile(data_path_CL, chal_files_CL{repr_CL}));
trial_name = chal_files_CL{repr_CL};

% Process target trace
trial_data.Flow_target = trial_data.Flow_target*mean(trial_data.US(1:1000))/trial_data.Flow_target(1);

% Obtain MAP and MFV from waveforms
MAP = robust_butter_median(trial_data.t_BP, trial_data.BP, 2,0.05);
MFV = 100*robust_butter_median(trial_data.t_US, trial_data.US, 2,0.05)/trial_data.Flow_target(1);

try
    close(figure(1))
end

% initialize figure axes
figure(1)
set(figure(1), 'Position', fig_pos)
ax1 = subplot(3,1,1);
ax2 = subplot(3,1,2); 
ax3 = subplot(3,1,3); 

set(ax1,'FontSize',7);
set(ax1,'LineWidth',1.5)
set(ax1,'xticklabel',{[]})
ax1.YLim = [min(trial_data.DR), max(trial_data.DR)].*[0.9 1.1]*60;
ylabel(ax1, {'I_{NE}','(\mug/kg/min)'});

set(ax2,'FontSize',7);
set(ax2,'LineWidth',1.5)
set(ax2,'xticklabel',{[]})
ax2.YLim = [min(MAP), max(MAP)].*[0.9 1.1];
% ax2.YLim = [min(MAP),120].*[0.9 1.1];
ylabel(ax2, {'MAP','(mmHg)'});


set(ax3,'FontSize',7);
set(ax3,'LineWidth',1.5)
ax3.YLim = [min(MFV), max(MFV)].*[0.9 1.1];
% ax3.YLim = [min(MFV), 120].*[0.9 1.1];
ylabel(ax3, {'MFV','(%)'});

% initialize lines to edit
line1 = line(ax1, NaT, nan, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color, 'MarkerSize',2);
line2 = line(ax2, NaT, nan,  'LineWidth',1.25,'Color', MAP_color);
line3 = line(ax3, NaT, nan, 'LineWidth',1.25,'Color',Flow_color);
line4 = line(ax3, NaT, nan, 'LineStyle',':', 'LineWidth',1.25,'Color',Flow_color);

min_time = min(trial_data.t_BP);
max_time = max(trial_data.t_BP);

win_length = 60;


% load video writer
v = VideoWriter(fullfile(vid_folder,sprintf('%s.mp4',erase(trial_name, '.mat'))),...
                        "MPEG-4");
v.Quality = 100;
v.FrameRate = 60;

open(v)
play_speed = 10;


% generate frame and write to file
for ct = min_time:seconds(play_speed/v.FrameRate):max_time
    
    % choose data
    [~, ct_ind_DR] = min(abs((trial_data.t_DR-ct)));
    [~, ct_ind_US] = min(abs((trial_data.t_US-ct)));
    [~, ct_ind_BP] = min(abs((trial_data.t_BP-ct)));
    [~, ct_ind_target] = min(abs((trial_data.t_target-ct)));

    % update lines and axis limits
    set(line1, 'XData', trial_data.t_DR(1:ct_ind_DR), 'YData', trial_data.DR(1:ct_ind_DR)*60);
    ax1.XLim = ct+seconds([-win_length 5]);
    
    set(line2, 'XData', trial_data.t_BP(1:ct_ind_BP), 'YData', MAP(1:ct_ind_BP));
    ax2.XLim = ct+seconds([-win_length 5]);
    
    set(line3, 'XData', trial_data.t_US(1:ct_ind_US), 'YData', MFV(1:ct_ind_US));
    set(line4, 'XData', trial_data.t_target(1:ct_ind_target), 'YData', 100*trial_data.correction*trial_data.Flow_target(1:ct_ind_target)/trial_data.Flow_target(1));
    ax3.XLim = ct+seconds([-win_length 5]);
    
    % write frame
    writeVideo(v, print('-RGBImage','-r600'));

end

close(v)
