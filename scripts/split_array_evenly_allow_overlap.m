function [ indices, num_groups, num_per_group, num_overlapping ] = split_array_evenly_allow_overlap( array_length, split_pct )
%SPLIT_ARRAY_EVENLY_ALLOW_OVERLAP splits a 1D array's indices into even and
%overlapping parts based on array_length and split_pct

% each group contains overlapping numbers
% number of overlapping is as follows:
% num_total - num_per_group * num_groups = num_remaining
% num_per_group + num_remaining = new_num_per_group
% new_num_per_group - (num_remaining - 1) = num_non_overlapping
% next group's first starts at num_non_overlapping from last first

num_per_group = ceil(array_length * split_pct);
num_groups = floor(array_length / num_per_group);
num_remaining = array_length - (num_groups * num_per_group);
num_per_group = num_per_group + num_remaining;
num_overlapping = num_remaining - 1;

% init groups
indices = zeros(num_groups, num_per_group);

% set indices
last_index = 1;
for i = 1:num_groups
    new_last_index = last_index + (num_per_group - 1);
    indices(i, :) = last_index:new_last_index;
    last_index = new_last_index - num_overlapping;
end

end

