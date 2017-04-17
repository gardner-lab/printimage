function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);
    global STL;
    global ao_volts_out; % Expose this for easier debugging
    
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
    foo = size(STL.print.voxels);
    STL.print.voxels(end, :, :) = zeros(foo(2:3));
    
    v = double(STL.print.voxels(:)) * STL.print.power;
    
    STL.print.ao_volts_raw = ao_volts_raw;
    STL.print.ao_volts_raw.B(:, STL.print.whichBeam) = hSI.hBeams.zprpBeamsPowerFractionToVoltage(STL.print.whichBeam, v);
    
    % Decrease power as appropriate for current zoom level. Empirically, this
    % seems to go sublinearly! Not sure why. Perhaps overscanning on Y doesn't
    % happen fast enough to count as more power? Perhaps SUBlinear because I
    % have not calibrated aspect ratio yet? FIXME
    %STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor;
    
    ao_volts_out = STL.print.ao_volts_raw;
    
    % Z will decrease (moving the fastZ stage towards 0 (highest position) and
    % then reset. Delete the reset:
    %    [val pos] = min(ao_volts_out.Z);
    %n = length(ao_volts_out.Z) - pos;
    %ao_volts_out.Z(pos+1:end) = ao_volts_out.Z(pos) * ones(1, n);
    
    if 0
        figure(32);
        colormap gray;
        %img = hSI.hWaveformManager.scannerAO.ao_volts_raw.B;
        img = ao_volts_raw.B;
        framesize = prod(STL.print.resolution(1:2));
        
        for i = 1:STL.print.resolution(3)
            startat = (i-1) * framesize + 1;
            
            % Need to give imagesc the positions of the pixels (voxels) or the
            % aspect ratio will be wrong.
            imagesc(STL.print.voxelpos.x, STL.print.voxelpos.y, ...
                reshape(img(startat:startat+framesize-1), STL.print.resolution(1:2))');
            colorbar;
            axis square;
            
            pause(0.01);
        end
    end
    %figure(33);
    %plot(ao_volts_out.Z);
end
