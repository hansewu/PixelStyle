//
//  MyTitleView.m
//  testWindow
//
//  Created by lchzh on 27/3/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import "PSTitleView.h"

@implementation PSTitleView

@synthesize m_windowTitle;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    m_windowTitle=@"";
    return self;
}

- (void)drawString:(NSString *)string inRect:(NSRect)rect {
    static NSDictionary *att = nil;
    if (!att) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
        [style setAlignment:NSCenterTextAlignment];
        att = [[NSDictionary alloc] initWithObjectsAndKeys: style, NSParagraphStyleAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName,[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
        [style release];
        
    }
    
    NSRect titlebarRect = NSMakeRect(rect.origin.x, rect.origin.y-4, rect.size.width, rect.size.height);
    
    
    [string drawInRect:titlebarRect withAttributes:att];
}


- (void)drawRect:(NSRect)dirtyRect
{
    NSRect windowFrame = [NSWindow  frameRectForContentRect:[[[self window] contentView] bounds] styleMask:[[self window] styleMask]];
    NSRect contentBounds = [[[self window] contentView] bounds];
    
    NSRect titlebarRect = NSMakeRect(0, 0, self.bounds.size.width, windowFrame.size.height - contentBounds.size.height);
    titlebarRect.origin.y = self.bounds.size.height - titlebarRect.size.height;
    
    
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4.0 yRadius:4.0];
    [[NSBezierPath bezierPathWithRect:titlebarRect] addClip];
    NSGradient * gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.25 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.25 alpha:1.0]] autorelease];
    [path addClip];
    [gradient drawInRect:titlebarRect angle:270.0];
    
    [self drawString:m_windowTitle inRect:titlebarRect];
    
    
}


/*
- (void)drawRect:(NSRect)dirtyRect
{
    NSRect windowFrame = [NSWindow  frameRectForContentRect:[[[self window] contentView] bounds] styleMask:[[self window] styleMask]];
    NSRect contentBounds = [[[self window] contentView] bounds];
    
    NSRect titlebarRect = NSMakeRect(0, 0, self.bounds.size.width, windowFrame.size.height - contentBounds.size.height);
    titlebarRect.origin.y = self.bounds.size.height - titlebarRect.size.height;
    
    NSRect topHalf, bottomHalf;
    NSDivideRect(titlebarRect, &topHalf, &bottomHalf, floor(titlebarRect.size.height / 2.0), NSMaxYEdge);
    
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4.0 yRadius:4.0];
    [[NSBezierPath bezierPathWithRect:titlebarRect] addClip];
    
    
    
    NSGradient * gradient1 = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:1 alpha:1.0]] autorelease];
    NSGradient * gradient2 = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0 alpha:1.0]] autorelease];
    
    [path addClip];
    
    [gradient1 drawInRect:topHalf angle:270.0];
    [gradient2 drawInRect:bottomHalf angle:270.0];
    
    [[NSColor blackColor] set];
    NSRectFill(NSMakeRect(0, -4, self.bounds.size.width, 1.0));
    
    
    [self drawString:@"My Title" inRect:titlebarRect];
    
    
}

*/

@end
