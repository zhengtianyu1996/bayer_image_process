# bayer_image_process
A very simple ISP to convert bayer format image to RGB image

## how to run
1. Open Matlab
2. run 'img2raw.m' to generate a raw file (with many frames)
3. run 'main.m' to convert the raw file to many RGB images

### ISP.m
A very simple implementation of Image Signal Processing pipeline, which contains:
1. Black Level Correction
2. Gain
3. White Balance
4. Demosaic
5. Color Correction
6. Gamma

### demosaic_fn.m
A collection of demosaic methods. At the moment, only 'bilinear' is implemented. Would support more in the future :)

### readme.pptx
Refer to this document to learn more details of bilinear demosaicing.

### example files
1. img_bayer_640x512_GBRG_12bits.raw  -> raw file with only 1 frame, 'GBRG' format bayer image, height 640px, width 512px, precision uint16
2. img_gt_001.jpg   -> ground truth RGB image, where the raw file comes from
3. img_rec_bilinear_001.jpg  -> reconstructed RGB image, using bilinear demosaic method.

In a word, convert [1.] to [3.], compare [3.] with [2.]
