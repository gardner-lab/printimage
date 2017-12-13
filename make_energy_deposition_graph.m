function make_energy_deposition_graph(RELOAD)

collection = '400e'; % Or "series" in the UI, but that's a MATLAB function
sz = 400;

methods = {};
methods{end+1} = 'None';
methods{end+1} = 'Speed';
%methods{end+1} = 'fit';
%methods{end+1} = 'both';
%methods{end+1} = 'both2';
%methods{end+1} = 'type';
methods{end+1} = 'Iteration 1';
methods{end+1} = 'Iteration 2';


if nargin == 0
    RELOAD = false;
end

methods_long = methods;
how_much_to_include = 0.05; % How much of the printed structure's size perpendicular to the direction of the sliding motion

FOV = 666; % microns
speed = 100; % um/s of the sliding stage
frame_rate = 15.21; % Hz
frame_spacing = speed / frame_rate;
sweep_halfsize = 500;

colours = [0 0 0; ...
    1 0 0; ...
    0 0.5 0; ...
    0 0 1; ...
    0 1 1];
%colours = distinguishable_colors(length(methods));

image_crop_x = 10;
image_crop_y = 40;

figure(23);
if exist('p', 'var')
    delete(p);
end

p = panel();

last_filename = sprintf('last_falloff_%s.mat', collection);

tic
if RELOAD & exist(last_filename, 'file')
    load(last_filename);
else
    if exist(sprintf('vignetting_cal_%s.tif', collection), 'file')
        tiffCal = double(imread(sprintf('vignetting_cal_%s.tif', collection)));
    elseif exist(sprintf('vignetting_cal_%s_00001_00001.tif', collection), 'file')
        tiffCal = double(imread(sprintf('vignetting_cal_%s_00001_00001.tif', collection)));
    elseif exist(sprintf('vignetting_cal.tif', collection), 'file')
        tiffCal = double(imread('vignetting_cal.tif'));
    else
        warning('No baseline calibration file ''%s'' found.', ...
            sprintf('vignetting_cal_%s.tif', collection));
        tiffCal = ones(512, 512);
    end
    
    for f = 1:length(methods)
        try
            tiffS{f} = double(imread(sprintf('slide_%s_%s_image_00001_00001.tif', methods{f}, collection)));
            disp(sprintf('Loaded ''slide_%s_%s_image_00001_00001.tif''', methods{f}, collection));
            methodsValid(f) = 1;
        catch ME
            disp(sprintf('Could not load ''slide_%s_%s_image_00001_00001.tif''', methods{f}, collection));
            methodsValid(f) = 0;
            continue;
        end
        tiffS{f} = tiffS{f} ./ tiffCal;
        tiffS{f} = tiffS{f}(1+image_crop_y:end-image_crop_y, 1+image_crop_x:end-image_crop_x);
        
        try
            tiffAdj{f} = load(sprintf('slide_%s_%s_adj.mat', methods{f}, collection));
            tiffFit{f} = load(sprintf('slide_%s_%s_fit.mat', methods{f}, collection));
            % Oops. I saved the whole thing, which means one copy per
            % Zstack layer.
            tiffAdj{f}.p = tiffAdj{f}.p(:,:,1);
        catch ME
            ME
        end
    end
        
%    save(last_filename, 'tiffCal', 'tiffX', 'tiffY', ...
%        'tiffS', 'tiffAdj', 'scanposX', 'scanposY', ...
%        'baselineX', 'baselineY', 'methodsValid', ...
%        'methods', 'methods_long', 'bright_x', 'bright_y', ...
%        'bright_x_std', 'bright_y_std', 'indices', 'baseline_indices');
end
disp(sprintf('Loaded data in %d seconds.', round(toc)));


letter = 'c';
for i = find(methodsValid)
    letter = char(letter+1);
    methods2{i} = sprintf('(%c) %s', letter, methods_long{i});
end

p.pack('v', {25 [] }, 1);
p(1,1).marginbottom = 100;
make_sine_plot_3(p(1,1));
%make_sine_plot_4(p(1,1), tiffAdj, methods, colours);



p(2,1).pack(1, sum(methodsValid));

c = 0;
for f = find(methodsValid)
    c = c + 1;
    
    centreX = round(length(tiffAdj{f}.xc) / 2);
    centreY = round(length(tiffAdj{f}.yc) / 2);
    tiffAdj{f}.p = tiffAdj{f}.p / tiffAdj{f}.p(centreX, centreY);
    
    p(2,1, 1,c).pack(3, 1);
    h_axes = p(2,1, 1,c, 1,1).select();
    cla;
    
    if exist('tiffAdj', 'var') & length(tiffAdj) >= f & ~isempty(tiffAdj{f})
        if false
            % Show power compensation function as a colormap

            [~,cf] = contourf(tiffAdj{f}.xc, tiffAdj{f}.yc, tiffAdj{f}.p', 100, ...
                'LineColor', 'none');
            
            cffigpos = get(get(cf, 'Parent'), 'Position');
            %surf(tiffAdj{f}.xc, tiffAdj{f}.yc, tiffAdj{f}.p');
            axis equal ij off;
            colo = colorbar('Location', 'WestOutside');
            set(colo, 'Position', get(colo, 'Position') .* [1 0 1 0] + cffigpos .* [0 1 0 1]);
            
            title(methods2{f});
        else
            % Show power compensation function as a surface
            
            h = surf(tiffAdj{f}.xc(1:5:end), tiffAdj{f}.yc(1:20:end), ...
                tiffAdj{f}.p(1:5:end,1:20:end)');
            %cffigpos = get(get(cf, 'Parent'), 'Position');
            %surf(tiffAdj{f}.xc, tiffAdj{f}.yc, tiffAdj{f}.p');
            %axis equal ij off;
            %colormap jet;
            %colo = colorbar('Location', 'WestOutside');
            %set(colo, 'Position', get(colo, 'Position') .* [1 0 1 0] + cffigpos .* [0 1 0 1]);
            xlabel('x (\mu{}m)');
            ylabel('y (\mu{}m)');
            zlabel('Power');
            set(gca, 'xlim', [-290 290], 'ylim', [-290 290], 'zlim', [0.5 1.8], ...
                'xtick', [-200 0 200], 'ytick', [-200 0 200]);
            title(methods2{f});
        end
    end
    
            
    p(2,1, 1,c, 2,1).select();
    cla;
    
    % Manual gain control
    %foo = max(foo - 0.4, 0.65);
    foo = tiffS{f};
    foo(1,1) = 0; % Stupid kludge: image() isn't scaling right; force imagesc() to do so.
    foo = min(foo, 1);
    foo = max(foo, 0.2);
    imagesc(foo);
    axis tight equal ij off;
    
    
    p(2,1, 1,c, 3,1).select();
    
    % h = plot( tiffAdj{f}.fitresult, [tiffAdj{f}.xData, tiffAdj{f}.yData], tiffAdj{f}.zData );
    h = plot( tiffFit{f}.fitresult );
    %shading interp;
    %legend( h, 'untitled fit 1', 'z vs. x, y', 'Location', 'NorthEast' );
    % Label axes
    xlabel x
    ylabel y
    zlabel brightness
    grid on
    %view( -32.7, 15.6 );
    set(gca, 'ZLim', [0.2 0.9]);
    
    %p(2,1,1,c,2).select();
    %hist(foo(:), 100);
    %colormap gray;
    drawnow;
end


colormap jet;

%Figure sizing
%pos = get(gcf, 'Position');
%set(gcf, 'Units', 'inches', 'Position', [pos(1) pos(2) 10 8])
%p.export('BeamGraph.eps', '-w240', '-a1.2');
p.export('BeamGraph.png', '-w240', '-a1.1');
