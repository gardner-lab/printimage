function connect_PI_hexapod()
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
    
    
    if~isfield(STL, 'motors') | ~isfield(STL.motors, 'Controller')
        STL.motors.Controller = PI_GCS_Controller();
    end;
    
    if(~isa(STL.motors.Controller,'PI_GCS_Controller'))
        STL.motors.Controller = PI_GCS_Controller();
    end
    
    
    %% Connecting to the C887
    
    devicesTcpIp = STL.motors.Controller.EnumerateTCPIPDevicesAsArray();
    disp([num2str(length(devicesTcpIp)), ' PI controllers were found on the network']);
    disp(devicesTcpIp);
    
    
    % Parameters
    % You MUST EDIT AND ACITVATE the parameters to make your system run properly:
    % 1. Activate the connection type
    % 2. Set the connection settings
    
    % Connection settings
    STL.motors.use_RS232_Connection    = false;
    STL.motors.use_TCPIP_Connection    = false;
    
    
    if (STL.motors.use_RS232_Connection)
        STL.motors.comPort = 1;          % Look at the device manager to get the rigth COM port.
        STL.motors.baudRate = 115200;    % Look at the manual to get the right baud rate for your controller.
    end
    
    if (STL.motors.use_TCPIP_Connection)
        STL.motors.ip = 'xxx.xxx.xxx.xxx';  % Use "devicesTcpIp = Controller.EnumerateTCPIPDevices('')" to get all PI controller available on the network.
        STL.motors.port = 50000;           % Is 50000 for almost all PI controllers
    end
    
    
    % Open connection
    STL.motors.boolC887connected = false;
    
    if (exist('C887','var'))
        if (C887.IsConnected)
            STL.motors.boolC887connected = true;
        end
    end
    
    
    if (~STL.motors.boolC887connected)
        if (STL.motors.use_RS232_Connection)
            STL.motors.C887 = STL.motors.Controller.ConnectRS232(STL.motors.comPort, STL.motors.baudRate);
        end
        
        if (STL.motors.use_TCPIP_Connection)
            STL.motors.C887 = STL.motors.Controller.ConnectTCPIP(ip, port);
        end
    end
    
    %% Configuration and referencing
    
    % Query controller identification
    STL.motors.C887.qIDN()
    
    % Query controller axes
    availableaxes = STL.motors.C887.qSAI_ALLasArray();
    if(isempty(availableaxes))
        error('No axes available');
    end
    axisname = availableaxes{1};
    
    
    % Reference stage
    STL.motors.C887.FRF(axisname);
    bReferencing = 1;
    % Wait for referencing to finish
    while(0 ~= STL.motors.C887.qFRF(axisname)==0)
        pause(0.1);
    end
    
    
    %% Basic controller functions
    STL.motors.dAxisMin = STL.motors.C887.qTMN(axisname);
    STL.motors.dAxisMax = STL.motors.C887.qTMX(axisname);
    
    STL.motors.start_pos = STL.motors.C887.POS?(axisname)
end

function nothing
    position = rand(1)*(STL.motors.dAxisMax-STL.motors.dAxisMin)+STL.motors.dAxisMin;
    STL.motors.C887.MOV(axisname, position);
    % Wait for motion to stop
    while(C887.IsMoving(axisname))
        pause(0.1);
    end
    
    C887.qPOS(axisname)
    
    %% Using the datarecorder
    
    C887.DRT(0,1,'0');
    C887.DRC(1,axisname,1);
    C887.MVR(axisname, -1);
    
    while(C887.IsMoving(axisname))
        pause(0.1);
    end
    
    %Read first 100 values from controller and plot
    data = C887.qDRR(1,1,100);
    plot(data(:,1),data(:,2));
    
    grid on;
    legend('Target Position', ...
        'location', 'northeastoutside');
    
    %% Disconnecting the C887
    
    C887.CloseConnection;
    
    
    %% Unloading the PI_MATLAB_Driver_GCS2
    
    Controller.Destroy;
    clear Controller;
    clear C887;
end