function match = SIFTSimpleMatcher(descriptor1, descriptor2, thresh)
% SIFTSimpleMatcher
%   Match one set of SIFT descriptors (descriptor1) to another set of
%   descriptors (descriptor2). Each descriptor from descriptor1 can at
%   most be matched to one member of descriptor2, but descriptors from
%   descriptor2 can be matched more than once.
%   
%   Matches are determined as follows:
%   For each descriptor vector in descriptor1, find the Euclidean distance
%   between it and each descriptor vector in descriptor2. If the smallest
%   distance is less than thresh * (the next smallest distance), we say that
%   the two vectors are a match, and we add the row [d1 index, d2 index] to
%   the "match" array.
%   
% INPUT:
%   descriptor1: N1 * 128 matrix, each row is a SIFT descriptor.
%   descriptor2: N2 * 128 matrix, each row is a SIFT descriptor.
%   thresh: a given threshold of ratio. Typically 0.7
%
% OUTPUT:
%   match: N * 2 matrix, each row is a match.
%          For example, match(k, :) = [i, j] means the i-th descriptor in
%          descriptor1 is matched to the j-th descriptor in descriptor2.

% Default threshold
if ~exist('thresh', 'var'),
    thresh = 0.8;
end

match = [];

% Get the size of the descriptors
[N1, ~] = size(descriptor1);
[N2, ~] = size(descriptor2);

% Loop through each descriptor in descriptor1
for i = 1:N1
    % Compute the Euclidean distance between the current descriptor in descriptor1 and all descriptors in descriptor2
    distances = pdist2(descriptor1(i, :), descriptor2, 'euclidean');
    
    % Sort the distances
    [sorted_distances, idx] = sort(distances);
    
    % Check if the smallest distance is less than the threshold times the next smallest distance
    if sorted_distances(1) < thresh * sorted_distances(2)
        match = [match; [i, idx(1)]];
    end
end

end