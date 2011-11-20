function result = blur_image(image, sigma);

% function result = blur_image(image, sigma);
%
% blurs the input image with a symmetrc Gaussian filter of std=sigma.

blur_size = round(ceil(sigma) * 6 + 1);
blur_window = fspecial('gaussian', blur_size, sigma);
result = imfilter(image, blur_window, 'same', 'symmetric');



