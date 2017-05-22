function move(which_motor, target_um)
    global STL;
    hSI = evalin('base', 'hSI');

    disp(sprintf(' ...servoing to [%s ]...', sprintf('%g ', target_um)));

    anti_backlash = [20 20 20];
    
    switch which_motor
        case 'mom'
            
            % Go to position-x on all dimensions in order to always
            % complete the move in the same direction.
            hSI.hMotors.motorPosition(1:length(target_um)) = target_um - anti_backlash(1:length(target_um));
            hSI.hMotors.motorPosition(1:length(target_um)) = target_um;
            
            
        case 'pi_hex'
            
            target_mm = target_um / 1e3;
            
            %position = rand(1)*(STL.motors.dAxisMax-STL.motors.dAxisMin)+STL.motors.dAxisMin;
            % Possible to do this as a single command?
            STL.motors.C887.MOV(axisname, target_um);
            % Wait for motion to stop
            while(STL.motors.C887.IsMoving(axisname))
                pause(0.1);
            end
    end
end
