function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);
    global STL;
    global ao_volts_out; % Expose this for easier debugging
    
    POWER_COMPENSATION = 'fit';
    
    if ~(isfield(STL, 'calibration') & isfield(STL.calibration, 'vignetting_fit') ...
            & isfield(STL.print, 'vignetting_compensation') & STL.print.vignetting_compensation)
        POWER_COMPENSATION = 'ad-hoc';
    end

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

    voxelpower = STL.print.metapower{mvx, mvy, mvz};

    disp(sprintf('Relative power is on [%g, %g]', ...
        min(min(min(voxelpower))), ...
        max(max(max(voxelpower)))));
    

    % Flyback blanking workaround KLUDGE!!! This means that metavoxel_overlap will need to be bigger than it would otherwise need
    % to be, by one voxel.
    
    foo = size(voxelpower);
    voxelpower(end,:,:) = zeros(foo(2:3));
    v = voxelpower(:);
    %disp(sprintf('=== Cosine took power down to %g', ...
    %    min(v(find(v~=0)))));
    % boost low-power voxels, but not the zero-power voxels
    vnot = (v > 0.01);
    v = v * STL.print.power;
    
    disp(sprintf('Adjusted power is on [%g, %g]', ...
        min(v), ...
        max(v)));

    switch POWER_COMPENSATION
        case 'ad-hoc'
            % Christos's ad-hoc compensation is very good on the development r3D2 unit at zoom = 2.2!
            disp('Using Christos''s ad-hoc curve...');
            v(vnot) = v(vnot) + 0.5*(STL.print.power - v(vnot));
            
        case 'fit'
            disp('Using Ben''s vignetting compensator.');
            if isfield(STL, 'calibration') & isfield(STL.calibration, 'vignetting_fit') ...
                    & isfield(STL.print, 'vignetting_compensation') & STL.print.vignetting_compensation
                xc = STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.x;
                yc = STL.print.voxelpos_wrt_fov{mvx, mvy, mvz}.y;
                [vig_x, vig_y] = meshgrid(xc, yc);
                vignetting_falloff = STL.calibration.vignetting_fit(vig_x, vig_y);
                vignetting_falloff = vignetting_falloff / max(max(vignetting_falloff));
            else
                disp('No vignetting fit available.');
                vignetting_falloff = ones(STL.print.resolution(1:2));
            end
            % Transpose: xc is the first index of the matrix (row #)
            vignetting_falloff = repmat(vignetting_falloff', [1, 1, size(voxelpower, 3)]);

            v(vnot) = v(vnot) ./ vignetting_falloff(vnot);
            
        otherwise
            disp('Using pure sinusoid power compensation.');
    end
    
    % Do not ask for more than 100% power:
    if max(v) > 1
        warning('Vignetting compensation is requesting power > 100%');
    end
    
    disp(sprintf('Adjusted power II is on [%g, %g]', ...
        min(v), ...
        max(v)));
    
    v = min(v, 1);
    v = max(v, 0);
    
    disp(sprintf('Adjusted power III is on [%g, %g]', ...
        min(v), ...
        max(v)));

     if false
        figure(12);
        subplot(1,2,2);
        v_vis = reshape(v, size(voxelpower));
        image(squeeze(v_vis(:,:,end-1))');
        colorbar;
        colormap jet;
    end
    
   %disp(sprintf('=== Compensation took power down to %g', ...
    %    min(v(find(v~=0)))));

    STL.print.ao_volts_raw = ao_volts_raw;
    STL.print.ao_volts_raw.B(:, STL.print.whichBeam) = hSI.hBeams.zprpBeamsPowerFractionToVoltage(STL.print.whichBeam, v);
    
    % Decrease power as appropriate for current zoom level. Empirically, this
    % seems to go sublinearly! Not sure why. Perhaps overscanning on Y doesn't
    % happen fast enough to count as more power? Perhaps SUBlinear because I
    % have not calibrated aspect ratio yet? FIXME
    %STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor;
    
    ao_volts_out = STL.print.ao_volts_raw;
    
    %figure(33);
    %plot(ao_volts_out.Z);
end
