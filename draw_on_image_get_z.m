% When drawing on top of ScanImage's image window, the Z positions of the
% points seem, um, up in the air. Here's a way to compute something that
% seems to work...
function z = draw_on_image_get_z(CurrentAxes)
    hSI = evalin('base', 'hSI');
    
    z = get(CurrentAxes, 'ZLim');
    if str2double(hSI.VERSION_MAJOR) <= 5.3 & ~str2double(hSI.VERSION_MINOR) > 0
        z = z(2) - 0.0001; % ScanImage < 5.3.1 wanted the z info drawn here.
    else
        z = mean(z); % This _MIGHT_ work with versions < 5.3.1 as well. Can't test due to NIDAQ firmware upgrade...
    end
end
