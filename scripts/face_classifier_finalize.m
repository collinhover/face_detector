function [ face_classifier ] = face_classifier_finalize( dimensions, classifiers_soft, classifiers_strong, scales, magnitude_threshold, cascade_pcts, skin_positives_path, skin_negatives_path, skin_threshold, dist_pct )
%FACE_CLASSIFIER_FINALIZE fixes face_classifier

face_classifier.soft = classifiers_soft;
face_classifier.strong = classifiers_strong;
face_classifier.dimensions = dimensions;
face_classifier.num_classifiers = size(face_classifier.soft, 1);
if exist('magnitude_threshold', 'var') == false
    face_classifier.magnitude_threshold = 0;
else
    face_classifier.magnitude_threshold = magnitude_threshold;
end

% scales
if exist('scales', 'var') == false
    face_classifier.scales = 1;
else
    face_classifier.scales = scales;
end

% cascade info
if exist('cascade_pcts', 'var') == false
    face_classifier.cascade_pcts = (0.1:0.225:1)';
else
    face_classifier.cascade_pcts = cascade_pcts(:);
end
face_classifier.cascade_num = size(face_classifier.cascade_pcts, 1);
face_classifier.cascade_points = ones(face_classifier.cascade_num, 2);
face_classifier.cascade_ranges = cell(face_classifier.cascade_num, 1);

% init cascade points
for c = 1:face_classifier.cascade_num
    c_val = max(3, round(face_classifier.num_classifiers * face_classifier.cascade_pcts(c)));
    if c == 1
        c_range = [1, c_val];
    else
        c_range = [face_classifier.cascade_points(c - 1, 2) + 1, c_val];
    end
    
    face_classifier.cascade_points(c, :) = c_range;
    face_classifier.cascade_ranges{c, 1} = c_range(1):c_range(2);
end

% dist pct
if exist('dist_pct', 'var') == false
    face_classifier.min_dist_pct = 1;
else
    face_classifier.min_dist_pct = dist_pct;
end
face_classifier.min_dist = round((max(face_classifier.dimensions(1), face_classifier.dimensions(2)) * face_classifier.min_dist_pct) * 0.5);

% load histograms for skin detection
if exist('skin_positives_path', 'var') && exist('skin_negatives_path', 'var')
    face_classifier.skin.enabled = true;
    face_classifier.skin.hist_pos = read_double_image(skin_positives_path);
    face_classifier.skin.hist_neg = read_double_image(skin_negatives_path);
else
    face_classifier.skin.enabled = false;
end
if exist('skin_threshold', 'var') == false
    face_classifier.skin.threshold = 0.5;
else
    face_classifier.skin.threshold = skin_threshold;
end

end

