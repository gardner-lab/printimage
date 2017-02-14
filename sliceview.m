i = 0;
figure(123);
try
    while true
        i = i + 1;
        a(i,:,:) = imread('gold_post_pwoertest_00001.tif', i);
        imagesc(squeeze(a(i,:,:)));
        pause(0.05);
    end
catch ME
end
