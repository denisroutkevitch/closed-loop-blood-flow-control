clear; close all;
% Purpose: To standardly estimate transfer functions for separate BP
% challenges
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)
% 

%% Step 0: Analysis choices

% overwrite TF analyses or no
OVERWRITE = 0;

load('repo_path.mat');

% % Paper data
% data_path = fullfile(repo_path,'Rat System ID');

data_path = fullfile(repo_path,'Sample Processed Directory');

%% Step 1: Record Baselines

detect_vessel_baseline(data_path)


%% Step 2: Poles-Zeros Search for Transfer Function Analysis


chal_folders = {dir(fullfile(data_path, 'TF by Challenge Type')).name};
chal_folders = chal_folders(3:end); % skip '.' and '..' directory entries

% run through all challenge types for species
for chal_type = 1:length(chal_folders)    % [12,15]%

    challenges = {dir(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type})).name};
    challenges = challenges(contains(challenges, '.mat') & ~contains(challenges, 'H_'));
    
    % in each individual challenge
    for chal_num = 1:length(challenges)
        
        fprintf('%s %s\n', chal_folders{chal_type}, challenges{chal_num});
        
        % load the files
        load(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, challenges{chal_num}));
        
        % set the cutoff frequency for noise removal 
        cutoff_freq = 0.05;  % pig experiments
%         cutoff_freq = 0.25; % rat experiments
        
        % filter the signals
        BP_filt = robust_butter(time, BP, 2,cutoff_freq);
        BP_filt = BP_filt- mean(BP_filt(1:find(time==0)-100));
        Flow_filt = robust_butter(time, Flow, 2,cutoff_freq);
        Flow_filt = Flow_filt- mean(Flow_filt(1:find(time==0)-100));
        
        % create dummy DR if it doesn't exist
        if ~exist("DR", "var")
            DR = 0;
        else
            DR = DR - DR(1);
        end

        % add zeros onto drug rate signal
        DR(isnan(DR)) = 0;
    
        % H_PF with all poles and zeros
        if OVERWRITE || ~isfile(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, ...
            'H_PF', sprintf('%s H_PF.mat', erase(challenges{chal_num}, '.mat'))))
            
            disp('H_PF')

            Dataset_PF = iddata(Flow_filt,BP_filt,ts);        
            
            [TFs, errors] = poles_zeros_search(Dataset_PF, time, ...
                fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, 'H_PF'), ...
                sprintf('%s H_PF', erase(challenges{chal_num}, '.mat')));
        end
        

        % H_IP with all poles and zeros
        if sum(DR~=0) && (OVERWRITE || ~isfile(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, ...
            'H_IP', sprintf('%s H_IP.mat', erase(challenges{chal_num}, '.mat')))))
            
            disp('H_IP')

            Dataset_IP = iddata(BP_filt, DR,ts);        
            
            [TFs, errors] = poles_zeros_search(Dataset_IP, time, ...
                fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, 'H_IP'), ...
                sprintf('%s H_IP', erase(challenges{chal_num}, '.mat')));
        end


        % H_IF with all poles and zeros
        if sum(DR~=0) && (OVERWRITE || ~isfile(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, ...
            'H_IF', sprintf('%s H_IF.mat', erase(challenges{chal_num}, '.mat')))))
            
            disp('H_IF')

            Dataset_IF = iddata(Flow_filt,DR,ts);        
            
            [TFs, errors] = poles_zeros_search(Dataset_IF, time, ...
                fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, 'H_IF'), ...
                sprintf('%s H_IF', erase(challenges{chal_num}, '.mat')));
        end
    end

end

%% Step 3: Export Dataset Plots


chal_folders = {dir(fullfile(data_path, 'TF by Challenge Type')).name};
chal_folders = chal_folders(3:end); % skip '.' and '..' directory entries

% run through all challenge types for species
for chal_type = 1:length(chal_folders)

    challenges = {dir(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type})).name};
    challenges = challenges(contains(challenges, '.mat') & ~contains(challenges, 'H_'));
    
    % in each individual challenge
    for chal_num = 1:length(challenges)
        
        fprintf('%s %s\n', chal_folders{chal_type}, challenges{chal_num});
        
         if OVERWRITE || ~isfile(fullfile(data_path, 'Filtered Traces by Challenge Type', ...
                chal_folders{chal_type}, sprintf("%s.png", erase(challenges{chal_num}, '.mat'))))

            % load the files
            load(fullfile(data_path, 'TF by Challenge Type', chal_folders{chal_type}, challenges{chal_num}));
            
            % set the cutoff frequency for noise removal 
            cutoff_freq = 0.05; % pig experiments
%             cutoff_freq = 0.25; % rat experiments
            
            % filter the signals
            BP_filt = robust_butter(time, BP, 2,cutoff_freq);
            BP_filt = BP_filt- mean(BP_filt(1:find(time==0)-100));
%             Flow = medfilt1(Flow, 70);
            Flow_filt = robust_butter(time, Flow, 2,cutoff_freq);
            Flow_filt = Flow_filt- mean(Flow_filt(1:find(time==0)-100));
            
            % add zeros onto drug rate signal
            DR(isnan(DR)) = 0;
            
            % plot confirmation
            figure(1)
            set(figure(1), 'Position', [360,100,450,480])
            subplot(3,1,1), plot(zero_times(1) + seconds(time), DR, 'LineWidth',1.25);
            set(gca,'LineWidth',2);
            ylabel('Infusion Rate (mg/kg/min)')
            ylim([0 3*CRI_rate+0.0001])
            
            subplot(3,1,2), plot(zero_times(1) + seconds(time), BP_filt);
            set(gca,'LineWidth',2);
            ylabel('BP (mmHg)')
            
            subplot(3,1,3), plot(zero_times(1) + seconds(time), Flow_filt);
            set(gca,'LineWidth',2);
            ylabel('Flow Velocity (cm/s)')
    
            
            if ~isfolder(fullfile(data_path, 'Filtered Traces by Challenge Type', chal_folders{chal_type}))
                mkdir(fullfile(data_path, 'Filtered Traces by Challenge Type', chal_folders{chal_type}));
            end
    
    
%             exportgraphics(figure(1), fullfile(data_path, 'Filtered Traces by Challenge Type', ...
%                 chal_folders{chal_type}, sprintf("%s.png", erase(challenges{chal_num}, '.mat'))), 'Resolution', '600') 
         end
    end

end

