//
//  PSScrollView.m
//  PixelStyle
//
//  Created by wyl on 16/1/12.
//
//

#import "PSScrollView.h"
#import "PSVerticalScroller.h"
#import "PSHorizontalScroller.h"

@implementation PSScrollView

- (void)drawRect:(NSRect)rect{
    [super drawRect: rect];
    
    if([self hasVerticalScroller] && [self hasHorizontalScroller])
    {
        NSRect vframe = [[self verticalScroller] frame];
        NSRect hframe = [[self horizontalScroller] frame];
        NSRect corner;
        corner.origin.x = NSMaxX(hframe);
        corner.origin.y = NSMinY(hframe);
        corner.size.width = NSWidth(vframe);
        corner.size.height = NSHeight(hframe);
        
        // your custom drawing in the corner rect here
        [[NSColor colorWithDeviceRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1.0] set];
        NSRectFill(corner);
    }
}

-(void)awakeFromNib
{
    NSRect vframe = NSMakeRect(self.bounds.size.width - 15, 0, 15, self.bounds.size.height - 15);
    NSRect hframe = NSMakeRect(0, self.bounds.size.height - 15, self.bounds.size.width - 15, 15);
    [self setVerticalScroller:[[PSVerticalScroller alloc] initWithFrame:vframe]];
    [self setHorizontalScroller:[[PSHorizontalScroller alloc] initWithFrame:hframe]];
}

-(void)dealloc
{
    [[self verticalScroller] release];
    [[self horizontalScroller] release];
    
    [super dealloc];
}
@end
