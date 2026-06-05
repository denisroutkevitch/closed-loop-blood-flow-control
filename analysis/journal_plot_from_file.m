% Function: journal_plot_from_file
%
% Purpose: to extract data from file name, synchronize, and perform average
% on multiple traces if user chooses. Main input is BP.
%
% Input parameters:
%   filename: string
%   label: string (optional)
%
% Output parameters:
%   time, Y, U_BP, U_CO2: T x 1 double
%   ts: double
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function journal_plot_from_file(fname, label)
    
    load('plot_colors.mat')

    
    % extract data
    if nargin == 1
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time] = extract_and_sync(fname);
    else
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time] = extract_and_sync(fname, label);
    end
    
    ds_num = 10;
    t_plot = [t_pre(1:ds_num:end) nan t_post(1:ds_num:end)];
    BP_plot = [BPpre(1:ds_num:end) nan BPpost(1:ds_num:end)];
%     US_plot = 0.01*[noah_filter_trial(t_pre(1:ds_num:end), USpre(1:ds_num:end), 5,1) nan noah_filter_trial(t_post(1:ds_num:end), USpost(1:ds_num:end), 5,1)]+1;
    US_plot = 0.01*[USpre(1:ds_num:end) nan USpost(1:ds_num:end)]+1;
%     CO2 = [CO2pre CO2post];
    MAP_plot = medfilt1(movmean(BP_plot, 100), 10);
    MF_plot = medfilt1(movmean(US_plot, 100), 10);
    
    
    
    %%% display figure for deciding  which parts of trace to extract %%%

    figure(1)
    min_time = min(t_pre-inj_time)/60;
    max_time = max(t_post-inj_time)/60;
    if isempty(max_time)
        max_time = max(t_pre-inj_time)/60;
    end
    
    window = [min_time, max_time];
    lineint = 10;
    alpha_trace = 0.1;
    
%         set(figure(2), 'Position',  [50 75 1180 825]);
    set(figure(1), 'Position', [171,361,300,145]) % paper

    subplot(2,1,1), plot((t_plot-inj_time)/60, BP_plot, 'Color', [hex2rgb(MAP_color), alpha_trace]);
    hold on;
    plot((t_plot-inj_time)/60, MAP_plot, 'Color', MAP_color, 'LineWidth', 2);

    % plot((t_post-inj_time)/60, BPpost, 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
%     xline(window(1):lineint:window(2), ':b');
    %     xline((crit_times-inj_time)/60, 'g');
    xline(0, 'r', 'LineWidth', 2);
    xlim([min_time, max_time])
    % ylim([0 1.2*max(BP(BP_inds))]);
    ylabel({'MAP','(mmHg)'})
    ylim([0 200])
    title('Mean Arterial Pressure')
    set(gca,'FontSize', 7)
    set(gca,'LineWidth',1.5)
    hold off
    
    subplot(2,1,2), plot((t_plot-inj_time)/60, US_plot, 'Color', [hex2rgb(Flow_color), alpha_trace]);
    hold on;
    subplot(2,1,2), plot((t_plot-inj_time)/60, MF_plot, 'Color', Flow_color, 'LineWidth', 2);
    % plot((t_post-inj_time)/60, abs(USpost), 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
%     xline(window(1):lineint:window(2), ':b');
    xline(0, 'r', 'LineWidth', 2);
    xlim([min_time, max_time])
    % ylim([0 1.2*max(US(US_inds))]);
    xlabel('Time since injury (min)')
    title('Spinal Cord Blood Flow Velocity')
    ylabel({'MFV', '(cm/s)'});
    set(gca,'FontSize', 7)
    set(gca,'LineWidth',1.5)
    hold off

    %%% End of display figure %%%

    
end


