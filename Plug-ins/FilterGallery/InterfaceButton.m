//
//  InterfaceButton.m
//  CIFilters
//
//  Created by Calvin on 1/17/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import "InterfaceButton.h"

@implementation InterfaceButton

-(void)setLabel:(NSString*)label
{
    _label = label;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSBezierPath* pathToFill = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor colorWithRed:70.0/255 green:70.0/255 blue:70.0/255 alpha:1] setFill];
    [pathToFill fill];
    
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    style.alignment = NSTextAlignmentCenter;
    NSDictionary * attr = @{NSParagraphStyleAttributeName : style, NSForegroundColorAttributeName : [NSColor colorWithWhite:1.0 alpha:1.0]};
    
    [_label drawInRect:NSMakeRect(dirtyRect.origin.x, 5, dirtyRect.size.width, 20) withAttributes:attr];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor colorWithWhite:0.0 alpha:1.0] setStroke];
    path.lineWidth = 2.0;
    [path stroke];
}

@end
