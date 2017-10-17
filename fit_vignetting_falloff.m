function [vignetting_fit] = fit_vignetting_falloff(filename, FOV, handles);
    
    % FOV = 666; % microns
    
    % Crop out rubbish if necessary, but crop symmetrically--cropped region must be (roughly) centered.
    %bg = imread('~/Downloads/emptyc.png');
    
    bg = imread(filename);
    
    PixelSize = FOV / size(bg, 1);
    
    % Use some centre portion of the image...
    CROPX = 0;
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
    

    x = (x - (max(x)+min(x))/2) * PixelSize;
    y = -(y - (max(y)+min(y))/2) * PixelSize; % Greater Y index in matrix = more negative Y value in FOV's coordinate system
    z = (z - min(z)) / (max(z) - min(z));
        
    [xData, yData, zData] = prepareSurfaceData( x, y, z );
    
    FITMETHOD = 'interp';
    
    switch FITMETHOD
        
        case 'cos4free'
            % Set up fittype and options.
            ft = fittype( 'a + b*cos(m*pi*((x-xc)^2+(y-yc)^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 0.0007 0 0];
            
        case 'cos4'
            ft = fittype( 'a + b*cos(m*pi*(x^2+y^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 0.001];
            
        case 'cos4+cos'
            ft = fittype( 'a + b*cos(m*pi*(x^2+y^2)^(1/2))^4 + c*cos(n*pi*((x-xc)^2+(y-yc)^2)^(1/2))', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            %opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.Lower = [0 0 0 0.00001 0.00001 -300 -300];
            opts.StartPoint = [0 0.5 0.5 0.001 0.001 0 0];
            opts.Upper = [0.1 1 1 0.01 0.01 300 300];
            
        case 'cos4+gauss'
            ft = fittype( 'a + b*cos(m*pi*(x^2+y^2)^(1/2))^4 + c*exp(-((x-c1)^2+(y-c2)^2)/c^2)', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            %opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.Lower = [0 0 0 -300 -300 0.0001];
            opts.StartPoint = [0 1 0.01 0 0 0.001];
            opts.Upper = [0.1 1 1 300 300 0.01];
            
        case 'interp'
            ft = 'linearinterp';
            opts = fitoptions('Method', 'linearinterpolant');
            
    end

    % Fit model to data.
    [vignetting_fit, gof] = fit( [xData, yData], zData, ft, opts );
    
    if nargin == 3 & false
        % Plot fit with data.
        h = plot(handles.axes2, vignetting_fit, [xData, yData], zData );
        % Label axes
        xlabel x
        ylabel y
        zlabel z
        grid off
        colormap jet;
    end
    
    vignetting_fit
    gof
