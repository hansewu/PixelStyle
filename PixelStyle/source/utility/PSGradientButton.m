//
//  PSGradientButton.m
//  PixelStyle
//
//  Created by lchzh on 5/18/16.
//
//

#import "PSGradientButton.h"

@implementation PSGradientButton

@synthesize gradientColor = _gradientColor;

- (void)drawRect:(NSRect)dirtyRect {
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    NSRect bounds = self.bounds;
    
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(bounds.size.width, bounds.size.height)] autorelease];
    [image lockFocus];
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"checkerboard1"]] set];
    NSRectFill(NSMakeRect(0, 0, bounds.size.width, bounds.size.height));
    [image unlockFocus];
    
    [image drawInRect:bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
    
    int count = bounds.size.width;
    for (int i = 0; i < count; i++) {
        float fi = i;
        NSColor *color = [self getColorAtPosition: fi / count];
        [color set];
        NSRect verRect = NSMakeRect(fi / count * bounds.size.width, 0, bounds.size.width / count, bounds.size.height);
        CGContextFillRect(context, verRect);
    }
    
    CGContextRestoreGState(context);
}

- (NSColor*)getColorAtPosition:(float)position
{
    int colorCount = (int)_gradientColor.colorInfo[0];
    int alphaCount = (int)_gradientColor.colorAlphaInfo[0];
    
    float red = 0.0;
    float green = 0.0;
    float blue = 0.0;
    float alpha = 0.0;
    
    if (colorCount >= 2) {
        if(position <= _gradientColor.colorInfo[4]){
            red = _gradientColor.colorInfo[1];
            green = _gradientColor.colorInfo[2];
            blue = _gradientColor.colorInfo[3];
        }else if(position >= _gradientColor.colorInfo[(colorCount - 1) * 4 + 4]){
            red = _gradientColor.colorInfo[(colorCount - 1) * 4 + 1];
            green = _gradientColor.colorInfo[(colorCount - 1) * 4 + 2];
            blue = _gradientColor.colorInfo[(colorCount - 1) * 4 + 3];
            
        }else{
            for (int i = 0; i < colorCount - 1; i++)
            {
                if(position >= _gradientColor.colorInfo[i * 4 + 4] && position <= _gradientColor.colorInfo[(i + 1) * 4 + 4])
                {
                    float pos = (position - _gradientColor.colorInfo[i * 4 + 4]) / (_gradientColor.colorInfo[(i + 1) * 4 + 4] - _gradientColor.colorInfo[i * 4 + 4]);
                    red = _gradientColor.colorInfo[i * 4 + 1] * (1.0 - pos) + _gradientColor.colorInfo[(i + 1) * 4 + 1] * pos;
                    green = _gradientColor.colorInfo[i * 4 + 2] * (1.0 - pos) + _gradientColor.colorInfo[(i + 1) * 4 + 2] * pos;
                    blue = _gradientColor.colorInfo[i * 4 + 3] * (1.0 - pos) + _gradientColor.colorInfo[(i + 1) * 4 + 3] * pos;
                    break;
                }
            }
        }

    }
    else if (colorCount == 1)
    {
        red = _gradientColor.colorInfo[1];
        green = _gradientColor.colorInfo[2];
        blue = _gradientColor.colorInfo[3];
        
    }
    
    if (alphaCount >= 2) {
        if(position <= _gradientColor.colorAlphaInfo[2]){
            alpha = _gradientColor.colorAlphaInfo[1];
        }else if(position >= _gradientColor.colorAlphaInfo[(alphaCount - 1) * 2 + 2]){
            alpha = _gradientColor.colorAlphaInfo[(alphaCount - 1) * 2 + 1];
            
        }else{
            for (int i = 0; i < alphaCount - 1; i++)
            {
                if(position >= _gradientColor.colorAlphaInfo[i * 2 + 2] && position <= _gradientColor.colorAlphaInfo[(i + 1) * 2 + 2])
                {
                    float pos = (position - _gradientColor.colorAlphaInfo[i * 2 + 2]) / (_gradientColor.colorAlphaInfo[(i + 1) * 2 + 2] - _gradientColor.colorAlphaInfo[i * 2 + 2]);
                    alpha = _gradientColor.colorAlphaInfo[i * 2 + 1] * (1.0 - pos) + _gradientColor.colorAlphaInfo[(i + 1) * 2 + 1] * pos;
                    break;
                }
            }
        }
    }else if (alphaCount == 1)
    {
        alpha = _gradientColor.colorAlphaInfo[1];        
    }
    
    return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
    
}

- (void)setGradientColor:(GRADIENT_COLOR)gradientColor
{
    _gradientColor = gradientColor;
    [self setNeedsDisplay:YES];
    
}


@end
