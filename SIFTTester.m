%% Author:ZHANG Kai 202200171008
%% This script helps you to debug your implementation of SIFTDescriptor.m.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%！！！！！！！！！ the target file has been defined and saved ,that may be an error 
% without changing the file name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clear all
clc; close all; clear all;

%% Add path
addpath('KeypointDetect');

%% Define the output directory
outputDir = './output_plots1/';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% Loop through all images from q1 to q20
for i = 1:20
    % Construct the image file name
    imgFileName = sprintf('./dataset/images/q%d.jpg', i);
    
    % Load the image
    img = imread(imgFileName);
    
    % Detect keypoints
    [feature, ~, imp] = detect_features(img);
    
    % Build descriptors
    descriptors = SIFTDescriptor(imp, feature(:,8:9), feature(:,3));
    
    %% Visualize n descriptors
    n = 70;
    figure;
    imagesc(img);
    hold on;
    PlotSIFTDescriptor(descriptors(1:n,:)', feature(1:n,1:3)');
    hold off;
    
    % Define the output file name
    outputFileName = sprintf('%s/q%d_plot.png', outputDir, i);
    
    % Save the plot to the output directory
    saveas(gcf, outputFileName, 'png');
    
    % Close the current figure to free up memory
    close(gcf);
end