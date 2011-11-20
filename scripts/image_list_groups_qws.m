function [ images, windows ] = image_list_groups_qws( image_list, index_groups, n, grayscale, dimensions, crop_pcts, scale, random_area, max_non_duplicate_tries )
%image_list_groups_qws reads up to n images from image list groups

% check grayscale
if exist('grayscale', 'var') == false
   grayscale = false; 
end

% check crop_pcts
if exist('crop_pcts', 'var') == false
   crop_pcts = [0, 1, 0, 1]; 
end

% check scale
if exist('scale', 'var') == false
   scale = 1; 
end

% check random_area
if exist('random_area', 'var') == false
   random_area = false; 
end

% init images
images = cell(n, 1);
windows = zeros(n, 5);

% num groups
[num_groups, num_per_group] = size(index_groups);

% check max_non_duplicate_tries
if exist('max_non_duplicate_tries', 'var') == false
   max_non_duplicate_tries = num_per_group; 
end

% until ni == n
ni = 1;
group_last_index = 1;
while ni <= n
    % reset tries
    tries = 0;
    
    % get group
    group = index_groups(group_last_index, :);
    
    % get random index within group
    img_group_index = ceil(rand() * num_per_group);
    img_list_index = group(img_group_index);
    
    % get image / window
    [image, window] = image_read_options(image_list(img_list_index).name, grayscale, dimensions, crop_pcts, scale, random_area);
    window_full = [img_list_index, window];
    
    % if is not duplicate
    duplicate = ismember(window_full, windows, 'rows');
    if duplicate == false || tries == max_non_duplicate_tries
        % store image and window
        images{ni, :} = image;
        windows(ni, :) = window_full;
        
        % increase group_last_index
        group_last_index = mod(group_last_index, num_groups) + 1;
        
        % increase ni
        ni = ni + 1;
    else
        tries = tries + 1;
    end
end

end

% faces sample
% t1 = double(imread(training_faces_list(round(rand() * num_faces)).name));
% t2 = t1(sample_width * sample_faces_crop_pcts(1):sample_width * sample_faces_crop_pcts(2), sample_height * sample_faces_crop_pcts(3):sample_height * sample_faces_crop_pcts(4), :);
% t3 = imresize(t2, sample_scale, 'bilinear');

% nonfaces sample
% t1 = double(imread(training_nonfaces_list(round(rand() * num_nonfaces)).name));
% [t1_h, t1_w, ~] = size(t1);
% t1_pos = [round(rand() * (t1_h - sample_dim(1))), round(rand() * (t1_w - sample_dim(2)))];
% t2 = t1(t1_pos(1):t1_pos(1) + sample_dim(1), t1_pos(2):t1_pos(2) + sample_dim(2), :);
% t3 = imresize(t2, sample_scale, 'bilinear');