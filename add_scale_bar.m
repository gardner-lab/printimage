function add_scale_bar()
    global STL;
    hSI = evalin('base', 'hSI');
    hSICtl = evalin('base', 'hSICtl');
    
    relevant_images = [];
    for i = 1:length(hSICtl.hManagedGUIs)
        if strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 1') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 2') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel Merge')
            relevant_images = [relevant_images i];
        end
    end
    
    fov = hSI.hRoiManager.imagingFovUm;
    bounds = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
    
    for i = relevant_images
        fig_bounds = diff([get(hSICtl.hManagedGUIs(i).CurrentAxes, 'XLim')' get(hSICtl.hManagedGUIs(i).CurrentAxes, 'YLim')']);
        fov_transform = diag([1 1] .* fig_bounds ./ bounds);
        
        scale_bar_length = 10^floor(log10(bounds(1)*0.5));
        scalelen = sprintf('%d {\\mu}m', scale_bar_length);
        scale_bar_ypos = fov(end,end) - 0.1 * bounds(2);
        
        z = get(hSICtl.hManagedGUIs(i).CurrentAxes, 'ZLim');
        z = z(2) - 0.0001;
        
        scale_bar_pos = [-scale_bar_length/2 scale_bar_length/2; ...
            scale_bar_ypos * [1 1]];
        scale_bar_pos = scale_bar_pos * fov_transform;
        line(scale_bar_pos(1,:), scale_bar_pos(2,:), [z z], 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes, 'Color', [1 0 0], 'LineWidth', 11);
        text(0, scale_bar_pos(2,1), z, scalelen, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes, 'Color', [1 1 1]);
    end
end
