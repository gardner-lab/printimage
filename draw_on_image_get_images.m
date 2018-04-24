% Get a list of indices into ScanImage's managed GUI structure that
% represent image windows for things like previews etc.
function [ relevant_images ] = draw_on_image_get_images
    hSICtl = evalin('base', 'hSICtl');

    relevant_images = [];
    irrelevant_images = [];
    for i = 1:length(hSICtl.hManagedGUIs)
        if (strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 1') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 2') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel Merge')) ...
                & strcmp(hSICtl.hManagedGUIs(i).Visible, 'on')
            relevant_images = [relevant_images i];
        else
            irrelevant_images = [irrelevant_images i];
        end
    end
    
    if length(relevant_images) == 0
        warning('Ben''s assumptions about what the relevant fields are in hSICtl.hManagedGUIs seem to be wrong.');
    end
end
