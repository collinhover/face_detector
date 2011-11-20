function [ image, bounds ] = image_read_options( filename, grayscale, dimensions, crop_pcts, scale, random_area )
%IMAGE_READ_OPTIONS reads image based on options

% read image
if exist('grayscale', 'var') == true && grayscale
    image = double_gray(imread(filename));
else
    image = double(imread(filename));
end

% check crop_pcts
if exist('crop_pcts', 'var') == true && isempty(crop_pcts) == false
    % get image size
    % set dimensions
    if exist('dimensions', 'var') == false || isempty(dimensions)
        dimensions = size(image);
    end
    crop_dim = [dimensions(1) * crop_pcts(2) - dimensions(1) * crop_pcts(1), dimensions(2) * crop_pcts(4) - dimensions(2) * crop_pcts(3)];
    crop_dim = max(1, crop_dim);

    % get crop position
    if exist('random_area', 'var') == true && random_area
        crop_pos = [rand() * (dimensions(1) - crop_dim(1)), rand() * (dimensions(2) - crop_dim(2))];
    else
        crop_pos = [dimensions(1) * crop_pcts(1), dimensions(2) * crop_pcts(3)];
    end
    crop_pos = max(1, crop_pos);
    
    % set bounds
    bounds = [crop_pos(1), crop_pos(1) + crop_dim(1) - 1, crop_pos(2), crop_pos(2) + crop_dim(2) - 1];
    bounds = round(bounds);
    
    % crop image
    image = image(bounds(1):bounds(2), bounds(3):bounds(4), :);
else
    % set bounds
    [img_rows, img_cols] = size(image);
    bounds = [1, img_rows, 1, img_cols];
end

% check scale
if exist('scale', 'var') == true
   image = imresize(image, scale, 'bilinear');
   bounds = round(bounds * scale);
end

end

