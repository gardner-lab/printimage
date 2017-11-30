function show_power_adjustment
    global STL;
    
    STL.print.mvx_now = 1;
    STL.print.mvy_now = 1;
    STL.print.mvz_now = 1;
    
    ao_volts_raw.B = [];
    
    ao_volts_out = printimage_modify_beam(ao_volts_raw);
    x = reshape(ao_volts_out.B, STL.print.metavoxel_resolution{1,1,1});
    
end
