function hexapod_wait(handles)
    global STL;
    
    if exist('handles', 'var')
        set(handles.messages, 'String', 'Waiting for hexapod to finish zeroing...');
    end
    for i = 1:6
        while(STL.motors.hex.C887.IsMoving(STL.motors.hex.axes(i)))
            pause(0.1);
        end
    end
    if exist('handles', 'var')
        set(handles.messages, 'String', '');
    end
end

