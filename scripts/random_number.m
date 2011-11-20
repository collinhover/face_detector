function result = random_number(lowest, highest)

% function result = random_number(lowest, highest)
%
% returns a random integer uniformly distributed in the range
% {lowest, lowest+1, lowest+2, ...,  highest}

 random_number = rand(1);
 range = highest - lowest +1;
 step = 1/range;
 result = floor(random_number/step);
 result = result + lowest;
 