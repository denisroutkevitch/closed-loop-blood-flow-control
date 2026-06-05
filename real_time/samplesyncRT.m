% Function: samplesyncRT
%
% Purpose: synchronize BP and US vectors for real_time use
%
% Input parameters:
%   t_BP: double vector
%   t_US: double vector
%   BP: double vector
%   US: double vector
%
% Output parameters:
%   t_sync: double vector
%   BP: double vector
%   US: double vector
%   fs: double vector
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu) and Nicholas Kats
% (nkats1@jhu.edu)

function [t_sync, BP, US] = samplesyncRT(t_BP, BP, t_US, US, sample_freq)

    % cut data to same time scale
    min_time = max([min(t_US), min(t_BP)]);
    max_time = min([max(t_US), max(t_BP)]);

    if isempty(min_time)
        [t_sync, BP, US, fs] = deal([]);
        return;
    end
    
    % find bounds for US
    [~, min_US] = min(abs(t_US - min_time));
    [~, max_US] = min(abs(t_US - max_time));

    % find bounds for BP
    [~, min_BP] = min(abs(t_BP - min_time));
    [~, max_BP] = min(abs(t_BP - max_time));

    % find inds that match best
    US_inds = min_US:max_US;
    BP_inds = min_BP:max_BP;
    
    
    % cut down vectors
    t_US= t_US(US_inds');
    t_BP= t_BP(BP_inds');
    US = US(US_inds');
    BP = BP(BP_inds');
    
    
    % resample and interpolate data so both traces have same length
    N = ceil(sample_freq * seconds(max_time-min_time));
    fs = N / seconds(max_time-min_time);
    t_sync = linspace(min_time, max_time, N)';
    
    if ~isempty(BP)
        BP = interp1(t_BP, BP, t_sync, 'linear', 'extrap');
    end

    if ~isempty(US)
        US = interp1(t_US, US, t_sync, 'linear', 'extrap');
    end


end