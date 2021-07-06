function [img_rgb] = ISP(img_bayer, opt)
%% Function: 
%       An implementation of a simple ISP pipeline
%
% ISP pipeline:
%   Black Level Correction
%   Gain
%   White Balance
%   Demosaic
%   Color Correction
%   Gamma

% Input:
%   img_bayer   -   Bayer format image
%   opt         -   params for processing
% Output:
%   img_rgb     -   Output RGB image

%% set ISP param
nbits = opt.nbits;                              % precision, Default：12
bayer_format = opt.bayer_format;                % bayer format, Default: 'GBRG'
blc = opt.blc;                               	% black level correction value, Default: 0
d_gain = opt.d_gain;                          	% digital gain, Default: 1.0
wb_gains = opt.wb_gains;                        % white balance, [r, g1, g2, b], Default: [1.0, 1.0, 1.0, 1.0]
demosaic_method = opt.demosaic_method;        	% demosaic method, Default: 'bilinear'
CCM = opt.CCM;                                  % sum = 1.0  color correction matrix, Default: eye(3,3)
gamma_v = opt.gamma_v;                        	% gamma, Default: 1.0

max_v = 2^nbits - 1;                            % Max value of the raw image

%% Process
% Black Level Correction
% key formula: I = I - blc
img_bayer = img_bayer - blc;
img_bayer = min(max(img_bayer, 0), max_v);

% Gain
% key formula: I = I * gain
img_bayer = round(img_bayer * d_gain);
img_bayer = min(max(img_bayer, 0), max_v);

% White Balance
% key formula: I_r = I_r * gain_r ; I_g = I_g * gain_g ; I_b = I_b * gain_b
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
img_bayer(pos_R(1):2:end, pos_R(2):2:end) = img_bayer(pos_R(1):2:end, pos_R(2):2:end) * wb_gains(1);
img_bayer(pos_G1(1):2:end, pos_G1(2):2:end) = img_bayer(pos_G1(1):2:end, pos_G1(2):2:end) * wb_gains(2);
img_bayer(pos_G2(1):2:end, pos_G2(2):2:end) = img_bayer(pos_G2(1):2:end, pos_G2(2):2:end) * wb_gains(3);
img_bayer(pos_B(1):2:end, pos_B(2):2:end) = img_bayer(pos_B(1):2:end, pos_B(2):2:end) * wb_gains(4);
img_bayer = round(img_bayer);
img_bayer = min(max(img_bayer, 0), max_v);

% Demosaic
img_rgb = demosaic_fn(img_bayer, bayer_format, demosaic_method);
img_rgb = min(max(double(img_rgb), 0), max_v);

% Color Correction
% key formula: I_r = I_r * a1 + I_g * a2 + I_b * a3, a1 + a2 + a3 = 1
img_rgb_ccm = zeros(size(img_rgb));
img_rgb_ccm(:,:,1)=img_rgb(:,:,1)*CCM(1,1)+img_rgb(:,:,2)*CCM(1,2)+img_rgb(:,:,3)*CCM(1,3);
img_rgb_ccm(:,:,2)=img_rgb(:,:,1)*CCM(2,1)+img_rgb(:,:,2)*CCM(2,2)+img_rgb(:,:,3)*CCM(2,3);
img_rgb_ccm(:,:,3)=img_rgb(:,:,1)*CCM(3,1)+img_rgb(:,:,2)*CCM(3,2)+img_rgb(:,:,3)*CCM(3,3);
img_rgb = round(img_rgb_ccm);
img_rgb = min(max(img_rgb, 0), max_v);

% Gamma
% key formula: I = norm(I)^gamma * max_v
img_rgb = (double(img_rgb)/max_v).^gamma_v;
img_rgb = round(img_rgb*max_v);

end
