function [ responses ] = soft_classifier_responses_batch( soft_classifiers, integral_images )
%SOFT_CLASSIFIER_RESPONSES_BATCH find classifier responses for cell of images

% get sizes
[num_classifiers, ~] = size(soft_classifiers(:));
[num_integral_images, ~] = size(integral_images(:));

% init responses
responses = zeros(num_classifiers, num_integral_images);

% calculate responses
% each classifier
for c = 1:num_classifiers
    % each integral image
    for i = 1:num_integral_images
        responses(c, i) = soft_classifier_eval(soft_classifiers{c, 1}, integral_images{i, 1}, 1, 1);
    end
end

end

