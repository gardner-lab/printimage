STL.print.zstep = 1;     % microns per step in z (vertical)
STL.print.power = 0.6;

STL.motors.hex.ip_address = '128.197.37.84';
STL.motors.hex.pivot_z_um = 36700;
STL.motors.hex.leveling = [0 0 0 -0.3367 -0.1383 -1.4];
STL.motors.hex.user_rotate_velocity = 20;

%STL.motors.rot.com_port = 'com4';

STL.motors.stitching = 'hex';
STL.motors.special = 'hex_pi';

STL.motors.mom.understage_centre = [12676 10480 16730]; % Where should MOM aim to see the understage's centre? 
