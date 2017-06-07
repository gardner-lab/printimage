function hexapod_reset_to_zero_rotation(handles)
    global STL;
    
    pos = hexapod_get_position();
    if any(abs(pos(4:6)) > 0.1)
        foo = questdlg('Ok to un-rotate hexapod?', ...
            'Stage setup', 'Yes', 'No', 'Yes');
        switch foo
            case 'Yes'
                ;
            case 'No'
                return;
        end
    end

    % For some reason, this can lead to about a 400-micron up-and-down. So
    % give us space!
    mompos = move('mom');
    move('mom', mompos - [ 0 0 400]);
    STL.motors.hex.C887.VLS(2);
    STL.motors.hex.C887.MOV('U V W', [0 0 0]);
    
    if exist('handles', 'var')
        hexapod_wait(handles);
    else
        hexapod_wait();
    end
    move('mom', mompos);
    STL.motors.hex.C887.VLS(1);
    if exist('handles', 'var')
        update_gui(handles);
    end
end
