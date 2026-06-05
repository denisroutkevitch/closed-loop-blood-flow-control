% Function: sound2vel
%
% Purpose: extract velocity envelope from sound file with user input (.wav)
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

function [t_US, US, thresh] = sound2vel(y,Fs, thresh, start_time)
    
    if nargin <2 | isempty(thresh)
        thresh = 18;
    elseif nargin == 2
        start_time = [];
    end
    
        
    % time-frequency    
    [s,f,t] = stft(y, Fs, 'Window',hann(4096, 'periodic'), 'OverlapLength', 3072, 'FrequencyRange','onesided');
    
    % set threshold and extract index of envelope
    [vel_ind, thresh] = user_set_thresh(abs(s), thresh);
    
    % Trim and change time axis
    cutoff = find((vel_ind>1 & vel_ind<200),1,'first');

    if isempty(cutoff)
        cutoff = 1;
    end
    
    t_US = t(cutoff:end);
    US = f(vel_ind(cutoff:end))';   % envelope index to actual frequency

    % User enters time bounds
    if isempty(start_time)
        prompt = 'Enter start time (yyyyMMddHHmmssSSS)';
        dlgtitle = sprintf('Filename: %s', filepath);
        answer = inputdlg(prompt,dlgtitle);
        t_US = datetime(answer{1}, 'InputFormat', 'yyyyMMddHHmmssSSS')+seconds(t_US)-seconds(t_US(1));
    else
        t_US = start_time+seconds(t_US)-seconds(t_US(1));
    end

end
