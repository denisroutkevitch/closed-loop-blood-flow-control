% Function: simulate_timeseries
%
% Purpose: to standardly simulate timeseries
%
% Input parameters: 
%       mdl: reference to Simulink model
%       ts_inputs: model inputs
%
% Output parameters:
%       out: model output
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function out = simulate_timeseries(mdl, ts_inputs)
    
    BP_series = ts_inputs{1};
    F_dist_series = ts_inputs{2};
    F_target_series = ts_inputs{3};
    r_I_series = ts_inputs{4};
    
    % Initialize input variables
    sys_inputs = Simulink.SimulationData.Dataset;
    [BP_dist, F_dist, F_target, r_I] = deal(Simulink.SimulationData.Signal);
    
    % set inputs
    BP_dist.Values = BP_series;
    F_dist.Values = F_dist_series;
    F_target.Values = F_target_series;
    r_I.Values = r_I_series;
    
    % Add inputs
    sys_inputs = addElement(sys_inputs,BP_dist,"BP Disturbance");
    sys_inputs = addElement(sys_inputs,F_dist,"Flow Disturbance");
    sys_inputs = addElement(sys_inputs,F_target,"Target Flow");
    sys_inputs = addElement(sys_inputs,r_I,"Reference I");
    
    % Load inputs
    simIn = Simulink.SimulationInput(mdl);
    simIn.ExternalInput = sys_inputs;
    
    % Run simulation
    out = sim(simIn);

end
    