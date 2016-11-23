function draw_slice(handles, zind);

global STL;

imagesc(STL.print.voxelpos.x, STL.print.voxelpos.y, squeeze(STL.print.voxels(:, :, zind))', 'Parent', handles.axes2);
axis(handles.axes2, 'image', 'ij');
