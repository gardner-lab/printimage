function enable_callback(enable, fcnName, eventName)

hSI = evalin('base', 'hSI');

found = false;
for i = 1:length(hSI.hUserFunctions.userFunctionsCfg)
    if strcmp(hSI.hUserFunctions.userFunctionsCfg(i).UserFcnName, fcnName)
        found = true;
        hSI.hUserFunctions.userFunctionsCfg(i).Enable = enable;
    end
end

if ~found    
    foo.EventName = eventName;
    foo.UserFcnName = fcnName;
    foo.Enable = enable;
    val = struct('EventName',eventName,'UserFcnName',fcnName,'Arguments',[{}],'Enable',enable);
    pos = length(hSI.hUserFunctions.userFunctionsCfg) + 1;
    hSI.hUserFunctions.userFunctionsCfg(1,:) = val;
    %hSI.hUserFunctions.userFunctionsCfg(pos).EventName = eventName;
    %hSI.hUserFunctions.userFunctionsCfg(pos).UserFcnName = fcnName;
    %hSI.hUserFunctions.userFunctionsCfg(pos).Enable = enable;
end
