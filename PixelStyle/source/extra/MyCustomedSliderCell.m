//
//  MyCustomedSlider.m
//  Super Denoiser
//
//  Created by lchzh on 26/6/15.
//
//

#import "MyCustomedSliderCell.h"

@implementation MyCustomedSliderCell

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//    
//    // Drawing code here.
//}

- (void)drawKnob:(NSRect)knobRect
{
    CGImageRef imageRef = [[NSImage imageNamed:@"slider-thumb"] CGImageForProposedRect:nil context:nil hints:nil];
    assert(imageRef);
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(context, knobRect, imageRef);
}

- (void)drawBarInside:(NSRect)rect flipped:(BOOL)flipped {
    
    //[super drawBarInside:rect flipped:flipped];
    
//    rect.size.height = 5.0;
//    
//    SInt32 versMaj, versMin, versBugFix;
//    Gestalt(gestaltSystemVersionMajor, &versMaj);
//    Gestalt(gestaltSystemVersionMinor, &versMin);
//    Gestalt(gestaltSystemVersionBugFix, &versBugFix);
//    if (versMaj==10&&versMin<=8) {
//        rect.origin.y+=8;
//    }
//    
//    // Bar radius
//    CGFloat barRadius = 2.5;
//    
    //NSLog(@"- Current Rect:%@ \n- Value:%f \n- Final Width:%f", NSStringFromRect(rect), value, finalWidth);
    
    // Draw Right Part
//    NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect: rect xRadius: barRadius yRadius: barRadius];
//    [NSColor.grayColor setFill];
//    [bg fill];
    
//    // Knob position depending on control min/max value and current control value.
//    CGFloat value = ([self doubleValue]  - [self minValue]) / ([self maxValue] - [self minValue]);
//    // Final Left Part Width
//    CGFloat finalWidth = value * ([[self controlView] frame].size.width - 8);
//    
//    // Left Part Rect
//    NSRect leftRect = rect;
//    leftRect.size.width = finalWidth;
//    
//    // Draw Left Part
//    NSBezierPath* active = [NSBezierPath bezierPathWithRoundedRect: leftRect xRadius: barRadius yRadius: barRadius];
////    [[NSColor colorWithDeviceRed:255.0/255 green:127.0/255 blue:0 alpha:1.0] setFill];
//    [[NSColor colorWithDeviceRed:73.0/255 green:148.0/255 blue:253.0/255 alpha:1.0] setFill];
//    [active fill];
//
    SInt32 versMaj, versMin;
    Gestalt(gestaltSystemVersionMajor, &versMaj);
    Gestalt(gestaltSystemVersionMinor, &versMin);
    if (versMaj==10&&versMin<=8)
    {
        [super drawBarInside:rect flipped:flipped];
        return;
    }
    
    NSImage *image = [self stretchableImageWithCapInset:[NSImage imageNamed:@"slider-bg"] leftWidth:10 middleWidth:rect.size.width - 20 rightWidth:10];
    
    CGImageRef imageRef = [image CGImageForProposedRect:nil context:nil hints:nil];
    assert(imageRef);
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(context, rect, imageRef);
}

-(NSImage *)stretchableImageWithCapInset:(NSImage *)image leftWidth:(float)fLeftWidth middleWidth:(float)fMiddleWidth rightWidth:(float)fRightWidth
{
    float fImageWidth  = fLeftWidth + fMiddleWidth + fRightWidth;
    float fImageHeight = image.size.height;
    
    NSRect leftRect = NSMakeRect(0, 0, fLeftWidth, fImageHeight);
    NSImage *leftImage = [[[NSImage alloc] initWithSize:NSMakeSize(fLeftWidth, fImageHeight)] autorelease];
    [leftImage lockFocus];
    [image drawInRect:leftRect fromRect:leftRect operation:NSCompositeCopy fraction:1.0];
    [leftImage unlockFocus];
    
    
    NSRect middleRect = NSMakeRect(0, 0, fMiddleWidth, fImageHeight);
    NSImage *middleImage = [[[NSImage alloc] initWithSize:NSMakeSize(fMiddleWidth, fImageHeight)] autorelease];
    [middleImage lockFocus];
    [image drawInRect:middleRect fromRect:NSMakeRect(fLeftWidth, 0, image.size.width - fLeftWidth - fRightWidth, fImageHeight) operation:NSCompositeCopy fraction:1.0];
    [middleImage unlockFocus];
    
    NSRect rightRect = NSMakeRect(0, 0, fRightWidth, fImageHeight);
    NSImage *rightImage = [[[NSImage alloc] initWithSize:NSMakeSize(fRightWidth, fImageHeight)] autorelease];
    [rightImage lockFocus];
    [image drawInRect:rightRect fromRect:NSMakeRect(image.size.width - fRightWidth, 0, fRightWidth, fImageHeight) operation:NSCompositeCopy fraction:1.0];
    [rightImage unlockFocus];
    
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(fImageWidth, fImageHeight)];
    [newImage lockFocus];
    NSDrawThreePartImage(NSMakeRect(0, 0, fImageWidth, fImageHeight), leftImage, middleImage, rightImage, NO, NSCompositeSourceOver, 1.0, NO);
    [newImage unlockFocus];
    
    return [newImage autorelease];

}
@end
