function result = generate_classifier(pattern_vertical, pattern_horizontal)

% function result = generate_classifier(pattern_vertical, pattern_horizontal)
%
% generate a random classifier (of type 1, 2, 3, or 4)

classifier_type = random_number(1, 4);
if classifier_type == 1
    result = generate_classifier1(pattern_vertical, pattern_horizontal);
elseif classifier_type == 2
    result = generate_classifier2(pattern_vertical, pattern_horizontal);
elseif classifier_type == 3
    result = generate_classifier3(pattern_vertical, pattern_horizontal);
elseif classifier_type == 4
    result = generate_classifier4(pattern_vertical, pattern_horizontal);
end
