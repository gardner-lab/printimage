function add_bullseye()
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
        if str2double(hSI.VERSION_MAJOR) <= 5.3 & ~str2double(hSI.VERSION_MINOR) > 0
            z = z(2) - 0.0001; % ScanImage < 5.3.1 wanted the z info drawn here.
        else
            z = mean(z); % This _MIGHT_ work with versions < 5.3.1 as well. Can't test due to NIDAQ firmware upgrade...
        end
        
        sizes = round(linspace(2, 18, 6).^2);
        
        hold on;
        for j = sizes
            plot3(0, 0, z, 'ro', 'MarkerSize', j, 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes);
        end
        hold off;
        %line(scale_bar_pos(1,:), scale_bar_pos(2,:), [z z], 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes, 'Color', [1 0 0], 'LineWidth', 11);
        %text(0, scale_bar_pos(2,1), z, scalelen, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes, 'Color', [1 1 1]);
    end
end
