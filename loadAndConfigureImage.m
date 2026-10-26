function [img,hatimg] = loadAndConfigureImage(image_file_path)
    img = imread(image_file_path);
    hatimg = imresize(img,[8 8],'nearest');
end
