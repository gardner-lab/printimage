function draw_slice(handles, zind);
    % zind is the fractional distance into the slice
    global STL;
    
    if isfield(STL.preview, 'show_metavoxel_slice') ...
            & all(~isnan(STL.preview.show_metavoxel_slice)) ...
            & all(STL.preview.show_metavoxel_slice <= STL.print.nmetavoxels) ...
            & all(STL.preview.show_metavoxel_slice > 0)
        
        if STL.print.voxelise_needed
            voxelise(handles, 'print');
        end
        
        w = STL.preview.show_metavoxel_slice;
        zi = STL.print.voxelpos{w(1),w(2),w(3)}.z;
        if length(zi) == 0
            image(STL.print.voxelpos{w(1), w(2), w(3)}.x, STL.print.voxelpos{w(1), w(2), w(3)}.y, ...
                zeros([length(STL.print.voxelpos{w(1), w(2), w(3)}.x), length(STL.print.voxelpos{w(1), w(2), w(3)}.y)]));
        else
            which_slice = round(zind * (length(zi) - 1)) + 1;
            imagesc(STL.print.voxelpos{w(1), w(2), w(3)}.x, STL.print.voxelpos{w(1), w(2), w(3)}.y, ...
                squeeze(STL.print.metavoxels{w(1), w(2), w(3)}(:, :, which_slice))', 'Parent', handles.axes2);
            title(handles.axes2, sprintf('%.1f {\\mu}m', zi(which_slice)));
        end
    else
        if STL.preview.voxelise_needed
            voxelise(handles, 'preview');
        end
        
        set(handles.show_metavoxel_slice, 'String', 'NaN');
        which_slice = max(1, round(zind * size(STL.preview.voxels, 3)));
        imagesc(STL.preview.voxelpos.x, STL.preview.voxelpos.y, squeeze(STL.preview.voxels(:, :, which_slice))', 'Parent', handles.axes2);
        
        title(handles.axes2, sprintf('%.1f {\\mu}m', zind*STL.print.size(3)));
    end
    
    axis(handles.axes2, 'image', 'ij');
end
