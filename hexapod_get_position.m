function pos = hexapod_get_position()
    global STL;
    
    if STL.logistics.simulated
        pos = STL.logistics.simulated_pos;
        return;
    end
    
    pos = STL.motors.hex.C887.qPOS('x y z u v w') ./ STL.motors.hex.range(:, 2);
end
