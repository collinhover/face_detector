function result = rectangle_filter2(vertical, horizontal)

% function result = rectangle_filter2(vertical, horizontal)
%
%  creates a rectangle filter of type 2 
% (white on the top, black on the bottom).

result = ones(2 * vertical, horizontal);
result((vertical+1):(2 * vertical), :) = -1;
