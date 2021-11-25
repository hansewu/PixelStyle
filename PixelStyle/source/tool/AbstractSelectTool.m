#import "AbstractSelectTool.h"

#import "PSDocument.h"
#import "PSHelpers.h"
#import "PSSelection.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"
#import "PSContent.h"

@implementation AbstractSelectTool

- (id)init
{
    if (![super init])
        return NULL;
    
    if(m_curDefault)            {[m_curDefault release]; m_curDefault = nil;}
    if(m_curAdd)                {[m_curAdd release]; m_curAdd = nil;}
    if(m_curSubtract)           {[m_curSubtract release]; m_curSubtract = nil;}
    if(m_curMultipy)            {[m_curMultipy release]; m_curMultipy = nil;}
    if(m_curSubtractProduct)    {[m_curSubtractProduct release]; m_curSubtractProduct = nil;}
    m_curDefault = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curAdd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curSubtract = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curMultipy = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-multiply-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curSubtractProduct = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subProduct-cursor"] hotSpot:NSMakePoint(7, 7)];
    
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Ctrl to select new area; Shift to add to selection; Opt to subtract from selection; Shift + Opt to intersect with selection; Shift + Ctrl to inverse intersect of selection.", nil)];

    return self;
}


-(void)dealloc
{
    if(m_curDefault)            {[m_curDefault release]; m_curDefault = nil;}
    if(m_curAdd)                {[m_curAdd release]; m_curAdd = nil;}
    if(m_curSubtract)           {[m_curSubtract release]; m_curSubtract = nil;}
    if(m_curMultipy)            {[m_curMultipy release]; m_curMultipy = nil;}
    if(m_curSubtractProduct)    {[m_curSubtractProduct release]; m_curSubtractProduct = nil;}
    
    [super dealloc];
}

- (void)mouseDownAt:(IntPoint)localPoint withEvent:(NSEvent *)event
{	
	if([[m_idDocument selection] active]){
		/* incidentally, we should only be translating when the mode is default
		 However, we don't know how to pass that logic in yet
		 here it is:
		 [(AbstractSelectOptions *)m_idOptions selectionMode] == kDefaultMode
		 */
		
		[self mouseDownAt: localPoint
				  forRect: [[m_idDocument selection] globalRect]
				  andMask: [(PSSelection*)[m_idDocument selection] mask]];
		
		// Also, we universally float the selection if alt is down
		if(![self isMovingOrScaling] && [(AbstractOptions*)m_idOptions modifier] == kAltModifier) {
//			[[m_idDocument contents] makeSelectionFloat:NO];
		}
	}
    
}

- (void)mouseDraggedTo:(IntPoint)localPoint withEvent:(NSEvent *)event
{
	if([[m_idDocument selection] active]){
		IntRect newRect = [self mouseDraggedTo: localPoint
									   forRect: [[m_idDocument selection] globalRect]
									   andMask: [(PSSelection*)[m_idDocument selection] mask]];
        
		if(m_nScalingDir > kNoDir && !m_bTranslating){
			[[m_idDocument selection] scaleSelectionTo: newRect
											  from: [self preScaledRect]
									 interpolation: GIMP_INTERPOLATION_CUBIC
										 usingMask: [self preScaledMask]];
		}else if (m_bTranslating && m_nScalingDir == kNoDir){
			[[m_idDocument selection] moveSelection:IntMakePoint(newRect.origin.x, newRect.origin.y)];
		}
	}
}

- (void)mouseUpAt:(IntPoint)localPoint withEvent:(NSEvent *)event
{
	if([[m_idDocument selection] active]){
		[self mouseUpAt: localPoint
				forRect: [[m_idDocument selection] globalRect]
				andMask: [(PSSelection*)[m_idDocument selection] mask]];
        
        //add by lcz
        IntRect newRect = [self mouseDraggedTo: localPoint
                                       forRect: [[m_idDocument selection] globalRect]
                                       andMask: [(PSSelection*)[m_idDocument selection] mask]];
        if(m_nScalingDir > kNoDir && !m_bTranslating){
            [[m_idDocument selection] scaleSelectionTo: newRect
                                                  from: [self preScaledRect]
                                         interpolation: GIMP_INTERPOLATION_CUBIC
                                             usingMask: [self preScaledMask]];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoScaleSelectionFrom:[self preScaledRect]];
        }else if (m_bTranslating && m_nScalingDir == kNoDir){
            //[[m_idDocument selection] moveSelection:IntMakePoint(newRect.origin.x, newRect.origin.y)];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMoveSelection:m_sOldOrigin];
        }
	}
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSRect operableRect;
    IntRect operableIntRect;
    
    operableIntRect = IntMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * xScale, [(PSContent *)[m_idDocument contents] height] *yScale);
    operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
    
    
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    operableRect.origin = [scrollView convertPoint: operableRect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], operableRect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    
    
    if(m_cursor) {[m_cursor release]; m_cursor  = nil;}
    
    if(!NSPointInRect(where, clippedRect))
    {
        m_cursor = [[NSCursor arrowCursor] retain];
        [m_cursor set];
        
        return;
    }
    
    if((NSPointInRect([NSEvent mouseLocation], [gColorPanel frame]) && [gColorPanel isVisible]))
    {
        m_cursor = [[NSCursor arrowCursor] retain];
        [m_cursor set];
        return;
    }
    
    
    NSArray *arrChildWindows = [[m_idDocument window] childWindows];
    for(NSWindow *window in arrChildWindows)
    {
        if((NSPointInRect([NSEvent mouseLocation], [window frame]) && [window isVisible]))
        {
            m_cursor = [[NSCursor arrowCursor] retain];
            [m_cursor set];
            
            return;
        }
    }
    
    
    
    int selectionMode = [m_idOptions selectionMode];
    
    if(selectionMode == kAddMode)
    {
        m_cursor = [m_curAdd retain];
    }
    else if (selectionMode == kSubtractMode)
    {
        m_cursor = [m_curSubtract retain];
    }
    else if (selectionMode == kMultiplyMode)
    {
        m_cursor = [m_curMultipy retain];
    }
    else if (selectionMode == kSubtractProductMode)
    {
        m_cursor = [m_curSubtractProduct retain];
    }
    else if(selectionMode != kDefaultMode)
    {
        m_cursor = [m_curDefault retain];
    }else
    {
        [super mouseMoveTo:where withEvent:event];
        
        int nScalingDir = [self point:where isInHandleFor:[[m_idDocument selection] globalRect]];
        if(nScalingDir > kNoDir) return;
        
        if(m_cursor) {[m_cursor release]; m_cursor  = nil;}
        m_cursor = [m_curDefault retain];
        // Now we need the handles and the hand
        if([[m_idDocument selection] active])
        {
            NSRect selectionRect = IntRectMakeNSRect([[m_idDocument selection] globalRect]);
            float xScale = [[m_idDocument contents] xscale];
            float yScale = [[m_idDocument contents] yscale];
            selectionRect = NSMakeRect(selectionRect.origin.x * xScale, selectionRect.origin.y * yScale, selectionRect.size.width * xScale, selectionRect.size.height * yScale);
            NSRect rect = NSConstrainRect(selectionRect,[[m_idDocument docView] bounds]);
            if(NSPointInRect(where, rect))
                
            {
                if(m_cursor) {[m_cursor release]; m_cursor  = nil;}
                m_cursor = [[NSCursor openHandCursor] retain];
            }
        }
    }
    
    
    [m_cursor set];

}

- (void)undoScaleSelectionFrom:(IntRect)oldRect
{
    IntRect globalRect = [(PSSelection*)[m_idDocument selection] globalRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    unsigned char *preMask = NULL;
    if(mask){
        preMask = malloc(globalRect.size.width * globalRect.size.height);
        memcpy(preMask, mask, globalRect.size.width * globalRect.size.height);
    } else {
        preMask = NULL;
    }
    [[m_idDocument selection] scaleSelectionTo: oldRect
                                          from: globalRect
                                 interpolation: GIMP_INTERPOLATION_CUBIC
                                     usingMask: preMask];
    if (preMask) {
        free(preMask);
    }
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoScaleSelectionFrom:globalRect];
}

- (void)undoMoveSelection:(IntPoint)origin
{
    IntPoint oldOrigin = [[m_idDocument selection] globalRect].origin;
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMoveSelection:oldOrigin];
    [[m_idDocument selection] moveSelection:origin];
}

- (void)cancelSelection
{
	m_bTranslating = NO;
	m_nScalingDir = kNoDir;

	m_bIntermediate = NO;
	[[m_idDocument helpers] selectionChanged];
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

@end
