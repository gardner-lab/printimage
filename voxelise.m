function [] = voxelise(handles, target)
    
    global STL;
    hSI = evalin('base', 'hSI');
    
    if exist('handles', 'var');
        set(handles.messages, 'String', 'Re-voxelising...');
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
    
    if STL.print.re_scale_needed
        warning('Rescaling...');
        rescale_object();
    end
    
    
    if strcmp(target, 'print')
        if exist('hSI', 'var') & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))
            
            
            % When we create the scan, we must add 0 to the right edge of the
            % scan pattern, so that the flyback is blanked.
            
            % 1. Compute metavoxels
            nmetavoxels = ceil(STL.print.size ./ STL.print.bounds);
            
            
            % 2. Set zoom to maximise fill of those metavoxels along one of X
            % or Y
            foo = nmetavoxels(1:2) ./ (STL.print.size(1:2) ./ STL.print.bounds(1:2));
            % FIXME not doing anything with this yet
            
            % 3. Set appropriate zoom level automatically? Nah, let's leave this manual for now.
            %STL.print.best_zoom = STL.print.min_zoom;
            %hSI.hRoiManager.scanZoomFactor = STL.print.best_zoom;
            %fov = hSI.hRoiManager.imagingFovUm;
            %STL.print.best_bounds([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
            
            
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
            xc = xc * STL.print.best_bounds(1);
            
            % Y (galvo) centres.
            yc = linspace(0, STL.print.best_bounds(2), hSI.hRoiManager.linesPerFrame);
            
            % Z centres aren't defined by zoom, but by zstep.
            zc = 0 : STL.print.zstep : min(STL.print.best_bounds(3), STL.print.size(3));
            
            
            % 5. Feed each metavoxel's centres to voxelise
            
            STL.print.nmetavoxels = nmetavoxels;
            
            for mvx = 1:nmetavoxels(1)
                for mvy = 1:nmetavoxels(2)
                    for mvz = 1:nmetavoxels(3)
                        STL.print.metavoxels{mvx, mvy, mvz} = VOXELISE(xc + (mvx - 1) * STL.print.metavoxel_shift(1), ...
                            yc + (mvy - 1) * STL.print.metavoxel_shift(2), ...
                            zc + (mvz - 1) * STL.print.metavoxel_shift(3), ...
                            STL.print.mesh);
                    end
                end
            end
            
            STL.print.voxelise_needed = false;
            STL.preview.voxelise_needed = false;
            STL.print.valid = true;
            
            if exist('handles', 'var')
                set(handles.messages, 'String', '');
                draw_slice(handles, 1);
                drawnow;
            end
            
        else
            if exist('handles', 'var')
                set(handles.messages, 'String', 'Could not voxelise for printing: run an acquire first.');
            else
                warning('Could not voxelise for printing: run an acquire first.');
            end
        end
    elseif strcmp(target, 'preview')
        STL.preview.resolution = [100 100 round(STL.print.size(3) / STL.print.zstep)];
        STL.preview.voxelpos.x = linspace(0, STL.print.size(1), STL.preview.resolution(1));
        STL.preview.voxelpos.y = linspace(0, STL.print.size(2), STL.preview.resolution(2));
        STL.preview.voxelpos.z = 0 : STL.print.zstep : STL.print.size(3);
        
        STL.preview.voxels = VOXELISE(STL.preview.voxelpos.x, ...
            STL.preview.voxelpos.y, ...
            STL.preview.voxelpos.z, ...
            STL.print.mesh);
        
        STL.print.voxelise_needed = true;
        STL.preview.voxelise_needed = false;
    end
        
    % Discard empty slices. This will hopefully be only the final slice, or
    % none. This might be nice for eliminating that last useless slice, but we
    % can't do that from printimage_modify_beam since the print is already
    % running.
    %STL.print.voxels = STL.print.voxels(:, :, find(sum(sum(STL.print.voxels, 1), 2) ~= 0));
    %STL.print.resolution(3) = size(STL.print.voxels, 3);
    
end

    
