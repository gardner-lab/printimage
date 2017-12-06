function motorHold(handles, v);
    % Control motor position-hold-before-reset: 'on', 'off', 'resetXY',
    % 'resetZ'
    global STL;
    hSI = evalin('base', 'hSI');
    
    if strcmp(v, 'on')
        set(handles.crushThing, 'BackgroundColor', [1 0 0]);
        %%%%%% FIXME Disabled! STL.print.FastZhold = true;
        %STL.print.FastZhold = true;
        STL.print.motorHold = true;
        %warning('Disabled fastZ hold hack.');
        STL.print.motor_reset_needed = true;
        STL.motors.mom.tmp_origin = move('mom');
        
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:5), 'LEVEL')
            hexapod_wait();
            STL.motors.hex.C887.KEN('ZERO');
        end
        STL.motors.hex.tmp_origin = hexapod_get_position_um();
    end
    
    if strcmp(v, 'off')
        STL.print.motorHold = false;
        STL.print.motor_reset_needed = true;
    end
    
    if strcmp(v, 'resetXY')
        if isfield(STL.motors.mom, 'tmp_origin')
            hSI.hMotors.motorPosition(1:2) = STL.motors.mom.tmp_origin(1:2);
        end
        if isfield(STL.motors.hex, 'tmp_origin')
            if STL.logistics.simulated
                STL.logistics.simulated_pos(1:2) = STL.motors.hex.tmp_origin(1:2);
            elseif STL.motors.hex.connected
                % If the hexapod is in 'rotation' coordinate system,
                % wait for move to finish and then switch to 'ZERO'.
                [~, b] = STL.motors.hex.C887.qKEN('');
                if ~strcmpi(b(1:5), 'LEVEL')
                    hexapod_wait();
                    STL.motors.hex.C887.KEN('ZERO');
                end
                move('hex', STL.motors.hex.tmp_origin(1:2));
            end
        end
        
        %STL.print.motorHold = false;
        %STL.print.motor_reset_needed = false;
        %set(handles.crushThing, 'BackgroundColor', 0.94 * [1 1 1]);
        set(handles.messages, 'String', 'Restored XY position but not Z position. Crush the thing?');
    end
    
    if strcmp(v, 'resetZ')
        %hSI.hFastZ.goHome; % This takes us to 0 (as I've set it up), which is not what we
        %want.
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
        
        % Don't use MOVE, since I haven't written MOVE to just move Z.
        if isfield(STL.motors.mom, 'tmp_origin')
            hSI.hMotors.motorPosition(3) = STL.motors.mom.tmp_origin(3);
        end
        if isfield(STL.motors.hex, 'tmp_origin')
            if STL.logistics.simulated
                STL.logistics.simulated_pos(3) = STL.motors.hex.tmp_origin(3);
            elseif STL.motors.hex.connected
                % If the hexapod is in 'rotation' coordinate system,
                % wait for move to finish and then switch to 'ZERO'.
                [~, b] = STL.motors.hex.C887.qKEN('');
                if ~strcmpi(b(1:5), 'LEVEL')
                    hexapod_wait();
                    STL.motors.hex.C887.KEN('ZERO');
                end
                STL.motors.hex.C887.MOV('Z', STL.motors.hex.tmp_origin(3)/1e3);
            end
        end
        
        STL.print.motorHold = false;
        STL.print.motor_reset_needed = false;
        set(handles.messages, 'String', '');
        set(handles.crushThing, 'BackgroundColor', 0.94 * [1 1 1]);
    end
end
