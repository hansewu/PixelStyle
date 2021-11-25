//
//  PSArrowheadCell.m
//
//  Created by Steve Sprang on 10/16/13.
//  Copyright (c) 2013 Taptrix, Inc. All rights reserved.
//

#import "PSArrowheadCell.h"

#import "WDArrowhead.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"

#define kArrowInset     15
#define kArrowWidth     72
#define kArrowHeight    40

#define KDefaultColorR 171.0/255
#define KDefaultColorG 200.0/255
#define KDefaultColorB 255.0/255


@interface PSArrowSeparatorView : NSView
@end

@implementation PSArrowSeparatorView

- (void) drawRect:(CGRect)rect
{
    CGRect          frame = self.frame;
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGFloat         lengths[] = {2};
    float           y = floor(CGRectGetMidY(frame)) + 0.5f;
    
    [[NSColor colorWithDeviceRed:KDefaultColorR green:KDefaultColorG blue:KDefaultColorB alpha:1.0] set];
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetLineDash(ctx, 0, lengths, 1);
    CGContextMoveToPoint(ctx, 0, y);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(frame), y);
    CGContextStrokePath(ctx);
}

@end

@implementation PSArrowheadCell

@synthesize startArrowButton = startArrowButton_;
@synthesize endArrowButton = endArrowButton_;
@synthesize arrowhead = arrowhead_;
@synthesize drawingController = drawingController_;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (!self) {
        return nil;
    }
    
    startArrowButton_ = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,kArrowWidth,kArrowHeight)];
    [startArrowButton_ setButtonType:NSSwitchButton];
    [startArrowButton_ setBezelStyle:NSThickSquareBezelStyle];
    [startArrowButton_ setBordered:NO];
    [startArrowButton_ setState:NSOffState];
    [startArrowButton_ setTarget:self];
    [startArrowButton_ setAction:@selector(leftArrowTapped:) ];
    [self addSubview:startArrowButton_];
//    [startArrowButton_ release];
    
    
    endArrowButton_ = [[NSButton alloc] initWithFrame:NSMakeRect(self.frame.size.width - kArrowWidth,0,kArrowWidth,kArrowHeight)];
    [endArrowButton_ setButtonType:NSSwitchButton];
    [endArrowButton_ setBezelStyle:NSThickSquareBezelStyle];
    [endArrowButton_ setBordered:NO];
    [endArrowButton_ setState:NSOffState];
    [endArrowButton_ setTarget:self];
    [endArrowButton_ setAction:@selector(rightArrowTapped:) ];
    [self addSubview:endArrowButton_];
//    [endArrowButton_ release];
    
    
    
    CGRect frame = CGRectInset(self.frame, kArrowWidth, 0);
    PSArrowSeparatorView *separator = [[PSArrowSeparatorView alloc] initWithFrame:frame];
    [separator setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    separator.layer.backgroundColor = nil;
    separator.layer.opaque = NO;
    [self addSubview:separator];
    [separator release];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(drawingController_)      [drawingController_ release];
    if(endArrowButton_)         [endArrowButton_ release];
    if(startArrowButton_)       [startArrowButton_ release];
    if(arrowhead_)              [arrowhead_ release];
    
    [super dealloc];
}

- (void) setDrawingController:(WDDrawingController *)drawingController
{
    if(drawingController_) [drawingController_ release];
    drawingController_ = [drawingController retain];

    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidProperties:)
                                                 name:WDInvalidPropertiesNotification
                                               object:drawingController_.propertyManager];
}

- (void) invalidProperties:(NSNotification *)aNotification
{
    NSSet *properties = [aNotification.userInfo objectForKey:WDInvalidPropertiesKey];
    
    if ([properties intersectsSet:[NSSet setWithObjects:WDStartArrowProperty, WDEndArrowProperty, nil]]) {
        WDStrokeStyle   *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
        
        self.startArrowButton.state = [strokeStyle.startArrow isEqualToString:arrowhead_];
        self.endArrowButton.state = [strokeStyle.endArrow isEqualToString:arrowhead_];
    }
}

- (void) leftArrowTapped:(NSButton *)sender
{
    [drawingController_ setValue:self.arrowhead forProperty:WDStartArrowProperty];
}

- (void) rightArrowTapped:(NSButton *)sender
{
    [drawingController_ setValue:self.arrowhead forProperty:WDEndArrowProperty];
}

- (void) setArrowhead:(NSString *)arrowhead
{
    if (arrowhead_ == arrowhead) {
        return;
    }
    
//    arrowhead_ = arrowhead;
    
    if(arrowhead_) [arrowhead_ release];
    arrowhead_ = [arrowhead retain];
    
    NSImage *image = [self imageForArrow:arrowhead start:YES selected:NO];
    [startArrowButton_ setImage:image];
    NSImage *imageSelected = [self imageForArrow:arrowhead start:YES selected:YES];
    [startArrowButton_ setAlternateImage:imageSelected];

    image = [self imageForArrow:arrowhead start:NO selected:NO];
    [endArrowButton_ setImage:image];
    imageSelected = [self imageForArrow:arrowhead start:NO selected:YES];
    [endArrowButton_ setAlternateImage:imageSelected];
}

- (NSImage *) imageForArrow:(NSString *)arrowID start:(BOOL)isStart selected:(BOOL)isSelected
{
    WDArrowhead     *arrow = [WDArrowhead arrowheads][arrowID];
    CGContextRef    ctx;
    float           scale = 2.0f;//3.0f;
    float           midY = floor(kArrowHeight / 2) + 0.5f;
    float           startX = kArrowInset + arrow.insetLength * scale;
    
    NSImage *result = [[NSImage alloc] initWithSize:NSMakeSize(kArrowWidth,kArrowHeight)];
    [result lockFocus];
    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    
    //选中背景
    if(isSelected)
    {
//        [[NSColor colorWithDeviceRed:0.0f green:(118.0f / 255) blue:1.0f alpha:1.0f] set];
        [[NSColor colorWithDeviceRed:KDefaultColorR green:KDefaultColorG blue:KDefaultColorB alpha:1.0] set];
        CGContextFillRect(ctx, CGRectInset(CGRectMake(0, 0, kArrowWidth, kArrowHeight), 4, 4));
        
        [[NSColor whiteColor] set];
    }
    else
    {
        [[NSColor colorWithDeviceRed:KDefaultColorR green:KDefaultColorG blue:KDefaultColorB alpha:1.0] set];
    }
   
    CGContextSetLineWidth(ctx, scale);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    if (!arrow) {
        CGContextMoveToPoint(ctx, kArrowInset, midY);
        CGContextAddLineToPoint(ctx, kArrowWidth - kArrowInset, midY);
    } else if (isStart) {
        [arrow addArrowInContext:ctx position:CGPointMake(startX, midY) scale:scale angle:M_PI useAdjustment:NO];
        CGContextFillPath(ctx);
        CGContextMoveToPoint(ctx, startX, midY);
        CGContextAddLineToPoint(ctx, kArrowWidth - kArrowInset, midY);
    } else {
        [arrow addArrowInContext:ctx position:CGPointMake(kArrowWidth - startX, midY) scale:scale angle:0 useAdjustment:NO];
        CGContextFillPath(ctx);
        CGContextMoveToPoint(ctx, kArrowWidth - startX, midY);
        CGContextAddLineToPoint(ctx, kArrowInset, midY);
    }
    
    CGContextStrokePath(ctx);
    
    [result unlockFocus];
    
    return [result autorelease];
}

@end
