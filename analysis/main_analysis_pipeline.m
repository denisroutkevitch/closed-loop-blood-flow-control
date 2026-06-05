clear; close all;
% Purpose: This script serves as a guide through the post-hoc analysis pipeline
% 
% Run setup_paths.m first to ensure proper path referencing
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


%% Part 1: Curate individual challenges by type

% manually select a challenge
curate_data_manual

% for infusion changes, use this script
infusion_auto_curate

% for LBNP trials, use this script
LBNP_auto_curate


%% Part 2: Transfer function estimation and storage for all challenges

estimate_transfer_functions

% Figures: evaluate the transfer functions for determination of "average" strategy
% this script evaluates the transfer functions related to autoregulation
Figure_2_evaluate_LBNP_TFs

% this script evaluates the transfer functions related to infusion
Figure_3_evaluate_infusion_TFs

%% Part 3: Define the "average transfer functions"

% this script defines the "average" transfer functions to use in the
% simulation
% Part of Figs 2 and 3 also contained here
define_average_TFs

%% Part 4: Use average transfer functions to generate controllers

generate_controllers

% associated figures
Figure_4_simulations

%% Part 5: Curate real time data

curate_data_RTFC

% associated figures
Figure_5_7_real_time
Figure_7f_long_term_FC

