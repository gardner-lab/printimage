function add_preview(handles)
    global STL;
    hSI = evalin('base', 'hSI');
    hSICtl = evalin('base', 'hSICtl');
    
    relevant_images = [];
    for i = 1:length(hSICtl.hManagedGUIs)
        if (strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 1') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel 2') ...
                | strcmp(hSICtl.hManagedGUIs(i).Name, 'Channel Merge')) ...
                & strcmp(hSICtl.hManagedGUIs(i).Visible, 'on')
            relevant_images = [relevant_images i];
        end
    end
    
    % Need to know the bounds that we'll be printing at. That's
    % bounds_best, computed in voxelise. So make sure that's been called:
    if STL.print.voxelise_needed
        voxelise(handles, 'print');
        if STL.logistics.abort
            % Did we abort? That's okay for now... until I figure out how
            % to do previews on stitched images. I guess just show the
            % first piece, which should always exist even after an abort.
            % Right?
            STL.logistics.abort = false;
        end
    end
    
    % Get current FOV
    fov = hSI.hRoiManager.imagingFovUm;
    if any(abs(fov) ~= abs(fov(1,1)))
        error('It seems Ben''s assumptions about a square, centred FOV were wrong.');
    end
    bounds = [fov(3,1) - fov(1,1)      fov(3,2) - fov(1,2)];
    zind = get(handles.zslider, 'Value');
    w = [1 1 1]; % Which metavoxel slice? This should be the one that prints first.
    which_slice = max(1, round(zind * size(STL.print.metavoxels{w(1), w(2), w(3)}, 3)));

    posx = STL.print.voxelpos{1,1,1}.x;
    posx = posx - (max(posx) - min(posx))/2;
    posy = STL.print.voxelpos{1,1,1}.y;
    posy = posy - (max(posy) - min(posy))/2;
    
    for i = relevant_images
        fig_lims = [get(hSICtl.hManagedGUIs(i).CurrentAxes, 'XLim')' ...
            get(hSICtl.hManagedGUIs(i).CurrentAxes, 'YLim')'];
        fig_bounds = diff(fig_lims);
                
        fov_transform = diag([1 1] .* fig_bounds ./ bounds);
        
        
        
        z = get(hSICtl.hManagedGUIs(i).CurrentAxes, 'ZLim');
        z = z(2) - 0.0001; % Don't ask
        
        psz = fig_bounds ./ STL.print.resolution(1:2) / 2;
        % try
        
        %axes(hSICtl.hManagedGUIs(i).CurrentAxes);
        %hold on;
        % Maybe try patches:
        [pixx pixy] = find(STL.print.metavoxels{1,1,1}(:,:,which_slice));
        
        scatterme = zeros(3, length(pixx));
        for j = 1: length(pixx)
            pos = [posx(pixx(j)) posy(pixy(j))] * fov_transform;
            scatterme(:,j) = [pos(1); pos(2); z];
        end
        %hold(hSICtl.hManagedGUIs(i).CurrentAxes, 'on');
        scatter3(hSICtl.hManagedGUIs(i).CurrentAxes, ...
            scatterme(1,:), scatterme(2,:), scatterme(3,:), 1, [1 0 0], ...
            'Marker', '.', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.5);
        %hold(hSICtl.hManagedGUIs(i).CurrentAxes, 'off');
        %rectangle('Position', [rectx, recty, rectw, recth], ...
        %    'Parent', hSICtl.hManagedGUIs(i).CurrentAxes);
        %text(pos(1), pos(2), z, 'o', 'HorizontalAlignment', 'center', ...
        % 'VerticalAlignment', 'middle', ...
        % 'Parent', hSICtl.hManagedGUIs(i).CurrentAxes, 'Color', [0 1 1]);
        
        % Or maybe mask it out:
        %masked = bsxfun(@times, src, cast(mask,class(src)))
        
        % Or scatter?
        %scatter([], [], STL.print.metavoxels{1,1,1}(:,:,which_slice));
        %imagesc(STL.print.voxelpos{w(1), w(2), w(3)}.x, STL.print.voxelpos{w(1), w(2), w(3)}.y, ...
        %    squeeze(STL.print.metavoxels{w(1), w(2), w(3)}(:, :, which_slice))', 'Parent', handles.axes2);
        hold off;
        %catch ME
        %    disp(sprintf('Cannot imagesc the metavoxel at [ %d %d %d ]', w(1), w(2), w(3)));
        %end
    end
end
