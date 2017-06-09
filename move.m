% Moves 'mom' (Sutter MOM) or 'hex' (Physik-Instrumente hexapod), and a
% 3-vector of target positions (in microns).
function [pos] = move(motor, target_um)
    global STL;
    hSI = evalin('base', 'hSI');
    
    % if target_um is blank, just return the current position
    if ~exist('target_um', 'var')
        if STL.logistics.simulated
            pos = STL.logistics.simulated_pos(1:3);
            return;
        end
        
        switch motor
            case 'mom'
                pos = hSI.hMotors.motorPosition;
            case 'hex'
                pos = hexapod_get_position();
        end
        return;
    end
    
    % Control just X or XY or XYZ, but only those three.
    if length(target_um) > 3
        target_um = target_um(1:3);
    end

    
    %disp(sprintf(' ...moving %s to [%s ]...', motor, sprintf('%g ', target_um)));
    
    if STL.logistics.simulated
        STL.logistics.simulated_pos(1:3) = target_um;
        pos = target_um;
        
        return;
    end

    anti_backlash = [20 20 20];
    
    switch motor
        case 'mom'
            
            % Move along the expected axes in the expected direction
            %target_um = target_um(STL.motors.mom.axis_order(1:length(target_um)));
            
            
            % Go to position-x on all dimensions in order to always
            % complete the move in the same direction.
            
            if all(target_um - anti_backlash(1:length(target_um)) >= 0)
                warning('MOM anti-backlash position is out of range.');
                hSI.hMotors.motorPosition(1:length(target_um)) = target_um - anti_backlash(1:length(target_um));
            end
            if all(target_um >= 0) & all(target_um <= 21500)
                hSI.hMotors.motorPosition(1:length(target_um)) = target_um;
            else
                error('MOM commanded position is out of range.');
            end
            
        case 'hex'
            
            % If the hexapod is in 'rotation' coordinate system,
            % wait for move to finish and then switch to 'ZERO'.
            [~, b] = STL.motors.hex.C887.qKEN('');
            if ~strcmpi(b(1:8), 'PI_LEVEL')
                hexapod_wait();
                STL.motors.hex.C887.KEN('ZERO');
            end
            
            target_mm = target_um / 1e3;

            % 0x19001500 (max velocity) qVLS, max seems around 2 (units?
            % should be 10 mm/s!)
            % Parameter 0x19001900 should be 0
            % Parameter 0x19001901 should be 0
            %position = rand(1)*(STL.motors.hex.dAxisMax-STL.motors.hex.dAxisMin)+STL.motors.hex.dAxisMin;
            % Possible to do this as a single command?
            %for i = 1:length(target_mm)
            %    % anti-backlash:
            %    STL.motors.hex.C887.MOV(STL.motors.hex.axes(i), target_mm(i) - 0.02);
            %end
            %hexapod_wait();
            
            if length(target_mm) == 2
                STL.motors.hex.C887.MOV('X Y', target_mm);
            elseif length(target_mm) == 3
                STL.motors.hex.C887.MOV('X Y Z', target_mm);
            else
                error('need XY or XYZ');
            end
            hexapod_wait();
        otherwise
            
            error('Invalid motor "%s". No movement.',  motor);
            
    end
end
