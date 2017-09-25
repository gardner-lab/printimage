STL.print.zstep = 1;     % microns per step in z (vertical)
STL.print.power = 0.6;

STL.motors.hex.ip_address = '128.197.37.149';
STL.motors.hex.pivot_z_um = 36700;
STL.motors.hex.leveling = [0 0 0 0.3 -0.1 -1.1];

%STL.motors.rot.com_port = 'com4';

STL.motors.stitching = 'hex';
STL.motors.special = 'hex_pi';

STL.motors.mom.origin = [12066 1.0896e+04 1.6890e+04]; % Where should MOM aim to see understage centre? 
