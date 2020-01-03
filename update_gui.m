function update_gui(handles);
    global STL;
    
    if isfield(STL, 'file')
        set(gcf, 'Name', STL.file);
    else
        set(gcf, 'Name', 'PrintImage');
    end
    set(handles.build_x_axis, 'Value', STL.print.xaxis);
    set(handles.build_z_axis, 'Value', STL.print.zaxis);
    
    %Switch based on user selections
    if get(handles.check_laserpercent, 'Value')
        set(handles.printpowerpercent, 'String', sprintf('%d', round(100*STL.print.power)));
    else
        equiv = interp1(STL.calibration.perpow(1,:), STL.calibration.perpow(2,:), STL.print.power); %interpolate value from mapping curve
        set(handles.printpowerpercent, 'String', sprintf('%d', round(equiv)));
    end

    set(handles.size1, 'String', sprintf('%d', round(STL.print.size(1))));
    set(handles.size2, 'String', sprintf('%d', round(STL.print.size(2))));
    set(handles.size3, 'String', sprintf('%d', round(STL.print.size(3))));
    set(handles.fastZhomePos, 'String', sprintf('%d', round(STL.print.fastZhomePos)));
    set(handles.powertest_start, 'String', sprintf('%g', 1));
    set(handles.powertest_end, 'String', sprintf('%g', 100));
    set(handles.invert_z, 'Value', STL.print.invert_z);
    set(handles.whichBeam, 'Value', STL.print.whichBeam);
    set(handles.show_metavoxel_slice, 'String', sprintf(['%d '], STL.preview.show_metavoxel_slice));
    set(handles.z_step, 'String', num2str(STL.print.zstep,2));
    spinnerSet(handles.minGoodZoom, STL.print.zoom_min);
    spinnerSet(handles.printZoom, STL.print.zoom);
    hexapod_pos = hexapod_get_position_frac();
    set(handles.hexapod_rotate_x, 'Value', hexapod_pos(4));
    set(handles.hexapod_rotate_y, 'Value', hexapod_pos(5));
    set(handles.hexapod_rotate_z, 'Value', hexapod_pos(6));
    update_best_zoom(handles);
end

% Set the value of a spinner GUI component to the given number.
function spinnerSet(h, val, format);
    if ~exist('format', 'var')
        format = '%g';
    end
    vals = get(h, 'String');
    match = find(strcmp(vals, sprintf(format, val)));
    set(h, 'Value', match);
end

