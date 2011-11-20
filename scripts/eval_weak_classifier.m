function result = eval_weak_classifier(classifier, integral, row, col)

% function result =  eval_weak_classifier(classifier, integral, row, col)
%
% computes the response of a weak classifier on an image A,
% on a subwindow whose top left corner is (row, col), 
% given (as second argument) the integral image of A

if (nargin == 2)
    row = 1;
    col = 1;
end

positive_rectangles = classifier{1};
negative_rectangles = classifier{2};
negative_value = classifier{4};

sum = 0;
for i = 1:size(positive_rectangles, 1)
    rectangle = positive_rectangles(i, :);
    sum = sum + rectangle_sum(integral, rectangle, row, col);
end

for i = 1:size(negative_rectangles, 1)
    rectangle =  negative_rectangles(i, :);
    sum = sum + negative_value * rectangle_sum(integral, rectangle, row, col);
end

result = sum;
