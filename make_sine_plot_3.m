% Make the sine plots. Takes one argument: the (sub?)panel into which to plot.
function make_sine_plot_3(p)
    
    %Number of time samples in a full phase:
    nsteps = 3333333 / 7980;
    
    %Time
    t = linspace(-pi, pi, nsteps);
    
    %Beam Velocity
    if isempty(p.children)
        p.pack(1,3);
    end
    
    p(1,1).select();

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
    p(1,2).select();
    % labels = {'Resonant scanner beam position'};
    x = sin(t);
    ti = find(t >= -pi/2 & t <= pi/2);
    plot(t(ti), x(ti), 'LineWidth', 2);
    hold on;
    tt = asin(0.9);
    
    % Imaging fraction of beam. Show voxel positions for slower control system for clarity...
    nsteps_show = 1000000 / 7980;
    t_show = linspace(-pi, pi, nsteps_show);
    x_show = sin(t_show);
    D = 0.9;
    tt = asin(0.9);
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

    p(1,3).select();
    % Power compensation
    p = cos(t);
    pstar = 0.5*(1+cos(t));
    
    %% cos^4 vignetting compensation. Show it for zoom=2.2x, since that's what
    %% pstar is calibrated to. That means that the usable part of the X axis has
    %% size FOV/zoom, the lens working distance
    lens_working_distance = 380; % um
    fov = 666; % um for whole FOV
    zoomlevel = 1.3;
    
    
    convert_phase_dist_to_microns = fov/(D*zoomlevel*2);
    positions_um = sin(t) * convert_phase_dist_to_microns;
    positions_um(2,:) = sqrt(positions_um(1,:).^2 + 200^2);
    %disp(sprintf('Working FOV is %g um', D*(max(positions_um)-min(positions_um))));
    %= lens_working_distance * convert_microns_to_phase_dist;
    % Divide p by predicted vignetting compensation
    cos3 = cos(atan(positions_um./lens_working_distance)).^3;
    cos4 = cos(atan(positions_um./lens_working_distance)).^4;
    
    plot(t(ti), p(ti), 'k', ...
        t(ti), cos3(1,ti), 'c', ...
        t(ti), p(ti)./cos4(1,ti), 'r', ...
        t(ti), p(ti)./cos3(1,ti), 'b');
    %    t(ti), pstar(ti), 'c', ... % Ad-hoc
    ylabel('Power');
    xlabel('Time (phase)');
    % xlim([-pi,pi]);
    % ylim([0 1.1]);
    legend({'Beam speed: cos(t)', 'Vignetting falloff: cos^3(x)', 'Compensation: cos(t)/cos^4(x)', 'Compensation: cos(t)/cos^3(x)' }, ...
        'Location', 'South', 'box', 'off');
    %title('(B) Relative voxel size');
    title(sprintf('(c) X power compensation, FOV = %d \\mu{}m', ...
        round(D*(max(positions_um)-min(positions_um)))));
    %Format
    xlim([-1.8, 1.8]);
    yl = get(gca, 'YLim');
    ylim([0, 1.3]);
    set(gca, 'box', 'off', 'TickDir', 'out');
    set(gca, 'XTick', [-pi/2, 0,pi/2], 'XTickLabel', {'-\pi/2', 0, '\pi/2'})
    set(gca, 'YTick', [0, 0.5, 1, 1.5, 2], 'YTickLabel', [0, 0.5, 1, 1.5, 2])
    %set(gca, 'YLim', [0.35 2]);
    
    %Figure sizing
    %p = get(gcf, 'Position');
    %set(gcf, 'Units', 'inches', 'Position', [p(1) p(2) 5 8])
