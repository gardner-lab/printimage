% Sets STL.print.dims, and calls for reorientation of the model.
function update_dimensions(handles, dim, val)
    global STL;
    % Recompute all dimensions based on aspect ratio and build axes
        
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    if isfield(STL.print, 'dims')
        olddims = STL.print.dims;
    else
        olddims = [NaN NaN NaN];
    end
    
    STL.print.dims = [STL.print.xaxis yaxis STL.print.zaxis];
    
    if isfield(STL, 'aspect_ratio')
        if get(handles.lockAspectRatio, 'Value') == 0
            % This is a total kludge for squashing the object for test
            % purposes. Thus, it's ugly.
            old_aspect_ratio = STL.aspect_ratio;
            dims_operator = eye(3);
            dims_operator = dims_operator(:, STL.print.dims);
            STL.print.size = [str2double(get(handles.size1, 'String')) ...
                str2double(get(handles.size2, 'String')) ...
                str2double(get(handles.size3, 'String'))];
            STL.aspect_ratio = (STL.print.size * inv(dims_operator)) / max(STL.print.size);
            
            dim_scale = diag(STL.aspect_ratio ./ old_aspect_ratio);
            STL.patchobj1.vertices = STL.patchobj1.vertices * dim_scale;
            STL.aspect_ratio = max(STL.patchobj1.vertices, [], 1);
            STL.aspect_ratio = STL.aspect_ratio / max(STL.aspect_ratio);
            STL.patchobj1.vertices = STL.patchobj1.vertices / max(STL.aspect_ratio);
            for i = 1:3
                STL.mesh1(:, i, :) = STL.mesh1(:, i, :) * dim_scale(i, i);
            end
            STL.mesh1 = STL.mesh1 / max(STL.aspect_ratio);
        end
        aspect_ratio = STL.aspect_ratio(STL.print.dims);
        
        if nargin == 1
            % If we're not looking to change a particular dimension,
            % default to holding Z constant and adjusting X and Y.
            dim = 3;
            val = STL.print.size(3);
        end
        if isfield(STL.print, 'size')
            oldsize = STL.print.size;
        end
        
        % Include a roundoff fudge factor (nearest nanometre)
        STL.print.size = round(1e3 * aspect_ratio/aspect_ratio(dim) * val)/1e3;
        if ~isfield(STL.print, 'size') | any(STL.print.size ~= oldsize) | any(STL.print.dims ~= olddims)
            STL.print.rescale_needed = true;
            STL.preview.voxelise_needed = true;
            STL.print.voxelise_needed = true;
        end
        
        update_gui(handles);
        update_3d_preview(handles);
    end
    
    %set(handles.messages, 'String', sprintf('New dims are [ %s]', sprintf('%d ', STL.print.dims)));
end

