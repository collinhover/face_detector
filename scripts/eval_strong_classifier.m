function result = eval_strong_classifier( integral_image, soft_classifiers, strong_classifier, offset_rows, offset_cols, classifier_range )
%EVAL_STRONG_CLASSIFIER evaluates strong classifier on image as integral

% init result
result = 0;

% check arguments
if nargin == 5
    % get classifier number
    classifier_number = size(strong_classifier, 1);
    classifier_range = 1:classifier_number;
end

% for each classifier in strong classifier
for c = classifier_range
    classifier_index = strong_classifier(c, 1);
    classifier_alpha = strong_classifier(c, 2);
    classifier_threshold = strong_classifier(c, 3);
    classifier = soft_classifiers{classifier_index};

    response1 = eval_weak_classifier(classifier, integral_image, offset_rows, offset_cols);
    if (response1 > classifier_threshold)
        response2 = 1;
    else
        response2 = -1;
    end
    response_weighted = classifier_alpha * response2;
    result = result + response_weighted;
end

end