function draw_slice(handles, zind);
    
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
            imagesc(STL.print.voxelpos{w(1), w(2), w(3)}.x, STL.print.voxelpos{w(1), w(2), w(3)}.y, ...
                squeeze(STL.print.metavoxels{w(1), w(2), w(3)}(:, :, min(zind, size(STL.print.metavoxels{w(1), w(2), w(3)}, 3))))', 'Parent', handles.axes2);
        catch ME
            disp(sprintf('Cannot imagesc the metavoxel at [ %d %d %d ]', w(1), w(2), w(3)));
        end
    else
        
        if STL.preview.voxelise_needed
            voxelise(handles, 'preview');
        end
        
        set(handles.show_metavoxel_slice, 'String', 'NaN');
        imagesc(STL.preview.voxelpos.x, STL.preview.voxelpos.y, squeeze(STL.preview.voxels(:, :, zind))', 'Parent', handles.axes2);
    end
    
    axis(handles.axes2, 'image', 'ij');
end
