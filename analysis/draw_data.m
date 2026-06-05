% Function: draw_data
%
% Purpose: draw ROI to extract specific data from entire experiment
%
% Input parameters:
%   f2: figure
%
% Output parameters:
%   index_list: double (set of indices)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function index_list = draw_data(f2)
    index_list = [];
    f2;

    user_satisfied = false;
    while ~user_satisfied
        
        brush(f2,'on')  
        
        c = uicontrol('String','Continue','Callback',@button_pushed);
        uiwait(figure(2))
            
        ax = gca; % Identify current axes
        
        for i=1:length(ax.Children) % loops through all the plot in figure
            try
                indices = find(ax.Children(i).BrushData); % gives the indices which are brushed
                if ~isempty(indices)
                    break% save the data into required variable
                end
            end
        end
        
        index_list(end+1,:) = [indices(1), indices(end)];

        answer = questdlg('Are you done selecting traces?');
    
        switch answer
            case 'Yes'
                user_satisfied = true;
            case 'No'
                
            case 'Cancel'
                close(f2);
                throw(MException('roiDraw:userCancel', 'User canceled run'));
        end
    end
    
    
    % to exit drawing
    function button_pushed(src, event)
        uiresume(f2)
    end
end


