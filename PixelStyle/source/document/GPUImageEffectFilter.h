//
//  GPUImageEffectFilter.h
//  test1
//
//  Created by lchzh on 6/9/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#import <GPUImage/GPUImage.h>

inline GPUVector3 makeGPUVector3(float v1, float v2, float v3)
{
    GPUVector3 vector3 = {v1, v2, v3};
    return vector3;
}

inline GPUVector4 makeGPUVector4(float v1, float v2, float v3, float v4)
{
    GPUVector4 vector4 = {v1, v2, v3, v4};
    return vector4;
}

@interface GPUImageEffectFilter : GPUImageTwoInputFilter
{
    GLint distanceMethodUniform;  // 0  cpu 1 GPU
    //stroke
    GLint strokeEnableUniform;
    GLint strokeSizeUniform;
    GLint strokePositionUniform;
    GLint strokeColorUniform;
    GLint strokeColorAlphaUniform;
    GLint strokeBlendModeUniform;
    GLint strokeColorModeUniform;
    GLint strokeGradientColorUniform;
    GLint strokeGradientColorAlphaUniform;
    GLint strokeGradientStyleUniform;
    GLint strokeGradientAngleUniform;
    GLint strokeGradientScaleRatioUniform;
    
    //fill
    GLint fillEnableUniform;
    GLint fillColorUniform;
    GLint fillColorAlphaUniform;
    GLint fillBlendModeUniform;    
    GLint fillColorModeUniform;
    GLint fillGradientColorUniform;
    GLint fillGradientColorAlphaUniform;
    GLint fillGradientStyleUniform;
    GLint fillGradientAngleUniform;
    GLint fillGradientScaleRatioUniform;
    
    
    //outerGlow
    GLint outerGlowEnableUniform;
    GLint outerGlowBlendModeUniform;
    GLint outerGlowColorModeUniform;
    GLint outerGlowColorUniform;
    GLint outerGlowColorAlphaUniform;
    GLint outerGlowSizeUniform;
    GLint outerGlowGradientColorUniform;
    GLint outerGlowGradientColorAlphaUniform;
    
    GLint innerGlowEnableUniform;
    GLint innerGlowBlendModeUniform;
    GLint innerGlowColorModeUniform;
    GLint innerGlowColorUniform;
    GLint innerGlowColorAlphaUniform;
    GLint innerGlowSizeUniform;
    GLint innerGlowGradientColorUniform;
    GLint innerGlowGradientColorAlphaUniform;
        
    GLint distanceScaleUniform;
    
    GLint ulOffsetUniform;
    GLint brOffsetUniform;
    GLint imageRectUniform;
    
}

@property (readwrite, nonatomic) int distanceMethod;

@property (readwrite, nonatomic) int strokeEnable;
@property (readwrite, nonatomic) CGFloat strokeSize;
@property (readwrite, nonatomic) int strokePosition;
@property (readwrite, nonatomic) GPUVector3 strokeColor;
@property (readwrite, nonatomic) CGFloat strokeColorAlpha;
@property (readwrite, nonatomic) int strokeBlendMode;
@property (readwrite, nonatomic) int strokeColorMode; //0 color 1 gradient
@property (readwrite, nonatomic) GPUVectorLong strokeGradientColor;
@property (readwrite, nonatomic) GPUVectorLong strokeGradientColorAlpha;
@property (readwrite, nonatomic) int strokeGradientStyle;
@property (readwrite, nonatomic) float strokeGradientAngle;
@property (readwrite, nonatomic) float strokeGradientScaleRatio;



@property (readwrite, nonatomic) int fillEnable;
@property (readwrite, nonatomic) int fillBlendMode;
@property (readwrite, nonatomic) int fillColorMode; //0 color 1 gradient 2 图案
@property (readwrite, nonatomic) GPUVector3 fillColor;
@property (readwrite, nonatomic) CGFloat fillColorAlpha;
@property (readwrite, nonatomic) GPUVectorLong fillGradientColor;
@property (readwrite, nonatomic) GPUVectorLong fillGradientColorAlpha;
@property (readwrite, nonatomic) int fillGradientStyle;
@property (readwrite, nonatomic) float fillGradientAngle;
@property (readwrite, nonatomic) float fillGradientScaleRatio;



@property (readwrite, nonatomic) int outerGlowEnable;
@property (readwrite, nonatomic) int outerGlowBlendMode;
@property (readwrite, nonatomic) int outerGlowColorMode; //0 color 1 gradient 2 图案
@property (readwrite, nonatomic) CGFloat outerGlowSize;
@property (readwrite, nonatomic) GPUVector3 outerGlowColor;
@property (readwrite, nonatomic) CGFloat outerGlowColorAlpha;
@property (readwrite, nonatomic) GPUVectorLong outerGlowGradientColor;
@property (readwrite, nonatomic) GPUVectorLong outerGlowGradientColorAlpha;



@property (readwrite, nonatomic) int innerGlowEnable;
@property (readwrite, nonatomic) int innerGlowBlendMode;
@property (readwrite, nonatomic) int innerGlowColorMode; //0 color 1 gradient 2 图案
@property (readwrite, nonatomic) CGFloat innerGlowSize;
@property (readwrite, nonatomic) GPUVector3 innerGlowColor;
@property (readwrite, nonatomic) CGFloat innerGlowColorAlpha;
@property (readwrite, nonatomic) GPUVectorLong innerGlowGradientColor;
@property (readwrite, nonatomic) GPUVectorLong innerGlowGradientColorAlpha;


@property (readwrite, nonatomic) CGFloat distanceScale;

@property(readwrite, nonatomic) CGPoint ulOffset;
@property(readwrite, nonatomic) CGPoint brOffset;
@property(readwrite, nonatomic) GPUVector4 imageRect;

@end
