#import "MyTabCell.h"

@implementation MyTabCell
@synthesize highlightedSegment;
// TODO: monitor this for clickable area and button image alignment. 
- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    for (int i =0 ;i < [self segmentCount]; i++) {
            [self drawSegment:i inFrame:cellFrame withView:controlView];	
    }
}

-(float)calcSegmentWidth:(int)nSegment
{
    float fWidth = [self widthForSegment:nSegment];
    return fWidth;
}

- (void) drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    if(segment == self.highlightedSegment)
    {
        [[NSColor colorWithRed:25.0/ 255 green:25.0/255 blue:25.0/255 alpha:1]set];
    }
    else{
        [[NSColor colorWithRed:60.0 / 255 green:60.0 /255 blue:60.0 / 255 alpha:1]set];
    }
    
    NSString* label = [self labelForSegment:segment];
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary * attr = @{NSParagraphStyleAttributeName : style, NSForegroundColorAttributeName : [NSColor colorWithWhite:1.0 alpha:1.0], NSFontAttributeName : [NSFont fontWithName:@"Helvetica" size:15]};
    
    NSAttributedString* attrLabel = nil;
    attrLabel = [[[NSAttributedString alloc] initWithString:label attributes:attr]autorelease];
    NSSize size = [attrLabel size];
    
    float fOriginX = 0.0;
    for (int i = 0; i < segment; i++) {
        float fWidth = [self calcSegmentWidth:i];
        fOriginX += fWidth;
    }
    
    NSRect rectForString,rect;
    rectForString.origin.x = fOriginX;
    rect.origin.x = fOriginX;

    rectForString.origin.y = 10;
    rect.origin.y = 5;
    
    rectForString.size.width = size.width + 20;
    rect.size.width = size.width + 20;
    
    rectForString.size.height = frame.size.height;
    rect.size.height = frame.size.height - 5;
    
    [[NSBezierPath bezierPathWithRect:rect] fill];
    [attrLabel drawInRect:rectForString];
    
    
    if(segment < [self segmentCount] - 1)
    {
        [[NSColor colorWithWhite:1.0 alpha:1.0] setStroke];
        NSPoint point1 = NSMakePoint(rect.origin.x + rect.size.width+1, rect.origin.y + 2);
        NSPoint point2 = NSMakePoint(rect.origin.x + rect.size.width+1, frame.size.height - 2);
        [NSBezierPath setDefaultLineWidth:3.0f];
        [NSBezierPath strokeLineFromPoint:point1 toPoint:point2];
    }
}

-(void)_updateHighlightedSegment:(NSPoint)currentPoint
                           inView:(NSView *)controlView {
    [self setHighlightedSegment:-1];
    NSPoint loc = currentPoint;
    NSRect frame = controlView.frame;
    loc.x += frame.origin.x;
    loc.y += frame.origin.y;
    NSUInteger i = 0, count = [self segmentCount];
    while(i < count && frame.origin.x < controlView.frame.size.width) {
        frame.size.width = [self widthForSegment:i];
        if(NSMouseInRect(loc, frame, NO))
        {
            [self setHighlightedSegment:i];
            break;
        }
        frame.origin.x += frame.size.width;
        i++;
    }
    [controlView setNeedsDisplay:YES];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint
                 inView:(NSView *)controlView {
    [self _updateHighlightedSegment:startPoint inView:controlView];
    return [super startTrackingAt:startPoint inView:controlView];
}

- (BOOL)continueTracking:(NSPoint)lastPoint
                      at:(NSPoint)currentPoint
                  inView:(NSView *)controlView {
    [self _updateHighlightedSegment:currentPoint inView:controlView];
    return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

// TODO: fix this warning.
- (void)stopTracking:(NSPoint)lastPoint
                  at:(NSPoint)stopPoint
              inView:(NSView *)controlView
           mouseIsUp:(BOOL)flag {
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
    if (highlightedSegment >= 0) {
        [self setSelectedSegment:highlightedSegment];
        if ([self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//            [self.target performSelector:self.action withObject:controlView];
#pragma clang diagnostic pop
        }
    }
//    [self setHighlightedSegment:-1];
}

@end
