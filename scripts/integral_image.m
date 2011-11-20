function result = integral_image(input)

% function result = integral_image(input)

image = double_gray(input); 

vertical_size  = size(image, 1);
horizontal_size = size(image, 2);

result = zeros(vertical_size, horizontal_size);

% first, compute sums along horizontal direction
for vertical = 1:vertical_size
    result(vertical, 1) = image(vertical, 1);
    for horizontal = 2:horizontal_size
        previous_sum = result(vertical, horizontal - 1);
        current_value = image(vertical, horizontal);
        result(vertical, horizontal) = previous_sum + current_value;
    end
end

% second, compute sums along vertical direction
for vertical = 2:vertical_size
    for horizontal = 1:horizontal_size
        previous_sum = result(vertical - 1, horizontal);
        current_value = result(vertical, horizontal);
        result(vertical, horizontal) = previous_sum + current_value;
    end
end
