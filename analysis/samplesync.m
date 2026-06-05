% Function: samplesync
%
% Purpose: synchronize BP and US vectors
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

function [t_sync, BP, US, CO2, fs] = samplesync(t_BP, BP, t_US, US, t_CO2, CO2, sample_freq)

    if nargin == 4
        [t_CO2, CO2] = deal([]);
        sample_freq = 100;
    elseif nargin == 5
        sample_freq = t_CO2;
        [t_CO2, CO2] = deal([]);
    elseif nargin == 6
        sample_freq = 100;
    end
    

    
    
%     sample_freq = 1/(t_BP(2)-t_BP(1));
%     sample_freq = 1/(t_US(2)-t_US(1));

    % cut data to same time scale
    min_time = max([min(t_US), min(t_BP), min(t_CO2)]);
    max_time = min([max(t_US), max(t_BP), max(t_CO2)]);

    if isempty(min_time)
        [t_sync, BP, US, CO2, fs] = deal([]);
        return;
    end
    
    % find bounds for US
    [~, min_US] = min(abs(t_US - min_time));
    [~, max_US] = min(abs(t_US - max_time));

    % find bounds for BP
    [~, min_BP] = min(abs(t_BP - min_time));
    [~, max_BP] = min(abs(t_BP - max_time));

    % find bounds for CO2
    [~, min_CO2] = min(abs(t_CO2 - min_time));
    [~, max_CO2] = min(abs(t_CO2 - max_time));
    
    % find inds that match best
    US_inds = min_US:max_US;
    BP_inds = min_BP:max_BP;
    CO2_inds = min_CO2:max_CO2;
    
    % cut down vectors
    t_US= t_US(US_inds);
    t_BP= t_BP(BP_inds);
    t_CO2= t_CO2(CO2_inds);
    US = US(US_inds);
    BP = BP(BP_inds);
    CO2= CO2(CO2_inds);
    
    % resample and interpolate data so both traces have same length
    N = ceil(sample_freq * (max_time-min_time));
    fs = N / (max_time-min_time);
    t_sync = linspace(min_time, max_time, N);
    
    
    % Resolve duplicate timestamps in BP (artifact of the PicoScope buffer
    % rollover). If the gap after the duplicate is large enough to indicate
    % a real sample, nudge the timestamp forward by 1 ms; otherwise delete
    % the duplicate entirely so interp1 does not error on non-unique inputs.
    inds_test = find(diff(t_BP)==0);
    inds_shift = inds_test((t_BP(inds_test+2)-t_BP(inds_test+1))>0.0012);
    inds_del   = inds_test((t_BP(inds_test+2)-t_BP(inds_test+1))<=0.0012);

    t_BP(inds_shift) = t_BP(inds_shift)+0.001;
    t_BP(inds_del) = [];
    BP(inds_del) = [];


    if ~isempty(BP)
        BP = interp1(t_BP, BP, t_sync, 'linear', 'extrap');
    end

    if ~isempty(US)
        US = interp1(t_US, US, t_sync, 'linear', 'extrap');
    end

    if ~isempty(CO2)
        CO2 = interp1(t_CO2, CO2, t_sync, 'linear', 0);
    end

end