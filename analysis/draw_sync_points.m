% Function: draw_sync_points
%
% Purpose: draw zero points in the system identification pipeline
%
% Input parameters:
%   f3: figure
%
% Output parameters:
%   index: double
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function index = draw_sync_points(f3)
    
    user_satisfied = false;
    while ~user_satisfied
        
        f3;
        datacursormode on
        
        c = uicontrol('String','Continue','Callback',@button_pushed);
        uiwait(figure(3))
            
        ax = gca; % Identify current axes
        tip = findobj(ax, 'Type','DataTip');

        index = tip.X;
        
        answer = questdlg(sprintf('Index: %d OK?', index));

        delete(tip)
    
        switch answer
            case 'Yes'
                user_satisfied = true;
            case 'No'
                
            case 'Cancel'
                close(f1);
                throw(MException('roiDraw:userCancel', 'User canceled run'));
        end
    end
    

    % to exit drawing
    function button_pushed(src, event)
        uiresume(f3)
    end
end


