% Script: setup_paths
%
% Purpose: Set local data paths for the preprocessing pipeline.
%   Run this script once after cloning the repository, and again any time
%   you move your data folder. It saves raw_path.mat and processed_path.mat
%   in the preprocessing/ directory.
%   Both files are git-ignored and will not appear in commits.
%
% Data directory structure expected:
%   raw_path/          - raw experimental data (one subfolder per experiment)
%   processed_path/    - compiled .mat files written by compile_data_RT.m
%                        (created if absent)
%   <data root>/surgery_data.mat - surgery metadata, one level above raw_path
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


%% Edit the path(s) below, then run this script

repo_path = '/path/to/your/data';

% Root of the raw (unprocessed) experimental data.
raw_path = fullfile(repo_path, ...
                    'Sample Raw Directory');

% Destination for compiled .mat files produced by compile_data_RT.m.
% Keep this separate from raw_path to avoid mixing raw and processed data.
processed_path = fullfile(repo_path, ...
                          'Sample Processed Directory');


%% Save — do not edit below this line

save('raw_path.mat',       'raw_path');
save('processed_path.mat', 'processed_path');

fprintf('Paths saved to preprocessing/.\n');
fprintf('  raw_path       = %s\n', raw_path);
fprintf('  processed_path = %s\n', processed_path);
