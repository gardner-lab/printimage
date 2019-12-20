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
    %      *See GUI Options on GUIDE's Tools menu.  Choose 'GUI allows only one
    %      instance to run (singleton)'.
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help tiffview
    
    % Last Modified by GUIDE v2.5 16-Jul-2018 13:59:39
    
    % 1) Specify folder to load with a gui, reload filelist without
    % relaunching tiffView DONE
    % 2) Delete tiff files from the GUI DONE
    
    % 3) Default slider should move one image at a time, use an edit/popup
    % box to edit step size
    % 4) edit box to jump to a specific image
    % 5) Develop a method 'of using the loaded tiff files to define a flat
    % (but likely angled/inclined) surface in a volume based on the relative 
    % brightness of the pixels in those images
    
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
    
    
    %files = dir('*.tif*');
    
    % loads the files of the folder you are currently in (CHANGE)
    
    %[sorted_names, sorted_index] = sortrows({files.name}');
    %handles.files = sorted_names;
    %handles.sorted_index = sorted_index;
    %set(handles.fileList,'String',handles.files,'Value',1);
    
    %addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));
    %set(handles.delete, 'Enable', 'off');

    % Update handles structure
    guidata(hObject, handles);
    
  

function filelist_update(hObject, handles)
files = dir(fullfile(handles.dirname, '*.tif'));
[sorted_names, sorted_index] = sortrows({files.name}');
handles.files = sorted_names;
handles.sorted_index = sorted_index;
set(handles.fileList,'String',handles.files,'Value',1);

guidata(hObject, handles);

    
function varargout = tiffview_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
    
    
function fileList_Callback(hObject, eventdata, handles)
    file = get(hObject, 'Value'); %% why index into sorted index if it's just a list of #'s from 1?
    %file = handles.sorted_index(get(hObject,'Value'));
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
    
    
    %set(handles.delete, 'Enable', 'off');
    drawnow;


    tiff = [];
    i = 0;
    title(handles.axes1, 'Loading image...');
    drawnow;
    try
        while true
            i = i + 1;
            tiff(i,:,:) = imread(strcat(handles.dirname, '/', handles.files{file}), i); % dis might be d issue: handles.files is just a cell array of strings
            %imagesc(squeeze(tiff(i,:,:)));
            % when does this loop end?
        end
    catch ME
    end
        
    % set slider values for this file
    [handles.numIm, ~, ~] = size(tiff);
    set(handles.zslider, 'Min', 1);
    set(handles.zslider, 'Max', handles.numIm);
    set(handles.zslider, 'SliderStep', [1/(handles.numIm - 1), 0.10]);
    handles.edit_stepSize.String = '1';
    handles.zSlider.Value = 1;

    guidata(hObject, handles);

    zslider_Callback(handles.zslider, [], handles);
    %set(handles.delete, 'Enable', 'on');

    
function fileList_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
function zslider_Callback(hObject, eventdata, handles)
    global tiff;
    
    ulim = size(tiff, 1);
    colormap bone;
    v = get(handles.zslider, 'Value');
    %imNumSelected = int32(get(handles.zslider, 'Value'));
    
    imagesc(squeeze(tiff(v,:,:)), 'Parent', handles.axes1);
    title(handles.axes1, sprintf('Slice %d of %d', v, ulim));
    drawnow;
    % when does it open the new figure window? 
    
    
function zslider_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end


% --- Executes on button press in push_loadFolder.
function push_loadFolder_Callback(hObject, eventdata, handles)
if isfield(handles, 'dirname')
    directory_name = uigetdir(handles.dirname);
else
    directory_name = uigetdir;
end

files = dir(fullfile(directory_name, '*.tif'));

% names: files.name
[sorted_names, sorted_index] = sortrows({files.name}');
handles.files = sorted_names;
handles.sorted_index = sorted_index;
set(handles.fileList,'String',handles.files,'Value',1);
    
addlistener(handles.zslider, 'Value', 'PreSet', @(~,~)zslider_Callback(hObject, [], handles));

%If its a real directory, load files from the folder
if ~isstr(directory_name)
    return
else
    %Load and sort from folder
    handles.dirname = directory_name;
    %[handles.filelist, handles.listSize] = folderLoad(handles);
 
    %handles.deleteIndx = false(1,length(handles.filelist));
    %if isempty(handles.filelist)
    %    set(handles.text_message, 'String',[directory_name ' is empty']);
    %    return
    %end
    

    %Update text message display
    %set(handles.text_message,'String',['Files loaded from ' directory_name])
    
    %set(handles.fileList,'string',richFileList);
    %set(handles.fileList,'value',handles.curfile);
end
guidata(hObject, handles);


% --- Executes on button press in push_delete.
function push_delete_Callback(hObject, eventdata, handles)

fileNum = get(handles.fileList, 'Value');
set(handles.text_status, 'String', num2str(fileNum));

% now delete it. Need the file name
quarFile = handles.files{fileNum};
set(handles.text_status, 'String', num2str(quarFile));
delete(strcat(handles.dirname, '/', quarFile));
set(handles.text_status, 'String', strcat(num2str(quarFile), ' was deleted'));

% update fileList display
filelist_update(hObject,handles);
guidata(hObject, handles);


function edit_goto_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit_goto_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_stepSize_Callback(hObject, eventdata, handles)
size = str2num(handles.edit_stepSize.String);
set(handles.zslider, 'SliderStep', [size/(handles.numIm - 1), size/(handles.numIm - 1)]);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_stepSize_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in push_go.
function push_go_Callback(hObject, eventdata, handles)
handles.pos = str2num(handles.edit_goto.String);
handles.zslider.Value = handles.pos;
guidata(hObject, handles);
zslider_Callback(handles.zslider, [], handles);
