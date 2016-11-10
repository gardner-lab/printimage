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

% Last Modified by GUIDE v2.5 09-Nov-2016 17:46:05

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
set(handles.buildaxis, 'Value', STL.buildaxis);

addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));


guidata(hObject, handles);


colormap(handles.axes2, 'gray');
end


function varargout = printimage_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end



function STLfile_Callback(hObject, eventdata, handles)
end

function STLfile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function chooseSTL_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile('*.stl');
set(handles.STLfile, 'String', strcat(PathName, FileName));
updateSTLfile(handles, strcat(PathName, FileName));
end



function updateSTLfile(handles, STLfile)
global STL;

STL.file = STLfile;
STL.mesh = READ_stl(STLfile);
% This is stupid, but patch() likes this format, so easiest to just read it
% again.
patchobj = stlread(STLfile);
ranges_scale = [min(min(patchobj.vertices)) max(max(patchobj.vertices))];
llim = min(patchobj.vertices);
patchobj.vertices = bsxfun(@minus, patchobj.vertices, llim) / (ranges_scale(2) - ranges_scale(1));

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
camlight('right');
material('dull');
axis('image');
daspect([1 1 1]);
view([-135 35]);
rotate3d on;

STL.resolution = [128 128 128];

STL.gridOutput = VOXELISE(STL.resolution(1), STL.resolution(2), STL.resolution(3), STL.mesh);
zslider_Callback(handles.zslider, [], handles);

end


function zslider_Callback(hObject, eventdata, handles)
global STL;

if isempty(STL)
    return;
end
zind = round(STL.resolution(STL.buildaxis)*get(handles.zslider, 'Value'));
zind = max(min(zind, STL.resolution(STL.buildaxis)), 1);
switch STL.buildaxis
    case 1
        imagesc(squeeze(STL.gridOutput(zind, :, :)), 'Parent', handles.axes2);
    case 2
        imagesc(squeeze(STL.gridOutput(:, zind, :)), 'Parent', handles.axes2);
    case 3
        imagesc(squeeze(STL.gridOutput(:, :, zind)), 'Parent', handles.axes2);
end
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
