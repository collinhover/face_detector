function [best_error, best_threshold, best_alpha] = ...
    weighted_error(responses, labels, weights, classifier)

% function [best_error, best_threshold, best_alpha] = ...
%    weighted_error(responses, labels, weights, classifier)
%
% responses: matrix, whose each column contains responses of a training
%            pattern on all weak classifiers
% labels: training labels of the patterns
% weights: current weights of the patterns (according  to the AdaBoost
%          algorithm)
% classifier: a row index  that specifies which weak classifier to use
%             (that corresponds to a row in the responses matrix).
%
% The  function computes the best threshold for the given classifier, and
% returns the threshold,  as well as the corresponding weighted error and
% weight that should be assigned to that weak classifier.

classifier_responses = [responses(classifier,:)]';
minimum = min(classifier_responses);
maximum = max(classifier_responses);
step = (maximum - minimum) / 50;
best_error = 2;

for threshold = minimum:step:maximum
     thresholded = (classifier_responses > threshold);
     thresholded = double(thresholded);
     thresholded(thresholded == 0) = -1;
     error1 = sum(weights .* (labels ~= thresholded));
     error = min(error1, 1 - error1);
     if (error < best_error)
         best_error = error;
         best_threshold = threshold;
         if (error1 < (1 - error1))
             best_direction = 1;
         else
             best_direction = -1;
         end
     end
end
 
best_alpha = best_direction * 0.5 * log( (1 - best_error) / best_error);
if (best_error == 0)
    best_alpha = 1;
end
