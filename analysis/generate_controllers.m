clear; close all;
% Purpose: To load the "average" TFs into the Simulink system and run the
% standard simulations
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
%  


%% Step 1A: Load transfer functions (norepinephrine)

load('repo_path.mat');

% Choose save path
save_fig_path = fullfile(repo_path, 'Saved Figures');

% tfs_path = fullfile(repo_path, 'Rat System ID', 'Official TFs (240806)');
% tfs_path = fullfile(repo_path, 'Pig System ID', 'Official TFs (240812)');
% tfs_path = fullfile(repo_path, 'Pig Intraoperative NIRS System ID', 'Official TFs (250529)');
tfs_path = fullfile(repo_path, 'Sample Processed Directory', 'Official TFs');

% 240811 Rat System ID
pz_vals = [4,1;     % unused
           2,1;     % H_PF_injured
           3,2;     % H_IP_NE
           3,2];    % H_total_d

% % 240918 Pig System ID
% pz_vals = [4,1;     % unused
%            2,1;     % H_PF_injured
%            3,2;     % H_IP_NE
%            3,1];    % H_total_d

% % 250529 Pig Intraoperative NIRS System ID
% pz_vals = [4,1;     % unused
%            2,1;     % H_PF_injured
%            2,1;     % H_IP_NE
%            2,1];    % H_total_d


% Autoregulation system
load(fullfile(tfs_path, 'H_PF_injured.mat'))
H_PF_inj = TFs{pz_vals(2,1), pz_vals(2,2)};

% Infusion to BP system
load(fullfile(tfs_path, 'H_IP_NE.mat'))
H_IP_d = TFs{pz_vals(3,1), pz_vals(3,2)};

% Infusion to flow overall system
load(fullfile(tfs_path, 'H_total_NE.mat'))
H_total_d = TFs{pz_vals(4,1), pz_vals(4,2)};

% Infusion to flow independent of pressure
H_IF_d = (H_total_d-(H_PF_inj*H_IP_d));


%% Step 1B: Define simulation settings


% Define time axis
% t_axis = (0:0.1:200)';
t_axis = (0:0.001:2000)';

gslen = 90;

% Initialize input variables
sys_inputs = Simulink.SimulationData.Dataset;
[BP_dist, F_dist, F_target, r_I] = deal(Simulink.SimulationData.Signal);

%%% BLOOD PRESSURE DISTURBANCE %%%
BP_dist.Values = timeseries(zeros(size(t_axis)),t_axis);                      % No disturbance
% BP_dist.Values = timeseries(-15*double(t_axis>20),t_axis);                    % Step decrease
% BP_dist.Values = timeseries(-15*sin(0.05*t_axis),t_axis);                     % Sine wave
% BP_dist.Values = timeseries(-15*double(sin(0.05*t_axis)>0),t_axis);           % Repeated drops and recovery
% BP_dist.Values = timeseries(-15*double(sin(0.05*t_axis)>0),t_axis);           % Repeated drops and recovery
% BP_dist.Values = timeseries(-15*max(min((t_axis-20),gslen),0)/gslen,t_axis);  % Gradual "step"

%%% BLOOD FLOW DISTURBANCE %%%
F_dist.Values = timeseries(zeros(size(t_axis)),t_axis);                         % No disturbance
% F_dist.Values = timeseries(-0.012*double(t_axis>40),t_axis);                  % Step decrease
% F_dist.Values = timeseries(-0.01*double(abs(t_axis-20)<3),t_axis);            % "Impulse" decrease


%%% BLOOD FLOW TARGET %%%
% F_target.Values = timeseries(zeros(size(t_axis)),t_axis);                       % Constant target at baseline
F_target.Values = timeseries(0.0012*double(t_axis>40),t_axis);                 % Step increase
% F_target.Values = timeseries(0.01*double(abs(t_axis-20)<3),t_axis);           % "Impulse" increase


%%% MANUAL INFUSION RATE CHANGE %%%
r_I.Values = timeseries(zeros(size(t_axis)),t_axis);                          % No manual input
% r_I.Values = timeseries(0.0012*double(t_axis>40),t_axis);                      % Begin constant infusion (step)
% r_I.Values = timeseries(0.01*double(abs(t_axis-20)<3),t_axis);                % Bolus dose (impulse)

% Add inputs
sys_inputs = addElement(sys_inputs,BP_dist,"BP Disturbance");
sys_inputs = addElement(sys_inputs,F_dist,"Flow Disturbance");
sys_inputs = addElement(sys_inputs,F_target,"Target Flow");
sys_inputs = addElement(sys_inputs,r_I,"Reference I");



%% Step 2A: Weighting functions for optimal control

% Choose model
mdl_open = 'H_inf_synth_model';

% Update end time
set_param(mdl_open, 'StopTime', num2str(t_axis(end)));


%%% SET WEIGHTS %%%
% makeweight(low-freq gain, crossover freq, high-freq gain, Ts, order)

% 240811 Rat System ID
W_I = makeweight(0.01,0.1,1.122,0);
W_e =  1.2*makeweight(1.122,0.0003,0.01,0);
W_p = 0.00008*makeweight(1.122,0.0003,0.01,0);


% % 240918 Pig System ID
% W_I = 15*makeweight(0.01,0.1,1.122,0);
% W_e =  1.2*makeweight(1.122,0.0003,0.01,0);
% W_p = 0.00008*makeweight(1.122,0.0003,0.01,0);


% % 250529 Pig Intraoperative NIRS System ID
% W_I = 2.5*makeweight(0.01,0.01,1.122,0);
% W_e =  0.9*makeweight(1.122,0.001,0.01,0);
% W_p = 0.000008*makeweight(1.122,0.001,0.01,0);


% Load inputs
simIn = Simulink.SimulationInput(mdl_open);
simIn.ExternalInput = sys_inputs;
% simIn.ExternalInput{2}.PortIndex = 2;

% Simulate
out = sim(simIn);

%%% ERRORS ARE CURRENTLY PLOTTED ON MODEL SCOPE %%%


%% Step 2B: Linearize system and find optimal control

% Linearize 
linsys1 = linearize(mdl_open, getlinio(mdl_open), operpoint(mdl_open));
 
% Run H_inf synthesis
opts = hinfsynOptions;
opts.Display = 'on';
K_h = hinfsyn(prescale(linsys1),1,1,opts);


% Display if failure
if isempty(K_h)
    error('Optimal controller not found')
end



%% Step 2C: (UNUSED IN PAPER) Define PID controllers

% The parameters for this controller can be determined
% using automatic tuner in PID_tuning_model_UNUSED.slx

PID_tuned = nan;

% 240806 RATS
% PID_tuned = pid(-0.0121403860969399, -0.000378728371566696, 0);

% 240812 PIGS
% PID_tuned = pid(-0.000571429039548576, -6.4935874741923e-06, 0.0150267772530542, 1/0.0251494937579228);                


%% Step 3: Run controller simulations

% Choose model
mdl_closed = 'simulate_controller';

% Update end time
set_param(mdl_closed, 'StopTime', num2str(t_axis(end)));


% choose controller type
% K_choice = PID_tuned;       % PID UNUSED
K_choice = K_h;           % Optimal
% K_choice = tf(0,1);       % Open-Loop


% set controller limits  (and choose whether to apply them)
limit_K = 1;
K_lims = [-0.003 0.03]; % mg/kg/min

% apply limits if chosen
if limit_K
    set_param(sprintf('%s/Control Saturation', mdl_closed),'Commented','off')
    upper_lim_I = K_lims(2); % mg/kg/min
    lower_lim_I = K_lims(1); % mg/kg/min
else
    set_param(sprintf('%s/Control Saturation', mdl_closed),'Commented','through')
end


% Load inputs
simIn = Simulink.SimulationInput(mdl_closed);
simIn.ExternalInput = sys_inputs;

% Run simulation
out = sim(simIn);

% Plot results
standard_sim_plot(out, 0);      % for personal display
% standard_sim_plot(out, 1);      % for publication

% Manual stop: the script ends here so the design can be reviewed before
% saving. To save this controller, run Step 4 below by hand.
disp('Controller design complete. Run Step 4 below manually to save it.')
return

%% Step 4: Save controllers and associated necessary info

% choose save name for this controller
prompt = 'Enter save name';
dlgtitle = '';
answer = inputdlg(prompt,dlgtitle);
this_save =  answer{1};

% Choose save path
save_path = fullfile(repo_path, 'Feedback Control', 'Official Controllers');

if ~exist(save_path, 'dir')
    mkdir(save_path)
end
 
% Save necessary variables
save(fullfile(save_path, sprintf('%s - Official Controllers.mat', this_save)), ...
    'K_h', 'PID_tuned', "W_p", "W_e", "W_I", ...
    "H_IF_d", "H_IP_d", "H_PF_inj", "H_total_d", ...
    "tfs_path", "pz_vals")

return



%% Optional: Save plots

% choose save name for this challenge
prompt = 'Enter save name';
dlgtitle = '';
answer = inputdlg(prompt,dlgtitle);
this_save =  answer{1};

% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s.png', this_save)), 'Resolution',600);
% exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s.pdf', this_save)), 'ContentType','vector');
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s.eps', this_save)));