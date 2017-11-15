function varargout = printimage(varargin)
    % PRINTIMAGE MATLAB code for printimage.fig
    %      PRINTIMAGE, by itself, creates a new PRINTIMAGE or raises the existing
    %      singleton*.
    %
    %      H = PRINTIMAGE returns the handle to a new PRINTIMAGE or the handle to
    %      the existing singleton*.
    %
    %      PRINTIMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in PRINTIMAGE.M with the given input arguments.
    %
    %      PRINTIMAGE('Property','Value',...) creates a new PRINTIMAGE or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before printimage_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to printimage_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help printimage
    
    % Last Modified by GUIDE v2.5 10-Nov-2017 18:05:05
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @printimage_OpeningFcn, ...
        'gui_OutputFcn',  @printimage_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end




function printimage_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    
    clear -global STL;
    global STL;
    
    % Add a menubar
    %hObject.MenuBar = 'none';
    menu_file = uimenu(hObject, 'Label', 'File');
    menu__file_OpenSTL = uimenu(menu_file, 'Label', 'Load STL', 'Callback', @chooseSTL_Callback);
    menu__file_LoadState = uimenu(menu_file, 'Label', 'Load State', 'Callback', @LoadState_Callback);
    menu__file_SaveState = uimenu(menu_file, 'Label', 'Save State', 'Callback', @SaveState_Callback);
    
    menu_calibrate = uimenu(hObject, 'Label', 'Calibrate');
    menu_calibrate_set_hexapod_level =  uimenu(menu_calibrate, 'Label', 'Save hexapod leveling coordinates', 'Callback', @hexapod_set_leveling);
    menu_calibrate_reset_rotation_to_centre = uimenu(menu_calibrate, 'Label', 'Reset hexapod to [ 0 0 0 0 0 0 ]', 'Callback', @hexapod_reset_to_centre);
    menu_calibrate_add_bullseye  = uimenu(menu_calibrate, 'Label', 'MOM--PI alignment', 'Callback', @align_stages);
    menu_calibrate_rotation_centre = uimenu(menu_calibrate, 'Label', 'Save hexapod-centre alignment', 'Callback', @set_stage_true_rotation_centre_Callback);
    menu_calibrate_vignetting_compensation = uimenu(menu_calibrate, 'Label', 'Calibrate vignetting falloff', 'Callback', @calibrate_vignetting_Callback);
    menu_test = uimenu(hObject, 'Label', 'Test');
    menu_test_linearity = uimenu(menu_test, 'Label', 'Stitching Stage Linearity', 'Callback', @test_linearity_Callback);
    
    try
        hSI = evalin('base', 'hSI');
        fprintf('Scanimage %s.%s\n', hSI.VERSION_MAJOR, hSI.VERSION_MINOR); % If the fields don't exist, this will throw an error and dump us into simulation mode.
        if isfield(hSI, 'simulated')
            if hSI.simulated
                error('Catch me!');
            end
        end
        STL.logistics.simulated = false;
    catch ME
        % Run in simulated mode.
        
        % To voxelise offline (e.g. big stitching jobs on a fast cluster),
        % the marked parameters should all be grabbed from the hSI
        % structure created by ScanImage on the r3D2 machine, or defined
        % here as you wish and copied manually to the r3D2 machine. FIXME
        % easy to copy to target
        
        % FIXME scanZoomFactor will probably only remain the same with
        % stitched items, for which the auto-zoom doesn't happen. If it
        % does auto-zoom, PrintImage will probably recalculate and
        % revoxelise, but if you're not doing stitching, then voxelising
        % one metavoxel is fast anyway, so there's probably no major need
        % to voxelise on a faster computer.
        STL.logistics.simulated = true;
        STL.logistics.simulated_pos = [ 0 0 0 0 0 0 ];
        hSI.simulated = true;
        hSI.hRoiManager.linesPerFrame = 512; % define here as desired
        hSI.hRoiManager.scanZoomFactor = 2.3; % define here as desired
        hSI.hRoiManager.imagingFovUm = [-333 -333; 0 0; 333 333]; % copy from hSI
        hSI.hScan_ResScanner.fillFractionSpatial = 0.9; % copy from hSI
        hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B = 152; % copy from hSI (available after a Focus)
        hSI.hMotors.motorPosition = 10000 * [ 1 1 1 ];
        STL.motors.hex.range = repmat([-10 10], 6, 1);

        assignin('base', 'hSI', hSI);
    end
    
    set(gcf, 'CloseRequestFcn', @clean_shutdown);
    
    STL.logistics.wbar_pos = [.05 .85];
    hSI.hDisplay.roiDisplayEdgeAlpha = 0.1;

    
    %% From this point onward, STL vars are not supposed to be user-configurable
    
    set_up_params();
    %foo = questdlg(sprintf('Stage rotation centre set to [%s ]. Ok?', ...
    %    sprintf(' %d', STL.motors.mom.understage_centre)), ...
    %    'Stage setup', 'Yes', 'No', 'Yes');
    %switch foo
    %    case 'Yes'
    %        ;
    %    case 'No'
    %        STL.motors.mom.understage_centre = [];
    %end
    
    
    if ~STL.logistics.simulated
        switch STL.motors.special
            case 'hex_pi'
                hexapod_pi_connect();
                set(handles.panel_rotation_hexapod, 'Visible', 'on');
            case 'rot_esp301'
                rot_esp301_connect();
                set(handles.panel_rotation_infinite, 'Visible', 'on');
            case 'none'
                ;
            otherwise
                warning('STL.motors.special: I don''t know what a ''%s'' is.', STL.motors.special);
        end
    end
    
    
    % ScanImage freaks out if we pass an illegal command to its motor stage
    % controller--and also if I can't move up the required amount, I
    % probably shouldn't drop the fastZ stage. Error out:
    zpos = hSI.hMotors.motorPosition(3);
    while zpos < 500
        foo = questdlg('Please safely drop the MOM''s Z axis to at least 500 microns.', ...
            'Stage setup', 'I did it', 'Cancel');
        switch foo
            case 'I did it'
                zpos = hSI.hMotors.motorPosition(3);
            case 'Cancel'
                hexapod_pi_disconnect()
                return;
        end
    end
    
    % Disable this for PI...
    warning('Disabling warning "MATLAB:subscripting:noSubscriptsSpecified" because there will be A LOT of them!');
    evalin('base', 'warning(''off'', ''MATLAB:subscripting:noSubscriptsSpecified'');');
    
    STL.logistics.abort = false; % Bookkeeping; not user-configurable
    
    
    % Some parameters are only computed on grab. So do one.
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    hSI.hFastZ.actuatorLag = 13e-3; % Should calibrate with zstep = whatever you're going to use

    legal_beams = {};
    if STL.logistics.simulated
        STL.motors.mom.understage_centre = [10000 10000 6000];
        STL.motors.hex.tmp_origin = [0 0 0];
        legal_beams = -1;
    else
        evalin('base', 'hSI.startGrab()');
        while ~strcmpi(hSI.acqState, 'idle')
            pause(0.1);
        end
        
        % Get the list of legal beam channels
        for i = 1:length(hSI.hChannels.channelName)
            legal_beams{i} = sprintf('%d', i);
        end
        
        % I'm going to drop the fastZ stage to 420. To make that safe, first
        % I'll move the slow stage up in order to create sufficient clearance
        % (with appropriate error checks).
        foo = hSI.hMotors.motorPosition - [0 0 (STL.print.fastZhomePos - hSI.hFastZ.positionTarget)];
        if foo(3) < 0
            foo(3) = 0;
        end
        move('mom', foo);
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    end
    set(handles.whichBeam, 'String', legal_beams);
    
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    addlistener(handles.rotate_infinite_slider, 'Value', 'PreSet', @(~,~)rotate_by_slider_show_Callback(hObject, [], handles));
    
    guidata(hObject, handles);
    
    UpdateBounds_Callback([], [], handles);
        
    %hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    %motorHold(handles, 'reset');
    
    if ~STL.logistics.simulated
        hSI.hFastZ.setHome(0);
    end
    %warning('Setting pixelsPerLine to 64 for faster testing.');
    %hSI.hRoiManager.pixelsPerLine = 64;
    hSI.hScan2D.bidirectional = false;
    hSI.hScan2D.linePhase = STL.calibration.ScanImage.ScanPhase;
    hSI.hScanner.linePhase = STL.calibration.ScanImage.ScanPhase;
    
    colormap(handles.axes2, 'gray');
    
    guidata(hObject, handles);
end


% This sets up default values for user-configurable STL parameters. Then,
% if printimage_config.m exists, we load that, and replace all valid
% parameters' default values with the user-configured versions. If the user
% tries to configure a parameter for which there is no default defined
% here, the user configuration parameter is ignored and a warning issued.
function set_up_params()
    global STL;
    
    STL.print.zstep = 1;     % microns per step in z (vertical)
    STL.print.xaxis = 1;     % axis of raw STL over which the resonant scanner scans
    STL.print.zaxis = 3;     % axis of raw STL over which we print upwards (fastZ etc)
    STL.print.power = 0.6;
    STL.print.whichBeam = 1; % if scanimage gets to play with >1 laser...
    STL.print.size = [360 360 360];
    STL.print.zoom_min = 1.2;
    STL.print.zoom = 1.2;
    STL.print.zoom_best = 1.2;
    STL.print.armed = false;
    STL.preview.resolution = [120 120 120];
    STL.print.metavoxel_overlap = [8 8 8]; % Microns of overlap (positive is more overlap) in order to get good bonding
    STL.print.voxelise_needed = true;
    STL.preview.voxelise_needed = true;
    STL.print.invert_z = false;
    STL.print.motor_reset_needed = false;
    STL.preview.show_metavoxel_slice = NaN;
    STL.print.fastZhomePos = 420;
    STL.calibration.lens_optical_working_distance = 380; % microns, for optical computations

    STL.motors.stitching = 'hex'; % 'hex' is a hexapod (so far, only hex_pi), 'mom' is Sutter MOM
    STL.motors.special = 'hex_pi'; % So far: 'hex_pi', 'rot_esp301', 'none'
    STL.motors.rot.connected = false;
    STL.motors.rot.com_port = 'com4';
    STL.motors.mom.understage_centre = [12066 1.0896e+04 1.6890e+04];
    STL.motors.hex.user_rotate_velocity = 50;
    
    STL.motors.hex.pivot_z_um = 24900; % For hexapods, virtual pivot height offset of sample.
    
    % MOM to image: [1 0 0] moves down
    %               [0 1 0] moves left
    %               [0 0 1] reduces height
    % MOM to hex:
    STL.motors.mom.coords_to_hex = [0 1 0; ...
        -1 0 0; ...
        0 0 -1];
    STL.motors.mom.axis_signs = [ -1 1 -1 ];
    STL.motors.mom.axis_order = [ 2 1 3 ];

    STL.motors.hex.connected = false;
    STL.motors.hex.ip_address = '0.0.0.0';
    % Hexapod to image: [1 0 0] moves right
    %                   [0 1 0] moves down
    %                   [0 0 1] reduces height
    STL.motors.hex.axis_signs = [ 1 1 -1 ];
    STL.motors.hex.axis_order = [ 1 2 3 ];
    STL.motors.hex.leveling = [0 0 0 0 0 0]; % This leveling zero pos will be manually applied
    %STL.motors.mom.understage_centre = [11240 10547 19479]; % When are we centred over the hexapod's origin?
    STL.motors.hex.slide_level = [ 0 0 0 0 0 0 ]; % Slide is mounted parallel to optical axis
    
    % The Zeiss LCI PLAN-NEOFLUAR 25mm has a nominal working depth of
    % 380um.
    STL.logistics.lens_working_distance = 370;
    zbound = min(STL.logistics.lens_working_distance, STL.print.fastZhomePos);
    STL.bounds_1 = [NaN NaN  zbound ];
    STL.print.bounds_max = [NaN NaN  zbound ];
    STL.print.bounds = [NaN NaN  zbound ];
    
    STL.calibration.pockelsFrequency = 3333333; % Frequency of Pockels cell controller

    % ScanImage's LinePhase adjustment. Save it here, just for good measure.
    STL.calibration.ScanImage.ScanPhase = 0;
    %%%%%
    %% Finally, allow the user to override any of these:
    %%%%%
    
    params_file = 'printimage_config'; 
    load_params(params_file, 'STL');
end

% Sets STL.print.dims, and calls for reorientation of the model.
function update_dimensions(handles, dim, val)
    global STL;
    % Recompute all dimensions based on aspect ratio and build axes
        
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    if isfield(STL.print, 'dims')
        olddims = STL.print.dims;
    else
        olddims = [NaN NaN NaN];
    end
    STL.print.dims = [STL.print.xaxis yaxis STL.print.zaxis];
    
    if isfield(STL, 'aspect_ratio')
        if get(handles.lockAspectRatio, 'Value') == 0
            % This is a total kludge for squashing the object for test
            % purposes. Thus, it's ugly.
            old_aspect_ratio = STL.aspect_ratio;
            dims_operator = eye(3);
            dims_operator = dims_operator(:, STL.print.dims);
            STL.print.size = [str2double(get(handles.size1, 'String')) ...
                str2double(get(handles.size2, 'String')) ...
                str2double(get(handles.size3, 'String'))];
            STL.aspect_ratio = (STL.print.size * inv(dims_operator)) / max(STL.print.size);
            
            dim_scale = diag(STL.aspect_ratio ./ old_aspect_ratio);
            STL.patchobj1.vertices = STL.patchobj1.vertices * dim_scale;
            STL.aspect_ratio = max(STL.patchobj1.vertices, [], 1);
            STL.aspect_ratio = STL.aspect_ratio / max(STL.aspect_ratio);
            STL.patchobj1.vertices = STL.patchobj1.vertices / max(STL.aspect_ratio);
            for i = 1:3
                STL.mesh1(:, i, :) = STL.mesh1(:, i, :) * dim_scale(i, i);
            end
            STL.mesh1 = STL.mesh1 / max(STL.aspect_ratio);
        end
        aspect_ratio = STL.aspect_ratio(STL.print.dims);
        
        if nargin == 1
            % If we're not looking to change a particular dimension,
            % default to holding Z constant and adjusting X and Y.
            dim = 3;
            val = STL.print.size(3);
        end
        if isfield(STL.print, 'size')
            oldsize = STL.print.size;
        end
        
        % Include a roundoff fudge factor (nearest nanometre)
        STL.print.size = round(1e3 * aspect_ratio/aspect_ratio(dim) * val)/1e3;
        if ~isfield(STL.print, 'size') | any(STL.print.size ~= oldsize) | any(STL.print.dims ~= olddims)
            STL.print.rescale_needed = true;
            STL.preview.voxelise_needed = true;
            STL.print.voxelise_needed = true;
        end
        
        update_gui(handles);
        update_3d_preview(handles);
    end
    
    %set(handles.messages, 'String', sprintf('New dims are [ %s]', sprintf('%d ', STL.print.dims)));
end

function [] = rescale_object(handles);
    global STL;
    
    set(handles.messages, 'String', 'Rescaling...');
    drawnow;
    
    % Relies on STL.print.size for desired dimensions.
    % Stores the result in STL.
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    STL.print.dims = [STL.print.xaxis yaxis STL.print.zaxis];
    set(handles.messages, 'String', sprintf('New dims (2) are [ %s]', sprintf('%d ', STL.print.dims)));
    
    max_dim = max(STL.print.size);
    
    meanz = (max(STL.patchobj1.vertices(:,STL.print.dims(3))) ...
        - min(STL.patchobj1.vertices(:,STL.print.dims(3))))/2;
    
    % Preview maintains original dimension ordering to make it easier to see what's
    % going on (no transform-order--dependent weirdness)
    STL.preview.patchobj = STL.patchobj1;
    STL.preview.mesh = STL.mesh1;
    if STL.print.invert_z
        STL.preview.patchobj.vertices(:,STL.print.dims(3)) = ...
            -(STL.preview.patchobj.vertices(:,STL.print.dims(3)) - meanz) + meanz;
        STL.preview.mesh(:, STL.print.dims(3), :) = ...
            -(STL.preview.mesh(:, STL.print.dims(3), :) - meanz) + meanz;
    end
    STL.preview.patchobj.vertices = STL.preview.patchobj.vertices * max_dim;
    
    % But this one will both scaled and rotated.
    STL.preview.mesh = STL.preview.mesh(:, STL.print.dims, :) * max_dim;
    
    % Print: reorder the dimensions (rotate) and scale.
    STL.print.mesh = STL.mesh1(:, STL.print.dims, :);
    if STL.print.invert_z
        STL.print.mesh(:, 3, :) = -(STL.print.mesh(:, 3, :) - meanz) + meanz;
    end
    STL.print.mesh = STL.print.mesh * max_dim;
    
    STL.print.rescale_needed = false;
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    set(handles.messages, 'String', '');
end



function varargout = printimage_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
end



function chooseSTL_Callback(hObject, eventdata, handles)
    [FileName,PathName] = uigetfile('*.stl');
    
    if isequal(FileName, 0)
        return;
    end
    
    handles = guidata(gcbo);
    STLfile = strcat(PathName, FileName);
    set(gcf, 'Name', STLfile);
    updateSTLfile(handles, STLfile);
end



function updateSTLfile(handles, STLfile)
    global STL;
        
    STL.file = STLfile;
    STL.mesh1 = READ_stl(STL.file);
    % This is stupid, but patch() likes this format, so easiest to just read it
    % again.
    STL.patchobj1 = stlRead(STL.file);
    
    % Reset one or two things...
    STL.print.invert_z = 0;
    set(handles.invert_z, 'Value', 0);
    
    % Position the object at the origin+.
    llim = min(STL.patchobj1.vertices);
    STL.patchobj1.vertices = bsxfun(@minus, STL.patchobj1.vertices, llim);
    STL.mesh1 = bsxfun(@minus, STL.mesh1, llim);
    
    % Scale into the desired dimensions--in microns--from the origin to
    % positive-everything.
    STL.aspect_ratio = max(STL.patchobj1.vertices);
    
    % Squeeze the object into a unit cube (hence the 1 in the name), for later easier scaling
    STL.patchobj1.vertices = STL.patchobj1.vertices / max(STL.aspect_ratio);
    STL.mesh1 = STL.mesh1 / max(STL.aspect_ratio);
    
    % Aspect ratio is normalised so max is 1
    STL.aspect_ratio = STL.aspect_ratio / max(STL.aspect_ratio);
    
    update_dimensions(handles); % First pass at object dimensions according to aspect ratio
end




function update_3d_preview(handles);
    global STL;
    
    if STL.print.rescale_needed
        rescale_object(handles);
    end
    
    axes(handles.axes1);
    cla;
    patch(STL.preview.patchobj, ...
        'FaceColor',       [0.8 0.8 0.8], ...
        'EdgeColor',       'none',        ...
        'FaceLighting',    'gouraud',     ...
        'AmbientStrength', 0.15);
    xlabel('x');
    ylabel('y');
    zlabel('z');
    material('dull');
    axis('image');
    daspect([1 1 1]);
    view([-135 35]);
    camlight_handle = camlight('right');
    rotate_handle = rotate3d;
    rotate_handle.enable = 'on';
end


% When the zSlider is moved, update things. If a build mesh is available, use that.
function zslider_Callback(hObject, eventdata, handles, pos)
    draw_slice(handles, get(handles.zslider, 'Value'));
end




function zslider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end


% Called when the user presses "PRINT". Various things need to happen, some
% of them before the scan is initiated and some right before the print
% waveform goes out. This function handles the former, and instructs
% WaveformManager to call printimage_modify_beam() to do the latter.
function print_Callback(hObject, eventdata, handles)
    global STL;
    
    global wbar;
    
    hSI = evalin('base', 'hSI');
    
    if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    % Save home positions. They won't be restored so as not to crush the
    % printed object, but they should be reset later.
    
    %foo = hSI.hFastZ.positionTarget;
    %hSI.hFastZ.positionTarget = 0;
    %pause(0.1);
    %hSI.hMotors.zprvResetHome();
    %hSI.hBeams.zprvResetHome();
    %hSI.hFastZ.positionTarget = foo;
    hexapos = hexapod_get_position_um();
    if any(abs(hexapos(1:3)) > 1)
        set(handles.messages, 'String', ...
            sprintf('Hexapod position is [%s ], not [ 0 0 0 ]. Please fix that first', ...
            sprintf(' %g', hexapos(1:3))));
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.rescale_needed
        rescale_object(handles);
    end
    
    UpdateBounds_Callback([], [], handles);
        
    if ~STL.logistics.simulated & isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        update_dimensions(handles); % In case the boundaries are newly available
    end
    
    hSI.hDisplay.roiDisplayEdgeAlpha = 0.1;
    
    % Make sure we haven't changed the desired resolution or anything else that
    % ScanImage can change without telling us. This should be a separate
    % function eventually!
    
    
    resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        round(STL.print.size(3) / STL.print.zstep)];
    if ~isfield(STL.print, 'resolution') | any(resolution ~= STL.print.resolution)
        STL.print.voxelise_needed = true;
    end
    
    
    if STL.print.voxelise_needed
        voxelise(handles, 'print');
        if STL.logistics.abort
            STL.logistics.abort = false;
            return;
        end
    end
    
    
    % This relies on voxelise() being called, above
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.numSlices = round(STL.print.size(3) / STL.print.zstep);
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    hSI.hFastZ.flybackTime = 0.025; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false;
    %hSI.hStackManager.stackZStartPos = 0;
    %hSI.hStackManager.stackZEndPos = NaN;
    tic
    STL.print.armed = true;
    
    % The main printing loop. How to manage the non-blocking call to
    % startLoop()?
    
    motorHold(handles, 'on');
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    start_time = datetime('now');
    eta = 'next weekend';
    
    eval(sprintf('motor = STL.motors.%s;', STL.motors.stitching));

    metavoxel_counter = 0;
    metavoxel_total = prod(STL.print.nmetavoxels);
    for mvz = 1:STL.print.nmetavoxels(3)
        for mvy = 1:STL.print.nmetavoxels(2)
            for mvx = 1:STL.print.nmetavoxels(1)
                
                if STL.logistics.abort
                    % The caller has to unset STL.logistics.abort
                    % (and presumably return).
                    disp('Aborting due to user.');
                    motorHold(handles, 'resetXY');
                    
                    if ishandle(wbar) & isvalid(wbar)
                        STL.logistics.wbar_pos = get(wbar, 'Position');
                        delete(wbar);
                    end
                    if exist('handles', 'var');
                        set(handles.messages, 'String', 'Canceled.');
                        drawnow;
                    end
                    STL.logistics.abort = false;
                    
                    STL.print.armed = false;
                    hSI.hStackManager.numSlices = 1;
                    hSI.hFastZ.enable = false;
                    
                    if ~STL.logistics.simulated
                        while ~strcmpi(hSI.acqState,'idle')
                            pause(0.1);
                        end
                    end
                    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
                    
                    return;
                end
                
                disp(sprintf('Starting on metavoxel [ %d %d %d ]...', mvx, mvy, mvz));
                
                % 0. Update the slice preview, because why the hell not?
                set(handles.show_metavoxel_slice, 'String', sprintf('%d %d %d', mvx, mvy, mvz));
                show_metavoxel_slice_Callback(hObject, eventdata, handles)
                
                % 1. Servo the slow stage to the correct starting position. This is convoluted
                % because (1) startPos may be 1x3 or 1x4, (2) we always want to approach from the
                % same side
                
                if STL.print.metavoxel_resolution{mvx, mvy, mvz}(3) == 0
                    disp(sprintf(' ...which is empty. Moving on...'));
                    continue;
                end
                
                % How many mvs are we away from the origin? Always positive.
                this_metavoxel_relative_origin = [ mvx mvy mvz] - 1;
                
                % Convert newpos from metavoxels to microns
                newpos = STL.print.metavoxel_shift .* this_metavoxel_relative_origin;
                
                % Some of the axes may want the opposite sign. This should be done in Machine_Data_File but I don't see how; see
                % below.
                newpos = newpos .* motor.axis_signs;
                
                % My axes and the motor's may be at odds, so reshuffle the order. This should be done in Machine_Data_File but I
                % don't see how; the docs are a little obsolete (or ahead of the free version?).
                newpos = newpos(motor.axis_order);
                
                % Add the motor origin from the start of this function
                newpos = newpos + motor.tmp_origin(1:3);
                
                move(STL.motors.stitching, newpos, 1);
                hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
                pause(0.1);
                
                % 2. Set up printimage_modify_beam with the appropriate
                % voxels and their power
                
                STL.print.mvx_now = mvx;
                STL.print.mvy_now = mvy;
                STL.print.mvz_now = mvz;
                
                %STL.print.voxels = STL.print.metavoxels{mvx, mvy, mvz};
                %STL.print.voxelpower = STL.print.metapower{mvx, mvy, mvz};
                
                % 3. Set resolution appropriately
                hSI.hStackManager.numSlices = STL.print.metavoxel_resolution{mvx, mvy, mvz}(3);
                
                % 4. Do whatever is necessary to get a blocking
                % startLoop(), like setting up a callback in acqModeDone?
                
                % 5. Print this metavoxel
                if ~STL.logistics.simulated
                    evalin('base', 'hSI.startLoop()');
                    
                    % 4a. Await callback from the user function "acqModeDone" or "acqAbort"? Or
                    % constantly poll... :(
                    while ~strcmpi(hSI.acqState,'idle')
                        pause(0.1);
                    end
                end
                
                % Show progress
                metavoxel_counter = metavoxel_counter + 1;
                if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
                    current_time = datetime('now');
                    eta_date = start_time + (current_time - start_time) / (metavoxel_counter / metavoxel_total);
                    if strcmp(datestr(eta_date, 'yyyymmdd'), datestr(current_time, 'yyyymmdd'))
                        eta = datestr(eta_date, 'HH:MM:SS');
                    else
                        eta = datestr(eta_date, 'dddd HH:MM');
                    end
                    
                    waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Printing. Done around %s.', eta));
                end
            end
        end
    end
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
    STL.print.armed = false;
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    
    % Reset just the XY plane to the starting point (NOT Z!)
    motorHold(handles, 'resetXY');
    
    if ~STL.logistics.simulated
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
    end
    toc;
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    if get(handles.focusWhenDone, 'Value')
        hSI.startFocus();
    end
end




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


function printpowerpercent_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.power = str2double(get(hObject, 'String')) / 100;
    STL.print.power = min(max(STL.print.power, 0.01), 1);
    set(hObject, 'String', sprintf('%d', round(100*STL.print.power)));
end


function printpowerpercent_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function powertest_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    
    %if isfield(STL, 'file') & ~isempty(STL.file) & STL.print.voxelise_needed
    %    voxelise(handles, 'print');
    %else
    %    STL.print.zoom_best = STL.print.zoom;
    %end
    
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    
    gridx = 1;
    gridy = 1;
    gridn = gridx * gridy;
    low = str2double(get(handles.powertest_start, 'String'));
    high = str2double(get(handles.powertest_end, 'String'));
    
    if strcmp(handles.powertest_spacing.SelectedObject.String, 'Log')
        pow_incr = (high/low)^(1/((gridn)-1));
        powers = (low) * pow_incr.^[0:(gridn)-1];
        powers(end) = high; % In case roundoff error resulted in 100.0000001
    else
        powers = linspace(low, high, gridn);
    end
    
    sx = 1/gridx;
    sy = 1/gridy;
    bufferx = 0.025;
    buffery = 0.01;
    
    % A bunch of stuff needs to be set up for this. Should undo it all later!
    oldBeams = hSI.hBeams;
    hSI.hBeams.powerBoxes = hSI.hBeams.powerBoxes([]);
    
    
    for i = 1:gridy
        for j = 1:gridx
            ind = j+gridx*(i-1);
            
            pb.rect = [sx*(j-1)+bufferx sy*(i-1)+buffery sx-2*bufferx sy-2*buffery];
            pb.powers = powers(ind);
            pb.name = sigfig(powers(ind), 2);
            pb.oddLines = 1;
            pb.evenLines = 1;
            
            hSI.hBeams.powerBoxes(ind) = pb;
        end
    end
    
    % 100 microns high
    nframes = 100 / STL.print.zstep;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    
    motorHold(handles, 'on');

    hSI.startLoop();
    
    % Clean up
    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    hSI.hBeams.enablePowerBox = false;
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    motorHold(handles, 'resetZ');
    
    if get(handles.focusWhenDone, 'Value')
        hSI.startFocus();
    end
end



function powertest_start_Callback(hObject, eventdata, handles)
end


function powertest_start_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function powertest_end_Callback(hObject, eventdata, handles)
end


function powertest_end_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function powertest_spacing_lin_Callback(hObject, eventdata, handles)
end


function build_x_axis_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    
    STL.print.xaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.zaxis = setdiff([1 2 3], STL.print.xaxis);
        STL.print.zaxis = STL.print.zaxis(1);
    end
    update_dimensions(handles);
end

function build_x_axis_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function build_z_axis_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    
    STL.print.valid = 0;
    STL.print.zaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.xaxis = setdiff([1 2 3], STL.print.zaxis);
        STL.print.xaxis = STL.print.xaxis(1);
    end
    update_dimensions(handles);
end


function build_z_axis_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', {'x', 'y', 'z'});
end



function setFastZ_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end



function fastZhomePos_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.fastZhomePos = str2double(get(hObject, 'String'));
end


function fastZhomePos_CreateFcn(hObject, eventdata, handles)
    global STL;
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


%function fastZlower_Callback(hObject, eventdata, handles)
%    global STL;
%    hSI = evalin('base', 'hSI');
%    hSI.hFastZ.positionTarget = 420;
%    motorHold(handles, 'reset');
%end


function invert_z_Callback(hObject, eventdata, handles)
    global STL;
    
    set(handles.messages, 'String', 'Inverting Z...');
    
    STL.print.invert_z = get(hObject, 'Value');
    
    STL.print.rescale_needed = true;
    STL.preview.rescale_needed = true;
    update_3d_preview(handles);
    set(handles.messages, 'String', '');
end

function crushThing_Callback(hObject, eventdata, handles)
    hSI = evalin('base', 'hSI');
    motorHold(handles, 'resetZ');
end



function size1_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 1, foo);
    end
end

function size1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function size2_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 2, foo);
    end
end

function size2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end




function size3_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    foo = str2double(get(hObject, 'String'));
    if foo > 0
        update_dimensions(handles, 3, foo);
    end
end

function size3_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% Set STL.print.bounds, either from the callback or from anywhere else.
function UpdateBounds_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if STL.logistics.simulated
        STL.bounds_1(1:2) = [666 666];
        STL.print.bounds_max(1:2) = STL.bounds_1(1:2) / STL.print.zoom_min;
        STL.print.bounds(1:2) = STL.bounds_1(1:2) / STL.print.zoom;
        update_gui(handles);
    elseif isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
        
        % Get bounds at zoom = 1
        hSI.hRoiManager.scanZoomFactor = 1;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.bounds_1([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        % Get bounds at min zoom
        hSI.hRoiManager.scanZoomFactor = STL.print.zoom_min;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.print.bounds_max([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        % Now, how about the user-selected print zoom?
        hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.print.bounds([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        
        hSI.hRoiManager.scanZoomFactor = userZoomFactor;
        update_gui(handles);
    end
end



function whichBeam_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.whichBeam = get(hObject, 'Value');
end

function whichBeam_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function minGoodZoom_Callback(hObject, eventdata, handles)
    global STL;
    contents = cellstr(get(hObject,'String'));
    STL.print.zoom_min = str2double(contents{get(hObject, 'Value')});
    
    if STL.print.zoom < STL.print.zoom_min
        STL.print.zoom = STL.print.zoom_min;
    end
    
    possibleZooms = STL.print.zoom_min:0.1:6;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
        
        % Allows user choice of zoom to remain unchanged despite the indexing for this widget
        if abs(STL.print.zoom - possibleZooms(i)) < 1e-15
            zoomVal = i;
        end
    end
    
    STL.print.voxelise_needed = true;
    set(handles.printZoom, 'String', foo, 'Value', zoomVal);
    
    UpdateBounds_Callback(hObject, eventdata, handles);
end

function minGoodZoom_CreateFcn(hObject, eventdata, handles)
    % These are just some allowed values. Need 1 sigfig, so just add likely
    % candidates manually... Could do it more cleverly!
    possibleZooms = 1:0.1:2;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end


function printZoom_Callback(hObject, eventdata, handles)
    global STL;
    
    contents = cellstr(get(hObject,'String'));
    STL.print.zoom = str2double(contents{get(hObject, 'Value')});
    
    STL.print.voxelise_needed = true;
    
    UpdateBounds_Callback(hObject, eventdata, handles);
end

function printZoom_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    global STL;
    possibleZooms = 1:0.1:4;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%g', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end


function voxelise_preview_button_Callback(hObject, eventdata, handles)
    %update_dimensions(handles);
    zslider_Callback([], [], handles);
    update_3d_preview(handles);
end


function crushReset_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    STL.motors.mom.tmp_origin = move('mom');
    STL.motors.hex.tmp_origin = hexapod_get_position_um();
    STL.print.motor_reset_needed = false;
    set(handles.crushThing, 'BackgroundColor', 0.94 * [1 1 1]);
    set(handles.messages, 'String', '');
end


function abort_Callback(hObject, eventdata, handles)
    global STL;
    STL.logistics.abort = true;
end



function show_metavoxel_slice_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.preview.show_metavoxel_slice = str2num(get(handles.show_metavoxel_slice, 'String'));
    zslider_Callback([], [], handles);
end

function show_metavoxel_slice_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function voxelise_print_button_Callback(hObject, eventdata, handles)
    global STL;
    global wbar;
    
    voxelise(handles, 'print');
    if STL.logistics.abort
        STL.logistics.abort = false;
        set(handles.messages, 'String', 'Canceled.');
        set(handles.show_metavoxel_slice, 'String', 'NaN');
        
        return;
    end
    set(handles.show_metavoxel_slice, 'String', '1 1 1');
    STL.preview.show_metavoxel_slice = [1 1 1];
    zslider_Callback([], [], handles);
end


function test_linearity_Callback(varargin)
    global STL;
    global wbar;
    hSI = evalin('base', 'hSI');
    
    handles = guidata(gcbo);
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents your test.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.motor_reset_needed
        set(handles.messages, 'String', 'CRUSH THE THING!!! Reset lens position before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    hexapos = hexapod_get_position_um();
    if any(abs(hexapos(1:3)) > 0.001)
        set(handles.messages, 'String', 'Hexapod position is [%s ], not [ 0 0 0 ]. Please fix that first');
        return;
    else
        set(handles.messages, 'String', '');
    end

    STL.motors.mom.tmp_origin = move('mom');
    STL.motors.hex.tmp_origin = hexapod_get_position_um();
    eval(sprintf('motor = STL.motors.%s', STL.motors.stitching));
    
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    
    hSI.hRoiManager.scanZoomFactor = 6;
    userPower = hSI.hBeams.powers;
    hSI.hBeams.powers = 1.3;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    % A bunch of stuff needs to be set up for this. Should undo it all later!
    oldBeams = hSI.hBeams;
    hSI.hBeams.powerBoxes = hSI.hBeams.powerBoxes([]);
    
    ind = 1;
    %pb.rect = [0.46 0.46 0.08 0.08];
    pb.rect = [0.9 0.46 0.08 0.08];
    pb.powers = STL.print.power * 100;
    pb.name = 'hi';
    pb.oddLines = 1;
    pb.evenLines = 1;
    
    hSI.hBeams.powerBoxes(ind) = pb;
    
    nframes = 36;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    motorHold(handles, 'on');
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    drawnow;
    
    [X Y] = meshgrid(0:1000:4000, 0:1000:4000);
    posns = [X(1:end) ; Y(1:end)];
    %rng(1234);
    
    metavoxel_counter = 0;
    metavoxel_total = prod(size(X));
    start_time = datetime('now');
    eta = 'next weekend';

        
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Printing...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    
    %posns = posns(:, randperm(prod(size(X))));
    posns = posns';
    
    STL.motors.hex.C887.VLS(1);

    for xy = 1:size(posns, 1)
        if STL.logistics.abort
            % The caller has to unset STL.logistics.abort
            % (and presumably return).
            disp('Aborting due to user.');
            move('hex', [ 0 0 ], 20);
            if ishandle(wbar) & isvalid(wbar)
                STL.logistics.wbar_pos = get(wbar, 'Position');
                delete(wbar);
            end
            if exist('handles', 'var');
                set(handles.messages, 'String', 'Canceled.');
                drawnow;
            end
            STL.logistics.abort = false;
            
            STL.print.armed = false;
            hSI.hStackManager.numSlices = 1;
            hSI.hFastZ.enable = false;
            hSI.hBeams.enablePowerBox = false;
            hSI.hRoiManager.scanZoomFactor = 1;
            hSI.hBeams.powers = userPower;
            if ~STL.logistics.simulated
                while ~strcmpi(hSI.acqState,'idle')
                    pause(0.1);
                end
            end
                    
            break;
        end
        
        

        newpos = posns(xy, :) + motor.tmp_origin(1:2);

        move(STL.motors.stitching, newpos, 2);
        
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
        
        hSI.startLoop();
        while ~strcmpi(hSI.acqState, 'idle')
            pause(0.1);
        end
        
        metavoxel_counter = metavoxel_counter + 1;
        if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
            current_time = datetime('now');
            eta_date = start_time + (current_time - start_time) / (metavoxel_counter / metavoxel_total);
            if strcmp(datestr(eta_date, 'yyyymmdd'), datestr(current_time, 'yyyymmdd'))
                eta = datestr(eta_date, 'HH:MM:SS');
            else
                eta = datestr(eta_date, 'dddd HH:MM');
            end
            
            waitbar(metavoxel_counter / metavoxel_total, wbar, sprintf('Printing. Done around %s.', eta));
        end
        
    end
    
    % Clean up
    hSI.hBeams.enablePowerBox = false;
    hSI.hRoiManager.scanZoomFactor = 1;
    hSI.hBeams.powers = userPower;
    motorHold(handles, 'resetXYZ');
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
end


function lockAspectRatio_Callback(hObject, eventdata, handles)
end


function preview_Callback(hObject, eventdata, handles)
    add_preview(handles);
end

function LoadState_Callback(varargin)
    global STL;
    
    % Some things should not be overwritten by the restored state:
    simulated = STL.logistics.simulated;
    STLmotors = STL.motors;
    
    
    [FileName,PathName] = uigetfile('*.mat');
    
    if isequal(FileName, 0)
        return;
    end
    
    load(strcat(PathName, FileName));
    
    % Restore the current stuff:
    STL.logistics.simulated = simulated;
    STL.motors = STLmotors;
    
    % Pull Y axis voxels from loaded file:
    hSI.hRoiManager.linesPerFrame = STL.print.resolution(2);
    % No need to pull zoom from loaded file, since the selected zoom is
    % stored in the STL, and ScanImage will be informed of it when printing
    % starts... I hope... (?)
    % hSI.hRoiManager.scanZoomFactor = 2.2; % define

    handles = guidata(gcbo);
    STLfile = strcat(PathName, FileName);
    update_gui(handles);
    update_3d_preview(handles);
    draw_slice(handles, get(handles.zslider, 'Value'));
end

function SaveState_Callback(varargin)
    global STL;
    uisave('STL', 'CurrentSTL');
end



function z_step_Callback(hObject, eventdata, handles)
    global STL;
    
    temp = str2double(get(hObject, 'String'));
    temp = floor(10*temp)/10;
    if (temp<0.1)
        temp = 0.1;
    elseif (temp > 10)
        temp = 10;
    end
    
    STL.print.zstep = temp;
    STL.print.voxelise_needed = true;
    set(hObject, 'String', num2str(temp,2));
    
end

function z_step_CreateFcn(hObject, eventdata, handles)
    global STL;
    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end



function search_Callback(hObject, eventdata, handles)
    global STL;
    global wbar;
    hSI = evalin('base', 'hSI');
    
    % Save user zoom factor. But at the end, should we restore it? Perhaps
    % not...
    if STL.logistics.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
    hSI.hRoiManager.scanZoomFactor = 1;
    
    if strcmpi(hSI.acqState, 'idle')
        hSI.startFocus();
    end
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        waitbar(0, wbar, 'Searching...', 'CreateCancelBtn', 'cancel_button_callback');
    else
        wbar = waitbar(0, 'Searching...', 'CreateCancelBtn', 'cancel_button_callback');
        set(wbar, 'Units', 'Normalized');
        wp = get(wbar, 'Position');
        wp(1:2) = STL.logistics.wbar_pos(1:2);
        set(wbar, 'Position', wp);
        drawnow;
    end
    
    positions = [];
    
    search_start_pos = hSI.hMotors.motorPosition;
    disp(sprintf('Search starting at [%d %d]', search_start_pos(1), search_start_pos(2)));
    
    motorFastMotionThreshold = Inf;
    stepsize_x = [500 0 0];
    stepsize_y = [0 500 0];
    direction = 1;
    nsteps_needed = 1;
    radius = 0;
    max_radius = 3000; % microns. Approximate due to laziness!
    
    while radius <= max_radius
        
        for nsteps_so_far_this_leg = 1:nsteps_needed
            if STL.logistics.abort
                if ishandle(wbar) & isvalid(wbar)
                    STL.logistics.wbar_pos = get(wbar, 'Position');
                    delete(wbar);
                end
                if exist('handles', 'var');
                    set(handles.messages, 'String', 'Stopped.');
                    drawnow;
                end
                STL.logistics.abort = false;
                return;
            end
            
            move('mom', hSI.hMotors.motorPosition + direction * stepsize_x);
            radius = sqrt(sum((hSI.hMotors.motorPosition(1:2) - search_start_pos(1:2)).^2));
            if radius >= max_radius
                break;
            end
            pause(0.3);
        end
        
        for nsteps_so_far_this_leg = 1:nsteps_needed
            if STL.logistics.abort
                if ishandle(wbar) & isvalid(wbar)
                    STL.logistics.wbar_pos = get(wbar, 'Position');
                    delete(wbar);
                end
                if exist('handles', 'var');
                    set(handles.messages, 'String', 'Stopped.');
                    drawnow;
                end
                STL.logistics.abort = false;
                return;
            end
            
            move('mom', hSI.hMotors.motorPosition + direction * stepsize_y);
            radius = sqrt(sum((hSI.hMotors.motorPosition(1:2) - search_start_pos(1:2)).^2));
            if radius >= max_radius
                break;
            end
            pause(0.3);
        end
        
        %scatter(positions(1,:), positions(2,:), 'Parent', handles.axes2);
        %set(handles.axes2, 'XLim', search_start_pos(1)+[-max_radius max_radius]*1.4, 'YLim', search_start_pos(2)+[-max_radius max_radius]*1.4);
        %drawnow;
        
        pos = hSI.hMotors.motorPosition;
        
        nsteps_needed = nsteps_needed + 1;
        direction = -direction;
    end
    
    if exist('handles', 'var');
        set(handles.messages, 'String', sprintf('Search radius limit %d um exceeded: r = %s um.', max_radius, sigfig(radius)));
        drawnow;
    end
    
    if ishandle(wbar) & isvalid(wbar)
        STL.logistics.wbar_pos = get(wbar, 'Position');
        delete(wbar);
    end
    
end

% This is used to calibrate the MOM-understage positions at 0.
function set_stage_true_rotation_centre_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    STL.motors.mom.understage_centre = hSI.hMotors.motorPosition;
    set(handles.messages, 'String', sprintf('Maybe add ''STL.motors.mom.understage_centre = [%s ]'' to your config.', ...
        sprintf(' %d', STL.motors.mom.understage_centre)));
end


% If the underlying object is rotated, we can servo to its new location (if
% we know the centre of rotation (see set_stage_rotation_centre_Callback).
function track_rotation_Callback(hObject, eventdata, handles)
    angle_deg = str2double(get(hObject, 'String'));
    track_rotation(handles, angle_deg);
end

function track_rotation(handles, angle_deg)
    global STL;
    hSI = evalin('base', 'hSI');
    
    if ~isfield(STL.logistics, 'stage_centre') | isempty(STL.motors.mom.understage_centre)
        set(handles.messages, 'String', 'No stage rotation centre set. Do that first.');
        return;
    end
    
    % Always rotate about the current position!
    pos = hSI.hMotors.motorPosition(1:2);
    pos_relative = pos - STL.motors.mom.understage_centre(1:2);
    
    r = pi*angle_deg/180;
    rm(1:2,1:2) = [cos(r) sin(r); -sin(r) cos(r)];
    pos_relative = pos_relative * rm;
    try
        set(handles.messages, 'String','');
        set(handles.rotate_infinite_textbox, 'String', '');
        move('mom', pos_relative + STL.motors.mom.understage_centre(1:2));
    catch ME
        ME
        set(handles.messages, 'String', 'The stage is not ready. Slow down!');
        rethrow(ME);
    end
end

function track_rotation_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function focusWhenDone_Callback(hObject, eventdata, handles)
end


function clean_shutdown(varargin)
    global STL;
    global wbar;
        
    try
        hSI = evalin('base', 'hSI');
        hSI.hRoiManager.scanZoomFactor = 1;
    end
    
    try
        fclose(STL.motors.rot.esp301);
    end
    
    %try
        hexapod_pi_disconnect();
    %end
    
    try
        delete(wbar);
    end
    
    clear -global STL;
    
    delete(gcf);
end


function hexapod_reset_to_centre(varargin)
    global STL;
    
    if ~STL.motors.hex.connected
        return;
    end
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end

    STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
    STL.motors.hex.C887.MOV('x y z u v w', [0 0 0 0 0 0]);
    hexapod_wait(handles);
    update_gui(handles);
end



function hexapod_rotate_x_Callback(hObject, eventdata, handles)
    global STL;
    
    hexapod_wait();
    %hexapod_set_rotation_centre_Callback();
    try
        %set(handles.messages, 'String', sprintf('Rotating U to %g', get(hObject, 'Value') * STL.motors.hex.range(4, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end
    catch ME
        set(handles.messages, 'String', 'Set the virtual rotation centre first.');
        return;
    end
    
    try
        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('U', get(hObject, 'Value') * STL.motors.hex.range(4, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_y_Callback(hObject, eventdata, handles)
    global STL;

    hexapod_wait();

    %hexapod_set_rotation_centre_Callback();
    try
        %set(handles.messages, 'String', sprintf('Rotating V to %g', get(hObject, 'Value') * STL.motors.hex.range(5, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end
        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('V', get(hObject, 'Value') * STL.motors.hex.range(5, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_z_Callback(hObject, eventdata, handles)
    global STL;
    
    %hexapod_set_rotation_centre_Callback();
    hexapod_wait();

    try
        %set(handles.messages, 'String', sprintf('Rotating W to %g', get(hObject, 'Value') * STL.motors.hex.range(6, 2)));
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:8), 'rotation')
            STL.motors.hex.C887.KEN('rotation');
        end

        STL.motors.hex.C887.VLS(STL.motors.hex.user_rotate_velocity);
        STL.motors.hex.C887.MOV('W', get(hObject, 'Value') * STL.motors.hex.range(6, 2));
    catch ME
        set(handles.messages, 'String', 'Given the hexapod''s state, that position is unavailable.');
        update_gui(handles);
    end
    hexapod_wait();
end

function hexapod_rotate_x_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function hexapod_rotate_y_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function hexapod_rotate_z_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

% During a drag of the slider, show the rotation angle that will be used if the drag ends now. This is for infinite-rotation
% devices (e.g. the esp301).
function rotate_by_slider_show_Callback(hObject, eventdata, handles)
    spos = get(handles.rotate_infinite_slider, 'Value');
    sscaled = sign(spos) * 90^abs(spos);
    set(handles.rotate_infinite_textbox, 'String', sprintf('%.3g', sscaled));
end

% Do the actual rotation when the drag ends. For infinite-rotation devices (currently just the esp301).
function rotate_infinite_slider_Callback(hObject, eventdata, handles)
    global STL;
    
    spos = get(hObject, 'Value');
    rotangle = sign(spos) * 90^abs(spos);
    set(handles.rotate_infinite_textbox, 'String', sprintf('Target: %.3g', rotangle));
    set(handles.rotate_infinite_slider, 'Value', 0);
    
    moveto_rel(STL.motors.rot.esp301, 3, -rotangle);
    track_rotation(handles, rotangle);
end


function rotate_infinite_slider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function hexapod_zero_angles_Callback(hObject, eventdata, handles)
    hexapod_reset_to_zero_rotation(handles);
end

% Set the virtual rotation centre to the point under the microscope lens.
% This is based on STL.motors.mom.understage_centre (MOM's coordinates when
% aligned to hexapod's true centre).
function hexapod_set_rotation_centre_Callback(varargin)
    global STL;
    hSI = evalin('base', 'hSI');
    
    head_position_rel = hSI.hMotors.motorPosition - STL.motors.mom.understage_centre;
    head_position_rel = head_position_rel * STL.motors.mom.coords_to_hex;
    head_position_rel(3) = STL.motors.hex.pivot_z_um;
    new_pivot_mm = head_position_rel / 1e3;
    %new_pivot_mm = [0 0 0];
    
    new_pivot_mm = new_pivot_mm .* [-1 -1 1];
    
    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end
    
    try
        STL.motors.hex.C887.KSD('rotation', 'x y z', new_pivot_mm);
    catch ME
        rethrow(ME);
    end
end


function add_bullseye_Callback(hObject, eventdata, handles)
    add_bullseye();
end

function align_stages(hObject, eventdata, handles);
    global STL;
    hSI = evalin('base', 'hSI');
    
    % FIXME (2) make sure the hexapod is in the right coordinate system:
    % should be in the Leveling system, (1) reset rotation coordinate
    % system to 0, (3) centre/zero it.

    STL.motors.hex.C887.KSD('rotation', 'X Y Z', [0 0 STL.motors.hex.pivot_z_um / 1e3]);

    [~, b] = STL.motors.hex.C887.qKEN('');
    if ~strcmpi(b(1:5), 'LEVEL')
        hexapod_wait();
        STL.motors.hex.C887.KEN('ZERO');
    end
    hexapod_wait();
    move('hex', [0 0 0 0 0 0], 10);
    hexapod_wait();
    
    handles = guidata(gcbo);
    add_bullseye();
    
    hexapod_reset_to_zero_rotation(handles);

    STL.motors.hex.C887.SPI('X Y Z', [0 0 0]);
end


function hexapod_zero_pos_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    hexapod_wait();
    STL.motors.hex.C887.MOV('X Y Z', [0 0 0]);
end


function calibrate_vignetting_Callback(hObject, eventdata)
        hSI = evalin('base', 'hSI');
        global STL;
        
        handles = guihandles(hObject);
        
        if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
            set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
            return;
        else
            set(handles.messages, 'String', '');
        end
        
        set(handles.messages, 'String', 'Taking snapshot of current view...'); drawnow;
        
        hSI.hStackManager.framesPerSlice = 100;
        hSI.hScan2D.logAverageFactor = 100;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logFileStem = 'vignetting_cal';
        hSI.hScan2D.logFileCounter = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
            
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end

        hSI.hStackManager.framesPerSlice = 1;
        hSI.hChannels.loggingEnable = false;
        
        set(handles.messages, 'String', 'Computing fit...'); drawnow;
        
        % Left over from when this was a dropdown on the UI:
        % methods = cellstr(get(handles.vignetting_fit_method, 'String'));
        % method = methods{get(handles.vignetting_fit_method, 'Value')};
        method = 'interpolant';

        STL.calibration.vignetting_fit = fit_vignetting_falloff('vignetting_cal_00001_00001.tif', method, STL.bounds_1(1), handles);
        % Left over for when this was a checkbox
        %set(handles.vignetting_compensation, 'Value', 1, 'ForegroundColor', [0 0 0], ...
        %    'Enable', 'on');
        %STL.print.vignetting_compensation = get(handles.vignetting_compensation, 'Value');

        s = get(handles.slide_filename_series, 'String');
        if ~strcmp(s, 'Series')
            copyfile('vignetting_cal_00001_00001.tif', sprintf('vignetting_cal_%s.tif', s));
        end
        
        set(handles.messages, 'String', '');
        
end


function vignetting_compensation_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.print.vignetting_compensation = get(hObject, 'Value');
end


function vignetting_fit_method_Callback(hObject, eventdata, handles)
    
end

function vignetting_fit_method_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% Measure brightness of an object by sliding the object over the lens and
% taking a video.
function measure_brightness_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
    
    
    if ~STL.logistics.simulated & ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents calibrating.');
        return;
    else
        set(handles.messages, 'String', '');
    end
        
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos - str2double(get(handles.brightness_height, 'String'));

    desc = sprintf('%s_%s', get(handles.slide_filename, 'String'), get(handles.slide_filename_series, 'String'));
    
    
    hSI.hFastZ.enable = 0;
    hSI.hStackManager.numSlices = 1;
    
    xc = STL.print.voxelpos_wrt_fov{1,1,1}.x;
    yc = STL.print.voxelpos_wrt_fov{1,1,1}.y;
    p = STL.print.voxelpower_adjustment;
    save(sprintf('slide_%s_adj', desc), 'xc', 'yc', 'p');

    if true
        %% First: take a snapshot.
        set(handles.messages, 'String', 'Taking snapshot of current view...');
        
        hSI.hStackManager.framesPerSlice = 100;
        hSI.hScan2D.logAverageFactor = 100;
        hSI.hChannels.loggingEnable = true;
        hSI.hScan2D.logFramesPerFileLock = true;
        hSI.hScan2D.logFileStem = sprintf('slide_%s_image', desc);
        hSI.hScan2D.logFileCounter = 1;
        hSI.hRoiManager.scanZoomFactor = 1;
        
        if ~STL.logistics.simulated
            hSI.startGrab();
            
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end
        
        hSI.hScan2D.logAverageFactor = 1;
        hSI.hStackManager.framesPerSlice = 1;
        hSI.hChannels.loggingEnable = false;
    end
    
    
    % If the hexapod is in 'rotation' coordinate system,
    % wait for move to finish and then switch to 'ZERO'.
    if STL.motors.hex.connected
        [~, b] = STL.motors.hex.C887.qKEN('');
        if ~strcmpi(b(1:5), 'LEVEL')
            hexapod_wait();
            STL.motors.hex.C887.KEN('ZERO');
        end
    end

    % Positions for the sliding measurements:
    pos = hexapod_get_position_um();
    left = pos; left(1) = left(1) - 500;
    right = pos; right(1) = right(1) + 500;
    bottom = pos; bottom(2) = bottom(2) - 500;
    top = pos; top(2) = top(2) + 500;

    %% Measure brightness along X axis
    
    % This should be in the base leveling coordinate system
    

    move('hex', left, 1);
    set(handles.messages, 'String', 'Sliding along current view...');

    scanspeed = 0.1; % mm/s
    % Time taken for the scan will be 666 um / 100 um/s; frame rate is
    % 15.21 Hz (can't figure out where that is in hSI, but somewhere...)
    scantime = STL.bounds_1(1) / (scanspeed * 1000);
    scanframes = ceil(scantime * 25);
    hSI.hStackManager.framesPerSlice = scanframes;
    hSI.hChannels.loggingEnable = true;
    hSI.hScan2D.logFramesPerFileLock = true;
    hSI.hScan2D.logAverageFactor = 1;
    hSI.hRoiManager.scanZoomFactor = 1;
    hSI.hScan2D.logFileStem = sprintf('slide_%s_x', desc);
    hSI.hScan2D.logFileCounter = 1;

    if ~STL.logistics.simulated
        hSI.startGrab();
    end
    
    move('hex', right, scanspeed);
    
    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    
    %% Measure brightness along y axis
        
    move('hex', top, 1);
    
    hSI.hScan2D.logFileStem = sprintf('slide_%s_y', desc);
    hSI.hScan2D.logFileCounter = 1;
    if ~STL.logistics.simulated
        hSI.startGrab();
    end
    
    move('hex', bottom, scanspeed);

    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end
    
    move('hex', pos, 1);


    hSI.hStackManager.framesPerSlice = 1;
    hSI.hChannels.loggingEnable = false;
    
    if false
        set(handles.messages, 'String', 'Processing...');
        tiffx = [];
        i = 0;
        try
            while true
                i = i + 1;
                tiffx(i,:,:) = imread(sprintf('slide_%s_x_00001_00001.tif', desc), i);
            end
        catch ME
        end
        tiffx = double(tiffx);
        middle = round(size(tiffx, 3)/2);
        n = 100;
        if ~isempty(tiffx)
            figure(16);
            subplot(1,2,1);
            plot(mean(tiffx(:, middle-n:middle+n, middle), 2));
            title('X axis brightness');
            set(gca, 'XLim', [0 size(tiffx, 1)]);
        end
        
        tiffy = [];
        i = 0;
        try
            while true
                i = i + 1;
                tiffy(i,:,:) = imread(sprintf('slide_%s_y_00001_00001.tif', desc), i);
            end
        catch ME
        end
        tiffy = double(tiffy);
        if ~isempty(tiffy)
            subplot(1,2,2);
            plot(mean(tiffy(:, middle, middle-n:middle+n), 3));
            title('Y axis brightness');
            set(gca, 'XLim', [0 size(tiffy, 1)]);
        end
    end
    set(handles.messages, 'String', '');
        
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
end



function slide_filename_Callback(hObject, eventdata, handles)
end

function slide_filename_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function centre_mom_Callback(hObject, eventdata, handles)
    global STL;
    set(handles.vignetting_compensation, 'Value', 1, 'ForegroundColor', [0 0 0], ...
        'Enable', 'on');
    move('mom', STL.motors.mom.understage_centre(1:2));
end


function slide_filename_series_Callback(hObject, eventdata, handles)
end

function slide_filename_series_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function brightness_height_Callback(hObject, eventdata, handles)
end

function brightness_height_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function level_slide_Callback(hObject, eventdata, handles)
    global STL;
    STL.motors.hex.C887.MOV('u v', STL.motors.hex.slide_level(4:5));
end
