function [img_rgb] = demosaic_fn(img_bayer,bayer_format, method)
%% Function: 
%       Demosaic a bayer image by various demosaic methods.
%
% Supported method:
%   bilinear    - Fastest, easiest method
%   gcbi        - Matlab Function

% Input:
%   img_bayer       -   Bayer format image
%   bayer_format    -   Default:'GBRG'.
%   method          -   Default:'bilinear'
% Output:
%   img_rgb         -   Output RGB image

%% Set default params
if nargin < 3
    method = 'bilinear';
end
if nargin < 2
    bayer_format = 'GBRG';
end

%% Process
switch method
    case 'bilinear' % bilinear interpolation
        img_rgb = dm_bilinear(img_bayer, bayer_format);
  	case 'gcbi'
        % Matlab Demosaic : gradient-corrected (bi)linear interpolation
        img_rgb = demosaic(uint16(img_bayer), lower(bayer_format));
    otherwise
        disp('Method not support yet.')
        return
end

end

function img_rgb = dm_bilinear(img_bayer, bayer_format)
%% Function: 
%       Demosaic a bayer image by bilinear method.

img_rgb = zeros(size(img_bayer,1), size(img_bayer,2), 3);

%% Bayer Padding 2x2, eg. 1920*1080 -> 1924*1084
% why padding 2? Because Bayer format is 2x2, and bilinear conv kernel size is 3x3
img_bayer_padding = zeros(size(img_bayer, 1)+4, size(img_bayer, 2)+4);
img_bayer_padding(3:end-2,3:end-2)=img_bayer;
img_bayer_padding(3:end-2, 1:2)=img_bayer(1:end, 1:2);
img_bayer_padding(3:end-2, end-1:end)=img_bayer(1:end, end-1:end);
img_bayer_padding(1:2, 1:end)=img_bayer_padding(3:4, 1:end);
img_bayer_padding(end-1:end, 1:end)=img_bayer_padding(end-3:end-2, 1:end);
img_bayer = img_bayer_padding;

%% Create CFA mask for each of the three colors
switch bayer_format
    case 'GBRG'
      	mask_R = repmat([0 0;1 0],size(img_bayer)/2);
        mask_G = repmat([1 0;0 1],size(img_bayer)/2);
        mask_B = repmat([0 1;0 0],size(img_bayer)/2);
    case 'GRBG'
     	mask_R = repmat([0 1;0 0],size(img_bayer)/2);
        mask_G = repmat([1 0;0 1],size(img_bayer)/2);
        mask_B = repmat([0 0;1 0],size(img_bayer)/2);
    case 'RGGB'
        mask_R = repmat([1 0;0 0],size(img_bayer)/2);
        mask_G = repmat([0 1;1 0],size(img_bayer)/2);
        mask_B = repmat([0 0;0 1],size(img_bayer)/2);
    case 'BGGR'
      	mask_R = repmat([0 0;0 1],size(img_bayer)/2);
        mask_G = repmat([0 1;1 0],size(img_bayer)/2);
        mask_B = repmat([1 0;0 0],size(img_bayer)/2);
    otherwise
        disp('Format is not supported!')
        return
end

cn_R = img_bayer.*mask_R;
cn_G = img_bayer.*mask_G;
cn_B = img_bayer.*mask_B;

%% Bilinear Process by Convolution
R = conv2(cn_R,[1 2 1;2 4 2;1 2 1]/4,'same');
G = conv2(cn_G,[0 1 0;1 4 1;0 1 0]/4,'same');
B = conv2(cn_B,[1 2 1;2 4 2;1 2 1]/4,'same');

%% remove padding
R = R(3:end-2, 3:end-2);
G = G(3:end-2, 3:end-2);
B = B(3:end-2, 3:end-2);

%% Merge
img_rgb(:,:,1)=R;
img_rgb(:,:,2)=G;
img_rgb(:,:,3)=B;

end

