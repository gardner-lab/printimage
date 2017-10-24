function [vignetting_fit] = fit_vignetting_falloff(filename, method, FOV, handles);
    
    % FOV = 666; % microns
    
    % Crop out rubbish if necessary, but crop symmetrically--cropped region must be (roughly) centered.
    %bg = imread('~/Downloads/emptyc.png');
    
    bg = imread(filename);
    
    PixelSize = FOV / size(bg, 1);
    
    % Use some centre portion of the image...
    CROPX = 5;
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
    
    switch method
        case 'cos4free'
            % Set up fittype and options.
            ft = fittype( 'a + b*cos(m*pi*((x-xc)^2+(y-yc)^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [0 1 0.0007 0 0];
            
        case 'cos4'
            % This one actually gets the model right: cos^4(arctan(r/z)),
            % but leaves the lens's true focal length free since it may
            % differ slightly from the published working distance (380 um
            % in our case).
            ft = fittype( 'cos(atan(((x^2+y^2)^(1/2))/m))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
            opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
            opts.Display = 'Off';
            opts.Robust = 'LAR';
            opts.StartPoint = [380];
            
        case 'interpolant'
            ft = 'linearinterp';
            opts = fitoptions('Method', 'linearinterpolant');
            
        otherwise
            error('Invalid fit method');
            
    end

    % Fit model to data.
    [vignetting_fit, gof] = fit( [xData, yData], zData, ft, opts );
    
    if nargin == 4 & isfield(handles, 'axes2')
        % Plot fit with data.
        cla(handles.axes2);
        set(handles.axes2, 'XLim', [min(xData) max(xData)], 'YLim', [min(yData) max(yData)]);
        h = plot(vignetting_fit, 'Parent', handles.axes2);
        hold on;
        scatter3(xData(1:50:end), yData(1:50:end), zData(1:50:end), 1, 'Parent', handles.axes2);
        hold off;
        % Label axes
        xlabel x
        ylabel y
        zlabel z
        grid off
        colormap jet;
    elseif true
        figure(11);
        h = plot(vignetting_fit);
        hold on;
        scatter3(xData, yData, zData, 1);
        hold off;
        xlabel x
        ylabel y
        zlabel z
        grid off
        colormap jet;
   end
    
    vignetting_fit
    gof
