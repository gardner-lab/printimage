function rot_esp301_connect()
    global STL;
    
    try
        STL.motors.rot.esp301 = espConnect(STL.motors.rot.com_port);
        setzero(STL.motors.rot.esp301, 3);
        fopen(STL.motors.rot.esp301);
        settrajmode = strcat('3TJ2');
        fprintf(STL.motors.rot.esp301, settrajmode);
        query(STL.motors.rot.esp301, '3TJ?')
        fclose(STL.motors.rot.esp301);
        STL.motors.rot.connected = true;
    catch ME
        error('Could not connect to esp301 on com port %s. Has it changed?', STL.motors.rot.com_port);
    end
end
