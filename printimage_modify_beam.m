function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);
    global STL;
    
    % Vignetting compensation can be done here, since it's independent of
    % zoom and thus doesn't require re-voxelising. Sinusoidal-velocity
    % compensation is currently in voxelise(); this is awkward for testing
    % and readability, but it's okay, since any change that affects it
    % (besides tweaking parameters) depends on zoom and thus requires
    % re-voxelising anyway.
    POWER_COMPENSATION = {'speed', 'fit'};
    
    BEAM_SPEED_POWER_COMPENSATION_FACTOR = 1;
    FIT_COMPENSATION_FACTOR = 2;
    SHOW_COMPENSATION = 34;
    
    hSI = evalin('base', 'hSI');
    %hSI.hChannels.loggingEnable = false;
    
    if STL.print.voxelise_needed
        voxelise([], 'print');
    end
    
    if STL.print.voxelise_needed
        error('Tried re-voxelising, but was unsuccessful.');
    end
    
    % Pull down which metavoxel we're working on:
    mvx = STL.print.mvx_now;
    mvy = STL.print.mvy_now;
    mvz = STL.print.mvz_now;
    voxelpower = STL.print.metavoxels{mvx, mvy, mvz} * STL.print.power;
    v_i = find(voxelpower(:)); % indices into voxels to be printed

    disp(sprintf('~ Voxel power is on [%g, %g]', ...
        min(voxelpower(v_i)), ...
        max(voxelpower(v_i))));
    
    % Flyback blanking workaround KLUDGE!!! This means that
    % metavoxel_overlap will need to be bigger than it would otherwise need
    % to be, by one voxel.
    workspace_size = size(voxelpower);
    voxelpower(end,:,:) = zeros(workspace_size(2:3));
    adj = ones(workspace_size);
    
    xc = STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.x;
    yc = STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.y;
    
    if SHOW_COMPENSATION
        figure(SHOW_COMPENSATION);
        subplot(1,2,1);
        cla;
        legend_entries = {};
    end
    
    
    for powercomp = 1:length(POWER_COMPENSATION)
        % Vignetting power compensation lives here.
        switch POWER_COMPENSATION{powercomp}
            case 'speed'
                % Compensate proportionally--generalise Christos's ad-hoc
                % compensation due to a nonlinearity in polymerisation vs speed
                % e.g., ((v - 1) * 0.5) + 1
                
                % Normalisation: as we zoom in, absolute speed decreasees,
                % so no normalisation is necessary.
                beamspeed = diff(xc) * STL.calibration.pockelsFrequency;
                beamspeed(end+1) = beamspeed(1);
                beam_power_comp_x = ((beamspeed - STL.calibration.beam_speed_max_um) * BEAM_SPEED_POWER_COMPENSATION_FACTOR ...
                    + STL.calibration.beam_speed_max_um) ...
                    / STL.calibration.beam_speed_max_um;
                adj = repmat(beam_power_comp_x', [1, workspace_size(2), workspace_size(3)]);
                voxelpower = voxelpower .* adj;
                disp(sprintf('~ Beam speed power compensation (factor %g) applied. Adjusted power is on [%g, %g]', ...
                    BEAM_SPEED_POWER_COMPENSATION_FACTOR, ...
                    min(voxelpower(v_i)), ...
                    max(voxelpower(v_i))));
                
                if SHOW_COMPENSATION
                    figure(SHOW_COMPENSATION);
                    subplot(1,2,1);
                    hold on;
                    plot(xc, beam_power_comp_x);
                    legend_entries{end+1} = 'speed';
                    hold off;
                end
                
            case 'cos'
                [vig_x, vig_y] = meshgrid(xc, yc);
                vignetting_falloff = cos(atan(((vig_x.^2 + vig_y.^2).^(1/2))/STL.calibration.lens_optical_working_distance));
                
                vignetting_falloff = repmat(vignetting_falloff', [1, 1, size(voxelpower, 3)]);
                voxelpower = voxelpower ./ vignetting_falloff;
                adj = adj ./ vignetting_falloff;
                
                disp(sprintf('~ Vignetting power compensation (cos(theta)) applied. Adjusted power is on [%g, %g]', ...
                    min(voxelpower(v_i)), ...
                    max(voxelpower(v_i))));
                
            case 'fit'
                if isfield(STL, 'calibration') & isfield(STL.calibration, 'vignetting_fit') & length(STL.calibration.vignetting_fit) > 0
                    [vig_x, vig_y] = meshgrid(xc, yc);
                    centreX = round(length(vig_x / 2));
                    centreY = round(length(vig_y / 2));
                    for fit_function = 1:length(STL.calibration.vignetting_fit)
                        vignetting_falloff = STL.calibration.vignetting_fit{fit_function}(vig_x, -vig_y);
                        
                        % So far, vignetting_falloff is still in arbitrary
                        % units of TIFF brightness! Set power change in centre
                        % of FOV to 1.
                        vignetting_falloff = vignetting_falloff / vignetting_falloff(centreX, centreY);
                        
                        % Rescale compensation (like a learning rate and a
                        % photoresist responsiveness factor rolled into
                        % one)
                        %vignetting_falloff = ((vignetting_falloff-1) * FIT_COMPENSATION_FACTOR) + 1;
                        vignetting_falloff = vignetting_falloff ^ FIT_COMPENSATION_FACTOR;
                        
                        
                        % Higher luminance (e.g. edges) indicates higher
                        % falloff, so it needs to be inverted.
                        vignetting_falloff = 1 ./ vignetting_falloff;
                        
                        % Transpose: xc is the first index of the matrix (row #)
                        vignetting_falloff = repmat(vignetting_falloff', [1, 1, size(voxelpower, 3)]);
                        adj = adj ./ vignetting_falloff;
                        voxelpower = voxelpower ./ vignetting_falloff;
                        disp(sprintf('~ Vignetting power compensation (current fit %d, factor %g) applied. Adjusted power is on [%g, %g]', ...
                            fit_function, ...
                            FIT_COMPENSATION_FACTOR, ...
                            min(voxelpower(v_i)), ...
                            max(voxelpower(v_i))));
                        
                        if SHOW_COMPENSATION
                            figure(SHOW_COMPENSATION);
                            subplot(1,2,1);
                            hold on;
                            middle = round(size(vignetting_falloff, 2));
                            plot(vig_x, adj(:, middle, end));
                            legend_entries{end+1} = sprintf('Iter %d', fit_function);
                            %plot(viog_x, STL.print.power ./ voxelpower(:, middle, end));
                            hold off;
                            
                            subplot(1,2,2);
                            surfc(vig_x, vig_y, 1./(adj(:,:,end)'));
                            colorbar;
                        end

                    end
                else
                    warning('~ No vignetting power compensation fit functions available.');
                end
                
            case 'none'
                disp('~ Vignetting power compensation NOT applied.');
                
            otherwise
                warning('~ Illegal value specified. Vignetting power compensation NOT applied.');
        end
    end
    
    % Do not ask for more than 100% power:
    if max(voxelpower(:)) > 1
        warning(sprintf('~ Vignetting compensation is requesting power %g%%! Squashing to 100%%.', 100*max(voxelpower(:))));
        voxelpower = min(voxelpower, 1);
    end
    
    if min(voxelpower(:)) < 0
        voxelpower = max(voxelpower, 0);
        %error('~ Someone requested power < 0. You''ll want to fix that.');
    end
            
    disp(sprintf('~ Final adjusted power is on [%g, %g]', ...
        min(voxelpower(v_i)), ...
        max(voxelpower(v_i))));
    
    if SHOW_COMPENSATION
        figure(SHOW_COMPENSATION);
        if exist('vignetting_falloff', 'var')
            subplot(1,2,1);
            title('Compensation factors @ Y=0');
            xlabel('X (\mu{}m)');
            ylabel('Factor');
            legend(legend_entries, 'Location', 'South');
            subplot(1,2,2);
        else
            subplot(1,1,1);
        end
        
        adj = adj(:,:,1); % Don't need all the repeats!
        
        imagesc(STL.print.voxelpos_wrt_fov{1,1,1}.x, ...
            STL.print.voxelpos_wrt_fov{1,1,1}.y, ...
            adj');
        axis square;
        colorbar;
        colormap(jet);
        title('Power compensation');
        xlabel('X (\mu{}m)');
        ylabel('Y (\mu{}m)');
    end

    % Save for analysis
    STL.print.voxelpower_adjustment = adj;
    STL.print.voxelpower_actual = voxelpower;
    STL.print.ao_volts_out = ao_volts_raw;

    if STL.logistics.simulated
        STL.print.ao_volts_out.B(:, STL.print.whichBeam) = voxelpower(:);
    else
        STL.print.ao_volts_out.B(:, STL.print.whichBeam) = hSI.hBeams.zprpBeamsPowerFractionToVoltage(STL.print.whichBeam, voxelpower(:));
    end
    
    % Decrease power as appropriate for current zoom level. Empirically, this
    % seems to go sublinearly! Not sure why. Perhaps overscanning on Y doesn't
    % happen fast enough to count as more power? Perhaps SUBlinear because I
    % have not calibrated aspect ratio yet? FIXME
    %STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor;
    
    ao_volts_out = STL.print.ao_volts_out;
end
