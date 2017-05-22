function disconnect_PI_hexapod()
    global STL;
    
    STL.motors.C887.CloseConnection;
    STL.motors.Controller.Destroy;
    STL.motors = rmfield(STL.motors, {'Controller', 'C887'});
end
