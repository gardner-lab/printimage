function measure_brightness_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    %Check if the system is in a state to take that action.
    if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
        return;
    else
        set(handles.messages, 'String', '');
    end
        
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos - str2double(get(handles.brightness_height, 'String'));

    desc = sprintf('%s_%s', get(handles.slide_filename, 'String'), get(handles.slide_filename_series, 'String'));
    
    
    hSI.hFastZ.enable = 0;
    hSI.hStackManager.numSlices = 1;
    
    xc = STL.print.voxelpos_wrt_fov{1,1,1}.x;
    yc = STL.print.voxelpos_wrt_fov{1,1,1}.y;
    p = STL.print.voxelpower_adjustment;
    save(sprintf('slide_%s_adj', desc), 'xc', 'yc', 'p');

    if false
        %% First: take a snapshot. But this has to be aimed into empty IP-Dip, so requires user intervention
        set(handles.messages, 'String', 'Taking snapshot of current view...');
        
        hSI.hStackManager.framesPerSlice = 100;
        hSI.hScan2D.logAverageFactor = 100;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logFileStem = sprintf('slide_%s_image', desc);
        hSI.hScan2D.logFileCounter = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
            
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end
        
        hSI.hScan2D.logAverageFactor = 1;
        hSI.hStackManager.framesPerSlice = 1;
        hSI.hChannels.loggingEnable = false;
    end
    
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    if STL.motors.hex.connected
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:5), 'LEVEL')
            hexapod_wait();
            STL.motors.hex.C887.KEN('ZERO');
        end
    end

    sweep_halfsize = 400;
    % Positions for the sliding measurements:
    pos = hexapod_get_position_um();
    left = pos; left(1) = left(1) - sweep_halfsize;
    right = pos; right(1) = right(1) + sweep_halfsize;
    bottom = pos; bottom(2) = bottom(2) - sweep_halfsize;
    top = pos; top(2) = top(2) + sweep_halfsize;

    %% Measure brightness along X axis
    
    % This should be in the base leveling coordinate system
    

    move('hex', left, 1);
    set(handles.messages, 'String', 'Sliding along current view...');

    scanspeed_mms = 0.1; % mm/s of the sliding stage
    scanspeed_ums = scanspeed_mms * 1000;
    frame_rate = 15.21; % Hz

    % Time taken for the scan will be 666 um / 100 um/s; frame rate is
    % 15.21 Hz (can't figure out where that is in hSI, but somewhere...)
    scantime = 2*sweep_halfsize / scanspeed_ums;
    scanframes = ceil(scantime * frame_rate);
    hSI.hStackManager.framesPerSlice = scanframes;
    hSI.hChannels.loggingEnable = true;
    hSI.hScan2D.logFramesPerFileLock = true;
    hSI.hScan2D.logAverageFactor = 1;
    hSI.hRoiManager.scanZoomFactor = 1;
    hSI.hScan2D.logFileStem = sprintf('slide_%s_x', desc);
    hSI.hScan2D.logFileCounter = 1;

    if ~STL.logistics.simulated
        hSI.startGrab();
    end
    
    move('hex', right, scanspeed_mms);
    
    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    
    %% Measure brightness along y axis
        
    move('hex', top, 1);
    
    hSI.hScan2D.logFileStem = sprintf('slide_%s_y', desc);
    hSI.hScan2D.logFileCounter = 1;
    if ~STL.logistics.simulated
        hSI.startGrab();
    end
    
    move('hex', bottom, scanspeed_mms);

    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    move('hex', pos, 1);


    hSI.hStackManager.framesPerSlice = 1;
    hSI.hChannels.loggingEnable = false;
    
    if false
        set(handles.messages, 'String', 'Processing...');
        tiffx = [];
        i = 0;
        try
            while true
                i = i + 1;
                tiffx(i,:,:) = imread(sprintf('slide_%s_x_00001_00001.tif', desc), i);
            end
        catch ME
        end
        tiffx = double(tiffx);
        middle = round(size(tiffx, 3)/2);
        n = 100;
        if ~isempty(tiffx)
            figure(16);
            subplot(1,2,1);
            plot(mean(tiffx(:, middle-n:middle+n, middle), 2));
            title('X axis brightness');
            set(gca, 'XLim', [0 size(tiffx, 1)]);
        end
        
        tiffy = [];
        i = 0;
        try
            while true
                i = i + 1;
                tiffy(i,:,:) = imread(sprintf('slide_%s_y_00001_00001.tif', desc), i);
            end
        catch ME
        end
        tiffy = double(tiffy);
        if ~isempty(tiffy)
            subplot(1,2,2);
            plot(mean(tiffy(:, middle, middle-n:middle+n), 3));
            title('Y axis brightness');
            set(gca, 'XLim', [0 size(tiffy, 1)]);
        end
    end
    set(handles.messages, 'String', '');
        
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end

