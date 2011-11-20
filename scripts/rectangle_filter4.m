function result = rectangle_filter4(vertical, horizontal)

% function result = rectangle_filter4(vertical, horizontal)
%
%  creates a rectangle filter of type 4 
% (white on the top, black on center, white on bottom).

result = ones(3 * vertical, horizontal);
result((vertical+1):(2 * vertical), :) = -2;
