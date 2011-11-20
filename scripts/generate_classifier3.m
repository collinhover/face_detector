function result = generate_classifier3(pattern_vertical, pattern_horizontal)

size_step = 1.3;
max_vertical = floor((pattern_vertical - 1) / 1);
max_horizontal = floor((pattern_horizontal - 1)/ 3);
max_vertical_log = floor(log(max_vertical) / log(size_step));
max_horizontal_log  = floor(log(max_horizontal) / log(size_step));

vertical_size_log = random_number(4, max_vertical_log);
horizontal_size_log = random_number(4, max_horizontal_log);

vertical_size = floor(size_step ^ vertical_size_log);
horizontal_size = floor(size_step ^ horizontal_size_log);

max_vertical_offset = pattern_vertical - (1 * vertical_size) + 1;
max_horizontal_offset = pattern_horizontal - (3 * horizontal_size) + 1;

vertical_offset = random_number(2, max_vertical_offset);
horizontal_offset = random_number(2, max_horizontal_offset);

% rectangles contains in each row: top, bottom, left, right limits of
% rectangle.
positive_rectangles = zeros(2, 4);
positive_rectangles(1, 1) = vertical_offset; % top
positive_rectangles(1, 2) = vertical_offset + vertical_size - 1; % bottom
positive_rectangles(1, 3) = horizontal_offset; % left
positive_rectangles(1, 4) =  horizontal_offset + horizontal_size - 1; % right

positive_rectangles(2, 1) = vertical_offset; % top
positive_rectangles(2, 2) = vertical_offset + vertical_size - 1; % bottom
positive_rectangles(2, 3) = horizontal_offset + 2 * horizontal_size; % left; % left
positive_rectangles(2, 4) =  horizontal_offset + 3 * horizontal_size - 1; % right

negative_rectangles = zeros(1, 4);
negative_rectangles(1, 1) = vertical_offset; % top
negative_rectangles(1, 2) = vertical_offset + vertical_size - 1; % bottom
negative_rectangles(1, 3) = horizontal_offset + horizontal_size; % left
negative_rectangles(1, 4) =  horizontal_offset + 2 * horizontal_size - 1; % right

% result format: 
% {positive rectangles, negative rectangles, 
%  type, negative value, 
%  rectangle_rows, rectangle_cols, 
%  vertical_offset, horizontal_offset,
%  filter}.

% notice the -2 for the negative value (4th element of result)
result = {positive_rectangles, negative_rectangles, ...
          3, -2, vertical_size, horizontal_size, ...
          vertical_offset, horizontal_offset, ...
          rectangle_filter3(vertical_size, horizontal_size)};
