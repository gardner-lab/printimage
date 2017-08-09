STL.print.zstep = 0.5;     % microns per step in z (vertical)
STL.print.power = 0.63;

STL.motors.hex.pivot_z_um = 24900; % For hexapods, virtual pivot height offset of sample.
STL.motors.hex.leveling = [0 0 0 0.3 -0.1 -1.1];

STL.motors.stitching = 'mom';
STL.motors.special = 'none';
STL.motors.rot.com_port = 'com4';
STL.motors.hex.ip_address = '128.197.37.110';
