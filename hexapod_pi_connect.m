function hexapod_pi_connect()
    global STL;
    
    %% Loading the PI_MATLAB_Driver_GCS2
    if     (strfind(evalc('ver'), 'Windows XP'))
        if (~exist('C:\Documents and Settings\All Users\PI\PI_MATLAB_Driver_GCS2','dir'))
            error('The PI_MATLAB_Driver_GCS2 was not found on your system. Probably it is not installed. Please run PI_MATLAB_Driver_GCS2_Setup.exe to install the driver.');
        else
            addpath('C:\Documents and Settings\All Users\PI\PI_MATLAB_Driver_GCS2');
        end
    elseif (strfind(evalc('ver'), 'Windows'))
        if (~exist('C:\Users\Public\PI\PI_MATLAB_Driver_GCS2','dir'))
            error('The PI_MATLAB_Driver_GCS2 was not found on your system. Probably it is not installed. Please run PI_MATLAB_Driver_GCS2_Setup.exe to install the driver.');
        else
            addpath('C:\Users\Public\PI\PI_MATLAB_Driver_GCS2');
        end
    end
    
    if~isfield(STL, 'motors') | ~isfield(STL.motors, 'hex') | ~isfield(STL.motors.hex, 'Controller')
        STL.motors.hex.Controller = PI_GCS_Controller();
    end;
    
    if(~isa(STL.motors.hex.Controller, 'PI_GCS_Controller'))
        STL.motors.hex.Controller = PI_GCS_Controller();
    end
    
    
    %% Connecting to the C887
    
    devicesTcpIp = STL.motors.hex.Controller.EnumerateTCPIPDevices()
    nPI = length(devicesTcpIp);
    if nPI ~= 1
        error('%d PI controllers were found on the network. Choose one.');
    end
    disp(devicesTcpIp);
    
    
    % Parameters
    % You MUST EDIT AND ACITVATE the parameters to make your system run properly:
    % 1. Activate the connection type
    % 2. Set the connection settings
    
    % Connection settings
    STL.motors.hex.use_RS232_Connection    = false;
    STL.motors.hex.use_TCPIP_Connection    = true;
    
    
    if (STL.motors.hex.use_RS232_Connection)
        STL.motors.hex.comPort = 1;          % Look at the device manager to get the rigth COM port.
        STL.motors.hex.baudRate = 115200;    % Look at the manual to get the right baud rate for your controller.
    end
    
    if (STL.motors.hex.use_TCPIP_Connection)
        %devicesTcpIp = Controller.EnumerateTCPIPDevices('')
        STL.motors.hex.ip = '128.197.37.110';  % Use "devicesTcpIp = Controller.EnumerateTCPIPDevices('')" to get all PI controller available on the network.
        STL.motors.hex.port = 50000;           % Is 50000 for almost all PI controllers
    end
    
    
    % Open connection
    STL.motors.hex.boolC887connected = false;
    try
        hexapod_pi_disconnect();
    catch ME
    end
    
    if (isfield(STL.motors.hex, 'C887')) & STL.motors.hex.C887.IsConnected
        STL.motors.hex.boolC887connected = true;
    end
    
    
    if (~STL.motors.hex.boolC887connected)
        if (STL.motors.hex.use_RS232_Connection)
            STL.motors.hex.C887 = STL.motors.hex.Controller.ConnectRS232(STL.motors.hex.comPort, STL.motors.hex.baudRate);
        end
        
        if (STL.motors.hex.use_TCPIP_Connection)
            STL.motors.hex.C887 = STL.motors.hex.Controller.ConnectTCPIP(STL.motors.hex.ip, STL.motors.hex.port);
        end
    end
    
    %% Configuration and referencing
    
    % Query controller identification
    STL.motors.hex.C887.qIDN()
    
    % Query controller axes
    availableaxes = STL.motors.hex.C887.qSAI_ALL();
    if(isempty(availableaxes))
        error('No axes available');
    end
    

    % Reference stage
    fprintf('Referencing hexapod axes... ');
    for i = 1:6
        axis = availableaxes{i};
        fprintf('%s ', axis);
        STL.motors.hex.axes(i) = axis;
        if ~STL.motors.hex.C887.qFRF(axis)
            STL.motors.hex.C887.FRF(axis);
        end
    end
    
    for i = 1:6
        while ~STL.motors.hex.C887.qFRF(axis)
            pause(0.1);
        end
        STL.motors.hex.range(i,:) = [STL.motors.hex.C887.qTMN(axis) STL.motors.hex.C887.qTMX(axis)];
    end
    fprintf('done.\n');

    STL.motors.hex.C887.VLS(2);
    hexapod_reset_to_zero_rotation();
    STL.motors.hex.C887.SPI('X', 0);
    STL.motors.hex.C887.SPI('Y', 0);
    STL.motors.hex.C887.SPI('Z', STL.motors.hex.pivot_z_um / 1e3);

end
