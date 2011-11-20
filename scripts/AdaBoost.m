function result = AdaBoost(responses, labels, rounds, weights)

result = zeros(rounds, 3);

classifier_number = size(responses, 1);
example_number = size(responses, 2);

if exist('weights', 'var') == false || size(weights, 1) ~= example_number
    weights = ones(example_number, 1) / example_number;
end
boosted_responses = zeros(example_number, 1);

for round = 1:rounds
    % find index, threshold, and alpha of best classifier
    [best_classifier, best_error, threshold, alpha] = ...
        find_best_classifier(responses, labels, weights);
    result(round, 1:3) = [best_classifier, alpha, threshold];
    
    % get outputs of the weak classifier on training examples
    weak_responses = double([responses(best_classifier, :)]' > threshold);
    weak_responses(weak_responses == 0) = -1;
    
    % reweigh training objects;
    new_weights = zeros(example_number, 1);
    for i = 1:example_number
        w = weights(i);
        new_w = w * exp(-alpha * weak_responses(i) * labels(i));
        new_weights(i) = new_w;
    end
    
    new_weights = new_weights / sum(new_weights);
    weights = new_weights;
    
    % update boosted responses
    boosted_responses = boosted_responses + alpha * weak_responses;
    thresholded = double(boosted_responses > 0);
    thresholded(thresholded == 0) = -1;
    error = mean(thresholded ~= labels);
    disp([round error best_error best_classifier alpha threshold]);
end



