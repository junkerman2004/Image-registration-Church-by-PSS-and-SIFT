%% Author: ZHANG Kai 202200171008
%% Replicate Paper Content, Calculate Phase Difference Between Images
function [ssp] = PSS(I1, I2)
% ssp
%   Calculate the phase similarity between two images (I1 and I2).
%
% INPUT:
%   I1: First input image.
%   I2: Second input image.
%
% OUTPUT:
%   ssp: Phase similarity score.

% Ensure both images have the same dimensions
if sum(size(I1)) ~= sum(size(I2))
    Iex = zeros(size(I1));
    [x, y, ~] = size(I2);
    Iex(1:x, 1:y, :) = I2;
    Iex = uint8(Iex);
    I2 = Iex;
end

% Convert images to grayscale
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

% Perform Fourier Transform
FI1 = fft2(I1gray);
FI2 = fft2(I2gray);

% Calculate phase difference and perform inverse Fourier Transform
ssp = ifft2((FI1 .* conj(FI2)) ./ sqrt((FI1 .* conj(FI1)) .* (FI2 .* conj(FI2)))); % Inverse transform from frequency domain to spatial domain
ssp = max(max(ssp)); % Take the maximum value of the phase similarity
end