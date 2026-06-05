% Function: standard_sim_plot
%
% Purpose: to create a nice standard plot for simulation results
%
% Input parameters: 
%       out: Simulink output structure
%       pub_choice: logical (determines size/layout)
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function standard_sim_plot(out, pub_choice)
    
    load('plot_colors.mat')

    if length(out.yout{1}.Values.Data) == 1
        out.yout{1}.Values.Data = repmat(out.yout{1}.Values.Data, length(out.tout),1);
    end
    
    figure(1)
    if pub_choice
        set(figure(1), 'Position', [360,100,200,175])
    else
        set(figure(1), 'Position', [360,100,600,450])
    end

    subplot(3,1,1), plot(out.tout, out.yout{1}.Values.Data*1000, 'LineWidth',1.25, 'Color', inf_color);
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'Infusion Rate','(\mug/kg/min)'})
    
    BP = out.yout{2}.Values.Data;
    subplot(3,1,2), plot(out.tout, BP, 'LineWidth',1.25, 'Color',MAP_color);
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta MAP', '(mmHg)'})
    try
        ylim([min(BP) - 0.1*(max(BP)-min(BP)) max(BP) + 0.1*(max(BP)-min(BP))])
    end
    
    subplot(3,1,3), plot(out.tout, out.yout{3}.Values.Data, 'LineWidth',1.25, 'Color', Flow_color,'LineStyle',':');
    hold on
    plot(out.tout, out.yout{4}.Values.Data, 'LineWidth',1.25, 'Color', Flow_color);
    hold off
    set(gca,'LineWidth',1.5);
    set(gca,'FontSize',7);
    ylabel({'\Delta MFV','(cm/s)'})
    xlabel('Time (s)')
    legend({'Target', 'Actual'})

end
    