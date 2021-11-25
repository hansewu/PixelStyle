//
//  PSColorIndicator.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "PSColorIndicator.h"
#import "WDColor.h"
#import "WDUtilities.h"
#import "PSUtilities.h"

@implementation PSColorIndicator

@synthesize alphaMode = alphaMode_;
@synthesize color = color_;

+ (PSColorIndicator *) colorIndicator
{
//    PSColorIndicator *indicator = [[PSColorIndicator alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    PSColorIndicator *indicator = [[PSColorIndicator alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
    return indicator;
}

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
	}
    
    self.color = [[WDColor whiteColor] retain];
    self.layer.opaque = NO;
    
    
//    NSView *overlay = [[NSView alloc] initWithFrame:self.bounds];
//    [self addSubview:overlay];
//    
//    overlay.layer.borderColor = [NSColor whiteColor].CGColor;
//    overlay.layer.borderWidth = 3;
//    overlay.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0f;
//    
//    overlay.layer.shadowOpacity = 0.5f;
//    overlay.layer.shadowRadius = 1;
//    overlay.layer.shadowOffset = CGSizeMake(0, 0);
    
	return self;
}

- (void) setColor:(WDColor *)color
{
    if ([color isEqual:color_]) {
        return;
    }
    
    if(color_)[color_ release];
    color_ = [color retain];
    
    [self setNeedsDisplay:YES];
//    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    CGRect          bounds = CGRectInset([self bounds], 2, 2);
    
    if (self.alphaMode) {
        CGContextSaveGState(ctx);
        CGContextAddEllipseInRect(ctx, bounds);
        CGContextClip(ctx);
        PSDrawTransparencyDiamondInRect(ctx, bounds);
        CGContextRestoreGState(ctx);
        [[self color] set];
    } else {
        [[[self color] opaqueUIColor] set];
    }
    
    CGContextFillEllipseInRect(ctx, bounds);
    
    CGContextSetShadowWithColor(ctx, CGSizeZero, 1.0, [NSColor colorWithDeviceWhite:0.5 alpha:0.5].CGColor);
    [[NSColor whiteColor] set];
    CGContextSetLineWidth(ctx,2);
    CGContextStrokeEllipseInRect(ctx, bounds);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(NSEvent *)event {
    return NO;
}

-(void)dealloc
{
    if(color_)          [color_ release];
    
    [super dealloc];
}


@end
