% Function: US_GUI
%
% Purpose: GUI for streamlining US data selection
%
% Input parameters:
%   US: structure
%
% Output parameters:
%   TPre: double vector
%   TPost: double vector
%   USPre: double vector
%   USPost: double vector
%   selectedLabel: string

% Created by: Noah Lu (nlu@jhu.edu) and Nicholas Kats (nkats1@jhu.edu)


function [TimePre, TimePost, USPre, USPost, selectedLabel] = US_GUI(US)
    
    % Extract labels from US struct
    Labels = {US.Label};
    
    selectedIndex = [];

    hFig = figure('Position', [300, 300, 330, 300], 'MenuBar', 'none', ...
                  'Name', 'US Label Selection', 'NumberTitle', 'off');
    hListbox = uicontrol('Style', 'listbox', 'String', Labels, ...
                         'Position', [50, 50, 130, 200]);
    hButton = uicontrol('Style', 'pushbutton', 'String', 'Select Region', ...
                        'Position', [200, 100, 100, 40], 'Callback', @buttonCallback);

    % waitfor(hButton)
    % uiwait(hButton);

    % hButton = uicontrol('Style', 'pushbutton', 'String', 'Get Vectors', ...
    %     'Position', [200, 100, 100, 40], 'UserData', 0, ...
    %     'Callback', @(src, event) set(src, 'UserData', 1));
    % 
    % % Wait for the button to be pressed (UserData to change to 1)
    % waitfor(hButton, 'UserData', 1);
    uiwait(hFig);
  
    function buttonCallback(~, ~)
       
        selectedIndex = get(hListbox, 'Value');
        US(selectedIndex)
        
        % Extract selected vectors
        TimePre = US(selectedIndex).TimePre;
        USPre = US(selectedIndex).USPre;
        TimePost = US(selectedIndex).TimePost;
        USPost = US(selectedIndex).USPost;

        
        selectedLabel = Labels{selectedIndex};
        fprintf('Vectors for [%s] saved to workspace!\n', selectedLabel);
        closereq();
       
    end
end