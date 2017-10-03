clear;

% Crop out rubbish if necessary, but crop symmetrically--cropped region must be (roughly) centered.
bg = imread('~/Downloads/emptyc.png');
PixelSize = 666/512;   % Microns per pixel. Numerator is total FOV of uncropped image, denominator is resolution of uncropped image.

x = zeros(prod(size(bg)), 1);
y = x;
z = x;

c = 0;

for i = 1:size(bg, 1)
    for j = 1:size(bg, 2)
        c = c + 1;
        x(c) = i;
        y(c) = j;
        z(c) = bg(i,j);
    end
end

% These are, ideally, approximately centred (fit is more likely to converge), but it's not important. We won't assume centering later.
x = (x - min(x));
x = x - 0.5*(max(x)-min(x)) * PixelSize;
y = (y - min(y));
y = y - 0.5*(max(y)-min(y)) * PixelSize;
z = (z - min(z)) / max(z - min(z));


[xData, yData, zData] = prepareSurfaceData( x, y, z );

% Set up fittype and options.
ft = fittype( 'a + b*cos(m*pi*((x-xx)^2+(y-yy)^2)^(1/2))^4', 'independent', {'x', 'y'}, 'dependent', 'z' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Robust = 'LAR';
opts.StartPoint = [0 1 0.001 0 0];

% Fit model to data.
[vignetting_fit, gof] = fit( [xData, yData], zData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( vignetting_fit, [xData, yData], zData );
legend( h, 'untitled fit 1', 'z vs. x, y', 'Location', 'NorthEast' );
% Label axes
xlabel x
ylabel y
zlabel z
grid on

vignetting_fit
gof

save vignetting_fit vignetting_fit

%cftool(x, y, z);
