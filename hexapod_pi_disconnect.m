function hexapod_pi_disconnect()
    global STL;
    
    STL.motors.hex.C887.CloseConnection;
    STL.motors.hex.Controller.Destroy;
    STL.motors.hex = rmfield(STL.motors.hex, {'Controller', 'C887'});
end
