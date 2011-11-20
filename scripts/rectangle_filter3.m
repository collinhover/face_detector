function result = rectangle_filter3(vertical, horizontal)

% function result = rectangle_filter3(vertical, horizontal)
%
%  creates a rectangle filter of type 3 
% (white on the left, black on the center, white on the right).

result = ones(vertical, 3 * horizontal);
result(:, (horizontal+1):(2 * horizontal)) = -2;
