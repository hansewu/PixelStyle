//
//  GPUImageEffectFilter.m
//  test1
//
//  Created by lchzh on 6/9/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//
#import <stdio.h>
#import "GPUImageEffectFilter.h"

@implementation GPUImageEffectFilter

@synthesize distanceMethod = _distanceMethod;
@synthesize strokeEnable = _strokeEnable;
@synthesize strokeSize = _strokeSize;
@synthesize strokePosition = _strokePosition;
@synthesize strokeColor = _strokeColor;
@synthesize strokeColorAlpha = _strokeColorAlpha;
@synthesize strokeBlendMode = _strokeBlendMode;
@synthesize strokeGradientColor = _strokeGradientColor;
@synthesize strokeGradientColorAlpha = _strokeGradientColorAlpha;
@synthesize strokeColorMode = _strokeColorMode;
@synthesize strokeGradientStyle = _strokeGradientStyle;
@synthesize strokeGradientAngle = _strokeGradientAngle;
@synthesize strokeGradientScaleRatio = _strokeGradientScaleRatio;

@synthesize fillBlendMode = _fillBlendMode;
@synthesize fillEnable = _fillEnable;
@synthesize fillColor = _fillColor;
@synthesize fillColorAlpha =_fillColorAlpha;
@synthesize fillGradientColor = _fillGradientColor;
@synthesize fillGradientColorAlpha = _fillGradientColorAlpha;
@synthesize fillColorMode = _fillColorMode;
@synthesize fillGradientStyle = _fillGradientStyle;
@synthesize fillGradientAngle = _fillGradientAngle;
@synthesize fillGradientScaleRatio = _fillGradientScaleRatio;

@synthesize outerGlowEnable = _outerGlowEnable;
@synthesize outerGlowBlendMode = _outerGlowBlendMode;
@synthesize outerGlowColorMode = _outerGlowColorMode;
@synthesize outerGlowColor = _outerGlowColor;
@synthesize outerGlowColorAlpha = _outerGlowColorAlpha;
@synthesize outerGlowSize = _outerGlowSize;
@synthesize outerGlowGradientColor = _outerGlowGradientColor;
@synthesize outerGlowGradientColorAlpha = _outerGlowGradientColorAlpha;

@synthesize innerGlowEnable = _innerGlowEnable;
@synthesize innerGlowBlendMode = _innerGlowBlendMode;
@synthesize innerGlowColorMode = _innerGlowColorMode;
@synthesize innerGlowColor = _innerGlowColor;
@synthesize innerGlowColorAlpha = _innerGlowColorAlpha;
@synthesize innerGlowSize = _innerGlowSize;
@synthesize innerGlowGradientColor = _innerGlowGradientColor;
@synthesize innerGlowGradientColorAlpha = _innerGlowGradientColorAlpha;


@synthesize distanceScale = _distanceScale;

@synthesize ulOffset = _ulOffset;
@synthesize brOffset = _brOffset;
@synthesize imageRect = _imageRect;

NSString *const kGPUImageEffectTextureVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputTextureCoordinate2;
 
 uniform float strokeGradientColor1[25];
 varying float strokeGradientColor[25];
 
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     textureCoordinate2 = inputTextureCoordinate2.xy;
     
     for(int i=0; i<25; i++)
         strokeGradientColor[i] = strokeGradientColor1[i];
//     memcpy(strokeGradientColor, strokeGradientColor1, 25*sizeof(float));
 }
 );

NSString *const kGPUImageEffectFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform int distanceMethod;
 //stroke
 uniform int strokeEnable;
 uniform float strokeSize;
 uniform int strokePosition;
 uniform vec3 strokeColor;
 uniform float strokeColorAlpha;
 uniform int strokeBlendMode;
 uniform int strokeColorMode;
 
 //uniform float strokeGradientColor[25];
 varying float strokeGradientColor[25]; //test
 
 uniform float strokeGradientColorAlpha[13];
 uniform int strokeGradientStyle;
 uniform float strokeGradientAngle;
 uniform float strokeGradientScaleRatio;
 
 //fill
 uniform int fillEnable;
 uniform int fillBlendMode;
 uniform int fillColorMode;
 uniform vec3 fillColor;
 uniform float fillColorAlpha;
 uniform float fillGradientColor[25];
 uniform float fillGradientColorAlpha[13];
 uniform int fillGradientStyle;
 uniform float fillGradientAngle;
 uniform float fillGradientScaleRatio;
 
 //outerglow
 uniform int outerGlowEnable;
 uniform int outerGlowBlendMode;
 uniform int outerGlowColorMode;
 uniform vec3 outerGlowColor;
 uniform float outerGlowColorAlpha;
 uniform float outerGlowSize;
 uniform float outerGlowGradientColor[25];
 uniform float outerGlowGradientColorAlpha[13];
 
 //innerglow
 uniform int innerGlowEnable;
 uniform int innerGlowBlendMode;
 uniform int innerGlowColorMode;
 uniform vec3 innerGlowColor;
 uniform float innerGlowColorAlpha;
 uniform float innerGlowSize;
 uniform float innerGlowGradientColor[25];
 uniform float innerGlowGradientColorAlpha[13];
 
 
 
 
 //scale
 uniform float distanceScale;
 
 //position
 uniform vec2 ulOffset;
 uniform vec2 brOffset;
 
 uniform vec4 imageRect;
 

 vec4 mergeCom_new(in vec4 c1, in vec4 c2, in int mode, in float opacity)
{
    vec4 outputColor = c2;
  //  c1.a = c1.a * opacity;
    c2.a = c1.a*c2.a;
    if(mode == 0)
    { //normal
        outputColor = c1 * opacity  + c2 * (1.0 - opacity);
    }else if(mode == 1){ //multiply
        vec4 base = c2;
        vec4 overlayer = c1;
        outputColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
    }else if(mode == 2){ //lighten
        outputColor = max(c1, c2);;
    }else if(mode == 3){ //darken
        vec4 base = c2;
        vec4 overlayer = c1;
        outputColor = vec4(min(overlayer.rgb * base.a, base.rgb * overlayer.a) + overlayer.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlayer.a), 1.0);
    }else if(mode == 4){ //source in
        outputColor = c1;
    }
    
    
    return outputColor;
}
 
 vec4 mergeCom(in vec4 c1, in vec4 c2, in int mode, in float opacity)
{
    vec4 outputColor = c2;
   // c1.a = c1.a * opacity;
    if(mode == 0){ //normal
        float a = c1.a + c2.a * (1.0 - c1.a);
        float alphaDivisor = a + step(a, 0.0);
        
        outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
        outputColor.a = a;
    }else if(mode == 1){ //multiply
        vec4 base = c2;
        vec4 overlayer = c1;
        outputColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
    }else if(mode == 2){ //lighten        
        outputColor = max(c1, c2);;
    }else if(mode == 3){ //darken
        vec4 base = c2;
        vec4 overlayer = c1;
        outputColor = vec4(min(overlayer.rgb * base.a, base.rgb * overlayer.a) + overlayer.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlayer.a), 1.0);
    }else if(mode == 4){ //source in
        outputColor = c1;
    }
  //  outputColor.a = c1.a * c2.a;
    outputColor = outputColor*opacity + c2 * (1.0 - opacity);
    return outputColor;
}
 

 vec4 merge(in vec4 c1, in vec4 c2)
{
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    //float a = 1.0 - (1.0 - c1.a) * (1.0 - c2.a);
    float alphaDivisor = a + step(a, 0.0);
    vec4 outputColor;
    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    return outputColor;
}
 

 vec4 gradientColorAtPositonSimple(in float xposition, in float gradientColor[25], in float gradientColorAlpha[13])
{
    vec4 outputColor = vec4(0.0, 0.0, 0.0, 0.0);
    int colorCount = int(gradientColor[0]);
    if(colorCount >= 2){
        if(xposition <= gradientColor[4]){
            outputColor.rgb = vec3(gradientColor[1], gradientColor[2], gradientColor[3]);
        }else if(xposition >= gradientColor[(colorCount - 1) * 4 + 4]){
            outputColor.rgb = vec3(gradientColor[(colorCount - 1) * 4 + 1], gradientColor[(colorCount - 1) * 4 + 2], gradientColor[(colorCount - 1) * 4 + 3]);
            
        }else{
            for (int i = 0; i < colorCount - 1; i++)
            {
                if(xposition >= gradientColor[i * 4 + 4] && xposition <= gradientColor[(i + 1) * 4 + 4]){
                    vec3 color1 = vec3(gradientColor[i * 4 + 1], gradientColor[i * 4 + 2], gradientColor[i * 4 + 3]);
                    vec3 color2 = vec3(gradientColor[(i + 1) * 4 + 1], gradientColor[(i + 1) * 4 + 2], gradientColor[(i + 1) * 4 + 3]);
                    float dist = gradientColor[(i + 1) * 4 + 4] - gradientColor[i * 4 + 4];
                    if(abs(dist) < 0.01){
                        outputColor.rgb = color1;
                        break;
                    }
                    float pos = (xposition - gradientColor[i * 4 + 4]) / dist;
                    outputColor.rgb = color1 * (1.0 - pos) + color2 * pos;
                    break;
                }
            }
        }

    }else if(colorCount == 1){
        outputColor.rgb = vec3(gradientColor[1], gradientColor[2], gradientColor[3]);
    }
        
    int alphaCount = int(gradientColorAlpha[0]);
    if(alphaCount >= 2){
        if(xposition <= gradientColorAlpha[2]){
            outputColor.a = gradientColorAlpha[1];
        }else if(xposition >= gradientColorAlpha[(alphaCount - 1) * 2 + 2]){
            outputColor.a = gradientColorAlpha[(alphaCount - 1) * 2 + 1];
            
        }else{
            for (int i = 0; i < alphaCount - 1; i++)
            {
                if(xposition >= gradientColorAlpha[i * 2 + 2] && xposition <= gradientColorAlpha[(i + 1) * 2 + 2]){
                    float dist = gradientColorAlpha[(i + 1) * 2 + 2] - gradientColorAlpha[i * 2 + 2];
                    if(abs(dist) < 0.01){
                        outputColor.a = gradientColorAlpha[i * 2 + 1];
                        break;
                    }
                    float pos = (xposition - gradientColorAlpha[i * 2 + 2]) / (gradientColorAlpha[(i + 1) * 2 + 2] - gradientColorAlpha[i * 2 + 2]);
                    outputColor.a = gradientColorAlpha[i * 2 + 1] * (1.0 - pos) + gradientColorAlpha[(i + 1) * 2 + 1] * pos;
                    break;
                }
            }
        }
    }else if(alphaCount == 1){
        outputColor.a = gradientColorAlpha[1];
    }
    
    
    return outputColor;
}
 

 vec4 gradientColorAtPositon(in vec4 imageRect, in vec2 coordinate, in float gradientColor[25], in float gradientColorAlpha[13], in int style, in float angle, in float scale, in vec2 center)
{
    angle = 90.0 - angle;
    angle = (angle) / 180.0 * 3.1416;
    scale = 1.0 / scale;
    vec4 outputColor;
    float xposition = 0.5;
    vec2 position;
    position.x = imageRect.x + coordinate.x * imageRect.z;
    position.y = imageRect.y + coordinate.y * imageRect.w;
    
    center = vec2(0.5, 0.5);
    
    if(style == 0){
        vec2 newposition;
        newposition.x = (position.x - center.x) * cos(angle) - (position.y - center.y) * sin(angle) + center.x;
        //newposition.y = (position.x - center.x) * sin(angle) + (position.y - center.y) * cos(angle) + center.y;
        xposition = newposition.x;
        xposition = (xposition - 0.5) * scale + 0.5;
        
    }else if(style == 1){
        vec2 newposition;
        xposition = (position.x - center.x) * (position.x - center.x) + (position.y - center.y) * (position.y - center.y);
        xposition = sqrt(xposition * 2.0);
        xposition = xposition * scale;
    }
    
    
    outputColor = gradientColorAtPositonSimple(xposition, gradientColor, gradientColorAlpha);
    
    return outputColor;
    
}
 

 float getDistance(vec4 colorI)
 {
     vec4 colorOffet   = texture2D(inputImageTexture2, textureCoordinate);
     float fStepU = colorOffet.z;
     float fStepV = colorOffet.w;
     
     fStepU /= 256.0;
     fStepV /= 256.0;
     
     vec2 offset = colorOffet.xy;
   //  int pointToProcessIn = 0;
     
     
     if(offset.x > 0.5)  offset.x = offset.x - 1.0;
     if(offset.y > 0.5)  offset.y = offset.y - 1.0;
     
     float fDist2 = 200.0;
    
     {
         vec2  offsetScale = offset;
     offsetScale.x /= fStepU;
     offsetScale.y /= fStepV;
     fDist2 = length(offsetScale);
     }
     
     if(fDist2 < 10.0)
     {

         fDist2 *= fDist2;
         for(float y=-2.0; y<=2.0; y+=1.0)
             for(float x=-2.0; x<=2.0; x+=1.0)
         {
             vec2  newOffset = offset + vec2(x*fStepU, y*fStepV);
            vec4 colorCurrent = texture2D(inputImageTexture,  textureCoordinate + newOffset);
             
             if(colorCurrent.a > 0.001 && colorI.a > 0.001) continue;
             if(colorCurrent.a < 0.001 && colorI.a < 0.001) continue;
             
             float fDistCurrent = newOffset.x*newOffset.x + newOffset.y * newOffset.y;
             
             if(fDistCurrent < fDist2)
             {
                 fDist2 = fDistCurrent;
                 offset = newOffset;
             }
        }
         
         offset.x /= fStepU;
         offset.y /= fStepV;
         fDist2 = length(offset);
     }
  /*   else
     {
         vec2 step = vec2(-fStepU, -fStepV );
         vec2 distoffset = offset;
         
         if(distoffset.x < 0.0)
         {
             distoffset.x = -distoffset.x;
             step.x = -step.x;
         }
         
         if(distoffset.y < 0.0)
         {
             distoffset.y = -distoffset.y;
             step.y = -step.y;
         }
         
         if(distoffset.x > distoffset.y)
         {
             step.y *= distoffset.y/distoffset.x;

         }
         else
         {
             step.x *= distoffset.x/distoffset.y;
         }
         
         if((colorI.a > 0.0 && colorOffet.a > 0.0 ) || (colorI.a < 0.001 && colorOffet.a < 0.001))//逆序
         {
             for(float j=-7.0; j<=0.0; j+=1.0)
             {
                 vec2  newOffset = offset + j* step;
                 vec4 colorCurrent = texture2D(inputImageTexture,  textureCoordinate + newOffset);
                 
                 if(colorI.a > 0.0 && colorCurrent.a < 0.001)
                     offset = newOffset;
                 else if(colorI.a < 0.001 && colorCurrent.a > 0.0)
                     offset = newOffset;
                 
            }
         }
         else
         {
             for(float j=7.0; j>=0.0; j-=1.0)
             {
                 vec2  newOffset = offset + j* step;
                 vec4 colorCurrent = texture2D(inputImageTexture,  textureCoordinate + newOffset);
                 
                 if(colorI.a > 0.0 && colorCurrent.a < 0.001)
                     offset = newOffset;
                 else if(colorI.a < 0.001 && colorCurrent.a > 0.0)
                     offset = newOffset;
                 
             }
         }
         
         offset.x /= fStepU;
         offset.y /= fStepV;
         fDist2 = length(offset);
         
     }
*/
     
         if(colorI.a > 0.0)
             fDist2 = - fDist2;
     
     
     return fDist2;
     
 }
 
 
 void main()
 {
     vec4 color = texture2D(inputImageTexture,  textureCoordinate);

     float distance  = 1.0;
     
     if(distanceMethod > 0)  // no fragment uniform space
         distance  = getDistance(color);
     else
       distance = texture2D(inputImageTexture2,  textureCoordinate).r / distanceScale;//200.0*
     
     float blur = 2.0;
     
     vec2 center = vec2(0.5, 0.5);
     
     vec4 desColor = color;
     if(fillEnable == 1)
     {
         if(distance <= 0.0) //color.a < 1.0 &&
         {
             vec4 c1;
             vec4 c2 = color;
             if(fillColorMode == 0){
                 if(fillBlendMode == 0)
                 {
                     c1 = vec4(fillColor, color.a);
                     desColor = vec4( fillColor*fillColorAlpha + color.rgb * (1.0 -fillColorAlpha), color.a);// mergeCom(c1, c2, fillBlendMode, fillColorAlpha);
                 }
                 else
                 {
                     c1 = vec4(fillColor, 1.0);
                     desColor = mergeCom(c1, c2, fillBlendMode, fillColorAlpha);
                     desColor.a = color.a; //add
                 }
             }else if(fillColorMode == 1){
                 c1 = gradientColorAtPositon(imageRect, textureCoordinate, fillGradientColor, fillGradientColorAlpha, fillGradientStyle, fillGradientAngle, fillGradientScaleRatio, center);
                // c1.a = color.a;
                 desColor = mergeCom(c1, c2, fillBlendMode, fillColorAlpha);
                 desColor.a = color.a; //add
             }
            
             
         }
     }
     
     if(innerGlowEnable == 1)
     {
         if(distance <= 0.0)
         {
             if(-distance <= innerGlowSize)
             {
                 vec4 c1;
                 vec4 c2 = desColor;
                 float xpostion = distance / innerGlowSize;

                 if(innerGlowColorMode == 0)
                 {
                     c1 = vec4(innerGlowColor,  (1.0 + xpostion));
                 }
                 else if(innerGlowColorMode == 1)
                 {
                     c1 = gradientColorAtPositonSimple(-xpostion, innerGlowGradientColor, innerGlowGradientColorAlpha);
                     c1.a = c1.a * (1.0 + xpostion);
                 }
                 
                 desColor = mergeCom(c1, c2, innerGlowBlendMode, innerGlowColorAlpha);
                 desColor.a = color.a;
             }
         }
         else
         {
             if(distance <= blur)
             {
                 vec4 outputColor;                 
                 
                 if(innerGlowColorMode == 0)
                 {
                     outputColor = vec4(innerGlowColor, innerGlowColorAlpha * (1.0 - distance / blur));
                 }
                 else if(innerGlowColorMode == 1)
                 {
                     outputColor = gradientColorAtPositonSimple(0.0, innerGlowGradientColor, innerGlowGradientColorAlpha);
                     outputColor.a = outputColor.a * (1.0 - distance / blur);
                 }
                 
                 desColor = outputColor;
             }
         }
     }

     
     vec4 colorOld = desColor;
     
     if(outerGlowEnable == 1)
     {
         
         if(distance > 0.0)
         {
             if(distance <= outerGlowSize){
                 
                 vec4 c2 = desColor;
                 vec4 c1;
                 float xpostion = distance / outerGlowSize;
                 if(outerGlowColorMode == 0){
                     c1 = vec4(outerGlowColor, 1.0 - xpostion);
                 }else if(outerGlowColorMode == 1){
                     c1 = gradientColorAtPositonSimple(xpostion, outerGlowGradientColor, outerGlowGradientColorAlpha);
                     c1.a = c1.a * (1.0 - xpostion);
                 }
                 desColor = mergeCom(c1, c2, outerGlowBlendMode, outerGlowColorAlpha);
             }
         }else{
             if(color.a > 0.0)
             {
                 vec4 c1 = desColor;
                 vec4 c2;
                 if(outerGlowColorMode == 0){
                     c2 = vec4(outerGlowColor, 1.0);
                 }else if(outerGlowColorMode == 1){
                     c2 = gradientColorAtPositonSimple(0.0, outerGlowGradientColor, outerGlowGradientColorAlpha);
                 }
                 c2.a = c2.a * outerGlowColorAlpha;
                 
                 desColor = mergeCom(c1, c2, 0, 1.0);
             }
         }
         
     }
     
     
     
     if(strokeEnable == 1)
     {
         vec4 c2 = desColor;
         vec4 c1;
         if(strokePosition == 0)
         {
             if(distance >= 0.1) //color.a < 1.0 &&
             {
                 if(distance < strokeSize)
                 {
                     float xpostion = distance / strokeSize;
                     if(strokeColorMode == 0){
                         c1 = vec4(strokeColor, 1.0);
                     }else if(strokeColorMode == 1){
                         if(strokeGradientStyle > 1){
                             c1 = gradientColorAtPositonSimple(xpostion, strokeGradientColor, strokeGradientColorAlpha);
                         }else{
                             c1 = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                         }
                     }
                     desColor = mergeCom(c1, c2, strokeBlendMode, strokeColorAlpha);
                 }
                 else if(distance <= strokeSize + blur)
                 {
                     if(strokeColorMode == 0){
                         c1 = vec4(strokeColor, (1.0 - (distance - strokeSize) / blur));
                     }else if(strokeColorMode == 1){
                         if(strokeGradientStyle > 1){
                             c1 = gradientColorAtPositonSimple(1.0, strokeGradientColor, strokeGradientColorAlpha);
                         }else{
                             c1 = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                         }
                         c1.a = c1.a * (1.0 - (distance - strokeSize) / blur);
                     }
                     desColor = mergeCom(c1, c2, strokeBlendMode, strokeColorAlpha);
                 }
                 
             }
             else{
                 vec4 c1 = colorOld;
                 vec4 c2;
                 
                 if(strokeColorMode == 0){
                     c2 = vec4(strokeColor, 1.0);
                 }else if(strokeColorMode == 1){
                     if(strokeGradientStyle > 1){
                         c2 = gradientColorAtPositonSimple(0.0, strokeGradientColor, strokeGradientColorAlpha);
                     }else{
                         c2 = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                     }
                 }
                 c2.a = c2.a * strokeColorAlpha;
                 
                 desColor = mergeCom(c1, c2, 0, 1.0);

             }

         }
         else if(strokePosition == 1)
             {
                 if(color.a >= 1.0)
                 {
                     if(-distance < strokeSize / 2.0){
                         
                         float xpostion = -distance / strokeSize + 0.5;
                         if(strokeColorMode == 0){
                             desColor = vec4(strokeColor, strokeColorAlpha);
                         }else if(strokeColorMode == 1){
                             if(strokeGradientStyle > 1){
                                 desColor = gradientColorAtPositonSimple(xpostion, strokeGradientColor, strokeGradientColorAlpha);
                             }else{
                                 desColor = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                             }
                             desColor.a = desColor.a * strokeColorAlpha;
                         }
                     }
                 }else if(distance <= 0.0 || (distance > 0.0 && distance <= strokeSize / 2.0)){
                     float xpostion = distance / strokeSize + 0.5;
                     if(strokeColorMode == 0){
                         desColor = vec4(strokeColor, strokeColorAlpha);
                     }else if(strokeColorMode == 1){
                         if(strokeGradientStyle > 1){
                             desColor = gradientColorAtPositonSimple(xpostion, strokeGradientColor, strokeGradientColorAlpha);
                         }else{
                             desColor = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                         }
                         desColor.a = desColor.a * strokeColorAlpha;
                     }
                 }
                 
             }
             else if(strokePosition == 2)
                 {
                     if(distance <= 0.0)
                     {
                         if(color.a >= 1.0)
                         {
                             if(-distance < strokeSize){
                                 float xpostion = -distance / strokeSize;
                                 if(strokeColorMode == 0){
                                     desColor = vec4(strokeColor, strokeColorAlpha);
                                 }else if(strokeColorMode == 1){
                                     if(strokeGradientStyle > 1){
                                         desColor = gradientColorAtPositonSimple(xpostion, strokeGradientColor, strokeGradientColorAlpha);
                                     }else{
                                         desColor = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                                     }
                                     desColor.a = desColor.a * strokeColorAlpha;
                                 }
                                 
                             }else if(-distance < strokeSize + blur){
                                 vec4 c2 = desColor;
                                 vec4 c1;
//                                 c1.rgb = strokeColor;
//                                 c1.a = strokeColorAlpha * (1.0 - (-distance - strokeSize) / blur);
                                 
                                 if(strokeColorMode == 0){
                                     c1 = vec4(strokeColor, (1.0 - (-distance - strokeSize) / blur));
                                 }else if(strokeColorMode == 1){
                                     if(strokeGradientStyle > 1){
                                         c1 = gradientColorAtPositonSimple(1.0, strokeGradientColor, strokeGradientColorAlpha);
                                     }else{
                                         c1 = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                                     }
                                     c1.a = c1.a * (1.0 - (-distance - strokeSize) / blur);
                                 }
                                 
                                 desColor = mergeCom(c1, c2, strokeBlendMode, strokeColorAlpha);
                             }
                         }
                         else{
                             
                             float xpostion = -distance / strokeSize;
                             if(strokeColorMode == 0){
                                 desColor = vec4(strokeColor, color.a * strokeColorAlpha);
                             }else if(strokeColorMode == 1){
                                 if(strokeGradientStyle > 1){
                                     desColor = gradientColorAtPositonSimple(xpostion, strokeGradientColor, strokeGradientColorAlpha);
                                 }else{
                                     desColor = gradientColorAtPositon(imageRect, textureCoordinate, strokeGradientColor, strokeGradientColorAlpha, strokeGradientStyle, strokeGradientAngle, strokeGradientScaleRatio, center);
                                 }
                                 desColor.a = desColor.a * color.a * strokeColorAlpha;
                             }

                         }
                         
                     }
                 }
         
     }

     gl_FragColor = desColor; //
     
     
 }
 
 );



- (id)init
{
 /*   if (!(self = [super initWithFragmentShaderFromString:kGPUImageEffectFragmentShaderString]))
    {
        return nil;
    }
   */
    if(!(self = [super initWithVertexShaderFromString:kGPUImageEffectTextureVertexShaderString fragmentShaderFromString:kGPUImageEffectFragmentShaderString]))
    {
        return nil;
    }
    distanceMethodUniform = [filterProgram uniformIndex:@"distanceMethod"];
    //stroke
    strokeEnableUniform = [filterProgram uniformIndex:@"strokeEnable"];
    strokeSizeUniform = [filterProgram uniformIndex:@"strokeSize"];
    strokePositionUniform = [filterProgram uniformIndex:@"strokePosition"];
    strokeColorUniform = [filterProgram uniformIndex:@"strokeColor"];
    strokeColorAlphaUniform = [filterProgram uniformIndex:@"strokeColorAlpha"];
    strokeBlendModeUniform = [filterProgram uniformIndex:@"strokeBlendMode"];
    strokeColorModeUniform = [filterProgram uniformIndex:@"strokeColorMode"];
    strokeGradientColorUniform = [filterProgram uniformIndex:@"strokeGradientColor1"];
    strokeGradientColorAlphaUniform = [filterProgram uniformIndex:@"strokeGradientColorAlpha"];
    strokeGradientStyleUniform = [filterProgram uniformIndex:@"strokeGradientStyle"];
    strokeGradientAngleUniform = [filterProgram uniformIndex:@"strokeGradientAngle"];
    strokeGradientScaleRatioUniform = [filterProgram uniformIndex:@"strokeGradientScaleRatio"];
    
    self.distanceMethod = 0;
    self.strokeEnable = 0;
    self.strokeBlendMode = 0;
    self.strokeColorMode = 0;
    self.strokePosition = 0;
    self.strokeSize = 0.1;
    self.strokeColor = makeGPUVector3(0.0, 0.0, 0.0);
    self.strokeColorAlpha = 1.0;
    //GPUVectorLong test;
    //self.strokeGradientColor = test;
    
    //fill
    fillEnableUniform = [filterProgram uniformIndex:@"fillEnable"];
    fillBlendModeUniform = [filterProgram uniformIndex:@"fillBlendMode"];
    fillColorModeUniform = [filterProgram uniformIndex:@"fillColorMode"];
    fillColorUniform = [filterProgram uniformIndex:@"fillColor"];
    fillColorAlphaUniform = [filterProgram uniformIndex:@"fillColorAlpha"];
    fillGradientColorUniform = [filterProgram uniformIndex:@"fillGradientColor"];
    fillGradientColorAlphaUniform = [filterProgram uniformIndex:@"fillGradientColorAlpha"];
    fillGradientStyleUniform = [filterProgram uniformIndex:@"fillGradientStyle"];
    fillGradientAngleUniform = [filterProgram uniformIndex:@"fillGradientAngle"];
    fillGradientScaleRatioUniform = [filterProgram uniformIndex:@"fillGradientScaleRatio"];
    self.fillEnable = 0;
    self.fillBlendMode = 0;
    self.fillColorMode = 0;
    self.fillColor = makeGPUVector3(0.0, 0.0, 0.0);
    self.fillColorAlpha = 1.0;
    self.fillGradientStyle = 0;
    self.fillGradientScaleRatio = 1.0;
    self.fillGradientAngle = 0.0;
    
    
    
    //outerglow
    outerGlowEnableUniform = [filterProgram uniformIndex:@"outerGlowEnable"];
    outerGlowBlendModeUniform = [filterProgram uniformIndex:@"outerGlowBlendMode"];
    outerGlowColorModeUniform = [filterProgram uniformIndex:@"outerGlowColorMode"];
    outerGlowSizeUniform = [filterProgram uniformIndex:@"outerGlowSize"];
    outerGlowColorUniform = [filterProgram uniformIndex:@"outerGlowColor"];
    outerGlowColorAlphaUniform = [filterProgram uniformIndex:@"outerGlowColorAlpha"];
    outerGlowGradientColorUniform = [filterProgram uniformIndex:@"outerGlowGradientColor"];
    outerGlowGradientColorAlphaUniform = [filterProgram uniformIndex:@"outerGlowGradientColorAlpha"];
    self.outerGlowEnable = 0;
    self.outerGlowBlendMode = 0;
    self.outerGlowColorMode = 0;
    self.outerGlowColor = makeGPUVector3(0.0, 0.0, 0.0);
    self.outerGlowColorAlpha = 1.0;
    self.outerGlowSize = 1.0;
    
    
    //outerglow
    innerGlowEnableUniform = [filterProgram uniformIndex:@"innerGlowEnable"];
    innerGlowBlendModeUniform = [filterProgram uniformIndex:@"innerGlowBlendMode"];
    innerGlowColorModeUniform = [filterProgram uniformIndex:@"innerGlowColorMode"];
    innerGlowSizeUniform = [filterProgram uniformIndex:@"innerGlowSize"];
    innerGlowColorUniform = [filterProgram uniformIndex:@"innerGlowColor"];
    innerGlowColorAlphaUniform = [filterProgram uniformIndex:@"innerGlowColorAlpha"];
    innerGlowGradientColorUniform = [filterProgram uniformIndex:@"innerGlowGradientColor"];
    innerGlowGradientColorAlphaUniform = [filterProgram uniformIndex:@"innerGlowGradientColorAlpha"];
    self.innerGlowEnable = 0;
    self.innerGlowBlendMode = 0;
    self.innerGlowColorMode = 0;
    self.innerGlowColor = makeGPUVector3(0.0, 0.0, 0.0);
    self.innerGlowColorAlpha = 1.0;
    self.innerGlowSize = 1.0;
    
    
    distanceScaleUniform = [filterProgram uniformIndex:@"distanceScale"];
    self.distanceScale = 1.0;
    
    ulOffsetUniform = [filterProgram uniformIndex:@"ulOffset"];
    brOffsetUniform = [filterProgram uniformIndex:@"brOffset"];
    self.ulOffset = CGPointMake(0.0f, 0.0f);
    self.brOffset = CGPointMake(1.0f, 1.0f);
    
    imageRectUniform = [filterProgram uniformIndex:@"imageRect"];
    self.imageRect = makeGPUVector4(0.0, 0.0, 1.0, 1.0);
    
        
    return self;
}


#pragma mark -
#pragma mark stroke info

- (void)setDistanceMethod:(int)distanceMethod
{
    _distanceMethod = distanceMethod;
    [self setInteger:distanceMethod forUniform:distanceMethodUniform program:filterProgram];
}

- (void)setStrokeEnable:(int)strokeEnable
{
    _strokeEnable = strokeEnable;
    [self setInteger:_strokeEnable forUniform:strokeEnableUniform program:filterProgram];
}

- (void)setStrokeSize:(CGFloat)strokeSize
{
    _strokeSize = strokeSize;
    [self setFloat:_strokeSize forUniform:strokeSizeUniform program:filterProgram];
}

- (void)setStrokePosition:(int)strokePosition
{
    _strokePosition = strokePosition;
    [self setInteger:_strokePosition forUniform:strokePositionUniform program:filterProgram];
}

- (void)setStrokeColor:(GPUVector3)strokeColor
{
    _strokeColor = strokeColor;
    [self setVec3:_strokeColor forUniform:strokeColorUniform program:filterProgram];
}

- (void)setStrokeColorAlpha:(CGFloat)strokeColorAlpha
{
    _strokeColorAlpha = strokeColorAlpha;
    [self setFloat:_strokeColorAlpha forUniform:strokeColorAlphaUniform program:filterProgram];
}

- (void)setStrokeBlendMode:(int)strokeBlendMode
{
    _strokeBlendMode = strokeBlendMode;
    [self setInteger:_strokeBlendMode forUniform:strokeBlendModeUniform program:filterProgram];
}

- (void)setStrokeColorMode:(int)strokeColorMode
{
    _strokeColorMode = strokeColorMode;
    [self setInteger:_strokeColorMode forUniform:strokeColorModeUniform program:filterProgram];
}

- (void)setStrokeGradientStyle:(int)strokeGradientStyle
{
    _strokeGradientStyle = strokeGradientStyle;
    [self setInteger:_strokeGradientStyle forUniform:strokeGradientStyleUniform program:filterProgram];
}


- (void)setStrokeGradientColor:(GPUVectorLong)strokeGradientColor
{
    _strokeGradientColor = strokeGradientColor;
    int size = _strokeGradientColor.array[0];
    size = size * 4 + 1;
   
    [self setFloatArray:_strokeGradientColor.array length:size forUniform:strokeGradientColorUniform program:filterProgram];
}

- (void)setStrokeGradientColorAlpha:(GPUVectorLong)strokeGradientColorAlpha
{
    _strokeGradientColorAlpha = strokeGradientColorAlpha;
    int size = _strokeGradientColorAlpha.array[0];
    size = size * 2 + 1;
    [self setFloatArray:_strokeGradientColorAlpha.array length:size forUniform:strokeGradientColorAlphaUniform program:filterProgram];
}

- (void)setStrokeGradientAngle:(float)strokeGradientAngle
{
    _strokeGradientAngle = strokeGradientAngle;
    [self setFloat:_strokeGradientAngle forUniform:strokeGradientAngleUniform program:filterProgram];
}

- (void)setStrokeGradientScaleRatio:(float)strokeGradientScaleRatio
{
    _strokeGradientScaleRatio = strokeGradientScaleRatio;
    [self setFloat:_strokeGradientScaleRatio forUniform:strokeGradientScaleRatioUniform program:filterProgram];
}


#pragma mark -
#pragma mark fill info

- (void)setFillEnable:(int)fillEnable
{
    _fillEnable = fillEnable;
    [self setInteger:_fillEnable forUniform:fillEnableUniform program:filterProgram];
}

- (void)setFillBlendMode:(int)fillBlendMode
{
    _fillBlendMode = fillBlendMode;
    [self setInteger:_fillBlendMode forUniform:fillBlendModeUniform program:filterProgram];
}


- (void)setFillColor:(GPUVector3)fillColor
{
    _fillColor = fillColor;
    [self setVec3:_fillColor forUniform:fillColorUniform program:filterProgram];
}

- (void)setFillColorAlpha:(CGFloat)fillColorAlpha
{
    _fillColorAlpha = fillColorAlpha;
    [self setFloat:_fillColorAlpha forUniform:fillColorAlphaUniform program:filterProgram];
}

- (void)setFillColorMode:(int)fillColorMode
{
    _fillColorMode = fillColorMode;
    [self setInteger:_fillColorMode forUniform:fillColorModeUniform program:filterProgram];
}

- (void)setFillGradientStyle:(int)fillGradientStyle
{
    _fillGradientStyle = fillGradientStyle;
    [self setInteger:_fillGradientStyle forUniform:fillGradientStyleUniform program:filterProgram];
}


- (void)setFillGradientColor:(GPUVectorLong)fillGradientColor
{
    _fillGradientColor = fillGradientColor;
    int size = _fillGradientColor.array[0];
    size = size * 4 + 1;
    [self setFloatArray:_fillGradientColor.array length:size forUniform:fillGradientColorUniform program:filterProgram];
}

- (void)setFillGradientColorAlpha:(GPUVectorLong)fillGradientColorAlpha
{
    _fillGradientColorAlpha = fillGradientColorAlpha;
    int size = _fillGradientColorAlpha.array[0];
    size = size * 2 + 1;
    [self setFloatArray:_fillGradientColorAlpha.array length:size forUniform:fillGradientColorAlphaUniform program:filterProgram];
}

- (void)setFillGradientAngle:(float)fillGradientAngle
{
    _fillGradientAngle = fillGradientAngle;
    [self setFloat:_fillGradientAngle forUniform:fillGradientAngleUniform program:filterProgram];
}

- (void)setFillGradientScaleRatio:(float)fillGradientScaleRatio
{
    _fillGradientScaleRatio = fillGradientScaleRatio;
    [self setFloat:_fillGradientScaleRatio forUniform:fillGradientScaleRatioUniform program:filterProgram];
}


#pragma mark -
#pragma mark outerglow info

- (void)setOuterGlowEnable:(int)outerGlowEnable
{
    _outerGlowEnable = outerGlowEnable;
    [self setInteger:_outerGlowEnable forUniform:outerGlowEnableUniform program:filterProgram];
}

- (void)setOuterGlowBlendMode:(int)outerGlowBlendMode
{
    _outerGlowBlendMode = outerGlowBlendMode;
    [self setInteger:_outerGlowBlendMode forUniform:outerGlowBlendModeUniform program:filterProgram];
}

- (void)setOuterGlowColorMode:(int)outerGlowColorMode
{
    _outerGlowColorMode = outerGlowColorMode;
    [self setInteger:_outerGlowColorMode forUniform:outerGlowColorModeUniform program:filterProgram];
}

- (void)setOuterGlowColor:(GPUVector3)outerGlowColor
{
    _outerGlowColor = outerGlowColor;
    [self setVec3:_outerGlowColor forUniform:outerGlowColorUniform program:filterProgram];
}

- (void)setOuterGlowColorAlpha:(CGFloat)outerGlowColorAlpha
{
    _outerGlowColorAlpha = outerGlowColorAlpha;
    [self setFloat:_outerGlowColorAlpha forUniform:outerGlowColorAlphaUniform program:filterProgram];
}

- (void)setOuterGlowSize:(CGFloat)outerGlowSize
{
    _outerGlowSize = outerGlowSize;
    [self setFloat:_outerGlowSize forUniform:outerGlowSizeUniform program:filterProgram];
}

- (void)setOuterGlowGradientColor:(GPUVectorLong)outerGlowGradientColor
{
    _outerGlowGradientColor = outerGlowGradientColor;
    int size = _outerGlowGradientColor.array[0];
    size = size * 4 + 1;
    [self setFloatArray:_outerGlowGradientColor.array length:size forUniform:outerGlowGradientColorUniform program:filterProgram];
}

- (void)setOuterGlowGradientColorAlpha:(GPUVectorLong)outerGlowGradientColorAlpha
{
    _outerGlowGradientColorAlpha = outerGlowGradientColorAlpha;
    int size = _outerGlowGradientColorAlpha.array[0];
    size = size * 2 + 1;
    [self setFloatArray:_outerGlowGradientColorAlpha.array length:size forUniform:outerGlowGradientColorAlphaUniform program:filterProgram];
}

#pragma mark -
#pragma mark innerglow info

- (void)setInnerGlowEnable:(int)innerGlowEnable
{
    _innerGlowEnable = innerGlowEnable;
    [self setInteger:_innerGlowEnable forUniform:innerGlowEnableUniform program:filterProgram];
}

- (void)setInnerGlowBlendMode:(int)innerGlowBlendMode
{
    _innerGlowBlendMode = innerGlowBlendMode;
    [self setInteger:_innerGlowBlendMode forUniform:innerGlowBlendModeUniform program:filterProgram];
}

- (void)setInnerGlowColorMode:(int)innerGlowColorMode
{
    _innerGlowColorMode = innerGlowColorMode;
    [self setInteger:_innerGlowColorMode forUniform:innerGlowColorModeUniform program:filterProgram];
}

- (void)setInnerGlowColor:(GPUVector3)innerGlowColor
{
    _innerGlowColor = innerGlowColor;
    [self setVec3:_innerGlowColor forUniform:innerGlowColorUniform program:filterProgram];
}

- (void)setInnerGlowColorAlpha:(CGFloat)innerGlowColorAlpha
{
    _innerGlowColorAlpha = innerGlowColorAlpha;
    [self setFloat:_innerGlowColorAlpha forUniform:innerGlowColorAlphaUniform program:filterProgram];
}

- (void)setInnerGlowSize:(CGFloat)innerGlowSize
{
    _innerGlowSize = innerGlowSize;
    [self setFloat:_innerGlowSize forUniform:innerGlowSizeUniform program:filterProgram];
}

- (void)setInnerGlowGradientColor:(GPUVectorLong)innerGlowGradientColor
{
    _innerGlowGradientColor = innerGlowGradientColor;
    int size = _innerGlowGradientColor.array[0];
    size = size * 4 + 1;
    [self setFloatArray:_innerGlowGradientColor.array length:size forUniform:innerGlowGradientColorUniform program:filterProgram];
}

- (void)setInnerGlowGradientColorAlpha:(GPUVectorLong)innerGlowGradientColorAlpha
{
    _innerGlowGradientColorAlpha = innerGlowGradientColorAlpha;
    int size = _innerGlowGradientColorAlpha.array[0];
    size = size * 2 + 1;
    [self setFloatArray:_innerGlowGradientColorAlpha.array length:size forUniform:innerGlowGradientColorAlphaUniform program:filterProgram];
}


#pragma mark -
#pragma mark scale 

- (void)setDistanceScale:(CGFloat)distanceScale
{
    _distanceScale = distanceScale;
    [self setFloat:_distanceScale forUniform:distanceScaleUniform program:filterProgram];
}

- (BOOL)getFilterIsValid
{
    if (_strokeEnable || _fillEnable || _outerGlowEnable || _innerGlowEnable) {
        return YES;
    }
    return NO;
}

- (void)setUlOffset:(CGPoint)ulOffset
{
    _ulOffset = ulOffset;
    [self setPoint:_ulOffset forUniform:ulOffsetUniform program:filterProgram];
}

- (void)setBrOffset:(CGPoint)brOffset
{
    _brOffset = brOffset;
    [self setPoint:_brOffset forUniform:brOffsetUniform program:filterProgram];
}

- (void)setImageRect:(GPUVector4)imageRect
{
    _imageRect = imageRect;
    [self setVec4:_imageRect forUniform:imageRectUniform program:filterProgram];
}

@end
