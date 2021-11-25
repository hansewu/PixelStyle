//
//  vxldt.cpp
//  test1
//
//  Created by lchzh on 8/9/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "PSvxldt.h"


//#include "omp.h"


void vil_distance_transform_one_way(float *image, int width, int height);
void vil_distance_transform_one_way_inverse(float *image, int width, int height);

void vil_distance_transform_r2_one_way(float *image, int width, int height, int*state);
void vil_distance_transform_r2_one_way_inverse(float *image, int width, int height, int*state);

void flipImage(float *image, int width, int height)
{
    for (int i = 0; i <  width/2 ; i++) {
        for (int j = 0; j < height ; j++) {
            float temp = image[i+j*width];
            image[i+j*width] = image[width-1-i + (height-1-j)*width];
            image[width-1-i + (height-1-j)*width] = temp;
        }
    }
    if (width%2==1) {
        int i = width/2;
        for (int j = 0; j < height/2 ; j++) {
            float temp = image[i+j*width];
            image[i+j*width] = image[width-1-i + (height-1-j)*width];
            image[width-1-i + (height-1-j)*width] = temp;
        }
    }

}


//void vil_computeDistance(unsigned char*srcData, int width, int height, int spp, float radius, float*distData)
//{
//    float *imageInfoForOut = (float*)malloc(width * height * sizeof(float));
//    float *imageInfoForIn = (float*)malloc(width * height * sizeof(float));
//    
//    #pragma omp parallel for
//    for (int i = 0; i < width; i++) {
//        for (int j = 0; j < height; j++) {
//            if (srcData[(j * width + i + 1) * spp - 1] > 0) {
//                imageInfoForOut[j * width + i] = 0.0;
//                imageInfoForIn[j * width + i] = radius;
//            }else{
//                imageInfoForOut[j * width + i] = radius;
//                imageInfoForIn[j * width + i] = 0.0;
//            }
//        }
//    }
//    
//
//    #pragma omp parallel for
//    for (int i = 0; i < 2; i++) {
//        if (i == 0) {
//            vil_distance_transform(imageInfoForOut, width, height);
//        }else{
//            vil_distance_transform(imageInfoForIn, width, height);
//        }
//        printf("vil_distance_transform");
//    }
//    
////    vil_distance_transform(imageInfoForOut, width, height);
////    vil_distance_transform(imageInfoForIn, width, height);
//    
//    #pragma omp parallel for
//    for (int i = 0; i < width; i++) {
//        for (int j = 0; j < height; j++) {
//            if (srcData[(j * width + i + 1) * spp - 1] > 0) {
//                distData[j * width + i] = -imageInfoForIn[j * width + i];
//            }else{
//                distData[j * width + i] = imageInfoForOut[j * width + i];
//            }
//        }
//    }
//    free(imageInfoForOut);
//    free(imageInfoForIn);
//}


void vil_computeDistance(unsigned char*srcData, int width, int height, int spp, float radius, float*distData)
{
    float *imageInfoForOut = (float*)malloc(width * height * sizeof(float));
    float *imageInfoForIn = (float*)malloc(width * height * sizeof(float));
    
    
    for (int i = 0; i < width; i++)
    {
        for (int j = 0; j < height; j++)
        {
            if (srcData[(j * width + i + 1) * spp - 1] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    
    vil_distance_transform(imageInfoForOut, width, height, NULL);
    vil_distance_transform(imageInfoForIn, width, height, NULL);
    
    for (int i = 0; i < width; i++)
    {
        for (int j = 0; j < height; j++)
        {
            if (srcData[(j * width + i + 1) * spp - 1] > 0)
            {
                distData[j * width + i] = -imageInfoForIn[j * width + i];
            }
            else
            {
                distData[j * width + i] = imageInfoForOut[j * width + i];
            }
        }
    }
    
    free(imageInfoForOut);
    free(imageInfoForIn);
}


void vil_computeDistanceFast(unsigned char*srcData, float *srcDist, int originx, int originy, int width, int height, int srcWidth, int srcHeight, int spp, float radius, float*distData, int extendInfo, int* effectState)
{
    float *imageInfoForOut = (float*)malloc(width * height * sizeof(float));
    float *imageInfoForIn = (float*)malloc(width * height * sizeof(float));
    
    //first row  j==0
    if (extendInfo & 8)
    {
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = ((originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
                imageInfoForIn[i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[i] = radius;
                imageInfoForIn[i] = 0.0;
            }
            
        }
        
    }else{
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = ((originy) * srcWidth + originx + i + 1) * spp - 1;
            int srcDistLoc = ((originy) * srcWidth + originx + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
                imageInfoForIn[i] = -srcDist[srcDistLoc];
            }
            else
            {
                imageInfoForOut[i] = srcDist[srcDistLoc];
                imageInfoForIn[i] = 0.0;
            }
        }
    }
    
    //last row
    if (extendInfo & 4)
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
        
    }
    else
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            int srcDistLoc = ((j + originy) * srcWidth + originx + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = -srcDist[srcDistLoc];
            }
            else
            {
                imageInfoForOut[j * width + i] = srcDist[srcDistLoc];
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //first column i==0
    if (extendInfo & 2)
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    else
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            int srcDistLoc = ((j + originy) * srcWidth + originx + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = -srcDist[srcDistLoc];
            }
            else
            {
                imageInfoForOut[j * width + i] = srcDist[srcDistLoc];
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //last column
    if (extendInfo & 1)
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }else{
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            int srcDistLoc = ((j + originy) * srcWidth + originx + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = -srcDist[srcDistLoc];
            }
            else
            {
                imageInfoForOut[j * width + i] = srcDist[srcDistLoc];
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    

    
    for (int i = 1; i < width - 1; i++)
    {
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    if (effectState && *effectState == 0)
    {
        free(imageInfoForOut);
        free(imageInfoForIn);
        return;
    }
    
    vil_distance_transform(imageInfoForOut, width, height, effectState);
    
    if (effectState && *effectState == 0)
    {
        free(imageInfoForOut);
        free(imageInfoForIn);
        return;
    }
    
    vil_distance_transform(imageInfoForIn, width, height, effectState);
    
    for (int i = 0; i < width; i++)
    {
        for (int j = 0; j < height; j++)
        {
            int srcLoc = ((j + originy) * srcWidth + originx + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                distData[j * width + i] = -imageInfoForIn[j * width + i];
            }
            else
            {
                distData[j * width + i] = imageInfoForOut[j * width + i];
            }
        }
        if (effectState && *effectState == 0)
        {
            free(imageInfoForOut);
            free(imageInfoForIn);
            return;
        }
    }
    
    free(imageInfoForOut);
    free(imageInfoForIn);
}

void vil_computeDistanceSimple_in(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState)
{
    float *imageInfoForIn = distData;//(float*)malloc(width * height * sizeof(float));
    
    //first row  j==0
    if (extendInfo & 8)
    {
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[i] = 0.0; //radius;
            }
            else
            {
                imageInfoForIn[i] = 0.0;
            }
            
        }
        
    }else{
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            int srcDistLoc = (i + 1) * 1 - 1;
            
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[i] = radius;
            }
            else
            {
                imageInfoForIn[i] = 0.0;
            }
        }
    }
    
    //last row
    if (extendInfo & 4)
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
        
    }else
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //first column i==0
    if (extendInfo & 2)
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    else
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //last column
    if (extendInfo & 1)
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    else
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    
    
    for (int j = 1; j < height - 1; j++)
    {
        for (int i = 1; i < width - 1; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    if (effectState && *effectState == 0)
    {
        return;
    }
    
    //   vil_distance_transform_test4(imageInfoForIn, width, height, effectState);
    vil_distance_transform(imageInfoForIn, width, height, effectState);
    
}


void vil_computeDistanceSimple_out(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState)
{
    float *imageInfoForOut = distData;//(float*)malloc(width * height * sizeof(float));
    
    //first row  j==0
    if (extendInfo & 8)
    {
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
            }
            else
            {
                imageInfoForOut[i] = radius;
            }
            
        }
        
    }else{
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            int srcDistLoc = (i + 1) * 1 - 1;
            
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
            }
            else
            {
                imageInfoForOut[i] = radius;
            }
        }
    }
    
    //last row
    if (extendInfo & 4)
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
        
    }else
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    
    //first column i==0
    if (extendInfo & 2)
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    else
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    
    //last column
    if (extendInfo & 1)
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    else
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    
    
    
    for (int j = 1; j < height - 1; j++)
    {
        for (int i = 1; i < width - 1; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
            }
        }
    }
    
    if (effectState && *effectState == 0)
    {
        return;
    }
    
    //   vil_distance_transform_test4(imageInfoForOut, width, height, effectState);
    vil_distance_transform(imageInfoForOut, width, height, effectState);

}


//simple
void vil_computeDistanceSimple(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState)
{
    float *imageInfoForOut = (float*)malloc(width * height * sizeof(float));
    float *imageInfoForIn = (float*)malloc(width * height * sizeof(float));
    
    //first row  j==0
    if (extendInfo & 8)
    {
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
                imageInfoForIn[i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[i] = radius;
                imageInfoForIn[i] = 0.0;
            }
            
        }
        
    }else{
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (i + 1) * spp - 1;
            int srcDistLoc = (i + 1) * 1 - 1;
            
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[i] = 0.0;
                imageInfoForIn[i] = radius;
            }
            else
            {
                imageInfoForOut[i] = radius;
                imageInfoForIn[i] = 0.0;
            }
        }
    }
    
    //last row
    if (extendInfo & 4)
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
        
    }else
    {
        int j = height - 1;
        for (int i = 0 ; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //first column i==0
    if (extendInfo & 2)
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    else
    {
        int i = 0;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    //last column
    if (extendInfo & 1)
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = 0.0; //radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    else
    {
        int i = width - 1;
        for (int j = 1; j < height - 1; j++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            int srcDistLoc = (j * width + i + 1) * 1 - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    
    
    for (int j = 1; j < height - 1; j++)
    {
        for (int i = 1; i < width - 1; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                imageInfoForOut[j * width + i] = 0.0;
                imageInfoForIn[j * width + i] = radius;
            }
            else
            {
                imageInfoForOut[j * width + i] = radius;
                imageInfoForIn[j * width + i] = 0.0;
            }
        }
    }
    
    if (effectState && *effectState == 0)
    {
        free(imageInfoForOut);
        free(imageInfoForIn);
        return;
    }
    
 //   vil_distance_transform_test4(imageInfoForOut, width, height, effectState);
    vil_distance_transform(imageInfoForOut, width, height, effectState);
    
    if (effectState && *effectState == 0)
    {
        free(imageInfoForOut);
        free(imageInfoForIn);
        return;
    }
    
 //   vil_distance_transform_test4(imageInfoForIn, width, height, effectState);
    vil_distance_transform(imageInfoForIn, width, height, effectState);
    
    for (int j = 0; j < height; j++)
    {
        for (int i = 0; i < width; i++)
        {
            int srcLoc = (j * width + i + 1) * spp - 1;
            if (srcData[srcLoc] > 0)
            {
                distData[j * width + i] = -imageInfoForIn[j * width + i]; //imageInfoForOut[j * width + i];//vil_distance_transform_test1
            }
            else
            {
                distData[j * width + i] = imageInfoForOut[j * width + i]; //imageInfoForIn[j * width + i]; //
            }
        }
        
        if (effectState && *effectState == 0)
        {
            free(imageInfoForOut);
            free(imageInfoForIn);
            return;
        }
    }
    
    free(imageInfoForOut);
    free(imageInfoForIn);
}



void vil_distance_transform(float *image, int width, int height, int* state)
{
    // Low to high pass
    vil_distance_transform_r2_one_way(image, width, height, state);
    
    vil_distance_transform_r2_one_way_inverse(image, width, height, state);
    
//    vil_distance_transform_one_way(image, width, height);
//    vil_distance_transform_one_way_inverse(image, width, height);
    
}

inline float vcl_min(float a, float b)
{
    return a < b ? a : b;
}

//: Compute directed distance function from zeros in original image
//  Image is assumed to be filled with max_dist where there
//  is background, and zero at the places of interest.
//  On exit, the values are the 8-connected distance to the
//  nearest original zero region above or to the left of current point.
//  One pass of distance transform, going from low to high i,j.
void vil_distance_transform_one_way(float *image, int width, int height)
{
    //assert(image.nplanes()==1);
    unsigned ni = width; //image.ni();
    unsigned nj = height; //image.nj();
    unsigned ni1 = ni-1;
    int istep = 1,  jstep = width ;
    int o1 = -istep, o2 = -jstep-istep, o3 = -jstep, o4 = istep-jstep;
    //float* row0 = image.top_left_ptr();
    float* row0 = image ; //image.top_left_ptr();
    
    const float sqrt2 = 1.4142135f;
    
    // Process the first row
    float* p0 = row0+istep;
    for (unsigned i=1;i<ni;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[-istep]+1.0f,*p0);
    }
    
    row0 += jstep;  // Move to next row
    
    // Process each subsequent row from low to high values of j
    for (unsigned j=1;j<nj;++j,row0+=jstep)
    {
        // Check first element against first two in previous row
        *row0 = vcl_min(row0[o3]+1.0f,*row0);
        *row0 = vcl_min(row0[o4]+sqrt2,*row0);

        float* p0 = row0+istep;
        for (unsigned i=1;i<ni1;++i,p0+=istep)
        {
            *p0 = vcl_min(p0[o1]+1.0f ,*p0); // (-1,0)
            *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
            *p0 = vcl_min(p0[o3]+1.0f ,*p0); // (0,-1)
            *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
            
        }
        
        // Check last element in row
        *p0 = vcl_min(p0[o1]+1.0f ,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f ,*p0); // (0,-1)
    }
}

void vil_distance_transform_one_way_inverse(float *image, int width, int height)
{
    //assert(image.nplanes()==1);
    unsigned ni = width; //image.ni();
    unsigned nj = height; //image.nj();
    unsigned ni1 = ni-1;
    int istep = -1,  jstep = -width ;
    int o1 = -istep, o2 = -jstep-istep, o3 = -jstep, o4 = istep-jstep;
    //float* row0 = image.top_left_ptr();
    float* row0 = &image[width * height - 1]; //image.top_left_ptr();
    
    const float sqrt2 = 1.4142135f;
    
    // Process the first row
    float* p0 = row0+istep;
    for (unsigned i=1;i<ni;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[-istep]+1.0f,*p0);
    }
    
    row0 += jstep;  // Move to next row
    
    // Process each subsequent row from low to high values of j
    for (unsigned j=1;j<nj;++j,row0+=jstep)
    {
        // Check first element against first two in previous row
        *row0 = vcl_min(row0[o3]+1.0f,*row0);
        *row0 = vcl_min(row0[o4]+sqrt2,*row0);
        
        float* p0 = row0+istep;
        for (unsigned i=1;i<ni1;++i,p0+=istep)
        {
            *p0 = vcl_min(p0[o1]+1.0f ,*p0); // (-1,0)
            *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
            *p0 = vcl_min(p0[o3]+1.0f ,*p0); // (0,-1)
            *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
            
        }
        
        // Check last element in row
        *p0 = vcl_min(p0[o1]+1.0f ,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f ,*p0); // (0,-1)
    }
}






//: Distance function, using neighbours +/-2 in x,y
//  More accurate thand vil_distance_function_one_way
void vil_distance_transform_r2_one_way(float *image, int width, int height, int*state)
{
    
    unsigned ni = width;
    unsigned nj = height;
    unsigned ni2 = ni-2;
    int istep = 1,  jstep = width;
    
    //   Kernel defining points to consider (relative to XX)
    //   -- o6 -- o7 --
    //   o5 o2 o3 o4 o8
    //   -- o1 XX -- --
    int o1 = -istep, o2 = -jstep-istep;
    int o3 = -jstep, o4 = istep-jstep;
    int o5 = -2*istep-jstep;
    int o6 = -istep-2*jstep;
    int o7 =  istep-2*jstep;
    int o8 =  2*istep-jstep;
    
    float* row0 = image;
    
    const float sqrt2 = 1.4142135f;
    const float sqrt5 = 2.236068f;
    
    // Process the first row
    float* p0 = row0+istep;
    for (unsigned i=1;i<ni;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[-istep]+1.0f,*p0);
    }
    
    row0 += jstep;  // Move to next row
    
    // ==== Process second row ====
    // Check first element against elements in previous row
    *row0 = vcl_min(row0[o3]+1.0f,*row0);  // (0,-1)
    *row0 = vcl_min(row0[o4]+sqrt5,*row0); // (1,-1)
    *row0 = vcl_min(row0[o8]+sqrt5,*row0); // (2,-1)
    
    p0 = row0+istep;  // Move to element 1
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
    *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
    
    p0+=istep;  // Move to element 2
    for (unsigned i=2;i<ni2;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
    }
    
    // Check element ni-2
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
    *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
    
    p0+=istep;  // Move to element ni-1
    // Check last element in row
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
    
    row0 += jstep;  // Move to next row (2)
    
    // Process each subsequent row from low to high values of j
    for (unsigned j=2;j<nj;++j,row0+=jstep)
    {
        if (state && *state == 0) {
            return;
        }
        
        // Check first element
        *row0 = vcl_min(row0[o3]+1.0f,*row0);  // (0,-1)
        *row0 = vcl_min(row0[o4]+sqrt2,*row0); // (1,-1)
        *row0 = vcl_min(row0[o7]+sqrt5,*row0); // (1,-2)
        *row0 = vcl_min(row0[o8]+sqrt5,*row0); // (2,-1)
        
        float* p0 = row0+istep;  // Element 1
        // Check second element, allowing for boundary conditions
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
        *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
        *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
        
        p0+=istep;  // Move to next element (2)
        for (unsigned i=2;i<ni2;++i,p0+=istep)
        {
            *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
            *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
            *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
            *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
            *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
            *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
            *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
            *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
        }
        // p0 points to element (ni-2,y)
        
        // Check last but one element in row
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
        *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
        
        p0+=istep; // Move to last element (ni-1,y)
        // Process last element in row
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
    }
}

void vil_distance_transform_r2_one_way_inverse(float *image, int width, int height, int*state)
{
    
    unsigned ni = width;
    unsigned nj = height;
    unsigned ni2 = ni-2;
    int istep = -1,  jstep = -width;
    
    //   Kernel defining points to consider (relative to XX)
    //   -- o6 -- o7 --
    //   o5 o2 o3 o4 o8
    //   -- o1 XX -- --
    int o1 = -istep, o2 = -jstep-istep;
    int o3 = -jstep, o4 = istep-jstep;
    int o5 = -2*istep-jstep;
    int o6 = -istep-2*jstep;
    int o7 =  istep-2*jstep;
    int o8 =  2*istep-jstep;
    
    float* row0 = &image[width * height - 1];
    
    const float sqrt2 = 1.4142135f;
    const float sqrt5 = 2.236068f;
    
    // Process the first row
    float* p0 = row0+istep;
    for (unsigned i=1;i<ni;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[-istep]+1.0f,*p0);
    }
    
    row0 += jstep;  // Move to next row
    
    // ==== Process second row ====
    // Check first element against elements in previous row
    *row0 = vcl_min(row0[o3]+1.0f,*row0);  // (0,-1)
    *row0 = vcl_min(row0[o4]+sqrt5,*row0); // (1,-1)
    *row0 = vcl_min(row0[o8]+sqrt5,*row0); // (2,-1)
    
    p0 = row0+istep;  // Move to element 1
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
    *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
    
    p0+=istep;  // Move to element 2
    for (unsigned i=2;i<ni2;++i,p0+=istep)
    {
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
    }
    
    // Check element ni-2
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
    *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
    
    p0+=istep;  // Move to element ni-1
    // Check last element in row
    *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
    *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
    *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
    *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
    
    row0 += jstep;  // Move to next row (2)
    
    // Process each subsequent row from low to high values of j
    for (unsigned j=2;j<nj;++j,row0+=jstep)
    {
        if (state && *state == 0) {
            return;
        }
        
        // Check first element
        *row0 = vcl_min(row0[o3]+1.0f,*row0);  // (0,-1)
        *row0 = vcl_min(row0[o4]+sqrt2,*row0); // (1,-1)
        *row0 = vcl_min(row0[o7]+sqrt5,*row0); // (1,-2)
        *row0 = vcl_min(row0[o8]+sqrt5,*row0); // (2,-1)
        
        float* p0 = row0+istep;  // Element 1
        // Check second element, allowing for boundary conditions
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
        *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
        *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
        
        p0+=istep;  // Move to next element (2)
        for (unsigned i=2;i<ni2;++i,p0+=istep)
        {
            *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
            *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
            *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
            *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
            *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
            *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
            *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
            *p0 = vcl_min(p0[o8]+sqrt5,*p0); // (2,-1)
        }
        // p0 points to element (ni-2,y)
        
        // Check last but one element in row
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o4]+sqrt2,*p0); // (1,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
        *p0 = vcl_min(p0[o7]+sqrt5,*p0); // (1,-2)
        
        p0+=istep; // Move to last element (ni-1,y)
        // Process last element in row
        *p0 = vcl_min(p0[o1]+1.0f,*p0); // (-1,0)
        *p0 = vcl_min(p0[o2]+sqrt2,*p0); // (-1,-1)
        *p0 = vcl_min(p0[o3]+1.0f,*p0); // (0,-1)
        *p0 = vcl_min(p0[o5]+sqrt5,*p0); // (-2,-1)
        *p0 = vcl_min(p0[o6]+sqrt5,*p0); // (-1,-2)
    }
}


