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
series = 610;
sz = 400;
% Pixels
CROPX = 40;
CROPY = 40;

if true
    c = 1;
    imgs{c}.file = sprintf('vignetting_cal_00%d_00001.tif', series);
    imgs{c}.desc = 'Ref';
    imgs{c}.method = 'cos4';
    imgs{c}.size = sz;
    
    c = c + 1;
    imgs{c}.file = sprintf('vignetting_sin_00%d_00001.tif', series);
    imgs{c}.desc = 'sine';
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing

    c = c + 1;
    imgs{c}.file = sprintf('vignetting_sin_00%d_00001.tif', series+1);
    imgs{c}.desc = 'sine R';
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing
    imgs{c}.rotated = true;

    c = c + 1;
    imgs{c}.file = sprintf('vignetting_adhoc_00%d_00001.tif', series);
    imgs{c}.desc = 'adhoc';
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing

    c = c + 1;
    imgs{c}.file = sprintf('vignetting_adhoc_00%d_00001.tif', series+1);
    imgs{c}.desc = 'adhoc R';
    imgs{c}.size = sz;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = 0; % microns, after reversing

    c = c + 1;
    imgs{c}.file = sprintf('vignetting_cos4_00%d_00001.tif', series);
    imgs{c}.desc = 'cos4';
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing
    if series == 610
        imgs{c}.cal = 'vignetting_cal_a_00610_00001.tif';
    end
    
    c = c + 1;
    imgs{c}.file = sprintf('vignetting_cos4_00%d_00001.tif', series+1);
    imgs{c}.desc = 'cos4 R';
    imgs{c}.size = sz;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = 0; % microns, after reversing
    if series == 610
        imgs{c}.cal = 'vignetting_cal_a_00610_00001.tif';
    end
    
    c = c + 1;
    imgs{c}.file = sprintf('vignetting_interp_00%d_00001.tif', series);
    imgs{c}.desc = 'interp';
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing

    c = c + 1;
    imgs{c}.file = sprintf('vignetting_interp_00%d_00001.tif', series+1);
    imgs{c}.desc = 'interp R';
    imgs{c}.rotated = true;
    imgs{c}.size = sz;
    imgs{c}.pos_adj = 0; % microns, after reversing

elseif false
    c = 1;
    imgs{c}.file = 'vignetting_empty_00300_00001.tif';
    imgs{c}.desc = 'Ref';
    imgs{c}.method = 'interpolant';
    imgs{c}.size = 500;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_sin_00300_00001.tif';
    imgs{c}.desc = 'sin';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_sin_00300_00001.tif';
    imgs{c}.desc = 'sin 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = -10; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_adhoc_00300_00001.tif';
    imgs{c}.desc = 'adhoc';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_adhoc_00300_00001.tif';
    imgs{c}.desc = 'adhoc 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0; % microns, after reversing
    imgs{c}.rotated = true;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_interp_00300_00001.tif';
    imgs{c}.desc = 'interp';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_interp_00300_00001.tif';
    imgs{c}.desc = 'interp 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = 0; % microns, after reversing
    
    if true
        c = c + 1;
        imgs{c}.file = 'vignetting_cos4_00300_00001.tif';
        imgs{c}.desc = 'cos^4';
        imgs{c}.size = 500;
        imgs{c}.pos_adj = 0;
        
        c = c + 1;
        imgs{c}.file = 'vignetting_f_cos4_00300_00001.tif';
        imgs{c}.desc = 'cos^4 180^\circ';
        imgs{c}.size = 500;
        imgs{c}.rotated = true;
        imgs{c}.pos_adj = 0; % microns, after reversing
    end
    
    if false
        c = c + 1;
        imgs{c}.file = 'vignetting_cos4free_00300_00001.tif';
        imgs{c}.desc = 'cos^4 free';
        imgs{c}.size = 500;
        imgs{c}.pos_adj = 0;
        
        c = c + 1;
        imgs{c}.file = 'vignetting_f_cos4free_00300_00001.tif';
        imgs{c}.desc = 'cos^4 free 180^\circ';
        imgs{c}.size = 500;
        imgs{c}.rotated = true;
        imgs{c}.pos_adj = 0; % microns, after reversing
        
        c = c + 1;
        imgs{c}.file = 'vignetting_cos4gauss_00300_00001.tif';
        imgs{c}.desc = 'cos^4+gauss';
        imgs{c}.size = 500;
        imgs{c}.pos_adj = 0;
        
        c = c + 1;
        imgs{c}.file = 'vignetting_f_cos4gauss_00300_00001.tif';
        imgs{c}.desc = 'cos^4+gauss 180^\circ';
        imgs{c}.size = 500;
        imgs{c}.rotated = true;
        imgs{c}.pos_adj = 0; % microns, after reversing
    end
elseif false
    c = 1;
    imgs{c}.file = 'vignetting_zero_00200_00001.tif';
    imgs{c}.desc = 'Ref';
    
    c = c + 1;
    imgs{c}.file = 'vignetting_sin_00200_00001.tif';
    imgs{c}.desc = 'sin';
    imgs{c}.size = 450;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_sin_00200_00001.tif';
    imgs{c}.desc = 'sin 180^\circ';
    imgs{c}.size = 450;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = -10; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_adhoc_00200_00001.tif';
    imgs{c}.desc = 'adhoc';
    imgs{c}.size = 450;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_adhoc_00200_00001.tif';
    imgs{c}.desc = 'adhoc 180^\circ';
    imgs{c}.size = 450;
    imgs{c}.pos_adj = -10;
    imgs{c}.rotated = true;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_interp_00200_00001.tif';
    imgs{c}.desc = 'interp';
    imgs{c}.size = 450;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_interp_00200_00001.tif';
    imgs{c}.desc = 'interp 180^\circ';
    imgs{c}.size = 450;
    imgs{c}.rotated = true;
    imgs{c}.pos_adj = 0; % microns, after reversing
end


calibration_imgs = [1];

FOV = 666; % microns

for i = 1:length(imgs)
    imgs{i}.data = double(imread(imgs{i}.file));
    
    if isfield(imgs{i}, 'cal')
        cal_for_this_one = double(imread(imgs{i}.cal));
        imgs{i}.data_normed = imgs{i}.data ./ cal_for_this_one;
    else
        imgs{i}.data_normed = imgs{i}.data ./ imgs{1}.data;
    end
    
    if isfield(imgs{i}, 'rotated') & imgs{i}.rotated
        % Unrotate
        imgs{i}.data = imgs{i}.data(end:-1:1, end:-1:1);
        imgs{i}.data_normed = imgs{i}.data_normed(end:-1:1, end:-1:1);
    end

    if any(i == calibration_imgs)
        imgs{i}.vignetting_fit = fit_vignetting_falloff(imgs{i}.file, imgs{i}.method, 666);
    end
end

MicronsPerPixel = FOV / size(imgs{1}.data, 2);

pixelpos = linspace(-333, 333, size(imgs{1}.data, 1));

for i = 1:length(imgs)
    % left/right shift: microns -> pixels
    if isfield(imgs{i}, 'pos_adj')
        npixels = round(imgs{i}.pos_adj / MicronsPerPixel);
        if npixels > CROPX
            npixels = CROPX;
        end
    else
        npixels = 0;
    end
    imgs{i}.data = imgs{i}.data(1+CROPY:end-CROPY, 1+CROPX-npixels:end-CROPX-npixels);
    imgs{i}.data_normed = imgs{i}.data_normed(1+CROPY:end-CROPY, 1+CROPX-npixels:end-CROPX-npixels);
end

pixelposX = pixelpos(1+CROPX:end-CROPX);
pixelposY = pixelpos(1+CROPY:end-CROPY);
pixelposY = pixelposY(end:-1:1);

n_real_imgs = length(imgs);

% Combine images and their flipped counterparts
for i = 2:2:n_real_imgs
    c = c + 1;
    imgs{c}.desc = sprintf('%s + rev', imgs{i}.desc);
    imgs{c}.size = imgs{i}.size;
    imgs{c}.data = (imgs{i}.data + imgs{i+1}.data)/2;
    imgs{c}.data_normed = (imgs{i}.data_normed + imgs{i+1}.data_normed)/2;
end


[px, py] = meshgrid(pixelposX, pixelposY);

sp1 = length(imgs);
sp2 = 4;
hFig = figure(12);


for i = 1:length(imgs)
    if any(calibration_imgs == i)
        % Vignetting fits

        imgs{i}.vignetting_falloff = imgs{i}.vignetting_fit(px, py);
        %imgs{i}.vignetting_falloff = imgs{i}.vignetting_falloff * max(max(imgs{i}.data));
        range1 = [min(imgs{i}.data(:)) max(imgs{i}.data(:))];
        range2 = [min(imgs{i}.vignetting_falloff(:)) max(imgs{i}.vignetting_falloff(:))];
        %imgs{i}.vignetting_falloff = (imgs{i}.vignetting_falloff - range2(1)) ...
        %    * (range1(2) / range1(1)) / (range2(2) / range2(1));
        imgs{i}.vignetting_falloff = (imgs{i}.vignetting_falloff - range2(1)) * range1(2);
        mn = min(min(imgs{i}.data));
        mn = 100;
        imgs{i}.vignetting_falloff(find(imgs{i}.vignetting_falloff <= mn)) = mn;
    
        subplot(sp1, sp2, (i-1)*sp2+2);
        imagesc(imgs{i}.data);
        axis off xy equal;
        % colorbar;
        xlabel(imgs{i}.desc);
    else
        % Raw data / calibration images
        subplot(sp1, sp2, (i-1)*sp2+1);
        imagesc(imgs{i}.data);
        if ~mod(i, 2)
            ylabel(imgs{i}.desc);
        end
        % colorbar;
        axis xy equal;

        set(gca, 'xtick', [], 'ytick', [], 'box', 'off');

        % Save baseline luminance for zero-power region
        imgs{i}.zeropowerX_i = find((pixelposX < -imgs{i}.size/2 - 10 & pixelposX > -imgs{i}.size/2 - 20) ...
            | (pixelposX > imgs{i}.size/2 + 10 & pixelposX < imgs{i}.size/2 + 20));
        imgs{i}.zeropowerY_i = find((pixelposY < -imgs{i}.size/2 - 10 & pixelposY > -imgs{i}.size/2 - 20) ...
            | (pixelposY > imgs{i}.size/2 + 10 & pixelposY < imgs{i}.size/2 + 20));

        % Plotting
        subplot(sp1, sp2, (i-1)*sp2+2);
        imagesc(imgs{i}.data_normed);
        axis xy equal off;
        % colorbar;
    end
end

colours = distinguishable_colors(length(imgs));
h = [];
l = {};
ylimits = [Inf -Inf];
for i = 2:length(imgs)    
    samplesY = round(0.9*(imgs{i}.size/2)/MicronsPerPixel);
    
    middleX = round(size(imgs{i}.data_normed, 2) ./ 2);
    middleY = round(size(imgs{i}.data_normed, 1) ./ 2);
    AVG{i} = mean(imgs{i}.data_normed(middleY-samplesY:middleY+samplesY, :), 1);
    % Bring object down to baseline of 0
    AVG{i} = AVG{i} - mean(AVG{i}(middleX-2:middleX+2));
    % Bring unprinted background up to 1
    AVG{i} = AVG{i} / mean(AVG{i}(imgs{i}.zeropowerX_i));
    STD{i} = std(imgs{i}.data_normed(middleY-samplesY:middleY+samplesY, :), [], 1);
    
    subplot(sp1, sp2, (i-1)*sp2+3);
    H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(sqrt(2*samplesY+1)));
    axis tight;
    a = get(gca, 'YLim');
    ylimits = [min(a(1), ylimits(1)) max(a(2), ylimits(2))];
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end

% All the plots should have the same scale.
ylimits(2) = 1.2;
for i = 2:length(imgs)
    subplot(sp1, sp2, (i-1)*sp2+3);
    set(gca, 'YLim', ylimits, 'XLim', [pixelposX(1) pixelposX(end)]);
end
xlabel('X position');


% A separate plot of the combined fits.
figure(14);
subplot(1,2,1);
cla;
hold on;
colours = distinguishable_colors(length(imgs)-n_real_imgs);
h = [];
l = {};
for i = n_real_imgs+1:length(imgs)
    H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(2*samplesY+1), ...
        'lineprops', {'Color', colours(i-n_real_imgs,:)}, 'transparent', 1);
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end
hold off;
grid on;
legend(h, l, 'Location', 'North');
title('Brightness vs. X');
axis tight;
xlabel('X position (\mu{}m)');
ylabel('Normalised brightness');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Now, do the same thing over the Y axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(12);
h = [];
l = {};
ylimits = [Inf -Inf];
for i = 2:length(imgs)    
    samplesX = round(0.9*(imgs{i}.size/2)/MicronsPerPixel);
    
    middleX = round(size(imgs{i}.data_normed, 2) ./ 2);
    middleY = round(size(imgs{i}.data_normed, 1) ./ 2);
    AVG{i} = mean(imgs{i}.data_normed(:, middleX-samplesX:middleX+samplesX), 2);
    % Bring object down to baseline of 0
    AVG{i} = AVG{i} - mean(AVG{i}(middleY-2:middleY+2));
    % Bring unprinted background up to 1
    AVG{i} = AVG{i} / mean(AVG{i}(imgs{i}.zeropowerY_i));
    STD{i} = std(imgs{i}.data_normed(:, middleX-samplesX:middleX+samplesX), [], 2);
    
    subplot(sp1, sp2, (i-1)*sp2+4);
    H = shadedErrorBar(pixelposY, AVG{i}, 1.96*STD{i}/sqrt(2*samplesX+1));
    axis tight;
    a = get(gca, 'YLim');
    ylimits = [min(a(1), ylimits(1)) max(a(2), ylimits(2))];
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end

% All the plots should have the same scale.
ylimits(2) = 1.2;
for i = 2:length(imgs)
    subplot(sp1, sp2, (i-1)*sp2+4);
    set(gca, 'YLim', ylimits, 'XLim', [pixelposX(1) pixelposX(end)]);
end
xlabel('Y position');

% A separate plot of the combined fits.
figure(14);
subplot(1,2,2);
cla;
hold on;
colours = distinguishable_colors(length(imgs)-n_real_imgs);
h = [];
l = {};
for i = n_real_imgs+1:length(imgs)
    H = shadedErrorBar(pixelposY, AVG{i}, 1.96*STD{i}/sqrt(2*samplesX+1), ...
        'lineprops', {'Color', colours(i-n_real_imgs,:)}, 'transparent', 1);
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end
hold off;
grid on;
legend(h, l, 'Location', 'North');
title('Brightness vs. Y');
axis tight;
xlabel('Y position (\mu{}m)');
ylabel('Normalised brightness');




