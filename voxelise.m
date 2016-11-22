function [] = voxelise()

global STL;
hSI = evalin('base', 'hSI');


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

if exist('hSI', 'var') & isfield(hSI, 'hWaveformManager') & isfield(hSI.hWaveformManager, 'scannerAO') ...
        & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))

    STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        height];
    format_to_print = true;
else
    STL.resolution = [100 100 height];
    format_to_print = false;
end

% x (resonant scanner) centres. Correct for sinusoidal velocity.  This computes the locations of
% pixel centres.
xc = (linspace(0, 1, STL.print.resolution(1)) - 0.5) * 2;
xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
xc = sin(xc);
xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
STL.print.voxelpos.x = (xc + 1) / 2;
warning('You computed the sinusoid compensation, but didn''t adjust the output power to match.');

% y centres. These should be spaced equally along Y Galvo scanlines.
yc = linspace(0, 1, STL.print.resolution(2));
STL.print.voxelpos.y = yc;
STL.print.voxelpos.z = linspace(0, 1, STL.print.resolutioin(3));
% z centres are defined by stack height, so VOXELISE() behaves fine
% already.

disp('Re-voxelising...');
voxels = VOXELISE(STL.print.voxelpos.x, STL.print.voxelpos.y, STL.print.resolution(3), STL.print.mesh);
if format_to_print
    STL.print.voxels = voxels;
else
    STL.voxels = voxels;
end
% Discard empty slices. This will hopefully be only the final slice, or
% none. This might be nice for eliminating that last useless slice, but we
% can't do that from printimage_modify_beam since the print is already
% running.
%STL.print.voxels = STL.print.voxels(:, :, find(sum(sum(STL.print.voxels, 1), 2) ~= 0));
%STL.print.resolution(3) = size(STL.print.voxels, 3);
disp('      ...done.');
