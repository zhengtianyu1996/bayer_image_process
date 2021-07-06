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
