% Most Software Machine Data File

%% ScanImage

%Global microscope properties
objectiveResolution = 37;           % Resolution of the objective in microns/degree of scan angle

%Scanner systems
scannerNames = {'ResScanner'};      % Cell array of string names for each scan path in the microscope
scannerTypes = {'Resonant'};        % Cell array indicating the type of scanner for each name. Current options: {'Resonant' 'Linear' 'SLM'}

%Simulated mode
simulated = false;                  % Boolean for activating simulated mode. For normal operation, set to 'false'. For operation without NI hardware attached, set to 'true'.

%Optional components
components = {};                    % Cell array of optional components to load. Ex: {'dabs.thorlabs.ECU1' 'dabs.thorlabs.BScope2'}

%Data file location
dataDir = '[MDF]\ConfigData';       % Directory to store persistent configuration and calibration data. '[MDF]' will be replaced by the MDF directory

startUpScript = '';

%% Shutters
%Shutter(s) used to prevent any beam exposure from reaching specimen during idle periods. Multiple
%shutters can be specified and will be assigned IDs in the order configured below.
shutterNames = {'Main Shutter'};    % Cell array specifying the display name for each shutter eg {'Shutter 1' 'Shutter 2'}
shutterDaqDevices = {'PXI1Slot4'};  % Cell array specifying the DAQ device or RIO devices for each shutter eg {'PXI1Slot3' 'PXI1Slot4'}
shutterChannelIDs = {'PFI0'};      % Cell array specifying the corresponding channel on the device for each shutter eg {'PFI12'}

shutterOpenLevel = true;               % Logical or 0/1 scalar indicating TTL level (0=LO;1=HI) corresponding to shutter open state for each shutter line. If scalar, value applies to all shutterLineIDs
shutterOpenTime = 0.1;              % Time, in seconds, to delay following certain shutter open commands (e.g. between stack slices), allowing shutter to fully open before proceeding.

%% Beams
beamDaqDevices = {'PXI1Slot6'};                            % Cell array of strings listing beam DAQs in the system. Each scanner set can be assigned one beam DAQ ex: {'PXI1Slot4'}

% Define the parameters below for each beam DAQ specified above, in the format beamDaqs(N).param = ...
beamDaqs(1).modifiedLineClockIn = '';           % one of {PFI0..15, ''} to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).frameClockIn = '';                  % one of {PFI0..15, ''} to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockIn = '';              % one of {PFI0..15, ''} to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockRate = 1e+07;          % if referenceClockIn is used, referenceClockRate defines the rate of the reference clock in Hz. Default: 10e6Hz

beamDaqs(1).chanIDs = 0;                       % Array of integers specifying AO channel IDs, one for each beam modulation channel. Length of array determines number of 'beams'.
beamDaqs(1).displayNames = {'Ch1 780'};                  % Optional string cell array of identifiers for each beam
beamDaqs(1).voltageRanges = 2;                % Scalar or array of values specifying voltage range to use for each beam. Scalar applies to each beam.

beamDaqs(1).calInputChanIDs = 0;               % Array of integers specifying AI channel IDs, one for each beam modulation channel. Values of nan specify no calibration for particular beam.
beamDaqs(1).calOffsets = -0.0037253;                    % Array of beam calibration offset voltages for each beam calibration channel
beamDaqs(1).calUseRejectedLight = false;        % Scalar or array indicating if rejected light (rather than transmitted light) for each beam's modulation device should be used to calibrate the transmission curve 
beamDaqs(1).calOpenShutterIDs = 1;             % Array of shutter IDs that must be opened for calibration (ie shutters before light modulation device).

%% Motors
%Motor used for X/Y/Z motion, including stacks. 

motors(1).controllerType = 'sutter.mpc200';           % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motors(1).dimensions = 'XYZ';               % Assignment of stage dimensions to SI dimensions. Can be any combination of X,Y,Z, and R.
motors(1).comPort = 3;                  % Integer identifying COM port for controller, if using serial communication
motors(1).customArgs = {};               % Additional arguments to stage controller. Some controller require a valid stageType be specified
motors(1).invertDim = '+++';                % string with one character for each dimension specifying if the dimension should be inverted. '+' for normal, '-' for inverted
motors(1).positionDeviceUnits = [];      % 1xN array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motors(1).velocitySlow = [];             % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motors(1).velocityFast = [];             % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motors(1).moveCompleteDelay = 0;        % Delay from when stage controller reports move is complete until move is actually considered complete. Allows settling time for motor
motors(1).moveTimeout = 10;              % Default: 2s. Fixed time to wait for motor to complete movement before throwing a timeout error
motors(1).moveTimeoutFactor = 0.0005;        % (s/um) Time to add to timeout duration based on distance of motor move command

%% FastZ
%FastZ hardware used for fast axial motion, supporting fast stacks and/or volume imaging

actuators(1).controllerType = 'analog';%'thorlabs.pfm450';           % If supplied, one of {'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}.
actuators(1).comPort = [];                  % Integer identifying COM port for controller, if using serial communication
actuators(1).customArgs = {};               % Additional arguments to stage controller
actuators(1).daqDeviceName = 'PXI1Slot5';            % String specifying device name used for FastZ control
actuators(1).frameClockIn = '';             % One of {PFI0..15, ''} to which external frame trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
actuators(1).cmdOutputChanID = 0;          % AO channel number (e.g. 0) used for analog position control
actuators(1).sensorInputChanID = 0;        % AI channel number (e.g. 0) used for analog position sensing
actuators(1).commandVoltsPerMicron = 0.020202;    % Conversion factor for desired command position in um to output voltage
actuators(1).commandVoltsOffset = [];        % Offset in volts for desired command position in um to output voltage
actuators(1).sensorVoltsPerMicron = 0.020202;     % Conversion factor from sensor signal voltage to actuator position in um. Leave empty for automatic calibration
actuators(1).sensorVoltsOffset = -0.12;        % Sensor signal voltage offset. Leave empty for automatic calibration
actuators(1).maxCommandVolts = 10;          % Maximum allowable voltage command
actuators(1).maxCommandPosn = 450;           % Maximum allowable position command in microns
actuators(1).minCommandVolts = 0;          % Minimum allowable voltage command
actuators(1).minCommandPosn = 0;           % Minimum allowable position command in microns
actuators(1).optimizationFcn = [];          % Function for waveform optimization
actuators(1).affectedScanners = {};         % If this actuator only changes the focus for an individual scanner, enter the name

%% ResScan (ResScanner)
nominalResScanFreq = 7910;          % [Hz] nominal frequency of the resonant scanner
beamDaqID = 1;                     % Numeric: ID of the beam DAQ to use with the resonant scan system
shutterIDs = 1;                     % Array of the shutter IDs that must be opened for resonant scan system to operate

digitalIODeviceName = 'PXI1Slot2';  % String: Device name of the DAQ board or FlexRIO FPGA that is used for digital inputs/outputs (triggers/clocks etc). If it is a DAQ device, it must be installed in the same PXI chassis as the FlexRIO Digitizer

fpgaModuleType = 'NI7961';          % String: Type of FlexRIO FPGA module in use. One of {'NI7961' 'NI7975'}
digitizerModuleType = 'NI5732';     % String: Type of digitizer adapter module in use. One of {'NI5732' 'NI5734'}
rioDeviceID = 'RIO0';               % FlexRIO Device ID as specified in MAX. If empty, defaults to 'RIO0'
channelsInvert = [true true];             % Logical: Specifies if the input signal is inverted (i.e., more negative for increased light signal)

externalSampleClock = false;        % Logical: use external sample clock connected to the CLK IN terminal of the FlexRIO digitizer module
externalSampleClockRate = [];       % [Hz]: nominal frequency of the external sample clock connected to the CLK IN terminal (e.g. 80e6); actual rate is measured on FPGA

enableRefClkOutput = false;         % Enables/disables the 10MHz reference clock output on PFI14 of the digitalIODevice

%Galvo mirror settings
galvoDeviceName = 'PXI1Slot2';      % String identifying the NI-DAQ board to be used to control the galvo(s). The name of the DAQ-Device can be seen in NI MAX. e.g. 'Dev1' or 'PXI1Slot3'. This DAQ board needs to be installed in the same PXI chassis as the FPGA board specified in section
galvoAOChanIDX = [];                % The numeric ID of the Analog Output channel to be used to control the X Galvo. Can be empty for standard Resonant Galvo scanners.
galvoAOChanIDY = 1;                 % The numeric ID of the Analog Output channel to be used to control the Y Galvo.

galvoAIChanIDX = [];                % The numeric ID of the Analog Input channel for the X Galvo feedback signal.
galvoAIChanIDY = [];                % The numeric ID of the Analog Input channel for the Y Galvo feedback signal.

xGalvoAngularRange = [];            % max range in optical degrees (pk-pk) for x galvo if present
yGalvoAngularRange = 20;            % max range in optical degrees (pk-pk) for y galvo

galvoVoltsPerOpticalDegreeX = 1;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)
galvoVoltsPerOpticalDegreeY = 0.97;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)

galvoParkDegreesX = -8;             % Numeric [deg]: Optical degrees from center position for X galvo to park at when scanning is inactive
galvoParkDegreesY = -8;             % Numeric [deg]: Optical degrees from center position for Y galvo to park at when scanning is inactive

%Resonant mirror settings
resonantZoomDeviceName = 'PXI1Slot2';        % String identifying the NI-DAQ board to host the resonant zoom analog output. Leave empty to use same board as specified in 'galvoDeviceName'
resonantZoomAOChanID = 0;           % resonantZoomAOChanID: The numeric ID of the Analog Output channel to be used to control the Resonant Scanner Zoom level.

resonantAngularRange = 26;          % max range in optical degrees (pk-pk) for resonant
rScanVoltsPerOpticalDegree = 0.2155;  % resonant scanner conversion factor from optical degrees to volts

resonantScannerSettleTime = 0.5;    % [seconds] time to wait for the resonant scanner to reach its desired frequency after an update of the zoomFactor

