//
//  PSGradientButton.h
//  PixelStyle
//
//  Created by lchzh on 5/18/16.
//
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    GRADIENT_STYLE_LINEAR = 0,
    GRADIENT_STYLE_RADIAL = 1,
    
}GRADIENT_STYLE;



typedef struct
{
    float  colorInfo[100]; //20*4+1
    float  colorAlphaInfo[50];
}GRADIENT_COLOR;

typedef struct
{
    GRADIENT_COLOR color;
    GRADIENT_STYLE style;
    float angle;
    float scaleRatio;
    
}GRADIENT_INFO;

@interface PSGradientButton : NSButton

@property (readwrite, nonatomic) GRADIENT_COLOR gradientColor;

@end
