//
//  PSBrowserCell.m
//  PixelStyle
//
//  Created by lchzh on 17/3/16.
//
//

#import "PSBrowserCell.h"
#import "PSVerticalScroller.h"

@implementation PSBrowserCell

//- (NSColor *)highlightColorInView:(NSView *)controlView
//{
//    //return [NSColor brownColor];
//    //[[NSColor colorWithCalibratedRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0] set];
//    
//    return [NSColor colorWithCalibratedRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0];
//}

- (BOOL)isLeaf
{
    return !self.node.isCatagory;
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    NSScrollView *superview = [[controlView superview] superview];
//    [superview setBorderType:NSBezelBorder];
//    [superview setHasVerticalScroller:NO];
//    NSScroller *vscroller = [superview verticalScroller];
//    PSVerticalScroller *scroller = [[PSVerticalScroller alloc] initWithFrame:vscroller.frame];
//    [superview setVerticalScroller:scroller];
    
    
    cellFrame.size.width += 10.0;
    if ([self isHighlighted]) {
        NSColor *invertColor = [NSColor colorWithCalibratedRed:220.0/255 green:210.0/255 blue:186.0/255 alpha:1.0];
        [invertColor set];
//        [[NSColor colorWithCalibratedRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0] set];
        [[NSBezierPath bezierPathWithRect: cellFrame] fill];
    }else{
        
    }
    
    [NSGraphicsContext saveGraphicsState];
    NSDictionary *attrs;
    NSRect textRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + (cellFrame.size.height - 14)/2.0, cellFrame.size.width, 14);
//    attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:11] , NSFontAttributeName, [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.8], NSForegroundColorAttributeName, nil];
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:11] , NSFontAttributeName, [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.8], NSForegroundColorAttributeName, nil];
    [[self stringValue] drawInRect:textRect withAttributes:attrs];
    [NSGraphicsContext restoreGraphicsState];
    
    
    
    //[super drawWithFrame:cellFrame inView:controlView];

}

//- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    cellFrame.size.width += 10.0;
//    [[NSColor colorWithCalibratedRed:112.0/255 green:123.0/255 blue:146.0/255 alpha:1.0] set];
//    [[NSBezierPath bezierPathWithRect: cellFrame] fill];
//    [super drawInteriorWithFrame:cellFrame inView:controlView];
//}

//- (NSRect) expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
//    NSRect expansionFrame = [super expansionFrameWithFrame:cellFrame inView:view];
//    if (!NSIsEmptyRect(expansionFrame)) {
//        expansionFrame.size.height += 10;
//    }
//    return expansionFrame;
//}
//
//- (void) drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view {
//    [super drawInteriorWithFrame:cellFrame inView:view];
//}
//
//
//
//- (NSSize) cellSizeForBounds:(NSRect)aRect {
//    NSSize theSize = [super cellSizeForBounds:aRect];
//    theSize.height -= 5.0;
//    return theSize;
//}
//
//- (NSRect)imageRectForBounds:(NSRect)cellFrame
//{
//    cellFrame.origin.y += 5.0;
//    return cellFrame;
//}
//
//// We could manually implement expansionFrameWithFrame:inView: and drawWithExpansionFrame:inView: or just properly implement titleRectForBounds to get expansion tooltips to automatically work for us
//- (NSRect)titleRectForBounds:(NSRect)cellFrame
//{
//    cellFrame.origin.y += 10.0;
//    return cellFrame;
//}




@end
