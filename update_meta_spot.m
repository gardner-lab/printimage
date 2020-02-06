function update_meta_spot(hObject, eventdata, handles)
%Test function for previewing the location of the metavoxels wrt the whole
%model

%Pull in required variables
global STL;

%Only launch all of this if stitch printing is required
overlap_needed = (STL.print.size > STL.print.bounds);
if ~overlap_needed
    return
end

%Create a separate figure
figure(42); clf

%Plot some version of the model (3D seems to make sense)
patch(STL.preview.patchobj, ...
    'FaceColor',       [0.8 0.8 0.8], ...
    'EdgeColor',       'none',        ...
    'FaceLighting',    'gouraud',     ...
    'AmbientStrength', 0.15);
xlabel('x');
ylabel('y');
zlabel('z');
material('dull');
axis('image');
daspect([1 1 1]);
view([-135 35]);
camlight_handle = camlight('right');
rotate_handle = rotate3d;
rotate_handle.enable = 'on';

hold on %Hold so you can add the planes later

%Based on the print zoom selected, calculate the FOV and 
% overlap_needed = (STL.print.size > STL.print.bounds);
nmetavoxels = ceil((STL.print.size - STL.print.metavoxel_overlap) ./ (STL.print.bounds - STL.print.metavoxel_overlap.*overlap_needed));
metavoxel_shift = floor(STL.print.bounds) - STL.print.metavoxel_overlap;

% origin = [0, 0, 0];
xs = [metavoxel_shift(1) .* (1:nmetavoxels(1)-1)];
ys = [metavoxel_shift(2) .* (1:nmetavoxels(2)-1)];
zs = [metavoxel_shift(3) .* (1:nmetavoxels(3)-1)];

%Make and plot a plane for each metavoxel edge
for i=1:numel(xs)
    %Define plane
    [x, y] = meshgrid([xs(i), xs(i)], [0, STL.print.size(2)]);
    z = [0, STL.print.size(3);0, STL.print.size(3)];
    s = surf(x, y, z);
end

for i=1:numel(ys)
    %Define plane
    [x, y] = meshgrid([0, STL.print.size(1)], [ys(i), ys(i)]);
    z = [0, 0; STL.print.size(3), STL.print.size(3)];
    s = surf(x, y, z);
end

for i=1:numel(zs)
    %Define plane
    [x, y] = meshgrid([0, STL.print.size(1)], [0, STL.print.size(2)]);
    z = [zs(i), zs(i); zs(i), zs(i)];
    s = surf(x, y, z);
end









