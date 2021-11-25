//
//  PSGradientEditor.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "PSGradientEditor.h"
#import "WDGradient.h"
#import "PSGradientController.h"
#import "WDGradientStop.h"
#import "PSGradientStopIndicator.h"
#import "WDUtilities.h"
#import "NSViewAdditions.h"

#define kMaxAllowableStops  6
#define kRemoveDistance     50

@implementation PSGradientEditor

@synthesize gradient = gradient_;
@synthesize renderingGradient = renderingGradient_;
@synthesize controller = controller_;
@synthesize inactive = inactive_;

- (void) awakeFromNib
{
    indicators_ = [[NSMutableArray alloc] init];
    self.gradient = [WDGradient defaultGradient];
    
    // add a subview to register for gestures
//    NSView *gestureView = [[NSView alloc] initWithFrame:self.bounds];
//    gestureView.opaque = NO;
//    gestureView.backgroundColor = nil;
//    [self addSubview:gestureView];
//    
//    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
//    swipe.direction = (UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight);
//    [gestureView addGestureRecognizer:swipe];
//    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
//    tap.numberOfTapsRequired = 2;
//    [gestureView addGestureRecognizer:tap];
//    
//    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    tap.numberOfTapsRequired = 1;
//    [gestureView addGestureRecognizer:tap];
    
//    self.gradient = [WDGradient defaultGradient];
}

-(void)dealloc
{
    if(indicators_)             [indicators_ release];
    if(gradient_)               [gradient_ release];
    if(activeIndicator_)        [activeIndicator_ release];
//    if(indicatorToRemove_)      [indicatorToRemove_ release];
//    if(indicatorToDrag_)        [indicatorToDrag_ release];
    if(renderingGradient_)      [renderingGradient_ release];
    if(controller_)             [controller_ release];
    
    [super dealloc];
}

//- (void) handleSingleTap:(UISwipeGestureRecognizer*)gesture
//{
//    if (gesture.state == UIGestureRecognizerStateEnded) {
//        if (inactive_) {
//            [self sendActionsForControlEvents:UIControlEventValueChanged];
//        }
//    }
//}
//
//- (void) handleDoubleTap:(UISwipeGestureRecognizer*)gesture
//{
//    if (gesture.state == UIGestureRecognizerStateEnded) {
//        [controller_ distributeGradientStops:self];
//    }
//}
//
//- (void) handleSwipe:(UISwipeGestureRecognizer*)gesture
//{
//    if (gesture.state == UIGestureRecognizerStateEnded) {
//        [controller_ reverseGradient:self];
//    }
//}

- (void) positionIndicator:(PSGradientStopIndicator *)indicator
{
    CGRect  bounds = CGRectInset(self.bounds, 1, 0);
    
    CGRect  frame = indicator.frame;
    indicator.sharpCenter = CGPointMake(CGRectGetMinX(self.frame) + indicator.stop.ratio * CGRectGetWidth(bounds),CGRectGetMinY(self.frame) - CGRectGetHeight(frame) / 2 - 5);
//    indicator.sharpCenter = CGPointMake(CGRectGetMinX(bounds) + indicator.stop.ratio * CGRectGetWidth(bounds), CGRectGetHeight(bounds) + (CGRectGetHeight(indicator.bounds) / 2.0f) - 5);
}

- (void) setGradient:(WDGradient *)gradient
{
    if ([gradient_ isEqual:gradient]) {
        // we can bail early, but we still need to make sure the color controller is showing the appropriate color
        if (activeIndicator_) {
            [controller_ colorSelected:activeIndicator_.stop.color];
        }
        return;
    }
    
    if(gradient_) [gradient_ release];
    gradient_ = [gradient retain];

    float activeIndicatorRatio = -1;
    if (activeIndicator_) {
        activeIndicatorRatio = activeIndicator_.stop.ratio;
        if(activeIndicator_)[activeIndicator_ release];
        activeIndicator_ = nil;
    }
    
    [indicators_ makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [indicators_ removeAllObjects];
    
    for (WDGradientStop *stop in gradient.stops) {
        PSGradientStopIndicator *indicator = [[PSGradientStopIndicator alloc] initWithStop:stop];
        [indicators_ addObject:indicator];
//        [self addSubview:indicator];
        
        [self.superview addSubview:indicator];
        
        [self positionIndicator:indicator];
        
        if (stop.ratio == activeIndicatorRatio) {
            [self setActiveIndicator:indicator];
        }
        
        indicator.hidden = inactive_;
    }
    
    self.renderingGradient = [gradient copy];
    
    if (!activeIndicator_) {
        [self setActiveIndicator:indicators_[0]];
    }
}

- (void) setRenderingGradient:(WDGradient *)gradient
{
    if(renderingGradient_) [renderingGradient_ release];
    renderingGradient_ = [gradient retain];
    
    [self setNeedsDisplay];
}
    
- (void)drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];;//UIGraphicsGetCurrentContext();
    
    WDDrawCheckersInRect(ctx, rect, 7);
     
    CGContextDrawLinearGradient(ctx,
                                [renderingGradient_ gradientRef], self.bounds.origin, CGPointMake(CGRectGetMaxX(self.bounds), 0),
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    [[NSColor blackColor] set];
//    UIRectFrame(self.bounds);
    NSFrameRect(self.bounds);
}

- (void) setInactive:(BOOL)inactive
{
    inactive_ = inactive;
    
    for (PSGradientStopIndicator *indicator in indicators_) {
        indicator.hidden = inactive;
    }
    
    if (!inactive_ && !activeIndicator_) {
        [self setActiveIndicator:indicators_[0]];
    }
}

- (NSArray *) stops
{
    NSMutableArray *stops = [NSMutableArray array];
    
    for (PSGradientStopIndicator *indicator in indicators_) {
        [stops addObject:indicator.stop];
    }
    
    return stops;
}

- (PSGradientStopIndicator *) stopIndicatorWithRatio:(float)ratio
{
    for (PSGradientStopIndicator *indicator in indicators_) {
        if (indicator.stop.ratio == ratio) {
            return indicator;
        }
    }
    
    return nil;
}

- (void) setColor:(WDColor *)color
{
    activeIndicator_.stop = [WDGradientStop stopWithColor:color andRatio:activeIndicator_.stop.ratio];
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    [self.controller takeGradientStopsFrom:self];
}

- (void) setActiveIndicator:(PSGradientStopIndicator *)indicator
{
    activeIndicator_.selected = NO;
    
    if(activeIndicator_) [activeIndicator_ release];
    activeIndicator_ = nil;
    
    activeIndicator_ = [indicator retain];
    activeIndicator_.selected = YES;
    
    if (activeIndicator_) {
        [controller_ colorSelected:activeIndicator_.stop.color];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    if (inactive_) {
        return ;//[super mouseDown:theEvent];
    }
    
    CGPoint pt = [theEvent locationInWindow];
    pt = [self.window.contentView convertPoint:pt toView:self];
   
    
    moved_ = NO;
//    if(indicatorToRemove_) [indicatorToRemove_ release];
//    if(indicatorToDrag_) [indicatorToDrag_ release];
    indicatorToDrag_ = indicatorToRemove_ = nil;
    
    for (PSGradientStopIndicator *indicator in [indicators_ reverseObjectEnumerator]) {
        NSRect rect = [self convertRect:indicator.frame fromView:self.superview];
//        if (CGRectContainsPoint(indicator.frame, pt)) {
        if (CGRectContainsPoint(NSRectToCGRect(rect), pt)) {
            [self setActiveIndicator:indicator];
            indicatorToDrag_ = indicator;
            break;
        }
    }
    
    return ;//[super mouseDown:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint pt = [theEvent locationInWindow];
    pt = [self.window.contentView convertPoint:pt toView:self];
    if(NSPointInRect(pt, self.bounds))
        return;
    if (inactive_) {
        return [super mouseDragged:theEvent];
    }
    
//    CGPoint pt = [theEvent locationInWindow];
//    pt = [self.window.contentView convertPoint:pt toView:self];
    moved_ = YES;
    
    if (indicatorToDrag_) {
        if ([indicators_ count] > 2 && fabs(WDCenterOfRect(indicatorToDrag_.frame).y - pt.y) > kRemoveDistance) {
            indicatorToDrag_.alphaValue = 0;
            indicatorToRemove_ = indicatorToDrag_;
        } else {
            if (indicatorToRemove_) {
                indicatorToDrag_.alphaValue = 1;
                
                [indicatorToRemove_ release];
                indicatorToRemove_ = nil;
            }
            
            indicatorToDrag_.stop = [WDGradientStop stopWithColor:indicatorToDrag_.stop.color andRatio:(pt.x / CGRectGetWidth(self.bounds))];
            [self positionIndicator:indicatorToDrag_];
        }
        
        self.renderingGradient = [self.renderingGradient gradientWithStops:self.stops];
    }
    
    return ;//[super mouseDragged:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if (!inactive_ && !moved_ && !indicatorToDrag_ && (self.gradient.stops.count < kMaxAllowableStops)) {
        CGPoint pt = [theEvent locationInWindow];
        pt = [self.window.contentView convertPoint:pt toView:self];
        float   ratio = (pt.x / CGRectGetWidth(self.bounds));
        
        self.gradient = [self.gradient gradientWithStopAtRatio:ratio];
        [self setActiveIndicator:[self stopIndicatorWithRatio:ratio]];
    } else if (indicatorToRemove_) {
        NSInteger ix = [indicators_ indexOfObject:indicatorToRemove_];
        
        [indicators_ removeObject:indicatorToRemove_];
        [indicatorToRemove_ removeFromSuperview];
        
        if(activeIndicator_)[activeIndicator_ release];
        if(indicatorToRemove_) [indicatorToRemove_ release];
        
        activeIndicator_ = indicatorToRemove_ = nil;
        
        
        ix--;
        if (ix < 0) {
            ix++;
        }
        [self setActiveIndicator:indicators_[ix]];
    }
    
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self.controller takeGradientStopsFrom:self];
    //[self.controller setGradient:self.gradient];
    
    return ;//[super mouseUp:theEvent];
}

//- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if (inactive_) {
//        return [super beginTrackingWithTouch:touch withEvent:event];
//    }
//    
//    CGPoint pt = [touch locationInView:self];
//    
//    moved_ = NO;
//    indicatorToDrag_ = indicatorToRemove_ = nil;
//    
//    for (WDGradientStopIndicator *indicator in [indicators_ reverseObjectEnumerator]) {
//        if (CGRectContainsPoint(indicator.frame, pt)) {
//            [self setActiveIndicator:indicator];
//            indicatorToDrag_ = indicator;
//            break;
//        }
//    }
//    
//    return [super beginTrackingWithTouch:touch withEvent:event];
//}
//
//- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    if (inactive_) {
//        return [super continueTrackingWithTouch:touch withEvent:event];
//    }
//    
//    CGPoint pt = [touch locationInView:self];
//    moved_ = YES;
//
//    if (indicatorToDrag_) {
//        if ([indicators_ count] > 2 && fabs(indicatorToDrag_.center.y - pt.y) > kRemoveDistance) {
//            indicatorToDrag_.alpha = 0;
//            indicatorToRemove_ = indicatorToDrag_;
//        } else {
//            if (indicatorToRemove_) {
//                indicatorToDrag_.alpha = 1;
//                indicatorToRemove_ = nil;
//            }
//            
//            indicatorToDrag_.stop = [WDGradientStop stopWithColor:indicatorToDrag_.stop.color andRatio:(pt.x / CGRectGetWidth(self.bounds))];
//            [self positionIndicator:indicatorToDrag_];
//        }
//        
//        self.renderingGradient = [self.renderingGradient gradientWithStops:self.stops];
//    }
//    
//    return [super continueTrackingWithTouch:touch withEvent:event];
//}
//
//- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
//{
//    if (!inactive_ && !moved_ && !indicatorToDrag_ && (self.gradient.stops.count < kMaxAllowableStops)) {
//        CGPoint pt = [touch locationInView:self];
//        float   ratio = (pt.x / CGRectGetWidth(self.bounds));
//        
//        self.gradient = [self.gradient gradientWithStopAtRatio:ratio];
//        [self setActiveIndicator:[self stopIndicatorWithRatio:ratio]];
//    } else if (indicatorToRemove_) {
//        NSInteger ix = [indicators_ indexOfObject:indicatorToRemove_];
//        
//        [indicators_ removeObject:indicatorToRemove_];
//        [indicatorToRemove_ removeFromSuperview];
//        activeIndicator_ = indicatorToRemove_ = nil;
//        
//        ix--;
//        if (ix < 0) {
//            ix++;
//        }
//        [self setActiveIndicator:indicators_[ix]];
//    }
//    
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
//    
//    return [super endTrackingWithTouch:touch withEvent:event];
//}

@end
