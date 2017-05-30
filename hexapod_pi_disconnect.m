function hexapod_pi_disconnect()
    global STL;
    
    try
        STL.motors.hex.C887.CloseConnection;
    end
    try
        STL.motors.hex.Controller.Destroy;
    end
    
    STL.motors.hex = rmfield(STL.motors.hex, {'Controller', 'C887'});
end
