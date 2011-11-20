function [ samples ] = misclassified_add_to_sample_set( dimensions, samples, mis, label, max_length )
%MISCLASSIFIED_ADD_TO_SAMPLE_SET adds misclassified images to sample set
%based on indices of both

% check max_length
if exist('max_length', 'var') == false
    max_length = Inf;
end

% num misclassified
num_mis = size(mis, 1);

% if num misclassified is not 0
for i = 1:num_mis
    mis_info = mis{i};
    mis_image = double(imread(mis_info.name));
    
    % get duplicates
    duplicates = ismember(mis_info.windows, samples.windows, 'rows');
    
    % get num possible
    curr_num = size(samples.windows, 1);
    num_possible = max_length - curr_num;
    if num_possible > 1
       % get only non duplicates
        new_windows = find(duplicates == 0, num_possible);
        num_new = size(new_windows, 1);
        
        for w = 1:num_new
            window_info = mis_info.windows(new_windows(w), :);
            window_image = mis_image(window_info(2):window_info(3), window_info(4):window_info(5), :);
            window_image = imresize(window_image, dimensions, 'bilinear');
            
            % get only images and indices that are new
            samples.images{end + 1, 1} = window_image;
            samples.windows(end + 1, :) = window_info;
            samples.integrals{end + 1, 1} = integral_image(window_image);
            samples.labels(end + 1, 1) = label; 
        end
    end
end

end

