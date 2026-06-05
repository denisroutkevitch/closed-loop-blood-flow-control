clear; close all;
% Purpose: To evaluate transfer function behavior for the 
% LBNP-related transfer functions
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 


%% Step 0: Define color palette and other parameters

load('plot_colors.mat')

fig_pos = [360,463,200,175];

load('repo_path.mat');
save_fig_path = fullfile(repo_path, 'Saved Figures');



%% Step 1: Compile to compare chosen response

% data_path = fullfile(repo_path,'Rat System ID','TF by Challenge Type','LBNP for Evaluation', 'H_PF');
data_path = fullfile(repo_path,'Sample Processed Directory/','TF by Challenge Type','Sample Trial', 'H_PF');


% find all challenges
chal_files = {dir(data_path).name};
chal_files = chal_files(contains(chal_files, ".mat"));


%% Step 2: extract only well-performed challenges (low noise, confounding signal, good TF fit)


% for vessel normalization
% load(fullfile(repo_path,'Rat System ID', "Flow Baselines.mat"));
load(fullfile(repo_path,'Sample Processed Directory', "Flow Baselines.mat"));

% which TF parameters to use?
n_p = 2;
n_z = 1;

% initialize storage variables
vacs = [];
zero_times = [];
subjects = [];
NVs = [];
TFs_per_chal = {};
data_sets = {};
time_sets = {};
vac_traces = {};


for chal = 1:length(chal_files)  
    
    % load individual challenge
    chal_name = chal_files{chal};    
    fprintf('%s\n', chal_name);
    load(fullfile(data_path, chal_name));
    
    % save vac and TF at chosen poles and zeros
    vacs = [vacs; abs(min(Dataset.InputData))];
    
    % import TFs, normalized to vessel 
    norm_vel = bl_table(contains({bl_table.Experiment}, chal_name(1:6))).MeanFlow;
    TFs_per_chal = [TFs_per_chal; {TFs{n_p,n_z}/norm_vel}];
    NVs = [NVs; norm_vel];
    
    % further data
    data_sets = [data_sets; {Dataset}];
    time_sets = [time_sets; {time}];
    subjects = [subjects; chal_name(1:6)];
    
    % import start times from initial data files
    zero_times = [zero_times; load(fullfile(data_path, '..', erase(chal_name, ' H_PF'))).zero_times];
    vac_traces = [vac_traces; {load(fullfile(data_path, '..', erase(chal_name, ' H_PF'))).V}];

    clear vac;
end



%% Figure 2c: Generate demonstrative ID plots

for i_ds = 1:10:length(data_sets)
    
    DS = data_sets{i_ds};
    TF = TFs_per_chal{i_ds};
    time = time_sets{i_ds};

    standard_ID_plot(time, zeros(size(time)), DS.InputData, DS.OutputData, chal_files{i_ds}, 0)

    figure(1), subplot(3,1,3)
    hold on
    plot(time, 100*lsim(TF, DS.InputData,time)*NVs(i_ds), 'LineWidth', 2, 'LineStyle', ':', 'Color',Flow_color)
    hold off

    print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Individual System ID.eps', chal_files{i_ds})));

end



%% For Fig 2g: Evaluate each TF against each dataset

% initialize
errors = nan(length(TFs_per_chal));

% test each TF
for i_tf = 1:length(TFs_per_chal)
    
    % progress bar
    if mod(i_tf,5)==0 || i_tf == length(TFs_per_chal)
        fprintf('TF: %.0f%%\n', 100*i_tf/length(TFs_per_chal));
    end
    
    % test each dataset
    for i_ds = 1:length(data_sets)
        DS = data_sets{i_ds};
        TF = TFs_per_chal{i_tf};
        
        % calculate rmse
        y = lsim(TF, DS.InputData, DS.SamplingInstants);
        errors(i_tf, i_ds) = rms(y - DS.OutputData/NVs(i_ds));
        
    end
end


%% For Fig 2g: Evaluate average TF

% load average TF
TFs = load(fullfile(repo_path, 'Rat System ID','Official TFs (240806)',"H_PF_injured.mat")).TFs;
av_TF = TFs{n_p,n_z};

% initialize variables
vacs(length(TFs_per_chal)+1) = abs(min(Dataset.InputData));
av_errors = nan(1,length(TFs_per_chal));

% calculate error between average and variables
for i_ds = 1:length(data_sets)
    DS = data_sets{i_ds};

    y = lsim(av_TF, DS.InputData, DS.SamplingInstants);
    av_errors(i_ds) = rms(y - DS.OutputData/NVs(i_ds));

end


%% Figure 2g: Export errors per subject

subj_bounds = [subj_ind; length(data_sets)];
within_subject = [];
inter_subject = [];
average_subject = [];

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
end


% save cross-subject error data
save(fullfile(save_fig_path, sprintf("%s H_PF SystemID comp.mat", datetime("today", 'Format','yyyyMMdd'))),...
    "within_subject", "inter_subject", "average_subject");



%% Figure S2b: Plot a bode plot for each rat


% initialize value to compare (magnitude at frequency range
comp_val = zeros(size(vacs));

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
        
        % correction for one of the phases
        if any(phase_interp>180)
            phase_interp = phase_interp-360;
        end
        
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
ylim([-180 180])
set(gca,'LineWidth',1.5);
set(gca, 'ytick', -540:180:540);
ylabel('Phase (\circ)')
xlabel('Frequency (rad/s)')

hold off

%% Fig S2d: Magnitude Invariance

% plot the analysis value to compare TF at each input mag
figure(2)
set(figure(2), 'Position', [400,450,270,250])

for sh = 1:max(shapes)
    scatter(vacs(shapes==sh), comp_val(shapes==sh), 60, cmap(100, :),  'filled', shapemap(sh));
    hold on
end
hold off

% correlation
[R_mag,P_mag] = corrcoef(vacs, comp_val);

xlim([0 20])
set(gca,'LineWidth',1.5);
ylabel('Average Gain (dB)')
xlabel('Maximum Change in MAP (mmHg)')
title(sprintf('PCC: %g; p = %g', R_mag(1,2), P_mag(1,2)));
set(gca,'xticklabel',num2str(get(gca,'xtick')','%g'))


%% Fig S2c: Time Invariance

time_since = nan(size(vac_type));

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


%% Fig S2e: Shape Invariance

% find shapes based on vacuum trace
vac_type = nan(size(comp_val));

for vt = 1:length(vac_traces)
    
    v_trace = vac_traces{vt};

    if length(unique(v_trace)) < 10
        vac_type(vt) = 1;
    elseif length(unique(round(diff(v_trace),1)))<20
        vac_type(vt) = 2;
    else
        vac_type(vt) = 3;
    end
end

% plot the analysis value to compare TFs for each shape
figure(4)
set(figure(4), 'Position', [400,100,190,250])
for sh = 1:max(shapes)
    scatter(vac_type(shapes==sh), comp_val(shapes==sh), 60, cmap(100, :),  'filled', shapemap(sh));
    hold on
end
hold off

xlim([0 4])
set(gca,'LineWidth',1.5);
ylabel('Average Gain (dB)')
xlabel('Challenge Type')
title(sprintf('Gain from %g-%g Hz', w_lims(1)/2/pi, w_lims(2)/2/pi));
set(gca,'xticklabel',num2str(get(gca,'xtick')','%g'))
legend({'Rat 1', 'Rat 2', 'Rat 3'})

% export values for prism
[vac_type_sort, sort_inds] = sort(vac_type);
comp_val_sort = comp_val(sort_inds);
rats_sort = shapes(sort_inds);


%% Figure S2: Save Plots

save_folder = fullfile(save_fig_path, 'LTI Plots');

if ~isfolder(save_folder)
    mkdir(save_folder)
end

this_save = sprintf('%s H_PF -', datetime('now', 'Format', 'yyMMdd'));


exportgraphics(figure(1), fullfile(save_folder, sprintf('%s Bode.png', this_save)), 'Resolution',600);

print(figure(2), '-vector', '-depsc', fullfile(save_folder, sprintf('%s Amplitude Dependence.eps', this_save)));
print(figure(3), '-vector', '-depsc', fullfile(save_folder, sprintf('%s Time Dependence.eps', this_save)));
print(figure(4), '-vector', '-depsc', fullfile(save_folder, sprintf('%s Challenge Dependence.eps', this_save)));

save(fullfile(save_folder, sprintf('%s Challenge Dependence for Prism.mat', this_save)), 'vac_type_sort', 'comp_val_sort', "rats_sort")


return;



