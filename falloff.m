function falloff

%addpath('~/Downloads');

%imgs{1}.file = 'picture_00006_00001.tif';
%imgs{1}.desc = 'Ref 1';
%imgs{2}.file = 'picture_00007_00001.tif';
%imgs{2}.desc = 'Cube a (500 \mu{}m)';
%imgs{2}.size = 500;

% 400: left-to-right: cos4+gauss, cos4, cos4free
if true
    c = 1;
    imgs{c}.file = 'vignetting_empty_00300_00001.tif';
    imgs{c}.desc = 'Ref';
    imgs{c}.method = 'interpolant';
    
    c = c + 1;
    imgs{c}.file = 'vignetting_sin_00300_00001.tif';
    imgs{c}.desc = 'sin';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_sin_00300_00001.tif';
    imgs{c}.desc = 'sin 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.reverse = true;
    imgs{c}.pos_adj = -10; % microns, after reversing
    
    c = c + 1;
    imgs{c}.file = 'vignetting_adhoc_00300_00001.tif';
    imgs{c}.desc = 'adhoc';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_adhoc_00300_00001.tif';
    imgs{c}.desc = 'adhoc 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = -10;
    imgs{c}.reverse = true;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_interp_00300_00001.tif';
    imgs{c}.desc = 'interp';
    imgs{c}.size = 500;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_interp_00300_00001.tif';
    imgs{c}.desc = 'interp 180^\circ';
    imgs{c}.size = 500;
    imgs{c}.reverse = true;
    imgs{c}.pos_adj = 0; % microns, after reversing
    
    if false
        c = c + 1;
        imgs{c}.file = 'vignetting_cos4_00300_00001.tif';
        imgs{c}.desc = 'cos^4';
        imgs{c}.size = 500;
        imgs{c}.pos_adj = 0;
        
        c = c + 1;
        imgs{c}.file = 'vignetting_f_cos4_00300_00001.tif';
        imgs{c}.desc = 'cos^4 180^\circ';
        imgs{c}.size = 500;
        imgs{c}.reverse = true;
        imgs{c}.pos_adj = 0; % microns, after reversing
        
        c = c + 1;
        imgs{c}.file = 'vignetting_cos4free_00300_00001.tif';
        imgs{c}.desc = 'cos^4 free';
        imgs{c}.size = 500;
        imgs{c}.pos_adj = 0;
        
        c = c + 1;
        imgs{c}.file = 'vignetting_f_cos4free_00300_00001.tif';
        imgs{c}.desc = 'cos^4 free 180^\circ';
        imgs{c}.size = 500;
        imgs{c}.reverse = true;
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
        imgs{c}.reverse = true;
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
    imgs{c}.reverse = true;
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
    imgs{c}.reverse = true;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_interp_00200_00001.tif';
    imgs{c}.desc = 'interp';
    imgs{c}.size = 450;
    imgs{c}.pos_adj = 0;
    
    c = c + 1;
    imgs{c}.file = 'vignetting_f_interp_00200_00001.tif';
    imgs{c}.desc = 'interp 180^\circ';
    imgs{c}.size = 450;
    imgs{c}.reverse = true;
    imgs{c}.pos_adj = 0; % microns, after reversing
end


calibration_imgs = [1];

FOV = 666; % microns

for i = 1:length(imgs)
    imgs{i}.data = imread(imgs{i}.file);
    if isfield(imgs{i}, 'reverse') & imgs{i}.reverse
        imgs{i}.data = imgs{i}.data(end:-1:1, end:-1:1);
    end
    if any(i == calibration_imgs)
        imgs{i}.vignetting_fit = fit_vignetting_falloff(imgs{i}.file, imgs{i}.method, 666);
    end
end

MicronsPerPixel = FOV / size(imgs{1}.data, 2);

pixelpos = linspace(-333, 333, size(imgs{1}.data, 1));

% Pixels
CROPX = 40;
CROPY = 40;
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
    imgs{i}.data = double(imgs{i}.data(1+CROPY:end-CROPY, 1+CROPX-npixels:end-CROPX-npixels));
end

pixelposX = pixelpos(1+CROPX:end-CROPX);
pixelposY = pixelpos(1+CROPY:end-CROPY);
pixelposY = pixelposY(end:-1:1);

n_real_imgs = length(imgs);

% Combine images and their flipped counterparts
for i = 2:2:n_real_imgs
    c = c + 1;
    imgs{c}.desc = sprintf('%s comb', imgs{i}.desc);
    imgs{c}.size = imgs{i}.size;
    imgs{c}.data = (imgs{i}.data + imgs{i+1}.data)/2;
end


[px, py] = meshgrid(pixelposX, pixelposY);

sp1=length(imgs);
sp2=3;
figure(12);


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
        axis off xy;
        % colorbar;
        title(imgs{i}.desc);
        
        subplot(sp1, sp2, (i-1)*sp2+3);
        imagesc(imgs{i}.vignetting_falloff);
        axis off xy;
        % colorbar;
        title(strcat(imgs{i}.desc, ' model'));
    else
        % Raw data / calibration images
        subplot(sp1, sp2, (i-1)*sp2+1);
        imagesc(imgs{i}.data);
        title(imgs{i}.desc);
        % colorbar;
        axis xy;
        axis off;

        imgs2{i}.data = imgs{i}.data ./ imgs{1}.data;
        imgs2{i}.data_f = imgs{i}.data ./ imgs{1}.vignetting_falloff;
        ulim = max(max(imgs2{i}.data));
        imgs2{i}.data_f(find(imgs2{i}.data_f > ulim)) = ulim;
        
        % Save baseline luminance for zero-power region
        imgs2{i}.zeropower_i = find((pixelposX < -imgs{i}.size/2 - 10 & pixelposX > -imgs{i}.size/2 - 20) ...
            | (pixelposX > imgs{i}.size/2 + 10 & pixelposX < imgs{i}.size/2 + 20));

        % Plotting
        subplot(sp1, sp2, (i-1)*sp2+2);
        imagesc(imgs2{i}.data);
        axis off xy;
        % colorbar;
        title(strcat(imgs{i}.desc, ' /  ', imgs{1}.desc));
    end
end



colours = distinguishable_colors(length(imgs));
h = [];
l = {};
ylimits = [Inf -Inf];
for i = 1:length(imgs)
    if isempty(imgs2{i})
        continue;
    end
    
    samplesY = round(0.95*(imgs{i}.size/2)/MicronsPerPixel);
    
    middleX = round(size(imgs2{i}.data, 2) ./ 2);
    middleY = round(size(imgs2{i}.data, 1) ./ 2);
    AVG{i} = mean(imgs2{i}.data(middleY-samplesY:middleY+samplesY, :), 1);
    % Bring object down to baseline of 0
    AVG{i} = AVG{i} - mean(AVG{i}(middleX-2:middleX+2));
    % Bring unprinted background up to 1
    AVG{i} = AVG{i} / mean(AVG{i}(imgs2{i}.zeropower_i));
    STD{i} = std(imgs2{i}.data(middleY-samplesY:middleY+samplesY, :), [], 1);
    
    subplot(sp1, sp2, (i-1)*sp2+3);
    H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(length(samplesY)));
    axis tight;
    a = get(gca, 'YLim');
    ylimits = [min(a(1), ylimits(1)) max(a(2), ylimits(2))];
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end
%hold off;
%grid on;
%legend(h, l);
%title('Brightness / Ref');
%axis tight;

ylimits(2) = 1.2;
for i = 2:length(imgs)
    subplot(sp1, sp2, (i-1)*sp2+3);
    set(gca, 'YLim', ylimits);
end

figure(14);
cla;
hold on;
colours = distinguishable_colors(length(imgs)-n_real_imgs);
h = [];
l = {};
for i = n_real_imgs+1:length(imgs)
    H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(length(samplesY)), ...
        'lineprops', {'Color', colours(i-n_real_imgs,:)}, 'transparent', 1);
    grid on;
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end
hold off;
grid on;
legend(h, l);
title('Brightness / Ref');
axis tight;
xlabel('\mu{}m');
ylabel('Normalised brightness');



if false
    subplot(sp1, sp2, 7);
    cla;
    hold on;
    h = [];
    l = {};
    for i = 1:length(imgs)
        if isempty(imgs2{i})
            continue;
        end
        
        middleX = round(size(imgs2{i}.data, 2) ./ 2);
        middleY = round(size(imgs2{i}.data, 1) ./ 2);
        AVG{i} = mean(imgs2{i}.data_f(middleY-100:middleY+100, :), 1);
        AVG{i} = AVG{i} - mean(AVG{i}(middleX-2:middleX+2));
        AVG{i} = AVG{i} / mean(AVG{i}(imgs2{i}.zeropower_i));
        STD{i} = std(imgs2{i}.data_f(middleY-100:middleY+100, :), [], 1);
        
        H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(21), 'lineprops', {'Color', colours(i+1,:)}, 'transparent', 1);
        h(end+1) = H.mainLine;
        l{end+1} = imgs{i}.desc;
    end
    hold off;
    legend(h, l);
    grid on;
    title('Brightness / Model');
    axis tight;
    ylim(yl);
    
    colormap jet;
end
