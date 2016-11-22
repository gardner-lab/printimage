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

% Last Modified by GUIDE v2.5 22-Nov-2016 16:16:16

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

STL.buildaxis = 2;
STL.print.power = 1;
STL.print.largestdim = 270;


addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));

guidata(hObject, handles);

update_gui(handles);

colormap(handles.axes2, 'gray');
end


function update_gui(handles);
global STL;

set(handles.buildaxis, 'Value', STL.buildaxis);
set(handles.printpowerpercent, 'String', sprintf('%d', round(100*STL.print.power)));
set(handles.largestdim, 'String', sprintf('%d', round(STL.print.largestdim)));

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

voxelise();

zslider_Callback(handles.zslider, [], handles);

end


% When the zSlider is moved, update things. If a build mesh is available, use that.
function zslider_Callback(hObject, eventdata, handles, pos)
global STL;

    
if exist('pos', 'var')
    set(handles.zslider, 'Value', pos/STL.resolution(STL.buildaxis));
end

if isempty(STL)
    return;
end
zind = round(STL.resolution(STL.buildaxis)*get(handles.zslider, 'Value'));
zind = max(min(zind, STL.resolution(STL.buildaxis)), 1);

if isfield(STL, 'print') & isfield(STL.print, 'resolution')
    grid = STL.print.voxles;
else
    grid = STL.voxels;
end

if isfield(STL.print, 'voxels')
    imagesc(squeeze(STL.print.voxels(:, :, zind))', 'Parent', handles.axes2);
else
    switch STL.buildaxis
        case 1
            imagesc(squeeze(STL.voxels(zind, :, :))', 'Parent', handles.axes2);
        case 2
            imagesc(squeeze(STL.voxels(:, zind, :))', 'Parent', handles.axes2);
        case 3
            imagesc(squeeze(STL.voxels(:, :, zind))', 'Parent', handles.axes2);
    end
end

axis(handles.axes2, 'image', 'ij');
end




function zslider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end


function buildaxis_Callback(hObject, eventdata, handles)
global STL;
STL.buildaxis = get(hObject, 'Value');
zslider_Callback(handles.zslider, [], handles);
end


function buildaxis_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String', {'x', 'y', 'z'});
end




% Called when the user presses "PRINT". Various things need to happen, some of them before the scan
% is initiated and some right before the print waveform goes out. This function handles the former,
% and instructs WaveformManager to call printimage_modify_beam() to do the latter.
function print_Callback(hObject, eventdata, handles)
global STL;


hSI = evalin('base', 'hSI');


% Save home positions. They won't be restored so as not to crush the printed object, but they should be
% reset later.
hSI.hMotors.zprvResetHome();
hSI.hBeams.zprvResetHome();


if ~strcmpi(hSI.acqState,'idle')
    set(handles.messages, 'String', 'Cannot print.  Abort the current ScanImage operation first.');
    return;
else
    set(handles.messages, 'String', '');
end

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


hSI.hRoiManager.scanZoomFactor = 1;
hSI.hStackManager.stackReturnHome = 0;
fov = hSI.hRoiManager.imagingFovUm;
fov_ranges = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
if fov_ranges(1) ~= fov_ranges(2)
    warning('FOV is not square. You could try rotating the object.');
end
hSI.hRoiManager.scanZoomFactor = fov_ranges(1) / STL.print.largestdim;

% Make the build axis the third column in the print mesh.
switch STL.buildaxis
    case 1
        STL.print.mesh = STL.mesh(:, [2 3 1], :);
        STL.print.aspect_ratio = STL.aspect_ratio([2 3 1]);
    case 2
        STL.print.mesh = STL.mesh(:, [1 3 2], :);
        STL.print.aspect_ratio = STL.aspect_ratio([1 3 2]);
    case 3
        STL.print.mesh = STL.mesh;
        STL.print.aspect_ratio = STL.aspect_ratio;
end

% Number of slices at 1 micron per slice:
height = round(max(STL.print.mesh(:, 3, 3)) * STL.print.largestdim);
hSI.hFastZ.enable = 1;
hSI.hStackManager.numSlices = height;



STL.print.armed = true;
evalin('base', 'hSI.startLoop()');
STL.print.armed = false;

zSlider_Callback(hObject);
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


function resetFastZ_Callback(hObject, eventdata, handles)
hSI = evalin('base', 'hSI');
hSI.hBeams.zprvGoHome();
hSI.hMotors.zprvGoHome();
end
