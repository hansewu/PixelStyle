//
//  TemplateButton.m
//  CIFilters
//
//  Created by Calvin on 1/12/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.
//

#import "TemplateButton.h"

@implementation TemplateButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor colorWithRed:79.0/255 green:79.0/255 blue:79.0/255 alpha:1.0] set];
    [path fill];
    [m_image drawInRect:dirtyRect];
}

-(void)setFaceImage:(NSImage*)image
{
    m_image = [image retain];
}

-(void)mouseEntered:(NSEvent *)event
{
    self.alphaValue = 0.7;
}

-(void)mouseExited:(NSEvent *)event
{
    self.alphaValue = 1.0;
}

-(id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil] autorelease];
        [self addTrackingArea:trackingArea];
    }
    return self;
}


-(void)dealloc
{
    NSArray* trackingAreas = [self trackingAreas];
    for (NSTrackingArea* area in trackingAreas) {
        [self removeTrackingArea:area];
    }
    if(m_image)
       [m_image release];
    [super dealloc];
}
@end
