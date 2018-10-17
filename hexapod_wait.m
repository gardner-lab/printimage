function hexapod_wait(handles)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end
    
    if exist('handles', 'var')
        set(handles.messages, 'String', 'Waiting for hexapod to finish zeroing...');
    end
    while(any(STL.motors.hex.C887.IsMoving('X Y Z U V W')))
        pause(0.1);
    end
    if exist('handles', 'var')
        set(handles.messages, 'String', '');
    end
end

