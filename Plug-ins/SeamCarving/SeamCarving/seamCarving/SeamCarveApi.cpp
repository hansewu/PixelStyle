//
//  SeamCarveApi.m
//
//  Created by wyl on 8/11/16.
//  Copyright © 2016 effectmatrix. All rights reserved.
//

#include "SeamCarveApi.h"
#include "SeamCarver.h"

int seamcarveImage(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData)
{
    assert(pInputData && pOutputData);
    
    int nInputWidth = pInputData->nWidth;
    int nInputHeight = pInputData->nHeight;
    
    int nOutputWidth = pOutputData->nWidth;
    int nOutputHeight = pOutputData->nHeight;
    
    assert(nInputWidth && nInputHeight && nOutputWidth && nOutputHeight);
    
    int nChannels = pInputData->nChannels;
    
    Mat_<Vec3b> image;
    if(nChannels == 3)
    {
        image = Mat(nInputHeight, nInputWidth, CV_8UC3, pInputData->pData);
    }
    else if(nChannels == 4)
    {
        Mat inputImage = Mat(nInputHeight, nInputWidth, CV_8UC4, pInputData->pData);
        image = Mat_<Vec3b>(nInputHeight,nInputWidth);
        cvtColor(inputImage, image, CV_RGBA2RGB);
    }
    else
    {
        cout << "Invalid input, seamcarveImage only support 4 /3 channels";
        return -1;
    }
    
    if (!image.data)
    {
        cout << "Invalid input";
        return -1;
    }
    
    SeamCarver s(image);
    
    
    for (int i = 0; i < nInputHeight - nOutputHeight; ++i)
    {
        vector<unsigned int> seam = s.findHorizontalSeam();
        s.removeHorizontalSeam(seam);
    }
    for (int i = 0; i < nInputWidth - nInputHeight; ++i)
    {
        vector<unsigned int> seam = s.findVerticalSeam();
        
        s.removeVerticalSeam(seam);
    }
    
    
    if(nChannels == 3)
    {
        memcpy(pOutputData->pData, s.getImage().data, nOutputWidth * nOutputHeight*3);
    }
    else if(nChannels == 4)
    {
        Mat outputImage;
        outputImage.create(nInputHeight,nInputWidth,CV_8UC4);
        cvtColor(s.getImage(), outputImage, CV_RGB2RGBA);
        
        memcpy(pOutputData->pData, outputImage.data, nOutputWidth * nOutputHeight*4);
        
        outputImage.release();
    }
    
    return 0;
}