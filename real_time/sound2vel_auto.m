% Function: sound2vel_auto
%
% Purpose: extract velocity envelope from sound without user input (.wav)
%
% Input parameters:
%   file_path: string
%   thresh: double (starting threshold to create envelope (default 18)
%
% Output parameters:
%   t,US, US: double vectors
%   thresh: double (final threshold)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


function [t_US, US] = sound2vel_auto(y, Fs, thresh, start_time)
    if nargin <2 | isempty(thresh)
        thresh = 18;
    elseif nargin == 2
        start_time = [];
    end

    % time-frequency    
    [s,f,t] = stft(y, Fs, 'Window',hann(4096, 'periodic'), 'OverlapLength', 3072, 'FrequencyRange','onesided');
    
    % set threshold and extract index of envelope
    vel_ind = auto_envelope(abs(s), thresh);
    
    % Trim and change time axis
    US = f(vel_ind);
    t_US = start_time+seconds(t)-seconds(t(1));
end
