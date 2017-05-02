function update_best_zoom(handles);
    global STL;
    
    nmetavoxels = ceil(STL.print.size ./ (STL.print.bounds - STL.print.metavoxel_overlap));

    if STL.logistics.simulated
        STL.print.zoom_best = 2.2;
    else
        STL.print.zoom_best = floor(min(nmetavoxels(1:2) ./ (STL.print.size(1:2) ./ (STL.bounds_1(1:2)))) * 10)/10;
    end
    
    if all(nmetavoxels(1:2) == 1) & STL.print.zoom_best >= STL.print.zoom_min
        set(handles.autozoom, 'String', sprintf('Auto: %g', STL.print.zoom_best));
    else
        STL.print.zoom_best = STL.print.zoom;
        set(handles.autozoom, 'String', '');
    end
end
