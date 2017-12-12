function [] = rescale_object(handles);
    global STL;
    
    set(handles.messages, 'String', 'Rescaling...');
    drawnow;
    
    % Relies on STL.print.size for desired dimensions.
    % Stores the result in STL.
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    STL.print.dims = [STL.print.xaxis yaxis STL.print.zaxis];
    set(handles.messages, 'String', sprintf('New dims (2) are [ %s]', sprintf('%d ', STL.print.dims)));
    
    max_dim = max(STL.print.size);
    
    meanz = (max(STL.patchobj1.vertices(:,STL.print.dims(3))) ...
        - min(STL.patchobj1.vertices(:,STL.print.dims(3))))/2;
    
    % Preview maintains original dimension ordering to make it easier to see what's
    % going on (no transform-order--dependent weirdness)
    STL.preview.patchobj = STL.patchobj1;
    STL.preview.mesh = STL.mesh1;
    if STL.print.invert_z
        STL.preview.patchobj.vertices(:,STL.print.dims(3)) = ...
            -(STL.preview.patchobj.vertices(:,STL.print.dims(3)) - meanz) + meanz;
        STL.preview.mesh(:, STL.print.dims(3), :) = ...
            -(STL.preview.mesh(:, STL.print.dims(3), :) - meanz) + meanz;
    end
    STL.preview.patchobj.vertices = STL.preview.patchobj.vertices * max_dim;
    
    % But this one will both scaled and rotated.
    STL.preview.mesh = STL.preview.mesh(:, STL.print.dims, :) * max_dim;
    
    % Print: reorder the dimensions (rotate) and scale.
    STL.print.mesh = STL.mesh1(:, STL.print.dims, :);
    if STL.print.invert_z
        STL.print.mesh(:, 3, :) = -(STL.print.mesh(:, 3, :) - meanz) + meanz;
    end
    STL.print.mesh = STL.print.mesh * max_dim;
    
    STL.print.rescale_needed = false;
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    set(handles.messages, 'String', '');
end


