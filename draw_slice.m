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
        try
            zi = STL.print.voxelpos{w(1),w(2),w(3)}.z;
            which_slice = round(zind * (length(zi) - 1)) + 1;
            imagesc(STL.print.voxelpos{w(1), w(2), w(3)}.x, STL.print.voxelpos{w(1), w(2), w(3)}.y, ...
                squeeze(STL.print.metavoxels{w(1), w(2), w(3)}(:, :, which_slice))', 'Parent', handles.axes2);
            title(handles.axes2, sprintf('%.1f {\\mu}m', zi(which_slice)));
        catch ME
            disp(sprintf('Cannot imagesc the metavoxel at [ %d %d %d ]', w(1), w(2), w(3)));
            rethrow(ME);
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
