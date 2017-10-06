function [] = voxelise(handles, target)

    global STL;
    hSI = evalin('base', 'hSI');    
    %warning('Voxelising again (for %s)', target);
    
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
    
    if strcmp(target, 'print') & STL.print.voxelise_needed
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
            
            update_best_zoom(handles);
            
            if STL.logistics.simulated
                user_zoom = 1;
            else
                user_zoom = hSI.hRoiManager.scanZoomFactor;
            end
            hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
            fov = hSI.hRoiManager.imagingFovUm;
            hSI.hRoiManager.scanZoomFactor = user_zoom;
            STL.print.bounds_best = STL.print.bounds;
            STL.print.bounds_best([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
            
            STL.print.metavoxel_shift = STL.print.bounds_best - STL.print.metavoxel_overlap;
            % 4. Get voxel centres for metavoxel 0,0,0
            
            STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
                hSI.hRoiManager.linesPerFrame ...
                round(STL.print.size(3) / STL.print.zstep)];
            
            % X (resonant scanner) centres. Correct for sinusoidal
            % velocity. This computes the locations of pixel centres given
            % an origin at 0.
            
            % FIXME We should really compute pixel left-edges for 0-1
            % transitions and right-edges for 1-0. Maybe in the next
            % version.
            xc = linspace(-1, 1, STL.print.resolution(1)); % On [-1 1] for asin()
            xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
            xc = sin(xc);
            temp_speed = xc;
            xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
            xc = (xc + 1) / 2;  % Now on [0 1].
            xc = xc * STL.print.bounds_best(1);
            
            % Y (galvo) centres. FIXME as above
            yc = linspace(0, STL.print.bounds_best(2), hSI.hRoiManager.linesPerFrame);
            
            % Z centres aren't defined by zoom, but by zstep.
            zc = STL.print.zstep : STL.print.zstep : min([STL.print.bounds(3) STL.print.size(3)]);
            
            
            % Compensate for lens vignetting, if we've done the fit.
            if exist('vignetting_fit.mat', 'file')
                warning('Using vignetting compensation from vignetting_fit.mat');
                load('vignetting_fit.mat');
                % Sadly, coordinates for the printed object are currently
                % on [0,1], not real FOV coords. So this is an
                % approximation for now. But it's pretty good.
                xc_c = xc - xc(end)/2;
                yc_c = yc - yc(end)/2;
                [vig_x, vig_y] = meshgrid(xc_c, yc_c);
                vignetting_falloff = vignetting_fit(vig_x, vig_y);
                vignetting_falloff = vignetting_falloff / max(max(vignetting_falloff));
            else
                vignetting_falloff = ones(STL.print.resolution(1:2));
            end
            % Transpose: xc is the first index of the matrix (row #)
            warning('Transposing vignetting_falloff. Correct?');
            vignetting_falloff = repmat(vignetting_falloff', [1, 1, size(zc, 2)]);

            % Calculate power compensation for sinusoidal speed
            speed = cos(asin(temp_speed));
            speed = repmat(speed', [1, size(yc,2), size(zc,2)]);
            %speed = cos(asin(foo)) * asin(hSI.hScan_ResScanner.fillFractionSpatial)/hSI.hScan_ResScanner.fillFractionSpatial;
            frame_power_adjustment = speed ./ vignetting_falloff;
            figure(12);
            subplot(1,2,1);
            plot(speed(:,256,10));
            hold on;
            plot(1./vignetting_falloff(:,round(size(vignetting_falloff,2)/2),10));
            hold off;
            axis tight;
            subplot(1,2,2);
            imagesc(xc_c,yc_c,squeeze(vignetting_falloff(:,:,1)));

            
            % 6. Feed each metavoxel's centres to voxelise
            
            STL.print.nmetavoxels = nmetavoxels;
            
            start_time = datetime('now');
            eta = 'next weekend';

            if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                waitbar(0, wbar, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
            else
                wbar = waitbar(0, 'Voxelising...', 'CreateCancelBtn', 'cancel_button_callback');
                set(wbar, 'Units', 'Normalized');
                wp = get(wbar, 'Position');
                wp(1:2) = STL.logistics.wbar_pos(1:2);
                set(wbar, 'Position', wp);
                drawnow;
            end
            metavoxel_counter = 0;
            metavoxel_total = prod(STL.print.nmetavoxels);
            STL.print.voxelpos = {};
            STL.print.metavoxel_resolution = {};
            STL.print.metavoxels = {};
            STL.logistics.abort = false;
            
%             parfor mvx = 1:nmetavoxels(1) % parfor threw an error --
%             can't use with an embedded return command
            for mvx = 1:nmetavoxels(1)
                for mvy = 1:nmetavoxels(2)
                    for mvz = 1:nmetavoxels(3)
                        
                        if STL.logistics.abort
                            % The caller has to unset STL.logistics.abort
                            % (and presumably return).
                            disp('Aborting due to user.');
                            if ishandle(wbar) & isvalid(wbar)
                                STL.logistics.wbar_pos = get(wbar, 'Position');
                                delete(wbar);
                            end
                            if exist('handles', 'var');
                                set(handles.messages, 'String', 'Canceled.');
                                drawnow;
                            end

                            return;
                        end
                        
                        % Voxels for each metavoxel:
                        STL.print.voxelpos{mvx, mvy, mvz}.x = xc + (mvx - 1) * STL.print.metavoxel_shift(1);
                        STL.print.voxelpos{mvx, mvy, mvz}.y = yc + (mvy - 1) * STL.print.metavoxel_shift(2);
                        STL.print.voxelpos{mvx, mvy, mvz}.z = zc + (mvz - 1) * STL.print.metavoxel_shift(3);
                        xlength = numel(STL.print.voxelpos{mvx, mvy, mvz}.x);
                        ylength = numel(STL.print.voxelpos{mvx, mvy, mvz}.y);
                        zlength = numel(STL.print.voxelpos{mvx, mvy, mvz}.z);

                        A = parVOXELISE(...
                            STL.print.voxelpos{mvx, mvy, mvz}.x, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.y, ...
                            STL.print.voxelpos{mvx, mvy, mvz}.z, ...
                            STL.print.mesh);

                       
                        parfor vx = 1:xlength
                            zvector = A(vx,:,:);
                            for vy = 1:ylength
                                for vz = 1:(zlength-5)
                                    test1 = [zvector(1,vy,vz) ~zvector(1,vy,vz+1) zvector(1,vy,vz+2) zvector(1,vy,vz+3)];
                                    %test2 = [zvector(vz) ~zvector(vz+1) ~zvector(vz+2) zvector(vz+3) zvector(vz+4) zvector(vz+5)];
                                    if all(test1)
                                        zvector(1,vy,vz+1) = 1;
                                    elseif ~any(test1)
                                        zvector(1,vy,vz+1) = 0;
%                                     elseif ~any(test2)
%                                         zvector(vz+1) = 0;
%                                         zvector(vz+2) = 0;
%                                     elseif all(test2)
%                                         zvector(vz+1) = 1;
%                                         zvector(vz+2) = 1;
                                    end
                                end
                                
                            end
                            A(vx,:,:) = zvector;
                        end
                        
                        STL.print.metavoxels{mvx, mvy, mvz} = A;
                        STL.print.metapower{mvx,mvy,mvz} = double(STL.print.metavoxels{mvx, mvy, mvz}) .* frame_power_adjustment;
                                                
                        % Delete empty zstack slices if they are above
                        % something that is printed:
                        foo = sum(sum(STL.print.metavoxels{mvx, mvy, mvz}, 1), 2);
                        cow = find(foo, 1, 'last');
                        %warning('Keeping zstack positions from 1-%d.', cow);
                        STL.print.metavoxels{mvx, mvy, mvz} ...
                            = STL.print.metavoxels{mvx, mvy, mvz}(:, :, 1:cow);
                        STL.print.voxelpos{mvx, mvy, mvz}.z = STL.print.voxelpos{mvx, mvy, mvz}.z(1:cow);
                        
                        % The voxel powers for each metavoxel are stored in
                        % metapower. During print(), the appropriate
                        % metapower becomes the new voxelpower. Yuck :(
                        STL.print.metapower{mvx, mvy, mvz} = STL.print.metapower{mvx, mvy, mvz}(:,:,1:cow);
                        
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
                STL.logistics.wbar_pos = get(wbar, 'Position');
                delete(wbar);
            end

            
        else
            if exist('handles', 'var')
                set(handles.messages, 'String', 'Could not voxelise for printing: run an acquire first.');
            else
                warning('Could not voxelise for printing: run an acquire first.');
            end
        end
    elseif strcmp(target, 'preview') & STL.preview.voxelise_needed
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
            
    % Save what we've done... just in case...
    disp('Saving voxelised file as LastVoxelised.mat');
    save('LastVoxelised_dont_remove_this_until_last_one_is_rescued', 'STL');
end

% was used instead of the parfor after parVOXELISE, keeping it as backup    
function zvector = smoothen(zvector)
    for i=2:(numel(zvector)-3)
%         test1 = [zvector(i) ~zvector(i+1) ~zvector(i+2) zvector(i+3) zvector(i+4) zvector(i+5)];
%         if ~any(test1)
%             zvector(i+1) = 0;
%             zvector(i+2) = 0;
%         end
%         if all(test1)
%             zvector(i+1) = 1;
%             zvector(i+2) = 1;
%         end
        test2 = [zvector(i) ~zvector(i+1) zvector(i+2) zvector(i+3)];
        if all(test2)
            zvector(i+1) = 1;
        elseif ~any(test2)
            zvector(i+1) = 0;
        end
    end
end
