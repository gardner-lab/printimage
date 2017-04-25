% Most Software Machine Data File

%% ScanImage

%Scanner systems
scannerNames = {'ResScanner'};      % Cell array of string names for each scan path in the microscope
scannerTypes = {'Resonant'};        % Cell array indicating the type of scanner for each name. Current options: {'Resonant' 'Linear}

%Simulated mode
simulated = false;                  % Boolean for activating simulated mode. For normal operation, set to 'false'. For operation without NI hardware attached, set to 'true'.

%Optional components
components = {};                    % Cell array of optional components to load. Ex: {'dabs.thorlabs.ECU1' 'dabs.thorlabs.BScope2'}

%Data file location
dataDir = '[MDF]\ConfigData';       % Directory to store persistent configuration and calibration data. '[MDF]' will be replaced by the MDF directory

objectiveResolution = 37;

startUpScript = '';

%% Shutters
%Shutter(s) used to prevent any beam exposure from reaching specimen during idle periods. Multiple
%shutters can be specified and will be assigned IDs in the order configured below.
shutterDaqDevices = {'PXI1Slot4'};  % Cell array specifying the DAQ device or RIO devices for each shutter eg {'PXI1Slot3' 'PXI1Slot4'}
shutterChannelIDs = {'PFI0'};      % Cell array specifying the corresponding channel on the device for each shutter eg {'port0/line0' 'PFI12'}

shutterOpenLevel = true;               % Logical or 0/1 scalar indicating TTL level (0=LO;1=HI) corresponding to shutter open state for each shutter line. If scalar, value applies to all shutterLineIDs
shutterOpenTime = 0.1;              % Time, in seconds, to delay following certain shutter open commands (e.g. between stack slices), allowing shutter to fully open before proceeding.

shutterNames = {'Shutter 1'};

%% Beams
beamDaqDevices = {'PXI1Slot6'};                            % Cell array of strings listing beam DAQs in the system. Each scanner set can be assigned one beam DAQ ex: {'PXI1Slot4'}

% Define the parameters below for each beam DAQ specified above, in the format beamDaqs(N).param = ...
beamDaqs(1).modifiedLineClockIn = '';           % one of {PFI0..15, ''} to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).frameClockIn = '';                  % one of {PFI0..15, ''} to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockIn = '';              % one of {PFI0..15, ''} to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus

beamDaqs(1).chanIDs = [0 1];                       % Array of integers specifying AO channel IDs, one for each beam modulation channel. Length of array determines number of 'beams'.
beamDaqs(1).displayNames = {'Ch1 780' 'Ch2 1140'};  % Optional string cell array of identifiers for each beam
beamDaqs(1).voltageRanges = [2 2];                % Scalar or array of values specifying voltage range to use for each beam. Scalar applies to each beam.

beamDaqs(1).calInputChanIDs = [0 1];               % Array of integers specifying AI channel IDs, one for each beam modulation channel. Values of nan specify no calibration for particular beam.
beamDaqs(1).calOffsets = [-0.00222381 -0.00756629];                    % Array of beam calibration offset voltages for each beam calibration channel
beamDaqs(1).calUseRejectedLight = [false false];        % Scalar or array indicating if rejected light (rather than transmitted light) for each beam's modulation device should be used to calibrate the transmission curve 
beamDaqs(1).calOpenShutterIDs = 1;             % Array of shutter IDs that must be opened for calibration (ie shutters before light modulation device).
beamDaqs(1).referenceClockRate = 1e+07;

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

%Resonant mirror and galvo settings
galvoDeviceName = 'PXI1Slot2';      % String identifying the NI-DAQ board to be used to control the galvo(s). The name of the DAQ-Device can be seen in NI MAX. e.g. 'Dev1' or 'PXI1Slot3'. This DAQ board needs to be installed in the same PXI chassis as the FPGA board specified in section %% ResonantAcq
galvoDeviceFrameClockIn = '';       % one of {PFI0..15, ''} to which external frame trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
galvoAOChanIDX = [];                % The numeric ID of the Analog Output channel to be used to control the X Galvo. Can be empty for standard Resonant Galvo scanners.
galvoAOChanIDY = 1;                 % The numeric ID of the Analog Output channel to be used to control the Y Galvo.

xGalvoAngularRange = [];            % max range in optical degrees (pk-pk) for x galvo if present
yGalvoAngularRange = 20;            % max range in optical degrees (pk-pk) for y galvo

galvoVoltsPerOpticalDegreeX = 1;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)
galvoVoltsPerOpticalDegreeY = 1;  % galvo conversion factor from optical degrees to volts (negative values invert scan direction)
galvoParkDegreesX = -8;             % Numeric [deg]: Optical degrees from center position for X galvo to park at when scanning is inactive
galvoParkDegreesY = -8;             % Numeric [deg]: Optical degrees from center position for Y galvo to park at when scanning is inactive

resonantAngularRange = 26;          % max range in optical degrees (pk-pk) for resonant

resonantZoomDeviceName = 'PXI1Slot2';        % String identifying the NI-DAQ board to host the resonant zoom analog output. Leave empty to use same board as specified in 'galvoDeviceName'
resonantZoomAOChanID = 0;           % resonantZoomAOChanID: The numeric ID of the Analog Output channel to be used to control the Resonant Scanner Zoom level.

rScanVoltsPerOpticalDegree = 0.2155;% resonant scanner conversion factor from optical degrees to volts
resonantScannerSettleTime = 0.5;    % [seconds] time to wait for the resonant scanner to reach its desired frequency after an update of the zoomFactor


%% FastZ
%FastZ hardware used for fast axial motion, supporting fast stacks and/or volume imaging
%fastZControllerType must be specified to enable this feature. 
%Specifying fastZControllerType='useMotor2' indicates that motor2 ControllerType/StageType/COMPort/etc will be used.
fastZControllerType = 'thorlabs.pfm450';           % If supplied, one of {'useMotor2', 'pi.e709', 'pi.e753', 'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}. 
fastZCOMPort = [];                  % Integer identifying COM port for controller, if using serial communication
fastZBaudRate = [];                 % Value identifying baud rate of serial communication. If empty, default value for controller used.

%Some FastZ hardware requires or benefits from use of an analog output used to control sweep/step profiles
%If analog control is used, then an analog sensor (input channel) must also be configured
fastZDeviceName = 'PXI1Slot5';               % String specifying device name used for FastZ control
frameClockIn = '';                  % One of {PFI0..15, ''} to which external frame trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
fastZAOChanID = 0;                 % Scalar integer indicating AO channel used for FastZ control
fastZAIChanID = 4;                 % Scalar integer indicating AI channel used for FastZ sensor

%% LSC Pure Analog
commandVoltsPerMicron = 10/450; % Conversion factor for command signal to analog linear stage controller
sensorVoltsPerMicron = 10/450;  % Conversion signal for sensor signal from analog linear stage controller. Leave empty for automatic calibration
commandVoltsOffset = 0; % Offset value, in volts, for command signal to analog linear stage controller
sensorVoltsOffset = 0;  % Offset value, in volts, for sensor signal from analog linear stage controller. Leave empty for automatic calibration

% Optional limits (any of these fields can be left blank; if ommited, default limits are +/-10V)
maxCommandVolts = 10;       % Maximum allowable voltage command
maxCommandPosn = 450;        % Maximum allowable position command in microns
minCommandVolts = 0;       % Minimum allowable voltage command
minCommandPosn = 0;        % Minimum allowable position command in microns

analogCmdBoardID = 'PXI1Slot5'; % String specifying NI board identifier (e.g. 'Dev1') containing AO channel for LSC control
analogCmdChanIDs = 0; % Scalar indicating AO channel number (e.g. 0) used for analog LSC control
analogSensorBoardID = 'PXI1Slot5'; % String specifying NI board identifier (e.g. 'Dev1') containing AI channel for LSC position sensor
analogSensorChanIDs = 0; % Scalar indicating AI channel number (e.g. 0) used for analog LSC position sensor


%% Motors
%Motor used for X/Y/Z motion, including stacks. 
%motorDimensions & motorControllerType must be specified to enable this feature.
motorControllerType = 'sutter.mpc200';           % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motorDimensions = 'XYZ';               % If supplied, one of {'XYZ', 'XY', 'Z'}. Defaults to 'XYZ'. To reassign physical axis, permute axis order (e.g. 'XZY')
motorStageType = '';                % Some controller require a valid stageType be specified
motorUSBName = '';                  % USB resource name if controller is connected via USB
motorCOMPort = 3;                  % Integer identifying COM port for controller, if using serial communication
motorBaudRate = [];                 % Value identifying baud rate of serial communication. If empty, default value for controller used.
motorZDepthPositive = true;         % Logical indicating if larger Z values correspond to greater depth
motorPositionDeviceUnits = [];      % 1x3 array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motorVelocitySlow = [];             % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motorVelocityFast = [];             % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.

%Secondary motor for Z motion, allowing either XY-Z or XYZ-Z hybrid configuration
motor2ControllerType = '';          % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motor2StageType = '';               % Some controller require a valid stageType be specified
motor2USBName = '';                 % USB resource name if controller is connected via USB
motor2COMPort = [];                 % Integer identifying COM port for controller, if using serial communication
motor2BaudRate = [];                % Value identifying baud rate of serial communication. If empty, default value for controller used.
motor2ZDepthPositive = true;        % Logical indicating if larger Z values correspond to greater depth
motor2PositionDeviceUnits = [];     % 1x3 array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motor2VelocitySlow = [];            % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motor2VelocityFast = [];            % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.

%Global settings that affect primary and secondary motor
moveCompleteDelay = 0;              % Numeric [s]: Delay from when stage controller reports move is complete until move is actually considered complete. Allows settling time for motor

