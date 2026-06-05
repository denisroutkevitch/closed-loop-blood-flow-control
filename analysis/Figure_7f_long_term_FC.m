% Purpose: Generate system ID plots for figure 7f
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

clear, close all;

%% Step 0: Define color palette and other parameters

load('plot_colors.mat')
load('repo_path.mat');

fig_pos = [698,211, 420, 130];
alpha_lbnp = 0.1;

% Choose save path
save_fig_path = fullfile(repo_path, 'Saved Figures');
data_path = fullfile(repo_path, 'Feedback Control', 'Challenge Trials');


%% Step 1A: Long-term files

chal_type = "Long-Term";

%%% LBNP Closed Loop %%%
data_path_CL = fullfile(data_path, "Long-Term (Fig 7f)");
file_numbers_CL = []; 

% find all challenges
chal_files_CL = {dir(data_path_CL).name};
chal_files_CL = chal_files_CL(contains(chal_files_CL, ".mat"));


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


%% Step 3: Plot trace

max_min = 6;

% graph limits (had plotted multiple drafts)
dr_lims = [[-0.02 0.3]];
bp_lims = [[60 130]];
us_lims = [[90 112]];

for repr_CL = 1:length(chal_files_CL)
    
    % load the data
    CL_data = load(fullfile(data_path_CL, chal_files_CL{repr_CL}));
    
    % MAP from waveform
    bp_plot = medfilt1(robust_butter_median(CL_data.t_BP, CL_data.BP, 2,0.05),20000);
    bp_fade = nan(size(bp_plot));    
    
    % plot in my style
    figure(1)
    set(figure(1), 'Position', fig_pos)
    
    % standardize axis limits
    min_time = min(CL_data.t_BP);
    max_time = max(CL_data.t_BP);
    zero_time = min_time;
    
    % infusion
    ax1 = subplot(3,1,1); plot(CL_data.t_DR-zero_time, CL_data.DR*60, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', inf_color, 'MarkerSize',2);
    hold on;
    xlim([min_time, max_time]-zero_time)
    ylabel({'I_{NE}','(\mug/kg/min)'})
    % ax1.YLim(1)=-0.05;
    ylim(dr_lims(repr_CL, :))
    % area(CL_data.t_V-zero_time, (2*(CL_data.V>0)-1)*(ax1.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp, BaseValue=-10);
    set(ax1,'FontSize',7);
    set(ax1,'LineWidth',1.5)
    set(ax1,'xticklabel',{[]})
    hold off
    
    % MAP
    ax2 = subplot(3,1,2); plot(CL_data.t_BP-zero_time, bp_plot,  'LineWidth',1.25,'Color', MAP_color);
    hold on;
    xlim([min_time, max_time]-zero_time)
    plot(CL_data.t_BP-zero_time, bp_fade,  'LineWidth',1.25,'Color', [0.8 0.8 0.8]);

    % fill([CL_data.t_BP(1:50:end)-zero_time; flipud(CL_data.t_BP(1:50:end)-zero_time)], [movmin(CL_data.BP(1:50:end), 50); flipud(movmax(CL_data.BP(1:50:end), 50))], hex2rgb(MAP_color), 'FaceAlpha',alpha_trace, 'LineStyle','none');
    ylabel({'MAP', '(mmHg)'})
    ylim(bp_lims(repr_CL, :))
    % area(CL_data.t_V-zero_time, (CL_data.V>0)*(ax2.YLim(2)), EdgeColor="none", FaceColor="k", FaceAlpha=alpha_lbnp);
    set(ax2,'FontSize',7);
    set(ax2,'LineWidth',1.5)
    set(ax2,'xticklabel',{[]})
    hold off
    try
        ax2.Children = ax2.Children([3 1 2]);
    end
    
    % MFV
    ax3 = subplot(3,1,3); plot(CL_data.t_US-zero_time, 100*robust_butter_median(CL_data.t_US, CL_data.US, 2,0.05)/CL_data.Flow_target(1),  'LineWidth',1.25,'Color', Flow_color);
    hold on;
    plot(CL_data.t_target-zero_time, 100*CL_data.Flow_target/CL_data.Flow_target(1), 'LineStyle',':', 'LineWidth',2,'Color','k')
    xlim([min_time, max_time]-zero_time)
    ylim([75 125])
    ylim(us_lims(repr_CL, :))
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
    
    % Save
    exportgraphics(figure(1), ...
        fullfile(save_fig_path, sprintf('%s.png',erase(chal_files_CL{repr_CL}, '.mat'))), 'Resolution', 1200);
    print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s.eps',erase(chal_files_CL{repr_CL}, '.mat'))));

end


%% Step 4: Infusion limits and performance metrics (Supplementary table)

% initialize recording files
fid = fopen(fullfile(save_fig_path, 'long_term_FC_metrics.csv'), 'w');
fprintf(fid, "Animal, MDAPE, MDPE, Wobble, Divergence\n");

for repr_CL = 1:length(chal_files_CL)
    
    % rename variables to match equations for metrics
    CL_data = load(fullfile(data_path_CL, chal_files_CL{repr_CL}));
    C_m = interp1(CL_data.t_target, CL_data.Flow_target, CL_data.t_US);
    C_p = robust_butter_median(CL_data.t_US, CL_data.US, 2,0.05);
    t = minutes(CL_data.t_US-CL_data.t_US(1));

    % performance error
    PE = 100*(C_m-C_p)./C_p;

    % MDAPE
    MDAPE = median(abs(PE), 'omitmissing');

    % MDPE (bias)
    MDPE = median(PE, 'omitmissing');

    % RMSE
    RMSE = rms(PE, 'omitmissing');

    % wobble
    WOBBLE = median(abs(PE-MDPE), 'omitmissing');

    % divergence
    DIVERGENCE = 60*(sum(abs(PE).*t, 'omitmissing')-(sum(abs(PE), 'omitmissing')*sum(t)/length(t)))/...
                (sum(t.^2)-((sum(t))^2)/length(t));

    % print results
    fprintf("%s range: %.2g - %.2g ug/kg/min\n", chal_files_CL{repr_CL}, min(CL_data.DR)*60, max(CL_data.DR)*60)
    fprintf("MDAPE: %.2g%%; MDPE: %.2g%%; Wobble: %.2g%%; Divergence: %.2g %%/hr\n", MDAPE, MDPE, WOBBLE, DIVERGENCE)
    fprintf('\n')
    
    % save results
    fprintf(fid, "%s, %.2g%%, %.2g%%, %.2g%%, %.2g %%/hr\n", chal_files_CL{repr_CL}, MDAPE, MDPE, WOBBLE, DIVERGENCE);
end

fclose(fid);