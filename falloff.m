clear;

addpath('~/Downloads');

imgs{1}.file = 'picture_00006_00001.tif';
imgs{1}.desc = 'Ref 1';
imgs{2}.file = 'picture_00007_00001.tif';
imgs{2}.desc = 'Cube 1';
imgs{3}.file = 'vignetting_cal_00001_00001.tif';
imgs{3}.desc = 'Ref 2';
imgs{4}.file = 'vignetting_00003_00001.tif';
imgs{4}.desc = 'Cube 2a';
imgs{5}.file = 'vignetting_00005_00001.tif';
imgs{5}.desc = 'Cube 2b';

calibration_imgs = [1 3];
calibration_refs = [1 1 3 3 3];

for i = 1:length(imgs)
    imgs{i}.data = imread(imgs{i}.file);
    if any(i == calibration_imgs)
        imgs{i}.vignetting_fit = fit_vignetting_falloff(imgs{i}.file, 666);
    end
end

pixelpos = linspace(-333, 333, size(imgs{1}.data, 1));

CROPX = 10;
CROPY = 40;
for i = 1:length(imgs)
    imgs{i}.data = double(imgs{i}.data(1+CROPY:end-CROPY, 1+CROPX:end-CROPX));
end

pixelposX = pixelpos(1+CROPX:end-CROPX);
pixelposY = pixelpos(1+CROPY:end-CROPY);
pixelposY = pixelposY(end:-1:1);

[px, py] = meshgrid(pixelposX, pixelposY);

sp1=5;
sp2=3;
figure(12);


% Compute vignetting falloffs for reference images
for i = 1:5
    if any(calibration_imgs == i)
        % Vignetting fits

        imgs{i}.vignetting_falloff = imgs{i}.vignetting_fit(px, py);
        imgs{i}.vignetting_falloff = imgs{i}.vignetting_falloff * max(max(imgs{i}.data));
        mn = min(min(imgs{i}.data));
        mn = 100;
        imgs{i}.vignetting_falloff(find(imgs{i}.vignetting_falloff <= mn)) = mn;
    
        subplot(sp1, sp2, (i-1)*sp2+2);
        imagesc(imgs{i}.data);
        axis off;
        % colorbar;
        title(imgs{i}.desc);
        
        subplot(sp1, sp2, (i-1)*sp2+3);
        imagesc(imgs{i}.vignetting_falloff);
        axis off;
        % colorbar;
        title(strcat(imgs{i}.desc, ' model'));
    else
        % Raw data / calibration images
        subplot(sp1, sp2, (i-1)*sp2+1);
        imagesc(imgs{i}.data);
        title(imgs{i}.desc);
        % colorbar;
        axis off;

        imgs2{i}.data = imgs{i}.data ./ imgs{calibration_refs(i)}.data;
        imgs2{i}.data_f = imgs{i}.data ./ imgs{calibration_refs(i)}.vignetting_falloff;
        
        subplot(sp1, sp2, (i-1)*sp2+2);
        imagesc(imgs2{i}.data);
        axis off;
        % colorbar;
        title(strcat(imgs{i}.desc, ' / ', imgs{calibration_refs(i)}.desc));
        
        subplot(sp1, sp2, (i-1)*sp2+3);
        imagesc(imgs2{i}.data_f);
        axis off;
        % colorbar;
        title(strcat(imgs{i}.desc, ' / ', imgs{calibration_refs(i)}.desc, ' model'));

    end
end


subplot(sp1, sp2, 1);
cla;
hold on;
colours = distinguishable_colors(6);
h = [];
l = {};
for i = 1:5
    if isempty(imgs2{i})
        continue;
    end
    
    middleX = round(size(imgs2{i}.data, 2) ./ 2);
    middleY = round(size(imgs2{i}.data, 1) ./ 2);
    AVG{i} = mean(imgs2{i}.data(middleY-10:middleY+10, :), 1);
    AVG{i} = AVG{i} - mean(AVG{i}(middleX-2:middleX+2));
    STD{i} = std(imgs2{i}.data(middleY-10:middleY+10, :), [], 1);
    
    H = shadedErrorBar(pixelposX, AVG{i}, 1.96*STD{i}/sqrt(21), 'lineprops', {'Color', colours(i+1,:)}, 'transparent', 1);
    h(end+1) = H.mainLine;
    l{end+1} = imgs{i}.desc;
end
hold off;
grid on;
legend(h, l);
title('Brightness / Ref');
axis tight;
yl = get(gca, 'YLim');

subplot(sp1, sp2, 7);
cla;
hold on;
h = [];
l = {};
for i = 1:5
    if isempty(imgs2{i})
        continue;
    end
    
    middleX = round(size(imgs2{i}.data, 2) ./ 2);
    middleY = round(size(imgs2{i}.data, 1) ./ 2);
    AVG{i} = mean(imgs2{i}.data_f(middleY-10:middleY+10, :), 1);
    AVG{i} = AVG{i} - mean(AVG{i}(middleX-2:middleX+2));
    STD{i} = std(imgs2{i}.data_f(middleY-10:middleY+10, :), [], 1);
    
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
