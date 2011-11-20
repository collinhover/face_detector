function [ face_locs, face_locs_row, face_locs_col, face_locs_scale ] = detect_faces_rectangle_cascades( filename, face_classifier )
%DETECT_FACES_RECTANGLE_CASCADES detects faces in an image based on
%boosted classifier made from rectangle filters and applied in cascades

% read image
img = imread(filename);

% figure, imshow(img, []);

% find stretchlim of contrast for image
img_stretchlim = stretchlim(img, [0 1]);
img_stretchlim(1, :) = min(0.2, max(img_stretchlim(1, :)));
img_stretchlim(2, :) = max(0.8, max(img_stretchlim(2, :)));

% contrast image as necessary
img = normalize_range(img, 0, 1);
img = imadjust(img, img_stretchlim, []);
img = normalize_range(img, 0, 255);
img = uint8(img);

% size
[rows, cols, ~] = size(img);

% skin detection
if size(img, 3) > 1 && face_classifier.skin.enabled == true
    skin = detect_skin(img, face_classifier.skin.hist_pos, face_classifier.skin.hist_neg);
else
    skin = ones(rows, cols);
end

% find indices in img where skin is above threshold
skin_locs = skin > face_classifier.skin.threshold;
% remove skin noise
skin_neighborhood_open = ones(3, 3);
skin_locs = imopen(skin_locs, skin_neighborhood_open);
[skin_locs_row, skin_locs_col] = find(skin_locs);
skin_locs_row = skin_locs_row';
skin_locs_col = skin_locs_col';
num_skin_locations = size(skin_locs_row, 2);

% figure, imshow(img, []);
% figure, imshow(skin, []);

% init results
num_scales = size(face_classifier.scales, 2);
face_locs = zeros(rows, cols, num_scales);
face_locs_row = [];
face_locs_col = [];
face_locs_scale = [];

% if skin locations found
if num_skin_locations > 0
    
    % init further results
    face_magnitudes = zeros(rows, cols, num_scales);
    face_locs_remove = zeros(rows, cols, num_scales);
    
    % create mask for contrast filter
    % remove noise (i.e. lone skin pixels)
    skin_neighborhood_open = ones(7, 7);
    skin_mask = imopen(skin_locs, skin_neighborhood_open);
    skin_neighborhood_close = strel('disk', 11);
    skin_mask = imdilate(skin_mask, skin_neighborhood_close);
    
%     figure, imshow(skin_locs, []);
%     figure, imshow(skin_mask, []);
    
    % gray image
    if size(img, 3) > 1
        img_gray = double(rgb2gray(img));
    else
        img_gray = double(img);
    end
    
    % reverse mask non skin areas (i.e. keep all non skin)
    img_gray_skin_masked = img_gray .* (1 - skin_mask);
    % for contrasting, keep only skin
    img_skin_contrasted = img_gray .* skin_mask;
    
%     figure, imshow(img_gray, []);
%     figure, imshow(img_gray_skin_masked, []);
%     figure, imshow(img_skin_contrasted, []);
    
    % find all skin components
    adapt_num_tiles_range = 2:1:6;
    adapt_window_size_min = [70 50];
    adapt_window_size_max = [170 120];
    [img_skin_components, img_skin_component_num] = bwlabel(skin_mask);
    for n = 1:img_skin_component_num
        % get window
        [component_rows, component_cols] = find(img_skin_components == n);
        window_top = min(component_rows);
        window_bot = max(component_rows);
        window_left = min(component_cols);
        window_right = max(component_cols);
        window = uint8(img_skin_contrasted(window_top:window_bot, window_left:window_right));
        % get num tiles for adapt hist eq based on window size
        % larger window = less tiles = less noise
        adapt_tile_pct_rows = min(1, max(0, ((window_bot - window_top) - adapt_window_size_min(1)) / (adapt_window_size_max(1) - adapt_window_size_min(1))));
        adapt_tile_pct_cols = min(1, max(0, ((window_right - window_left) - adapt_window_size_min(2)) / (adapt_window_size_max(2) - adapt_window_size_min(2))));
        adapt_num_tiles = adapt_num_tiles_range(max(1, ceil(size(adapt_num_tiles_range, 2) * (1 - (adapt_tile_pct_rows + adapt_tile_pct_cols) * 0.5))));
        % contrast window
        window = normalize_range(window, 0, 1);
        window = adapthisteq(window, 'NumTiles', [adapt_num_tiles adapt_num_tiles]);
        window = double(normalize_range(window, 0, 255));
        
        % add window back
        img_skin_contrasted(window_top:window_bot, window_left:window_right) = window .* skin_mask(window_top:window_bot, window_left:window_right);
    end
    
%     % contrast
%     img_skin_contrasted = normalize_range(img_skin_contrasted, 0, 1);
%     img_skin_contrasted = adapthisteq(img_skin_contrasted);
%     img_skin_contrasted = normalize_range(img_skin_contrasted, 0, 255);
    
    % add contrasted skin areas back to to non skin areas
    img_gray_skin_masked = img_gray_skin_masked + img_skin_contrasted;
    img_gray = img_gray_skin_masked;
    
%     figure, imshow(img_gray, [0 255]);
%     pause;

    % classifier dimensions
    c_rows = face_classifier.dimensions(1);
    c_cols = face_classifier.dimensions(2);

    % for each scale
    for s = 1:num_scales
        % rescale dimensions of image
        scale_cl = face_classifier.scales(s);
        scale_im = 1 / scale_cl;
        if scale_im == Inf || scale_im < 0
            scale_im = 1;
        end
        si_rows = round(rows * scale_im);
        si_cols = round(cols * scale_im);
        disp(strcat('detecting at scale: ', num2str(scale_cl), ', with actual image scale/size: ', num2str(scale_im), ', new dim: ', mat2str([si_rows, si_cols]), '(', mat2str([rows, cols]), ')'));
        % if rescaled is larger than image, skip scale
        if si_rows < c_rows || si_cols < c_cols
            disp('> skipping scale');
            continue;
        else
            % scale image
            img_gray_scaled = imresize(img_gray, scale_im, 'bilinear');
            
            % new integral 
            img_integral_scaled = integral_image(img_gray_scaled);
        end

        % get start and end points based on scaled classifier size
        rows_start = ceil(c_rows * 0.5);
        rows_end = si_rows - rows_start - 1;
        cols_start = ceil(c_cols * 0.5);
        cols_end = si_cols - cols_start - 1;

        % for each skin pixel
        for l = 1:num_skin_locations
            i_loc = skin_locs_row(l);
            j_loc = skin_locs_col(l);
            i = round(i_loc * scale_im);
            j = round(j_loc * scale_im);

            % if row is before start or after end, skip
            if i < rows_start || j < cols_start || i > rows_end || j > cols_end 
                continue;
            end

            % get next window bounds
            window_top = i - rows_start + 1;
            window_left = j - cols_start + 1;

            % for each cascade point
            for c = 1:face_classifier.cascade_num
                % eval cascade range
                magnitude = eval_strong_classifier(img_integral_scaled, face_classifier.soft, face_classifier.strong, window_top, window_left, face_classifier.cascade_ranges{c});
                face_magnitudes(i_loc, j_loc, s) = face_magnitudes(i_loc, j_loc, s) + magnitude;
                magnitude_threshold = face_classifier.magnitude_threshold * (face_classifier.cascade_points(c, 2) / face_classifier.cascade_points(end, 2));
                if face_magnitudes(i_loc, j_loc, s) >= magnitude_threshold
                    face_locs(i_loc, j_loc, s) = 1;
                else
                    face_locs(i_loc, j_loc, s) = -1;
                    break;
                end
            end
        end
    end

    % trim results
    [face_locs_row, face_locs_col] = find(face_locs == 1);
    face_locs_scale = floor(face_locs_col / cols);
    face_locs_col = face_locs_col - (face_locs_scale * cols);
    face_locs_scale = face_locs_scale + 1;
    num_face_locs = size(face_locs_row, 1);
    for l = 1:num_face_locs
        % get location and scale
        i = face_locs_row(l);
        j = face_locs_col(l);
        s = face_locs_scale(l);
        
        % find all others nearby, regardless of scale
        % to search only in same scale, add: face_locs_scale(l+1:end) == s & 
        others_nearby = find(abs(face_locs_row(l+1:end) - i) <= face_classifier.min_dist & abs(face_locs_col(l+1:end) - j) <= face_classifier.min_dist) + l;
        others_nearby = others_nearby';

        % for all other locations of same scale within min_dist
        for o = others_nearby
            oi = face_locs_row(o);
            oj = face_locs_col(o);
            os = face_locs_scale(o);
            if face_magnitudes(i, j, s) > face_magnitudes(oi, oj, os)
                face_locs_remove(oi, oj, os) = 1;
            else
                face_locs_remove(i, j, s) = 1;
                break;
            end
        end
    end

    % remove all locations that need removal
    face_locs(face_locs_remove == 1) = -1;

    % get final positions and scales
    [face_locs_row, face_locs_col] = find(face_locs == 1);
    face_locs_scale = floor(face_locs_col / cols);
    face_locs_col = face_locs_col - (face_locs_scale * cols);
    face_locs_scale = face_locs_scale + 1;
    
%     % draw rectangle onto remaining face locations
%     img_result = img;
%     num_face_locs = size(face_locs_row, 1);
%     for l = 1:num_face_locs
%         i = face_locs_row(l);
%         j = face_locs_col(l);
%         s = face_locs_scale(l);
%         scale_cl = face_classifier.scales(s);
%         c_rows_half = round(c_rows * scale_cl * 0.5);
%         c_cols_half = round(c_cols * scale_cl * 0.5);
%         img_result = draw_rectangle1(img_result, i - c_rows_half + 1, i + c_rows_half, j - c_cols_half + 1, j + c_cols_half);
%     end
%     figure, imshow(img_result, []);
end

end

