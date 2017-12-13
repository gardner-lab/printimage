% Make the sine plots. Takes one argument: the (sub?)panel into which to plot.
function make_sine_plot_4(panels, tiffAdj, methods, methodsValid, colours)
    
    %Number of time samples in a full phase:
    nsteps = 3333333 / 7980;
    
    %Time
    t = linspace(-pi, pi, nsteps);
    
    SHOW_X_GRAPH = 1;
    SHOW_Y_GRAPH = 0;
    
    %Beam Velocity
    if isempty(panels.children)
        panels.pack(1,2 + SHOW_X_GRAPH + SHOW_Y_GRAPH);
    end
    
    panels(1,1).select();

    x = cos(t);
    ti = find(t >= -pi/2 & t <= pi/2);
    plot(t(ti), x(ti), 'LineWidth', 2); hold on;
    xlabel('Time (phase)');
    ylabel('Velocity');
    
    %Format
    xlim([-1.8, 1.8]);
    ylim([0, 1]);
    set(gca, 'box', 'off', 'TickDir', 'out');
    set(gca, 'XTick', [-pi/2, 0, pi/2], 'XTickLabel', {'-\pi/2', 0, '\pi/2'})
    set(gca, 'YTick', [0, 0.5, 1], 'YTickLabel', [0, 0.5, 1])
    title('(a) Beam velocity');
    
    %Beam position
    panels(1,2).select();
    % labels = {'Resonant scanner beam position'};
    x = sin(t);
    ti = find(t >= -pi/2 & t <= pi/2);
    plot(t(ti), x(ti), 'LineWidth', 2);
    hold on;
    
    
    % Imaging fraction of beam. Show voxel positions for slower control system for clarity...
    D = 0.9;
    nsteps_show = 1000000 / 7980;
    t_show = linspace(-pi, pi, nsteps_show);
    x_show = sin(t_show);
    tt = asin(D);
    ti = find(t > -tt & t < tt);
    ti_show = find(t_show > -tt & t_show < tt);
    %plot(t_show(ti_show),x_show(ti_show), 'k.', 'MarkerSize', 10);
    
    sz = 0.1;
    lines_x = [t_show(ti_show)-sz; t_show(ti_show)+sz];
    lines_y = [x_show(ti_show); x_show(ti_show)];
    line(lines_x, lines_y, 'Color', [0 0 0], 'LineWidth', 0.1);
    
    %hold off;
    ylabel('X Position');
    xlabel('Time (phase)');
    %xlim([-pi,pi]);
    legend({'Beam position', 'Voxels'}, 'Location', 'NorthWest', 'box', 'off');
    %title('(A) Beam position through time');
    title('(b) Voxel positions');
    %Format
    xlim([-1.8, 1.8]);
    ylim([-1, 1]);
    set(gca, 'box', 'off', 'TickDir', 'out');
    set(gca, 'XTick', [-pi/2, 0, pi/2], 'XTickLabel', {'-\pi/2', 0, '\pi/2'})
    set(gca, 'YTick', [-1, 0, 1], 'YTickLabel', {'-\xi', 0, '\xi'})

    if SHOW_X_GRAPH
        panels(1,3).select();
        % Power compensation
        p = cos(t);
        pstar = 0.5*(1+cos(t));
        
        %% cos^4 vignetting compensation. Show it for zoom=2.2x, since that's what
        %% pstar is calibrated to. That means that the usable part of the X axis has
        %% size FOV/zoom, the lens working distance
        fov = 666; % um for whole FOV
        zoomlevel = 1.6;
        
        convert_phase_dist_to_microns = fov/(D*zoomlevel*2);
        positions_um = sin(t) * convert_phase_dist_to_microns;
        %positions_um(2,:) = sqrt(positions_um(1,:).^2 + 200^2);
        %disp(sprintf('Working FOV is %g um', D*(max(positions_um)-min(positions_um))));
        %= lens_working_distance * convert_microns_to_phase_dist;
        % Divide p by predicted vignetting compensation
        %cos3 = cos(atan(positions_um./lens_working_distance)).^3;
        
        cla;
        hold on;
        for i = find(methodsValid)
            centreX = round(size(tiffAdj{i}.p, 1)/2);
            centreY = round(size(tiffAdj{i}.p, 2)/2);
            plot(asin(tiffAdj{i}.xc / convert_phase_dist_to_microns), ...
                tiffAdj{i}.p(:, centreY) / tiffAdj{i}.p(centreX, centreY), ...
                'Color', colours(i,:));
        end
        hold off;
        
        %    t(ti), pstar(ti), 'c', ... % Ad-hoc
        ylabel('Power');
        xlabel('Time (phase)');
        % xlim([-pi,pi]);
        % ylim([0 1.1]);
        legend(methods(find(methodsValid)), 'Location', 'South', 'box', 'off');
        %title('(B) Relative voxel size');
        title(sprintf('(c) X power compensation, FOV = %d \\mu{}m', ...
            round(D*(max(positions_um)-min(positions_um)))));
        %Format
        xlim([-1.8, 1.8]);
        %yl = get(gca, 'YLim');
        %ylim([0, 1.3]);
        ylim([0.4 1.1]);
        set(gca, 'box', 'off', 'TickDir', 'out');
        set(gca, 'XTick', [-pi/2, 0,pi/2], 'XTickLabel', {'-\pi/2', 0, '\pi/2'})
        set(gca, 'YTick', [0, 0.5, 1, 1.5, 2])
        %set(gca, 'YLim', [0.35 2]);
    end
    
    if SHOW_Y_GRAPH
        panels(1,3 + SHOW_X_GRAPH).select();
        
        cla;
        hold on;
        for i = 1:length(tiffAdj)
            centreX = round(size(tiffAdj{i}.p, 1)/2);
            centreY = round(size(tiffAdj{i}.p, 2)/2);
            plot(tiffAdj{i}.yc, ...
                tiffAdj{i}.p(centreX, :) / tiffAdj{i}.p(centreX, centreY), ...
                'Color', colours(i,:));
        end
        hold off;
        
        %    t(ti), pstar(ti), 'c', ... % Ad-hoc
        ylabel('Power');
        xlabel('Y position (\mu{}m)');
        legend(methods, 'Location', 'NorthWest', 'box', 'off');
        %title('(B) Relative voxel size');
        title(sprintf('(d) Y power compensation, FOV = %d \\mu{}m', ...
            round(D*(max(positions_um)-min(positions_um)))));
        %Format
        %xlim([-1.8, 1.8]);
        %yl = get(gca, 'YLim');
        %ylim([0, 1.3]);
        ylim([0.7 1.8]);
        xlim([-290 290]);
        set(gca, 'box', 'off', 'TickDir', 'out');
        set(gca, 'YTick', [0, 0.5, 1, 1.5, 2])
    end
    drawnow;
    