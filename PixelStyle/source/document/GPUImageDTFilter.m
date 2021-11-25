//
//  GPUImageDTFilter.m
//  PixelStyle
//
//  Created by wzq on 10/8/16.
//
//

#import "GPUImageDTFilter.h"


//外部点 初始化  0.50 0.50  0.0  0.0
//外部点 zw 永远为 0.0 0.0
//外部点不能被未经初始化的外部点替换



//内部点  0.0  0.0  0.50 0.50
//内部点 xy 永远为 0.0 0.0
//内部点不能被未经初始化的内部点替换

@implementation GPUImageResample


NSString *const kGPUImageResampleFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main ()
 {
     vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = color;
 }
 );


- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageResampleFragmentShaderString]) )
    {
        return nil;
    }
    
    return self;
}

@end

@implementation GPUImageDTInitFilter


NSString *const kGPUImageDTInitFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main ()
 {
     vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     if(color.a > 0.0)
     {
         color.r = 0.0;
         color.g = 0.0;
         color.b = 0.5;
         color.a = 0.5;
     }
     else
     {
         color.r = 0.5;
         color.g = 0.5;
         color.b = 0.0;
         color.a = 0.0;
     }

     gl_FragColor = color;//vec4( color.rgb, color.a);
 }
 );


- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageDTInitFragmentShaderString]) )
    {
        return nil;
    }
    
    return self;
}

@end



@implementation GPUImageDTItemFilter
NSString *const kGPUImageDTItemFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
// uniform int radiusJumpX;
// uniform int width;
// uniform int radiusJumpY;
// uniform int height;
 uniform vec4 paraM;
 
 
 
 
 float testCandidate(in vec2 stepvec, inout vec2 result, float fDist, int pointToProcessIn, vec2  _scaleInv)
 {
     vec4 toCompare = texture2D(inputImageTexture, textureCoordinate + stepvec);
     vec2 toCompareXY;
     
     if(pointToProcessIn == 1)
     {
         if((toCompare.x < 0.0001 && toCompare.y < 0.0001)) //内部点
         {
             if((toCompare.z > 0.49 && toCompare.z < 0.51) && (toCompare.w > 0.49 && toCompare.w < 0.51)) return fDist;  //不能替换成未经初始化的内部点
             
         }
         toCompareXY = toCompare.zw;
     }
     else
     {
         if((toCompare.z < 0.0001 && toCompare.w < 0.0001)) //外部点
         {
             if((toCompare.x > 0.49 && toCompare.x < 0.51) && (toCompare.y > 0.49 && toCompare.y < 0.51)) return fDist; //不能替换成未经初始化的内部点
             
         }
         toCompareXY = toCompare.xy;
     }
     
   
   //  if(!(toCompare.a > 0.0)) return fDist;
     
     if(toCompareXY.x > 0.5)  toCompareXY.x = toCompareXY.x - 1.0;
     if(toCompareXY.y > 0.5)  toCompareXY.y = toCompareXY.y - 1.0;
     
     toCompareXY.x *= _scaleInv.x;
     toCompareXY.y *= _scaleInv.y;
     
     vec2 offset = toCompareXY + stepvec;
    // toCompare.xy = toCompare.xy + textureCoordinate + stepvec;
     
     float aspect = paraM.w;
     float fDist2 = offset.x*offset.x*aspect*aspect + offset.y*offset.y;
     
     if(fDist > fDist2)
     {
         result = offset;
         fDist = fDist2;
     }
     
     return fDist;
 }
 
 // 最大偏移支持 －0.49 0.49
 // 0.5 0.5 z w  z,w< 0.49 | z,w>0.51  内部点
 // x y    0.5 0.5  x,y< 0.49 | x,y>0.51  外部点
 
 void main ()
 {
     vec2  _scale;
     vec2  _scaleInv;
     float aspect = paraM.w;
     
     vec4 currentMap   = texture2D(inputImageTexture, textureCoordinate);
     float radiusJumpX = paraM.x;
     float radiusJumpY = paraM.y;
     
//     oneu->1.0/256.0
     _scale.x = 1.0/(256.0*paraM.z);
     _scale.y = 1.0/(256.0*paraM.z);
     _scaleInv.x = 256.0*paraM.z;
     _scaleInv.y = 256.0*paraM.z;
     
   //  radiusJumpX = (float)((int)(radiusJumpX/paraM.z)) * paraM.z;

     float fDist;
     int pointToProcessIn = 0;
     
     if((currentMap.x < 0.0001 && currentMap.y < 0.0001))
         pointToProcessIn =1;
     
     vec2 currentOffset;

     if(pointToProcessIn == 0)
     {
         currentOffset = currentMap.xy;
     }
     else
     {
         currentOffset = currentMap.zw;
     }
     
     if((currentOffset.x > 0.49 && currentOffset.x < 0.51) && (currentOffset.y > 0.49 && currentOffset.y < 0.51))
         fDist = 1.1;
     else
     {
         if(currentOffset.x > 0.5)  currentOffset.x = currentOffset.x - 1.0;
         if(currentOffset.y > 0.5)  currentOffset.y = currentOffset.y - 1.0;
     
         currentOffset.x *= _scaleInv.x;
         currentOffset.y *= _scaleInv.y;
         
         fDist = currentOffset.x*currentOffset.x*aspect*aspect + currentOffset.y*currentOffset.y;
     }
     
      vec2 result = currentOffset;
     
     if(fDist > 0.0001  )
     {
         
             if(textureCoordinate.x - radiusJumpX >0.0)
             {
                 fDist = testCandidate(vec2(-radiusJumpX, 0.0), result, fDist, pointToProcessIn, _scaleInv);
             }
  
    
             if(textureCoordinate.x + radiusJumpX <1.0)
             {
                 fDist = testCandidate(vec2(radiusJumpX, 0.0), result, fDist, pointToProcessIn, _scaleInv);
             }

             
             if(textureCoordinate.y - radiusJumpY >0.0)
             {
                fDist = testCandidate(vec2(0.0, - radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
             }
             
             if(textureCoordinate.y + radiusJumpY <1.0)
             {
                 fDist = testCandidate(vec2(0.0, radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
             }
         //     else
             if(textureCoordinate.x - radiusJumpX >0.0 && textureCoordinate.y - radiusJumpY >0.0)
             {
                 fDist = testCandidate(vec2(-radiusJumpX, -radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
             }
             
             if( textureCoordinate.x + radiusJumpX < 1.0 && textureCoordinate.y - radiusJumpY >0.0)
             {
                 fDist = testCandidate(vec2(radiusJumpX, -radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
             }
             
             if(textureCoordinate.x - radiusJumpX >0.0 &&  textureCoordinate.y + radiusJumpY < 1.0)
             {
                 fDist = testCandidate(vec2(-radiusJumpX, radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
                 
             }
         
             if(textureCoordinate.x + radiusJumpX < 1.0 && textureCoordinate.y + radiusJumpY < 1.0)
             {
                 fDist = testCandidate(vec2(radiusJumpX, radiusJumpY), result, fDist, pointToProcessIn, _scaleInv);
             }
     }
   
     
 //    vec2 offsetXY = result;// - textureCoordinate;
     //在大图中128范围的 u v 对应值变成很小，如 宽10000的  128 对应 128.0/10000.0
     //这样转成 gl_FragColor使用unsigned char存储会丢失精度，乘以一定的系数放大
     
     result.x *= _scale.x;
     result.y *= _scale.y;
     
     if(fDist > 1.0 || result.x > 0.47 || result.y> 0.47 || result.x < -0.47 || result.y < -0.47 )
         gl_FragColor = currentMap;
     else
     {
       //  result.x = 0.2* paraM.z;
         if(result.x < 0.0)
             result.x = 1.0 + result.x;

         if(result.y < 0.0)
             result.y = 1.0 + result.y;

         
         if(pointToProcessIn == 0)
             gl_FragColor = vec4(result, currentMap.zw);
         else
             gl_FragColor = vec4(currentMap.xy, result);
     }
 
 }
 );
@synthesize paraM;


- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageDTItemFragmentShaderString]) )
    {
        return nil;
    }
    
    _paraMUniform  = [filterProgram uniformIndex:@"paraM"];

    
    return self;
}

- (void)setParaM:(GPUVector4)paraM
{
    [self setVec4:paraM forUniform:_paraMUniform program:filterProgram];
}


@end




@implementation GPUImageDTOutFilter

NSString *const kGPUImageDTOutFragmentShaderString_old = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 paraM;
 
 void main ()
 {
     vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     vec2 offset = color.xy;
     int pointToProcessIn = 0;
     
     if(color.x < 0.0001 && color.y < 0.0001)
     {
         offset = color.zw;
         pointToProcessIn = 1;
     }
     
     if(offset.x > 0.5)  offset.x = offset.x - 1.0;
     if(offset.y > 0.5)  offset.y = offset.y - 1.0;
     // vec2 offset = color.xy;
     
     //  color.xy = color.xy + textureCoordinate;
     
     float fDist = length(offset);
     
     if(pointToProcessIn == 0)
         gl_FragColor = vec4(fDist, paraM.z, paraM.w, 0.0);
     else
         gl_FragColor = vec4(fDist, paraM.z,  paraM.w, 1.0);
     
 }
 );

NSString *const kGPUImageDTOutFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 paraM;
 
 void main ()
 {
     vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     vec2 offset = color.xy;
     int pointToProcessIn = 0;
     
     if(color.x < 0.0001 && color.y < 0.0001)
     {
         offset = color.zw;
         pointToProcessIn = 1;
     }
     
 //    if(offset.x > 0.5)  offset.x = offset.x - 1.0;
 //    if(offset.y > 0.5)  offset.y = offset.y - 1.0;
     // vec2 offset = color.xy;
     
     //  color.xy = color.xy + textureCoordinate;
     
  //   float fDist = length(offset);
     
     if(pointToProcessIn == 0)
         gl_FragColor = vec4(offset, paraM.z, paraM.w);
     else
         gl_FragColor = vec4(offset, paraM.z,  paraM.w);
     
 }
 );


- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageDTOutFragmentShaderString]) )
    {
        return nil;
    }
    
    _paraMUniform  = [filterProgram uniformIndex:@"paraM"];
    
    return self;
}

- (void)setParaM:(GPUVector4)paraM
{
    [self setVec4:paraM forUniform:_paraMUniform program:filterProgram];
}

@end



@implementation GPUImageDTFilter

#define NTIMES 9
-(id)initWithWidth:(int)width height:(int)height
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    GPUImageDTInitFilter *dtInitFilter = [[GPUImageDTInitFilter alloc] init];
    GPUTextureOptions outputTextureOptions = dtInitFilter.outputTextureOptions;
    outputTextureOptions.minFilter = GL_NEAREST;
    outputTextureOptions.magFilter = GL_NEAREST;
    // outputTextureOptions.type = GL_UNSIGNED_SHORT;
    dtInitFilter.outputTextureOptions = outputTextureOptions;
    
    [self addFilter:dtInitFilter];
    
    int nIndex = 0;
    GPUImageDTItemFilter *dtItemFilter[NTIMES];
    int nStep = 50; //偏移量最小，最大为  -127 128 存储在unsigned char中
    
    do{
        dtItemFilter[nIndex] = [[GPUImageDTItemFilter alloc] init];
        outputTextureOptions = dtItemFilter[nIndex].outputTextureOptions;
        outputTextureOptions.minFilter = GL_NEAREST;
        outputTextureOptions.magFilter = GL_NEAREST;
     //   outputTextureOptions.internalFormat = GL_RGBA16;  // mac mini does not supprot it converted to GL_RGB8 automatically
     //       outputTextureOptions.type = GL_UNSIGNED_SHORT;//GL_UNSIGNED_BYTE;
        dtItemFilter[nIndex].outputTextureOptions = outputTextureOptions;
        
        GPUVector4 vecParaM;
        vecParaM.one = (float)nStep/(float)256.0;
        vecParaM.two = (float)nStep/(float)256.0;//height;
        vecParaM.three = 1.0/(float)256.0;//(float)width/128.0;
        vecParaM.four = (float)width/height;//(float)height/128.0;  //aspect ratio
        
        dtItemFilter[nIndex].paraM = vecParaM;
       nStep /= 2;
        
        [self addFilter:dtItemFilter[nIndex]];
        
        if(nIndex == 0)
            [dtInitFilter addTarget:dtItemFilter[0]];
        else
            [dtItemFilter[nIndex -1] addTarget:dtItemFilter[nIndex]];
        nIndex++;
        
    }while(nIndex < NTIMES);
    
    GPUImageDTOutFilter *dtOutFilter = [[GPUImageDTOutFilter alloc] init];
    outputTextureOptions = dtOutFilter.outputTextureOptions;
    outputTextureOptions.minFilter = GL_NEAREST;
    outputTextureOptions.magFilter = GL_NEAREST;
  //  outputTextureOptions.internalFormat = GL_RGBA16;
  //  outputTextureOptions.type = GL_UNSIGNED_SHORT;//GL_UNSIGNED_BYTE;
 //   dtOutFilter.outputTextureOptions = outputTextureOptions;
    
    GPUVector4 vecParaM;
    
    vecParaM.one = (float)64/(float)width;
    vecParaM.two = (float)64/(float)height;
    vecParaM.three = 256.0/(float)width;//(float)width/1024.0;//128.0/1024.0;//(float)width;
    vecParaM.four =  256.0/(float)height;//128.0/1024.0;//(float)height;
    dtOutFilter.paraM = vecParaM;
    
    [self addFilter:dtOutFilter];
    
    //  [dtInitFilter addTarget:dtOutFilter];
    [dtItemFilter[NTIMES -1] addTarget:dtOutFilter];
    
    self.initialFilters = [NSArray arrayWithObject:dtInitFilter];
    self.terminalFilter = dtOutFilter;
    
    return self;
}

- (void)dealloc
{
    for(NSUInteger i=0; i< [self filterCount]; i++)
    {
        GPUImageOutput *filter = [self filterAtIndex:i];
        [filter release];
    }

    [super dealloc];
    
    
}

@end


