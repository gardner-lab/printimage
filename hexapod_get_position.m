function pos = hexapod_get_position()
    global STL;
    
    if STL.logistics.simulated
        pos = STL.logistics.simulated_pos;
        return;
    end
    
    for i = 1:6
        pos(i) = STL.motors.hex.C887.qPOS(STL.motors.hex.axes(i)) / STL.motors.hex.range(i, 2);
    end
end
