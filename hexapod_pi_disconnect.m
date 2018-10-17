function hexapod_pi_disconnect()
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end

    try
        STL.motors.hex.C887.CloseConnection;
    catch ME
        ME
    end
    
    try
        STL.motors.hex.Controller.Destroy;
    catch ME
        ME
    end
    
    %try
        %STL.motors.hex = rmfield(STL.motors.hex, {'Controller', 'C887'});
    %end
    STL.motors.hex.connected = false;

end
