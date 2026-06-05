clear; close all;
% Purpose: To generate the official transfer functions for Simulink
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 


%% Step 0: Define color palette and other parameters

inf_color = '#456F8A';
MAP_color = 'k';
Flow_color = '#cc0000';

fig_pos = [360,463,200,175];

load('repo_path.mat');
save_fig_path = fullfile(repo_path, 'Saved Figures');


%% Step 1: Injured autoregulation transfer functions

% % Find the challenges to use
% data_path = fullfile(repo_path, 'Rat System ID');
% chal_type = "LBNP for Model";
% cutoff_freq = 0.05;

% % Find the challenges to use
% data_path = fullfile(repo_path, 'Pig System ID');
% chal_type = "Hemorrhage for Model";
% cutoff_freq = 0.01;

% % Find the challenges to use
% data_path = fullfile(repo_path, 'Pig Intraoperative NIRS System ID');
% chal_type = "Hemorrhage for Model";
% cutoff_freq = 0.01;

% Find the challenges to use
data_path = fullfile(repo_path, 'Sample Processed Directory');
chal_type = "Sample Trial";
cutoff_freq = 0.05;


challenges = {dir(fullfile(data_path, 'TF by Challenge Type', chal_type)).name};
challenges = challenges(contains(challenges, '.mat') & ~contains(challenges, 'H_'));

% extract, normalize blood flow, and synchronize signals
[t_set, DR_set, BP_set, Flow_set, CO2_set] = average_norm_signals(fullfile(data_path, 'TF by Challenge Type', chal_type), challenges, cutoff_freq);
ts = t_set(2,1)-t_set(1,1);

% average within rat first so no over-representation
[DR_set, BP_set, Flow_set, subj_names] = average_subject_signals(DR_set, BP_set, Flow_set, challenges);

% define average Dataset
Dataset_PF = iddata(mean(Flow_set, 2),mean(BP_set, 2),ts);        

% poles zeros search
[TFs, errors] = poles_zeros_search(Dataset_PF, round(t_set(:,1),3), ...
    fullfile(data_path, 'Official TFs'), 'H_PF_injured');


%% Fig 2d: Average slope challenge

% generate dataset plots
standard_ID_plot(t_set, DR_set, BP_set, Flow_set, 'H_PF_inj',0)

% add dotted line
figure(2)
subplot(3,1,3)
hold on
plot(t_set(:,1), 100*lsim(TFs{2,1}, Dataset_PF.InputData,t_set(:,1)), 'LineWidth', 2, 'LineStyle', ':', 'Color',Flow_color)
hold off

% save figure
exportgraphics(figure(1), fullfile(save_fig_path, 'H_PF_inj Individual Traces.png'), 'Resolution',600);
exportgraphics(figure(2), fullfile(save_fig_path, 'H_PF_inj Average Traces.png'), 'Resolution',600);

print(figure(2), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Average Traces.eps', "H_PF_inj")));


%% Fig 2f: Plot step response

BP_step = 15*double(t_set(:,1)>0);
standard_ID_plot(t_set(:,1), DR_set, BP_step, lsim(TFs{2,1}, BP_step,t_set(:,1)), 'STEP H_PF_inj',0, save_fig_path)

figure(1)
subplot(3,1,2), ylim([-2 17]);
subplot(3,1,3), ylim([-3 30]);

print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Traces.eps', "STEP H_PF_inj")));


%% Step response standard deviation across subjects

equil_ind = zeros(size(BP_set, 2),1);

BP_step = 15*double(t_set(:,1)>0);
for i_ind = 1:size(BP_set, 2)
    

    % define average Dataset
    Dataset_ind = iddata(Flow_set(:,i_ind),BP_set(:,i_ind),ts);        
    
    % poles zeros search
    [TFs_ind, ~] = poles_zeros_search(Dataset_ind, round(t_set(:,1),3), ...
        save_fig_path, 'H_PF_injured');

    step_ind = lsim(TFs_ind{2,1}, BP_step,t_set(:,1));
    equil_ind(i_ind) = step_ind(end);
end

step_mean = lsim(TFs{2,1}, BP_step,t_set(:,1));
equil_mean = step_mean(end);

fprintf('%.1f +- %.1f\n', equil_mean*100, std(equil_ind)*100);


%% Step 2: Norepinephrine transfer functions

% % Find the challenges to use
% data_path = fullfile(repo_path, 'Rat System ID');
% chal_type = "NE for Model";
% cutoff_freq = 0.05;

% % Find the challenges to use
% data_path = fullfile(repo_path, 'Pig System ID');
% chal_type = "NE for Model";
% cutoff_freq = 0.01;
% 
% % Find the challenges to use
% data_path = fullfile(repo_path, 'Pig Intraoperative NIRS System ID');
% chal_type = "NE for Model";
% cutoff_freq = 0.01;

% Find the challenges to use
data_path = fullfile(repo_path, 'Sample Processed Directory');
chal_type = "Sample Infusion";
cutoff_freq = 0.01;


challenges = {dir(fullfile(data_path, 'TF by Challenge Type', chal_type)).name};
challenges = challenges(contains(challenges, '.mat') & ~contains(challenges, 'H_'));

% extract, normalize blood flow, and synchronize signals
[t_set, DR_set, BP_set, Flow_set, CO2_set] = average_norm_signals(fullfile(data_path, 'TF by Challenge Type', chal_type), challenges, cutoff_freq);
ts = t_set(2,1)-t_set(1,1);

DR_norm = abs(DR_set-DR_set(1,:));
norm_set  = max(DR_norm, [], 1);

% normalize to DR step size in mg/kg/min (not ug)
BP_norm = abs(BP_set)./norm_set/1000;
Flow_norm = abs(Flow_set)./norm_set/1000;
DR_norm = abs(DR_norm)./norm_set/1000;

% average within rat first so no over-representation
[DR_norm, BP_norm, Flow_norm, subj_names] = average_subject_signals(DR_norm, BP_norm, Flow_norm, challenges);

standard_ID_plot(t_set, DR_norm, BP_norm, Flow_norm, 'H_NE_norm', 0, save_fig_path)
standard_ID_plot(t_set, DR_set, BP_set, Flow_set, 'H_NE', 0, save_fig_path)

% % OPTIONAL can evaluate trials one by one
% eval_ID_sets(t_set, DR_set, BP_set, Flow_set, challenges);
% eval_ID_sets(t_set, DR_norm, BP_norm, Flow_norm, subj_names);

%%

% define average Datasets
Dataset_IP = iddata(mean(abs(BP_norm), 2),mean(abs(DR_norm), 2),ts); 
Dataset_total = iddata(mean(abs(Flow_norm), 2),mean(abs(DR_norm), 2),ts);
Dataset_PF = iddata(mean(abs(Flow_norm), 2),mean(abs(BP_norm), 2),ts);

% poles zeros search
[TFs_IP, errors] = poles_zeros_search(Dataset_IP, t_set(:,1), ...
    fullfile(data_path, 'Official TFs'), 'H_IP_NE');

[TFs_IF, errors] = poles_zeros_search(Dataset_total, t_set(:,1), ...
    fullfile(data_path, 'Official TFs'), 'H_total_NE');

[TFs, errors] = poles_zeros_search(Dataset_PF, t_set(:,1), ...
    fullfile(data_path, 'Official TFs'), 'H_PF_NE');

%% Fig 3d: Average pulse challenge

% plot individual signals to evaluate
% (iterate this step if any signals are wildly different)
standard_ID_plot(t_set, DR_set, BP_set, Flow_set, 'H_NE',0)
exportgraphics(figure(1), fullfile(save_fig_path, 'H_NE Individual Traces.png'), 'Resolution',600);
exportgraphics(figure(2), fullfile(save_fig_path, 'H_NE Average Traces.png'), 'Resolution',600);


% plot normalized signals to evaluate
% (iterate this step if any signals are wildly different)
standard_ID_plot(t_set, DR_norm, BP_norm, Flow_norm, 'H_NE_norm',0)

figure(2)
subplot(3,1,2)
hold on
plot(t_set(:,1), lsim(TFs_IP{4,2}, Dataset_IP.InputData,t_set(:,1)), 'LineWidth', 2, 'LineStyle', ':', 'Color',MAP_color)
hold off

figure(2)
subplot(3,1,3)
hold on
plot(t_set(:,1), 100*lsim(TFs_IF{4,2}, Dataset_total.InputData,t_set(:,1)), 'LineWidth', 2, 'LineStyle', ':', 'Color',Flow_color)
hold off

exportgraphics(figure(1), fullfile(save_fig_path, 'H_NE_norm Individual Traces.png'), 'Resolution',600);
exportgraphics(figure(2), fullfile(save_fig_path, 'H_NE_norm Average Traces.png'), 'Resolution',600);

print(figure(2), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Average Traces.eps', "H_NE_norm")));


%% Fig 3f: Plot step response

t_plot = t_set(:,1)*5;

imp_width = 1.5;
DR_impulse = 0.01*double(abs(t_set(:,1)-imp_width/2)<imp_width);

DR_step = 0.001*double(t_set(:,1)>0);

% DR_plot = DR_impulse;
DR_plot = DR_step;

standard_ID_plot(t_plot, DR_plot, lsim(TFs_IP{4,2}, DR_plot,t_plot), lsim(TFs_IF{4,2}, DR_plot, t_plot), 'STEP H_PF_inj',0)

figure(1)
set(figure(1), 'Position', [360,463,180,175])
subplot(3,1,1), ylim([-0.1 1.1]);
% subplot(3,1,2), ylim([-0.5 10]);
% subplot(3,1,3), ylim([-1 10]);

print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Traces.eps', "STEP H infusions")));

%% Compute steady-state gains for H_IP and H_total

tfs_path = fullfile(repo_path, 'Rat System ID', 'Official TFs (240806)');


% Infusion to BP system
load(fullfile(tfs_path, 'H_IP_NE.mat'))
H_IP_d = TFs{4,2};

% Infusion to flow overall system
load(fullfile(tfs_path, 'H_total_NE.mat'))
H_total_d = TFs{4,2};


t = (0:0.001:2000)';
DR = 0.001*double(t>0);
BP = lsim(H_IP_d, DR,t);
Flow = lsim(H_total_d, DR, t);

fprintf('BP: %.2f; Flow; %.2f\n', BP(end), Flow(end)*100);