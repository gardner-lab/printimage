function hexapod_reset_to_zero_rotation(handles)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end

    %% Some versions of PI Hexapod control crash z into the lens when doing
    %% a big z rotation! So make sure it's okay to pull the lens up before
    %% rotating.
    %pos = hexapod_get_position();
    %if any(abs(pos(4:6)) > 0.1)
    %    foo = questdlg('Ok to un-rotate hexapod?', ...
    %        'Stage setup', 'Yes', 'No', 'Yes');
    %    switch foo
    %        case 'Yes'
    %            ;
    %        case 'No'
    %            return;
    %   end
    %end

    %% For some reason, this can lead to about a 400-micron up-and-down. So
    %% give us space!
    %mompos = move('mom');
    %minmommove = max(min(mompos(3), 400) - 1, 0)
    %disp('Moving MOM to:');
    %mompos - [0 0 minmommove]

    %move('mom', mompos - [ 0 0 minmommove]);
    hexapod_wait();

    try
        % If a rotation coordinate system is defined, then use it.
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end
    end

    STL.motors.hex.C887.VLS(10);
    STL.motors.hex.C887.MOV('U V W', [0 0 0]);
    
    if exist('handles', 'var')
        hexapod_wait(handles);
    else
        hexapod_wait();
    end
    %% Return MOM to the previous height
    %disp('Moving MOM to:');
    %mompos

    %move('mom', mompos);
    if exist('handles', 'var')
        update_gui(handles);
    end
end
