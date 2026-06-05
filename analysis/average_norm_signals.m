% Function: average_norm_signals
%
% Purpose: to average the signals from a list of challenges and normalize
% velocity
%
% Input parameters: 
%       chal_path: string
%       challenges: cell array of strings
%       cutoff_freq: double
%
% Output parameters:
%       [t_set, DR_set, BP_set, Flow_set, CO2_set]: double
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function [t_set, DR_set, BP_set, Flow_set, CO2_set] = average_norm_signals(chal_path, challenges, cutoff_freq)
    
    t_set = [];
    DR_set = [];
    BP_set = [];
    Flow_set = [];
    CO2_set = [];

    % for vessel normalization
    load(fullfile(chal_path,'..','..',"Flow Baselines.mat"));


    for chal_num = 1:length(challenges)
        
        chal_name = challenges{chal_num};

        fprintf('%s\n', chal_name);
        
        % load the files
        load(fullfile(chal_path, chal_name));
        
        % find the normalization velocity for this challenge
        norm_vel = bl_table(contains({bl_table.Experiment}, chal_name(1:6))).MeanFlow;
        
        % filter the signals
        BP_filt = robust_butter(time, BP, 2,cutoff_freq);
        BP_filt = BP_filt- mean(BP_filt(1:find(time==0)-100));
        Flow_filt = robust_butter(time, Flow, 2,cutoff_freq);
        Flow_filt = Flow_filt- mean(Flow_filt(1:find(time==0)-100));
        Flow_filt = Flow_filt/norm_vel;
        

        % infusions autocurate lacked CO2
        if ~exist('CO2', 'var')
            CO2 = nan(size(BP_filt));
        end
        
        % LBNP autocurate lacked DR
        if ~exist('DR', 'var')
            DR = nan(size(BP_filt));
        end

        % add zeros onto drug rate signal
        DR(isnan(DR)) = 0;
    
        time = round(time, 3);
        
        % trim appropriate challenges
        if chal_num > 1
            % trim new challenge start if too long
            if min(time) < min(t_set)
                sync_ind = find(time == min(t_set(:,1)),1);
                
                
                time = time(sync_ind:end);
                DR = DR(sync_ind:end);
                BP_filt = BP_filt(sync_ind:end);
                Flow_filt = Flow_filt(sync_ind:end);
                CO2 = CO2(sync_ind:end);
            
            % trim start of all other challenges
            elseif min(time) >= min(t_set)
                sync_ind = find(t_set(:,1) == min(time),1);
                
                t_set = t_set(sync_ind:end,:);
                DR_set = DR_set(sync_ind:end,:);
                BP_set = BP_set(sync_ind:end,:);
                Flow_set = Flow_set(sync_ind:end,:);
                CO2_set = CO2_set(sync_ind:end,:);
            end
        
            % trim end of new challenge if too long
            if max(time) > max(t_set)
                sync_ind = find(time == max(t_set(:,1)),1);
                
                time = time(1:sync_ind);
                DR = DR(1:sync_ind);
                BP_filt = BP_filt(1:sync_ind);
                Flow_filt = Flow_filt(1:sync_ind);
                CO2 = CO2(1:sync_ind);
        
            % trim end of all other challenges
            elseif max(time(:,1)) <= max(t_set)
                sync_ind = find(t_set == max(time),1);
                
                t_set = t_set(1:sync_ind,:);
                DR_set = DR_set(1:sync_ind,:);
                BP_set = BP_set(1:sync_ind,:);
                Flow_set = Flow_set(1:sync_ind,:);
                CO2_set = CO2_set(1:sync_ind,:);
            end
        end
        
        % update challenge set
        t_set = [t_set, time];
        DR_set = [DR_set, DR];
        BP_set = [BP_set, BP_filt];
        Flow_set = [Flow_set, Flow_filt];
        CO2_set = [CO2_set, CO2];

        % clear variables so no confusion above
        clear("CO2", "DR")
    end
end