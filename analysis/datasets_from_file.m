% Function: datasets_from_file
%
% Purpose: to extract data from file name, synchronize, and perform average
% on multiple traces if user chooses. Main input is BP.
%
% Input parameters:
%   fname: string
%   label: string (optional)
%   t_range: (optional)
%
% Output parameters:
%   time, Y, U_BP, U_CO2: T x 1 double
%   ts: double
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function [time, Y ,U_BP, U_CO2, ts, zero_inds] = datasets_from_file(fname, label, t_range)
    
    % extract data
    if nargin == 1
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time, inj_time_dt] = extract_and_sync(fname);
    else
        [t_pre, BPpre, CO2pre, USpre, t_post, BPpost, CO2post, USpost, fspre, fspost, inj_time, inj_time_dt] = extract_and_sync(fname, label);
    end
    
    t = [t_pre t_post];
    BP = [BPpre BPpost];
    US = [USpre USpost];
    CO2 = [CO2pre CO2post];
    
        
%     % deal with nan in BP
%     if any(isnan(BP))
%         BP =interpnan(BP);
%     end
    
    
    %%% display figure for deciding which parts of trace to extract %%%
    if nargin == 2
        figure(2)
        
        % full bounds
        min_time = min(t_pre-inj_time)/60;
        max_time = max(t_post-inj_time)/60;

        % if you want to zoom in
%         min_time=  -400;
%         max_time = -300;


        if isempty(min_time)
            min_time = min(t_post-inj_time)/60;
        end

        if isempty(max_time)
            max_time = max(t_pre-inj_time)/60;
        end
        
        window = [min_time, max_time];
        lineint = 10;
        
        set(figure(2), 'Position',  [50,75,1180,825]);
        % set(figure(2), 'Position',  [50,75,2990,825]);
        subplot(2,1,1), plot((t-inj_time)/60, BP, 'LineStyle','none', 'Marker','.','MarkerEdgeColor', 'b');
        hold on;
        % plot((t_post-inj_time)/60, BPpost, 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        xline(window(1):lineint:window(2), ':b');
        %     xline((crit_times-inj_time)/60, 'g');
        xline(0, 'r');
        xlim([min_time, max_time])
        % ylim([0 1.2*max(BP(BP_inds))]);
        ylabel('BP (mmHg)');
        ylim([0 200])
        title('Mean Arterial Pressure')
        set(gca,'FontWeight','bold')
        set(gca,'LineWidth',1.5)
        hold off
        
        subplot(2,1,2), plot((t-inj_time)/60, robust_butter_median(t, US, 5,0.1), 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        hold on;
        % plot((t_post-inj_time)/60, abs(USpost), 'LineStyle','none', 'Marker','.','MarkerEdgeColor','b');
        xline(window(1):lineint:window(2), ':b');
        xline(0, 'r');
        xlim([min_time, max_time])
        % ylim([0 1.2*max(US(US_inds))]);
        xlabel('Time (min)')
        title('Spinal Cord Blood Flow')
        ylabel('Frequency (Hz)');
        set(gca,'FontWeight','bold')
        set(gca,'LineWidth',1.5)
        hold off

    %%% End of display figure %%%
    
        
        % Ask user for input
        indices = draw_data(figure(2));
        close(figure(2))
        
        % filter for determining t = 0 (for averaging)
        filt_size = 1000;
        av_filt = ones(filt_size, 1)/filt_size;    
        sync_inds = zeros(size(indices, 1), 1);    
        
        % ask user to determine sync points for averaging
        figure(3)
        hold off
        for ind = 1:size(indices, 1)
            findpeaks(conv(BP(indices(ind,1):indices(ind,2)), av_filt, 'full'),'MinPeakProminence',2);  %, 'MinPeakWidth', 15, 'MinPeakProminence',10, 'NPeaks',3);
            sync_index = draw_sync_points(figure(3));
            sync_inds(ind) = indices(ind,1)+ sync_index - filt_size/2;
        end

    else
        t_range = hour(t_range)*3600+minute(t_range)*60+second(t_range);
        [~, indices] = min(abs(t_pre' - (t_range)));

        if indices(2) == 1 | indices(2) == length(t_pre)
            [~, indices] = min(abs(t_post' - (t_range))); 
        end

        sync_inds = indices(2);
        indices = indices([1,3]);
    end
    
    
    % if multiple traces chosen find borders
    sync_bounds = [max(indices(:,1) - sync_inds), min(indices(:,2) - sync_inds)]+sync_inds;
    [t_comb, BP_comb, US_comb, CO2_comb] = deal(zeros(sync_bounds(1,2)-sync_bounds(1,1)+1, size(indices, 1)));

    % convert sync_time to datetime for storage
    zero_inds = inj_time_dt+seconds(t(sync_inds)-inj_time);
    
    % combined matrices with synced time
    for ind = 1:size(indices, 1)
        t_comb(:,ind) = t(sync_bounds(ind,1):sync_bounds(ind,2)) - t(sync_inds(ind));
        BP_comb(:,ind) = BP(sync_bounds(ind,1):sync_bounds(ind,2));
        US_comb(:,ind) = US(sync_bounds(ind,1):sync_bounds(ind,2));
        try
            CO2_comb(:,ind) = CO2(sync_bounds(ind,1):sync_bounds(ind,2));
        end
    end
    
    % Briefly display all traces for user evaluation    
    subplot(3,1,1), plot(t_comb, BP_comb)
    subplot(3,1,2), plot(t_comb, US_comb)
    subplot(3,1,3), plot(t_comb, CO2_comb)

    pause(2)
    close(figure(3))
    
    % find etCO2 from raw capnography
    etCO2_comb = movmean(CO2_comb, 16, 1, 'omitnan');
    etCO2_comb = movmax(etCO2_comb, 500, 1, 'omitnan');
    etCO2_comb = movmedian(etCO2_comb, 2000, 1, 'omitnan');
    etCO2_comb = movmean(etCO2_comb, 2000, 1, 'omitnan');
    
    % calculate mean from traces
    BP_mean = mean(BP_comb,2);
    US_mean = mean(US_comb,2);
    CO2_mean = mean(CO2_comb,2);
    etCO2_mean = mean(etCO2_comb,2);
    
    % final outputs
    time = t_comb(:,1);
    Y = US_mean;
    U_BP = BP_mean;
    U_CO2 = etCO2_mean;
    
    try 
        ts = 1/fspre;
    catch
        ts = 1/fspost;
    end

    % final figure to evaluate performance
%     figure(4)
%     subplot(3,1,1)
%     plot(time, BP_mean)
%     hold on
%     plot(time, U_BP)
% 
%     subplot(3,1,2)
%     plot(time, CO2_mean)
%     hold on
%     plot(time, etCO2_mean)
%     ylim([30 50])
% 
%     subplot(3,1,3)
%     plot(time, US_mean)
%     hold on
%     plot(time, Y)
end


