//
//  PSColorWell.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "WDColor.h"
#import "PSColorWell.h"
#import "WDGradient.h"
#import "PSGradientStopIndicator.h"
#import "WDGradientStop.h"
#import "WDUtilities.h"
#import "NSViewAdditions.h"

@implementation PSColorWell

@synthesize painter = painter_;
//@synthesize barButtonItem = barButtonItem_;
@synthesize strokeMode = strokeMode_;
@synthesize gradientStopMode = gradientStopMode_;
@synthesize shadowMode = shadowMode_;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
	}

	return self;
}

- (void) setPainter:(id<WDPathPainter>)painter
{
    if (painter == painter_) {
        return;
    }
    
    if(painter_) [painter_ release];
    painter_ = [painter retain];
    
    if (gradientStop_) {
        gradientStop_.stop = [WDGradientStop stopWithColor:(WDColor *)painter_ andRatio:0];
    }
    
    if (shadowMode_) {
        shadowView_.layer.shadowColor = ((WDColor *) painter_).CGColor;
    } else {
        [self setNeedsDisplay];
    }
}

- (void) setShadowMode:(BOOL)shadowMode
{
    shadowMode_ = shadowMode;
    
//    if (!shadowView_) {
//        shadowView_ = [[NSView alloc] initWithFrame:CGRectInset(self.bounds, 5, 5)];
////        shadowView_.opaque = NO;
////        shadowView_.backgroundColor = nil;
//
//        CALayer *layer = shadowView_.layer;
//        
//        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:shadowView_.bounds cornerRadius:5];
//        
//        layer.shadowPath = path.CGPath;
//        layer.shadowOffset = CGSizeZero;
//        layer.shadowRadius = 3;
//        layer.shadowColor = ((WDColor *) painter_).CGColor;
//        layer.shadowOpacity = 1;
//
//        [self addSubview:shadowView_];
//
//        shadowView_.sharpCenter = WDCenterOfRect(self.bounds);
//    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect          bounds = [self bounds];
    
    if (shadowMode_) {
        WDDrawCheckersInRect(ctx, rect, 7);
        [[NSColor blackColor] set];
//        UIRectFrame(bounds);
        NSFrameRect(bounds);
        return;
    }
    
//    if (barButtonItem_) {
//        int inset = ceil((CGRectGetHeight(bounds) - CGRectGetWidth(bounds)) / 2);
//        bounds = CGRectInset(bounds, 0, inset);
//    }
//    
//    int inset = barButtonItem_ ? 7 : 10;
    int inset = 10;
    CGRect  hole = CGRectInset(bounds, inset, inset);
    
    if (strokeMode_) {
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, bounds);
        CGContextAddRect(ctx, hole);
        CGContextEOClip(ctx);
    }
    
    if (painter_) {
        [painter_ drawSwatchInRect:bounds];
    } else {
        [[UIColor whiteColor] set];
        CGContextFillRect(ctx, bounds);
        
        CGContextSaveGState(ctx);
        CGContextClipToRect(ctx, bounds);
        
        [[UIColor redColor] set];
        CGContextSetLineWidth(ctx, 2.0f);
        CGContextMoveToPoint(ctx, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
        CGContextStrokePath(ctx);
        
        CGContextRestoreGState(ctx);
    }
    
    if (strokeMode_) {
        CGContextRestoreGState(ctx);
        
        [[NSColor blackColor] set];
//        UIRectFrame(hole);
        NSFrameRect(hole);
    }
    
    [[NSColor blackColor] set];
    NSFrameRect(bounds);
//    UIRectFrame(bounds);
}

- (void) setGradientStopMode:(BOOL)gradient
{
    if (gradient && !gradientStop_) {
        gradientStop_ = [[PSGradientStopIndicator alloc] initWithStop:[WDGradientStop stopWithColor:(WDColor *)self.painter andRatio:0]];
        gradientStop_.selected = YES;
//        [self addSubview:gradientStop_];
        [self.superview addSubview:gradientStop_];
        
        CGRect  frame = gradientStop_.frame;
//        gradientStop_.sharpCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds) + CGRectGetHeight(frame) / 2);
        
        gradientStop_.sharpCenter = CGPointMake(WDCenterOfRect(self.frame).x, CGRectGetMinY(self.frame) - CGRectGetHeight(frame) / 2);
    } else if (!gradient && gradientStop_) {
        [gradientStop_ removeFromSuperview];
        [gradientStop_ release];
        gradientStop_ = nil;
    }
}

- (void) setStrokeMode:(BOOL)strokeMode
{
    strokeMode_ = strokeMode;
    
    if (strokeMode) {
        self.layer.backgroundColor = nil;
        self.layer.opaque = NO;
    }
}

-(void)dealloc
{
    if(gradientStop_)   [gradientStop_ release];
    if(painter_) [painter_ release];
    
    [super dealloc];
}

@end
