function [] = voxelise(handles)

global STL;
hSI = evalin('base', 'hSI');

if exist('handles', 'var');
    set(handles.messages, 'String', 'Re-voxelising...');
    drawnow;
end


yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);

dims = [STL.print.xaxis yaxis STL.print.zaxis];
STL.print.mesh = STL.mesh(:, dims, :);
STL.print.aspect_ratio = STL.aspect_ratio(dims);

% Since I control X and Y sizes by zooming (for best resolution) (sadly
% those two dimensions covary), we should rescale the printable object so
% that the max(xsize, ysize) = 1, and then voxelise over that range.
STL.print.mesh(:, 1:2, :) = STL.print.mesh(:, 1:2, :) / max(STL.print.aspect_ratio([1 2]));

if exist('hSI', 'var') & ~isempty(fieldnames(hSI.hWaveformManager.scannerAO))

    STL.print.resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        round(STL.print.size(3) / STL.print.zstep)];

    STL.print.re_voxelise_needed_before_print = false;
    STL.print.re_voxelise_needed_before_display = false;
    
    % x (resonant scanner) centres. Correct for sinusoidal velocity.  This computes the locations of
    % pixel centres.
    xc = (linspace(0, 1, STL.print.resolution(1)) - 0.5) * 2;
    xc = xc * asin(hSI.hScan_ResScanner.fillFractionSpatial);
    xc = sin(xc);
    xc = xc / hSI.hScan_ResScanner.fillFractionSpatial;
    STL.print.voxelpos.x = (xc + 1) / 2;
else
    STL.print.valid = false;
    STL.print.resolution = [200 200 round(STL.print.size(3) / STL.print.zstep)];
    STL.print.voxelpos.x = linspace(0, 1, STL.print.resolution(1));
    xc = linspace(0, 1, STL.print.resolution(1));
    STL.print.re_voxelise_needed_before_print = true;
    STL.print.re_voxelise_needed_before_display = false;
end

% y centres. These should be spaced equally along Y Galvo scanlines.
STL.print.voxelpos.y = linspace(0, 1, STL.print.resolution(2));
STL.print.voxelpos.z = round(STL.print.size(3) / STL.print.zstep);
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
