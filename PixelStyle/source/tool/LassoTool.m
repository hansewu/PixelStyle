#import "LassoTool.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "LassoOptions.h"
#import "PSContent.h"
#import "PSTools.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSView.h"
#import "PSLayer.h"
#import "PSWhiteboard.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"

@implementation LassoTool

- (id)init
{
    if (![super init])
        return NULL;
    
    if(m_curDefault)            {[m_curDefault release]; m_curDefault = nil;}
    if(m_curAdd)                {[m_curAdd release]; m_curAdd = nil;}
    if(m_curSubtract)           {[m_curSubtract release]; m_curSubtract = nil;}
    if(m_curMultipy)            {[m_curMultipy release]; m_curMultipy = nil;}
    if(m_curSubtractProduct)    {[m_curSubtractProduct release]; m_curSubtractProduct = nil;}
    m_curDefault = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curAdd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso-add-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curSubtract = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso-subtract-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curMultipy = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso-multiply-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curSubtractProduct = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lasso-subProduct-cursor"] hotSpot:NSMakePoint(1, 1)];
    
    return self;
}

- (int)toolId
{
	return kLassoTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Lasso Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"L";
}
/*
- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	[super mouseDownAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
		
	if(![super isMovingOrScaling]){
		where.x -= [layer xoff];
		where.y -= [layer yoff];

		// Create the points list
		m_sPoints = malloc(kMaxLTPoints * sizeof(IntPoint));
		m_nPos = 0;
		m_sPoints[0] =  NSPointMakeIntPoint(where);
		m_poiLast = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
		[[m_idDocument docView] setNeedsDisplay:YES];
		m_bIntermediate = YES;
	}
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	[super mouseDraggedTo:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
	
	if(m_bIntermediate && ![super isMovingOrScaling]){
		int width, height;
		where.x -= [layer xoff];
		where.y -= [layer yoff];

		// Check we have a valid start point
		// Check this point is different to the last
		if (m_nPos < kMaxLTPoints - 1) {

			if (m_sPoints[m_nPos].x != where.x || m_sPoints[m_nPos].y != where.y) {
				// Add the point to the list
				m_nPos++;
				m_sPoints[m_nPos] = NSPointMakeIntPoint(where);
				
				// Make sure we fall inside the layer
				width = [(PSLayer *)[[m_idDocument contents] activeLayer] width];
				height = [(PSLayer *)[[m_idDocument contents] activeLayer] height];
				if (m_sPoints[m_nPos].x < 0) m_sPoints[m_nPos].x = 0;
				if (m_sPoints[m_nPos].y < 0) m_sPoints[m_nPos].y = 0;
				if (m_sPoints[m_nPos].x > width) m_sPoints[m_nPos].x = width;
				if (m_sPoints[m_nPos].y > height) m_sPoints[m_nPos].y = height;
			}
		}
		[[m_idDocument docView] setNeedsDisplay:YES];
	}
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	[super mouseUpAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
	
	// Check we have a valid start point
	if (m_bIntermediate && ![super isMovingOrScaling]) {
        PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
        IMAGE_DATA imageData = [overlayData lockDataForWrite];
        unsigned char *overlay = imageData.pBuffer;
		unsigned char *fakeOverlay;
		int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
		float xScale, yScale;
		int fakeHeight, fakeWidth;
		int interpolation;
		int spp = [[m_idDocument contents] spp];
		int tpos;
		IntRect rect;
		GimpVector2 *gimpPoints;

		// Redraw canvas
		[[m_idDocument docView] setNeedsDisplay:YES];

		// Clear last selection
		if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode)
			[[m_idDocument selection] clearSelectionShow];
		
		// No single-pixel loops
        if (m_nPos <= 1) {
            [overlayData unLockDataForWrite];
            return;
        }

		// Fill out the variables
		if([[m_idDocument docView] zoom] <= 1){
			interpolation = GIMP_INTERPOLATION_NONE;
		}else{
			interpolation = GIMP_INTERPOLATION_CUBIC;
		}
					
		// Create an overlay that's the size of what the user sees
		xScale = [[m_idDocument contents] xscale];
		yScale = [[m_idDocument contents] yscale];
		fakeHeight = height * yScale;
		fakeWidth  = width * xScale;
		fakeOverlay = malloc(make_128(fakeWidth * fakeHeight * spp));
		memset(fakeOverlay, 0, fakeWidth * fakeHeight * spp);

		// Reconnect the loop
		m_nPos++;
		m_sPoints[m_nPos] = m_sPoints[0];
		gimpPoints = malloc((m_nPos) * sizeof(GimpVector2));

		// Find the rectangle of the selection
		rect.origin = m_sPoints[0];
		rect.size.width = rect.size.height = 1;
		for (tpos = 1; tpos <= m_nPos; tpos++) {
			// Scale the points depending on the zoom
			m_sPoints[tpos].x *= xScale;
			m_sPoints[tpos].y *= yScale;
			
			if (m_sPoints[tpos].x < rect.origin.x) {
				rect.size.width += rect.origin.x - m_sPoints[tpos].x;
				rect.origin.x = m_sPoints[tpos].x; 
			}
			
			if (m_sPoints[tpos].y < rect.origin.y) {
				rect.size.height += rect.origin.y - m_sPoints[tpos].y;
				rect.origin.y = m_sPoints[tpos].y;
			}

			if (m_sPoints[tpos].x >= rect.origin.x + rect.size.width)
				rect.size.width = m_sPoints[tpos].x - rect.origin.x;
				
			if (m_sPoints[tpos].y >= rect.origin.y + rect.size.height)
				rect.size.height = m_sPoints[tpos].y - rect.origin.y;
				
			gimpPoints[tpos - 1].x = (double)m_sPoints[tpos].x;
			gimpPoints[tpos - 1].y = (double)m_sPoints[tpos].y;			

		}
		
		// Ensure an IntRect (as opposed to NSRect)
		rect.origin.x = (int)floor(rect.origin.x / xScale);
		rect.origin.y = (int)floor(rect.origin.y / yScale);
		rect.size.width = (int)ceil(rect.size.width / xScale);
		rect.size.height = (int)ceil(rect.size.height / yScale);			
		
		// Fill in region
		GCDrawPolygon(fakeOverlay, fakeWidth, fakeHeight, gimpPoints, m_nPos, spp);
		// Scale region to the actual size of the overlay
		GCScalePixels(overlay, width, height, fakeOverlay, fakeWidth, fakeHeight, interpolation, spp);
        
        [overlayData unLockDataForWrite];
	
		// Then select it
		[[m_idDocument selection] selectOverlay:YES inRect:rect mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
			
		// Release the fake (scaled) overlay
		free(fakeOverlay);
        free(m_sPoints);    //add by wyl
        m_sPoints = NULL;
		m_bIntermediate = NO;
		[[m_idDocument docView] setNeedsDisplay:YES];
	}

	m_bTranslating = NO;
	m_nScalingDir = kNoDir;
}

*/


- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    if(![super isMovingOrScaling])
    {
        // Create the points list
        m_sPoints = malloc(kMaxLTPoints * sizeof(IntPoint));
        m_nPos = 0;
        m_sPoints[0] = where;
        m_poiLast = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
        
        // Clear the active selection and start the selection
        if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode){
            //[[m_idDocument selection] clearSelectionShow];
            m_bOldActive = [[m_idDocument selection] active];
            [[m_idDocument selection] setActive:NO];
        }
        
        [[m_idDocument docView] setNeedsDisplay:YES];
        m_bIntermediate = YES;
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDraggedTo:where withEvent:event];
    
    if(m_bIntermediate && ![super isMovingOrScaling]){
        
        // Check we have a valid start point
        // Check this point is different to the last
        if (m_nPos < kMaxLTPoints - 1)
        {
            if (m_sPoints[m_nPos].x != where.x || m_sPoints[m_nPos].y != where.y) {
                // Add the point to the list
                m_nPos++;
                m_sPoints[m_nPos] = where;
            }
        }
        [[m_idDocument docView] setNeedsDisplay:YES];
    }

}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseUpAt:where withEvent:event];
    
    // Check we have a valid start point
    if (m_bIntermediate && ![super isMovingOrScaling])
    {
        int tpos;
        IntRect rect;
        
        // Redraw canvas
        [[m_idDocument docView] setNeedsDisplay:YES];
        
//        // Clear last selection
//        if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode)
//            [[m_idDocument selection] clearSelectionShow];
        
        // No single-pixel loops
        if (m_nPos <= 1) return;
        
        // Reconnect the loop
        m_nPos++;
        m_sPoints[m_nPos] = m_sPoints[0];
        
        // Find the rectangle of the selection
        rect.origin = m_sPoints[0];
        rect.size.width = rect.size.height = 1;
        for (tpos = 1; tpos <= m_nPos; tpos++) {
            
            if (m_sPoints[tpos].x < rect.origin.x) {
                rect.size.width += rect.origin.x - m_sPoints[tpos].x;
                rect.origin.x = m_sPoints[tpos].x;
            }
            
            if (m_sPoints[tpos].y < rect.origin.y) {
                rect.size.height += rect.origin.y - m_sPoints[tpos].y;
                rect.origin.y = m_sPoints[tpos].y;
            }
            
            if (m_sPoints[tpos].x >= rect.origin.x + rect.size.width)
                rect.size.width = m_sPoints[tpos].x - rect.origin.x;
            
            if (m_sPoints[tpos].y >= rect.origin.y + rect.size.height)
                rect.size.height = m_sPoints[tpos].y - rect.origin.y;
        }
        
        rect.origin.x += [[[m_idDocument contents] activeLayer] xoff];
        rect.origin.y += [[[m_idDocument contents] activeLayer] yoff];
        [[m_idDocument selection] selectPolyon:rect points:m_sPoints pointNum:m_nPos mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
        
        free(m_sPoints);    //add by wyl
        m_sPoints = NULL;
        m_bIntermediate = NO;
        [[m_idDocument docView] setNeedsDisplay:YES];
    }
    
    m_bTranslating = NO;
    m_nScalingDir = kNoDir;
}

- (BOOL)isFineTool
{
    return NO;//YES;
}

- (LassoPoints)currentPoints
{
	LassoPoints result;
	result.points = m_sPoints;
	result.pos = m_nPos;
	return result;
}

- (BOOL)stopCurrentOperation
{
    m_nPos = -1;
    free(m_sPoints);
    m_sPoints = NULL;
    m_bIntermediate = NO;
    
    [[m_idDocument selection] setActive:m_bOldActive];
    
    return YES;
}


@end
