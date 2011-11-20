function result = normalize_range(input_image, target_low, target_high)

% function result = normalize_range(input_image, target_low,  target_high)
%
% shift the values in input_image so that the minimum value is 
% target_low and the maximum value is target_high.
% 
% function result = normalize_range(input_image)
%
% returns normalize_range(input_image, 0, 255)


if nargin == 1
    target_low = 0;
    target_high = 255;
end

if ~isfloat(input_image)
    % note: the next line creates a copy, does not modify the input.
    input_image = double(input_image);
end

target_range = target_high - target_low;
low = min(input_image(:));
high = max(input_image(:));
range = high - low;

% this will give warning
result = (input_image - low) * target_range / range + target_low;

