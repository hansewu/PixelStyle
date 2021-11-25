//
//  PSGradientStopIndicator.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDColor.h"
#import "PSGradientStopIndicator.h"
#import "WDGradientStop.h"
#import "WDUtilities.h"
#import "PSUtilities.h"

const float kColorRectInset = 10;

@implementation PSGradientStopOverlay
@synthesize indicator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.layer.opaque = NO;
    self.layer.backgroundColor = nil;
    
    self.layer.shadowOpacity = 0.5f;
    self.layer.shadowRadius = 1;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    
    CGRect          colorRect = [indicator colorRect];
    
    CGRect outsideRect = CGRectInset(colorRect, -2, -2);
    outsideRect.size.height -= 1;
    outsideRect.origin.y += 1;
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    CGPathMoveToPoint(pathRef, NULL, CGRectGetMinX(outsideRect),self.bounds.size.height -  CGRectGetMinY(outsideRect));
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMidX(self.bounds),self.bounds.size.height -  CGRectGetMinY(self.bounds) + 0);
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(outsideRect),self.bounds.size.height -  CGRectGetMinY(outsideRect));
    
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMaxX(outsideRect),self.bounds.size.height -  CGRectGetMaxY(outsideRect));
    CGPathAddLineToPoint(pathRef, NULL, CGRectGetMinX(outsideRect),self.bounds.size.height -  CGRectGetMaxY(outsideRect));
    CGPathCloseSubpath(pathRef);
    
    CGPathAddRect(pathRef, NULL, CGRectInset(colorRect, 1, 1));
    
    [[NSColor whiteColor] set];
    CGContextAddPath(ctx, pathRef);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 1.0, [NSColor colorWithDeviceWhite:0.5 alpha:1.0].CGColor);
    CGContextEOFillPath(ctx);
    
    if (indicator.selected) {
        CGRect selectionRect = CGRectOffset(outsideRect, 0, outsideRect.size.height);
        selectionRect.size.height = 4;
        selectionRect.origin.y = self.bounds.size.height -  selectionRect.origin.y;
        [[NSColor colorWithDeviceRed:0.0f green:(118.0f / 255.0) blue:1.0f alpha:1.0f] set];
        CGContextFillRect(ctx, selectionRect);
    }
    
    CGPathRelease(pathRef);
}

-(void)dealloc
{
    if(indicator)        [indicator release];
    
    [super dealloc];
}

@end


@implementation PSGradientStopIndicator

@synthesize stop = stop_;
@synthesize selected = selected_;
@synthesize overlay = overlay_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.layer.opaque = NO;
    self.layer.backgroundColor = nil;
    
    return self;
}

- (id) initWithStop:(WDGradientStop *)stop
{
    self = [self initWithFrame:CGRectMake(0,0,39,39)];
//    self = [self initWithFrame:CGRectMake(0,0,35,28)];
    
    if (!self) {
        return nil;
    }
    
    self.stop = [stop retain];
    
    overlay_ = [[PSGradientStopOverlay alloc] initWithFrame:self.bounds];
    overlay_.indicator = self;
    [self addSubview:overlay_];
    
    return self;
}

- (void) setStop:(WDGradientStop *)stop
{
    if(stop_) [stop_ release];
    stop_ = [stop retain];
    [self setNeedsDisplay:YES];
}

- (void) setSelected:(BOOL)flag
{
    selected_ = flag;
    [overlay_ setNeedsDisplay:YES];
}

- (CGRect) colorRect
{
    CGRect rect = self.bounds;
    rect = CGRectInset(rect, kColorRectInset, kColorRectInset);
    rect.size.height = rect.size.width;
    rect.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(rect) - (kColorRectInset - 1);
    
    return rect;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect          colorRect = [self colorRect];
    
    PSDrawTransparencyDiamondInRect(ctx, colorRect);
    [stop_.color set];
    CGContextFillRect(ctx, colorRect);
}

-(void)dealloc
{
    if(overlay_)        [overlay_ release];
    if(stop_)           [stop_ release];
    
    [super dealloc];
}

@end
