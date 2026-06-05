% Function: open_v_closed_plot
%
% Purpose: to create a nice standard plot for simulation results with OL v
% CL
%
% Input parameters: 
%       out__: Simulink output structures
%       pub_choice: logical (type of figure)
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function open_v_closed_plot(out_closed, out_open, pub_choice)
    
    load('plot_colors.mat')
    
    if length(out_closed.yout{1}.Values.Data) == 1
        out_closed.yout{1}.Values.Data = repmat(out_closed.yout{1}.Values.Data, length(out_closed.tout),1);
    end
    
    figure(1)
    if pub_choice
        set(figure(1), 'Position', [360,100,185,175])
    else
        set(figure(1), 'Position', [360,100,600,450])
    end
    
    DR = [out_closed.yout{1}.Values.Data*1000; out_open.yout{1}.Values.Data*1000];
    subplot(3,1,1), plot(out_closed.tout/60, out_closed.yout{1}.Values.Data*1000, 'LineWidth',1.25, 'Color', inf_color);
    hold on
    plot(out_open.tout/60, out_open.yout{1}.Values.Data*1000, 'LineWidth',1.25, 'Color', inf_color,'LineStyle','--');
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta I_{NE}','(\mug/kg/min)'})
    try
        ylim([min(DR) - 0.1*(max(DR)-min(DR)) max(DR) + 0.1*(max(DR)-min(DR))])
    end
    hold off
    
    BP = [out_closed.yout{2}.Values.Data; out_open.yout{2}.Values.Data];
    subplot(3,1,2), plot(out_closed.tout/60, out_closed.yout{2}.Values.Data, 'LineWidth',1.25, 'Color',MAP_color);
    hold on
    plot(out_open.tout/60, out_open.yout{2}.Values.Data, 'LineWidth',1.25, 'Color',MAP_color,'LineStyle','--');
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta MAP', '(mmHg)'})
    try
        ylim([min(BP) - 0.1*(max(BP)-min(BP)) max(BP) + 0.1*(max(BP)-min(BP))])
    end
    hold off
    
    F = 100*[out_closed.yout{4}.Values.Data; out_open.yout{4}.Values.Data];
    subplot(3,1,3), plot(out_closed.tout/60, 100*out_closed.yout{3}.Values.Data, 'LineWidth',1.25, 'Color', Flow_color ,'LineStyle',':');
    hold on
    plot(out_closed.tout/60, 100*out_closed.yout{4}.Values.Data, 'LineWidth',1.25, 'Color', Flow_color);
    plot(out_open.tout/60, 100*out_open.yout{4}.Values.Data, 'LineWidth',1.25, 'Color', Flow_color,'LineStyle','--');
    hold off
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta MFV','(%)'})
    xlabel('Time (min)')
    % legend({'Target', 'Closed-Loop', 'Open-Loop'})
    try
        ylim([min(F) - 0.1*(max(F)-min(F)) max(F) + 0.1*(max(F)-min(F))])
    end

end
    