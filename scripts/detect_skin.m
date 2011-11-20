function result = detect_skin(image, positive_histogram, negative_histogram)

% function result = detect_skin(image, positive_histogram, negative_histogram)

vertical_size = size(image, 1);
horizontal_size = size(image, 2);
histogram_bins =  size(positive_histogram, 1);
factor = 256 / histogram_bins;

result = zeros(vertical_size, horizontal_size);

for vertical = 1: vertical_size
    for horizontal = 1: horizontal_size
        red = double(image(vertical, horizontal, 1));
        green = double(image(vertical, horizontal, 2));
        blue = double(image(vertical, horizontal, 3));
        
        red_index = floor(red / factor) + 1;
        green_index = floor(green / factor) + 1;
        blue_index = floor(blue / factor) + 1;
              
        skin_value = positive_histogram(red_index, green_index, blue_index);
        non_skin_value = negative_histogram(red_index, green_index, blue_index);
        total = skin_value + non_skin_value;
        if (total ~= 0)
            result(vertical, horizontal) = skin_value/total;
        end
    end
end