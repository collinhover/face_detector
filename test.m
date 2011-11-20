% TEST tests face detector using skin detection and classifier cascades
% using a classifier trained with AdaBoost, bootstrapping

clear;
clc;

% set directories
directories;

% load data
load(strcat(training_directory, '\', 'face_classifier.mat'));

% set test parameters
% face_classifier.soft, face_classifier.strong, face_classifier.dimensions
% already set by training
magnitude_threshold = 1.3;
scales = 0.25:0.25:1.5;
cascade_start = 0.05;
cascade_delta = 0.05;
cascade_end = 1;
cascade_pts = cascade_start:cascade_delta:cascade_end;
skin_threshold = 0.5;
dist_pct = 1;
face_classifier = face_classifier_finalize(face_classifier.dimensions, face_classifier.soft, face_classifier.strong, scales, magnitude_threshold, cascade_pts, 'skin_positives.bin', 'skin_negatives.bin', skin_threshold, dist_pct);

% test faces cropped list
results.faces_cropped = test_results_directory_setup(strcat(data_directory, '\', 'test_cropped_faces'));

% test faces list
results.faces_photos = test_results_directory_setup(strcat(data_directory, '\', 'test_face_photos'));

% test nonfaces list
results.nonfaces = test_results_directory_setup(strcat(data_directory, '\', 'test_nonfaces'));

% test results identifier
results.id = 'face_classifier_test_results';

% set faces photos face locations for comparison with test results
results.faces_photos.detection_dist_tolerance = face_classifier.min_dist * 0.5;
results.faces_photos.known_locations = ...
    {   'DSC01181.jpg', [163, 176], [168, 253];
        'DSC01418.jpg', [], [142, 319; 135, 275];
        'DSC02950.jpg', [], [185, 450];
        'DSC03292.jpg', [142, 218], [162, 375];
        'DSC03318.jpg', [205, 368], [221, 212]; % redo till here
        'DSC03457.jpg', [161, 147; 106, 193], [114, 243];
        'DSC04545.jpg', [72, 136], [];
        'DSC04546.jpg', [], [123, 212];
        'DSC06590.jpg', [], [191, 143; 212, 392];
        'DSC06591.jpg', [], [202, 303; 290, 366];
        'IMG_3793.jpg', [228, 309; 195, 477], [214, 177; 240, 374];
        'IMG_3794.jpg', [171, 221; 189, 135; 191, 328], [169, 570; 189, 466];
        'IMG_3840.jpg', [235, 298; 253, 402], [238, 187; 198, 510];
        'clintonAD2505_468x448.jpg', [186, 144; 101, 272], [];
        'jackie-yao-ming.jpg', [], [62, 110; 78, 188];
        'katie-holmes-tom-cruise.jpg', [83, 122], [97, 217];
        'mccain-palin-hairspray-horror.jpg', [103, 154; 143, 294], [];
        'obama8.jpg', [121, 150], [];
        'phil-jackson-and-michael-jordan.jpg', [53, 175], [];
        'the-lord-of-the-rings_poster.jpg', [153, 28; 47, 64; 61, 158; 226, 258], [68, 244; 246, 13]; };
for t = 1:results.faces_photos.num_images
    results.faces_photos.known_locations{t, 1} = strcat(data_directory, '\', 'test_face_photos', '\', results.faces_photos.known_locations{t, 1});
end

% test cropped faces
% for each cropped face
for t = 1:results.faces_cropped.num_images
    % detect faces
    [face_locs, face_locs_row, face_locs_col, face_locs_scale] = detect_faces_rectangle_cascades(results.faces_cropped.list(t).name, face_classifier);
    
    % check detected areas
    [img_rows, img_cols, ~] = size(face_locs);
    num_face_locs = size(face_locs_row, 1);
    for l = 1:num_face_locs
        i = face_locs_row(l);
        j = face_locs_col(l);
        s = face_locs_scale(l);
        scale = face_classifier.scales(s);
        c_dim_half = round(face_classifier.dimensions * scale * 0.5);
        
        % add to counter
        if abs(i - round(img_rows * 0.5)) <= round(face_classifier.dimensions(1) * 0.5) && abs(j - round(img_cols * 0.5)) <= round(face_classifier.dimensions(2) * 0.5)
            results.faces_cropped.true_positives = results.faces_cropped.true_positives + 1;
        else
            results.faces_cropped.false_positives = results.faces_cropped.false_positives + 1;
            results.faces_cropped.mis_windows(end + 1, :) = [t, true, i - c_dim_half(1) + 1, i + c_dim_half(1), j - c_dim_half(2) + 1, j + c_dim_half(2)];
        end
    end
    
    % if no faces found
    if num_face_locs == 0
        c_dim_half = round(face_classifier.dimensions * 0.5);
        results.faces_cropped.false_negatives = results.faces_cropped.false_negatives + 1;
        results.faces_cropped.mis_windows(end + 1, :) = [t, false, img_rows - c_dim_half(1) + 1, img_rows + c_dim_half(1), img_cols - c_dim_half(2) + 1, img_cols + c_dim_half(2)];
    end
    
    % increase num windows classified
    results.faces_cropped.total_windows_classified = results.faces_cropped.total_windows_classified +  + size(face_locs, 1) * size(face_locs, 2) * size(face_locs, 3);
    
    % increase num images classified
    results.faces_cropped.total_images_classified = results.faces_cropped.total_images_classified + 1;
    
    % status update
    clc; disp(strcat('[test] face cropped #', num2str(t), ', correct so far: ', num2str(results.faces_cropped.true_positives)));
end

% test faces photos
% for each faces photos
for t = 1:results.faces_photos.num_images
    % detect faces
    tic;
    [face_locs, face_locs_row, face_locs_col, face_locs_scale] = detect_faces_rectangle_cascades(results.faces_photos.list(t).name, face_classifier);
    toc;
    disp(results.faces_photos.list(t).name);
    
    % check detected areas against known areas
    known_face_locs_index = find(strcmpi(results.faces_photos.list(t).name, results.faces_photos.known_locations(:, 1)));
    if isempty(known_face_locs_index) == false
        expected_face_locs = results.faces_photos.known_locations{known_face_locs_index, 2};
        bonus_face_locs = results.faces_photos.known_locations{known_face_locs_index, 3};
    else
        expected_face_locs = [];
        bonus_face_locs = [];
    end
    
    [img_rows, img_cols, ~] = size(face_locs);
    num_face_locs = size(face_locs_row, 1);
    for l = 1:num_face_locs
        i = face_locs_row(l);
        j = face_locs_col(l);
        is_not_valid_location = true;
        
        disp(strcat('checking found face loc #', num2str(l)));
        
        % for each expected location
        for k = 1:size(expected_face_locs, 1)
            % get dist of location from known location
            found_to_known_dist = sqrt((expected_face_locs(k, 1) - i) ^ 2 + (expected_face_locs(k, 2) - j) ^ 2);
            % if dist equal to or below tolerance
            % record as true positive
            % set as valid location
            % remove expected location from list
            if found_to_known_dist <= results.faces_photos.detection_dist_tolerance
                disp('found expected location');
                results.faces_photos.true_positives = results.faces_photos.true_positives + 1;
                is_not_valid_location = false;
                expected_face_locs(k, :) = [];
                break;
            end
        end
        
        % for each bonus location
        for k = 1:size(bonus_face_locs, 1)
            % get dist of location from known location
            found_to_known_dist = sqrt((bonus_face_locs(k, 1) - i) ^ 2 + (bonus_face_locs(k, 2) - j) ^ 2);
            % if dist equal to or below tolerance
            % record as true positive
            % set as valid location
            % remove bonus location from list
            if found_to_known_dist <= results.faces_photos.detection_dist_tolerance
                disp('found bonus location');
                results.faces_photos.true_positives = results.faces_photos.true_positives + 1;
                is_not_valid_location = false;
                bonus_face_locs(k, :) = [];
                break;
            end
        end
        
        % if is not valid location
        % record as false positive
        if is_not_valid_location
            disp(strcat(num2str(l), ' = invalid location'));
            results.faces_photos.false_positives = results.faces_photos.false_positives + 1;
        end
    end
    
    % for all remaining known expected face locations 
    % (only penalize for known and expected locations, not bonus)
    % record as false negatives
    for k = 1:size(expected_face_locs, 1)
        disp(strcat(num2str(k), ' = missed expected location'));
        results.faces_photos.false_negatives = results.faces_photos.false_negatives + 1;
    end
    
    % increase num windows classified
    results.faces_photos.total_windows_classified = results.faces_photos.total_windows_classified +  + size(face_locs, 1) * size(face_locs, 2) * size(face_locs, 3);
    
    % increase num images classified
    results.faces_photos.total_images_classified = results.faces_photos.total_images_classified + 1;
    
    % status update
    disp(strcat('[test] faces photos #', num2str(t), ', true positives so far: ', num2str(results.faces_photos.true_positives), ', false positives so far: ', num2str(results.faces_photos.false_positives), ', false negatives so far: ', num2str(results.faces_photos.false_negatives)));
end


% test nonfaces
% for each nonface
for t = 1:results.nonfaces.num_images
    % detect faces
    [face_locs, face_locs_row, face_locs_col, face_locs_scale] = detect_faces_rectangle_cascades(results.nonfaces.list(t).name, face_classifier);
    
    % check detected areas
    [img_rows, img_cols, ~] = size(face_locs);
    num_face_locs = size(face_locs_row, 1);
    for l = 1:num_face_locs
        results.nonfaces.false_positives = results.nonfaces.false_positives + 1;
    end
    
    % increase num windows classified
    results.nonfaces.total_windows_classified = results.nonfaces.total_windows_classified +  + size(face_locs, 1) * size(face_locs, 2) * size(face_locs, 3);
    
    % increase num images classified
    results.nonfaces.total_images_classified = results.nonfaces.total_images_classified + 1;
    
    % status update
    clc; disp(strcat('[test] nonface #', num2str(t), ', incorrect so far: ', num2str(results.nonfaces.false_positives)));
end


% store results
results.faces_cropped.text = strcat('   [fc] faces cropped:', num2str(results.faces_cropped.false_positives), ',', num2str(results.faces_cropped.false_negatives), ',', num2str(results.faces_cropped.true_positives), ',', num2str(results.faces_cropped.total_images_classified), ', ', num2str(results.faces_cropped.total_windows_classified));
results.faces_photos.text = strcat('   [fp] faces photos:', num2str(results.faces_photos.false_positives), ',', num2str(results.faces_photos.false_negatives), ',', num2str(results.faces_photos.true_positives), ',', num2str(results.faces_photos.total_images_classified), ', ', num2str(results.faces_photos.total_windows_classified));
results.nonfaces.text = strcat('   [nf] nonfaces:', num2str(results.nonfaces.false_positives), ',', num2str(results.nonfaces.false_negatives), ',', num2str(results.nonfaces.true_positives), ',', num2str(results.nonfaces.total_images_classified), ', ', num2str(results.nonfaces.total_windows_classified));

results_full_text = '\r\n';
results_full_text = strcat(results_full_text, '----------------------------------------------------------------', '\r\n');
results_full_text = strcat(results_full_text, '[TEST] using following settings', '\r\n');
results_full_text = strcat(results_full_text, '----------------------------------------------------------------', '\r\n');
results_full_text = strcat(results_full_text, 'classifier dimensions: ', num2str(face_classifier.dimensions), '\r\n');
results_full_text = strcat(results_full_text, 'num classifiers: ', num2str(face_classifier.num_classifiers), '\r\n');
results_full_text = strcat(results_full_text, 'magnitude threshold: ', num2str(magnitude_threshold), '\r\n');
results_full_text = strcat(results_full_text, 'skin used: ', num2str(face_classifier.skin.enabled), '\r\n');
results_full_text = strcat(results_full_text, 'skin threshold: ', num2str(skin_threshold), '\r\n');
results_full_text = strcat(results_full_text, 'distance pct: ', num2str(dist_pct), '\r\n');
results_full_text = strcat(results_full_text, 'cascade start pct: ', num2str(cascade_start), '\r\n');
results_full_text = strcat(results_full_text, 'cascade delta pct: ', num2str(cascade_delta), '\r\n');
results_full_text = strcat(results_full_text, 'cascade end pct: ', num2str(cascade_end), '\r\n');
results_full_text = strcat(results_full_text, 'cascade ranges: ', mat2str(face_classifier.cascade_points), '\r\n');
results_full_text = strcat(results_full_text, 'scales: ', mat2str(scales), '\r\n');
results_full_text = strcat(results_full_text, '----------------------------------------------------------------', '\r\n');
results_full_text = strcat(results_full_text, '[RESULTS] (false pos, false neg, true pos, total img, total win)', '\r\n');
results_full_text = strcat(results_full_text, '----------------------------------------------------------------', '\r\n');
results_full_text = strcat(results_full_text, results.faces_cropped.text, '\r\n');
results_full_text = strcat(results_full_text, results.faces_photos.text, '\r\n');
results_full_text = strcat(results_full_text, results.nonfaces.text, '\r\n');
results_full_text = strcat(results_full_text, '----------------------------------------------------------------', '\r\n');
results_full_text = strcat(results_full_text, '\r\n');

% write to file
results_fid = fopen(strcat(training_directory, '\', results.id, '.txt'), 'a');
fprintf(results_fid, results_full_text);
fclose(results_fid);

% display results
clc;
disp('----------------------------------------------------------------');
disp('[RESULTS] (false pos, false neg, true pos, total img, total win)');
disp('----------------------------------------------------------------');
disp(results.faces_cropped.text);
disp(results.faces_photos.text);
disp(results.nonfaces.text);
disp('----------------------------------------------------------------');