%% Author: ZHANG Kai  202200171008
%% Stitch two images together
function [image, tforms] = imagestitch(image_last, image_next, tforms_last)
%% image_last: The image resulting from the previous stitching iteration
%% image_next: The next image to be stitched
%% tforms_last: The transformation matrix from the previous stitching iteration

% Initialize the image transformation matrix
t1 = affine2d([1 0 0; 0 1 0; 0 0 1]);

% Match features between the two images
[feature_tforms] = match(image_next, image_last);

% Calculate the canvas size
[xlim(1,:), ylim(1,:)] = outputLimits(tforms_last, [1 size(image_last,2)], [1 size(image_last,1)]); 
[xlim(2,:), ylim(2,:)] = outputLimits(feature_tforms, [1 size(image_next,2)], [1 size(image_next,1)]); 
xMin = min([1; xlim(:)]);
xMax = max([size(image_last,2); xlim(:)]);
yMin = min([1; ylim(:)]);
yMax = max([size(image_last,1); ylim(:)]);
width  = round(xMax - xMin);
height = round(yMax - yMin);
xLimits = [xMin xMax];
yLimits = [yMin yMax];

% Create a new canvas
image_new = zeros([height, width, 3], 'like', image_next);
view = imref2d([height, width], xLimits, yLimits); % Create a 2D spatial reference object to define the size of the panorama

% Create a blender object for blending images
blender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port'); 

% Warp the last image to the new canvas
lastWarpedImage = imwarp(image_last, t1, 'cubic', 'OutputView', view, 'SmoothEdges', true);
lastmask = imwarp(true(size(image_last, 1), size(image_last, 2)), t1, 'cubic', 'OutputView', view, 'SmoothEdges', true); % Generate a mask

% Warp the next image to the new canvas
warpedImage = imwarp(image_next, feature_tforms, 'cubic', 'OutputView', view, 'SmoothEdges', true);
mask = imwarp(true(size(image_next, 1), size(image_next, 2)), feature_tforms, 'cubic', 'OutputView', view, 'SmoothEdges', true); % Generate a mask

% Blend the warped images onto the new canvas
image_new = step(blender, image_new, lastWarpedImage, lastmask);
image_new = step(blender, image_new, warpedImage, mask);

% Remove black borders in both directions
Ig = rgb2gray(image_new);
blackInx = sum(Ig, 1) == 0; % Sum along columns
if ~isempty(blackInx)
    Inx = 1:size(Ig, 2);
    Inx(blackInx) = [];
    image_cut = image_new(:, Inx, :);
else
    image_cut = image_new;
end

% Remove black borders in the other direction
Ig = rgb2gray(image_cut);
Ig = Ig';
blackInx = sum(Ig, 2) == 0; % Sum along rows
if ~isempty(blackInx)
    Inx = 1:size(Ig, 2);
    Inx(blackInx) = [];
    image_new = image_cut(Inx, :, :);
end

% Assign the final stitched image and transformation matrix
image = image_new;
tforms = feature_tforms;

end