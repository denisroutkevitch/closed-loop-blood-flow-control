% Function: eval_ID_sets
%
% Purpose: to reevaluate the datasets used to create the average functions
%
% Input parameters: 
%       t_set, DR_set, BP_set, Flow_set: double
%       challenges: cell array
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function eval_ID_sets(t_set, DR_set, BP_set, Flow_set, challenges)
    
    DR_set = DR_set*1000;
    
    inf_color = '#456F8A';
    MAP_color = 'k';
    Flow_color = '#cc0000';
    
    fig_pos = [360,463,200,175];
        
    figure(1)
    set(figure(1), 'Position', fig_pos)
    
    for samp = 1:size(BP_set, 2)
        
        
        subplot(3,1,1), plot(t_set(:,1), DR_set(:,samp), 'LineWidth',1.25, 'Color', inf_color);
        set(gca,'LineWidth',1.5);
        set(gca,'FontSize',7);
        ylabel('I(t) (\mug/kg/min)');
        % title('Individual Traces')
        
        subplot(3,1,2), plot(t_set(:,1), BP_set(:,samp), 'LineWidth',1.25, 'Color', MAP_color);
        set(gca,'LineWidth',1.5);
        set(gca,'FontSize',7);
        ylabel('MAP (mmHg)')
        
        subplot(3,1,3), plot(t_set(:,1), Flow_set(:,samp), 'LineWidth',1.25, 'Color', Flow_color);
        set(gca,'LineWidth',1.5);
        set(gca,'FontSize',7);
        ylabel('MFV (cm/s)')
        xlabel('Time (s)')
        % legend(challenges, 'Location','southwest')

        input(challenges{samp});

    end
    

end
    