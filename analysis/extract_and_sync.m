% Function: extract_and_sync
%
% Purpose: Extract data from file containing BP, CO2, US traces
%
% Input parameters:
%   fname: string
%   label: string (optional)
%
% Output parameters:
%   t_pre: double vector
%   BPpre: double vector
%   CO2pre: double vector
%   USpre: double vector
%   t_post: double vector
%   BPpost: double vector
%   CO2post: double vector
%   USpost: double vector
%   fspre: double vector
%   fspost: double vector
%   inj_time: double vector
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu) and Nicholas Kats
% (nkats1@jhu.edu)

function [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time, inj_time_dt, label] = extract_and_sync(fname, label)
    
    load(fname)
    
    % Option to specify label or use GUI
    if nargin == 1
        % Run GUI
        [TimePre, TimePost, USPre, USPost, label] = US_GUI(US);

    else
        % predetermined blood flow label
        selectedIndex = find(strcmp({US.Label},label));
        
        if isempty(selectedIndex)
            error('Blood flow label %s does not exist for...\n%s', label, fname)
        end

        % Extract selected vectors
        TimePre = US(selectedIndex).TimePre;
        USPre = US(selectedIndex).USPre;
        TimePost = US(selectedIndex).TimePost;
        USPost = US(selectedIndex).USPost;
    end

    
    % Extract US, BP, CO2 data from structure
    [t_USpre, ia, ~] = unique(TimePre, 'stable');
    USpre = USPre(ia);
    
    [t_USpost, ia, ~] = unique(TimePost, 'stable');
    USpost = USPost(ia);
    
    % convert time vector into double
    % default so the inj_time_dt output is always assigned, even when
    % inj_time is not a datetime
    inj_time_dt = NaT;
    if isa(inj_time,'datetime')

        inj_time_dt = inj_time;
        t_USpre = hour(t_USpre)*3600+minute(t_USpre)*60+second(t_USpre);
        t_USpost = hour(t_USpost)*3600+minute(t_USpost)*60+second(t_USpost);
    
        t_CO2pre = hour(t_CO2pre)*3600+minute(t_CO2pre)*60+second(t_CO2pre);
        t_CO2post = hour(t_CO2post)*3600+minute(t_CO2post)*60+second(t_CO2post);

        t_BPpre = hour(t_BPpre)*3600+minute(t_BPpre)*60+second(t_BPpre);
        t_BPpost = hour(t_BPpost)*3600+minute(t_BPpost)*60+second(t_BPpost);
    
        inj_time = hour(inj_time)*3600+minute(inj_time)*60+second(inj_time);
    end
    
    % sync variables and change to correct sampling
    [t_post_up, BPpost, USpost, CO2post, fspost] = samplesync(t_BPpost, BPpost, t_USpost, USpost, t_CO2post, CO2post);
    [t_pre_up, BPpre, USpre, CO2pre, fspre] = samplesync(t_BPpre, BPpre, t_USpre, USpre, t_CO2pre, CO2pre);
      
    
    % Compute sampling frequency of synced data
    t_pre = t_pre_up;
    t_post = t_post_up;
    
    try
        fspre = 1/(t_pre(2)-t_pre(1));
    catch
        fspre = [];
    end
    
    try
        fspost = 1/(t_post(2)-t_post(1));
    catch
        fspost = [];
    end

end



