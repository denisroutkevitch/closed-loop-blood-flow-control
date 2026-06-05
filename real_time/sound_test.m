% Script: sound_test
%
% Purpose: to determine the appropriate threshold value for envelope
% frequency determination
%
%
% Created by: Denis Routkevitch  (droutke1@jhmi.edu)

% record 4 seconds
audio_sampling_rate = 44100; % Hz
frame_size = audio_sampling_rate*4;

% initialize audio device
deviceReader = audioDeviceReader(audio_sampling_rate, frame_size, "Device","Line (2- Sound Blaster G3)");


%%% uncomment this part to determine initial thresh %%%
[audio, ~] = deviceReader();
[~, ~, thresh] = sound2vel(audio, audio_sampling_rate, 0.4, datetime("now", 'InputFormat', 'yyyyMMddHHmmssSSS'));

% display new thresh value to put into real_time_feedback_control
disp(thresh)

% stops audio device connection
release(deviceReader)