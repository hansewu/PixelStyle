//
//  PSSelectionEventInfo.m
//  PixelStyle
//
//  Created by lchzh on 5/11/15.
//
//

#import "PSSelectionEventInfo.h"



@implementation PSSelectionEventInfo

@synthesize selectionType;
@synthesize selectionMode;
@synthesize selectionRect;
@synthesize selectionPoints;
@synthesize selectionPointsCount;
@synthesize selectionFeather;
@synthesize selectionRadius;
@synthesize selectionFirstActive;
@synthesize wandInfo;

- (id)init
{
    self = [super init];
    selectionPoints = NULL;
    return self;
}

- (void)dealloc
{
    if (selectionPoints) {
        free(selectionPoints);
        selectionPoints = NULL;
    }
    [super dealloc];
}

@end
