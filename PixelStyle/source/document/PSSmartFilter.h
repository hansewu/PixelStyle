//
//  PSSmartFilter.h
//  SmartFilterDesign
//
//  Created by lchzh on 1/12/15.
//  Copyright © 2015 effectmatrix. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GPUImage/GPUImage.h>


typedef enum{
    V_INT = 0,
    V_FLOAT = 1,
    V_STRING = 2,
    V_DWORDCOLOR = 3,
    V_DWORDCOLORRGB = 4,
    V_MATRIX3x3 =5,
    V_MATRIX4x4 = 6,
    V_POINTER = 7,
    V_FILENAME = 8,
    V_CENTEROFFSET = 9,
    V_FLOAT_VECTOR3 = 10,
    V_FLOAT_VECTOR4 = 11,
    V_FLOAT_ARRAY = 12,
}ENUM_VARIABLE_TYPE;


#define FLOAT_ARRAY_SIZE 100

typedef union{
    int         nIntValue;
    float       fFloatValue;
    char        cString[512];
    unsigned int nUnsignedValue; //从后向前rgb
    float       fMatrix3x3[9];
    float       fMatrix4x4[16];
    void *		pValue;
    float       fOffsetXY[2];
    float       fFloatVector3[3];
    float 		fFloatVector4[4];
    float 		fFloatArray[FLOAT_ARRAY_SIZE];
}PARAMETER_VALUE;

#define CHAR_ARRAY_SIZE 256

typedef struct
{
    char        displayName[CHAR_ARRAY_SIZE];
    char        parameterName[CHAR_ARRAY_SIZE];
    ENUM_VARIABLE_TYPE parameterType;
    int  nValueEnable;//从低到高按bit位  有无  缺省值，最大值 最小值
    PARAMETER_VALUE  value;
    PARAMETER_VALUE  defaultValue;
    PARAMETER_VALUE  maxValue;
    PARAMETER_VALUE  minValue;
    int nScaleType; //0 无 1 scale同比例 10 无法预知
    int nNeedExtensionType; //0 无 1 size同比例 2 size2倍同比例 10 无法预知
    int nEffectExtensionType; //0 无 1 size同比例 2 size2倍同比例 10 无法预知
}FILTER_PARAMETER_INFO;


typedef struct
{
    char        filterName[CHAR_ARRAY_SIZE]; //唯一，代表类型
    char        filterCatagoryName[CHAR_ARRAY_SIZE];
    char        filterClassName[CHAR_ARRAY_SIZE];
    
    FILTER_PARAMETER_INFO *filterParameters; //没包含texture
    int parametersCount;
    GPUImageOutput<GPUImageInput> *gpuImageFilter;
    int textureCount;
    
}COMMON_FILTER_INFO;


//输入、输出数据也作为一个特殊的filter，方便filter级联
@interface GPUImageOutput (GPUImageFilterExtension)

//参数转化
- (void)setFilterParameter:(FILTER_PARAMETER_INFO*)paramters parameterCount:(int)count;
- (void)setFilterParameterValue:(PARAMETER_VALUE)paramterValue forParameter:(NSString*)paramterName parameterType:(ENUM_VARIABLE_TYPE)parameterType;
- (BOOL)getFilterIsValid;

@end




@interface PSSmartFilterRegister : NSObject
{
    COMMON_FILTER_INFO *m_allFiltersInfo;
    int m_filtersCount;
}

+(id)sharedSmartFilterRegister;
+(int)getFiltersCount;
+ (COMMON_FILTER_INFO) filterWithName:(NSString *) filterName;
+ (NSArray *) getAllFiltersCatagoryName;
+ (NSArray *) getAllFiltersName;
+ (NSArray *) getAllFiltersNameForCatagory:(NSString *)catagoryName;

@end

