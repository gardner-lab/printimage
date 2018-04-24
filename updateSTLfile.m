function updateSTLfile(handles, STLfile)
    global STL;
        
    STL.file = STLfile;
    STL.mesh1 = READ_stl(STL.file);
    % This is stupid, but patch() likes this format, so easiest to just read it
    % again.
    STL.patchobj1 = stlread(STL.file);
    
    % Reset one or two things...
    STL.print.invert_z = 0;
    set(handles.invert_z, 'Value', 0);
    
    % Position the object at the origin+.
    llim = min(STL.patchobj1.vertices);
    STL.patchobj1.vertices = bsxfun(@minus, STL.patchobj1.vertices, llim);
    STL.mesh1 = bsxfun(@minus, STL.mesh1, llim);
    
    % Scale into the desired dimensions--in microns--from the origin to
    % positive-everything.
    STL.aspect_ratio = max(STL.patchobj1.vertices);
    
    % Squeeze the object into a unit cube (hence the 1 in the name), for later easier scaling
    STL.patchobj1.vertices = STL.patchobj1.vertices / max(STL.aspect_ratio);
    STL.mesh1 = STL.mesh1 / max(STL.aspect_ratio);
    
    % Aspect ratio is normalised so max is 1
    STL.aspect_ratio = STL.aspect_ratio / max(STL.aspect_ratio);
    
    update_dimensions(handles); % First pass at object dimensions according to aspect ratio
end

