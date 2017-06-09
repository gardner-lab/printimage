function pos = hexapod_get_position()
    global STL;
    
    if STL.logistics.simulated
        pos = STL.logistics.simulated_pos;
        return;
    end
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end
    
    pos = STL.motors.hex.C887.qPOS('x y z u v w') ./ STL.motors.hex.range(:, 2);
    pos = pos';
end
