% Function: robust_butter_median
%
% Purpose: median pre-filter followed by zero-phase Butterworth low-pass
% filter with mirror-padding to suppress edge transients and spikes
%
% Input parameters:
%   t: datetime or double vector (time axis)
%   x: double vector (signal to filter)
%   n: int (filter order)
%   fc: double (cutoff frequency, Hz)
%   medbool: logical (1 = apply median pre-filter, default 1)
%
% Output parameters:
%   y: double vector (filtered signal)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu) and Noah Lu

function y = robust_butter_median(t, x, n, fc, medbool)

    if nargin == 4
        medbool = 1;
    end

    if strcmp(whos('t').class, 'datetime') | strcmp(whos('t').class, 'duration')
        fs = 1/seconds((t(2)-t(1)));
    else
        fs = 1/((t(2)-t(1)));
    end

    % optional median filter to remove spikes before Butterworth
    if medbool
        x = medfilt1(x, round(fs*0.1));
    end

    [b, a] = butter(n, fc/(fs/2));

    % Mirror-pad the signal (prepend and append a flipped copy) before
    % filtering to avoid edge transients, then trim back to original length.
    if size(x, 1) == 1
        filter_x = [flip(x), x, flip(x)];
    else
        filter_x = [flip(x); x; flip(x)];
    end

    butter_x = filter(b, a, filter_x);
    y = butter_x(length(x)+1:2*length(x));

end
