% When the zSlider is moved, update things. If a build mesh is available, use that.
function zslider_Callback(hObject, eventdata, handles, pos)
    draw_slice(handles, get(handles.zslider, 'Value'));
end
