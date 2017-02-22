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
    
    % Last Modified by GUIDE v2.5 22-Feb-2017 16:47:07
    
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
    
    clear global -regexp STL;
    global STL;
    
    try
        hSI = evalin('base', 'hSI');
        STL.simulated = false;
        hSI.hDisplay.roiDisplayEdgeAlpha = 0.1;
    catch ME
        STL.simulated = true;
        hSI.simulated = true;
        hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B = 150;
        hSI.hRoiManager.linesPerFrame = 256;
        hSI.hRoiManager.imagingFovUm = [-200 -200; 0 0; 200 200];
        hSI.hScan_ResScanner.fillFractionSpatial = 0.7;
        hSI.hMotors.motorPosition = 10000 * [ 1 1 1 ];
        assignin('base', 'hSI', hSI);
    end
    
    % Some parameters are only computed on grab. So do one.
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    
    STL.print.zstep = 1;     % microns per step in z (vertical)
    STL.print.xaxis = 1;     % axis of raw STL over which the resonant scanner scans
    STL.print.zaxis = 3;     % axis of raw STL over which we print upwards (fastZ etc) 
    STL.print.power = 1;
    STL.print.whichBeam = 1; % if scanimage gets to play with >1 laser...
    STL.print.size = [300 300 300];
    STL.print.zoom_min = 1;
    STL.print.zoom = 1;
    STL.print.armed = false;
    STL.preview.resolution = [120 120 120];
    STL.print.metavoxel_overlap = [10 0 10]; % Microns of overlap (positive is more overlap) in order to get good bonding
    STL.print.voxelise_needed = true;
    STL.preview.voxelise_needed = true;
    STL.print.invert_z = false;
    STL.print.motor_reset_needed = false;
    STL.print.motorOrigin = hSI.hMotors.motorPosition - [0 0 450]; %[10000 9000 0];
    STL.print.fastZhomePos = 450;
    
    STL.logistics.abort = false;
    
    % The Zeiss LCI PLAN-NEOFLUAR 25mm has a nominal working depth of
    % 380um.
    STL.bounds_1 = [NaN NaN 360];
    STL.print.bounds_max = [NaN NaN 360];
    STL.print.bounds = [NaN NaN 360];
    
    if STL.simulated
        foo = -1;
    else
        evalin('base', 'hSI.startGrab()');
        while ~strcmpi(hSI.acqState, 'idle')
            pause(0.1);
        end
        
        for i = 1:length(hSI.hChannels.channelName)
            foo{i} = sprintf('%d', i);
        end
        
        disp(sprintf('Servoing to [ %s]', sprintf('%g ', STL.print.motorOrigin)));
        hSI.hMotors.motorPosition = STL.print.motorOrigin;
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    end
    set(handles.whichBeam, 'String', foo);
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    
    guidata(hObject, handles);
    
    UpdateBounds_Callback([], [], handles);
    
    %hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    %motorHold(handles, 'reset');
    
    if ~STL.simulated
        hSI.hFastZ.setHome(0);
    end
    %warning('Setting pixelsPerLine to 64 for faster testing.');
    %hSI.hRoiManager.pixelsPerLine = 64;
    hSI.hScan2D.bidirectional = false;
    hSI.hScan2D.linePhase = -6e-6;
    
    colormap(handles.axes2, 'gray');
end


function update_gui(handles);
    global STL;
    
    set(handles.build_x_axis, 'Value', STL.print.xaxis);
    set(handles.build_z_axis, 'Value', STL.print.zaxis);
    set(handles.printpowerpercent, 'String', sprintf('%d', round(100*STL.print.power)));
    set(handles.size1, 'String', sprintf('%d', round(STL.print.size(1))));
    set(handles.size2, 'String', sprintf('%d', round(STL.print.size(2))));
    set(handles.size3, 'String', sprintf('%d', round(STL.print.size(3))));
    set(handles.fastZhomePos, 'String', sprintf('%d', round(STL.print.fastZhomePos)));
    set(handles.powertest_start, 'String', sprintf('%g', 1));
    set(handles.powertest_end, 'String', sprintf('%g', 100));
    set(handles.invert_z, 'Value', STL.print.invert_z);
    set(handles.whichBeam, 'Value', STL.print.whichBeam);
    set(handles.PrinterBounds, 'String', sprintf('Metavoxel: [ %s] um', ...
        sprintf('%d ', round(STL.print.bounds))));
    nmetavoxels = ceil(STL.print.size ./ (STL.print.bounds - STL.print.metavoxel_overlap));
    set(handles.nMetavoxels, 'String', sprintf('Metavoxels: [ %s]', sprintf('%d ', nmetavoxels)));
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
        aspect_ratio = STL.aspect_ratio(STL.print.dims);
        if nargin == 1
            dim = 1;
            val = STL.print.size(1);
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
    
    % Preview maintains original dimensions to make it easier to see what's
    % going on
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
    
    STLfile = strcat(PathName, FileName);
    set(hObject, 'String', STLfile);
    updateSTLfile(handles, STLfile);
end



function updateSTLfile(handles, STLfile)
    global STL;
    
    STL.file = STLfile;
    STL.mesh1 = READ_stl(STL.file);
    % This is stupid, but patch() likes this format, so easiest to just read it
    % again.
    STL.patchobj1 = stlread(STL.file);
    
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
    
    %STL.preview.voxelise_needed = true;
    %STL.print.voxelise_needed = true;
    
    %update_3d_preview(handles);
    
    % Draw the slices
    %zslider_Callback(handles.zslider, [], handles);
end




function [] = update_3d_preview(handles);
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
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        close(wbar);
    end
    
    hSI = evalin('base', 'hSI');
    
    if ~STL.simulated & ~strcmpi(hSI.acqState,'idle')
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
    
    if STL.simulated
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
    
    if STL.print.rescale_needed
        rescale_object(handles);
    end
    
    UpdateBounds_Callback([], [], handles);
    
    
    if ~STL.simulated & isempty(fieldnames(hSI.hWaveformManager.scannerAO))
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
    end
    
    
    % This relies on voxelise() being called, above
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom_best;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    hSI.hFastZ.enable = 1;
    %hSI.hStackManager.numSlices = round(STL.print.size(3) / STL.print.zstep);
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
        waitbar(0, wbar, 'Printing...');
    else
        wbar = waitbar(0, 'Printing...');
    end
    
    axis_signs = [ -1 1 -1 ];
    axis_order = [ 2 1 3 ];
    
    metavoxel_counter = 0;
    metavoxel_total = prod(STL.print.nmetavoxels);
    for mvz = 1:STL.print.nmetavoxels(3)
        for mvy = 1:STL.print.nmetavoxels(2)
            for mvx = 1:STL.print.nmetavoxels(1)
                if STL.logistics.abort
                    disp('Aborting due to user.');
                    STL.logistics.abort = false;
                    break;
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
                newpos = newpos .* axis_signs;
                
                % My axes and the motor's may be at odds, so reshuffle the order. This should be done in Machine_Data_File but I
                % don't see how; the docs are a little obsolete (or ahead of the free version?).
                newpos = newpos(axis_order);
                
                % Add the motor origin from the start of this function
                newpos = newpos + STL.print.motorOrigin(1:3);
                
                disp(sprintf(' ...servoing to [%g %g %g]...', newpos));
                % Go to position-x on all dimensions in order to always
                % complete the move in the same direction.
                hSI.hMotors.motorPosition(1:3) = newpos + [1 1 1] * 3;
                pause(0.1);
                hSI.hMotors.motorPosition(1:3) = newpos;
                hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
                pause(0.1);
                
                % 2. Set up printimage_modify_beam with the appropriate
                % voxels
                
                STL.print.voxels = STL.print.metavoxels{mvx, mvy, mvz};
                
                % 3. Set resolution appropriately
                hSI.hStackManager.numSlices = STL.print.metavoxel_resolution{mvx, mvy, mvz}(3);
                
                % 4. Do whatever is necessary to get a blocking
                % startLoop(), like setting up a callback in acqModeDone?
                
                % 5. Print this metavoxel
                if ~STL.simulated
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
                    waitbar(metavoxel_counter / metavoxel_total, wbar);
                end
                
            end
        end
    end
    
    if exist('wbar', 'var') & ishandle(wbar) & isvalid(wbar)
        close(wbar);
    end
    
    STL.print.armed = false;
    hSI.hStackManager.numSlices = 1;
    hSI.hFastZ.enable = false;
    
    motorHold(handles, 'off');
    if ~STL.simulated
        while ~strcmpi(hSI.acqState,'idle')
            pause(0.1);
        end
    end
    toc;
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
end




function motorHold(handles, v);
    % Control motor position-hold-before-reset: 'on', 'off', 'reset'
    global STL;
    hSI = evalin('base', 'hSI');
    
    if strcmp(v, 'on')
        set(handles.crushThing, 'BackgroundColor', [1 0 0]);
        %%%%%% FIXME Disabled! STL.print.FastZhold = true;
        %STL.print.FastZhold = true;
        STL.print.motorHold = true;
        %warning('Disabled fastZ hold hack.');
        STL.print.motor_reset_needed = true;
        STL.print.motorOrigin = hSI.hMotors.motorPosition;
    end
    
    if strcmp(v, 'off')
        STL.print.motorHold = false;
        STL.print.motor_reset_needed = true;
    end
    
    if strcmp(v, 'reset')
        %hSI.hFastZ.goHome; % This takes us to 0 (as I've set it up), which is not what we
        %want.
        hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
        
        if isfield(STL.print, 'motorOrigin')
            disp(sprintf('Servoing to [ %s]', sprintf('%g ', STL.print.motorOrigin)));
            hSI.hMotors.motorPosition = STL.print.motorOrigin;
        end
        
        STL.print.motorHold = false;
        STL.print.motor_reset_needed = false;
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
    
    if STL.simulated
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


    gridx = 2;
    gridy = 2;
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
    
    nframes = 100;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    motorHold(handles, 'on');
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    
    hSI.startLoop();
    
    % Clean up
    while ~strcmpi(hSI.acqState,'idle')
        pause(0.1);
    end

    hSI.hBeams.enablePowerBox = false;  
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    motorHold(handles, 'off');
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
        STL.print.zaxis = setdiff([1 2], STL.print.xaxis);
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
        STL.print.xaxis = setdiff([1 2], STL.print.zaxis);
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
%%    hSI = evalin('base', 'hSI');
%    hSI.hFastZ.positionTarget = 450;
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
    motorHold(handles, 'reset');
end



function size1_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    % Should the dim here really be 1? Or 2?
    update_dimensions(handles, 1, str2double(get(hObject, 'String')));
end

function size1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function size2_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    update_dimensions(handles, 2, str2double(get(hObject, 'String')));
end

function size2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end




function size3_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.rescale_needed = true;
    
    update_dimensions(handles, 3, str2double(get(hObject, 'String')));
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
    
    if STL.simulated
        STL.bounds_1(1:2) = [500 500];
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
    
    possibleZooms = STL.print.zoom_min:0.1:5;
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
    
    STL.print.motorOrigin = hSI.hMotors.motorPosition;
    %STL.print.motor_reset_needed = false;
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
    
    voxelise(handles, 'print');
    set(handles.show_metavoxel_slice, 'String', '1 1 1');
    STL.preview.show_metavoxel_slice = [1 1 1];
    zslider_Callback([], [], handles);
end


function test_button_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    
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
    
    STL.print.motorOrigin = hSI.hMotors.motorPosition;

    if STL.simulated
        userZoomFactor = 1;
    else
        userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    end
        
    hSI.hRoiManager.scanZoomFactor = 1;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
        
    % A bunch of stuff needs to be set up for this. Should undo it all later!
    oldBeams = hSI.hBeams;
    hSI.hBeams.powerBoxes = hSI.hBeams.powerBoxes([]);
    
    ind = 1;
    pb.rect = [0.45 0.45 0.1 0.1];
    pb.powers = STL.print.power * 100;
    pb.name = 'hi';
    pb.oddLines = 1;
    pb.evenLines = 1;
    
    hSI.hBeams.powerBoxes(ind) = pb;
    
    nframes = 100;
    
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
    
    
    for x = 0:100:500
        for y = 0:100:500
            if STL.logistics.abort
                STL.logistics.abort = false;
                hSI.hBeams.enablePowerBox = false;
                hSI.hRoiManager.scanZoomFactor = 1;
                motorHold(handles, 'off');
            end
                        
            newpos = [x y] + STL.print.motorOrigin(1:2);
            disp(sprintf(' ...servoing to [%g %g]...', x, y));
            % Go to position-x on all dimensions in order to always
            % complete the move in the same direction.
            hSI.hMotors.motorPosition(1:2) = newpos + [1 1] * 3;
            pause(0.1);
            hSI.hMotors.motorPosition(1:2) = newpos;
            hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
            pause(0.1);
            
            hSI.startLoop();
            while ~strcmpi(hSI.acqState,'idle')
                pause(0.1);
            end
        end
    end
    
    % Clean up
    hSI.hBeams.enablePowerBox = false;  
    hSI.hRoiManager.scanZoomFactor = 1;
    motorHold(handles, 'off');
    
end
