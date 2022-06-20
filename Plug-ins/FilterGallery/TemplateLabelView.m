//
//  TemplateLabelView.m
//  CIFilters
//
//  Created by Calvin on 1/17/17.
//  Copyright © 2017 EffectMatrix. All rights reserved.
//

#import "TemplateLabelView.h"

@implementation TemplateLabelView

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithRed:79.0/255 green:79.0/255 blue:79.0/255 alpha:1]set];
    [[NSBezierPath bezierPathWithRect:dirtyRect]fill];
    
    NSMutableDictionary* attribute = [NSMutableDictionary dictionary];
    attribute[NSFontAttributeName] = [NSFont systemFontOfSize:13];
    attribute[NSForegroundColorAttributeName] = [NSColor colorWithDeviceWhite:1.0 alpha:1.0];

    NSRect rect = [m_title boundingRectWithSize:NSMakeSize(1000, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    
    [m_title drawInRect:NSMakeRect(5.0, 5.0, rect.size.width, rect.size.height) withAttributes:attribute];
    
    [[NSColor colorWithRed:64.0/255 green:64.0/255 blue:64.0/255 alpha:1]set];
    [NSBezierPath setDefaultLineWidth:1.0f];
    [NSBezierPath strokeLineFromPoint:m_startpointForLine toPoint:m_endpointForLine];
    
    [[NSColor colorWithRed:97.0/255 green:98.0/255 blue:97.0/255 alpha:1]set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(m_startpointForLine.x + 1, m_startpointForLine.y) toPoint:NSMakePoint(m_endpointForLine.x + 1, m_endpointForLine.y)];
}

-(void)setTitle:(NSString*)title
{
    m_title = title;
}

-(void)setLineStartPoint:(NSPoint)point
{
    m_startpointForLine = point;
}

-(void)setLineEndPoint:(NSPoint)point
{
    m_endpointForLine = point;
}
@end
