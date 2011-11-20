function [ result ] = remove_directories_from_dir_list( list_as_struct )
%REMOVE_DIRECTORIES_FROM_DIR_LIST removes all directories from a struct
%list created by dir()

result = list_as_struct;

[rows, ~] = size(result);

for i = 1:rows
    fi = rows - i + 1;
    if result(fi).isdir == 1
        if fi == rows
            result = result(1:(fi - 1), :);
        elseif fi == 1
            result = result((fi + 1):end, :);
        else
            result = [result(1:(fi - 1), :); result((fi + 1):end, :)];
        end
    end
end

end

