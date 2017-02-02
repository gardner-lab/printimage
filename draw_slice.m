function draw_slice(handles, zind);

global STL;

imagesc(STL.preview.voxelpos.x, STL.preview.voxelpos.y, squeeze(STL.preview.voxels(:, :, zind))', 'Parent', handles.axes2);
axis(handles.axes2, 'image', 'ij');
