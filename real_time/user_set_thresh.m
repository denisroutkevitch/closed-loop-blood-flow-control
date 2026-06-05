% Function: user_set_thresh
%
% Purpose: simple GUI to choose envelope threshold
% Input parameters: 
%       s_filt: double array (time-freqeuncy analysis of sound)
%       thresh: double (starting threshold)
%
% Output parameters:
%       vel_ind: double array (frequency indices of envelope)
%       new_thresh: double (final threshold)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function [vel_ind, new_thresh] = user_set_thresh(s_filt, thresh)
    
    % Set view parameters
    window = 1:size(s_filt,2);
    ylims = 1:(100*2*pi);
    clims = ([0 max(s_filt(:))]);

    % initialize figure
    fig = uifigure("Position",[100 100 1200 800]);
    g = uigridlayout(fig);
    g.RowHeight = {'1x','fit'};
    g.ColumnWidth = {'1x','10x','1x'};
    
    % initialize axes
    ax = uiaxes(g);
    ax.Layout.Row = 1;    
    ax.Layout.Column = [1 length(g.ColumnWidth)];
    
    % default value
    new_thresh = thresh;
    
    % velocity envelope variable
    vel_ind = ones(1,size(s_filt, 2)); 
    
    % sample envelope calculation for user evaluation
    for cc = window  %size(s_filt, 2)    
        try 
            vel_ind(cc) = find(s_filt(:,cc)>thresh, 1, 'last');
        end
    end
    
    % plot envelope    
    imagesc(s_filt(ylims, window), 'YData', [1 size(s_filt, 1)],'Parent',ax)
    ax.CLim = clims;
    ax.XLim = [window(1), window(end)]-window(1)+1;
    ax.YLim = [ylims(1), ylims(end)];    
    hold(ax,'on');
    plot(vel_ind(window)*size(s_filt,1)/ylims(end), 'LineWidth', 2,'Color','r','Parent',ax)
    hold(ax,'off');
    

    % user interactive components
    sld = uislider(g, ...
        "ValueChangingFcn",@(src,event)updateFrame(src,event,image,ax));
    sld.Layout.Row = 2;
    sld.Layout.Column = 2;
    sld.Limits = clims;
%     sld.MajorTicks = clims(1):0.1:clims(2);

    close_btn = uibutton(g,"Text","Done", ...
        "ButtonPushedFcn", @(src,event) closeButtonPushed(src,event));
    close_btn.Layout.Row = 2;
    close_btn.Layout.Column = 3;


    % wait for user to choose
    waitfor(fig);
    
    % aberrant image is closed
    close(figure(1))

    % evaluate entire velocity with chosen threshold
    for cc = 1:size(s_filt, 2)    
        try 
            vel_ind(cc) = find(s_filt(:,cc)>new_thresh, 1, 'last');
        end
    end

    % replot with new threshold
    function updateFrame(~,event,~,ax)
        
        new_thresh = round(4*event.Value,1)/4;
        vel_ind = ones(1,size(s_filt, 2));       
        
        % calculate
        for cc = window
            try 
                vel_ind(cc) = find(s_filt(:,cc)>new_thresh, 1, 'last');
            end
        end
        
        % plot
        imagesc(s_filt(ylims, window), 'YData', [1 size(s_filt, 1)],'Parent',ax)
        ax.CLim = clims;
        hold(ax,'on');
        plot(vel_ind(window)*size(s_filt,1)/ylims(end), 'LineWidth', 2,'Color','r','Parent',ax)
        hold(ax,'off');
        
    end
    
    % close plot
    function closeButtonPushed(src,event)
        closereq();
    end
end
