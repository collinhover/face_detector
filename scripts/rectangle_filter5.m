function result = rectangle_filter5(vertical, horizontal)

% function result = rectangle_filter3(vertical, horizontal)
%
%  creates a rectangle filter of type 5
% (white on the  top left, black on the top right,
% black on bottom left, white on bottom right).

result = ones(2 * vertical, 2 * horizontal);
result(1:vertical, (horizontal+1):(2 * horizontal)) = -1;
result((vertical+1):(2*vertical), 1:horizontal) = -1;
