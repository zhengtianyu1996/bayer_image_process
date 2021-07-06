% Function: 
%       Convert a RGB img to raw file with specific Bayer Pattern
%       The raw image should be very similar to the real data captured from
%       image sensor, so we suppose the default precision is 12bits and
%       apply an invert ISP pipeline to the RGB image.
%
% Invert ISP pipeline:
%   De-Gamma
%   De-Color Correction
%   Sample a RGB image
%   De-White Balance
%   De-Gain
%   De-Black Level Correction
%
% Bayer Format Example:
%   'GBRG' :
%               G B G B
%               R G R G
%               G B G B
%               R G R G
% Matlab index starts since 1, not 0

fclose all;clear all;close all;clc

img=double(imread('img.jpg'));      % read as shape:[height, width, channel]

crop_size = [640, 512];     % height, width
bayer_format = 'GBRG';      % Bayer pattern, Default: 'GBRG'
frames = 5;                 % how many frames you want to save in the raw file. Set to 1 for development
nbits = 12;                 % specify the precision of each saved pixel, 1-8 : uint8, 9-16 : uint16, etc.. | 12/14/16 is common
                            % if set to 8, please set blc (Line 99) to 0

max_v = 2^nbits - 1;        % Max value of the saved image

fid = fopen(['./img_bayer_' num2str(crop_size(1)) 'x' num2str(crop_size(2)) '_' bayer_format '_' num2str(nbits, '%02d') 'bits.raw'], 'wb');

for i=1:frames
    % crop RGB img to a patch with shape [crop_size(1), crop_size(2), *]
    start_pos = [300 + 30 * i, 300 + 30 * i];       % Up-Left Position, [row, col]
    img_patch_ori = img(start_pos(1):start_pos(1)+crop_size(1)-1, start_pos(2):start_pos(2)+crop_size(2)-1, :);   
    
    %% Invert ISP pipeline
    % Scale the image from [0, 255] to [0, 4095]
    img_patch = round(img_patch_ori*max_v/255);
    
    % De-Gamma
    gamma_v = 2.2;
    img_patch = (double(img_patch)/max_v).^gamma_v;
    img_patch = round(img_patch*max_v);
    img_patch = min(max(img_patch, 0), max_v);
    
    % De-Color Correction
    CCM=[1.2148, -0.2461, 0.0313;   % sum = 1 color correction matrix
        -0.1992, 1.2969, -0.0977;   % sum = 1
        0.1406, -0.6094, 1.4688];   % sum = 1
    CCM_Invert = CCM^-1;
    img_patch_ccm = zeros(size(img_patch));
    img_patch_ccm(:,:,1)=img_patch(:,:,1)*CCM_Invert(1,1)+img_patch(:,:,2)*CCM_Invert(1,2)+img_patch(:,:,3)*CCM_Invert(1,3);
    img_patch_ccm(:,:,2)=img_patch(:,:,1)*CCM_Invert(2,1)+img_patch(:,:,2)*CCM_Invert(2,2)+img_patch(:,:,3)*CCM_Invert(2,3);
    img_patch_ccm(:,:,3)=img_patch(:,:,1)*CCM_Invert(3,1)+img_patch(:,:,2)*CCM_Invert(3,2)+img_patch(:,:,3)*CCM_Invert(3,3);
    img_patch = round(img_patch_ccm);
    img_patch = min(max(img_patch, 0), max_v);
    
    % Sample the RGB img according to bayer format
    switch bayer_format
        case 'GBRG'
            pos_R = [2,1]; pos_G1 = [1,1]; pos_G2 = [2,2]; pos_B = [1,2];
        case 'GRBG'
            pos_R = [1,2]; pos_G1 = [1,1]; pos_G2 = [2,2]; pos_B = [2,1];
        case 'RGGB'
            pos_R = [1,1]; pos_G1 = [1,2]; pos_G2 = [2,1]; pos_B = [2,2];
        case 'BGGR'
            pos_R = [2,2]; pos_G1 = [1,2]; pos_G2 = [2,1]; pos_B = [1,1];
        otherwise
            disp('Format is not supported!')
            return
    end
    img_bayer = zeros(crop_size(1), crop_size(2));    % initial an empty bayer img
    img_bayer(pos_R(1):2:end, pos_R(2):2:end) = img_patch(pos_R(1):2:end, pos_R(2):2:end, 1);         % R 
    img_bayer(pos_G1(1):2:end, pos_G1(2):2:end) = img_patch(pos_G1(1):2:end, pos_G1(2):2:end, 2);     % G1
    img_bayer(pos_G2(1):2:end, pos_G2(2):2:end) = img_patch(pos_G2(1):2:end, pos_G2(2):2:end, 2);     % G2
    img_bayer(pos_B(1):2:end, pos_B(2):2:end) = img_patch(pos_B(1):2:end, pos_B(2):2:end, 3);         % B
    
    % De-White Balance
    wb_gains=[1.6016, 1.0, 1.0, 1.2422];      % [r, g1, g2, b]
    wb_gains_invert = 1./wb_gains;
    img_bayer(pos_R(1):2:end, pos_R(2):2:end) = round(img_bayer(pos_R(1):2:end, pos_R(2):2:end) * wb_gains_invert(1));
    img_bayer(pos_G1(1):2:end, pos_G1(2):2:end) = round(img_bayer(pos_G1(1):2:end, pos_G1(2):2:end) * wb_gains_invert(2));
    img_bayer(pos_G2(1):2:end, pos_G2(2):2:end) = round(img_bayer(pos_G2(1):2:end, pos_G2(2):2:end) * wb_gains_invert(3));
    img_bayer(pos_B(1):2:end, pos_B(2):2:end) = round(img_bayer(pos_B(1):2:end, pos_B(2):2:end) * wb_gains_invert(4));
    img_bayer = min(max(img_bayer, 0), max_v);
    
    % De-Gain
    d_gain = 4.5;
    img_bayer = img_bayer / d_gain;
    img_bayer = min(max(img_bayer, 0), max_v);
    
    % De-Black Level Correction
    blc = 240;              % if nbits = 8, please set blc to 0
    img_bayer = img_bayer + blc;
    img_bayer = min(max(img_bayer, 0), max_v);
    
    %% Save bayer format raw file with specified precision
    if nbits>0 && nbits<9
        bit_prec = 'uint8';
    elseif nbits>8 && nbits<17
        bit_prec = 'uint16';
    end
    fwrite(fid, img_bayer, bit_prec);
    
    % Save ground truth RGB image (uint8)
    imwrite(uint8(img_patch_ori), ['./img_gt_' num2str(i, '%03d') '.jpg']);
end

fclose(fid);
