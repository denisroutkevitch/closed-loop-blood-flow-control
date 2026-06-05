% Function: standard_ID_plot
%
% Purpose: to create a nice standard plot for ID results
%
% Input parameters: 
%       t_set, DR_set, BP_set, Flow_set: double array
%       plot_name: string
%       save_bool: logical (whether to save the plot or not)
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function standard_ID_plot(t_set, DR_set, BP_set, Flow_set, plot_name, save_bool, save_fig_path)

    if nargin==5
        save_bool = 1;
    end
    
    DR_set = DR_set*1000;
    
    load('plot_colors.mat')
    
    fig_pos = [360,463,200,175];
    
    
    figure(1)
    set(figure(1), 'Position', fig_pos)
    
    subplot(3,1,1), plot(t_set(:,1), DR_set, 'LineWidth',1.25, 'Color', inf_color);
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta I_{NE}','(\mug/kg/min)'})
    % title('Individual Traces')
    
    subplot(3,1,2), plot(t_set(:,1), BP_set, 'LineWidth',1.25, 'Color', MAP_color);
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\DeltaMAP','(mmHg)'})
    
    subplot(3,1,3), plot(t_set(:,1), 100*Flow_set, 'LineWidth',1.25, 'Color', Flow_color);
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\DeltaMFV','(%)'})
    xlabel('Time (s)')
    % legend(challenges, 'Location','southwest')
    
    if save_bool
        exportgraphics(figure(1), fullfile(save_fig_path, sprintf('%s Individual Traces.png', plot_name)), 'Resolution',600);
        print(figure(1), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Individual Traces.eps', plot_name)));
    end

    t_set = t_set(1:10:end, :);
    DR_set = DR_set(1:10:end, :);
    BP_set = BP_set(1:10:end, :);
    Flow_set = Flow_set(1:10:end, :);

    mean_DR =  mean(DR_set, 2);
    mean_BP = mean(BP_set, 2);
    mean_Flow = mean(Flow_set, 2);

    std_DR =  std(DR_set, 0, 2);
    std_BP = std(BP_set, 0, 2);
    std_Flow = std(Flow_set, 0, 2);

    figure(2)
    set(figure(2), 'Position', fig_pos + [200 0 0 0])

    subplot(3,1,1), fill([t_set(:,1);flipud(t_set(:,1))],[mean_DR-std_DR;flipud(mean_DR+std_DR)],[.9 .9 .9], ...
            'linestyle','none', 'FaceColor', inf_color, 'FaceAlpha', '0.3');
    hold on
    plot(t_set(:,1), mean_DR, 'LineWidth',1.25, 'Color', inf_color);
    hold off
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta I_{NE}','(\mug/kg/min)'})
    % title('Individual Traces')
    
    subplot(3,1,2), fill([t_set(:,1);flipud(t_set(:,1))],[mean_BP-std_BP;flipud(mean_BP+std_BP)],[.9 .9 .9], ...
            'linestyle','none', 'FaceColor', MAP_color, 'FaceAlpha', '0.3');
    hold on
    plot(t_set(:,1), mean_BP, 'LineWidth',1.25, 'Color', MAP_color);
    hold off
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\DeltaMAP','(mmHg)'})
    
    subplot(3,1,3), fill([t_set(:,1);flipud(t_set(:,1))],100*[mean_Flow-std_Flow;flipud(mean_Flow+std_Flow)],[.9 .9 .9], ...
            'linestyle','none', 'FaceColor', Flow_color, 'FaceAlpha', '0.3');
    hold on
    plot(t_set(:,1), 100*mean_Flow, 'LineWidth',1.25, 'Color', Flow_color);
    hold off
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\DeltaMFV','(%)'})
    xlabel('Time (s)')
    % legend(challenges, 'Location','southwest')
    
    if save_bool
        exportgraphics(figure(2), fullfile(save_fig_path, sprintf('%s Average Traces.png', plot_name)), 'Resolution',600);
        print(figure(2), '-vector', '-depsc', fullfile(save_fig_path, sprintf('%s Average Traces.eps', plot_name)));
    end

end
    