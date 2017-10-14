function [vignetting_fit] = fit_vignetting_falloff(filename, FOV);
    
    % FOV = 666; % microns
    
    % Crop out rubbish if necessary, but crop symmetrically--cropped region must be (roughly) centered.
    %bg = imread('~/Downloads/emptyc.png');
    
    bg = imread(filename);
    
    PixelSize = FOV / size(bg, 1);
    
    % Use some centre portion of the image...
    CROPX = 10;
    CROPY = 40;
    bg = bg(1+CROPY:end-CROPY, 1+CROPX:end-CROPX);
    
    x = zeros(prod(size(bg)), 1);
    y = x;
    z = x;
    
    c = 0;
        
    for i = 1:size(bg, 2) % X axis on index 2
        for j = 1:size(bg, 1) % Y axis on index 1
            c = c + 1;
            x(c) = i;
            y(c) = j;
            z(c) = bg(j,i);
        end
    end
    

    % These are, ideally, approximately centred (fit is more likely to converge), but it's not important. We won't assume centering later.
    x = (x - (max(x)+min(x))/2) * PixelSize;
    y = -(y - (max(y)+min(y))/2) * PixelSize; % Greater Y index in matrix = lower Y value on FOV
    z = (z - min(z)) / (max(z) - min(z));
        
    [xData, yData, zData] = prepareSurfaceData( x, y, z );
    
    FITMETHOD = 'cos+cos4';
    
    switch FITMETHOD
        
        case 'cos4free'
            % Set up fittype and options.
            ft = fittype( 'a + b*cos(m*pi*((x-xx)^2+(y-yy)^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 0.001 0 0];
            
        case 'cos4zero'
            ft = fittype( 'a + b*cos(m*pi*(x^2+y^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 0.001];
            
        case 'cos+cos4'
            ft = fittype( 'a + b*cos(m*pi*(x^2+y^2)^(1/2))^4 + c*cos(n*pi*((x-xc)^2+(y-yc)^2)^(1/2))', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            %opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 1 0.001 0.001 0 0];
            opts.Lower = [0 0 0 0.00001 0.00001 -300 -300];
            opts.StartPoint = [0 1 1 0.001 0.001 0 0];
            opts.Upper = [1 1 1 0.01 0.01 300 300];
            
        case 'interp'
            ft = 'linearinterp';
            opts = fitoptions('Method', 'linearinterpolant');
            
    end

    % Fit model to data.
    [vignetting_fit, gof] = fit( [xData, yData], zData, ft, opts );
    
    if false
        % Plot fit with data.
        figure(12);
        %subplot(2,1,2);
        h = plot( vignetting_fit, [xData, yData], zData );
        legend( h, 'untitled fit 1', 'z vs. x, y', 'Location', 'NorthEast' );
        % Label axes
        xlabel x
        ylabel y
        zlabel z
        grid on
    end
    
    vignetting_fit
    gof
    save vignetting_fit vignetting_fit
    
    %cftool(x, y, z);
