function [index, error, threshold, alpha] = ...
    find_best_classifier(responses, labels, weights)

% function [index, error, threshold, alpha] = ...
%     find_best_classifier(responses, labels, weights)

classifier_number = size(responses, 1);
example_number = size(responses, 2);

% find best classifier
best_error = 2;

for classifier = 1:classifier_number
    [error threshold alpha] = weighted_error(responses, labels, ...
                                             weights, classifier);
    if (error < best_error)
        best_error = error;
        best_threshold = threshold;
        best_classifier = classifier;
        best_alpha = alpha;
    end
end

index = best_classifier;
error = best_error;
threshold = best_threshold;
alpha = best_alpha;
