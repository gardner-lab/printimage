function pos = hexapod_get_position_frac()
    global STL;
    pos = hexapod_get_position_um ./ STL.motors.hex.range(:, 2)';
end
