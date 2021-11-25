//
//  AImageFilter.h
//  MyBrushesPlugin_mac
//
//  Created by wu zhiqiang on 2/5/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#ifndef __MyBrushesPlugin_mac__AImageFilter__
#define __MyBrushesPlugin_mac__AImageFilter__

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef enum{
    AV_INT = 0,
    AV_FLOAT = 1,
    AV_STRING = 2,
    AV_DWORDCOLOR = 3,
    AV_DWORDCOLORRGB = 4,
    AV_MATRIX3x3 =5,
    AV_MATRIX4x4 = 6,
    AV_POINTER = 7,
    AV_FILENAME = 8,
    AV_CENTEROFFSET = 9,
}AENUM_VARIABLE_TYPE;


typedef union{
    int         nIntValue;
    float       fFloatValue;
    char        cString[512];
    unsigned int nUnsignedValue;
//    float       fArray[10];
    float       fMatrix3x3[9];
    float       fMatrix4x4[16];
    void *		pValue;
    float       fOffsetXY[2];
}AVARIABLE_VALUE;

typedef struct
{
    char       cName[100];
    char       cInterName[100];
    AENUM_VARIABLE_TYPE  nType;
    AVARIABLE_VALUE      Value;
    int                 nValueEnable;//从低到高按bit位  有无  缺省值，最大值 最小值
    AVARIABLE_VALUE      DefaultValue;
    AVARIABLE_VALUE      MaxValue;
    AVARIABLE_VALUE      MinValue;
    
    //是否有归一化值，没有为0，有为1；
    int                  nValueNormalizationEnable;
    //参数范围是否涉及到图像的大小，不涉及0，涉及为1, 如果为3则表示参数大小大图小图如果要有相同效果则要等比例扩大或者缩放
    int mod;
}AUNI_VARIABLE;

int GetFiltersCount();
NSString *GetFilterName(int nFilterIndex);
int	 GetFilterParaCount(int nFilterIndex);
NSString *GetFilterParamName(int nFilterIndex, int nItem);
AVARIABLE_VALUE GetFilterParamMax(int nFilterIndex, int nItem);
AVARIABLE_VALUE GetFilterParamMin(int nFilterIndex, int nItem);
AVARIABLE_VALUE GetFilterParamDefault(int nFilterIndex, int nItem);
AENUM_VARIABLE_TYPE GetFilterParamType(int nFilterIndex, int nItem);



int GetCategoriesCount();
int GetFiltersCountInCategory(int nCategoryIndex);
NSString* GetCategoryNameInCategory(int nCategoryIndex);


NSString* GetFilterNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex);
int GetFilterParaCountInCategory(int nCategoryIndex, int nFilterInCatetoryIndex);
NSString * GetFilterParamNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex, int nItem);
NSString *GetFilterParamInNameInCategory(int nCategoryIndex,int nFilterInCatetoryIndex, int nItem);
AENUM_VARIABLE_TYPE GetFilterParamTypeInCategory(int nCategoryIndex,  int nFilterInCategoryIndex, int nItem);
AVARIABLE_VALUE GetFilterParamMaxInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem);
AVARIABLE_VALUE GetFilterParamMinInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem);
AVARIABLE_VALUE GetFilterParamDefaultInCategory(int nCategoryIndex,int nFilterInCatetoryIndex,int nItem);

typedef struct
{
    CIImage *image;
    CIFilter *filter;
    int nFilterIndex;
}IMAGE_FILTER;

typedef void * IMAGE_FILTER_HANDLE;

IMAGE_FILTER_HANDLE CreateFilterForImage(CIImage *image, int nFilterIndex);
IMAGE_FILTER_HANDLE CreateFilterForImageInCategory(CIImage *image, int nCategoryIndex,int nFilterIndex);


void DestroyImageFilter(IMAGE_FILTER_HANDLE hImageFilter);
void ModifyImageFilterParm(IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue);
void ModifyImageFilterParmWithWidthAndHeight(IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue,float fWidth, float fHeight);
AUNI_VARIABLE GetImageFilterParm(IMAGE_FILTER_HANDLE hImageFilter, int nItem);

//IMAGE_FILTER_HANDLE CreateFilterForCALayerInCategory(int nCategoryIndex,int nFilterIndex);
void ModifyFilterParamInLayer(CALayer* layer, IMAGE_FILTER_HANDLE hImageFilter, int nItem, AVARIABLE_VALUE aValue);

CIImage *GetOutImage(IMAGE_FILTER_HANDLE hImageFilter);
void RenderCIImage(CGContextRef contextCG, CIImage *pCIImage, CGRect rectTo, CGRect rectFrom );

#endif /* defined(__MyBrushesPlugin_mac__AImageFilter__) */
