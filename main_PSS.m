%% Author: ZHANG Kai 202200171008
close all;
clear; clc;

%% Program Execution Method
% Modify the folder path below
% Run the program

%% Image Reading
image_data = imageDatastore("C:\Users\张凯123\Desktop\code\dataset\images\"); % Load images from the specified directory
image_num = 20; % Number of images to stitch

figure(1);
montage(image_data.Files, 'Size', [5 ceil(image_num/5)]); % Display all images in a grid layout
title('所有加载的图像');

%% Calculate the Most Similar Pair of Images
image_init = [0 0 -Inf]; % Initialize variables to store the indices of the most similar images and their similarity score
fprintf('正在计算最相似图像对...\n');
for i = 1:image_num-1
    I1 = readimage(image_data, i); 
    for j = i+1:image_num
        I2 = readimage(image_data, j); 
        temp = PSS(I1, I2); 
        if temp > image_init(3) % Update the most similar pair if the current similarity is higher
            image_init = [i, j, temp];
        end
    end
    fprintf('已处理第%d个图像与其他图像的相似度。\n', i);
end
fprintf('最相似的两个图像是第%d和第%d张，相似度得分：%f\n', image_init(1), image_init(2), image_init(3));

%% Automatic Sorting and Stitching
image_next = image_init(1); % Start with one of the most similar images
image = readimage(image_data, image_next); 
imagelist = setdiff(1:image_num, image_next); % Remove the initial image from the list
tforms = affine2d([1 0 0;0 1 0;0 0 1]); % Initialize the transformation matrix
fprintf('开始拼接图像，顺序为：%d', image_next); 
tic % Start timing the stitching process
for k = 1:image_num-1
    SSP = -Inf; 
    for i = 1:length(imagelist)
        q = imagelist(i); 
        I2 = readimage(image_data, q); 
        tempSSP = PSS(image, I2); % Compute the phase similarity between the current image and the stitched image
        if tempSSP > SSP 
            SSP = tempSSP;
            image_next = q;
        end
    end
    imagelist(imagelist == image_next) = []; 
    fprintf(' -> %d', image_next);
    I = readimage(image_data, image_next); 
    [image, tforms] = imagestitch(image, I, tforms); 
    figure(2);
    imshow(image); % Display the current stitched image
    title(sprintf('拼接过程 - 当前已拼接%d/%d张图像', k+1, image_num));
end
fprintf('\n %d张图像拼接完成！\n', image_num); 
imwrite(image, 'result_new.jpg');
toc 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Replicate Paper Content, Calculate Phase Difference Between Images
function [ssp] = PSS(I1, I2)
% I1: First input image
% I2: Second input image
% ssp: Phase similarity score

if sum(size(I1)) ~= sum(size(I2)) % Ensure both images have the same dimensions
    Iex = zeros(size(I1));
    [x, y, ~] = size(I2);
    Iex(1:x, 1:y, :) = I2;
    Iex = uint8(Iex);
    I2 = Iex;
end
% Convert to grayscale
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);
% Perform Fourier Transform
FI1 = fft2(I1gray);
FI2 = fft2(I2gray);
% Calculate phase difference and perform inverse Fourier Transform
ssp = ifft2((FI1 .* conj(FI2)) ./ sqrt((FI1 .* conj(FI1)) .* (FI2 .* conj(FI2)))); % Inverse transform from frequency domain to spatial domain
ssp = max(max(ssp)); % Maximum value of the phase similarity
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stitch Two Images Together
function [image, tforms] = imagestitch(image_last, image_next, tforms_last)
% image_last: The image resulting from the last stitching iteration
% image_next: The next image to be stitched
% tforms_last: Transformation matrix from the last stitching iteration

t1 = affine2d([1 0 0;0 1 0;0 0 1]); % Initialize the image transformation matrix
[feature_tforms] = match(image_next, image_last); % Match features between the two images

% Calculate the canvas size
[xlim(1,:), ylim(1,:)] = outputLimits(tforms_last, [1 size(image_last, 2)], [1 size(image_last, 1)]); % Output limits of the last image
[xlim(2,:), ylim(2,:)] = outputLimits(feature_tforms, [1 size(image_next, 2)], [1 size(image_next, 1)]); % Output limits of the next image
xMin = min([1; xlim(:)]);
xMax = max([size(image_last, 2); xlim(:)]);
yMin = min([1; ylim(:)]);
yMax = max([size(image_last, 1); ylim(:)]);
width = round(xMax - xMin);
height = round(yMax - yMin);
xLimits = [xMin xMax];
yLimits = [yMin yMax];

image_new = zeros([height, width, 3], 'like', image_next); 
view = imref2d([height, width], xLimits, yLimits); % Define the size of the panoramic image
blender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');

lastWarpedImage = imwarp(image_last, t1, 'cubic', 'OutputView', view, 'SmoothEdges', true); 
lastmask = imwarp(true(size(image_last, 1), size(image_last, 2)), t1, 'cubic', 'OutputView', view, 'SmoothEdges', true); 
warpedImage = imwarp(image_next, feature_tforms, 'cubic', 'OutputView', view, 'SmoothEdges', true); 
mask = imwarp(true(size(image_next, 1), size(image_next, 2)), feature_tforms, 'cubic', 'OutputView', view, 'SmoothEdges', true); % Generate a mask for the next image

image_new = step(blender, image_new, lastWarpedImage, lastmask); % Blend the warped last image onto the panorama
image_new = step(blender, image_new, warpedImage, mask); 
% Remove black borders
Ig = rgb2gray(image_new);
blackInx = sum(Ig) == 0; % Find columns with only black pixels
if ~isempty(blackInx)
    Inx = 1:size(Ig, 2);
    Inx(blackInx) = [];
    image_cut = image_new(:, Inx, :);
end
% Remove black borders on the other axis
Ig = rgb2gray(image_cut);
Ig = Ig';
blackInx = sum(Ig) == 0; % Find rows with only black pixels
if ~isempty(blackInx)
    Inx = 1:size(Ig, 2);
    Inx(blackInx) = [];
    image_new = image_cut(Inx, :, :);
end
image = image_new;
tforms = feature_tforms;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Detect Image Feature Points
function [feature_tforms] = match(image1, image2)
% image1: First image
% image2: Second image

image1_gray = rgb2gray(image1); 
image2_gray = rgb2gray(image2); 
image1_point = detectSURFFeatures(image1_gray, 'MetricThreshold', 50); 
image2_point = detectSURFFeatures(image2_gray, 'MetricThreshold', 50); 

% Extract feature descriptors
[image1_features, image1_point] = extractFeatures(image1_gray, image1_point);
[image2_features, image2_point] = extractFeatures(image2_gray, image2_point);

% Match feature descriptors
boxPairs = matchFeatures(image1_features, image2_features, 'MaxRatio', 0.7); % Match features based on the ratio test
image1_match = image1_point(boxPairs(:, 1), :); 
image2_match = image2_point(boxPairs(:, 2), :); 
% Estimate geometric transform
tforms = estimateGeometricTransform(image1_match, image2_match, 'similarity', 'Confidence', 99, 'MaxNumTrials', 1500); 
feature_tforms = tforms; % Return the transformation matrix
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%