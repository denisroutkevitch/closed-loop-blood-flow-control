% Script: real_time_feedback_control
%
% Purpose: to implement the real-time feedback control system. Inputs: MAP
% and MFV. Output: infusion rate to Genie pump.
%
% HARDWARE REQUIREMENTS (each detected automatically at startup):
%   1. PicoScope 2000 (arterial blood pressure / MAP)
%      - Requires PicoScope MATLAB SDK (PS2000Config, picotech_ps2000_generic.mdd)
%      - If absent: MAP is recorded as NaN (control loop runs in open loop)
%   2. Sound Blaster G3 USB audio card (mean flow velocity / MFV)
%      - Connected to a transcranial Doppler or transit-time flow probe
%      - If absent: MFV is recorded as NaN (closed-loop control disabled)
%   3. Genie syringe pump on serial port (drug infusion)
%      - Set pump_com below to match your system's COM port
%      - If absent: infusion commands are skipped (no drug delivered)
%
% Created by: Denis Routkevitch  (droutke1@jhmi.edu)


%% Clear Command Window and Close any Figures

clc;
close all;

%% Step 0: Experiment parameters

%%% Use sound_test to determine best thresh value
thresh = 2.1;

%%% Choose operating room location (used for PicoScope BP calibration)
% or_loc = 'Traylor 7';
or_loc = 'Ross 4';

%%% Choose controller
controller_name = '240811 Rat System ID - Official Controllers.mat';
% controller_name = '240918 Pig System ID - Official Controllers.mat';
% controller_name = '250529 Pig Intraoperative NIRS System ID - Official Controllers.mat';

%%% Set drug infusion parameters
subj_weight = 25000; %g
drug_conc = 0.04; % mg/mL
syringe_size = 50; % mL

%%% Set baseline infusion rate
I_0 = 0.0001; % mg/kg/min (note: units differ from the GUI display)

% various infusion limits
I_0_BL = I_0;
max_I = 0.01;

%%% Com port info
pump_com = 'COM7';
% US_com = "Line (Sound Blaster G3)";
US_com = "Line (2- Sound Blaster G3)";

% load the chosen controller
load(controller_name, 'K_h')

%% Step 1: Set parameters for real_time

% loop processing parameters (unlikely to need to change)
update_time = 1; % s
buffer_time = 600; % s
averaging_time = 0.5; % s
cutoff_freq = 0.05; % Hz
baseline_time = 20; %s

% rate control to ensure even updates
r = rateControl(update_time);
r.OverrunAction = 'drop';


%% Step 2: Start PicoScope (HARDWARE: PicoScope 2000 + SDK)

% check if picoscope connected and initialize
try
    open_picoscope;
    pico_connected = true;

% allow loop to run without PicoScope signals
catch
    warning('Picoscope not connected - NOT RECORDING MAP')
    pico_connected = false;
    samplingIntervalMs = 1;

end


%% Step 3: Establish audio recording object for MFV (HARDWARE: Sound Blaster G3 + Doppler probe)

% recording parameters
audio_sampling_rate = 44100; % Hz
frame_size = audio_sampling_rate * update_time; % how many samples to load


% check if audio connected
try
    lastwarn('');
    deviceReader = audioDeviceReader(audio_sampling_rate, frame_size, "Device", US_com);
    US_connected = true;

    [warnMsg, warnId] = lastwarn;
    if ~isempty(warnMsg)
        error('US not connected')
    end

% allow loop to run without US measurement
catch
    warning('Ultrasound not connected - NOT RECORDING MFV')
    US_connected = false;

end


%% Step 4: Establish Serial Communication with Syringe Pump (HARDWARE: Genie pump, COM port)

% check if pump connected
try
    if exist('pump', 'var') == 0
        pump = serialport(pump_com, 9600); % double check port 
        flush(pump);
        status = getpinstatus(pump);
        configureTerminator(pump, 3, "CR");
    
        pump.Timeout = 2;
        pump.StopBits = 1;   
    end
    

    % Pump connected confirm
    fprintf('Drug pump connected on %s \n', pump.Port);
    pump_connected = true;
    
    % stop pump to update with all settings
    try
        last_comm = tell_pump(pump, "STP");
    end


    % infusion log (for vet team)
    last_comm = tell_pump(pump, "DIS");
    writecell({datetime("now"), last_comm}, 'Inf Record.txt', 'WriteMode','append');
    
    % choose syringe diameter
    if syringe_size == 5
        last_comm = tell_pump(pump, "DIA12.06"); % 5 mL Syringes
    elseif syringe_size == 50 | syringe_size == 60
        last_comm = tell_pump(pump, "DIA26.7"); % 50 and 60 mL Syringes
    else
        error("Syringe size not specified");
    end
    
    % tell pump the new rate
    last_comm = tell_pump(pump, "PHN1");
    last_comm = tell_pump(pump, "VOL9999");
    last_comm = tell_pump(pump, "RAT10UM");
    last_comm = mlkgmin_to_ulmin(pump, I_0, subj_weight, drug_conc);


% allow loop to run if pump not connected
catch
    warning('Drug pump not connected - INFUSION NOT CONTROLLED');
    pump_connected = false;

end


%% Step 5: The actual feedback control loop

%%%%% MISCELLANEOUS INITIALIZATION %%%%%
% reset audio recording and writing devices
if US_connected
    release(deviceReader)
end

try
    release(wavFileWriter);
end

% another PicoScope initialization step
if pico_connected
    invoke(streamingGroupObj, 'clearFastStreamingParameters');
    [status.stop] = invoke(ps2000DeviceObj, 'ps2000Stop');
end

% make Data folder if needed
if ~isfolder('Data')
    mkdir('Data')
end

% set save name for this run (based on existing recordings)
runs_so_far = length({dir(fullfile('Data', sprintf('%s*ideal.txt', datetime('now', 'Format', 'yyMMdd')))).name});
this_run_name = fullfile('Data', sprintf('%s -%03g-', datetime('now', 'Format', 'yyMMdd'),runs_so_far+1));

% open audio file for writing
wav_name = sprintf('%s raw US.wav', this_run_name);
wavFileWriter = dsp.AudioFileWriter(wav_name,'FileFormat','WAV');

% add headers for the following files
writecell({'time', 'MFV target (frac of max)'}, sprintf('%s MFV ideal.txt', this_run_name),'WriteMode','append')
writecell({'time', 'MAP_0', 'MFV_0', 'I_0'}, sprintf('%s BL values.txt', this_run_name),'WriteMode','append')

% initialize plot variables.
plotted_US = NaN;
t_plotted_US = NaT;
plotted_BP = NaN;
t_plotted_BP = NaT;

% initialize target variable (called MFV_ideal here)
MFV_ideal = [];
last_target_update = datetime('now');

% initialize internal buffer variables.
BP_buffer = [];
t_BP_buffer = datetime([],[],[], 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
US_buffer = [];
t_US_buffer = datetime([],[],[], 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

% initialize sample tracking variables
% (and how many samples are missed due to lag)
first_time = 1;
totalUSsamples = 0;
totalUSoverrun = 0;
previousBPSampleNum = 0;
totalBPoverrun = 0;
thisLoopSamples = 0;

% text in command window for updating
bl_text_length = 0;

%%%%% END MISCELLANEOUS INITIALIZATION %%%%%


% start GUI
[GUIfig.f, GUIfig.h] = controlGUI(controller_name, buffer_time, I_0_BL, subj_weight, drug_conc, syringe_size, or_loc);


%%%%% INITIALIZE LIVE PLOT %%%%%
% initialize figure
figure1 = figure('Name','Real-Time Feedback Control', ...
     'NumberTitle','off');
set(figure(1), 'Position', [773,234,1047,671])

axes1 = subplot(3,1,1);
axes2 = subplot(3,1,2);
axes3 = subplot(3,1,3);

% Blood Pressure
line1 = line(axes1, NaT, nan, 'LineWidth', 1.5);
xl1 = xline(axes1, datetime('now'));
axes1.XLim = datetime('now') + seconds([-10 3]);
xlabel(axes1, 'Time (hr:min:sec)');
ylabel(axes1, 'BP (mmHG)');
set(axes1,'LineWidth',1.5);
set(axes1,'FontSize',15);

% Blood Flow
line2 = line(axes2, NaT, nan, 'Color', 'red', 'LineWidth', 1.5);
xl2 = xline(axes2, datetime('now'));
axes2.XLim = datetime('now') + seconds([-10 3]);
xlabel(axes2, 'Time (hr:min:sec)');
ylabel(axes2, 'US (cm/s)');
set(axes2,'LineWidth',1.5);
set(axes2,'FontSize',15);

% target flow (updates with MFV_ideal later)
line2_1 = line(axes2, NaT, nan, 'LineWidth', 1.5);

% infusion
line3 = line(axes3, NaT, nan, 'LineWidth', 1.5);
xl3 = xline(axes3, datetime('now'));
axes3.XLim = datetime('now') + seconds([-10 3]);
xlabel(axes3, 'Time (hr:min:sec)');
ylabel(axes3, 'I(t) (\mug/kg/min)');
set(axes3,'LineWidth',1.5);
set(axes3,'FontSize',15);


%%%%% RECORDING LOOP START %%%%%

% Start time of the MAP data collection
BP_start = datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

% Start PicoScope data streaming
if pico_connected
    [status.runStreamingNs] = invoke(streamingGroupObj, 'ps2000RunStreamingNs', numSamplesPerAggregate);
end

% reset rate control
reset(r)

% Collect samples as long as the STOP button has not been pressed
while(GUIfig.h.bStop.Value == 0)



    %%%%% RECORD PICOSCOPE VARIABLES: MAP %%%%%
    
    % determines buffer length (needed even if Pico not connected)
    BP_buff_length = round(buffer_time*1000/samplingIntervalMs);

    % record Pico data
    if pico_connected
        ready = 0;

        % Wait for Picoscope to be ready
        while(ready == PicoConstants.FALSE)
            invoke(streamingGroupObj, 'pollFastStreaming');
            ready = invoke(streamingGroupObj, 'isFastStreamingReady');
            
            % drawnow;
        end           
    
        % Retrieve BP information.
        [totalBPValues, overflowBP, triggeredAt, hasTriggered, hasAutoStopped, ...
            isAppBufferFull, startIndex] = invoke(streamingGroupObj, 'getFastStreamingDetails');
        
        % warn if blood pressure overflowed
        if overflowBP
            warning("overflow of MAP")
        end
        
        % update BP sampling information
        totalBPoverrun = totalBPoverrun+double(overflowBP);
        thisLoopSamples = totalBPValues - previousBPSampleNum; % Calculate previous total.
        previousBPSampleNum = totalBPValues;
        
        % Position indices of data in the buffer(s).
        lastValuePosn = startIndex+thisLoopSamples;
        firstValuePosn = startIndex+1;
        
        % Convert data values to millivolts from the application buffer(s).
        bufferChAmV = adc2mv(pAppBufferChA.Value(max(1, lastValuePosn-BP_buff_length):lastValuePosn), chARangeMv, maxADCCount);
        
        % Convert PicoScope ADC millivolts to mmHg using room-specific calibration.
        % Calibration coefficients (slope, intercept) were determined by
        % simultaneously recording arterial line pressure and PicoScope voltage.
        if strcmp(or_loc, 'Traylor 7')
            BP_buffer = 0.100*bufferChAmV;              % rat calibration
        elseif strcmp(or_loc, 'Ross 4')
            BP_buffer = 0.1004*bufferChAmV + 5.442;    % pig calibration
        else
            error('Specify valid OR location (for PicoScope BP calculation)');
        end
    
        % index into BP buffer
        t_BP_last = BP_start + seconds((totalBPValues+totalBPoverrun)*samplingIntervalMs/1000);
        t_BP_buffer = t_BP_last - seconds(fliplr(1:length(bufferChAmV))*samplingIntervalMs/1000)';

        % define averaging filters
        BP_filt_length = averaging_time/samplingIntervalMs*1000;
    

    % if no PicoScope connected, record NaN
    else
        t_BP_buffer = datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        BP_buffer = nan;
        thisLoopSamples = 1;
        BP_filt_length = 1;
    end


    %%% write BP values to files
    writematrix(t_BP_buffer(end-thisLoopSamples+1:end), sprintf('%s t_BP.txt', this_run_name),'WriteMode','append')
    writematrix(BP_buffer(end-thisLoopSamples+1:end), sprintf('%s BP.txt', this_run_name),'WriteMode','append')
    

    
    %%%%% RECORD AUDIO VARIABLES: MFV %%%%%

    % start time for .wav file
    if first_time
        US_start = datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        BL_time = US_start;
        writecell({US_start, sprintf('Threshold: %g', thresh)}, sprintf('%s US start time.txt', this_run_name), 'WriteMode','append');
        first_time = 0;
    end
    
    % record US data
    if US_connected
        [audio, overrunUS] = deviceReader(); % retrieve data
        wavFileWriter(audio);                % record raw data to hard drive immediately
        
        % start time for this data chunk
        t_US_1 = US_start + seconds((totalUSsamples+totalUSoverrun)/audio_sampling_rate);
            
        % Extract spectral envelope frequency (Hz) from audio, then convert
        % to normalized flow units used by the controller.
        % The linear mapping (0.01*f_Hz + 1) was empirically calibrated to
        % place resting flow near 1.0 with a ~1% change per Hz Doppler shift.
        [t_US_chunk, US_chunk] = sound2vel_auto(audio', audio_sampling_rate, thresh, t_US_1);
        US_chunk = 0.01*US_chunk + 1;

        % update US sampling information
        totalUSsamples = totalUSsamples+length(audio);
        totalUSoverrun = totalUSoverrun+overrunUS;

        % refresh US buffer
        US_buff_length = round(buffer_time/(seconds(t_US_chunk(2)-t_US_chunk(1))));        
        US_buffer = [US_buffer(max(1, length(US_buffer)-US_buff_length):end); US_chunk];
        t_US_buffer = [t_US_buffer(max(1, length(t_US_buffer)-US_buff_length):end); t_US_chunk];

        % define averaging filter
        US_filt_length = averaging_time/(seconds(t_US_chunk(2)-t_US_chunk(1)));


    % if no audio device connected, record NaN
    else
        t_US_chunk = datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        US_chunk = nan;

        overrunUS = 0;
        US_filt_length = 1;
    end
    

    %%% write US values to files
    writematrix(t_US_chunk, sprintf('%s t_US.txt', this_run_name),'WriteMode','append')
    writematrix(US_chunk, sprintf('%s US.txt', this_run_name),'WriteMode','append')
    

    
    %%%%% PROCESS THE RECORDED SIGNALS %%%%%
    
    % calculate waveform signals
    % (averaging filter for vertical resolution enhancement)
    BP_oversampled = movmean(BP_buffer, BP_filt_length);
    Flow_oversampled = movmean(US_buffer, US_filt_length);
    
    % synchronize signals
    if ~sum(isnan(BP_oversampled)) && ~sum(isnan(Flow_oversampled))
        [t_sync, BP, Flow] = samplesyncRT(t_BP_buffer, BP_oversampled, t_US_buffer, Flow_oversampled, 40);
    elseif sum(isnan(BP_oversampled))
        [t_sync, ~, Flow] = samplesyncRT(t_US_buffer, ones(size(Flow_oversampled)), t_US_buffer, Flow_oversampled, 40);
        BP = [];
    elseif sum(isnan(Flow_oversampled))
        [t_sync, BP, ~] = samplesyncRT(t_BP_buffer, BP_oversampled, t_BP_buffer,  ones(size(BP_oversampled)), 40);
        Flow = [];
    else
        t_sync = datetime([],[],[]);
        [BP, Flow] = deal([]);
    end

    
    % store target if enough data has recorded
    if ~isempty(t_sync)
        % get target
        MFV_target = GUIfig.h.s3.Value;
        new_samples = sum(t_sync>last_target_update);
        
        % add to MFV vector
        MFV_ideal = [MFV_ideal; MFV_target*ones(new_samples,1)];
        MFV_ideal = MFV_ideal(max(1,end-length(t_sync)+1):end);
        
        % write target values to files
        last_target_update = t_sync(end);
        writecell({last_target_update, MFV_target}, sprintf('%s MFV ideal.txt', this_run_name),'WriteMode','append')
    end

    
    % generate MAP
    if ~isempty(BP)
        MAP = robust_butter(t_sync, BP, 2,cutoff_freq);
    else 
        MAP = [];
    end
    
    % generate MFV
    if ~isempty(Flow)
        MFV = robust_butter(t_sync, Flow, 2,cutoff_freq);
    else 
        MFV = [];
    end
    
    
    %%%%% OPEN VS CLOSED LOOP CONTROL %%%%%

    if ~isempty(t_sync) & seconds(t_sync(end)-BL_time) > baseline_time % excludes baseline acquisition
        
            
        % only update infusion if the pump is connected
        if pump_connected

            %%% CLOSED LOOP %%%
            if GUIfig.h.bControl.Value == 1 & US_connected
                % calculate error function: e(t)
                e_t = (MFV/MFV_0)-MFV_ideal;
        
                % calculate closed-loop infusion rate: I(t)
                % movmean window of 4x US_filt_length smooths controller
                % output to prevent pump chatter from rapid step changes
                I_t = movmean(I_0 + lsim(K_h, e_t, seconds(t_sync-t_sync(1))), US_filt_length*4);
        
                % impose the infusion limits
                new_rate = min(max(I_t(end),0), max_I);
                
                % update closed loop rate (records in overall infusion file)
                CRI_string = mlkgmin_to_ulmin(pump, new_rate, subj_weight, drug_conc);

                % update in command line
                fprintf([repmat('\b', 1, bl_text_length)]);
                bl_text_length = fprintf('Pump Command: %s; Rate: %g x I_0_BL\n', CRI_string, new_rate/I_0_BL);
            

            %%% OPEN LOOP %%%
            else 
                % update open-loop rate and record baseline values
                I_0 = GUIfig.h.s2.Value/1000;
                I_t = I_0 * ones(size(t_sync));
                new_rate = I_0;
                
                writecell({datetime('now'), MAP_0, MFV_0, I_0/I_0_BL}, sprintf('%s BL values.txt', this_run_name),'WriteMode','append')
                
                % records in overall infusion file
                last_comm = mlkgmin_to_ulmin(pump, I_0, subj_weight, drug_conc);

                % update command line
                fprintf([repmat('\b', 1, bl_text_length)]);
                bl_text_length = fprintf('%s\n', last_comm);
            end
        end
    

    %%% Baseline Acquisition %%%
    else
        % update baseline values as mean of each trace
        MAP_0 = mean(MAP);
        MFV_0 = mean(MFV);
        I_t = I_0 * ones(size(t_sync));
        
        % update baseline values in command window
        if seconds(datetime('now')-BL_time) < baseline_time
            fprintf([repmat('\b', 1, bl_text_length)]);
            bl_text_length = fprintf('Acquiring Baseline MAP (%g mmHg) and MFV (%g cm/s)\n', MAP_0, MFV_0);
        end
        
        % write baseline values to disk
        writecell({datetime('now'), MAP_0, MFV_0, I_0}, sprintf('%s BL values.txt', this_run_name),'WriteMode','append')
    end
    
    
    %%%%% LIVE PLOT UPDATE %%%%%
    % update plot signals
    if GUIfig.h.bMAP.Value == 1
        plotted_BP = MAP;
        t_plotted_BP = t_sync; 
    else
        plotted_BP = BP_buffer;
        t_plotted_BP = t_BP_buffer;
    end

    if GUIfig.h.bMFV.Value == 1
        plotted_US = MFV./MFV_0;
        t_plotted_US = t_sync;
    else
        plotted_US = US_buffer./MFV_0;
        t_plotted_US = t_US_buffer;
    end


    % makes the infusion graph dotted line in open loop scenario
    if GUIfig.h.bControl.Value == 1
        cl_toggle = '-';
    else
        cl_toggle = ':';
    end

    
    % update plots
    t_lim = -GUIfig.h.s1.Value*60;    
    
    % BP
    set(line1, 'XData', t_plotted_BP, 'YData', plotted_BP);
    axes1.XLim = datetime('now') + seconds([t_lim 3]);
    xl1.Value = datetime('now');
    
    % MFV and MFV_ideal (target)
    set(line2, 'XData', t_plotted_US, 'YData', plotted_US);
    set(line2_1, 'XData', t_sync, 'YData', MFV_ideal);
    axes2.XLim = datetime('now') + seconds([t_lim 3]);
    xl2.Value = datetime('now');
    
    % infusion
    set(line3, 'XData', t_sync, 'YData', I_t*1000, 'LineStyle', cl_toggle);
    axes3.XLim = datetime('now') + seconds([t_lim 3]);
    xl3.Value = datetime('now');
    

    % ensures even timing of 1 second per loop
    waitfor(r);
end


%%%%% CLOSING ACTIONS %%%%%
disp('Data collection complete.');
fprintf("Initial Rate: %g mg/kg/min\n", I_0_BL)
fprintf("Open-Loop Rate: %g mg/kg/min\n", I_0)
if ~exist("new_rate","var")
    new_rate = I_0;
end
fprintf("Current Rate: %g mg/kg/min\n", new_rate)


% Close the STOP button window
if(exist('GUIfig', 'var'))    
    close('Control GUI');
    clear GUIfig;        
end

% update plot
drawnow;


% shut down PicoScope connection
if pico_connected
    % Clear parameters held in the wrapper library if another data capture run
    % is to take place.
    invoke(streamingGroupObj, 'clearFastStreamingParameters');
    
    % Stop the Device.
    % This function should be called regardless of whether the autoStop
    % property is enabled or not.
    [status.stop] = invoke(ps2000DeviceObj, 'ps2000Stop');
    
    
    % Disconnect device object from hardware.
    disconnect(ps2000DeviceObj);
    delete(ps2000DeviceObj);
end

% shut down audio card connection
if US_connected
    release(deviceReader)
    release(wavFileWriter)
end