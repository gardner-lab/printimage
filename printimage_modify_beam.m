function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);
global STL;
global ao_volts_out; % Expose this for easier debugging

% For manual debugging, ao_volts_raw = hSI.hWaveformManager.scannerAO.ao_volts_raw

ao_volts_out = ao_volts_raw;

hSI = evalin('base', 'hSI');
hSI.hChannels.loggingEnable = false;

if ~STL.print.valid
    voxelise();
end

if STL.print.invert_z
    voxels = STL.print.voxels(:, :, end:-1:1);
else
    voxels = STL.print.voxels;
end

v = double(voxels(:)) * STL.print.power;

STL.print.ao_volts_raw.B = hSI.hBeams.zprpBeamsPowerFractionToVoltage(1,v);

% Decrease power as appropriate for current zoom level:
%STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor^2;

ao_volts_out.B = STL.print.ao_volts_raw.B;

% Z will decrease (moving the fastZ stage towards 0 (highest position) and
% then reset. Delete the reset:
if STL.fastZ_reverse
    [val pos] = max(ao_volts_out.Z);
else
    [val pos] = min(ao_volts_out.Z);
end    
n = length(ao_volts_out.Z) - pos;
ao_volts_out.Z(pos+1:end) = ao_volts_out.Z(pos) * ones(1, n);

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
figure(33);
plot(ao_volts_out.Z);
