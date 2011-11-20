% TRAIN trains face detector using skin detection, AdaBoost, bootstrapping,
% and classifier cascades

% check if training initialized
if exist('training_initialized', 'var') == false || training_initialized == false
    clear;
    %clc;

    % set directories
    directories;
    
    % training faces list
    training_faces_path = [data_directory, '\', 'training_faces'];
    training_faces_list = dir(training_faces_path);
    training_faces_list = remove_directories_from_dir_list(training_faces_list);

    % training nonfaces list
    training_nonfaces_path = [data_directory, '\', 'training_nonfaces'];
    training_nonfaces_list = dir(training_nonfaces_path);
    training_nonfaces_list = remove_directories_from_dir_list(training_nonfaces_list);

    % get sizes of lists
    num_faces = size(training_faces_list, 1);
    num_nonfaces = size(training_nonfaces_list, 1);

    % set absolute paths
    for i = 1:num_faces
        training_faces_list(i).name = [training_faces_path, '\', training_faces_list(i).name];
    end
    for i = 1:num_nonfaces
        training_nonfaces_list(i).name = [training_nonfaces_path, '\', training_nonfaces_list(i).name];
    end

    % split lists into even groups as per quasi-random weighted sampling (QWS+)
    % pct chosen for smaller but relatively close number per group,
    % regardless of total number of samples
    split_pct = 0.025;

    % init groups, which contain only rows of indices referring to the index
    % of the image in the primary lists
    % faces
    [groups_tfl, num_tfl_groups, num_tfl_per_group, num_tfl_overlapping] = ...
        split_array_evenly_allow_overlap(num_faces, split_pct);

    % non faces
    [groups_tnfl, num_tnfl_groups, num_tnfl_per_group, num_tnfl_overlapping] = ...
        split_array_evenly_allow_overlap(num_nonfaces, split_pct);

    % set sample properties
    sample_gray = false;
    sample_dim = [100, 100];
    sample_crop_pcts = [0.25, 0.93, 0.23, 0.77];
    sample_scale = 1;
    sample_dim_crop = [round(sample_dim(1) * sample_crop_pcts(2) - sample_dim(1) * sample_crop_pcts(1)), round(sample_dim(2) * sample_crop_pcts(4) - sample_dim(2) * sample_crop_pcts(3))];
    sample_dim_scaled = [round(sample_dim_crop(1) * sample_scale), round(sample_dim_crop(2) * sample_scale)];

    % set various values
    training_version = 'alt_004';
    num_samples_init = num_faces;%max(num_tfl_groups, num_tnfl_groups);
    num_classifiers = 1000;
    num_rounds_adaboost_max = 50;
    num_samples_diff_max_pct = Inf;
    num_samples_diff_max_num = Inf;

    % test values
    test_nonfaces_counter = 0;
    test_scales = 0.25:0.25:1.5;
    test_magnitude_threshold = 1;
    test_cascade_pts = 0.1:0.225:1;
    test_skin_threshold = 0.5;
    test_dist_pct = 1;
    test_num_iterations = 0;
    test_num_duplicate_classifiers = 0;
    test_num_duplicate_classifiers_threshold = round(num_rounds_adaboost_max * 0.6);
    test_error_change_faces = Inf;
    test_error_change_nonfaces = Inf;
    test_error_change = Inf;
    test_error_change_min = 0.001;

    % init soft classifiers
    soft_classifiers = cell(num_classifiers, 1);

    % init samples
    % faces
    % [samples.faces.images, samples.faces.identities] = image_list_groups_qws( training_faces_list, groups_tfl, num_samples_init, sample_gray, sample_dim, sample_crop_pcts, sample_scale );
    samples.faces.images = cell(num_samples_init, 1);
    samples.faces.windows = zeros(num_samples_init, 5);
    for i = 1:num_samples_init
        [image, identity] = image_read_options(training_faces_list(i).name, true, sample_dim, sample_crop_pcts, sample_scale);
        samples.faces.images{i, :} = image;
        samples.faces.windows(i, :) = [i, identity];
    end
    samples.faces.integrals = integral_image_batch(samples.faces.images);
    samples.faces.labels = ones(num_samples_init, 1);

    % non-faces
    [samples.nonfaces.images, samples.nonfaces.windows] = image_list_groups_qws( training_nonfaces_list, groups_tnfl, num_samples_init, sample_gray, sample_dim, sample_crop_pcts, sample_scale, true );
    samples.nonfaces.integrals = integral_image_batch(samples.nonfaces.images);
    samples.nonfaces.labels = zeros(num_samples_init, 1);
    samples.nonfaces.labels(:) = -1;
end

% initialized
training_initialized = true;

%
%
%
% init loop
%
%
%
while test_num_duplicate_classifiers < test_num_duplicate_classifiers_threshold || test_error_change > test_error_change_min || test_error_change_faces > test_error_change_min || test_error_change_nonfaces > test_error_change_min
    % check for existing soft classifiers
    if exist('state', 'var')
        disp('[x] existing classifiers');
        num_existing_classifiers = size(state.commit.classifiers.soft, 1);
        soft_classifiers(1:num_existing_classifiers, 1) = state.commit.classifiers.soft(:, 1);
    else
        disp('[O] no previous classifiers');
        num_existing_classifiers = 0;
    end
    % generate soft classifiers
    num_classifiers_to_generate = num_classifiers - num_existing_classifiers;
    for i = num_existing_classifiers+1:num_classifiers
        soft_classifiers{i, 1} = generate_classifier(sample_dim_scaled(1), sample_dim_scaled(2));
    end

    % samples existing (i.e. misclassified)
    if exist('state', 'var')
        disp('[x] existing misclassified image windows');
        % get num samples before change
        num_prechange_samples_faces = size(samples.faces.images, 1);
        num_prechange_samples_nonfaces = size(samples.nonfaces.images, 1);
        num_misclassified_face = state.commit.test_results.num_misclassified_faces;
        num_misclassified_nonface = state.commit.test_results.num_misclassified_nonfaces;
        num_max_samples = min(num_prechange_samples_faces + num_misclassified_face, num_prechange_samples_nonfaces + num_misclassified_nonface);
        num_max_samples = num_max_samples + min(round(num_max_samples * num_samples_diff_max_pct), num_samples_diff_max_num);
        disp(strcat('> current # faces: ', num2str(num_prechange_samples_faces), ', # nonfaces: ', num2str(num_prechange_samples_nonfaces)));
        disp(strcat('> + misclassified # faces: ', num2str(num_misclassified_face), ', # nonfaces: ', num2str(num_misclassified_nonface)));
        % faces
        samples.faces = misclassified_add_to_sample_set(sample_dim_scaled, samples.faces, state.commit.misclassified.faces, 1, num_max_samples);
%         num_existing_samples_face = size(state.commit.misclassified.faces.images, 1);
%         if num_existing_samples_face > 0
%             num_existing_vs_max = min(num_existing_samples_face, num_samples_init);
%             misclassified_start_index = floor(rand() * (num_existing_samples_face - max(0, num_existing_vs_max - 1))) + 1;
%             misclassified_end_index = misclassified_start_index + num_existing_vs_max - 1;
%             disp(strcat('faces # exist: ', num2str(num_existing_samples_face), ', min vs max: ', num2str(num_existing_vs_max), ', start index: ', num2str(misclassified_start_index), ', end index: ', num2str(misclassified_end_index)));
%             samples.faces.images = state.commit.misclassified.faces.images(misclassified_start_index:misclassified_end_index);
%         end
        
        % nonfaces
        samples.nonfaces = misclassified_add_to_sample_set(sample_dim_scaled, samples.nonfaces, state.commit.misclassified.nonfaces, -1, num_max_samples);
%         num_existing_samples_nonface = size(state.commit.misclassified.nonfaces.images, 1);
%         if num_existing_samples_nonface > 0
%             misclassified_indices_to_add = find(state.commit.misclassified.nonfaces.indices ~= samples.nonfaces.indices);
%             num_misclassified_to_add = size(misclassified_indices_to_add, 1);
%             samples.nonfaces.images(end+1:end+num_misclassified_to_add) = state.commit.misclassified.nonfaces.images(misclassified_indices_to_add);
%             samples.nonfaces.indices(end+1:end+num_misclassified_to_add) = state.commit.misclassified.nonfaces.indices(misclassified_indices_to_add);
%             num_existing_vs_max = min(num_existing_samples_nonface, num_samples_init);
%             misclassified_start_index = floor(rand() * (num_existing_samples_nonface - max(0, num_existing_vs_max - 1))) + 1;
%             misclassified_end_index = misclassified_start_index + num_existing_vs_max - 1;
%             disp(strcat('nonfaces # exist: ', num2str(num_existing_samples_nonface), ', min vs max: ', num2str(num_existing_vs_max), ', start index: ', num2str(misclassified_start_index), ', end index: ', num2str(misclassified_end_index)));
%             samples.nonfaces.images = state.commit.misclassified.nonfaces.images(misclassified_start_index:misclassified_end_index);
%         end
        disp(strcat('> = updated # faces: ', num2str(size(samples.faces.images, 1)), ' (delta: ', num2str(size(samples.faces.images, 1) - num_prechange_samples_faces) ,'), # nonfaces: ', num2str(size(samples.nonfaces.images, 1)),  ' (delta: ', num2str(size(samples.nonfaces.images, 1) - num_prechange_samples_nonfaces), ')'));
    else
        disp('[O] no misclassified image windows');
        num_existing_samples_face = 0;
        num_existing_samples_nonface = 0;
    end
    
    % calculate responses
    samples.faces.responses = soft_classifier_responses_batch(soft_classifiers, samples.faces.integrals);
    samples.nonfaces.responses = soft_classifier_responses_batch(soft_classifiers, samples.nonfaces.integrals);

    % get samples integrals, labels, responses
    % samples faces
    num_samples_faces = size(samples.faces.images, 1);
    
    % samples nonfaces
    num_samples_nonfaces = size(samples.nonfaces.images, 1);
    
    % get weights
    samples.faces.weights = (ones(num_samples_faces, 1) * 0.5) / num_samples_faces;
    samples.nonfaces.weights = (ones(num_samples_nonfaces, 1) * 0.5) / num_samples_nonfaces;
    samples.all.weights = [samples.faces.weights; samples.nonfaces.weights];

    % combine labels
    samples.all.labels = [samples.faces.labels; samples.nonfaces.labels];

    % combine responses
    samples.all.responses = [samples.faces.responses, samples.nonfaces.responses];

    % begin adaboost
    % compute boosted classifier
    disp(strcat('-------- num rounds of adaboost: ', num2str(num_rounds_adaboost_max)));
    strong_classifier = AdaBoost(samples.all.responses, samples.all.labels, num_rounds_adaboost_max, samples.all.weights);

    % normalize adaboost alphas(weights)
    % get euclidian distance of alphas(weights) to origin of boosted classifier
    dist = sqrt(sum(strong_classifier(:, 2) .^2));

    % divide alphas by sum
    strong_classifier(:, 2) = strong_classifier(:, 2) / dist;

    % display extra results
    num_classifiers_boosted = size(strong_classifier, 1);
    disp(strcat('>>>> num actual rounds: ', num2str(num_classifiers_boosted) ,', >>> sum of alphas: ', num2str(sum(strong_classifier(:, 2) .^ 2))));


    %
    %
    % TESTING
    %
    %

    % create new state from current training iteration
    % store test error, soft classifiers, boosted classifier info
    state_new.classifiers.soft = soft_classifiers(strong_classifier(:, 1));
    state_new.classifiers.strong = strong_classifier;
    state_new.classifiers.strong(:, 1) = 1:1:num_classifiers_boosted';
    state_new.classifiers.num_duplicate = 0;
    state_new.classifiers.magnitude_threshold = test_magnitude_threshold;
    
    % init face classifier for round
    face_classifier = face_classifier_finalize(sample_dim_scaled, state_new.classifiers.soft, state_new.classifiers.strong, test_scales, state_new.classifiers.magnitude_threshold, test_cascade_pts);%, 'skin_positives.bin', 'skin_negatives.bin', test_skin_threshold, test_dist_pct);

    % init misclassified windows lists
    state_new.misclassified.faces = {};
    state_new.misclassified.nonfaces = {};
    
    % test results
    test_results.num_classified_faces = 0;
    test_results.num_misclassified_faces = 0;
    test_results.num_classified_nonfaces = 0;
    test_results.num_misclassified_nonfaces = 0;
    
    disp('testing all faces with boosted classifiers');
    
    % test faces
    for t = 1:num_faces
        % window
        image_name = training_faces_list(t).name;
        [test_img_window, test_img_window_bounds] = image_read_options(image_name, true, sample_dim, sample_crop_pcts, sample_scale);
        
        % get window integral
        test_img_window_integral = integral_image(test_img_window);
        
        % evaluate strong classifier on window
        classified_magnitude_result = eval_strong_classifier(test_img_window_integral, soft_classifiers, strong_classifier, 1, 1);
        if classified_magnitude_result > state_new.classifiers.magnitude_threshold
            classified_label_result = 1;
        else
            classified_label_result = -1;
        end
        
        % add to num classified counter
        test_results.num_classified_faces = test_results.num_classified_faces + 1;
        
        % if received label does not match expected
        if classified_label_result ~= 1
            % if no face locations found, add image name to misclassified
            mis_info.name = image_name;
            mis_info.windows = [t, test_img_window_bounds];
            state_new.misclassified.faces{end + 1, 1} = mis_info;
            test_results.num_misclassified_faces = test_results.num_misclassified_faces + 1;
        end
    end
        
    disp('testing all nonfaces with boosted classifiers');
    
    % update nonfaces counter
    test_nonfaces_counter = test_nonfaces_counter + 1;
    if test_nonfaces_counter > num_nonfaces
        test_nonfaces_counter = 1;
    end
    
    % test non faces
    for t = 1:num_nonfaces %test_nonfaces_counter
        disp(strcat(' > testing all windows in nonface #', num2str(t), ' (total # ', num2str(num_nonfaces), ')'));
        
        % get image name
        image_name = training_nonfaces_list(t).name;
        
        % find all faces in image
        [face_locs, face_locs_row, face_locs_col, face_locs_scale] = detect_faces_rectangle_cascades(image_name, face_classifier);
        
        % add to num classified counter
        test_results.num_classified_nonfaces = test_results.num_classified_nonfaces + size(face_locs, 1) * size(face_locs, 2) * size(face_locs, 3);
        
        % get number of faces found
        num_face_locs = size(face_locs_row, 1);
        if num_face_locs > 0
            % if any face locations found, add image name to misclassified
            mis_info.name = image_name;
            mis_info.windows = zeros(0, 5);
            
            % for each face found
            % store identity of each misclassified window
            for l = 1:num_face_locs
                i = face_locs_row(l);
                j = face_locs_col(l);
                s = face_locs_scale(l);
                scale = face_classifier.scales(s);
                c_dim_half = round(sample_dim_scaled * scale * 0.5);
                
                % store results
                mis_info.windows(end + 1, :) = [t, i - c_dim_half(1) + 1, i + c_dim_half(1), j - c_dim_half(2) + 1, j + c_dim_half(2)];
                test_results.num_misclassified_nonfaces = test_results.num_misclassified_nonfaces + 1;
            end
            
            % store misclassified info
            state_new.misclassified.nonfaces{end + 1, 1} = mis_info;
        end
    end
%         % image
%         test_img = image_read_options(training_nonfaces_list(t).name, true);%, [], [], sample_scale);
%         
%         % integral
%         test_img_integral = integral_image(test_img);
%         
%         % size
%         [test_rows, test_cols] = size(test_img);
%         disp(strcat('img size: ', num2str(test_rows), ', ', num2str(test_cols)));
%         % for each scale
%         for s = test_scales
%             % get rescaled dimensions
%             curr_dim_scaled = round(sample_dim_scaled * s);
%             disp(strcat('testing windows of current scale: ', num2str(s), ', new dim: ', mat2str(curr_dim_scaled), '(', mat2str(sample_dim_scaled), ')'));
%             % if rescaled is larger than image, skip scale
%             if curr_dim_scaled(1) > test_rows || curr_dim_scaled(2) > test_cols
%                 continue;
%             end
%             % get start and end pixels based on size of scaled and cropped sample
%             test_rows_start = ceil(curr_dim_scaled(1) * 0.5);
%             test_rows_end = test_rows - test_rows_start - 1;
%             test_cols_start = ceil(curr_dim_scaled(2) * 0.5);
%             test_cols_end = test_cols - test_cols_start - 1;
%             
%             % for each window
%             for i = test_rows_start:test_rows_end
%                 for j = test_cols_start:test_cols_end
%                     % get window of image
%                     window_top = i - test_rows_start + 1;
%                     window_bot = window_top + curr_dim_scaled(1);
%                     window_left = j - test_cols_start + 1;
%                     window_right = window_left + curr_dim_scaled(2);
%                     test_img_window_bounds = [window_top, window_bot, window_left, window_right];
%                     test_img_window = test_img(window_top:window_bot, window_left:window_right);
%                     
%                     % if rescaled is different than base, resize to base
%                     if curr_dim_scaled(1) ~= sample_dim_scaled(1) || curr_dim_scaled(2) ~= sample_dim_scaled(2)
%                         test_img_window = imresize(test_img_window, sample_dim_scaled, 'bilinear');
%                     end
%                     
%                     % get window integral
%                     test_img_window_integral = integral_image(test_img_window);
% 
%                     % evaluate strong classifier on window
%                     classified_magnitude_result = eval_strong_classifier(test_img_window_integral, soft_classifiers, strong_classifier);
%                     if classified_magnitude_result > state_new.classifiers.magnitude_threshold
%                         classified_label_result = 1;
%                     else
%                         classified_label_result = -1;
%                     end
% 
%                     % store results
%                     test_results.magnitude(end + 1, 1) = classified_magnitude_result;
%                     test_results.labels.received(end + 1, 1) = classified_label_result;
%                     test_results.labels.expected(end + 1, 1) = -1;
%                     test_results.num_classified_nonfaces = test_results.num_classified_nonfaces + 1;
% 
%                     % if received label does not match expected
%                     if classified_label_result ~= -1
%                        state_new.misclassified.nonfaces.images{end + 1, 1} = test_img_window;
%                        state_new.misclassified.nonfaces.identities(end + 1, :) = [t, test_img_window_bounds];
%                     end
%                 end
%             end
%         end
%     end
    
    % get error
    test_results.num_classified_total = test_results.num_classified_faces + test_results.num_classified_nonfaces;
    test_results.num_misclassified_total = test_results.num_misclassified_faces + test_results.num_misclassified_nonfaces;
    test_results.error_faces = test_results.num_misclassified_faces / test_results.num_classified_faces;
    test_results.error_nonfaces = test_results.num_misclassified_nonfaces / test_results.num_classified_nonfaces;
    test_results.error_total = test_results.num_misclassified_total / test_results.num_classified_total;
   
    % store test results
    state_new.test_results = test_results;
    
    % commit new state
    if exist('state', 'var') == false
        state.all = {};
        
        % new error
        test_error_change = state_new.test_results.error_total;
        test_error_change_faces = state_new.test_results.error_faces;
        test_error_change_nonfaces = state_new.test_results.error_nonfaces;
    else
        test_error_change = state.commit.test_results.error_total - state_new.test_results.error_total;
        test_error_change_faces = state.commit.test_results.error_faces - state_new.test_results.error_faces;
        test_error_change_nonfaces = state.commit.test_results.error_nonfaces - state_new.test_results.error_nonfaces;
        
        % find number of duplicate classifiers
        for i = 1:num_classifiers_boosted
            c_new = state_new.classifiers.soft{i, :};
            
            % for each old classifier
            for j = 1:num_classifiers_boosted
                c_old = state.commit.classifiers.soft{j, :};

                % compare classifiers
                if isequal(c_new, c_old)
                    state_new.classifiers.num_duplicate = state_new.classifiers.num_duplicate + 1;
                    break;
                end
            end
        end
        
        % compare new state to previous
        state.all{end + 1, 1} = state.commit;
    end
    state.commit = state_new;
    
    % info
    test_num_iterations = test_num_iterations + 1;
    test_num_duplicate_classifiers = state.commit.classifiers.num_duplicate;
    disp('-------------round complete--------------');
    disp(strcat('num misclassified, faces: ', num2str(test_results.num_misclassified_faces), ', nonfaces: ',num2str(test_results.num_misclassified_nonfaces))); 
    disp(strcat('error change, total: ', num2str(test_error_change), ', faces: ', num2str(test_error_change_faces), ', nonfaces: ', num2str(test_error_change_nonfaces)));
    disp(strcat('num duplicate classifiers: ', num2str(state.commit.classifiers.num_duplicate)));
    disp(strcat('current num iterations: ', num2str(test_num_iterations)));
    disp('-----------------------------------------');
    
    % save classifier state for round
    save(strcat(training_directory, '\', 'face_classifier_', training_version, '.mat'), 'face_classifier');
end

% % find max amongst test results
% test_results_max = max(test_results(:));
% 
% % if greater than threshold
% if test_results_max > 0
%     % find all indices with max value
%     [test_results_max_rows, test_results_max_cols] = find(test_results == test_results_max);
% 
%     for i = 1:size(test_results_max_rows, 1)
%         for j = 1:size(test_results_max_cols, 1)
%             window_top = test_results_max_rows(i) - test_rows_start + 1;
%             window_bot = window_top + sample_dim_scaled(1) - 1;
%             window_left = test_results_max_cols(j) - test_cols_start + 1;
%             window_right = window_left + sample_dim_scaled(2) - 1;
%             figure(i); imshow(draw_rectangle1(test_img, window_top, window_bot, window_left, window_right) / 255, []);
%         end
%     end
% end



% %
% %
% % Using GML AdaBoost Toolbox
% %   > around 500 samples of face and 500 samples of nonface gave
% %     0.4% error with RealAdaBoost and 1.4% error with ModestAdaBoost
% %     
% %
% %
% 
% % Step1: reading Data from the file
% for i = 1:num_samples_faces
%     samples.faces.images_v(:, i) = samples.faces.images{i}(:);
% end
% for i = 1:num_samples_nonfaces
%     samples.nonfaces.images_v(:, i) = samples.nonfaces.images{i}(:);
% end
% 
% % boosting iterations
% MaxIter = 100; 
% 
% % Step2: splitting data to training and control set
% TrainData   = [samples.faces.images_v, samples.nonfaces.images_v];
% TrainLabels = samples.all.labels';
% 
% % test faces
% testing.faces.images = image_list_groups_qws( training_faces_list, groups_tfl, num_samples_init, sample_gray, sample_dim, sample_crop_pcts, sample_scale );
% [num_test_faces, ~] = size(testing.faces.images);
% testing.faces.labels = ones(num_test_faces, 1);
% for i = 1:num_test_faces
%     testing.faces.images_v(:, i) = testing.faces.images{i}(:);
% end
% 
% % test nonfaces
% testing.nonfaces.images = image_list_groups_qws( training_nonfaces_list, groups_tnfl, num_samples_init, sample_gray, sample_dim, sample_crop_pcts, sample_scale, true );
% [num_test_nonfaces, ~] = size(testing.nonfaces.images);
% testing.nonfaces.labels = zeros(num_test_nonfaces, 1);
% testing.nonfaces.labels(:) = -1;
% for i = 1:num_test_nonfaces
%     testing.nonfaces.images_v(:, i) = testing.nonfaces.images{i}(:);
% end
% 
% % combine test labels
% testing.all.labels = [testing.faces.labels; testing.nonfaces.labels];
% 
% ControlData   = [testing.faces.images_v, testing.nonfaces.images_v];
% ControlLabels = testing.all.labels';
% 
% % Step3: constructing weak learner
% weak_learner = tree_node_w(3); % pass the number of tree splits to the constructor
% 
% % Step4: training with Gentle AdaBoost
% [RLearners RWeights] = RealAdaBoost(weak_learner, TrainData, TrainLabels, MaxIter);
% 
% % Step5: training with Modest AdaBoost
% [MLearners MWeights] = ModestAdaBoost(weak_learner, TrainData, TrainLabels, MaxIter);
% 
% % Step6: evaluating on control set
% ResultR_raw = Classify(RLearners, RWeights, ControlData);
% ResultR = sign(ResultR_raw);
% 
% ResultM = sign(Classify(MLearners, MWeights, ControlData));
% 
% % Step7: calculating error
% ErrorR  = sum(ControlLabels ~= ResultR) / length(ControlLabels);
% 
% ErrorM  = sum(ControlLabels ~= ResultM) / length(ControlLabels);

