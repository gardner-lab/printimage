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

% 610: same order
% cos(ax^2+b^2...)
sz = 500;

%methods = {'sin', 'adhoc', 'cos4', 'interp'};
methods = {'sin_a', 'cos4_a'}
FOV = 666; % microns
how_much_to_include = .9;

figure(17);
for f = 1:length(methods)
    tiffx{f} = [];
    i = 0;    
    try
        while true
            i = i + 1;
            tiffx{f}(i,:,:) = imread(sprintf('slide_%s_%d_x_00001_00001.tif', methods{f}, sz), i);
        end
    catch ME
    end
    tiffx{f} = double(tiffx{f});
    
    
    middle = round(size(tiffx{f}, 3)/2);
    pixelpos = linspace(-FOV/2, FOV/2, size(tiffx{f}, 2));
    indices = find(pixelpos > -how_much_to_include * sz / 2 ...
        & pixelpos < how_much_to_include * sz / 2);
    
    bright_x(f,:) = mean(tiffx{f}(:, indices, middle), 2);
    bright_x_std(f,:) = std(tiffx{f}(:,indices, middle), [], 2);
    
    tiffy{i} = [];
    i = 0;
    try
        while true
            i = i + 1;
            tiffy{f}(i,:,:) = imread(sprintf('slide_%s_%d_y_00001_00001.tif', methods{f}, sz), i);
        end
    catch ME
    end
    tiffy{f} = double(tiffy{f});
    
    bright_y(f,:) = mean(tiffy{f}(:, middle, indices), 3);
    bright_y_std(f,:) = std(tiffy{f}(:, middle, indices), [], 3);
end



colours = distinguishable_colors(length(methods));

subplot(1,2,1);
cla;
h = [];
hold on;
scanposX = 1:size(bright_x, 2);
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
set(gca, 'XLim', [1 size(bright_x, 2)]);
legend(h, methods, 'Location', 'North');
title('X brightness');

subplot(1,2,2);
cla;
h = [];
hold on;
scanposY = 1:size(bright_y, 2);
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
set(gca, 'XLim', [1 size(bright_x, 2)]);
legend(h, methods, 'Location', 'North');
title('Y brightness');

ylimits2 = get(gca, 'YLim');
ylimits = [min(ylimits(1), ylimits2(1)) max(ylimits(2), ylimits2(2))];
set(gca, 'YLim', ylimits);
subplot(1,2,1);
set(gca, 'YLim', ylimits);

