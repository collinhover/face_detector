function result = draw_rectangle1(frame, top, bottom, left, right);

% function result = draw_rectangle1(frame, top, bottom, left, right);
%
% frame is a grayscale or color image. result is a copy of frame 
% with a white rectangle superimposed.

% make sure rectangle fits in the image
[rows, cols] = size(frame);
left = max(2, left);
left = min(cols-1, left);
right = max(2, right);
right = min(cols-1, right);
top = max(2, top);
top = min(rows-1, top);
bottom = max(2, bottom);
bottom = min(rows-1, bottom);

result = frame;
% we do (left-1):(left+1) to have a thicker line.
bands = size(result, 3);
for band = 1:bands
    result(top:bottom, [(left-1):(left+1), (right-1):(right+1)], band) = 255;
    result([(top-1):(top+1), (bottom-1):(bottom+1)], left:right, band) = 255;
end
