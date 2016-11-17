function [ao_volts_out] = printimage_modify_beam(ao_volts_raw);

global STL;

hSI = evalin('base','hSI');% get hSI from the base workspace
%hSI.hMotors.motorPosition = [0 0 0];  % move stage to origin Note: depending on motor this value is a 1x3 OR 1x4 matrix
%hSI.hScan2D.logFilePath = 'C:\';      % set the folder for logging Tiff files
%hSI.hScan2D.logFileStem = 'myfile'    % set the base file name for the Tiff file
%hSI.hScan2D.logFileCounter = 1;       % set the current Tiff file number
hSI.hChannels.loggingEnable = false;
%hSI.hRoiManager.scanZoomFactor = 2;   % define the zoom factor
%hSI.hRoiManager.framesPerSlice = 100; % set number of frames to capture in one Grab
STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
    length(hSI.hWaveformManager.scannerAO.ao_volts.B) / (hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B * hSI.hFastZ.numFramesPerVolume) ...
    hSI.hFastZ.numFramesPerVolume];
warning('This should figure out Z based on how many microns (roughly 1um/slice) are needed given zoom/FOV.');

% Reconfigure the printable mesh so that printing can proceed along Z:
switch STL.buildaxis
    case 1
        STL.print.mesh = STL.mesh(:, [2 3 1], :);
    case 2
        STL.print.mesh = STL.mesh(:, [1 3 2], :);
    case 3
        STL.print.mesh = STL.mesh;
end

% correct for sinusoidal velocity.  This computes the locations of pixel
% centres.
xc = (linspace(0, 1, STL.print.resolution(1)) - 0.5) * 2;
xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
xc = sin(xc);
xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
STL.print.respos = (xc + 1) / 2;

disp('Re-voxelising...');
STL.print.voxels = VOXELISE(STL.print.respos, STL.print.resolution(2), STL.print.resolution(3), STL.print.mesh);
disp('...done.');

v = double(STL.print.voxels(:)) * STL.print.power;
STL.print.beams = hSI.hBeams.zprpBeamsPowerFractionToVoltage(1,v);

ao_volts_out = ao_volts_raw;
ao_volts_out.B = STL.print.beams;

if 0
    figure(32);
    colormap gray;
    img = hSI.hWaveformManager.scannerAO.ao_volts_raw.B;
    if isfield(hSI.hWaveformManager.scannerAO.ao_volts_raw, 'Bpb')
        imgpb = hSI.hWaveformManager.scannerAO.ao_volts_raw.Bpb;
        bpb = true;
    else
        disp('No powerboxes, no problem!');
        bpb = false;
    end
    framesize = prod(STL.print.resolution(1:2));
    
    for i = 1:STL.print.resolution(3)
        startat = (i-1) * framesize + 1;
        
        if bpb
            subplot(2,1,1);
        else
            subplot(1,1,1);
        end
        imagesc(reshape(img(startat:startat+framesize-1), ...
            STL.print.resolution(1:2))');
        colorbar;
        
        if bpb
            subplot(2,1,2);
            imagesc(reshape(imgpb(startat:startat+framesize-1), ...
                STL.print.resolution(1:2))');
            colorbar;
        end
        
        pause(0.01);
    end
end
