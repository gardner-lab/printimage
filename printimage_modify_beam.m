function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);

global STL;

% For debugging, ao_volts_raw = hSI.hWaveformManager.scannerAO.ao_volts_raw

hSI = evalin('base', 'hSI');
hSI.hChannels.loggingEnable = false;
%hSI.hRoiManager.framesPerSlice = 100; % set number of frames to capture in one Grab

voxelise();

v = double(STL.print.voxels(:)) * STL.print.power;

STL.print.ao_volts_raw.B = hSI.hBeams.zprpBeamsPowerFractionToVoltage(1,v);

% Decrease power as appropriate for current zoom level:
STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor^2;

ao_volts_out = ao_volts_raw;
ao_volts_out.B = STL.print.ao_volts_raw.B;

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
