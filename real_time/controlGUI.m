% Function: controlGUI
%
% Purpose: creates GUI to interact with the real-time feedback control loop
%
% Input parameters:
%   controller_name: string
%   buffer_time: double
%   I_0: double
%   subj_weight: double
%   drug_conc: double
%   syringe_size: double
%
% Output parameters:
%   f: GUI figure handle
%   h: struct (GUI component values)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


function [f, h] = controlGUI(controller_name, buffer_time, I_0, subj_weight, drug_conc, syringe_size, or_loc)
    
    % initialize figure for GUI
    f = uifigure('Name', 'Control GUI', 'menubar', 'none',...
              'units', 'pix',...
              'pos', [100,250,560,575], 'HandleVisibility', 'on');
    
    % initialize layout
    g = uigridlayout(f,[12 4]);
    g.RowHeight = {'3x','2x','fit','1x','2x','fit','1x','2x','fit','1x','3x', '3x'};
    g.ColumnWidth = {'3x','3x','1x','2x'};
    
    % initialize structure for storing variables
    h = struct();
    

    %%%% generate title
    % includes important information to double check in real time
    if subj_weight>=1000
        % pig
        title_text = sprintf('Subj. Weight: %0.3g kg    Drug Conc: %0.1g mg/mL    Syr. Size: %d mL', ...
            subj_weight/1000,drug_conc,syringe_size);
    else
        % rat
        title_text = sprintf('Subj. Weight: %0.3g g    Drug Conc: %0.1g mg/mL    Syr. Size: %d mL', ...
            subj_weight,drug_conc,syringe_size);
    end
    

    %%% displays
    % display title
    l1 = uilabel(g, "Text", {title_text,or_loc}, 'HorizontalAlignment','center');
    l1.Layout.Row = 1;
    l1.Layout.Column = [1 4];

    % display controller file used
    l2 = uilabel(g, "Text", erase(controller_name, '.mat'), 'HorizontalAlignment','center', 'WordWrap','on');
    l2.Layout.Row = 12;
    l2.Layout.Column = 2;
    

    %%% buttons
    % toggle MAP vs waveform
    h.bMAP = uibutton(g, 'state', 'Text', 'MAP');
    h.bMAP.Layout.Row = 11;
    h.bMAP.Layout.Column = 1;
    
    % toggle MFV vs waveform
    h.bMFV = uibutton(g, 'state', 'Text', 'MFV');
    h.bMFV.Layout.Row = 12;
    h.bMFV.Layout.Column = 1;
    
    % toggle open-loop vs closed-loop
    h.bControl = uibutton(g, 'state', 'Text', 'Control On', 'ValueChangedFcn',@controlToggle);
    h.bControl.Layout.Row = 11;
    h.bControl.Layout.Column = 2;
        
    % stop button
    h.bStop = uibutton(g, 'state', 'Text', 'STOP');
    h.bStop.Layout.Row = [11 12];
    h.bStop.Layout.Column = 4;
    

    %%% plot limits
    % slider
    h.s1 = uislider(g, "Value", 30/60, 'Limits', [6 buffer_time]/60, 'MajorTicks',1:round(buffer_time/60), 'ValueChangedFcn',@s1ValueChanged);
    h.s1.Layout.Row = 2;
    h.s1.Layout.Column = [1 3];
    
    % manual entry
    h.e1 = uieditfield(g, 'Numeric', "Value", 30/60, 'Limits', [6 buffer_time]/60, 'ValueChangedFcn',@e1ValueChanged);
    h.e1.Layout.Row = 2;
    h.e1.Layout.Column = 4;
    
    % label
    l3 = uilabel(g, "Text", "Plot Limits (min)", 'HorizontalAlignment','center');
    l3.Layout.Row = 3;
    l3.Layout.Column = [1 3];
    

    %%% open-loop infusion rate
    % slider
    h.s2 = uislider(g, "Value", 1000*I_0, 'Limits', 1000*I_0*[0 10], 'MajorTicks',round(I_0*(0:1000:10000),1),  'ValueChangedFcn',@s2ValueChanged);
    h.s2.Layout.Row = 5;
    h.s2.Layout.Column = [1 3];
    
    % manual entry
    h.e2 = uieditfield(g, 'Numeric', "Value", 1000*I_0, 'Limits', 1000*I_0*[0 10], 'ValueChangedFcn',@e2ValueChanged);
    h.e2.Layout.Row = 5;
    h.e2.Layout.Column = 4;
    
    % label
    l4 = uilabel(g, "Text", "Baseline Infusion (ug/kg/min)", 'HorizontalAlignment','center');
    l4.Layout.Row = 6;
    l4.Layout.Column = [1 3];
    

    %%% closed-loop target
    % slider
    h.s3 = uislider(g, "Value", 1, 'Limits', [0 2], 'ValueChangedFcn',@s3ValueChanged, 'Enable','off');
    h.s3.Layout.Row = 8;
    h.s3.Layout.Column = [1 3];
    
    % manual entry
    h.e3 = uieditfield(g, 'Numeric', "Value", 1, 'Limits', [0 2], 'ValueChangedFcn',@e3ValueChanged, 'Enable','off');
    h.e3.Layout.Row = 8;
    h.e3.Layout.Column = 4;
    
    % label
    l5 = uilabel(g, "Text", "Target MFV (fold baseline)", 'HorizontalAlignment','center', 'Enable','off');
    l5.Layout.Row = 9;
    l5.Layout.Column = [1 3];
    
    % set font sizes
    set(allchild(g),'FontSize',16)
    set(l1,'FontSize',17, 'FontWeight', 'bold')
    
    
    %%% functions to update synced values
    % plot limits slider and manual entry
    function s1ValueChanged(src, event)
        h.e1.Value = h.s1.Value;
    end
    
    function e1ValueChanged(src, event)
        h.s1.Value = h.e1.Value;
    end
    

    % open-loop infusion slider and manual entry
    function s2ValueChanged(src, event)
        h.e2.Value = h.s2.Value;
    end
    
    function e2ValueChanged(src, event)
        h.s2.Value = h.e2.Value;
    end
    
    
    % closed-loop target slider and manual entry
    function s3ValueChanged(src, event)
        h.e3.Value = h.s3.Value;
    end
    
    function e3ValueChanged(src, event)
        h.s3.Value = h.e3.Value;
    end
    
    
    % grays out open-loop or closed-loop sliders
    function controlToggle(src, event)
        if h.bControl.Value == 1
            h.s3.Enable = matlab.lang.OnOffSwitchState.on;
            h.e3.Enable = matlab.lang.OnOffSwitchState.on;
            l5.Enable = matlab.lang.OnOffSwitchState.on;
            
            h.s2.Enable = matlab.lang.OnOffSwitchState.off;
            h.e2.Enable = matlab.lang.OnOffSwitchState.off;
            l4.Enable = matlab.lang.OnOffSwitchState.off;

        else
            h.s3.Enable = matlab.lang.OnOffSwitchState.off;
            h.e3.Enable = matlab.lang.OnOffSwitchState.off;
            l5.Enable = matlab.lang.OnOffSwitchState.off;

            h.s2.Enable = matlab.lang.OnOffSwitchState.on;
            h.e2.Enable = matlab.lang.OnOffSwitchState.on;
            l4.Enable = matlab.lang.OnOffSwitchState.on;
        end
    end

end

