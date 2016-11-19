function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);

global STL;

% For debugging, ao_volts_raw = hSI.hWaveformManager.scannerAO.ao_volts_raw

hSI = evalin('base', 'hSI');
hSI.hChannels.loggingEnable = false;
%hSI.hRoiManager.framesPerSlice = 100; % set number of frames to capture in one Grab

% Reconfigure the printable mesh so that printing can proceed along Z:
switch STL.buildaxis
    case 1
        STL.print.mesh = STL.mesh(:, [2 3 1], :);
        STL.print.aspect_ratio = STL.aspect_ratio([2 3 1]);
    case 2
        STL.print.mesh = STL.mesh(:, [1 3 2], :);
        STL.print.aspect_ratio = STL.aspect_ratio([1 3 2]);
    case 3
        STL.print.mesh = STL.mesh;
        STL.print.aspect_ratio = STL.aspect_ratio;
end

height = floor(max(STL.print.mesh(:, 3, 3)) * STL.print.largestdim);
STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
    hSI.hRoiManager.linesPerFrame ...
    height];

% x centres. Correct for sinusoidal velocity.  This computes the locations
% of pixel centres.
xc = (linspace(0, 1, STL.print.resolution(1)) - 0.5) * 2;
xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
xc = sin(xc);
xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
STL.print.respos = (xc + 1) / 2;

% y centres. These should be spaced equally along Y Galvo scanlines.
yc = linspace(0, 1, STL.print.resolution(2));

% z centres are defined by stack height, so VOXELISE() behaves fine
% already.

disp('Re-voxelising...');
STL.print.voxels = VOXELISE(STL.print.respos, yc, STL.print.resolution(3), STL.print.mesh);
% Discard empty slices. This will hopefully be only the final slice, or
% none. This might be nice for eliminating that last useless slice, but we
% can't do that from printimage_modify_beam since the print is already
% running.
%STL.print.voxels = STL.print.voxels(:, :, find(sum(sum(STL.print.voxels, 1), 2) ~= 0));
%STL.print.resolution(3) = size(STL.print.voxels, 3);
disp('      ...done.');


v = double(STL.print.voxels(:)) * STL.print.power;

STL.print.ao_volts_raw.B = hSI.hBeams.zprpBeamsPowerFractionToVoltage(1,v);

% Decrease power as appropriate for current zoom level:
%STL.print.ao_volts_raw.B = STL.print.ao_volts_raw.B / hSI.hRoiManager.scanZoomFactor^2;

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
        imagesc(STL.print.respos, linspace(0, 1, STL.print.resolution(2)), ...
            reshape(img(startat:startat+framesize-1), STL.print.resolution(1:2))');
        colorbar;
        axis square;
                
        pause(0.01);
    end
end
