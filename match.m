%% Author: ZHANG Kai 202200171008
function [feature_tforms] = match(image1, image2)
% image1: First input image
% image2: Second input image
%
% This function detects feature points in both images, matches them,
% and estimates the geometric transformation required to align the images.

% Convert images to grayscale
image1_gray = rgb2gray(image1);
image2_gray = rgb2gray(image2);

% Detect SURF feature points in both images with a threshold
image1_point = detectSURFFeatures(image1_gray, 'MetricThreshold', 50);
image2_point = detectSURFFeatures(image2_gray, 'MetricThreshold', 50);

% Extract feature descriptors from the detected points
[image1_features, image1_point] = extractFeatures(image1_gray, image1_point);
[image2_features, image2_point] = extractFeatures(image2_gray, image2_point);

% Match feature descriptors using the Lowe's ratio test
boxPairs = matchFeatures(image1_features, image2_features, 'MaxRatio', 0.7);

% Select the matched feature points from both images
image1_match = image1_point(boxPairs(:, 1), :); % Matched points from the first image
image2_match = image2_point(boxPairs(:, 2), :); % Matched points from the second image

% Estimate the geometric transformation matrix using the matched points
% 'similarity' option is used to estimate a similarity transformation (rotation, translation, and scale)
% 'Confidence' and 'MaxNumTrials' parameters are set to ensure robust estimation
tforms = estimateGeometricTransform(image1_match, image2_match, 'similarity', 'Confidence', 99, 'MaxNumTrials', 1500);

% Return the estimated transformation matrix
feature_tforms = tforms;
