//
//  PSEventForwardingView.m
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "PSEventForwardingView.h"


@implementation PSEventForwardingView

@synthesize forwardToView = forwardToView_;

- (void) awakeFromNib
{
    self.layer.opaque = NO;
    self.layer.backgroundColor = nil;
    
    m_bDragging = NO;
    
    NSRect rect = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height);
    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:rect options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil] autorelease];
    [self addTrackingArea:trackingArea];
}

-(void)dealloc
{
    [super dealloc];
}
//- (NSView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    NSView *view = [super hitTest:point withEvent:event];
//    
//    return (view == self) ? forwardToView_ : view;
//}

-(void)mouseDown:(NSEvent *)theEvent
{
    [forwardToView_ mouseDown:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    m_bDragging = YES;
    
    [forwardToView_ mouseDragged:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    m_bDragging = NO;
    [forwardToView_ mouseUp:theEvent];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    if(m_bDragging)
        [forwardToView_ mouseUp:theEvent];
    
    m_bDragging = NO;
}

@end
