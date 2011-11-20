function result = rectangle_filter1(vertical, horizontal)

% function result = rectangle_filter1(vertical, horizontal)
%
%  creates a rectangle filter of type 1 
% (white on the left, black on the right).

result = ones(vertical, 2 * horizontal);
result(:, (horizontal+1):(2 * horizontal)) = -1;
