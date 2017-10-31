function falloff

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

%methods = {'sin', 'adhoc', 'cos4', 'interp'};
methods = {'sin_3', 'adhoc_3', 'interp_3', 'cos^4_3', 'cos^3_3', 'cos3b', 'cos3c'};
methods = {'cos^3_3', 'cos3b', 'cos3c'};
methods = {'sin_5', 'adhoc_5', 'interp_5', 'cos^4_5', 'cos^3_5'};
FOV = 666; % microns
how_much_to_include = .95;
speed = 100; % um/s of the sliding stage
frame_rate = 15.21; % Hz
frame_spacing = speed / frame_rate;
methods2 = strtok(methods, '_');
image_crop_x = 20;
image_crop_y = 40;

figure(16);

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


for f = 1:length(methods)
    subplot(2, length(methods), f)
    imagesc(tiffS{f});
    title(methods2{f});
    axis equal off;
end

subplot(2,2,3);
cla;
h = [];
hold on;
scanposX = (1:size(bright_x, 2)) * frame_spacing;

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
set(gca, 'XLim', [100 900]);
legend(h, strtok(methods, '_'), 'Location', 'North');
title('X brightness');
xlabel('\mu{}m');
ylabel('normalised brightness');

subplot(2,2,4);
cla;
h = [];
hold on;
scanposY = (1:size(bright_y, 2)) * frame_spacing;
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
set(gca, 'XLim', [100 900]);
legend(h, strtok(methods, '_'), 'Location', 'North');
title('Y brightness');
xlabel('\mu{}m');
ylabel('normalised brightness');

ylimits2 = get(gca, 'YLim');
ylimits = [min(ylimits(1), ylimits2(1)) max(ylimits(2), ylimits2(2))];
set(gca, 'YLim', ylimits);
subplot(2,2,3);
set(gca, 'YLim', ylimits);

