//
//  vxldt.h
//  test1
//
//  Created by lchzh on 8/9/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#ifndef __test1__vxldt__
#define __test1__vxldt__

#include <stdio.h>
#include <stdlib.h>

void vil_computeDistance(unsigned char*srcData, int width, int height, int spp, float radius, float*distData);

void vil_computeDistanceFast(unsigned char*srcData, float *srcDist, int originx, int originy, int width, int height, int srcWidth, int srcHeight, int spp, float radius, float*distData, int extendInfo, int*effectState);

void vil_computeDistanceSimple(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState);

void vil_distance_transform(float *image, int width, int height, int* state);

void vil_computeDistanceSimple_in(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState);
void vil_computeDistanceSimple_out(unsigned char*srcData, int width, int height, int spp, float radius, float*distData, int extendInfo, int* effectState);

void vil_distance_transform_test(float *image, int width, int height, int* state);
void vil_distance_transform_test2(float *image, int width, int height, int* state);
void vil_distance_transform_test3(float *image, int width, int height, int* state);
void vil_distance_transform_test4(float *image, int width, int height, int* state);

#endif /* defined(__test1__vxldt__) */
