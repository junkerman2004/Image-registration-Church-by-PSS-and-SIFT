%% Author:ZHANG Kai 202200171008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script tests your implementation of MultiStitch.m, and you can also
% use it for generating panoramas from your own images using SIFT to better
% capture the 3D information inherent in the images. However, this approach
% might require a longer processing time to complete the task.
%
% In case generating a panorama takes too long or too much memory, it is
% advisable to resize images to smaller sizes.
%
% To ensure successful stitching, the dataset should be kept in a sequential
% order where consecutive images have overlapping regions. Otherwise, the code
% may fail due to insufficient matching points, which is a limitation of our
% implementation.
%
% You may also want to tune matching criteria and RANSAC parameters to
% optimize performance and results.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clear all
clc; 
close all; 
clc; 
%% Load a list of images (Change file name if you want to use other images)
imgList = dir(".\dataset\shuffle_images_forSIFT\q*"); 
saveFileName = 'yosemite.jpg'; 

%% Add path
addpath('KeypointDetect'); 

%% Load images into a cell array
IMAGES = cell(1, length(imgList)); % Initialize a cell array to store images
for i = 1 : length(imgList),
    IMAGES{i} = imread(['./dataset/shuffle_images_forSIFT//' imgList(i).name]); % Read each image and store it in the cell array
    %% Resize to make memory efficient
    if max(size(IMAGES{i})) > 1000 || length(imgList) > 10, 
        IMAGES{i} = imresize(IMAGES{i}, 0.6); 
    end
end
disp('Images loaded. Beginning feature detection...'); % Display a message indicating that images are loaded and feature detection is starting

%% Feature detection
DESCRIPTOR = cell(1, length(imgList)); 
POINT_IN_IMG = cell(1, length(imgList)); 
for i = 1 : length(imgList),
    [feature, ~, imp] = detect_features(IMAGES{i});
    % Detect features in the image
    POINT_IN_IMG{i} = feature(:, 1:2); 
    % Extract the coordinates of the feature points
    pointInPyramid = feature(:, 8:9); 
    % Extract additional information about the feature points
    DESCRIPTOR{i} = SIFTDescriptor(imp, pointInPyramid, feature(:,3));
    % Compute SIFT descriptors for the feature points
end

%% Compute Transformation
TRANSFORM = cell(1, length(imgList)-1); % Initialize a cell array to store transformation matrices
for i = 1 : (length(imgList)-1),
    disp(['fitting transformation from ' num2str(i) ' to ' num2str(i+1)]); 

    M = SIFTSimpleMatcher(DESCRIPTOR{i}, DESCRIPTOR{i+1}, 0.7);

    
    % Check the number of matches
    if size(M, 1) < 4 % If fewer than 4 matches are found
        warning('Not enough matches to produce a transformation matrix. Increasing match threshold...'); % Issue a warning
        M = SIFTSimpleMatcher(DESCRIPTOR{i}, DESCRIPTOR{i+1}, 0.9); % Retry with a higher threshold of 0.9
    end
    
    % Check the number of matches again
    if size(M, 1) < 4 % If still fewer than 4 matches are found
        error('Still not enough matches to produce a transformation matrix.'); % Throw an error
    end
    
    TRANSFORM{i} = RANSACFit(POINT_IN_IMG{i}, POINT_IN_IMG{i+1}, M); % Compute the transformation matrix using RANSAC
end

%% Make Panoramic image
disp('Stitching images...'); 


MultipleStitch(IMAGES, TRANSFORM, saveFileName); 

disp(['The completed file has been saved as ' saveFileName]);
imshow(imread(saveFileName)); 