%% Function: 
%       Process a raw file with bayer pattern, then convert to RGB file
% ISP pipeline:
%   Black Level Correction
%   Gain
%   White Balance
%   Demosaic
%   Color Correction
%   Gamma

fclose all;clear all;close all;clc

dir_raw = 'img_bayer_640x512_GBRG_12bits.raw';

%% Set Params
% get precision/height/width from filename, to read data correctly. If can't get param, let users decide them. 
fn_group = split(dir_raw, '_');
size_str = char(fn_group(3));
nbits = char(fn_group(5));
nbits = str2double(nbits(1:2));                     % precision, Default：12.  12/14/16 is common
pos_x = findstr(size_str, 'x');
height = str2double(size_str(1:pos_x-1));           % height, Default：1080
width = str2double(size_str(pos_x+1:end));          % width, Default：1920

% set ISP param, to control result. Users decide them
opt.nbits = nbits;                                  % precision, Default：12.  12/14/16 is common
opt.bayer_format = char(fn_group(4));               % bayer format, Default: 'GBRG'
opt.blc = 240;                                      % black level correction value, Default: 0
opt.d_gain = 4.5;                                  	% digital gain, Default: 1.0
opt.wb_gains=[1.6016, 1.0, 1.0, 1.2422];          	% white balance, [r, g1, g2, b], Default: [1.0, 1.0, 1.0, 1.0]
opt.demosaic_method = 'bilinear';                 	% demosaic method, Default: 'bilinear'. | 'bilinear', 'gcbi'
opt.CCM=[1.2148, -0.2461, 0.0313;                   % sum = 1.0   color correction matrix, Default: eye(3,3)
        -0.1992, 1.2969, -0.0977;                   % sum = 1.0
        0.1406, -0.6094, 1.4688];                   % sum = 1.0  
opt.gamma_v = 1/2.2;                                % gamma, Default: 1.0

if nbits>0 && nbits<9    
    rat = 1;
    precision = 'uint8';
elseif nbits>8 && nbits<17
    rat = 2;
    precision = 'uint16';
end
max_v = 2^nbits - 1;                            % Max value of the raw image
frame_size = height * width * rat;              % how many bytes does each frame contains

fid = fopen(dir_raw, 'rb');
fseek(fid, 0, 'eof');
frames = round( ftell(fid) / frame_size );   	% Specify how many frames
fseek(fid, 0, 'bof');

for i = 1:frames
    img_bayer = fread(fid, [height, width], precision);
%     figure;imshow(img_bayer, [0,max_v])     % show the bayer img
    
    %% simple ISP pipeline
    img_rgb = ISP(img_bayer, opt);
%     figure;imshow(uint8(img_rgb*255/max_v), [0,255])     % show the RGB img
    
    %% Save result
    % Write each frame as RGB file
    imwrite(uint8(img_rgb * 255 / max_v), ['./img_rec_' opt.demosaic_method '_' num2str(i, '%03d') '.jpg']);
end

fclose(fid);
