//
//  PSVerticalScroller.m
//  retarget
//
//  Created by lchzh on 30/3/15.
//
//

#import "MyVerticalScroller.h"

@implementation MyVerticalScroller

- (void)drawKnob
{
    NSRect knobRect = [self rectForPart:NSScrollerKnob];
    NSRect realKnobRect=NSMakeRect(knobRect.origin.x+3, knobRect.origin.y+2, knobRect.size.width-8, knobRect.size.height-4);
    NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:realKnobRect xRadius:4 yRadius:4];
    [[NSColor colorWithDeviceRed:m_fKnobColorRed green:m_fKnobColorRed blue:m_fKnobColorRed alpha:1.0] set];
    [path fill];
}


@end
