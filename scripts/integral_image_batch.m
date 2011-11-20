function [ integral_images ] = integral_image_batch( images )
%INTEGRAL_IMAGE_BATCH get integral images for a cell of images and return

% size of images list
[num_images, ~] = size(images(:));

% init integral_images
integral_images = cell(num_images, 1);

% for each image
for i = 1:num_images
    integral_images{i, 1} = integral_image(images{i, 1});
end

end

