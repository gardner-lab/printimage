i = 0;
figure(123);
clear foo;
try
    while true
        i = i + 1;
        foo(i,:,:) = imread('gold_post_pwoertest_00001.tif', i);
        imagesc(squeeze(foo(i,:,:)));
        pause(0.05);
    end
catch ME
    ME
end
