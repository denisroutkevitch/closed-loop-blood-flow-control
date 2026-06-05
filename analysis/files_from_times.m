% Function: files_from_times
%
% Purpose: Generate mat files from all Trace Timings.
%
% Input parameters: 
%       root_path: string (path to peruse for any ungenerated mat files)
%
% Output parameters:
%       none
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


function files_from_times(root_path)
    
    % find challenge types
    root_trial_sets = {dir(root_path).name};
    root_trial_sets = root_trial_sets(4:end);

    % find all full experiments stored
    trace_path = fullfile(root_path,'..');
    trace_files = {dir(trace_path).name};
    trace_files = trace_files(contains(trace_files, ".mat") & ~contains(trace_files, "Trace Log") & ~contains(trace_files, "Baselines"));
    
    % run through each challenge type
    for rt = 1:length(root_trial_sets)
        
        
        data_path = fullfile(root_path, root_trial_sets{rt});
        
        % find all challenge trials
        chal_files = {dir(data_path).name};
        chal_files = chal_files(contains(chal_files, ".png") & ~contains(chal_files, "CO2"));
        
        % load times
        [times_start, times_end] = import_times(fullfile(data_path, "Trace Timings.txt"));
        
        % extract each mat
        for repr = 1:length(times_start)
            
            % start and end times
            t_start = times_start(repr);
            t_end = times_end(repr);
            
            % for file name
            datstr = char(t_start);
            
            % timing must match existing png
            try
                chal_name = [erase(chal_files{contains(chal_files, datstr)}, 'png'), 'mat'];
            catch
                error("Trace Timings.txt does not match challenges")
            end
            
            % skip any mats that have already been done
            if isfile(fullfile(data_path, chal_name))
                continue;
            end
        
            disp(chal_name)
            
            % load full experiment
            load(fullfile(trace_path, trace_files{contains(trace_files, datstr(3:8))}));
            
            % concatenate pre and post injury
            t_BP = [t_BPpre; t_BPpost];
            BP = [BPpre; BPpost];
            
            t_US = [US.TimePre; US.TimePost];
            US = [US.USPre; US.USPost];
    
            t_CO2 = [t_CO2pre; t_CO2post];
            CO2 = [CO2pre; CO2post];
            
            t_BP(isnan(BP)) = [];
            BP(isnan(BP)) = [];
            
            if ~exist('V', 'var') | max(t_V)<min(t_BP)
                t_V = datetime([],[],[]);
                V = [];
            end
            
            % deal with if there are repeated time values
            [t_BL, ia, ~] = unique(t_BL);
            Flow_BL = Flow_BL(ia);

            % find parts of baseline curve without averaging artifact for each switch
            inds_keep = [(~(diff(Flow_BL)~=0) | diff(t_BL)>seconds(3)) & ~(diff(t_BL)==0);true];
            
            % resample to target signal
            Flow_BL_resamp = interp1(t_BL(inds_keep), Flow_BL(inds_keep), t_target, "previous");
            
            % In real-time code, actual target was set as multiple of baseline
            Flow_target = Flow_BL_resamp.*target;
            
            
            % extract only signals within time limited
            [~, BP_start] = min(abs(t_BP-t_start));
            [~, BP_end] = min(abs(t_BP-t_end));
            
            BP = BP(BP_start:BP_end);
            t_BP = t_BP(BP_start:BP_end);
            
            [~, US_start] = min(abs(t_US-t_start));
            [~, US_end] = min(abs(t_US-t_end));
            
            US = US(US_start:US_end);
            t_US = t_US(US_start:US_end);
            
            [~, DR_start] = min(abs(t_DR-t_start));
            [~, DR_end] = min(abs(t_DR-t_end));
            
            DR = DR(DR_start:DR_end);
            t_DR = t_DR(DR_start:DR_end);
            
            try
                [~, CO2_start] = min(abs(t_CO2-t_start));
                [~, CO2_end] = min(abs(t_CO2-t_end));
                
                CO2 = CO2(CO2_start:CO2_end);
                t_CO2 = t_CO2(CO2_start:CO2_end);
            catch
                [t_CO2, CO2] = deal([]);
            end
            
            % extract these only if they exist
            if ~isempty(V)
                [~, V_start] = min(abs(t_V-t_start));
                [~, V_end] = min(abs(t_V-t_end));
                
                V = V(V_start:V_end);
                t_V = t_V(V_start:V_end);
            end
        
        
            if ~isempty(Flow_target)
                [~, target_start] = min(abs(t_target-t_start));
                [~, target_end] = min(abs(t_target-t_end));
                
                Flow_target = Flow_target(target_start:target_end);
                t_target = t_target(target_start:target_end);
            end
            
            % save
            save(fullfile(data_path, chal_name),...
                "t_target", "Flow_target", "t_V","V","t_DR","DR","t_BP","BP", "t_US", "US","t_CO2","CO2");
        
        end
    
    end
end