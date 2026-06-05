clear; close all;
% Purpose: To evaluate transfer function behavior for the 
% infusion-related transfer functions. Ran compile_infusion_data.m to
% generate the proper combined folder
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 


%% Step 0: Define color palette and other parameters

load('plot_colors.mat')

fig_pos = [360,463,200,175];

load('repo_path.mat')
save_fig_path = fullfile(repo_path, 'Saved Figures');


%% Step 1: Compile to compare chosen response


% Choose challenge type to compile (H_IF is H_total here)
chal_choice = "H_IP";
% chal_choice = "H_IF";

% data_path = fullfile(repo_path,'Rat System ID','TF by Challenge Type','NE for Evaluation', chal_choice);
data_path = fullfile(repo_path,'Sample Processed Directory','TF by Challenge Type','Sample Infusion', chal_choice);


% find all challenges
chal_files = {dir(data_path).name};
chal_files = chal_files(contains(chal_files, ".mat"));


%% Step 2: extract only well-performed challenges (low noise, confounding signal)


% for vessel normalization
% load(fullfile(repo_path,'Rat System ID', "Flow Baselines.mat"));
load(fullfile(repo_path,'Sample Processed Directory', "Flow Baselines.mat"));


% which TF parameters to use?
if chal_choice == "H_IP"
    n_p = 3;
    n_z = 2;
else
    n_p = 3;
    n_z = 1;
end

% initialize storage variables
doses = [];
zero_times = [];
subjects = [];
NVs = [];
TFs_per_chal = {};
data_sets = {};
time_sets = {};

for chal = 1:length(chal_files)  
    
    % load individual challenge
    chal_name = chal_files{chal};    
    fprintf('%s\n', chal_name);
    load(fullfile(data_path, chal_name));
    
    % figure out dose given
    DR = Dataset.InputData;
    dose = sum(DR-DR(1))*Dataset.Ts/60; % mg/kg
    
    % save dose and TF at chosen poles and zeros
    doses = [doses; dose];
    
    % import TFs, normalized to vessel in case of MFV
    norm_vel = bl_table(contains({bl_table.Experiment}, chal_name(1:6))).MeanFlow;
    if chal_choice =="H_IP"
        TFs_per_chal = [TFs_per_chal; TFs(n_p,n_z)]; % need this for H_IP
    else 
        TFs_per_chal = [TFs_per_chal; {TFs{n_p,n_z}/norm_vel}]; % need this for H_IF
    end
    NVs = [NVs; norm_vel];
    

    % further data
    data_sets = [data_sets; {Dataset}];
    time_sets = [time_sets; {time}];
    subjects = [subjects; chal_name(1:6)];

    % import start times from initial data files
    zero_times = [zero_times; load(fullfile(data_path, '..', erase(chal_name, sprintf(' %s', chal_choice)))).zero_times];
    
end

if any(doses<0)
    doses = abs(doses);
end

if chal_choice == "H_IP"
    save("reference H_IP TFs.mat", "TFs_per_chal", "data_sets")
end


%% Figure 3c: Generate demonstrative ID plots


if chal_choice == "H_IF"
    
    TFs_IP = load("reference H_IP TFs.mat").TFs_per_chal;
    data_sets_IP = load("reference H_IP TFs.mat").data_sets;
    
    for i_ds = 1:10:length(data_sets)
        
        DS_IP = data_sets_IP{i_ds};
        TF_IP = TFs_IP{i_ds};

        DS_IF = data_sets{i_ds};
        TF_IF = TFs_per_chal{i_ds};
        time = time_sets{i_ds};
    
        standard_ID_plot(time, DS_IF.InputData, DS_IP.OutputData, DS_IF.OutputData, chal_files{i_ds}, 0)
    
        figure(1), 
        subplot(3,1,1)
        ylim(1000*[min(DS_IF.InputData) max(DS_IF.InputData)]+[-0.1 0.1])
        
        subplot(3,1,2)
        hold on
        plot(time, lsim(TF_IP, DS_IF.InputData,time), 'LineWidth', 2, 'LineStyle', ':', 'Color',MAP_color)
        hold off

        subplot(3,1,3)
        hold on
        plot(time, 100*lsim(TF_IF, DS_IF.InputData,time)*NVs(i_ds), 'LineWidth', 2, 'LineStyle', ':', 'Color',Flow_color)
        hold off

        if i_ds == 1
            legend('Actual', 'Estimated')
        end
    
        print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Individual System ID.eps', chal_files{i_ds})));
    
    end
end

%% For Fig 3g,h: Evaluate each TF against each dataset

t_step = -10:0.1:200;
DR_step = 0.001*double(t_step>0);

% initialize
errors = nan(length(TFs_per_chal));
equils = nan(length(TFs_per_chal),1);

% test each TF
for i_tf = 1:length(TFs_per_chal)

    % progress bar
    if mod(i_tf,5)==0 || i_tf == length(TFs_per_chal)
        fprintf('TF: %.0f%%\n', 100*i_tf/length(TFs_per_chal));
    end
    
    TF = TFs_per_chal{i_tf};
    y_step = lsim(TF, DR_step, t_step);
    equils(i_tf) = y_step(end);


    % test each dataset
    for i_ds = 1:length(data_sets)
        DS = data_sets{i_ds};

        % calculate RMSE
        y = lsim(TF, DS.InputData, DS.SamplingInstants);

        if chal_choice == "H_IP"
            errors(i_tf, i_ds) = rms(y - DS.OutputData); % for H_IP
        else
            errors(i_tf, i_ds) = rms(y - DS.OutputData/NVs(i_ds)); % for H_IF
        end
    end
end

%% For Fig 3g,h: Evaluate average TF

% load average TF
if chal_choice == "H_IP"
    TFs = load(fullfile(repo_path, 'Rat System ID','Official TFs (240806)',"H_IP_NE.mat")).TFs;
else
    TFs = load(fullfile(repo_path, 'Rat System ID','Official TFs (240806)',"H_total_NE.mat")).TFs;
end

% initialize variables
av_TF = TFs{n_p, n_z};
doses(length(TFs_per_chal)+1) = abs(min(Dataset.InputData));
av_errors = nan(1,length(TFs_per_chal));

% calculate error between average and variables
for i_ds = 1:length(data_sets)
    DS = data_sets{i_ds};

    y = lsim(av_TF, DS.InputData, DS.SamplingInstants);

    if chal_choice == "H_IP"
        av_errors(i_ds) = rms(y - DS.OutputData); % for H_IP
    else
        av_errors(i_ds) = rms(y - DS.OutputData/NVs(i_ds)); % for H_IF
    end
end


%% For Fig 3g,h: Export errors per subject

this_save = chal_choice;

[subj_label, subj_ind] = unique(subjects, "rows");
subj_bounds = [subj_ind; length(data_sets)];
within_subject = [];
inter_subject = [];
average_subject = [];
equil_response = [];

for si = 1:length(subj_bounds)-1
    
    for sj = 1:length(subj_bounds)-1

        paired_err = errors(subj_bounds(si):subj_bounds(si+1), subj_bounds(sj):subj_bounds(sj+1));

        % group to within or inter subject error
        if si == sj
            within_subject = [within_subject; mean(paired_err, "all")];
        else
            inter_subject = [inter_subject; mean(paired_err, "all")];
        end
    end

    % calculate error for average subject
    paired_err = mean(av_errors(subj_bounds(si):subj_bounds(si+1)), "all");
    average_subject = [average_subject; mean(paired_err, "all")];

    
    equil_response = [equil_response; mean(equils(subj_bounds(si):subj_bounds(si+1)-1), "all")];
end

close all
scatter(1, (within_subject))
hold on
scatter(2, (inter_subject))
scatter(3, (average_subject))
hold off

% save cross-subject error data
save(fullfile(save_fig_path, sprintf("%s %s SystemID comp.mat", datetime("today", 'Format','yyyyMMdd'), this_save)),...
    "within_subject", "inter_subject", "average_subject", "equil_response");



%% Figure S3/4 b: Plot a bode plot for each rat


% initialize value to compare (magnitude at frequency range
comp_val = zeros(size(doses));

% calculate bodes for all TFs
[mag,phase,wout] = cellfun(@bode,TFs_per_chal, 'UniformOutput',false);

% parameters for plot
cmap = flipud(bone);
alpha_trace = 0.03;

% one shape type for each rat
shapemap = ["o","square","diamond","^","v", "<", ">", "pentagram", "*", "x"];
[subj_names,~,shapes]= unique(subjects, 'rows');

% frequency limits
w_lims = 2*pi*[0.002, 0.5];
w_axis = logspace(log10(w_lims(1)), log10(w_lims(2)))';


% initialize bode variables
[mags_av, mags_std, phase_av, phase_std] = deal(nan(length(w_axis), max(shapes)));

figure(1)
set(figure(1), 'Position', [50,450,350,250])

% generate bode for each rat
for sh = 1:max(shapes)
    
    % all challenges of that rat
    chal_inds = find(shapes==sh);
    
    % all bodes for that rat
    [mags_subj, phase_subj] = deal([]);

    for chal_row = chal_inds'  
        
        % collect data
        mag_interp = interp1(wout{chal_row}, squeeze(mag{chal_row}), w_axis);
        phase_interp = interp1(wout{chal_row}, squeeze(phase{chal_row}), w_axis);
        
        % % correction for one of the phases
        % if any(phase_interp>180)
        %     phase_interp = phase_interp-360;
        % end
        
        % store bode
        mags_subj = [mags_subj, 20*log10(mag_interp)];
        phase_subj = [phase_subj, phase_interp];
       
        % store magnitude in range
        comp_val(chal_row) = mean(20*log10(mag_interp), "all", "omitmissing");
    end
    
    % calculate curve for error bars
    mags_av(:, sh) = mean(mags_subj, 2, "omitmissing");
    mags_std(:, sh) = std(mags_subj, [], 2, "omitmissing");
    phase_av(:, sh) = mean(phase_subj, 2, "omitmissing");
    phase_std(:, sh) = std(phase_subj, [], 2, "omitmissing");
end



% magnitude plot
subplot(2,1,1)
for sh = 1:max(shapes)
    % plot magnitude in decibels
    semilogx(w_axis, mags_av(:,sh), 'Color',  'k', 'LineWidth',1.5);
    hold on
    fill([w_axis; flipud(w_axis)], [mags_av+mags_std; flipud(mags_av-mags_std)], cmap(100, :), 'FaceAlpha',alpha_trace, 'LineStyle','none');
end
hold off

xlim(w_lims)
set(gca,'LineWidth',1.5);
title('Bode Plot')
ylabel('Gain (dB)')


% phase plot
subplot(2,1,2)
for sh = 1:max(shapes)
    semilogx(w_axis, phase_av(:,sh), 'Color',  'k', 'LineWidth',1.5);
    hold on
    fill([w_axis; flipud(w_axis)], [phase_av+phase_std; flipud(phase_av-phase_std)], cmap(100, :), 'FaceAlpha',alpha_trace, 'LineStyle','none'); 
end

xlim(w_lims)
ylim([-180 360])
set(gca,'LineWidth',1.5);
set(gca, 'ytick', -540:180:540);
ylabel('Phase (\circ)')
xlabel('Frequency (rad/s)')

hold off

%% Fig S3/4 d: Magnitude Invariance

% plot the analysis value to compare TF at each input mag
figure(2)
set(figure(2), 'Position', [400,450,270,250])

for sh = 1:max(shapes)
    scatter(1000*doses(shapes==sh), comp_val(shapes==sh), 60, cmap(100, :),  'filled', shapemap(sh));
    hold on
end
hold off

% correlation
[R_mag,P_mag] = corrcoef(doses, comp_val);

% xlim([0 5])
set(gca,'LineWidth',1.5);
ylabel('Average Gain (dB)')
xlabel('Dose (\mug/kg)')
title(sprintf('PCC: %g; p = %g', R_mag(1,2), P_mag(1,2)));
set(gca,'xticklabel',num2str(get(gca,'xtick')','%g'))


%% Fig S3/4 c: Time Invariance

time_since = nan(size(doses));

% plot the analysis value to compare TF at each time
figure(3)
set(figure(3), 'Position', [100,100,270,250])
for sh = 1:max(shapes)
    
    % find start times
    start_times = zero_times(shapes==sh);
    time_since(shapes==sh) = minutes(start_times - start_times(1));

    scatter(minutes(start_times - start_times(1)), comp_val(shapes==sh), 60, cmap(100, :),  'filled', shapemap(sh));
    hold on
end
hold off

% correlation
[R_time,P_time] = corrcoef(time_since, comp_val);

xlim([0 60])
set(gca,'LineWidth',1.5);
ylabel('Average Gain (dB)')
xlabel('Time into Experiment (min)')
title(sprintf('PCC: %g; p = %g', R_time(1,2), P_time(1,2)));
set(gca,'xticklabel',num2str(get(gca,'xtick')','%g'))


% less confusing name for keeping rats straight
rats = shapes;

%% Figure S3/4: Save Plots

save_folder = fullfile(save_fig_path, 'LTI Plots');

if ~isfolder(save_folder)
    mkdir(save_folder)
end

this_save = sprintf('%s %s -', datetime('now', 'Format', 'yyMMdd'), chal_choice);


exportgraphics(figure(1), fullfile(save_folder, sprintf('%s %s Bode.png', this_save, chal_choice)), 'Resolution',600);

print(figure(2), '-vector', '-depsc', fullfile(save_folder, sprintf('%s %s Amplitude Dependence.eps', this_save, chal_choice)));
print(figure(3), '-vector', '-depsc', fullfile(save_folder, sprintf('%s %s Time Dependence.eps', this_save, chal_choice)));

save(fullfile(save_folder, sprintf('%s %s for Prism.mat', this_save, chal_choice)), 'rats', 'comp_val', 'data_path')



return;


