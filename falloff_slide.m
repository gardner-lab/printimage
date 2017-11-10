function falloff_slide

%addpath('~/Downloads');

%imgs{1}.file = 'picture_00006_00001.tif';
%imgs{1}.desc = 'Ref 1';
%imgs{2}.file = 'picture_00007_00001.tif';
%imgs{2}.desc = 'Cube a (500 \mu{}m)';
%imgs{2}.size = 500;

% 400: left-to-right in original rotation: interpolant, cos4, ad-hoc, sine

% 600: left-to-right in original rotation: interpolant, cos4, ad-hoc, sine
% a+b*cos...

% 3: left-to-right: sin, interp, cos3, cos4, adhoc

% 610: same order
% cos(ax^2+b^2...)

collection = '15'; % Or "series" in the UI, but that's a MATLAB function
sz = 500;

methods = {'none', 'speed', 'vignetting', 'both'};%, 'interp', 'cos^4', 'cos^3'};
methods_long = {'None', 'Speed only', 'Vignetting only', 'Both'};%, 'Fit from data', 'Cos^4 model', 'Cos^3 model'};
%methods = {'300', '380', '400'};
%methods_long = methods;
FOV = 666; % microns
how_much_to_include = .2;
speed = 100; % um/s of the sliding stage
frame_rate = 15.21; % Hz
frame_spacing = speed / frame_rate;

colours = [0 0 0; ...
    0 0.5 0; ...
    1 0 0; ...
    0 0 1; ...
    1 0 1];

letter = 'c';
for i = 1:length(methods)
    letter = char(letter+1);
    methods2{i} = sprintf('(%c) %s', letter, methods_long{i});
end
image_crop_x = 10;
image_crop_y = 40;

figure(23);
if exist('p', 'var')
    delete(p);
end
p = panel();
p.pack(3, 1);
p(1,1).marginbottom = 100;
make_sine_plot_3(p(1,1));

if exist(sprintf('vignetting_cal_%s.tif', collection), 'file')
    tiffCal = double(imread(sprintf('vignetting_cal_%s.tif', collection)));
elseif exist(sprintf('vignetting_cal_%s_00001_00001.tif', collection), 'file')
    tiffCal = double(imread(sprintf('vignetting_cal_%s_00001_00001.tif', collection)));
else
    warning('No baseline calibration file ''%s'' found.', ...
        sprintf('vignetting_cal_%s.tif', collection));
    tiffCal = ones(512, 512);
end

for f = 1:length(methods)
    try
        tiffS{f} = double(imread(sprintf('slide_%s_%s_image_00001_00001.tif', methods{f}, collection)));
        methodsValid(f) = 1;
    catch ME
        methodsValid(f) = 0;
        continue;
    end
    tiffS{f} = tiffS{f} ./ tiffCal;
    tiffS{f} = tiffS{f}(1+image_crop_y:end-image_crop_y, 1+image_crop_x:end-image_crop_x);
    
    tiffX{f} = [];
    i = 0;
    try
        while true
            i = i + 1;
            t = imread(sprintf('slide_%s_%s_x_00001_00001.tif', methods{f}, collection), i);
            tiffX{f}(i,:,:) = double(t) ./ tiffCal;
        end
    catch ME
    end
    
    
    middle = round(size(tiffX{f}, 3)/2);
    pixelpos = linspace(-FOV/2, FOV/2, size(tiffX{f}, 2));
    indices = find(pixelpos > -how_much_to_include * sz / 2 ...
        & pixelpos < how_much_to_include * sz / 2);
    
    % Normalise brightness
    baselineX = mean(mean(tiffX{f}(1:30,indices,middle), 2), 1);
    tiffX{f} = tiffX{f}/baselineX;
    
    bright_x(f,:) = mean(tiffX{f}(:, indices, middle), 2);
    bright_x_std(f,:) = std(tiffX{f}(:,indices, middle), [], 2);
    
    tiffY{i} = [];
    i = 0;
    try
        while true
            i = i + 1;
            t = imread(sprintf('slide_%s_%s_y_00001_00001.tif', methods{f}, collection), i);
            tiffY{f}(i,:,:) = double(t) ./ tiffCal;
        end
    catch ME
    end
    
    % Normalise brightness
    baselineY = mean(mean(tiffY{f}(1:30,middle,indices), 3), 1);
    tiffY{f} = tiffY{f}/baselineY;
    
    
    bright_y(f,:) = mean(tiffY{f}(:, middle, indices), 3);
    bright_y_std(f,:) = std(tiffY{f}(:, middle, indices), [], 3);
end


p(2,1).pack(1, length(methods));

for f = 1:length(methods)
    if ~methodsValid(f)
        continue;
    end
    p(2,1, 1,f).select();
    cla;
    
    foo = tiffS{f};
    % Manual gain control :)
    foo = min((foo - min(min(tiffS{f}))), 0.7);
    foo = min(tiffS{f}, 1.2);
    
    imagesc(foo);
    title(methods2{f});
    axis equal ij off;
    colormap gray;
end

p(3,1).pack(1, 2);
p(3,1,1,1).select();
cla;
h = [];
hold on;
scanposX = (1:size(bright_x, 2)) * frame_spacing - 500;

for f = 1:length(methods)
    if ~methodsValid(f)
        continue;
    end

    H = shadedErrorBar(scanposX, ...
        bright_x(f,:), ...
        1.96*bright_x_std(f,:)/sqrt(length(indices)), ...
        'lineprops', {'Color', colours(f,:)}, ...
        'transparent', 1);
    h(end+1) = H.mainLine;
end
hold off;
axis tight;
grid on;
ylimits = get(gca, 'YLim');
set(gca, 'XLim', [-400 400]);
legend(h, methods_long(find(methodsValid)), 'Location', 'North');
letter = letter + 1;
title(sprintf('(%c) X brightness', letter));
xlabel('\mu{}m');
ylabel('normalised brightness');

p(3,1,1,2).select();
cla;
h = [];
hold on;
scanposY = (1:size(bright_y, 2)) * frame_spacing - 500;
for f = 1:length(methods)
    if ~methodsValid(f)
        continue;
    end

    H = shadedErrorBar(scanposY, ...
        bright_y(f,:), ...
        1.96*bright_y_std(f,:)/sqrt(length(indices)), ...
        'lineprops', {'Color', colours(f,:)}, ...
        'transparent', 1);
    h(end+1) = H.mainLine;
end
hold off;
axis tight;
set(gca, 'XLim', [-400 400]);
grid on;
legend(h, methods_long(find(methodsValid)), 'Location', 'North');
letter = letter + 1;
title(sprintf('(%c) Y brightness', letter));
xlabel('\mu{}m');
ylabel('normalised brightness');

ylimits2 = get(gca, 'YLim');
ylimits = [min(ylimits(1), ylimits2(1)) max(ylimits(2), ylimits2(2))];
set(gca, 'YLim', ylimits);
p(3,1,1,1).select();
%set(gca, 'YLim', ylimits);

%Figure sizing
%pos = get(gcf, 'Position');
%set(gcf, 'Units', 'inches', 'Position', [pos(1) pos(2) 10 8])
%p.export('BeamGraph.eps', '-w240', '-a1.2');
%p.export('BeamGraph.png', '-w240', '-a1.2');
