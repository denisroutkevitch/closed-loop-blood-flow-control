% Function: average_subject_signals
%
% Purpose: to average the signals per subject
%
% Input parameters: 
%       [DR_temp, BP_temp, Flow_temp]: double
%       challenges: cell array
%
% Output parameters:
%       [DR_set, BP_set, Flow_set]: double
%       subj_names: cell array
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function [DR_set, BP_set, Flow_set, subj_names] = average_subject_signals(DR_temp, BP_temp, Flow_temp, challenges)
    
    % find unique subjects
    subjects = string(cellfun(@(c)c(1:6),challenges','UniformOutput',false));
    [subj_names,~,ic]= unique(subjects, 'rows');
    [DR_set, BP_set, Flow_set] = deal([]);
    
    % find the average signal for a subject
    for subj = 1:size(subj_names, 1)
        inds = find(ic == subj);
        DR_set(:,subj) = mean(DR_temp(:,inds), 2);
        BP_set(:,subj) = mean(BP_temp(:,inds), 2);
        Flow_set(:,subj) = mean(Flow_temp(:,inds), 2);
    end
    
    % set the baseline value to 0
    BP_set = BP_set- mean(BP_set(1:1000,:));
    Flow_set = Flow_set- mean(Flow_set(1:1000,:));

end