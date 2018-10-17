function cancel_button_callback()
    global STL;
        
    disp('Canceling (in the callback).');
    STL.logistics.abort = true;
end
