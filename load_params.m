% Replace default values of parameters with custom values from an m file.
% 'vars' is a cell array of strings, each of which is the name of a variable that are global and can be
% updated.

function load_params(params_file, vars)
    
    % Make input args consistent
    if ischar(vars)
        v = vars;
        clear vars;
        vars{1} = v;
    end
    
    if ~exist(strcat(params_file, '.m'), 'file')
        warning('Parameters file ''%s'' does not exist.', strcat(params_file, '.m'));
        return;
    end
    
    % Check that each variable to be updated is, in fact, available in the
    % global workspace. If not, warn. If so, make it accessible in this
    % function.
    for i = 1:length(vars)
        a = who('global', vars{i});
        if isempty(a)
            warning('Global variable ''%s'' ain''t no thang!', vars{i});
        else
            eval(sprintf('global %s;', vars{i}));
        end
    end
    
    % This will create a copy of the top-level variables in the params file
    new_params = load_the_damn_thing(params_file);
    
    % textscan reads one line at a time, causing difficulty for multi-line
    % variable declarations (e.g. nicely-typeset arrays). So we use this
    % just to get the variable names to check their legitimacy.
    fid = fopen(strcat(params_file, '.m'), 'r');
    disp(sprintf('======= Loading parameters from ''%s''=======', params_file));
    while true
        % Read a line
        s = fgetl(fid);
        if ~ischar(s)
            break;
        end
        % Chew off anything comment-y
        n = findstr(s, '%');
        if n == 1
            continue;
        elseif ~isempty(n)
            s = s(1:n-1);
        end
        % See if the line contains an equals sign
        n = findstr(s, '=');
        if isempty(n) | n == 1
            continue;
        else
            s = s(1:n-1);
        end
        
        % Try to read the value of the variable. If it doesn't exist, catch
        % the error and turn it into a warning.
        try
            eval(sprintf('thing = %s;', s));
            disp(sprintf('%s = new_params.%s;', s, s));
            eval(sprintf('%s = new_params.%s;', s, s));
        catch ME
            warning('Parameter ''%s'' ain''t no thang!', s);
        end
    end
    disp('==================================================');
end

% Namespaces: load the vars into this function's workspace, and then prefix
% them so they can be passed back without overwriting the real global and
% hence losing the information on whether the variable is legit.
function [ out ] = load_the_damn_thing(params_file)
    
    eval(params_file);

    v = whos;
    for i = 1:length(v)
        if strcmp(v(i).name, 'params_file')
            continue;
        end
        eval(sprintf('out.%s = %s;', v(i).name, v(i).name));
    end
end
