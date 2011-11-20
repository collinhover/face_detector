function [ result ] = test_results_directory_setup( directory )
%TEST_RESULTS_DIRECTORY_SETUP inits test results struct by directory

result.path = directory;
result.list = dir(result.path);
result.list = remove_directories_from_dir_list(result.list);
result.num_images = size(result.list, 1);
for i = 1:result.num_images
    result.list(i).name = [result.path, '\', result.list(i).name];
end
result.mis_windows = zeros(0, 6); % image index (1), false pos = 1 / false neg = 0 (2), bounds (3:6)
result.true_positives = 0;
result.true_negatives = 0;
result.false_positives = 0;
result.false_negatives = 0;
result.total_images_classified = 0;
result.total_windows_classified = 0;

end

