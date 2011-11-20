function result = rectangle_sum(integral, rectangle, row, col)

% function result = rectangle_sum(integral, rectangle)
%
% integral:  integral image of some image A
% rectangle: [top bottom left right]
% row: an offset that is used to adjust top and bottom
% col: an offset that is used to adjust left and right.

top = rectangle(1);
bottom = rectangle(2);
left = rectangle(3);
right = rectangle(4);

area1 = integral(top+row - 2, left + col - 2);
area2 = integral(bottom + row - 1, right + col - 1);
area3 = integral(bottom + row - 1, left + col - 2);
area4 = integral(top + row - 2, right + col - 1);

result = area1 + area2 - area3 - area4;
