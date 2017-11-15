STL.print.zstep = 1;     % microns per step in z (vertical)
STL.print.power = 0.6;
STL.calibration.lens_optical_working_distance = 380;

STL.motors.hex.ip_address = '128.197.37.84';
STL.motors.hex.pivot_z_um = 36700;

% On r3D2:
% If brightness increases 
%                         as X increases, increase V (pos 5)
%                         as Y increases, increase U (pos 4)
% If stitching stretches objects NW-SE, increase W
%%STL.motors.hex.leveling = [0 0 0 0.28 -0.365 -1.4]; % [ X Y Z U V W ]
STL.motors.hex.leveling = [0 0 0 0.305 -0.48 -1.4]; % [ X Y Z U V W ]
STL.motors.hex.user_rotate_velocity = 20;
STL.motors.hex.slide_level = [ 0 0 0 0.255 -0.09 0 ];
STL.calibration.ScanImage.ScanPhase = -5.8e-6;


STL.calibration.pockelsFrequency = 3333333; % Hz

%STL.motors.rot.com_port = 'com4';

STL.motors.stitching = 'hex';
STL.motors.special = 'hex_pi';

STL.motors.mom.understage_centre = [12676 10480 16730]; % Where should MOM aim to see the understage's centre? 
