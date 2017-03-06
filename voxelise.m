function [] = voxelise(handles, target)

    global STL;
    hSI = evalin('base', 'hSI');    
    warning('Voxelising again...');
    
    global wbar;

    if exist('handles', 'var');
        set(handles.messages, 'String', sprintf('Re-voxelising %s...', target));
        drawnow;
    end
    
    % For motorstage printing: INTERFACE: set (1) max cube, (2) object size.
    % How many metavoxels are required? Set zoom to maximise fill given
    % the size. FIXME what about X and Y and Z having different fills?
    % Maybe add different zoom scaling for X and Y... later. For now,
    % choose to optimise X, because that's where we need it the most.
    
    % Max cube implies a min zoom level Zmin to eliminate vignetting.
    % If even, (1) zoom to best level >= Zmin and compute voxelisation centres
    % for all points in STL. Then cut a cube out of that and send it to be
    % printed, move stage, etc, iterating over [X Y Z].
    
    % UI variables: (1) Min safe zoom level to eliminate vignetting
    
    % Need to place voxels according to "actual" position given zoom level,
    % rather than normalising everything and zooming, because the latter
    % quantises.
    
    if strcmp(target, 'print')
        if exist('hSI', 'var') & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))
            if ~STL.print.voxelise_needed
                set(handles.messages, 'String', '');
                return;
            end
            % When we create the scan, we must add 0 to the right edge of the
            % scan pattern, so that the flyback is blanked. Or is this
            % automatic?
                        
            % 1. Compute metavoxels based on user-selected print zoom:
            nmetavoxels = ceil(STL.print.size ./ (STL.print.bounds - STL.print.metavoxel_overlap));
            
            % 2. Set zoom to maximise fill of those metavoxels along one of X
            % or Y
            % FIXME not doing anything with this yet
            
            % 3. Set appropriate zoom level: if object bounds < STL.print.zoom,
            % then zoom in. Otherwise, just use STL.print.zoom.
            zoom_best = floor(min(nmetavoxels(1:2) ./ (STL.print.size(1:2) ./ (STL.bounds_1(1:2)))) * 10)/10;
            if all(nmetavoxels(1:2) == 1) & zoom_best >= STL.print.zoom_min
                disp(sprintf('Changing print zoom to %g.', zoom_best));
                STL.print.zoom_best = zoom_best;
            else
                STL.print.zoom_best = STL.print.zoom;
            end
                
            hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
            fov = hSI.hRoiManager.imagingFovUm;
            STL.print.bounds_best = STL.print.bounds;
            STL.print.bounds_best([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
            
            STL.print.metavoxel_shift = STL.print.bounds_best - STL.print.metavoxel_overlap;
            % 4. Get voxel centres for metavoxel 0,0,0
            
            STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
                hSI.hRoiManager.linesPerFrame ...
                round(STL.print.size(3) / STL.print.zstep)];
            
            % X (resonant scanner) centres. Correct for sinusoidal velocity. This computes the locations of
            % pixel centres given an origin at 0.
            xc = linspace(-1, 1, STL.print.resolution(1)); % On [-1 1] for asin()
            xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
            xc = sin(xc);
            xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
            xc = (xc + 1) / 2;  % Now on [0 1].
            xc = xc * STL.print.bounds_best(1);
            
            % Y (galvo) centres.
            yc = linspace(0, STL.print.bounds_best(2), hSI.hRoiManager.linesPerFrame);
            
            % Z centres aren't defined by zoom, but by zstep.
            zc = STL.print.zstep : STL.print.zstep : min(STL.print.bounds_best(3), STL.print.size(3));
            
            
            % 5. Feed each metavoxel's centres to voxelise
            
            STL.print.nmetavoxels = nmetavoxels;
            
            start_time = datetime('now');
            eta = 'next weekend';

            if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                waitbar(0, wbar, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
            else
                wbar = waitbar(0, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
            end
            metavoxel_counter = 0;
            metavoxel_total = prod(STL.print.nmetavoxels);
            STL.print.voxelpos = {};
            STL.print.metavoxel_resolution = {};
            STL.print.metavoxels = {};
            STL.logistics.abort = false;

            for mvx = 1:nmetavoxels(1)
                for mvy = 1:nmetavoxels(2)
                    for mvz = 1:nmetavoxels(3)
                        
                        if STL.logistics.abort
                            % The caller has to unset STL.logistics.abort
                            % (and presumably return).
                            disp('Aborting due to user.');
                            if ishandle(wbar) & isvalid(wbar)
                                delete(wbar);
                            end
                            if exist('handles', 'var');
                                set(handles.messages, 'String', '');
                                drawnow;
                            end

                            return;
                        end
                        
                        % Voxels for each metavoxel:
                        STL.print.voxelpos{mvx, mvy, mvz}.x = xc + (mvx - 1) * STL.print.metavoxel_shift(1);
                        STL.print.voxelpos{mvx, mvy, mvz}.y = yc + (mvy - 1) * STL.print.metavoxel_shift(2);
                        STL.print.voxelpos{mvx, mvy, mvz}.z = zc + (mvz - 1) * STL.print.metavoxel_shift(3);

                        STL.print.metavoxels{mvx, mvy, mvz} = VOXELISE(...
                            STL.print.voxelpos{mvx, mvy, mvz}.x, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.y, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.z, ...
                            STL.print.mesh);
                        
                        % Delete empty zstack slices if they are above
                        % something that is printed:
                        foo = sum(sum(STL.print.metavoxels{mvx, mvy, mvz}, 1), 2);
                        cow = find(foo, 1, 'last');
                        %warning('Keeping zstack positions from 1-%d.', cow);
                        STL.print.metavoxels{mvx, mvy, mvz} ...
                            = STL.print.metavoxels{mvx, mvy, mvz}(:, :, 1:cow);
                        
                        % Printing happens at this resolution--we need to set up zstack height etc so printimage_modify_beam()
                        % produces a beam control vector of the right length.
                        STL.print.metavoxel_resolution{mvx, mvy, mvz} = size(STL.print.metavoxels{mvx, mvy, mvz});
                        
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
                            
                            waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Voxelising. Done around %s.', eta));
                        end                        
                    end
                end
            end
            
            if STL.logistics.abort
                STL.logistics.abort = false;
            else
                STL.print.voxelise_needed = false;
                STL.print.valid = true;
            end
            
            if exist('handles', 'var')
                set(handles.messages, 'String', '');
                draw_slice(handles, 1);
                drawnow;
            end
            
            if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                delete(wbar);
            end

            
        else
            if exist('handles', 'var')
                set(handles.messages, 'String', 'Could not voxelise for printing: run an acquire first.');
            else
                warning('Could not voxelise for printing: run an acquire first.');
            end
        end
    elseif strcmp(target, 'preview')
        if ~STL.preview.voxelise_needed
            set(handles.messages, 'String', '');
            return;
        end

        STL.preview.resolution = [120 120 round(STL.print.size(3) / STL.print.zstep)];
        STL.preview.voxelpos.x = linspace(0, STL.print.size(1), STL.preview.resolution(1));
        STL.preview.voxelpos.y = linspace(0, STL.print.size(2), STL.preview.resolution(2));
        STL.preview.voxelpos.z = 0 : STL.print.zstep : STL.print.size(3);
        
        STL.preview.voxels = VOXELISE(STL.preview.voxelpos.x, ...
            STL.preview.voxelpos.y, ...
            STL.preview.voxelpos.z, ...
            STL.print.mesh);
        
        STL.preview.voxelise_needed = false;
        
        % Discard empty slices. This will hopefully be only the final slice, or
        % none. This might be nice for eliminating that last useless slice, but we
        % can't do that from printimage_modify_beam since the print is already
        % running.
        STL.preview.voxels = STL.preview.voxels(:, :, find(sum(sum(STL.preview.voxels, 1), 2) ~= 0));
        STL.preview.resolution(3) = size(STL.preview.voxels, 3);
    end
    
    if exist('handles', 'var');
        set(handles.messages, 'String', '');
        drawnow;
    end

end

    
