% Script: open_picoscope
%
% Purpose: call this script to open picoscope in a safe fashion (that
% doesn't require computer restart
%
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)


%% Close any existing scope (prevents driver error that requires restart)

try 
    disconnect(ps2000DeviceObj);
    delete(ps2000DeviceObj);
end

%% Load Configuration Information

PS2000Config;

%%% Parameter Definitions
% Define any additional parameters that will be used throughout the script.
channelA = ps2000Enuminfo.enPS2000Channel.PS2000_CHANNEL_A;
channelB = ps2000Enuminfo.enPS2000Channel.PS2000_CHANNEL_B;

%%% Device Connection
% Create a device object. 
ps2000DeviceObj = icdevice('picotech_ps2000_generic.mdd');
% Connect device object to hardware.
connect(ps2000DeviceObj);


% Obtain references to device groups to access their respective properties
% and functions.
blockGroupObj = get(ps2000DeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Streaming specific properties and functions are located in the Instrument
% Driver's Streaming group.
streamingGroupObj = get(ps2000DeviceObj, 'Streaming');
streamingGroupObj = streamingGroupObj(1);

% Trigger specific properties and functions are located in the Instrument
% Driver's Trigger group.
triggerGroupObj = get(ps2000DeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);


%% Configure Device
% Enable Channels A and B, set the sampling interval and the number of
% samples to collect.

% Set channels - channel information is loaded from the PS2000Config file:

% Channel     : 0 (ps2000Enuminfo.enPS2000Channel.PS2000_CHANNEL_A)
% Enabled     : 1 (PicoConstants.TRUE)
% DC          : 1 (DC Coupling)
% Range       : 6 (ps2000Enuminfo.enPS2000Range.PS2000_1V)
[status.setChA] = invoke(ps2000DeviceObj, 'ps2000SetChannel', channelA, ...
    ps2000ConfigInfo.channelSettings.channelA.enabled, ps2000ConfigInfo.channelSettings.channelA.dc, ...
    7);

% Obtain the voltage range for the channel (in millivolts).
% chARangeMv = PicoConstants.SCOPE_INPUT_RANGES(ps2000ConfigInfo.channelSettings.channelA.range)
chARangeMv = PicoConstants.SCOPE_INPUT_RANGES(8);

% Find the maximum ADC Count from the driver.
maxADCCount = get(ps2000DeviceObj, 'maxADCValue');



[status.setChB] = invoke(ps2000DeviceObj, 'ps2000SetChannel', channelB, ...
    0, ps2000ConfigInfo.channelSettings.channelA.dc, ...
    8);


%% Trigger setup: disable trigger in our case

% Turn trigger off. 
[status.setTriggerOff] = invoke(triggerGroupObj, 'setTriggerOff');

%% Set sampling and buffer settings for MAP. 

% NOTE: The driver will calculate the nearest sampling
% interval that is relatively shorter if an exact match cannot be found.
% Sampling rates faster than 1MS/s are not recommended as these are low
% memory devices.
samplingIntervalMs = 1; % 1 ms
set(streamingGroupObj, 'streamingIntervalMs', samplingIntervalMs);

% Collect 1 million samples from the driver
numStreamingSamples = 10000000;
set(ps2000DeviceObj, 'numberOfSamples', numStreamingSamples);

% Set the size of the overview buffer used for streaming capture.
% This is the size of the internal buffer for each channel and should be
% large enough to accommodate the data that is collected in the time it
% takes to execute an iteration of the loop below.
set(streamingGroupObj, 'overviewBufferSize', 100000);

% Set Application Buffers
% The data for each channel will be collected into a corresponding
% application buffer.
%
% Ensure application buffers are large enough to accommodate pre- and
% post-trigger samples, as Data collection will stop if the application
% buffer becomes full.
%
% If capturing data without using the autoStop flag, or if using a trigger
% with the autoStop flag, allocate sufficient space (1.5 times the sum of
% the number of pre-trigger and post-trigger samples is shown below) to
% allow for additional pre-trigger data. Pre-allocating the array is more
% efficient than using vertcat to combine data.
%
% The maximum array size will depend on PC's resources - type
% <matlab:doc('memory') |memory|> at the MATLAB command prompt for further
% information.
appBufferSize = numStreamingSamples * 1.5;
pAppBufferChA = libpointer('int16Ptr', zeros(appBufferSize, 1, 'int16'));

% Set the application buffers in the underlying wrapper library.
invoke(streamingGroupObj, 'setBuffer', channelA, pAppBufferChA, appBufferSize);


%% Miscellaneous other parameters

% Set aggregation ratio to 1
numSamplesPerAggregate = 1;

% Variables to be used when collecting the data
hasAutoStopped          = PicoConstants.FALSE;
isAppBufferFull         = PicoConstants.FALSE;
totalBPSamples          = 0;
previousBPTotalSamples  = 0; % Keep track of previous total.
hasTriggered            = 0; % To indicate if trigger has occurred.
triggeredAtIndex        = 0; % The index in the overall buffer where the trigger occurred.