function [pos] = stitching_get_position_um();
    global STL;
    hSI = evalin('base', 'hSI');
    
    if strcmp(STL.motors.stitching, 'mom')
        pos = hSI.hMotors.motorPosition;
    elseif strcmp(STL.motors.stitching, 'hex')
        pos = hexapod_get_position_um();
    else
        pos = NaN * [0 0 0 0 0 0];
    end
end
