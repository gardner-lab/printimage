function [] = calibrate_vignetting_slide(hObject, ~)
    global STL;

    hSI = evalin('base', 'hSI');
    
    handles = guihandles(hObject);
            
    if ~STL.logistics.simulated && ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    
    %% Print the test object
    height = 50;
    sz = 400;  % STL.bounds_1(1) / STL.print.zoom_best;
    safety_margin = 10;
    % FIXME also set zoom=?
    
    %Load test object STL (hardcoded...) and setup the params and GUI as appropriate
    updateSTLfile(handles, 'C:\Users\Gardner Lab\Desktop\printimage-old-ben\STL files\cube.stl');
    set(handles.lockAspectRatio, 'Value', 0);
    if any(STL.print.size ~= [sz sz height])
        set(handles.size1, 'String', sprintf('%d', sz));
        set(handles.size2, 'String', sprintf('%d', sz));
        set(handles.size3, 'String', sprintf('%d', height));
        STL.print.rescale_needed = true;
        update_dimensions(handles);
    end
    update_gui(handles);
    
    %Command to print the test object
    success = print_Callback(hObject, [], handles);
    
    %Sanity checking
    if ~success
        warning('Failed to print. Please fix something.');
        return;
    end
    
    %% Set up the calibration routine
    %Set the piezo position for calibration
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos - (height - 2);
    
    desc = sprintf('%s_%s', get(handles.slide_filename, 'String'), get(handles.slide_filename_series, 'String'));
    
    %Calibration parameters
    poly_order = 4;             %for the fit
    n_sweeps = 17;              %number of sweeps
    how_much_to_include = 10;   % How many microns +- perpendicular to the direction of sliding
    FOV = 666;                  % microns (why is this hardcoded?)
    scanspeed_mms = 0.3;        % mm/s of the sliding stage
    frame_rate = 15.21;         % Hz
    frame_spacing_um = scanspeed_mms * 1000 / frame_rate;
    
    %Turn of piezo (?)
    hSI.hFastZ.enable = 0;
    
    %z-slices to acquire
    hSI.hStackManager.numSlices = 1;
    
    %Imaging params to save
    xc = STL.print.voxelpos_wrt_fov{1,1,1}.x;
    yc = STL.print.voxelpos_wrt_fov{1,1,1}.y;
    p = STL.print.voxelpower_adjustment;
    save(sprintf('slide_%s_adj', desc), 'xc', 'yc', 'p');

    %Process bar for calibration
    if exist('wbar', 'var') && ishandle(wbar) && isvalid(wbar)
        waitbar(0, wbar, 'Measuring polymerisation...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Measuring polymerisation...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end

    % First: take a (multi-frame) averaged snapshot of the printed object
    set(handles.messages, 'String', 'Taking snapshot of current view...');
    
    hSI.hStackManager.framesPerSlice = 100;
    hSI.hScan2D.logAverageFactor = 100;
    hSI.hChannels.loggingEnable = true;
    hSI.hScan2D.logFramesPerFileLock = true;
    hSI.hScan2D.logFileStem = sprintf('slide_%s_image', desc);
    hSI.hScan2D.logFileCounter = 1;
    hSI.hRoiManager.scanZoomFactor = 1;
    
    %If this isn't all fake, go ahead and take the snapshot
    if ~STL.logistics.simulated
        hSI.startGrab();
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
    end
    
    %Reset to the usual imaging parameters
    hSI.hScan2D.logAverageFactor = 1;
    hSI.hStackManager.framesPerSlice = 1;
    hSI.hChannels.loggingEnable = false;
    
    %This is actually real and references the baseline file that is taken
    %in the calibration menu... 
    if exist('vignetting_cal.tif', 'file')
        tiffCal = double(imread('vignetting_cal.tif'));
    else
        warning('No baseline calibration file ''vignetting_cal.tif'' found.');
        tiffCal = ones(512, 512);
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
    
    sweep_halfsize = sz/2 + 100; % x halfsize
    sweep_pos = linspace(-(sz/2 - safety_margin - how_much_to_include), (sz/2 - safety_margin - how_much_to_include), n_sweeps); % y positions

    % Get the current hexapod position (x,y,z,u,v,w)
    pos = hexapod_get_position_um();

    %% Measure brightness along X axis by sliding the printed object
    
    %Collection arrays
    x = [];
    y = [];
    z = [];

    %Loop controls the sliding, image acquisition, and brightness
    %extraction
    for sweep = 1:n_sweeps
        
        %This executes on abort, but I don't think this works... shit gets
        %cray if you try to exit before done
        if STL.logistics.abort
            % The caller has to unset STL.logistics.abort
            % (and presumably return).
            disp('Aborting due to user.');
            if ishandle(wbar) && isvalid(wbar)
                STL.logistics.wbar_pos = get(wbar, 'Position');
                delete(wbar);
            end
            if exist('handles', 'var');
                set(handles.messages, 'String', 'Canceled.');
                drawnow;
            end
            STL.logistics.abort = false;
            
            STL.print.armed = false;
            move('hex', [ 0 0 0 ], 20);
            hSI.hStackManager.numSlices = 1;
            hSI.hFastZ.enable = false;
            hSI.hBeams.enablePowerBox = false;
            hSI.hRoiManager.scanZoomFactor = 1;
            if ~STL.logistics.simulated
                while ~strcmpi(hSI.acqState,'idle')
                    pause(0.1);
                end
            end
            
            break;
        end

        %Move hexapod to start of row
        move('hex', pos(1:2) + [-sweep_halfsize sweep_pos(sweep)], 20);
        
        %Update text messages
        set(handles.messages, 'String', sprintf('Sliding along current view (%d/%d)...', sweep, n_sweeps));
        
        % Time taken for the scan will be sweep_halfsize / 100 um/s; frame rate is
        % 15.21 Hz (can't figure out where that is in hSI, but somewhere...)
        scantime = 2*sweep_halfsize / (scanspeed_mms * 1000);
        scanframes = ceil(scantime * frame_rate);
        
        %scanimage interlocks and settings
        hSI.hStackManager.framesPerSlice = scanframes;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logAverageFactor = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        hSI.hScan2D.logFileStem = sprintf('sliding', desc);
        hSI.hScan2D.logFileCounter = 1;
        
        %If its not fake, start the image acq
        if ~STL.logistics.simulated
            hSI.startGrab();
        end
        
        %Move hexapod to next position
        move('hex', pos(1:2) + [sweep_halfsize sweep_pos(sweep)], scanspeed_mms);
       
        %debounce
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
        
        % Load the just saved tiff files and process them 
        tiffX = [];
        i = 0;
        try
            while true
                i = i + 1;
                if i == 2
                    tiffX(1000,1,1) = 0;
                end
                %Temporary image location for the current slide
                t = imread(sprintf('sliding_00001_00001.tif'), i);
                
                %Normalize each snapshot by the 'control' vignetting image -- makes a
                %difference, but less than you would think
                tiffX(i,:,:) = double(t) ./ tiffCal; 
            end
        catch ME
        end
        
        %Trim to actual image stack size
        tiffX = tiffX(1:i-1,:,:);
        
        %Find the pixels that you actually care about -- i.e., center on X
        %and +/- a range on the Y <-- This is where the brightness
        %measurements are extracted from. These are reasonably within the
        %bounds of the printed object
        middle = round(size(tiffX, 3)/2);
        pixelposY = linspace(-FOV/2, FOV/2, size(tiffX, 2));
        indicesY = find(pixelposY > -how_much_to_include ...
            & pixelposY < how_much_to_include);
        
        % Normalise brightness to that of unpolymerized resist. Note that
        % this is ~50um beyond the right edge of the printed cube --
        % important not to calibrate too close to existant objects
        scanposX = (0:(size(tiffX, 1) - 1)) * frame_spacing_um - sweep_halfsize;
        baseline_indices = find(scanposX > sz / 2 + 20); % background outside the printed object
        baselineX = mean(mean(tiffX(baseline_indices, indicesY, middle), 2), 1); %Locations in what should be unprinted resist
        tiffX = tiffX/baselineX; %Normalize whole image by this value
        
        %Extracts brightness at each of the relevant points for this
        %row-slide
        bright_x = mean(tiffX(:, indicesY, middle), 2);
        i = find(scanposX > -(sz/2 - safety_margin) & scanposX < (sz/2 - safety_margin));
        x = [x scanposX(i)'];
        y = [y ones(size(i))'*-sweep_pos(sweep)]; % When hexapod (understage) is at y, we're looking at object at -y
        z = [z bright_x(i)];
        
        if exist('wbar', 'var') && ishandle(wbar) && isvalid(wbar)
            waitbar(((sweep+1) / (n_sweeps+1)), wbar, sprintf('Pass %d of %d...', sweep, n_sweeps));
        end

    end
    
    %%
    %Now that all the sweeps and extractions are done, delete waitbar
    if exist('wbar', 'var') && ishandle(wbar) && isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
    %Reset image acq to snapshot
    hSI.hStackManager.framesPerSlice = 1;
    hSI.hChannels.loggingEnable = false;
    
    %No idea what this move is for... deletable?
    move('hex', pos(1:2), 5);    

    set(handles.messages, 'String', 'Processing fit...');
    
    %Take position and brightness measures and format for surface-fitting
    [xData, yData, zData] = prepareSurfaceData( x, y, z );
    
    %Fit surface to data
    ft = fittype(sprintf('poly%d%d', poly_order, poly_order )); %surface model poly44 (quad in x and y)
    [fitresult, gof] = fit( [xData, yData], zData, ft );
    
    %Copy the fitted surface to permenant structure
    if ~isfield(STL.calibration, 'vignetting_fit')
        STL.calibration.vignetting_fit = {};
    end
    STL.calibration.vignetting_fit{end+1} = fitresult;
    
    %save the fit info for later inspection
    save(sprintf('slide_%s_fit', desc), 'fitresult', 'x', 'y', 'z', 'xData', 'yData', 'zData');
    
    % Show how many calibration functions there are
    disp(sprintf('~ You now have %d vignetting compensators.', length(STL.calibration.vignetting_fit)));
    
    % Plot fit with data.
    if true
        figure(41);
        h = plot( fitresult, [xData, yData], zData );
        legend( h, 'untitled fit 1', 'z vs. x, y', 'Location', 'NorthEast' );
        % Label axes
        xlabel x
        ylabel y
        zlabel z
        grid on
        view( -32.7, 15.6 );
    end
    set(handles.messages, 'String', '');
    
    %Save a backup version of the fit to load later if desired
    vigfit = STL.calibration.vignetting_fit;
    save('printimage_last_vignetting_fit', 'vigfit');
    
    %Return the hexapod and piezo scanner to 0-position
    move('hex', [0 0 0]);
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end