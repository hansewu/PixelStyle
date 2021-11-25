//
//  MyHorizontalScrollView.m
//  FilterGallery
//
//  Created by Calvin on 3/2/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import "MyHorizontalScrollView.h"

@implementation MyHorizontalScrollView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

-(void)scrollWheel:(NSEvent *)event
{
    NSPoint scrollPoint = [[self contentView] bounds].origin;
    if([event scrollingDeltaY] < 0)
    {
        scrollPoint.x -= (rintf([event scrollingDeltaY]) - 10);
    }else{
        scrollPoint.x -= (rintf([event scrollingDeltaY]) + 10);
    }
    [[self documentView] scrollPoint:scrollPoint];
}
@end
