//
//  GPUImageChannelFilter.h
//  PixelStyle
//
//  Created by lchzh on 11/12/15.
//
//

#import <GPUImage/GPUImage.h>

@interface GPUImageChannelFilter : GPUImageFilter
{
    GLint redVisibleUniform;
    GLint greenVisibleUniform;
    GLint blueVisibleUniform;
    GLint alphaVisibleUniform;
}



@property (readwrite, nonatomic) int redVisible;
@property (readwrite, nonatomic) int greenVisible;
@property (readwrite, nonatomic) int blueVisible;
@property (readwrite, nonatomic) int alphaVisible;


@end
