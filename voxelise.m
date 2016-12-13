function [] = voxelise(handles)

global STL;
hSI = evalin('base', 'hSI');

if exist('handles', 'var');
    set(handles.messages, 'String', 'Re-voxelising...');
    drawnow;
end

%if ~isfield(STL.print, 'resolution')
%    enable_callback(true, 'focusDone_resolution_Callback', 'focusDone');
%end

% Reconfigure the printable mesh so that printing can proceed along Z:
if STL.print.xaxis == STL.print.yaxis
    error('X and Z can''t both be on axis %d.', STL.print.xaxis);
end

yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);

dims = [STL.print.xaxis yaxis STL.print.zaxis];
STL.print.mesh = STL.mesh(:, dims, :);
STL.print.aspect_ratio = STL.aspect_ratio(dims);

height = floor(max(STL.print.mesh(:, 3, 3)) * STL.print.largestdim);

if exist('hSI', 'var') & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))

    STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        height];

    STL.print.valid = true;
    
    % x (resonant scanner) centres. Correct for sinusoidal velocity.  This computes the locations of
    % pixel centres.
    xc = (linspace(0, 1, STL.print.resolution(1)) - 0.5) * 2;
    xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
    xc = sin(xc);
    xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
    STL.print.voxelpos.x = (xc + 1) / 2;
    warning('You computed the sinusoid compensation, but didn''t adjust the output power to match.');
else
    STL.print.valid = false;
    STL.print.resolution = [200 200 height];
    STL.print.voxelpos.x = linspace(0, 1, STL.print.resolution(1));
    xc = linspace(0, 1, STL.print.resolution(1));
end

% y centres. These should be spaced equally along Y Galvo scanlines.
STL.print.voxelpos.y = linspace(0, 1, STL.print.resolution(2));
STL.print.voxelpos.z = height;
% z centres are defined by stack height, so VOXELISE() behaves fine
% already.
STL.print.voxels = VOXELISE(STL.print.voxelpos.x, STL.print.voxelpos.y, STL.print.voxelpos.z, STL.print.mesh);

% Discard empty slices. This will hopefully be only the final slice, or
% none. This might be nice for eliminating that last useless slice, but we
% can't do that from printimage_modify_beam since the print is already
% running.
%STL.print.voxels = STL.print.voxels(:, :, find(sum(sum(STL.print.voxels, 1), 2) ~= 0));
%STL.print.resolution(3) = size(STL.print.voxels, 3);
if exist('handles', 'var')
    set(handles.messages, 'String', '');
    draw_slice(handles, 1);
    drawnow;
end
