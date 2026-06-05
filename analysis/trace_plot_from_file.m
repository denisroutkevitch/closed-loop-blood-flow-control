% Function: trace_plot_from_file
%
% Purpose: quick plot export to visualize entire experiment
%
% Input parameters:
%   filename: string
%   label: string (optional)
%
% Output parameters:
%   none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function trace_plot_from_file(fname, label)
    
    % extract data
    if nargin == 1
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time] = extract_and_sync(fname);
    else
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time] = extract_and_sync(fname, label);
    end
    
    if isempty(USpost)
        USpost = zeros(size(BPpost));
    end
    
    % concatenate signals
    t = [t_pre t_post];
    BP = movmean([BPpre BPpost],100);
    US = [USpre USpost];
    CO2 = [CO2pre CO2post];
    
    
    %%% display figure for deciding  which parts of trace to extract %%%

        figure(2)
        min_time = min(t_pre-inj_time)/60;
        if isempty(min_time)
            min_time = min(t_post-inj_time)/60;
        end

        max_time = max(t_post-inj_time)/60;
        if isempty(max_time)
            max_time = max(t_pre-inj_time)/60;
        end
        
        window = [min_time, max_time];
        lineint = 10;
        
        set(figure(2), 'Position',  [50 75 1180 825]);
        subplot(2,1,1), plot((t-inj_time)/60, BP, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', 'b');
        hold on;
        % plot((t_post-inj_time)/60, BPpost, 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        xline(window(1):lineint:window(2), ':b');
        %     xline((crit_times-inj_time)/60, 'g');
        xline(0, 'r');
        xlim([min_time, max_time])
        % ylim([0 1.2*max(BP(BP_inds))]);
        ylabel('BP (mmHg)');
        ylim([0 200])
        title('Mean Arterial Pressure')
        set(gca,'FontWeight','bold')
        set(gca,'LineWidth',1.5)
        hold off
        
        subplot(2,1,2), plot((t-inj_time)/60, robust_butter_median(t, 0.01*US+1, 5,0.1), 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        hold on;
        % plot((t_post-inj_time)/60, abs(USpost), 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        xline(window(1):lineint:window(2), ':b');
        xline(0, 'r');
        xlim([min_time, max_time])
        % ylim([0 1.2*max(US(US_inds))]);
        xlabel('Time (min)')
        title('Spinal Cord Blood Flow Velocity')
        ylabel('Flow Velocity (cm/s)');
        set(gca,'FontWeight','bold')
        set(gca,'LineWidth',1.5)
        hold off

    %%% End of display figure %%%

    
end


