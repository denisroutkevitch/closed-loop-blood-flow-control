% Function: robust_butter
%
% Purpose: zero-phase Butterworth low-pass filter with mirror-padding
% to suppress edge transients
%
% Input parameters:
%   t: datetime or double vector (time axis)
%   x: double vector (signal to filter)
%   n: int (filter order)
%   fc: double (cutoff frequency, Hz)
%
% Output parameters:
%   y: double vector (filtered signal)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu), Noah Lu,
% and Nicholas Kats (nkats1@jhu.edu)

function y = robust_butter(t, x, n, fc)

    if strcmp(whos('t').class, 'datetime') | strcmp(whos('t').class, 'duration')
        fs = 1/seconds((t(2)-t(1)));
    else
        fs = 1/((t(2)-t(1)));
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
