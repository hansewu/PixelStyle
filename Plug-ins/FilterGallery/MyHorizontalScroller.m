//
//  PSHorizontalScroller
//  retarget
//
//  Created by lchzh on 30/3/15.
//
//

#import "MyHorizontalScroller.h"

@implementation MyHorizontalScroller

-(id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        [self performSelector:@selector(initView) withObject:nil afterDelay:0.05];
    }
    
    return self;
}

-(void)initView
{
    m_fKnobColorRed = 110/255.0;
    m_fKnobColorGreen = 110/255.0;
    m_fKnobColorBlue = 110/255.0;
    
    if((self.bounds.size.width == 0) || (self.bounds.size.height == 0))
        m_bShow = false;
    else
    {
        m_bShow = true;
        NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil] autorelease];
        [self addTrackingArea:trackingArea];
    }
}

-(void)dealloc
{
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *trackingArea in trackingAreas)
    {
        [self removeTrackingArea:trackingArea];
//        [trackingArea release];
//        trackingArea = nil;
    }

    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    if(!m_bShow)
    {
        [self performSelector:@selector(initView) withObject:nil afterDelay:0.05];
    }
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
    [[NSColor colorWithDeviceRed:52/255.0 green:52/255.0 blue:52/255.0 alpha:1.0] set];
    NSRect realSlotRect=NSMakeRect(slotRect.origin.x-10, slotRect.origin.y-10, slotRect.size.width+20, slotRect.size.height+20);
    NSRectFill(realSlotRect);
}

- (void)drawKnob
{
    NSRect knobRect = [self rectForPart:NSScrollerKnob];
    NSRect realKnobRect=NSMakeRect(knobRect.origin.x+2, knobRect.origin.y+4, knobRect.size.width-4, knobRect.size.height-8);
    NSBezierPath *path=[NSBezierPath bezierPathWithRoundedRect:realKnobRect xRadius:4 yRadius:4];
    [[NSColor colorWithDeviceRed:m_fKnobColorRed green:m_fKnobColorGreen blue:m_fKnobColorBlue alpha:1.0] set];
    [path fill];
}

#pragma mark - mouse Events
- (void) mouseEntered:(NSEvent*)theEvent {
    // Mouse entered tracking area.8
    m_fKnobColorRed = 90/255.0;
    m_fKnobColorGreen = 90/255.0;
    m_fKnobColorBlue = 90/255.0;
}

- (void) mouseExited:(NSEvent*)theEvent {
    // Mouse exited tracking area.
    m_fKnobColorRed = 110/255.0;
    m_fKnobColorGreen = 110/255.0;
    m_fKnobColorBlue = 110/255.0;
}

@end
