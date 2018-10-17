function pos = hexapod_get_position_frac()
    global STL;
    
    if ~STL.motors.hex.connected
        pos = NaN * [ 0 0 0 0 0 0 ];
        return;
    end
    
    pos = hexapod_get_position_um ./ STL.motors.hex.range(:, 2)';
end
