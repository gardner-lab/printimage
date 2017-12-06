% Set STL.print.bounds, either from the callback or from anywhere else.
function UpdateBounds_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if STL.logistics.simulated
        STL.bounds_1(1:2) = [666 666];
        STL.print.bounds_max(1:2) = STL.bounds_1(1:2) / STL.print.zoom_min;
        STL.print.bounds(1:2) = STL.bounds_1(1:2) / STL.print.zoom;
        update_gui(handles);
    elseif isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
        
        % Get bounds at zoom = 1
        hSI.hRoiManager.scanZoomFactor = 1;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.bounds_1([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        % Get bounds at min zoom
        hSI.hRoiManager.scanZoomFactor = STL.print.zoom_min;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.print.bounds_max([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        % Now, how about the user-selected print zoom?
        hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.print.bounds([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        
        hSI.hRoiManager.scanZoomFactor = userZoomFactor;
        update_gui(handles);
    end
end

