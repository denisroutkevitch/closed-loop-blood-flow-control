% Script: setup_paths
%
% Purpose: Set local data paths for the analysis pipeline.
%   Run this script once after cloning the repository, and again any time
%   you move your data folder. It saves repo_path.mat in the analysis/ directory.
%
% Data directory structure expected under repo_path:
%   Sample Save Directory/     - sample dataset for running the pipeline
%   Feedback Control/          - real-time challenge trial data
%   Saved Figures/             - figures are written here (created if absent)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


%% Edit the path(s) below, then run this script

% Root of the sample/analysis data directory.
% Default points to the "Data for Repo" folder distributed with this code.
repo_path = '/path/to/your/data';


%% Save — do not edit below this line

save('repo_path.mat', 'repo_path');

fprintf('Paths saved to analysis/.\n');
fprintf('  repo_path                      = %s\n', repo_path);
