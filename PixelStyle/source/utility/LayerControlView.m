#import "LayerControlView.h"
#import "StatusUtility.h"

@implementation LayerControlView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
		m_idStatusUtility = nil;
    }
    
    return self;
}

- (void)resetCursorRects
{
	if(m_bDrawThumb)
    {
		[self addCursorRect:NSMakeRect(0, 0, 15 , [self frame].size.height) cursor:[NSCursor resizeLeftRightCursor]];
	}
}

- (void)drawRect:(NSRect)rect
{
    // Drawing code here.
//	[[NSImage imageNamed:@"layer-gradient"] drawInRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0]; 
	
	if(m_bDrawThumb)
    {
	
//		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
//		
//		NSBezierPath *tempPath = [NSBezierPath bezierPath];
//        float rightPX = 12;
//        float leftPX = 11;
//		[tempPath moveToPoint: NSMakePoint(rightPX, [self frame].size.height - 7.5)];
//		[tempPath lineToPoint:NSMakePoint(rightPX, 6.5)];
//		[tempPath stroke];
//
//		
//		tempPath = [NSBezierPath bezierPath];
//		[tempPath moveToPoint: NSMakePoint(rightPX - 3.0, [self frame].size.height - 7.5)];
//		[tempPath lineToPoint:NSMakePoint(rightPX - 3.0, 6.5)];
//		[tempPath stroke];
//
//		tempPath = [NSBezierPath bezierPath];
//		[tempPath moveToPoint: NSMakePoint(rightPX - 6.0 ,[self frame].size.height - 7.5)];
//		[tempPath lineToPoint:NSMakePoint(rightPX - 6.0, 6.5)];
//		[tempPath stroke];
//
//		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
//
//		tempPath = [NSBezierPath bezierPath];
//		[tempPath moveToPoint: NSMakePoint(leftPX, [self frame].size.height - 8.5)];
//		[tempPath lineToPoint:NSMakePoint(leftPX, 5.5)];
//		[tempPath stroke];
//		
//		tempPath = [NSBezierPath bezierPath];
//		[tempPath moveToPoint: NSMakePoint(leftPX - 3.0, [self frame].size.height - 8.5)];
//		[tempPath lineToPoint:NSMakePoint(leftPX - 3.0, 5.5)];
//		[tempPath stroke];
//		
//		tempPath = [NSBezierPath bezierPath];
//		[tempPath moveToPoint: NSMakePoint(leftPX - 6.0 ,[self frame].size.height - 8.5)];
//		[tempPath lineToPoint:NSMakePoint(leftPX - 6.0, 5.5)];
//		[tempPath stroke];
     
	}
    else
    {
		[m_idStatusUtility update];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if(!m_bDrawThumb) return;
	m_poiOld = [[m_idRightPane superview] convertPoint:[theEvent locationInWindow] fromView:NULL];
	if(m_poiOld.x < [m_idLeftPane frame].size.width + 20) // > [self frame].size.width - 20
		m_bIntermediate = YES;
	else
		m_bIntermediate = NO;
	m_fOldWidth = [m_idLeftPane frame].size.width;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint localPoint;
    
	localPoint = [[m_idRightPane superview] convertPoint:[theEvent locationInWindow] fromView:NULL];
    
	if(m_bIntermediate && m_bDrawThumb)
    {
		float diff = localPoint.x - m_poiOld.x;
        //NSLog(@"diff %f %f",diff,localPoint.x);
		float newWidth = m_fOldWidth + diff;
		// Minimum width
		if([[m_idRightPane superview] frame].size.width - newWidth < 150)
			newWidth = [[m_idRightPane superview] frame].size.width - 150;
		
		[m_idDelButton setHidden:(newWidth < 75)];
		[m_idDupButton setHidden:(newWidth < 107)];
		[m_idShButton setHidden:(newWidth < 138)];
			
		[m_idLeftPane setFrame:NSMakeRect(0, [m_idLeftPane frame].origin.y, newWidth, [m_idLeftPane frame].size.height)];
		[m_idRightPane setFrame:NSMakeRect(newWidth, [m_idRightPane frame].origin.y, [[m_idRightPane superview] frame].size.width - newWidth, [m_idRightPane frame].size.height)];
    
		
		[self setNeedsDisplay:YES];
		[m_idLeftPane setNeedsDisplay:YES];
		[m_idRightPane setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	m_bIntermediate = NO;
}

- (void)setHasResizeThumb:(BOOL)hasThumb
{
	m_bDrawThumb = hasThumb;
}

@end
