%function falloff
clear
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
sz = 500;


methods = {'sin_6', 'interp_6', 'cos^4_6', 'cos^3_6'};
FOV = 666; % microns
how_much_to_include = .95;
speed = 100; % um/s of the sliding stage
frame_rate = 15.21; % Hz
frame_spacing = speed / frame_rate;

letter = 'c';
for i = 1:length(methods)
    letter = char(letter+1);
    methods2{i} = sprintf('(%c) %s', letter, strtok(methods{i}, '_'));
end
image_crop_x = 20;
image_crop_y = 40;

figure(19);
if exist('p', 'var')
    delete(p);
end
p = panel();
p.pack(3, 1);
p(1,1).marginbottom = 100;
make_sine_plot_3(p(1,1));

tiffCal = double(imread('vignetting_cal_00001_00001.tif'));

for f = 1:length(methods)
    tiffS{f} = double(imread(sprintf('slide_%s_image_00001_00001.tif', methods{f})));
    tiffS{f} = tiffS{f} ./ tiffCal;
    tiffS{f} = tiffS{f}(1+image_crop_y:end-image_crop_y, 1+image_crop_x:end-image_crop_x);
    
    tiffX{f} = [];
    i = 0;
    try
        while true
            i = i + 1;
            tiffX{f}(i,:,:) = imread(sprintf('slide_%s_x_00001_00001.tif', methods{f}), i);
        end
    catch ME
    end
    tiffX{f} = double(tiffX{f});
    
    
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
            tiffY{f}(i,:,:) = imread(sprintf('slide_%s_y_00001_00001.tif', methods{f}), i);
        end
    catch ME
    end
    tiffY{f} = double(tiffY{f});
    
    % Normalise brightness
    baselineY = mean(mean(tiffY{f}(1:30,middle,indices), 3), 1);
    tiffY{f} = tiffY{f}/baselineY;
    
    
    bright_y(f,:) = mean(tiffY{f}(:, middle, indices), 3);
    bright_y_std(f,:) = std(tiffY{f}(:, middle, indices), [], 3);
end

colours = distinguishable_colors(length(methods));


p(2,1).pack(1, length(methods));

for f = 1:length(methods)
    p(2,1, 1,f).select();
    cla;
    foo = min((tiffS{f} - min(min(tiffS{f}))), 2);
    
    imagesc(foo);
    title(methods2{f});
    axis equal off;
    colormap gray;
end

p(3,1).pack(1, 2);
p(3,1,1,1).select();
cla;
h = [];
hold on;
scanposX = (1:size(bright_x, 2)) * frame_spacing - 500;

for f = 1:length(methods)
    H = shadedErrorBar(scanposX, ...
        bright_x(f,:), ...
        1.96*bright_x_std(f,:)/sqrt(length(indices)), ...
        'lineprops', {'Color', colours(f,:)}, ...
        'transparent', 1);
    h(end+1) = H.mainLine;
end
hold off;
axis tight;
ylimits = get(gca, 'YLim');
set(gca, 'XLim', [-400 400]);
legend(h, strtok(methods, '_'), 'Location', 'North');
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
legend(h, strtok(methods, '_'), 'Location', 'North');
letter = letter + 1;
title(sprintf('(%c) Y brightness', letter));
xlabel('\mu{}m');
ylabel('normalised brightness');

ylimits2 = get(gca, 'YLim');
ylimits = [min(ylimits(1), ylimits2(1)) max(ylimits(2), ylimits2(2))];
set(gca, 'YLim', ylimits);
p(3,1,1,1).select();
set(gca, 'YLim', ylimits);

%Figure sizing
%pos = get(gcf, 'Position');
%set(gcf, 'Units', 'inches', 'Position', [pos(1) pos(2) 10 8])
p.export('beamgraph.eps', '-w250', '-a1.2');