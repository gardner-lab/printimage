function varargout = tiffview(varargin)
    % TIFFVIEW MATLAB code for tiffview.fig
    %      TIFFVIEW, by itself, creates a new TIFFVIEW or raises the existing
    %      singleton*.
    %
    %      H = TIFFVIEW returns the handle to a new TIFFVIEW or the handle to
    %      the existing singleton*.
    %
    %      TIFFVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in TIFFVIEW.M with the given input arguments.
    %
    %      TIFFVIEW('Property','Value',...) creates a new TIFFVIEW or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before tiffview_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to tiffview_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help tiffview
    
    % Last Modified by GUIDE v2.5 17-Feb-2017 14:30:41
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @tiffview_OpeningFcn, ...
        'gui_OutputFcn',  @tiffview_OutputFcn, ...
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
    
    
    % --- Executes just before tiffview is made visible.
function tiffview_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    
    
    files = dir('*.tif*');
    
    [sorted_names, sorted_index] = sortrows({files.name}');
    handles.files = sorted_names;
    handles.sorted_index = sorted_index;
    set(handles.file,'String',handles.files,'Value',1);
    
    addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    set(handles.delete, 'Enable', 'off');

    % Update handles structure
    guidata(hObject, handles);
    
    
    
function varargout = tiffview_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
    
    
function file_Callback(hObject, eventdata, handles)    
    file = handles.sorted_index(get(hObject,'Value'));
    do_file(hObject, handles, file);
    
    
function do_file(hObject, handles, file)    
    global tiff;
    global lastfile;
    
    if lastfile == file
        return;
    end
        
    if file > length(handles.files)
        disp(sprintf('inspect.m: Requested file %d, but only %d files', ...
            file, length(handles.files)));
        return;
    end
    
    
    set(handles.delete, 'Enable', 'off');
    drawnow;


    tiff = [];
    i = 0;
    title(handles.axes1, 'Loading image...');
    drawnow;
    try
        while true
            i = i + 1;
            tiff(i,:,:) = imread(handles.files{file}, i);
            %imagesc(squeeze(tiff(i,:,:)));
        end
    catch ME
    end
    
    lastfile = file;

    zslider_Callback(handles.zslider, [], handles);
    set(handles.delete, 'Enable', 'on');

    
function file_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
function zslider_Callback(hObject, eventdata, handles)
    global tiff;
    ulim = size(tiff, 1);
    v = get(handles.zslider, 'Value');
    
    imagesc(handles.axes1, squeeze(tiff(max(1, round(v*ulim)),:,:)));
    title(handles.axes1, sprintf('Slice %d of %d', max(1, round(v*ulim)), ulim));
    drawnow;
    
    
function zslider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


function delete_Callback(hObject, eventdata, handles)
    global lastfile;
    
    file = handles.sorted_index(get(handles.file, 'Value'));
    delete(handles.files{file});
    
    % Reload
    files = dir('*.tif*');
    [sorted_names, sorted_index] = sortrows({files.name}');
    handles.files = sorted_names;
    handles.sorted_index = sorted_index;
    set(handles.file,'String',handles.files,'Value',min(file, length(handles.sorted_index)));
    guidata(hObject, handles);

    set(handles.delete, 'Enable', 'off');
    lastfile = [];
    
