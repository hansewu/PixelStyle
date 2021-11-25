//
//  PSColorSelectView.m
//  Curves
//
//  Created by lchzh on 10/10/15.
//  Copyright © 2015 lchzh. All rights reserved.
//

#import "PSColorSelectView.h"

@implementation PSColorSelectView

- (void)awakeFromNib
{
    m_viewTag = 0;
    
}

- (void)setCustumDelegate:(id)delegate
{
    m_delegate = delegate;
}

- (void)setViewTag:(int)tag
{
    m_viewTag = tag;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    unsigned char* color = [m_delegate getViewColorWithTag:m_viewTag];
    NSColor *viewColor = [NSColor colorWithDeviceRed:color[0] / 255.0 green:color[1] / 255.0 blue:color[2] / 255.0 alpha:1.0];
    [viewColor set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, dirtyRect.size.width, dirtyRect.size.height)] fill];
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [m_delegate colorSelectViewClickedWithTag:m_viewTag];
}

@end
