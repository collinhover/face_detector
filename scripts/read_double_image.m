function result = read_double_image(filename)

% reads a double image in a format compatible with my C++ code

result = [];
fp = fopen(filename, 'r');
if fp == -1
    disp(['failed to open ', filename]);
    return;
end

result = read_double_image2(fp);
fclose(fp);
