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
    
    % Last Modified by GUIDE v2.5 06-Feb-2017 15:11:55
    
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
    
    global STL;
    hSI = evalin('base', 'hSI');
    
    % Some parameters are only computed on grab. So do one.
    evalin('base', 'hSI.startGrab()');
    
    STL.print.zstep = 1;     % microns per step
    STL.print.xaxis = 1;
    STL.print.zaxis = 3;
    STL.print.power = 1;
    STL.print.whichBeam = 1;
    STL.print.size = [300 300 300];
    STL.print.min_zoom = 1;
    STL.print.zoom = 1;
    STL.preview.resolution = [120 120 120];
    STL.print.voxelise_needed = true;
    STL.preview.voxelise_needed = true;
    STL.fastZ_reverse = false;
    STL.print.invert_z = false;
    STL.print.fastZ_needs_reset = true;
    if STL.fastZ_reverse
        STL.print.fastZhomePos = 0;
    else
        STL.print.fastZhomePos = 450;
    end
    
    STL.bounds_1 = [NaN NaN 350];
    STL.print.bounds_max = [NaN NaN 350];
    STL.print.bounds = [NaN NaN 350];
    
    for i = 1:length(hSI.hChannels.channelName)
        foo{i} = sprintf('%d', i);
    end
    set(handles.whichBeam, 'String', foo);
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    
    guidata(hObject, handles);
    
    UpdateBounds_Callback([], [], handles);
    
    UpdateBounds_Callback([], [], handles);
    
    %hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    %FastZhold(handles, 'reset');
    
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
    set(handles.PrinterBounds, 'String', sprintf('Metavoxel: [ %s] ?m', ...
        sprintf('%d ', round(STL.print.bounds_max))));
end


function [colour] = colour_limits(thing, bound1, bound2)
    colour = [1 1 1]*0;
    if thing < bound1
        colour = [1 0 0];
    end
    if nargin == 3 & thing > bound2
        colour = [1 0 0];
    end
end


function update_dimensions(handles, dim, val)
    global STL;
    % Recompute all dimensions based on aspect ratio and build axes
    
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    dims = [STL.print.xaxis yaxis STL.print.zaxis];
    
    if isfield(STL, 'aspect_ratio')
        aspect_ratio = STL.aspect_ratio(dims);
        if nargin == 1
            dim = 1;
            val = STL.print.size(1);
        end
        if isfield(STL.print, 'size')
            oldsize = STL.print.size;
        end
        STL.print.size = aspect_ratio/aspect_ratio(dim) * val;
        if ~isfield(STL.print, 'size') | any(STL.print.size ~= oldsize)
            STL.print.voxelise_needed = true;
        end
        update_gui(handles);
    end
    
    STL.print.re_scale_needed = true;
    warning('FIXME: Place a button near the dimensions boxes for re-displaying.');
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
    STL.mesh = READ_stl(STL.file);
    % This is stupid, but patch() likes this format, so easiest to just read it
    % again.
    STL.patchobj1 = stlread(STL.file);
    
    % Position the object at the origin+.
    llim = min(STL.patchobj.vertices);
    STL.patchobj1.vertices = bsxfun(@minus, STL.patchobj1.vertices, llim);
    STL.mesh1 = bsxfun(@minus, STL.mesh, llim);
    
    % Scale into the desired dimensions--in microns--from the origin to
    % positive-everything.
    STL.aspect_ratio = max(STL.patchobj1.vertices);
    
    % Squeeze the object into a unit cube (hence the 1 in the name), for later easier scaling
    STL.patchobj1.vertices = STL.patchobj1.vertices / max(STL.aspect_ratio);
    STL.mesh1 = STL.mesh1 / max(STL.aspect_ratio);
    
    % Aspect ratio is normalised so max is 1
    STL.aspect_ratio = STL.aspect_ratio / max(STL.aspect_ratio);
    
    update_dimensions(handles); % First pass at object dimensions according to aspect ratio
    
    redraw_object(handles);
    
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
    
    % Draw the slices
    zslider_Callback(handles.zslider, [], handles);
end


function [] = rescale_object();
    global STL;
    
    % Relies on STL.print.size for desired dimensions.
    % Stores the result in STL.
    yaxis = setdiff([1 2 3], [STL.print.xaxis STL.print.zaxis]);
    
    STL.print.dims = [STL.print.xaxis yaxis STL.print.zaxis];
    STL.print.aspect_ratio = STL.aspect_ratio(dims);
    
    max_dim = max(STL.print.size);
    
    STL.preview.patchobj = STL.patchobj1;
    STL.preview.patchobj.vertices = STL.patchobj1.vertices * max_dim;
    STL.print.mesh = STL.mesh1(:, STL.print.dims, :) * max_dim;
    
    STL.print.re_scale_needed = false;
    STL.preview.voxelise_needed = true;
    STL.print.voxelise_needed = true;
end



function [] = redraw_object(handles);
    global STL;
    
    if STL.print.re_scale_needed
        rescale_object();
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
    global STL;
    %hSI = evalin('base', 'hSI');
    
    %if exist('hSI', 'var') & isfield(hSI.hWaveformManager.scannerAO, 'ao_samplesPerTrigger')
    %    resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
    %        hSI.hRoiManager.linesPerFrame ...
    %        round(STL.print.size(3) / STL.print.zstep)];
    %    if any(resolution ~= STL.print.resolution)
    %        STL.print.voxelise_needed = true;
    %        STL.preview.voxelise_needed = true;
    %    end
    %end
    
    if STL.preview.voxelise_needed
        voxelise(handles, 'preview');
    end
    
    if get(handles.zslider, 'Max') ~= STL.preview.resolution(3)
        set(handles.zslider, 'Max', STL.preview.resolution(3));
    end
    
    if exist('pos', 'var')
        set(handles.zslider, 'Value', pos*STL.preview.resolution(3));
    end
    
    zind = round(get(handles.zslider, 'Value'));
    zind = max(min(zind, STL.preview.resolution(3)), 1);
    
    draw_slice(handles, zind);
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
    
    
    hSI = evalin('base', 'hSI');
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    if STL.print.fastZ_needs_reset
        set(handles.messages, 'String', 'Reset FastZ before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    % Save home positions. They won't be restored so as not to crush the
    % printed object, but they should be reset later.
    
    %foo = hSI.hFastZ.positionTarget;
    %hSI.hFastZ.positionTarget = 0;
    %pause(0.1);
    %hSI.hMotors.zprvResetHome();
    %hSI.hBeams.zprvResetHome();
    %hSI.hFastZ.positionTarget = foo;
    
    
    % Set the zoom factor for highest resolution:
    %if ~isfield(STL, 'print') | ~isfield(STL.print, 'ResScanResolution')
    % If no acquisition has been run yet, run one. THIS DOESN'T WORK.
    %if isempty(fieldnames(hSI.hWaveformManager.scannerAO))
    %    % Get ScanImage to compute the resonant scanner's resolution
    %    evalin('base', 'hSI.startGrab()');
    %end
    %STL.print.ResScanResolution = hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B;
    %end
    
    STL.print.metavoxel_shift
    
    if isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        update_dimensions(handles); % In case the boundaries are newly available
    end
    
    % Make sure we haven't changed the desired resolution or anything else that
    % ScanImage can change without telling us. This should be a separate
    % function eventually!
    resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        round(STL.print.size(3) / STL.print.zstep)];
    if any(resolution ~= STL.print.resolution)
        STL.print.voxelise_needed = true;
    end
    
    
    UpdateBounds_Callback([], [], handles);
    fov_ranges = STL.print.bounds_max;
    if fov_ranges(1) ~= fov_ranges(2)
        warning('FOV is not square. You could try rotating the object.');
    end
    
    userZoomFactor = hSI.hRoiManager.scanZoomFactor;
    
    
    if STL.print.voxelise_needed
        voxelise(handles, 'print');   
    end
    
    % This relies on voxelise() being called, above
    hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
    
    % Number of slices at 1 micron per slice:
    hSI.hScan2D.bidirectional = false;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.numSlices = round(STL.print.size(3) / STL.print.zstep);
    if STL.fastZ_reverse
        hSI.hStackManager.stackZStepSize = STL.print.zstep;
    else
        hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    end
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false;
    %hSI.hStackManager.stackZStartPos = 0;
    %hSI.hStackManager.stackZEndPos = NaN;
    FastZhold(handles, 'on');
    tic
    STL.print.armed = true;
    
    % The main printing loop. How to manage the non-blocking call to
    % startLoop()?
    
    startPos = hSI.hMotors.motorPosition;
    
    for mvx = 1:STL.print.nmetavoxels(1)
        for mvy = 1:STL.print.nmetavoxels(2)
            for mvz = 1:STL.print.nmetavoxels(3)
                
                % 1. Servo the slow stage to the correct starting position. This is convoluted
                % because (1) startPos may be 1x3 or 1x4, (2) we always want to approach from the
                % same side
                hSI.hMotors.motorPosition(1:3) = startPos(1:3) + STL.print.metavoxel_shift * ([mvx mvy mvz] - 1);
                disp(sprintf('Servoing to [%g %g %g]...', STL.print.metavoxel_shift * [mvx mvy mvz] - 1));
                
                % 2. Set up printimage_modify_beam with the appropriate
                % voxels
                
                STL.print.voxels = STL.print.metavoxels{mvx, mvy, mvz};
                
                % 3. Do whatever is necessary to get a blocking
                % startLoop(), like setting up a callback in acqModeDone?
                
                % 4. Print this metavoxel
                evalin('base', 'hSI.startLoop()');
                
                % 5. Await callback from the user function "acqModeDone" or "acqAbort"? Or
                % constantly poll... :(
                while ~strcmpi(hSI.acqState,'idle')
                    pause(0.1);
                end
            end
        end
    end
    
    
    STL.print.armed = false;
    
    FastZhold(handles, 'off');
    toc
    hSI.hRoiManager.scanZoomFactor = userZoomFactor;
    
    zslider_Callback([], [], handles);
end




function FastZhold(handles, v);
    % Control FastZ position-hold-before-reset: 'on', 'off', 'reset'
    global STL;
    hSI = evalin('base', 'hSI');
    
    if strcmp(v, 'on')
        set(handles.fastZhome, 'BackgroundColor', [1 0 0]);
        %%%%%% FIXME Disabled! STL.print.FastZhold = true;
        warning('Disabled fastZ hold hack.');
        STL.print.fastZ_needs_reset = true;
    end
    
    if strcmp(v, 'off')
        STL.print.FastZhold = false;
        STL.print.fastZ_needs_reset = true;
    end
    
    if strcmp(v, 'reset')
        STL.print.FastZhold = false;
        hSI.hFastZ.goHome;
        STL.print.fastZ_needs_reset = false;
        set(handles.fastZhome, 'BackgroundColor', 0.94 * [1 1 1]);
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
    
    if STL.print.fastZ_needs_reset
        set(handles.messages, 'String', 'Reset FastZ before printing!');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    gridx = 5;
    gridy = 9;
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
    
    nframes = 200;
    
    hSI.hFastZ.enable = 1;
    if STL.fastZ_reverse
        hSI.hStackManager.stackZStepSize = STL.print.zstep;
    else
        hSI.hStackManager.stackZStepSize = -STL.print.zstep;
    end
    %hSI.hFastZ.flybackTime = 25; % SHOULD BE IN MACHINE_DATA_FILE?!?!
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    FastZhold(handles, 'on');
    hSI.hScan2D.bidirectional = false;
    hSI.hStackManager.numSlices = nframes;
    hSI.hBeams.powerLimits = 100;
    hSI.hBeams.enablePowerBox = true;
    
    hSI.startLoop();
    hSI.hBeams.enablePowerBox = false;
    FastZhold(handles, 'off');
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



function resetFastZ_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    hSI.hFastZ.positionTarget = STL.print.fastZhomePos;
    FastZhold(handles, 'reset');
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


function fastZlower_Callback(hObject, eventdata, handles)
    global STL;
    hSI = evalin('base', 'hSI');
    hSI.hFastZ.positionTarget = 450;
    FastZhold(handles, 'reset');
end


function invert_z_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.invert_z = get(hObject, 'Value');
end

function fastZhome_Callback(hObject, eventdata, handles)
    hSI = evalin('base', 'hSI');
    FastZhold(handles, 'reset');
end



function size1_Callback(hObject, eventdata, handles)
    update_dimensions(handles, 2, str2double(get(hObject, 'String')));
end

function size1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function size2_Callback(hObject, eventdata, handles)
    update_dimensions(handles, 2, str2double(get(hObject, 'String')));
end

function size2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end




function size3_Callback(hObject, eventdata, handles)
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
    
    if isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
        
        % Get bounds at zoom = 1
        hSI.hRoiManager.scanZoomFactor = 1;
        fov = hSI.hRoiManager.imagingFovUm;
        STL.bounds_1([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
        
        % Get bounds at min zoom
        hSI.hRoiManager.scanZoomFactor = STL.print.min_zoom;
        fov = hSI.hRoiManager.imagingFovUm;
        warning('FIXME: Does this result in the correct FOV? scanZoomFactor = %g, FOV in bounds window', hSI.hRoiManager.scanZoomFactor);
        STL.print.bounds_max([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];

        % Now, how about the user-selected print zoom?
        hSI.hRoiManager.scanZoomFactor = STL.print.zoom;
        fov = hSI.hRoiManager.imagingFovUm;
        warning('FIXME: Does this result in the correct FOV? scanZoomFactor = %g, FOV in bounds window', hSI.hRoiManager.scanZoomFactor);
        STL.print.bounds([1 2]) = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];

        update_dimensions(handles);
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
    STL.print.min_zoom = str2double(contents{get(hObject, 'Value')});
    
    
    if isfield(STL.print.zoom) & STL.print.zoom >= STL.print.min_zoom
        z = STL.print.zoom;
    else
        z = STL.print.min_zoom;
    end
    
    possibleZooms = STL.print.min_zoom:0.1:4;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%f', possibleZooms(i));
        
        % Allows user choice of zoom to remain unchanged despite the indexing for this widget
        if possibleZooms(i) == z
            zoomVal = i;
        end
    end
    
    set(handles.printZoom, 'String', foo, 'Value', zoomVal);
    
    UpdateBounds_Callback(hObject, eventdata, handles);
end

function minGoodZoom_CreateFcn(hObject, eventdata, handles)
    % These are just some allowed values. Need 1 sigfig, so just add likely
    % candidates manually... Could do it more cleverly!
    possibleZooms = 1:0.1:2;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%f', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end


function printZoom_Callback(hObject, eventdata, handles)
    global STL;
    
    contents = cellstr(get(hObject,'String'));
    STL.print.zoom = str2double(contents{get(hObject, 'Value')});
    
    UpdateBounds_Callback(hObject, eventdata, handles); 
    nmetavoxels = ceil(STL.print.size ./ STL.print.bounds);
    set(handles.nMetavoxels, 'String', sprintf('Metavoxels: [ %s]', sprintf(nMetavoxels)));

end

function printZoom_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    global STL;
    possibleZooms = STL.print.min_zoom:0.1:4;
    for i = 1:length(possibleZooms)
        foo{i} = sprintf('%f', possibleZooms(i));
    end
    set(hObject, 'String', foo, 'Value', 1);
end
