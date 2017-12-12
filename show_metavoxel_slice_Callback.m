function show_metavoxel_slice_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.show_metavoxel_slice = str2num(get(handles.show_metavoxel_slice, 'String'));
    zslider_Callback([], [], handles);
end

