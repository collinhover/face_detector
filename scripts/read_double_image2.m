function result = read_double_image2(fp)

% same as read_double_image, but here we pass in a file pointer

[header, count] = fread(fp, 4, 'int32');
result = [];

if count ~= 4
    disp('failed to read header');
    return;
elseif header(1) ~= 5
    disp(sprintf('bad entry in header 1: %li', header(1)));
    return;
elseif header(4) < 1
    disp(sprintf('bad number of bands: %li', header(4)));
    return;
end

vertical = header(2);
horizontal = header(3);
channels = header(4);

result = zeros(channels, vertical, horizontal);
for counter = 1: channels
    [temporary, count] = fread(fp, [horizontal, vertical], 'double');
    if count ~= vertical * horizontal
        disp(sprintf('failed to read data, count = %li', count));
        result = [];
        return;
    end
    temporary = temporary';
    result(counter,:,:) = temporary;
end


