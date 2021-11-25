//
//  GPUImageChannelFilter.m
//  PixelStyle
//
//  Created by lchzh on 11/12/15.
//
//

#import "GPUImageChannelFilter.h"

@implementation GPUImageChannelFilter

@synthesize redVisible = _redVisible;
@synthesize greenVisible = _greenVisible;
@synthesize blueVisible = _blueVisible;
@synthesize alphaVisible = _alphaVisible;


NSString *const kGPUImageChannelFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 
 //channel
 uniform int redVisible;
 uniform int greenVisible;
 uniform int blueVisible;
 uniform int alphaVisible;
 
 
 void main()
 {
     vec4 color = texture2D(inputImageTexture,  textureCoordinate);
     vec4 desColor = color;
     if(redVisible == 1 && greenVisible == 0 && blueVisible == 0)
     {
         desColor.rgb = vec3(color.r, color.r, color.r);
     }else if(redVisible == 0 && greenVisible == 1 && blueVisible == 0){
         desColor.rgb = vec3(color.g, color.g, color.g);
     }else if(redVisible == 0 && greenVisible == 0 && blueVisible == 1){
         desColor.rgb = vec3(color.b, color.b, color.b);
     }else if(redVisible == 1 && greenVisible == 1 && blueVisible == 0){
         desColor.b = 0.0;
     }else if(redVisible == 1 && greenVisible == 0 && blueVisible == 1){
         desColor.g = 0.0;
     }else if(redVisible == 0 && greenVisible == 1 && blueVisible == 1){
         desColor.r = 0.0;
     }
     
     
     
     gl_FragColor = desColor;
     
     
 }
 
 );



- (id)init
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageChannelFragmentShaderString]))
    {
        return nil;
    }
    
    //channel
    redVisibleUniform = [filterProgram uniformIndex:@"redVisible"];
    greenVisibleUniform = [filterProgram uniformIndex:@"greenVisible"];
    blueVisibleUniform = [filterProgram uniformIndex:@"blueVisible"];
    alphaVisibleUniform = [filterProgram uniformIndex:@"alphaVisible"];
    self.redVisible = 1;
    self.greenVisible = 1;
    self.blueVisible = 1;
    self.alphaVisible = 1;
    
    
    return self;
}


#pragma mark -
#pragma mark channel info
- (void)setRedVisible:(int)redVisible
{
    _redVisible = redVisible;
    [self setInteger:_redVisible forUniform:redVisibleUniform program:filterProgram];
}
- (void)setGreenVisible:(int)greenVisible
{
    _greenVisible = greenVisible;
    [self setInteger:_greenVisible forUniform:greenVisibleUniform program:filterProgram];
}
- (void)setBlueVisible:(int)blueVisible
{
    _blueVisible = blueVisible;
    [self setInteger:_blueVisible forUniform:blueVisibleUniform program:filterProgram];
}
- (void)setAlphaVisible:(int)alphaVisible
{
    _alphaVisible = alphaVisible;
    [self setInteger:_alphaVisible forUniform:alphaVisibleUniform program:filterProgram];
}

- (BOOL)getFilterIsValid
{
    if (_redVisible && _greenVisible && _blueVisible && _alphaVisible) {
        return NO;
    }
    return YES;
}


@end
