//
//  PSjfdt.cpp
//  ComputeDistance
//
//  Created by wzq on 10/8/16.
//  Copyright © 2016 effectmatrix. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

//X方向，y方向分别在最大半径内直接寻找，半径大时速度很慢
void vil_distance_transform_test(float *image, int width, int height, int* state)
{
    unsigned int *tempImage = (unsigned int *)malloc(width * height * sizeof(float));
    
    float fBaseValue = 200.0;
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            
            if(image[nOffset] > 0)
            {
                fBaseValue  = image[nOffset];
                tempImage[nOffset] = 0;
                continue;
            }
            
            tempImage[nOffset] = 200.0;
            //    int nNext = 1;
            for(int xx = 0; xx< 200; xx++)
            {
                int bFound = 0;
                for(int i=0; i<2; i++)
                {
                    int xoff = xx;
                    if(i==1) xoff = -xx;
                    if(x+xoff < 0) continue;
                    if(x+xoff >= width)  continue;
                    
                    
                    if(image[nOffset + xoff] > 0)
                    {
                        tempImage[nOffset] = xx;//x + xoff;
                        
                        bFound = 1;
                        break;
                    }
                    
                }
                if(bFound) break;
            }
        }
    
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            
            if(image[nOffset] > 0)
            {
                image[nOffset] = 0;
                continue;
            }
            /*      else
             {
             if(tempImage[nOffset] > 0)
             image[nOffset] = tempImage[nOffset];//(x - tempImage[nOffset] > 0) ? (x - tempImage[nOffset]):-(x - tempImage[nOffset]);
             else image[nOffset] = 0;
             continue;
             }
             */
            image[nOffset] = fBaseValue;
            for(int yy = 0; yy< 200; yy ++)
            {
                int bFound = 0;
                for(int i=0; i<2; i++)
                {
                    int yyy = yy;
                    if(i==1) yyy = -yy;
                    if(y+yyy < 0) continue;
                    if(y+yyy >= height)  continue;
                    
                    
                    if(tempImage[nOffset + yyy*width]<200)
                    {
                        
                        float fDistX = tempImage[nOffset + yyy*width];//x - tempImage[nOffset + yyy*width];
                        float fDist = sqrt(yyy*yyy + fDistX * fDistX);
                        
                        if(fDist < image[nOffset])
                            image[nOffset] = fDist;
                        //       bFound = 1;
                        //       break;
                        if(yy > image[nOffset])
                        {
                            bFound = 1;
                            break;
                        }
                    }
                }
                if(bFound) break;
            }
        }
    
    //   memcpy(image, tempImage, width*height*sizeof(float));
    free(tempImage);
}

// jump flooding 只有距离信息的变换，此种方法有很大误差
void vil_distance_transform_test2(float *image, int width, int height, int* state)
{
    float *image2 = (float *)malloc(width * height * sizeof(float));
    
    float *imageRead = image;
    float *imageWrite = image2;
    
    int nLevel = 100;
    
    
    do{
        for(int y=0; y< height; y++)
            for(int x = 0; x < width; x++)
            {
                int nOffset = y*width + x;
                
                if(imageRead[nOffset] > 1)
                {
                    float fDist = imageRead[nOffset];
                    if(x - nLevel >=0)
                    {
                        if(fDist > imageRead[nOffset - nLevel] + nLevel)
                            fDist = imageRead[nOffset - nLevel] + nLevel;
                    }
                    
                    if( x+nLevel < width)
                    {
                        if(fDist > imageRead[nOffset + nLevel] + nLevel)
                            fDist = imageRead[nOffset + nLevel] + nLevel;
                    }
                    
                    if( y - nLevel >= 0)
                    {
                        if(fDist > imageRead[nOffset - nLevel*width] + nLevel)
                            fDist = imageRead[nOffset - nLevel*width] + nLevel;
                    }
                    
                    if( y + nLevel < height)
                    {
                        if(fDist > imageRead[nOffset + nLevel*width] + nLevel)
                            fDist = imageRead[nOffset + nLevel*width] + nLevel;
                    }
                    
                    if(x - nLevel >=0 && y - nLevel >= 0)
                    {
                        if(fDist > imageRead[nOffset - nLevel -nLevel*width] + (float)nLevel*1.414)
                            fDist = imageRead[nOffset - nLevel-nLevel*width] + (float)nLevel*1.414;
                    }
                    
                    if( x+nLevel < width && y - nLevel >= 0)
                    {
                        if(fDist > imageRead[nOffset + nLevel-nLevel*width] + (float)nLevel*1.414)
                            fDist = imageRead[nOffset + nLevel-nLevel*width] + (float)nLevel*1.414;
                    }
                    
                    if(x - nLevel >=0 &&  y + nLevel < height)
                    {
                        if(fDist > imageRead[nOffset- nLevel  + nLevel*width] + (float)nLevel*1.414)
                            fDist = imageRead[nOffset - nLevel  + nLevel*width] + (float)nLevel*1.414;
                    }
                    
                    if(x+nLevel < width && y + nLevel < height)
                    {
                        if(fDist > imageRead[nOffset +nLevel + nLevel*width] + (float)nLevel*1.414)
                            fDist = imageRead[nOffset +nLevel + nLevel*width] + (float)nLevel*1.414;
                    }
                    
                    imageWrite[nOffset] = fDist;
                }
                else
                    imageWrite[nOffset] = imageRead[nOffset];
                
            }
        
        float *fTemp = imageRead;
        imageRead = imageWrite;
        imageWrite = fTemp;
        
        nLevel/=2;
    }while(nLevel != 0);
    
    if(image != imageRead)
    {
        memcpy(image, imageRead, width * height * sizeof(float));
    }
    
    free(image2);
}

typedef struct
{
    unsigned short int x;
    unsigned short int y;
}PIXEL_COORD;

inline float Distance2(PIXEL_COORD point1, PIXEL_COORD point2)
{
    if(point1.x == 65535 || point1.y == 65535 || point2.x == 65535 || point2.y == 65535)
        return 100000.0*100000.0;
    
    if(point1.x == point2.x && point1.y == point2.y)  return 0.0;
    
    return (((float)point1.x - (float)point2.x)*((float)point1.x - (float)point2.x)
            + ((float)point1.y - (float)point2.y)*((float)point1.y - (float)point2.y));
}

inline float Distance(PIXEL_COORD point1, PIXEL_COORD point2)
{
    if(point1.x == 65535 || point1.y == 65535 || point2.x == 65535 || point2.y == 65535)
        return 10000000.0;
    
    if(point1.x == point2.x && point1.y == point2.y)  return 0.0;
    
    return sqrtf(((float)point1.x - (float)point2.x)*((float)point1.x - (float)point2.x)
                 + ((float)point1.y - (float)point2.y)*((float)point1.y - (float)point2.y));
}

// jump flooding 记录坐标信息信息的距离变换，基本完美
void vil_distance_transform_test3(float *image, int width, int height, int* state)
{
    PIXEL_COORD *image1 = (PIXEL_COORD *)malloc(width * height * sizeof(PIXEL_COORD));
    PIXEL_COORD *image2 = (PIXEL_COORD *)malloc(width * height * sizeof(PIXEL_COORD));
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            
            if(image[nOffset] > 0)
            {
                image1[nOffset].x = 65535;
                image1[nOffset].y = 65535;
                
            }
            else
            {
                image1[nOffset].x = x;
                image1[nOffset].y = y;
            }
        }
    
    PIXEL_COORD *imageRead = image1;
    PIXEL_COORD *imageWrite = image2;
    
    int nLevel = 100;//width > height ? width/2: height/2;  //决定迭代次数
    //  int nTimes = 0;
    
    do{
        //     nTimes++;
        for(int y=0; y< height; y++)
            for(int x = 0; x < width; x++)
            {
                int nOffset = y*width + x;
                PIXEL_COORD pointCurrent;
                
                pointCurrent.x = x;
                pointCurrent.y = y;
                
                if(imageRead[nOffset].x != x || imageRead[nOffset].y != y)
                {
                    float fDist = Distance2(imageRead[nOffset], pointCurrent);
                    
                    //  if(nTimes %2 == 0)
                    {
                        if(x - nLevel >=0)
                        {
                            float fDist2 = Distance2(imageRead[nOffset - nLevel], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset - nLevel];
                                fDist = fDist2;
                            }
                        }
                        
                        if( x+nLevel < width)
                        {
                            float fDist2 = Distance2(imageRead[nOffset + nLevel], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset + nLevel];
                                fDist = fDist2;
                            }
                        }
                        
                        if( y - nLevel >= 0)
                        {
                            float fDist2 = Distance2(imageRead[nOffset - nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset - nLevel*width];
                                fDist = fDist2;
                            }
                        }
                        
                        if( y + nLevel < height)
                        {
                            float fDist2 = Distance2(imageRead[nOffset + nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset + nLevel*width];
                                fDist = fDist2;
                            }
                        }
                    }
                    //     else
                    {
                        
                        if(x - nLevel >=0 && y - nLevel >= 0)
                        {
                            float fDist2 = Distance2(imageRead[nOffset - nLevel -nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset - nLevel -nLevel*width];
                                fDist = fDist2;
                            }
                            
                        }
                        
                        if( x+nLevel < width && y - nLevel >= 0)
                        {
                            float fDist2 = Distance2(imageRead[nOffset + nLevel-nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset + nLevel-nLevel*width];
                                fDist = fDist2;
                            }
                        }
                        
                        if(x - nLevel >=0 &&  y + nLevel < height)
                        {
                            float fDist2 = Distance2(imageRead[nOffset- nLevel  + nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset- nLevel  + nLevel*width];
                                fDist = fDist2;
                            }
                            
                        }
                        
                        if(x+nLevel < width && y + nLevel < height)
                        {
                            float fDist2 = Distance2(imageRead[nOffset +nLevel + nLevel*width], pointCurrent);
                            if(fDist > fDist2)
                            {
                                imageWrite[nOffset] = imageRead[nOffset +nLevel + nLevel*width];
                                fDist = fDist2;
                            }
                        }
                    }
                    
                    if(fDist == Distance2(imageRead[nOffset], pointCurrent))
                        imageWrite[nOffset] = imageRead[nOffset];
                }
                else
                    imageWrite[nOffset] = imageRead[nOffset];
                
            }
        
        PIXEL_COORD *fTemp = imageRead;
        imageRead = imageWrite;
        imageWrite = fTemp;
        
        nLevel/=2;
    }while(nLevel != 0);
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            PIXEL_COORD pointCurrent;
            
            pointCurrent.x = x;
            pointCurrent.y = y;
            
            float fDist = Distance(imageRead[nOffset], pointCurrent);
            if(fDist > 60000.0)
                image[nOffset] = 200.0;
            else
                image[nOffset] = fDist;
            
        }
    
    free(image2);
    free(image1);
}

typedef struct
{
    float x;
    float y;
    float z;
    float w;
}PIXEL_INFO;

typedef struct
{
    float x;
    float y;
}PIXEL_VEC2;

PIXEL_VEC2 remap(PIXEL_VEC2 floatdata, float texLevels)
{
    PIXEL_VEC2 result;
    
    result.x = floatdata.x * (texLevels - 1.0) / texLevels * 2.0 - 1.0;
    result.y = floatdata.y * (texLevels - 1.0) / texLevels * 2.0 - 1.0;
    
    return result;
}

PIXEL_VEC2 remap_inv(PIXEL_VEC2 floatvec, float texLevels)
{
    PIXEL_VEC2 result;
    
    result.x = (floatvec.x + 1.0) * 0.5 * texLevels / (texLevels - 1.0);
    result.y = (floatvec.y + 1.0) * 0.5 * texLevels / (texLevels - 1.0);

    return result;
}

// TODO this isn't ideal, also will it work for most texture sizes?
PIXEL_INFO sampleTexture(PIXEL_INFO *texture, int nWidth, int nHeight, PIXEL_VEC2 vec)
{
    // The algorithm depends on the texture having a CLAMP_TO_BORDER attribute and a border color with R = 0.
    // These explicit conditionals to avoid propagating incorrect vectors when looking outside of [0,1] in UV cause a slowdown of about 25%.
    if(vec.x >= 1.0 || vec.y >= 1.0 || vec.x <= 0.0 || vec.y <= 0.0)
    {
        PIXEL_INFO info;
        
        memset(&info, 0, sizeof(info));
      //  vec = clamp(vec, 0.0, 1.0);
        return info; //vec3(0.0, 0.0, 0.0);
    }
    
    int nOffsetX = vec.x * nWidth;
    int nOffsetY = vec.y * nHeight;
    
    return texture[nOffsetY* nWidth + nOffsetX];
}

static float Length(PIXEL_VEC2 vec)
{
    return sqrtf(vec.x*vec.x + vec.y * vec.y);
}

void testCandidate(PIXEL_INFO *inputImageTexture, int nWidth, int nHeight, PIXEL_VEC2 stepvec, PIXEL_INFO &bestseed, PIXEL_VEC2 textureCoordinate, float texLevels)
{
    PIXEL_VEC2 newvec;
    
    newvec.x = textureCoordinate.x + stepvec.x;
    newvec.y = textureCoordinate.y + stepvec.y;
    
    PIXEL_INFO texel = sampleTexture(inputImageTexture, nWidth, nHeight, newvec);
    PIXEL_INFO newseed; // Closest point from that candidate (xy), its AA distance (z) and its grayscale value (w)
    
    PIXEL_VEC2 temp;
    
    temp.x = texel.x;  temp.y = texel.y;
    temp= remap(temp, texLevels);
    
    newseed.x = temp.x; newseed.y = temp.y;
    
    if(newseed.x > -0.99999) // If the new seed is not "indeterminate distance"
    {
        newseed.x = newseed.x + stepvec.x;
        newseed.y = newseed.y + stepvec.y;
        
        // TODO: implement better equations for calculating the AA distance
        // Try by getting the direction of the edge using the gradients of nearby edge pixels
        temp.x = newseed.x;  temp.y = newseed.y;
        float di = Length(temp);
        float df = texel.z - 0.5;
        
        // TODO: This AA assumes texw == texh. It does not allow for non-square textures.
        newseed.z = di + (df /(float) nWidth);
        newseed.w = texel.z;
        
        if(newseed.z < bestseed.z)
        {
            bestseed = newseed;
        }
    }
}

void vil_distance_transform_test4(float *image, int width, int height, int* state)
{
    float texLevels = 200.0;
    // Represents zero
    float myzero = 0.5 * texLevels / (texLevels - 1.0);
    
    // Represents infinity/not-yet-calculated
    float myinfinity = 0.0;
    
    
    PIXEL_INFO *image1 = (PIXEL_INFO *)malloc(width * height * sizeof(PIXEL_INFO));
    PIXEL_INFO *image2 = (PIXEL_INFO *)malloc(width * height * sizeof(PIXEL_INFO));
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            
            float texel = (image[nOffset])/200.0;
            // Sub-pixel AA distance
            float aadist = texel;
            
            if(texel > 0.99999)
            {
                image1[nOffset].x = myinfinity;
                image1[nOffset].y = myinfinity;
            }
            else
            {
                image1[nOffset].x = myzero;
                image1[nOffset].y = myzero;
            }
            
            image1[nOffset].z = aadist;
            image1[nOffset].w = 1.0;
        }
    
    PIXEL_INFO *imageRead = image1;
    PIXEL_INFO *imageWrite = image2;
    
    float step = (float)width/2.0;
    do{
        //     nTimes++;
        for(int y=0; y< height; y++)
            for(int x = 0; x < width; x++)
            {
                int nOffset = y*width + x;
                float stepu;
                float stepv;
                
                stepu = step / (float)width;
                stepv = stepu;//step / (float)height;
                
                PIXEL_VEC2 textureCoordinate;
                textureCoordinate.x =(float)x/(float)width;
                textureCoordinate.y =(float)y/(float)height;
                
                // Searches for better distance vectors among 8 candidates
                PIXEL_INFO texel = sampleTexture(image1, width, height, textureCoordinate);
                
                // Closest seed so far
                PIXEL_INFO bestseed;
                
                PIXEL_VEC2 temp;
                temp.x = texel.x; temp.y = texel.y;
                temp = remap(temp, texLevels);
                
                bestseed.x = temp.x;  bestseed.y = temp.y;
                bestseed.z = Length(temp) + (texel.z - 0.5) / (float)width; // Add AA edge offset to distance
                bestseed.w = texel.z; // Save AA/grayscale value
                
                temp.x = -stepu; temp.y = -stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = -stepu; temp.y = 0.0;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = -stepu; temp.y = stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = 0.0; temp.y = -stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = 0.0; temp.y = stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = stepu; temp.y = -stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = stepu; temp.y = 0.0;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = stepu; temp.y = stepv;
                testCandidate(image1, width, height, temp, bestseed, textureCoordinate,  texLevels);
                
                temp.x = bestseed.x; temp.y = bestseed.y;
                temp = remap_inv(temp, texLevels);
                
                image2[nOffset].x = temp.x;
                image2[nOffset].y = temp.y;
                image2[nOffset].z = bestseed.w;
                image2[nOffset].w = 1.0;
              //  gl_FragColor = vec4(remap_inv(bestseed.xy), bestseed.w, 1.0);
                
            }
        
        PIXEL_INFO *fTemp = imageRead;
        imageRead = imageWrite;
        imageWrite = fTemp;
        
        step/=2.0;
      //  nLevel/=2;
    }while(step >= 1.0);//nLevel != 0);
    
    for(int y=0; y< height; y++)
        for(int x = 0; x < width; x++)
        {
            int nOffset = y*width + x;
            
            PIXEL_INFO info = imageRead[nOffset];
            
            PIXEL_VEC2 temp;
            temp.x = info.x; temp.y = info.y;
            temp = remap(temp, texLevels);
            
            image[nOffset] = Length(temp) + (info.z - 0.5) / (float)width;
            image[nOffset] *= 200.0;
        }
    
    free(image2);
    free(image1);
}