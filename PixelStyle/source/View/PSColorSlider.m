//
//  PSColorSlider.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "PSColorSlider.h"
#import "WDUtilities.h"
#import "PSColorIndicator.h"
#import "WDColor.h"
#import "NSViewAdditions.h"
#import "NSImageAdditions.h"

#define kCornerRadius   10
#define kIndicatorInset 10

@interface  PSColorSlider (Private)
- (CGImageRef) p_hueImage;
- (void) p_buildHueImage;
- (void) positionIndicator_;
@end

void HSVtoRGB2(float h, float s, float v, float *r, float *g, float *b)
{
    if (s == 0) {
        *r = *g = *b = v;
    } else {
        float   f,p,q,t;
        int     i;
        
        h *= 360;
        
        if (h == 360.0f) {
            h = 0.0f;
        }
        
        h /= 60;
        i = floor(h);
        
        f = h - i;
        p = v * (1.0 - s);
        q = v * (1.0 - (s*f));
        t = v * (1.0 - (s * (1.0 - f)));
        
        switch (i) {
            case 0: *r = v; *g = t; *b = p; break;
            case 1: *r = q; *g = v; *b = p; break;
            case 2: *r = p; *g = v; *b = t; break;
            case 3: *r = p; *g = q; *b = v; break;
            case 4: *r = t; *g = p; *b = v; break;
            case 5: *r = v; *g = p; *b = q; break;
        }
    }
}

static void evaluateShading(void *info, const CGFloat *in, CGFloat *out)
{
    PSColorSlider   *slider = (__bridge PSColorSlider *) info;
    WDColor         *color = slider.color;
    CGFloat         blend = in[0];
    float           hue, saturation, brightness;
    float           r1 = 0, g1 = 0, b1 = 0;
    float           r2 = 0, g2 = 0, b2 = 0;
    float           r = 0, g = 0, b = 0;
    BOOL            blendRGB = YES;
    
    hue = color.hue;
    saturation = color.saturation;
    brightness = color.brightness;
    
    if (slider.mode == PSColorSliderModeAlpha) {
        r = color.red; g = color.green; b = color.blue;
        blendRGB = NO;
    } else if (slider.mode == PSColorSliderModeBrightness) {
        HSVtoRGB2(hue, saturation, 0.0, &r1, &g1, &b1);
        HSVtoRGB2(hue, saturation, 1.0, &r2, &g2, &b2);
    } else if (slider.mode == PSColorSliderModeSaturation) {
        HSVtoRGB2(hue, 0.0, brightness, &r1, &g1, &b1);
        HSVtoRGB2(hue, 1.0, brightness, &r2, &g2, &b2);
    } else if (slider.mode == PSColorSliderModeRed) {
        r1 = 0; r2 = 1;
        g1 = g2 = color.green;
        b1 = b2 = color.blue;
    } else if (slider.mode == PSColorSliderModeGreen) {
        r1 = r2 = color.red;
        g1 = 0; g2 = 1;
        b1 = b2 = color.blue;
    } else if (slider.mode == PSColorSliderModeBlue) {
        r1 = r2 = color.red;
        g1 = g2 = color.green;
        b1 = 0; b2 = 1;
    } else if (slider.mode == PSColorSliderModeRedBalance) {
        r1 = 0; r2 = 1;
        g1 = 1; g2 = 0;
        b1 = 1; b2 = 0;
    } else if (slider.mode == PSColorSliderModeGreenBalance) {
        r1 = 1; r2 = 0;
        g1 = 0; g2 = 1;
        b1 = 1; b2 = 0;
    } else if (slider.mode == PSColorSliderModeBlueBalance) {
        r1 = 1; r2 = 0;
        g1 = 1; g2 = 0;
        b1 = 0; b2 = 1;
    }
    
    if (blendRGB) {
        r = (blend * r2) + (1.0f - blend) * r1;
        g = (blend * g2) + (1.0f - blend) * g1;
        b = (blend * b2) + (1.0f - blend) * b1;
    }
    
    out[0] = r;
    out[1] = g;
    out[2] = b;
    out[3] = (slider.mode == PSColorSliderModeAlpha ? in[0] : 1.0f);
}

static void release(void *info) {
}

@implementation PSColorSlider

@synthesize mode = mode_;
@synthesize floatValue = value_;
@synthesize color = color_;
@synthesize reversed = reversed_;
@synthesize indicator = indicator_;

- (void) awakeFromNib
{
    indicator_ = [PSColorIndicator colorIndicator];
    indicator_.sharpCenter = WDCenterOfRect(NSRectToCGRect([self bounds]));
    [self addSubview:indicator_];
    
    self.layer.opaque = NO;
    self.layer.backgroundColor = nil;
//    self.clearsContextBeforeDrawing = YES;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(NSEvent *)event
{
    CGRect bounds = CGRectInset(self.bounds, -10, -10);
    return CGRectContainsPoint(bounds, point);
}

- (void) dealloc
{
    if (hueImage_) {
        CGImageRelease(hueImage_);
    }
    
    if (shadingRef_) {
        CGShadingRelease(shadingRef_);
    }
    
    if(color_)              [color_ release];
    if(indicator_)          [indicator_ release];
    
    [super dealloc];
}
    
- (CGShadingRef) newShadingRef
{
    CGShadingRef        gradient;
    CGFloat             domain[] = {0.0f, 1.0f};
    CGFloat             range[] = {0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f};
    CGFunctionCallbacks callbacks;
    
    callbacks.version = 0;
    callbacks.evaluate = evaluateShading;
    callbacks.releaseInfo = release;
    
    CGPoint start = CGPointMake(0.0, 10.0f);
    CGPoint end = CGPointMake(CGRectGetWidth(self.frame), 10.0f);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFunctionRef gradientFunction = CGFunctionCreate((__bridge void *)(self), 1, domain, 4, range, &callbacks);
    
    if (self.reversed) {
        gradient = CGShadingCreateAxial(colorspace, end, start, gradientFunction, NO, NO);
    } else {
        gradient = CGShadingCreateAxial(colorspace, start, end, gradientFunction, NO, NO);
    }
    
    CGFunctionRelease(gradientFunction);
    CGColorSpaceRelease(colorspace);
    
    return gradient;
}

- (CGShadingRef) shadingRef
{
    if (!shadingRef_) {
        shadingRef_ = [self newShadingRef];
    }
    
    return shadingRef_;
}

- (void) setColor:(WDColor *)color
{
    switch (mode_) {
        case PSColorSliderModeAlpha:
            value_ = [color alpha];
            break;
        case PSColorSliderModeHue:
            value_ = [color hue];
            break;
        case PSColorSliderModeBrightness:
            value_ = [color brightness];
            break;
        case PSColorSliderModeSaturation:
            value_ = [color saturation];
            break;
        case PSColorSliderModeRed:
        case PSColorSliderModeRedBalance:
            value_ = [color red];
            break;
        case PSColorSliderModeGreen:
        case PSColorSliderModeGreenBalance:
            value_ = [color green];
            break;
        case PSColorSliderModeBlue:
        case PSColorSliderModeBlueBalance:
            value_ = [color blue];
            break;
        default: break;
    }
    
    if (!color_ || color.hue != color_.hue || color.saturation != color_.saturation || color.brightness != color_.brightness) {
        if (mode_ != PSColorSliderModeHue && shadingRef_) {
            CGShadingRelease(shadingRef_);
            shadingRef_ = NULL;
        }
    
        [self setNeedsDisplay];
    }
    if(color_) [color_ release];
    color_ = [color retain];
    
    [self positionIndicator_];
    
    if (self.reversed) {
        [indicator_ setColor:[color colorWithAlphaComponent:(1.0f - color.alpha)]];
    } else {
        if (mode_ == PSColorSliderModeHue) {
            color = [WDColor colorWithHue:color.hue saturation:1 brightness:1 alpha:1];
        }
        
        [indicator_ setColor:color];
    }
}

- (void) setMode:(PSColorSliderMode)mode
{
    mode_ = mode;
    indicator_.alphaMode = (mode == PSColorSliderModeAlpha);
    
    if (mode_ != PSColorSliderModeHue && shadingRef_) {
        CGShadingRelease(shadingRef_);
        shadingRef_ = NULL;
    }
    
    [self setNeedsDisplay];
}

- (void) setReversed:(BOOL)reversed
{
    reversed_ = reversed;
    [self setNeedsDisplay];
}

- (NSImage *) borderImage
{
    static NSImage *borderImage = nil;
    
    
    NSRect boundRect = NSInsetRect([self bounds], 4, 4);
    if (borderImage && !CGSizeEqualToSize(borderImage.size, boundRect.size)) {
        [borderImage release];
        borderImage = nil;
    }
    
    if (!borderImage) {
        borderImage = [NSImage imageNamed:@"slider_border.png"];
    
        NSEdgeInsets edgeInsets;
        edgeInsets.left = edgeInsets.right = 15;
        edgeInsets.top = edgeInsets.bottom = 0;
        borderImage = [borderImage stretchableImageWithLeftCapWidth:15 middleWidth:boundRect.size.width - 2*15 rightCapWidth:15];
//        [borderImage stretchableImageWithSize:[self bounds].size edgeInsets:edgeInsets];
    }
    
    return borderImage;
}

- (void) drawRect:(CGRect)clip
{
    NSRect boundRect = NSInsetRect([self bounds], 4, 4);
    
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect          bounds = NSRectToCGRect(boundRect);
//    CGContextClearRect(ctx, bounds);
    
    CGContextSaveGState(ctx);
//    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:8];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:boundRect xRadius:8 yRadius:8];
    [path addClip];
        
    if (mode_ == PSColorSliderModeAlpha) {
        WDDrawCheckersInRect(ctx, bounds, 8);
    }
    
    if (mode_ == PSColorSliderModeHue) {
        CGContextDrawImage(ctx, boundRect, [self p_hueImage]);
    } else {
        CGContextDrawShading(ctx, [self shadingRef]);
    }
    
    CGContextRestoreGState(ctx);
    
    [[self borderImage] drawInRect:bounds fromRect:NSZeroRect operation:NSCompositeMultiply fraction:0.333f];
//    [[self borderImage] drawInRect:bounds blendMode:kCGBlendModeMultiply alpha:0.333f];
}

- (float) indicatorCenterX_
{
    CGRect  trackRect = CGRectInset(self.bounds, kIndicatorInset, 0);
    
    return roundf(value_ * CGRectGetWidth(trackRect) + CGRectGetMinX(trackRect));
}

- (void) computeValue_:(CGPoint)pt
{
    CGRect  trackRect = CGRectInset(self.bounds, kIndicatorInset, 0);
    float   percentage;
    
    percentage = (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
    percentage = WDClamp(0.0f, 1.0f, percentage);
    
    value_ = percentage;
    
    [self setNeedsDisplay];
}

//- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
-(void)mouseDown:(NSEvent *)theEvent
{
//    CGPoint pt = [touch locationInView:self];
    CGPoint pt = [theEvent locationInWindow];
    pt = [self.window.contentView convertPoint:pt toView:self];
    
    [self computeValue_:pt];
    [self positionIndicator_];
    
//    [super mouseDown:theEvent];
    [self _trackMouse];
    
    return;
}

- (void)_trackMouse
{
    // track!
    NSEvent *event = nil;
    while([event type] != NSLeftMouseUp)
    {
        [self sendAction: [self action] to: [self target]];
        event = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        [self mouseDragged:event];
    }
}

//- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
-(void)mouseDragged:(NSEvent *)theEvent
{
//    CGPoint pt = [touch locationInView:self];
    CGPoint pt = [theEvent locationInWindow];
    pt = [self.window.contentView convertPoint:pt toView:self];

    [self computeValue_:pt];
    [self positionIndicator_];
    
    return [super mouseDragged:theEvent];
}

@end

@implementation PSColorSlider (Private)

- (CGImageRef) p_hueImage
{
    if (!hueImage_) {
        [self p_buildHueImage];
    }
    
    return hueImage_;
}

- (void) p_buildHueImage
{
    int             x, y;
    float           r,g,b;
    int             width = CGRectGetWidth(self.bounds);
    int             height = CGRectGetHeight(self.bounds);
    int             bpr = width * 4;
    UInt8           *data, *ptr;
    
    ptr = data = calloc(1, sizeof(unsigned char) * height * bpr);
    
    for (x = 0; x < width; x++) {
        float angle = ((float) x) / width;
        HSVtoRGB2(angle, 1.0f, 1.0f, &r, &g, &b);
        
        for (y = 0; y < height; y++) {
            ptr[y * bpr + x*4] = 255;
            ptr[y * bpr + x*4+1] = r * 255;
            ptr[y * bpr + x*4+2] = g * 255;
            ptr[y * bpr + x*4+3] = b * 255;
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, bpr, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    hueImage_ = CGBitmapContextCreateImage(ctx);
    
    // clean up
    free(data);
    CGContextRelease(ctx);
}

- (void) positionIndicator_
{
    indicator_.sharpCenter = CGPointMake([self indicatorCenterX_], WDCenterOfRect(indicator_.frame).y);
}

@end
