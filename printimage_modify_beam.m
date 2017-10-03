function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);
    global STL;
    global ao_volts_out; % Expose this for easier debugging
    
    POWER_COMPENSATION = 'christos';
    
    hSI = evalin('base', 'hSI');
    %hSI.hChannels.loggingEnable = false;
    
    if STL.print.voxelise_needed
        voxelise([], 'print');
    end
    
    if STL.print.voxelise_needed
        error('Tried re-voxelising, but was unsuccessful.');
    end
    
    % Flyback blanking workaround KLUDGE!!! This means that metavoxel_overlap will need to be bigger than it would otherwise need
    % to be, by one voxel.
    foo = size(STL.print.voxelpower);
    STL.print.voxelpower(end,:,:) = zeros(foo(2:3));
    v = STL.print.voxelpower(:);
    %disp(sprintf('=== Cosine took power down to %g', ...
    %    min(v(find(v~=0)))));
    % boost low-power voxels, but not the zero-power voxels
    vnot = (v > 0.1);
    v = v * STL.print.power;
    
    switch POWER_COMPENSATION
        case 'christos'
            v(vnot) = v(vnot) + 0.5*(STL.print.power - v(vnot));
        case 'ben'
            v(vnot) = v(vnot) + something;
        otherwise
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
