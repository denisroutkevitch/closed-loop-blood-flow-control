% Purpose: Generate closed-loop simulation plots for figure 4
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

clear, close all;

%% Step 0: Define color palette and other parameters

load('plot_colors.mat')

fig_pos = [360,463,160,150];

load('repo_path.mat');

% Choose save path
save_fig_path = fullfile(repo_path, 'Saved Figures');
K_path = fullfile(repo_path, 'Feedback Control', 'Official Controllers', '240811 Rat System ID - Official Controllers.mat');
K_path = fullfile(repo_path, 'Feedback Control', 'Official Controllers', '240918 Pig System ID - Official Controllers.mat');
K_path = fullfile(repo_path, 'Feedback Control', 'Official Controllers', '250529 Pig Intraoperative NIRS System ID - Official Controllers.mat');

if ~isfolder(save_fig_path)
    mkdir(save_fig_path);
end


%% Step 1: Load simulation parameters and model

load(K_path)

% Choose model
mdl_closed = 'simulate_controller';


%%% choose controller type %%%
% % PID
% K_choice = PID_tuned;       
% plot_name = 'PID';

% Optimal
K_choice = K_h;
plot_name = 'Optimal';


%%% set controller limits  (and choose whether to apply them) %%%
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


%% Step 2A: MAP Step Drop

% Set plot name
this_save = "MAP Step Drop";

% Define time axis
t_axis = (-20:0.1:300)';

% Update end timex
set_param(mdl_closed, 'StartTime', num2str(t_axis(1)), 'StopTime', num2str(t_axis(end)));

% define inputs
ts_inputs = {timeseries(-15*double(t_axis>0),t_axis),...                      % Step decrease
             timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(zeros(size(t_axis)),t_axis),...                        % Constant target at baseline
             timeseries(zeros(size(t_axis)),t_axis)};                          % No manual input

% Simulate with chosen inputs
out_closed = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','on')         % Closed loop
out_open = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','off')        % Open loop

% Plot results
open_v_closed_plot(out_closed, out_open, 1);      % for publication

% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s - %s.png', this_save, plot_name)), 'Resolution',600);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s - %s.eps', this_save, plot_name)));


%% Step 2B: MAP Step Gradual

% Set plot name
gslen = 30;
this_save = sprintf("MAP Step Gradual - %g s", gslen);

% Define time axis
t_axis = (-120:0.1:360)';

% Update end time
set_param(mdl_closed, 'StartTime', num2str(t_axis(1)), 'StopTime', num2str(t_axis(end)));

% define inputs
ts_inputs = {timeseries(-15*max(min((t_axis),gslen),0)/gslen,t_axis),...    % Gradual "step"
             timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(zeros(size(t_axis)),t_axis),...                        % Constant target at baseline
             timeseries(zeros(size(t_axis)),t_axis)};                          % No manual input

% Simulate with chosen inputs
out_closed = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','on')         % Closed loop
out_open = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','off')        % Open loop


% Plot results
open_v_closed_plot(out_closed, out_open, 1);      % for publication


% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s - %s.png', this_save, plot_name)), 'Resolution',600);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s - %s.eps', this_save, plot_name)));



%% Step 2C: Flow Step Disturbance

% Set plot name
this_save = "Flow Step Disturbance";

% Define time axis
t_axis = (-20:0.01:300)';

% Update end time
set_param(mdl_closed, 'StartTime', num2str(t_axis(1)), 'StopTime', num2str(t_axis(end)));

% define inputs
ts_inputs = {timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(-0.15*double(t_axis>40),t_axis),...                   % Step decrease
             timeseries(zeros(size(t_axis)),t_axis),...                        % Constant target at baseline
             timeseries(zeros(size(t_axis)),t_axis)};                          % No manual input

% Simulate with chosen inputs
out_closed = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','on')         % Closed loop
out_open = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','off')        % Open loop


% Plot results
open_v_closed_plot(out_closed, out_open, 1);      % for publication


% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s - %s.png', this_save, plot_name)), 'Resolution',600);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s - %s.eps', this_save, plot_name)));


%% Step 2D: Flow "Impulse" Disturbance

% Set plot name
this_save = "Flow Impulse Disturbance";

% Define time axis
t_axis = (-20:0.01:300)';

% Update end time
set_param(mdl_closed, 'StartTime', num2str(t_axis(1)), 'StopTime', num2str(t_axis(end)));

% define inputs
ts_inputs = {timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(-0.01*double(abs(t_axis-20)<3),t_axis),...             % "Impulse" decrease
             timeseries(zeros(size(t_axis)),t_axis),...                        % Constant target at baseline
             timeseries(zeros(size(t_axis)),t_axis)};                          % No manual input

% Simulate with chosen inputs
out_closed = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','on')         % Closed loop
out_open = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','off')        % Open loop


% Plot results
open_v_closed_plot(out_closed, out_open, 1);      % for publication


% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s - %s.png', this_save, plot_name)), 'Resolution',600);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s - %s.eps', this_save, plot_name)));


%% Step 2E: Target Step Increase

% Set plot name
this_save = "Target Step Increase";

% Define time axis
t_axis = (-120:0.01:360)';

% Update end time
set_param(mdl_closed, 'StartTime', num2str(t_axis(1)), 'StopTime', num2str(t_axis(end)));

% define inputs
ts_inputs = {timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(zeros(size(t_axis)),t_axis),...                        % No disturbance
             timeseries(0.15*double(t_axis>0),t_axis),...                    % Step increase in target
             timeseries(zeros(size(t_axis)),t_axis)};                          % No manual input

% Simulate with chosen inputs
out_closed = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','on')         % Closed loop
out_open = simulate_timeseries(mdl_closed,ts_inputs);
set_param(sprintf('%s/Controller', mdl_closed),'Commented','off')        % Open loop


% Plot results
open_v_closed_plot(out_closed, out_open, 1);      % for publication


% Export figures
exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s - %s.png', this_save, plot_name)), 'Resolution',600);
print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s - %s.eps', this_save, plot_name)));


%% Supplementary: Pole-zero plot

try
    close(figure(1))
end

H_plot = {H_PF_inj, H_IP_d, H_IF_d, K_h};
H_name = ["H_{PF}", "H_{IP}", "H_{IF}", "K"];

figure(1)
set(figure(1), 'Position', [758,360,656,280])

for hh = 1:length(H_plot)
    subplot(1,2,1)
    h1 = pzplot(H_plot{hh});
    p1 = getoptions(h1);
    p1.Title.String = sprintf('a. Pole Zero Map for %s', H_name(hh));
    setoptions(h1, p1);



    subplot(1,2,2)
    scatter(NaN, NaN, 'Marker','x', 'MarkerEdgeColor','b')
    hold on
    scatter(NaN, NaN, 'Marker','o', 'MarkerEdgeColor','b')


    h2 = pzplot(H_plot{hh});
    hold off
    xlim([-1 0])
    legend({"Poles", "Zeros"}, 'Location', 'northwest')

    p2 = getoptions(h2);
    p2.Title.String = sprintf('b. Pole Zero Map for %s', H_name(hh));
    setoptions(h2, p2);




    print(figure(1), '-dpng', fullfile(save_fig_path, '..','Supplementary Figures', 'PZ Maps', sprintf('%s Pole-Zero.png', H_name(hh))), '-r600');
end



%% Supplementary: Weighting functions Bode plot

try
    close(figure(1))
end

W_plot = {W_e, W_p, W_I};
W_name = ["W_e", "W_p", "W_I"];
sub_fig_lab = ["a", "b", "c"];

figure(1)
set(figure(1), 'Position', [106,292,1000,290])

for ww = 1:length(W_plot)
    
    
    subplot(1,3,ww)
    bode(W_plot{ww});
    t = title(sprintf('%s         Bode plot for %s', sub_fig_lab(ww), W_name(ww)));
    
    t.HorizontalAlignment = 'right';
    
end

% f1 = gcf;
% f1.Children().TitleHorizontalAlignment = "left";

print(figure(1), '-dpng', fullfile(save_fig_path, '..','Supplementary Figures', 'Weighting Fx', 'Weighting Fx Bode.png'), '-r600');


%% Supplementary: Controller Bode plot

try
    close(figure(1))
end


figure(1)
set(figure(1), 'Position', [106,292,350,280])


bode(K_h);
t = title('Bode plot for K');


% f1 = gcf;
% f1.Children().TitleHorizontalAlignment = "left";

print(figure(1), '-dpng', fullfile(save_fig_path, '..','Supplementary Figures', sprintf('Bode plot for K_h - %s.png', K_path(end-32:end-27))), '-r600');

