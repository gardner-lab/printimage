function update_3d_preview(handles);
    global STL;
    
    if STL.print.rescale_needed
        rescale_object(handles);
    end
    
    axes(handles.axes1);
    cla;
    patch(STL.preview.patchobj, ...
        'FaceColor',       [0.8 0.8 0.8], ...
        'EdgeColor',       'none',        ...
        'FaceLighting',    'gouraud',     ...
        'AmbientStrength', 0.15);
    xlabel('x');
    ylabel('y');
    zlabel('z');
    material('dull');
    axis('image');
    daspect([1 1 1]);
    view([-135 35]);
    camlight_handle = camlight('right');
    rotate_handle = rotate3d;
    rotate_handle.enable = 'on';
end
