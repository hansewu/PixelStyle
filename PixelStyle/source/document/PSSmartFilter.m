//
//  PSSmartFilter.m
//  SmartFilterDesign
//
//  Created by lchzh on 1/12/15.
//  Copyright © 2015 lchzh. All rights reserved.
//

#import "PSSmartFilter.h"



@implementation GPUImageOutput (GPUImageFilterExtension)


- (void)setFilterParameter:(FILTER_PARAMETER_INFO*)paramters parameterCount:(int)count
{
    for (int i = 0; i < count; i++)
    {
        FILTER_PARAMETER_INFO paraInfo = paramters[i];
        NSString *key = [NSString stringWithCString:paraInfo.parameterName encoding:NSASCIIStringEncoding];
        id value = nil;
        switch (paraInfo.parameterType) {
            case V_INT:
                value = [NSNumber numberWithInt:paraInfo.value.nIntValue];
                break;
                
            case V_FLOAT:
                value = [NSNumber numberWithFloat:paraInfo.value.fFloatValue];
                break;
                
            case V_DWORDCOLORRGB:{
                //( r| (g<<8) | (b<<16) )
                unsigned int nUnsignedValue = paraInfo.value.nUnsignedValue;
                int red = nUnsignedValue & 0xFF;
                int green = (nUnsignedValue >> 8) & 0xFF;
                int blue = (nUnsignedValue >> 16) & 0xFF;
                GPUVector3 color = {red / 255.0, green / 255.0, blue / 255.0};
                value = [NSValue valueWithBytes:&color objCType:@encode(GPUVector3)];
            }
                break;
                
            case V_DWORDCOLOR:{
                unsigned int nUnsignedValue = paraInfo.value.nUnsignedValue;
                int red = nUnsignedValue & 0xFF;
                int green = (nUnsignedValue >> 8) & 0xFF;
                int blue = (nUnsignedValue >> 16) & 0xFF;
                int alpha = (nUnsignedValue >> 24) & 0xFF;
                GPUVector4 color = {red / 255.0, green / 255.0, blue / 255.0, alpha / 255.0};
                value = [NSValue valueWithBytes:&color objCType:@encode(GPUVector4)];
            }
                break;
                
            case V_CENTEROFFSET:{
                float offsetx = paraInfo.value.fOffsetXY[0];
                float offsety = paraInfo.value.fOffsetXY[1];
                
                CGPoint offset = {offsetx, offsety};
                value = [NSValue valueWithBytes:&offset objCType:@encode(CGPoint)];
            }
                break;
                
            case V_FLOAT_VECTOR4:{
                float* fv = paraInfo.value.fFloatVector4;
                GPUVector4 vec4 ={fv[0], fv[1], fv[2], fv[3]};
                value = [NSValue valueWithBytes:&vec4 objCType:@encode(GPUVector4)];
                //value = [NSData dataWithBytes:paraInfo.value.fFloatVector4 length:4 * sizeof(float)];
            }
                break;
                
            case V_FLOAT_ARRAY:{
                //value = [NSValue valueWithBytes:paraInfo.value.fFloatVector4 objCType:@encode(GPUVector4)];
                //value = [NSData dataWithBytes:paraInfo.value.fFloatArray length:200 * sizeof(float)];
                GPUVectorLong vecLong;
                memcpy(vecLong.array, paraInfo.value.fFloatArray, 100 * sizeof(float));
                value = [NSValue valueWithBytes:&vecLong objCType:@encode(GPUVectorLong)];
                //value = [NSNumber numberwith];
                
            }
                break;
                
            default:
                break;
        }
        assert(value);
        
        [self setValue:value forKey:key];
    }
}

- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key
{
    //process NSUndefinedKeyException
    //NSLog(@"%@",key);
}



- (BOOL)getFilterIsValid
{
    return YES;
}

@end


@implementation PSSmartFilterRegister

static PSSmartFilterRegister *sharedDefaultRegister = nil;


void makeFilterParameterInfoForFloat(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, int  nValueEnable, float  defaultValue, float  maxValue, float  minValue, int nScaleType, int nNeedExtensionType, int nEffectExtensionType, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_FLOAT;
    parameterInfo->nValueEnable = nValueEnable;
    parameterInfo->nScaleType = nScaleType;
    parameterInfo->nNeedExtensionType = nNeedExtensionType;
    parameterInfo->nEffectExtensionType = nEffectExtensionType;
    
    parameterInfo->defaultValue.fFloatValue = defaultValue;
    parameterInfo->value.fFloatValue = defaultValue;
    parameterInfo->maxValue.fFloatValue = maxValue;
    parameterInfo->minValue.fFloatValue = minValue;
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
}

void makeFilterParameterInfoForInt(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, int  nValueEnable, int  defaultValue, int  maxValue, int  minValue, int nScaleType, int nNeedExtensionType, int nEffectExtensionType, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_INT;
    parameterInfo->nValueEnable = nValueEnable;
    parameterInfo->nScaleType = nScaleType;
    parameterInfo->nNeedExtensionType = nNeedExtensionType;
    parameterInfo->nEffectExtensionType = nEffectExtensionType;
    
    parameterInfo->defaultValue.nIntValue = defaultValue;
    parameterInfo->value.nIntValue = defaultValue;
    parameterInfo->maxValue.nIntValue = maxValue;
    parameterInfo->minValue.nIntValue = minValue;
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
}

//暂时为颜色值
void makeFilterParameterInfoForRGB(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, unsigned int value, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_DWORDCOLORRGB;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    parameterInfo->defaultValue.nUnsignedValue = value;
    parameterInfo->value.nUnsignedValue = value;
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
}

void makeFilterParameterInfoForRGBA(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, unsigned int value, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_DWORDCOLOR;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    parameterInfo->defaultValue.nUnsignedValue = value;
    parameterInfo->value.nUnsignedValue = value;
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
    
}

void makeFilterParameterInfoForPoint2(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, float offsetx, float offsety, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_CENTEROFFSET;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    parameterInfo->defaultValue.fOffsetXY[0] = offsetx;
    parameterInfo->defaultValue.fOffsetXY[1] = offsety;
    parameterInfo->value.fOffsetXY[0] = offsetx;
    parameterInfo->value.fOffsetXY[1] = offsety;
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
    
}

void makeFilterParameterInfoForPoint2MaxMin(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, float *offset, float *offsetmax, float *offsetmin, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_CENTEROFFSET;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    parameterInfo->defaultValue.fOffsetXY[0] = offset[0];
    parameterInfo->defaultValue.fOffsetXY[1] = offset[1];
    parameterInfo->value.fOffsetXY[0] = offset[0];
    parameterInfo->value.fOffsetXY[1] = offset[1];
    
    parameterInfo->maxValue.fOffsetXY[0] = offsetmax[0];
    parameterInfo->maxValue.fOffsetXY[1] = offsetmax[1];
    
    parameterInfo->minValue.fOffsetXY[0] = offsetmin[0];
    parameterInfo->minValue.fOffsetXY[1] = offsetmin[1];
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
    
}

void makeFilterParameterInfoForFloat4(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, float* vec4, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_FLOAT_VECTOR4;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    memcpy(parameterInfo->defaultValue.fFloatVector4, vec4, 4 * sizeof(float));
    memcpy(parameterInfo->value.fFloatVector4, vec4, 4 * sizeof(float));
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
}

void makeFilterParameterInfoForFloatArray(FILTER_PARAMETER_INFO *parameterInfo, NSString *parameterName, float* vec, int size, NSString *displayName)
{
    [parameterName getCString:parameterInfo->parameterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    parameterInfo->parameterType = V_FLOAT_ARRAY;
    parameterInfo->nValueEnable = 1;
    parameterInfo->nScaleType = 0;
    parameterInfo->nNeedExtensionType = 0;
    parameterInfo->nEffectExtensionType = 0;
    
    memcpy(parameterInfo->defaultValue.fFloatArray, vec, size * sizeof(float));
    memcpy(parameterInfo->value.fFloatArray, vec, size * sizeof(float));
    
    if (displayName) {
        [displayName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }else{
        [parameterName getCString:parameterInfo->displayName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    }
    
}


#define MAX_SIZE_VALUE 200

- (id)init
{
    self = [super init];
    m_filtersCount = 50;
    m_allFiltersInfo = (COMMON_FILTER_INFO*)malloc(sizeof(COMMON_FILTER_INFO) * m_filtersCount);
    
    int filterIndex = 0;
    int parameterIndex = 0;
    
    //GPUImageEffectFilter
    [@"SPECIAL" getCString:m_allFiltersInfo[filterIndex].filterCatagoryName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    [@"Effect" getCString:m_allFiltersInfo[filterIndex].filterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    [@"GPUImageEffectFilter" getCString:m_allFiltersInfo[filterIndex].filterClassName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    m_allFiltersInfo[filterIndex].parametersCount = 45;
    FILTER_PARAMETER_INFO *parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);

    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"strokeEnable", 0x1, 0, 0, 0, 0, 0, 0, NULL); //enable for test
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"strokeSize", 0x1, 20.0, MAX_SIZE_VALUE, 0.0, 1, 2, 1, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"strokePosition", 0x1, 0, 2, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForRGB(&parameterInfo[parameterIndex++], @"strokeColor", 0x0000FF, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"strokeColorAlpha", 0x7, 0.8, 1.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"strokeBlendMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"strokeColorMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"strokeGradientStyle", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    float color[9] = {2, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"strokeGradientColor", color, 9, NULL);
    float colorAlpha[5] = {2, 1.0, 0.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"strokeGradientColorAlpha", colorAlpha, 5, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"strokeGradientAngle", 0x7, 0.0, 360.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"strokeGradientScaleRatio", 0x7, 1.0, 3.0, 0.1, 0, 0, 0, NULL);
    
    
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"fillEnable", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForRGB(&parameterInfo[parameterIndex++], @"fillColor", 0x00FF00, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"fillColorAlpha", 0x7, 1.0, 1.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"fillBlendMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"fillColorMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"fillGradientStyle", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    //float color[9] = {2, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"fillGradientColor", color, 9, NULL);
    //float colorAlpha[5] = {2, 1.0, 0.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"fillGradientColorAlpha", colorAlpha, 5, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"fillGradientAngle", 0x7, 0.0, 360.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"fillGradientScaleRatio", 0x7, 1.0, 3.0, 0.1, 0, 0, 0, NULL);
    
    
    
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"outerGlowEnable", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"outerGlowBlendMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"outerGlowColorMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"outerGlowSize", 0x1, 30.0, MAX_SIZE_VALUE, 0.0, 1, 2, 1, NULL);
    makeFilterParameterInfoForRGB(&parameterInfo[parameterIndex++], @"outerGlowColor", 0xBEFFFF, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"outerGlowColorAlpha", 0x7, 0.8, 1.0, 0.0, 0, 0, 0, NULL);
    //float color[9] = {2, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"outerGlowGradientColor", color, 9, NULL);
    //float colorAlpha[5] = {2, 1.0, 0.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"outerGlowGradientColorAlpha", colorAlpha, 5, NULL);
    
    
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"innerGlowEnable", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"innerGlowBlendMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"innerGlowColorMode", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"innerGlowSize", 0x1, 30.0, MAX_SIZE_VALUE, 0.0, 1, 2, 1, NULL);
    makeFilterParameterInfoForRGB(&parameterInfo[parameterIndex++], @"innerGlowColor", 0xBEFFFF, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"innerGlowColorAlpha", 0x7, 0.8, 1.0, 0.0, 0, 0, 0, NULL);
    //float color[9] = {2, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"innerGlowGradientColor", color, 9, NULL);
    //float colorAlpha[5] = {2, 1.0, 0.0, 1.0, 1.0};
    makeFilterParameterInfoForFloatArray(&parameterInfo[parameterIndex++], @"innerGlowGradientColorAlpha", colorAlpha, 5, NULL);
    
    
    
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"shadowEnable", 0x1, 0, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"shadowLightAngle", 0x1, 315.0, 360.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"shadowDistance", 0x1, 40.0, MAX_SIZE_VALUE, 0.0, 1, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"shadowBlur", 0x1, 20.0, 50, 0.0, 1, 0, 0, NULL);
    makeFilterParameterInfoForRGB(&parameterInfo[parameterIndex++], @"shadowColor", 0x404040, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"shadowColorAlpha", 0x7, 0.80, 1.0, 0.0, 0, 0, 0, NULL);
    float rect[4] = {0.0, 0.0, 1.0, 1.0};
    makeFilterParameterInfoForFloat4(&parameterInfo[parameterIndex++], @"imageRect", rect, NULL);
    
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 2;
    m_allFiltersInfo[filterIndex].parametersCount = parameterIndex;
    
    
    //GPUImageChannelFilter
    filterIndex++;
    parameterIndex = 0;
    [@"SPECIAL" getCString:m_allFiltersInfo[filterIndex].filterCatagoryName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    [@"Channel" getCString:m_allFiltersInfo[filterIndex].filterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    [@"GPUImageChannelFilter" getCString:m_allFiltersInfo[filterIndex].filterClassName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
    m_allFiltersInfo[filterIndex].parametersCount = 4;
    
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"redVisible", 0x1, 1, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"greenVisible", 0x1, 1, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"blueVisible", 0x1, 1, 0, 0, 0, 0, 0, NULL);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"alphaVisible", 0x1, 1, 0, 0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
   
    //GPUImageHueFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Hue Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Hue Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageHueFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageHueFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"Hue", 0x7, 10.0, 180.0, -180.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageRGBFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"RGB Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"RGB Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageRGBFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageRGBFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 3;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"red", 0x7, 1.0, 5.0, 0.0, 0, 0, 0, @"red");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"green", 0x7, 1.0, 5.0, 0.0, 0, 0, 0, @"green");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blue", 0x7, 1.0, 5.0, 0.0, 0, 0, 0, @"blue");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSaturationFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Saturation Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Saturation Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSaturationFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSaturationFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"saturation", 0x7, 1.0, 2.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageContrastFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Contrast Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Contrast Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageContrastFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageContrastFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"contrast", 0x7, 1.0, 4.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageBrightnessFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Brightness Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Brightness Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageBrightnessFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageBrightnessFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"brightness", 0x7, 0.0, 1.0, -1.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageExposureFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Exposure Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Exposure Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageExposureFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageExposureFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"exposure", 0x7, 0.0, 10.0, -10.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageWhiteBalanceFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"White Balance" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"White Balance" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageWhiteBalanceFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageWhiteBalanceFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"temperature", 0x7, 5000.0, 7500.0, 2500.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"tint", 0x7, 0.0, 1000.0, -1000.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageGrayscaleFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Grayscale" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Grayscale" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageGrayscaleFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageGrayscaleFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageGammaFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Gamma Adjustment" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Gamma Adjustment" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageGammaFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageGammaFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"gamma", 0x7, 1.0, 3.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageHighlightShadowFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Highlight Shadow" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Highlight Shadow" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageHighlightShadowFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageHighlightShadowFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"shadows", 0x7, 0.0, 1.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"highlights", 0x7, 1.0, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageHazeFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Haze" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Haze" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageHazeFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageHazeFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"distance", 0x7, 0.0, 0.3, -0.3, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"slope", 0x7, 0.0, 0.3, -0.3, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    
    //GPUImageMonochromeFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Color Monochrome" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Monochrome" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageMonochromeFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageMonochromeFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"intensity", 0x7, 1.0, 2.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForRGBA(&parameterInfo[parameterIndex++], @"color", 0xFF204060, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageFalseColorFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"False Color" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"False Color" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageFalseColorFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageFalseColorFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForRGBA(&parameterInfo[parameterIndex++], @"firstColor", 0xFFFFE0FF, NULL);
    makeFilterParameterInfoForRGBA(&parameterInfo[parameterIndex++], @"secondColor", 0xFF00FF00, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSepiaFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Sepia" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sepia" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSepiaFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSepiaFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"intensity", 0x7, 0.0, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageColorInvertFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Color Invert" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Invert" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageColorInvertFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageColorInvertFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageLuminanceThresholdFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Luminance Threshold" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Luminance Threshold" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageLuminanceThresholdFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageLuminanceThresholdFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"threshold", 0x7, 0.5, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImagePixellatePositionFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Pixelation" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Pixelation" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePixellatePositionFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePixellatePositionFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 3;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"fractionalWidthOfAPixel", 0x7, 0.01, 1.0, 0.0, 0, 0, 0, @"width");
    {
        float offset[2] = {0.5, 0.5};
        float offsetmax[2] = {1.0, 1.0};
        float offsetmin[2] = {0.0, 0.0};
        makeFilterParameterInfoForPoint2MaxMin(&parameterInfo[parameterIndex++], @"center", offset, offsetmax, offsetmin, NULL);
    }
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"radius", 0x7, 1.0, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImagePolarPixellateFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Polar Pixellate" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Polar Pixellate" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePolarPixellateFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePolarPixellateFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    {
        float offset[2] = {0.5, 0.5};
        float offsetmax[2] = {1.0, 1.0};
        float offsetmin[2] = {0.0, 0.0};
        makeFilterParameterInfoForPoint2MaxMin(&parameterInfo[parameterIndex++], @"center", offset, offsetmax, offsetmin, NULL);
    }
    {
        float offset[2] = {0.05, 0.05};
        float offsetmax[2] = {2.0, 2.0};
        float offsetmin[2] = {-2.0, -2.0};
        makeFilterParameterInfoForPoint2MaxMin(&parameterInfo[parameterIndex++], @"pixelSize", offset, offsetmax, offsetmin, NULL);
    }    
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImagePolkaDotFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Polka Dot" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Polka Dot" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePolkaDotFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePolkaDotFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"dotScaling", 0x7, 0.5, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageCrosshatchFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Cross Hatch" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Cross Hatch" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageCrosshatchFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageCrosshatchFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"crossHatchSpacing", 0x7, 0.003, 1.0, 0.0, 0, 0, 0, NULL);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"lineWidth", 0x7, 0.03, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageOpacityFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Opacity" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Opacity" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageOpacityFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageOpacityFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"opacity", 0x7, 1.0, 1.0, 0.0, 0, 0, 0, NULL);
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageCGAColorspaceFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Color Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Color Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"CGA Color Space" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"CGA Color Space" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageCGAColorspaceFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageCGAColorspaceFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageLaplacianFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Laplacian" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Laplacian" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageLaplacianFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageLaplacianFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSobelEdgeDetectionFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Sobel" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sobel" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSobelEdgeDetectionFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSobelEdgeDetectionFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"edgeStrength", 0x7, 1.0, 20.0, 0.0, 0, 0, 0, @"Edge Strength");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImagePrewittEdgeDetectionFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Prewitt" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Prewitt" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePrewittEdgeDetectionFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePrewittEdgeDetectionFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageCannyEdgeDetectionFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Canny" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Canny" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageCannyEdgeDetectionFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageCannyEdgeDetectionFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 4;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 1.0, 5.0, 0.0, 0, 0, 0, @"Blur Radius");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurTexelSpacingMultiplier", 0x7, 1.0, 20.0, 1.0, 0, 0, 0, @"blurTexelSpacingMultiplier");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"upperThreshold", 0x7, 1.0, 1.0, 0.0, 0, 0, 0, @"upperThreshold");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"lowerThreshold", 0x7, 0.0, 1.0, 0.0, 0, 0, 0, @"lowerThreshold");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageWeakPixelInclusionFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Weak Pixel Inclusion" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Weak Pixel Inclusion" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageWeakPixelInclusionFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageWeakPixelInclusionFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSketchFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Sketch" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sketch" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSketchFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSketchFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"edgeStrength", 0x7, 1.0, 20.0, 0.0, 0, 2, 1, @"Edge Strength");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageThresholdSketchFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Edge Detection" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Edge Detection" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Threshold Sketch" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Threshold Sketch" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageThresholdSketchFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageThresholdSketchFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"edgeStrength", 0x7, 1.0, 20.0, 0.0, 0, 2, 1, @"Edge Strength");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"threshold", 0x7, 0.8, 1.0, 0.0, 0, 2, 1, @"threshold");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageGaussianBlurFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Gaussian Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Gaussian Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageGaussianBlurFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageGaussianBlurFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 1.0, 10.0, 0.0, 1, 2, 1, @"Radius");
//    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"texelSpacingMultiplier", 0x7, 1.0, 20.0, 1.0, 0, 0, 0, @"Multiplier");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageBoxBlurFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Box Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Box Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageBoxBlurFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageBoxBlurFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 1.0, 10.0, 0.0, 1, 2, 1, @"Radius");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageMotionBlurFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Motion Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Motion Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageMotionBlurFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageMotionBlurFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurSize", 0x7, 1.0, 10.0, 0.0, 1, 2, 1, @"Size");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurAngle", 0x7, 0.0, 360.0, 0.0, 0, 2, 1, @"Angle");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;

    
    //GPUImageZoomBlurFilter 牵涉到整张图 没办法传递 因为必须切割
    
    
    //GPUImageHighPassFilter
//    filterIndex++;
//    parameterIndex = 0;
//    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
//    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"High Pass" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"High Pass" length]);
//    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageHighPassFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageHighPassFilter" length]);
//    m_allFiltersInfo[filterIndex].parametersCount = 1;
//    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
//    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"filterStrength", 0x7, 0.5, 1.0, 0.0, 1, 2, 1, @"Strength");    
//    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
//    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
//    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageMedianFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Median" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Median" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageMedianFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageMedianFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 0;
    m_allFiltersInfo[filterIndex].filterParameters = nil;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;

    //GPUImageBilateralFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Blur" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Blur" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Bilateral" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Bilateral" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageBilateralFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageBilateralFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 1.0, 10.0, 0.0, 1, 2, 1, @"Radius");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSharpenFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Sharpen" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sharpen" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Sharpen" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sharpen" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSharpenFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSharpenFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"sharpness", 0x7, 0.0, 4.0, -4.0, 0, 2, 1, @"Sharpness");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageUnsharpMaskFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Sharpen" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Sharpen" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Unsharp Mask" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Unshar pMask" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageUnsharpMaskFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageUnsharpMaskFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 4.0, 10.0, 0.0, 1, 2, 1, @"Radius");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"intensity", 0x7, 1.0, 10.0, 0.0, 0, 2, 1, @"Intensity");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageToonFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Toon" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Toon" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageToonFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageToonFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"threshold", 0x7, 0.2, 1.0, 0.0, 0, 2, 1, @"Threshold");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"quantizationLevels", 0x7, 10.0, 20.0, 1.0, 0, 0, 0, @"Quantization Levels");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageSmoothToonFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Smooth Toon" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Smooth Toon" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageSmoothToonFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageSmoothToonFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 3;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 2.0, 20.0, 0.0, 1, 2, 1, @"Radius");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"threshold", 0x7, 0.2, 1.0, 0.0, 0, 2, 1, @"Threshold");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"quantizationLevels", 0x7, 10.0, 20.0, 1.0, 0, 0, 0, @"Quantization Levels");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageTiltShiftFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Tilt Shift" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Tilt Shift" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageTiltShiftFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageTiltShiftFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 4;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"blurRadiusInPixels", 0x7, 7.0, 20.0, 0.0, 1, 2, 1, @"Radius");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"topFocusLevel", 0x7, 0.4, 1.0, 0.0, 0, 2, 1, @"Top Level");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"bottomFocusLevel", 0x7, 0.6, 1.0, 0.0, 0, 0, 0, @"Bottom Level");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"focusFallOffRate", 0x7, 0.2, 1.0, 0.0, 0, 0, 0, @" Falloff Rate");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageEmbossFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Emboss" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Emboss" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageEmbossFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageEmbossFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"intensity", 0x7, 1.0, 4.0, 0.0, 0, 2, 1, @"Intensity");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageChromaKeyFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Chroma Key" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Chroma Key" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageChromaKeyFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageChromaKeyFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 2;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"thresholdSensitivity", 0x7, 0.3, 1.0, 0.0, 0, 0, 0, @"Sensitivity");
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"smoothing", 0x7, 0.1, 1.0, 0.0, 0, 2, 1, @"Smoothing");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImageKuwaharaFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Kuwahara" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Kuwahara" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImageKuwaharaFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImageKuwaharaFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForInt(&parameterInfo[parameterIndex++], @"radius", 0x7, 3, 30, 1, 1, 2, 1, @"Radius");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;
    
    //GPUImagePosterizeFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Posterize" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Posterize" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePosterizeFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePosterizeFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 1;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"thresholdSensitivity", 0x7, 0.3, 1.0, 0.0, 0, 0, 0, @"Sensitivity");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;

    //GPUImagePerlinNoiseFilter
    filterIndex++;
    parameterIndex = 0;
    memcpy(m_allFiltersInfo[filterIndex].filterCatagoryName, [@"Effect" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Effect" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterName, [@"Perlin Noise" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"Perlin Noise" length]);
    memcpy(m_allFiltersInfo[filterIndex].filterClassName, [@"GPUImagePerlinNoiseFilter" cStringUsingEncoding:NSASCIIStringEncoding], 2*[@"GPUImagePerlinNoiseFilter" length]);
    m_allFiltersInfo[filterIndex].parametersCount = 3;
    parameterInfo = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFiltersInfo[filterIndex].parametersCount);
    makeFilterParameterInfoForFloat(&parameterInfo[parameterIndex++], @"scale", 0x7, 10.0, 100.0, 0.0, 0, 2, 1, @"scale");
    makeFilterParameterInfoForRGBA(&parameterInfo[parameterIndex++], @"colorStart", 0xFF0000FF, @"Start Color");
    makeFilterParameterInfoForRGBA(&parameterInfo[parameterIndex++], @"colorFinish", 0xFF00FF00, @"Finish Color");
    m_allFiltersInfo[filterIndex].filterParameters = parameterInfo;
    m_allFiltersInfo[filterIndex].gpuImageFilter = nil;
    m_allFiltersInfo[filterIndex].textureCount = 1;

    
    
    m_filtersCount = filterIndex + 1;
    return self;
    
}


- (void)dealloc
{
    for (int i = 0; i < m_filtersCount; i++) {
        if (m_allFiltersInfo[i].filterParameters) {
            free(m_allFiltersInfo[i].filterParameters);
        }
        [m_allFiltersInfo[i].gpuImageFilter release];
    }
    if (m_allFiltersInfo) {
        free(m_allFiltersInfo);
    }
    
    [super dealloc];
}

- (int)getFiltersCount
{
    return m_filtersCount;
}

- (COMMON_FILTER_INFO*)getAllFiltersInfo
{
    return m_allFiltersInfo;
}

+(id)sharedSmartFilterRegister {
    
    if (!sharedDefaultRegister) {
        sharedDefaultRegister = [[PSSmartFilterRegister alloc] init];
    }
    return sharedDefaultRegister;
}

+(int)getFiltersCount
{
    return [[PSSmartFilterRegister sharedSmartFilterRegister] getFiltersCount];
}



+ (COMMON_FILTER_INFO) filterWithName:(NSString *) filterName
{
    PSSmartFilterRegister *sharedRegister = [PSSmartFilterRegister sharedSmartFilterRegister];
    COMMON_FILTER_INFO *allFiltersInfo = [sharedRegister getAllFiltersInfo];
    int filtersCount = [sharedRegister getFiltersCount];
    
    COMMON_FILTER_INFO filterInfo;
    NSString *fliterClassName = nil;
    for (int i = 0; i < filtersCount; i++) {
        COMMON_FILTER_INFO temmpFilterInfo = allFiltersInfo[i];
        NSString *tfilterName = [NSString stringWithUTF8String:temmpFilterInfo.filterName];
        if ([tfilterName isEqualToString:filterName]) {
            fliterClassName = [NSString stringWithUTF8String:temmpFilterInfo.filterClassName];
            filterInfo = temmpFilterInfo;
            break;
        }
    }
    if (!fliterClassName) {
        return filterInfo;
    }
    Class filterClass = NSClassFromString(fliterClassName);
    GPUImageOutput *filter = [[filterClass alloc] init];
    [filter useNextFrameForImageCapture];
    filterInfo.gpuImageFilter = filter;
    
    FILTER_PARAMETER_INFO *filterParameters = nil;
    if (filterInfo.parametersCount > 0) {
        filterParameters = (FILTER_PARAMETER_INFO *)malloc(sizeof(FILTER_PARAMETER_INFO) * filterInfo.parametersCount);
        memcpy(filterParameters, filterInfo.filterParameters, sizeof(FILTER_PARAMETER_INFO) * filterInfo.parametersCount);
    }
    filterInfo.filterParameters = filterParameters;
    
    return filterInfo;
}




+ (NSArray *) getAllFiltersCatagoryName
{
    PSSmartFilterRegister *sharedRegister = [PSSmartFilterRegister sharedSmartFilterRegister];
    COMMON_FILTER_INFO *allFiltersInfo = [sharedRegister getAllFiltersInfo];
    int filtersCount = [sharedRegister getFiltersCount];
    
    NSMutableArray *namesArray = [NSMutableArray array];
    for (int i = 0; i < filtersCount; i++) {
        NSString *cname = [NSString stringWithUTF8String:allFiltersInfo[i].filterCatagoryName];
        if (![namesArray containsObject:cname]) {
            [namesArray addObject:cname];
        }
    }
    return namesArray;
}

+ (NSArray *) getAllFiltersName
{
    PSSmartFilterRegister *sharedRegister = [PSSmartFilterRegister sharedSmartFilterRegister];
    COMMON_FILTER_INFO *allFiltersInfo = [sharedRegister getAllFiltersInfo];
    int filtersCount = [sharedRegister getFiltersCount];
    
    NSMutableArray *namesArray = [NSMutableArray array];
    for (int i = 0; i < filtersCount; i++) {
        [namesArray addObject:[NSString stringWithUTF8String:allFiltersInfo[i].filterName]];
    }
    return namesArray;
}


+ (NSArray *) getAllFiltersNameForCatagory:(NSString *)catagoryName
{
    PSSmartFilterRegister *sharedRegister = [PSSmartFilterRegister sharedSmartFilterRegister];
    COMMON_FILTER_INFO *allFiltersInfo = [sharedRegister getAllFiltersInfo];
    int filtersCount = [sharedRegister getFiltersCount];
    
    NSMutableArray *namesArray = [NSMutableArray array];
    for (int i = 0; i < filtersCount; i++) {
        NSString *cname = [NSString stringWithUTF8String:allFiltersInfo[i].filterCatagoryName];
        if ([catagoryName isEqualToString:cname]) {
            [namesArray addObject:[NSString stringWithUTF8String:allFiltersInfo[i].filterName]];
        }
        
    }
    return namesArray;
}


@end