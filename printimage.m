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
    
    % Last Modified by GUIDE v2.5 13-Dec-2016 13:01:50
    
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
    
    STL.print.xaxis = 1;
    STL.print.zaxis = 3;
    STL.print.power = 1;
    STL.print.largestdim = 300;
    STL.print.valid = false;
    STL.fastZ_reverse = false;
    STL.print.invert_z = false;
    if STL.fastZ_reverse
        STL.print.fastZhomePos = 0;
    else
        STL.print.fastZhomePos = 450;
    end
    
    STL.printer.bounds = [270 270 450]; % Should take this from software!!!
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    
    guidata(hObject, handles);
    
    update_gui(handles);
    
    colormap(handles.axes2, 'gray');
end


function update_gui(handles);
    global STL;
    
    set(handles.build_x_axis, 'Value', STL.print.xaxis);
    set(handles.build_z_axis, 'Value', STL.print.zaxis);
    set(handles.printpowerpercent, 'String', sprintf('%d', round(100*STL.print.power)));
    set(handles.largestdim, 'String', sprintf('%d', round(STL.print.largestdim)));
    set(handles.fastZhomePos, 'String', sprintf('%d', round(STL.print.fastZhomePos)));
    set(handles.powertest_start, 'String', sprintf('%g', 1));
    set(handles.powertest_end, 'String', sprintf('%g', 100));
    set(handles.invert_z, 'Value', STL.print.invert_z);
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
    
    STL.print.valid = false;
    STL.file = STLfile;
    STL.mesh = READ_stl(STL.file);
    % This is stupid, but patch() likes this format, so easiest to just read it
    % again.
    patchobj = stlread(STL.file);
    
    % Scale into a 1x1x1 box:
    aspect_ratio = max(patchobj.vertices) - min(patchobj.vertices);
    range_scale = max(aspect_ratio);
    aspect_ratio = aspect_ratio / range_scale;
    llim = min(patchobj.vertices);
    patchobj.vertices = bsxfun(@minus, patchobj.vertices, llim) / range_scale;
    STL.mesh = bsxfun(@minus, STL.mesh, llim) / range_scale;
    STL.patchobj = patchobj;
    
    axes(handles.axes1);
    cla;
    patch(patchobj, ...
        'FaceColor',       [0.8 1 0.8], ...
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
    %rotate_handle.ActionPostCallback = @RotationCallback;
    rotate_handle.enable = 'on';
    
    %% FIXME Compute resolution as done in ResonantGalvo:448:
    %            if obj.hasBeams
    %                hBm = obj.beams;
    %                [~,lineAcquisitionPeriod] = obj.linePeriod([]);
    %                bExtendSamples = floor(hBm.beamClockExtend * 1e-6 * hBm.sampleRateHz);
    %                samplesPerTrigger.B = ceil( lineAcquisitionPeriod * hBm.sampleRateHz ) + 1 + bExtendSamples;
    %            end
    
    
    
    STL.aspect_ratio = aspect_ratio;
    
    voxelise(handles);
    
    zslider_Callback(handles.zslider, [], handles);
    
end





% When the zSlider is moved, update things. If a build mesh is available, use that.
function zslider_Callback(hObject, eventdata, handles, pos)
    global STL;
    
    if isempty(STL)
        return;
    end
    
    if get(handles.zslider, 'Max') ~= STL.print.resolution(3)
        set(handles.zslider, 'Max', STL.print.resolution(3));
    end
    
    if exist('pos', 'var')
        set(handles.zslider, 'Value', pos*STL.print.resolution(3));
    end
    
    zind = round(get(handles.zslider, 'Value'));
    zind = max(min(zind, STL.print.resolution(3)), 1);
    
    draw_slice(handles, zind);
end




function zslider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end




% Called when the user presses "PRINT". Various things need to happen, some of them before the scan
% is initiated and some right before the print waveform goes out. This function handles the former,
% and instructs WaveformManager to call printimage_modify_beam() to do the latter.
function print_Callback(hObject, eventdata, handles)
    global STL;
    
    
    hSI = evalin('base', 'hSI');
    
    if ~strcmpi(hSI.acqState,'idle')
        set(handles.messages, 'String', 'Some other ongoing operation (FOCUS?) prevents printing.');
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
    
    if isempty(fieldnames(hSI.hWaveformManager.scannerAO))
        set(handles.messages, 'String', 'Cannot read resonant resolution. Run a focus or grab manually first.');
        return;
    else
        set(handles.messages, 'String', '');
    end
    
    % Make sure we haven't changed the desired resolution or anything else that
    % ScanImage can change without telling us. This should be a separate
    % function eventually!
    height = floor(max(STL.print.mesh(:, 3, 3)) * STL.print.largestdim);
    resolution = [hSI.hWaveformManager.scannerAO.ao_samplesPerTrigger.B ...
        hSI.hRoiManager.linesPerFrame ...
        height];
    if any(resolution ~= STL.print.resolution)
        voxelise(handles);
    end
    
    
    
    
    hSI.hRoiManager.scanZoomFactor = 1;
    fov = hSI.hRoiManager.imagingFovUm;
    fov_ranges = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
    if fov_ranges(1) ~= fov_ranges(2)
        warning('FOV is not square. You could try rotating the object.');
    end
    hSI.hRoiManager.scanZoomFactor = fov_ranges(1) / STL.print.largestdim;
    
    if ~STL.print.valid
        warning('STL.print.valid is false.');
        return;
    end
    
    % Number of slices at 1 micron per slice:
    height = round(max(STL.print.mesh(:, 3, 3)) * STL.print.largestdim);
    hSI.hScan2D.bidirectional = false;
    
    hSI.hFastZ.enable = 1;
    hSI.hStackManager.numSlices = height;
    if STL.fastZ_reverse
        hSI.hStackManager.stackZStepSize = 1;
    else
        hSI.hStackManager.stackZStepSize = -1;
    end
    hSI.hStackManager.stackReturnHome = false; % This seems useless.
    %hSI.hStackManager.stackZStartPos = 0;
    %hSI.hStackManager.stackZEndPos = NaN;
    FastZhold(handles, 'on');
    
    STL.print.armed = true;
    evalin('base', 'hSI.startLoop()');
    STL.print.armed = false;
    
    FastZhold(handles, 'off');
    
    zslider_Callback([], [], handles);
end




function FastZhold(handles, v);
    % Control FastZ position-hold-before-reset: 'on', 'off', 'reset'
    global STL;
    hSI = evalin('base', 'hSI');
    
    if strcmp(v, 'on')
        set(handles.fastZhome, 'BackgroundColor', [1 0 0]);
        STL.print.FastZhold = true;
    end
    
    if strcmp(v, 'off')
        STL.print.FastZhold = false;
    end
    
    if strcmp(v, 'reset')
        STL.print.FastZhold = false;
        hSI.hFastZ.goHome;
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



function largestdim_Callback(hObject, eventdata, handles)
    global STL;
    STL.print.largestdim = str2double(get(hObject,'String'));
end



function largestdim_CreateFcn(hObject, eventdata, handles)
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
        hSI.hStackManager.stackZStepSize = 1;
    else
        hSI.hStackManager.stackZStepSize = -1;
    end
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
    
    STL.print.valid = 0;
    STL.print.xaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.zaxis = setdiff([1 2], STL.print.xaxis);
        update_gui(handles);
    end
    voxelise(handles);
end

function build_x_axis_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function build_z_axis_Callback(hObject, eventdata, handles)
    global STL;
    
    STL.print.valid = 0;
    STL.print.zaxis = get(hObject, 'Value');
    if STL.print.zaxis == STL.print.xaxis
        STL.print.xaxis = setdiff([1 2], STL.print.zaxis);
        update_gui(handles);
    end
    voxelise(handles);
    zslider_Callback(handles.zslider, [], handles);
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
    %FastZhold(handles, 'reset');
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
