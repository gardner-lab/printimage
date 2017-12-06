% Called when the user presses "PRINT". Various things need to happen, some
% of them before the scan is initiated and some right before the print
% waveform goes out. This function handles the former, and instructs
% WaveformManager to call printimage_modify_beam() to do the latter.
function [success] = print_Callback(hObject, eventdata, handles)
    global STL;
    
    global wbar;
    
    success = false;
    
    hSI = evalin('base', 'hSI');
        
    if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    % Save home positions. They won't be restored so as not to crush the
    % printed object, but they should be reset later.
    
    %foo = hSI.hFastZ.positionTarget;
    %hSI.hFastZ.positionTarget = 0;
    %pause(0.1);
    %hSI.hMotors.zprvResetHome();
    %hSI.hBeams.zprvResetHome();
    %hSI.hFastZ.positionTarget = foo;
    hexapos = hexapod_get_position_um();
    if any(abs(hexapos(1:3)) > 1)
        set(handles.messages, 'String', ...
            sprintf('Hexapod position is [%s ], not [ 0 0 0 ]. Please fix that first', ...
            sprintf(' %g', hexapos(1:3))));
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.rescale_needed
        rescale_object(handles);
    end
    
    UpdateBounds_Callback([], [], handles);
        
    if ~STL.logistics.simulated & isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        update_dimensions(handles); % In case the boundaries are newly available
    end
    
    hSI.hDisplay.roiDisplayEdgeAlpha = 0.1;
    
    % Make sure we haven't changed the desired resolution or anything else that
    % ScanImage can change without telling us. This should be a separate
    % function eventually!
    
    
    resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        round(STL.print.size(3) / STL.print.zstep)];
    if ~isfield(STL.print, 'resolution') | any(resolution ~= STL.print.resolution)
        STL.print.voxelise_needed = true;
    end
    
    
    if STL.print.voxelise_needed
        voxelise(handles, 'print');
        if STL.logistics.abort
            STL.logistics.abort = false;
            return;
        end
    end
    
    
    % This relies on voxelise() being called, above
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.numSlices = round(STL.print.size(3) / STL.print.zstep);
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    hSI.hFastZ.flybackTime = 0.025; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false;
    %hSI.hStackManager.stackZStartPos = 0;
    %hSI.hStackManager.stackZEndPos = NaN;
    tic
    STL.print.armed = true;
    
    % The main printing loop. How to manage the non-blocking call to
    % startLoop()?
    
    motorHold(handles, 'on');
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    start_time = datetime('now');
    eta = 'next weekend';
    
    eval(sprintf('motor = STL.motors.%s;', STL.motors.stitching));

    metavoxel_counter = 0;
    metavoxel_total = prod(STL.print.nmetavoxels);
    for mvz = 1:STL.print.nmetavoxels(3)
        for mvy = 1:STL.print.nmetavoxels(2)
            for mvx = 1:STL.print.nmetavoxels(1)
                
                if STL.logistics.abort
                    % The caller has to unset STL.logistics.abort
                    % (and presumably return).
                    disp('Aborting due to user.');
                    motorHold(handles, 'resetXY');
                    
                    if ishandle(wbar) & isvalid(wbar)
                        STL.logistics.wbar_pos = get(wbar, 'Position');
                        delete(wbar);
                    end
                    if exist('handles', 'var');
                        set(handles.messages, 'String', 'Canceled.');
                        drawnow;
                    end
                    STL.logistics.abort = false;
                    
                    STL.print.armed = false;
                    hSI.hStackManager.numSlices = 1;
                    hSI.hFastZ.enable = false;
                    
                    if ~STL.logistics.simulated
                        while ~strcmpi(hSI.acqState,'idle')
                            pause(0.1);
                        end
                    end
                    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
                    
                    return;
                end
                
                disp(sprintf('Starting on metavoxel [ %d %d %d ]...', mvx, mvy, mvz));
                
                % 0. Update the slice preview, because why the hell not?
                set(handles.show_metavoxel_slice, 'String', sprintf('%d %d %d', mvx, mvy, mvz));
                show_metavoxel_slice_Callback(hObject, eventdata, handles)
                
                % 1. Servo the slow stage to the correct starting position. This is convoluted
                % because (1) startPos may be 1x3 or 1x4, (2) we always want to approach from the
                % same side
                
                if STL.print.metavoxel_resolution{mvx, mvy, mvz}(3) == 0
                    disp(sprintf(' ...which is empty. Moving on...'));
                    continue;
                end
                
                % How many mvs are we away from the origin? Always positive.
                this_metavoxel_relative_origin = [ mvx mvy mvz] - 1;
                
                % Convert newpos from metavoxels to microns
                newpos = STL.print.metavoxel_shift .* this_metavoxel_relative_origin;
                
                % Some of the axes may want the opposite sign. This should be done in Machine_Data_File but I don't see how; see
                % below.
                newpos = newpos .* motor.axis_signs;
                
                % My axes and the motor's may be at odds, so reshuffle the order. This should be done in Machine_Data_File but I
                % don't see how; the docs are a little obsolete (or ahead of the free version?).
                newpos = newpos(motor.axis_order);
                
                % Add the motor origin from the start of this function
                newpos = newpos + motor.tmp_origin(1:3);
                
                move(STL.motors.stitching, newpos, 1);
                hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
                pause(0.1);
                
                % 2. Set up printimage_modify_beam with the appropriate
                % voxels and their power
                
                STL.print.mvx_now = mvx;
                STL.print.mvy_now = mvy;
                STL.print.mvz_now = mvz;
                
                %STL.print.voxels = STL.print.metavoxels{mvx, mvy, mvz};
                %STL.print.voxelpower = STL.print.metapower{mvx, mvy, mvz};
                
                % 3. Set resolution appropriately
                hSI.hStackManager.numSlices = STL.print.metavoxel_resolution{mvx, mvy, mvz}(3);
                
                % 4. Do whatever is necessary to get a blocking
                % startLoop(), like setting up a callback in acqModeDone?
                
                % 5. Print this metavoxel
                if ~STL.logistics.simulated
                    evalin('base', 'hSI.startLoop()');
                    
                    % 4a. Await callback from the user function "acqModeDone" or "acqAbort"? Or
                    % constantly poll... :(
                    while ~strcmpi(hSI.acqState,'idle')
                        pause(0.1);
                    end
                end
                
                % Show progress
                metavoxel_counter = metavoxel_counter + 1;
                if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                    current_time = datetime('now');
                    eta_date = start_time + (current_time - start_time) / (metavoxel_counter / metavoxel_total);
                    if strcmp(datestr(eta_date, 'yyyymmdd'), datestr(current_time, 'yyyymmdd'))
                        eta = datestr(eta_date, 'HH:MM:SS');
                    else
                        eta = datestr(eta_date, 'dddd HH:MM');
                    end
                    
                    waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Printing. Done around %s.', eta));
                end
            end
        end
    end
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
    STL.print.armed = false;
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    
    % Reset just the XY plane to the starting point (NOT Z!)
    motorHold(handles, 'resetXY');
    
    if ~STL.logistics.simulated
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
    end
    toc;
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    if get(handles.focusWhenDone, 'Value')
        hSI.startFocus();
    end
    
    success = true;
end


