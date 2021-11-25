//
//  PSHistogramDrawView.m
//  PixelStyle
//
//  Created by lchzh on 4/11/15.
//
//

#import "PSHistogramDrawView.h"

@implementation PSHistogramDrawView


- (void)setCustomDelegate:(id)delegate
{
    m_idDelegate = delegate;
}

- (void)awakeFromNib
{
    CGColorRef backColor = CGColorCreateGenericRGB(0.1, 0.1, 0.1, 1.0);
    [self.layer setBackgroundColor:backColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSRect bounds = self.bounds;
    NSBezierPath *outPath = [NSBezierPath bezierPathWithRect:bounds];
    //[outPath closePath];
    [[NSColor blackColor] set];
    [outPath stroke];
    
    
    int index = [m_idDelegate getSelectedColorIndex];
    if (index == 0) {
        unsigned char *hitogramInfo = [m_idDelegate getRGBHistogramInfo];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path setLineWidth:1.0];
        [[NSColor redColor] set];
        [path moveToPoint:NSMakePoint(1.0, (float)hitogramInfo[0] / 255.0 * bounds.size.height)];
        for (int i = 1; i < 256; i++) {
            [path lineToPoint:NSMakePoint(1.0 + (float)i / 255.0 * (bounds.size.width - 2.0), (float)hitogramInfo[i] / 255.0 * bounds.size.height)];
        }
        [path stroke];
        
        path = [NSBezierPath bezierPath];
        [path setLineWidth:1.0];
        [[NSColor greenColor] set];
        [path moveToPoint:NSMakePoint(1.0, (float)hitogramInfo[256] / 255.0 * bounds.size.height)];
        for (int i = 257; i < 512; i++) {
            [path lineToPoint:NSMakePoint(1.0 + (float)(i - 256) / 255.0 * (bounds.size.width - 2.0), (float)hitogramInfo[i] / 255.0 * bounds.size.height)];
        }
        [path stroke];
        
        path = [NSBezierPath bezierPath];
        [path setLineWidth:1.0];
        [[NSColor blueColor] set];
        [path moveToPoint:NSMakePoint(1.0, (float)hitogramInfo[512] / 255.0 * bounds.size.height)];
        for (int i = 513; i < 768; i++) {
            [path lineToPoint:NSMakePoint(1.0 + (float)(i - 512) / 255.0 * (bounds.size.width - 2.0), (float)hitogramInfo[i] / 255.0 * bounds.size.height)];
        }
        [path stroke];
        
        
    }else{
        unsigned char *hitogramInfo = [m_idDelegate getGrayHistogramInfo];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path setLineWidth:1.0];
        switch (index) {
            case 1:
                [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.8] set];
                break;
            case 2:
                [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.8] set];
                break;
            case 3:
                [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.8] set];
                break;
            case 4:
                [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.8] set];
                break;
                
            default:
                break;
        }
        for (int i = 0; i < 256; i++) {
            [path moveToPoint:NSMakePoint(1.0 + (float)i / 255.0 * (bounds.size.width - 2.0), 0)];
            [path lineToPoint:NSMakePoint(1.0 + (float)i / 255.0 * (bounds.size.width - 2.0), (float)hitogramInfo[i] / 255.0 * bounds.size.height)];
        }
        [path stroke];
    }
    

}

@end
