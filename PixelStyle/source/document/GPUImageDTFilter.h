//
//  GPUImageDTFilter.h
//  PixelStyle
//
//  Created by wzq on 10/8/16.
//
//

#import <GPUImage/GPUImage.h>

@interface GPUImageResample : GPUImageFilter

@end

@interface GPUImageDTInitFilter : GPUImageFilter

@end



@interface GPUImageDTItemFilter : GPUImageFilter
{
    GLint _paraMUniform;
 //   GLint radiusJumpUniformX;
//    GLint widthUniform;
//    
//    GLint radiusJumpUniformY;
//    GLint heightUniform;

}
@property (nonatomic, readwrite) GPUVector4 paraM;
//@property (nonatomic, readwrite) int radiusJumpX;
//@property (nonatomic, readwrite) int width;
//@property (nonatomic, readwrite) int radiusJumpY;
//@property (nonatomic, readwrite) int height;
@end

@interface GPUImageDTFilter : GPUImageFilterGroup
{
}

-(id)initWithWidth:(int)width height:(int)height;
@end

@interface GPUImageDTOutFilter : GPUImageFilter
{
    GLint _paraMUniform;
}
@property (nonatomic, readwrite) GPUVector4 paraM;

@end
