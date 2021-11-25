#import "PolygonLassoTool.h"
#import "LassoTool.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "PolygonLassoOptions.h"
#import "PSContent.h"
#import "PSTools.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSView.h"
#import "PSLayer.h"
#import "PSWhiteboard.h"

@implementation PolygonLassoTool

- (id)init
{
    if (![super init])
        return NULL;
    
    if(m_curDefault)            {[m_curDefault release]; m_curDefault = nil;}
    if(m_curAdd)                {[m_curAdd release]; m_curAdd = nil;}
    if(m_curSubtract)           {[m_curSubtract release]; m_curSubtract = nil;}
    if(m_curMultipy)            {[m_curMultipy release]; m_curMultipy = nil;}
    if(m_curSubtractProduct)    {[m_curSubtractProduct release]; m_curSubtractProduct = nil;}
    m_curDefault = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"polyon-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curAdd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"polyon-add-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curSubtract = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"polyon-subtract-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curMultipy = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"polyon-multiply-cursor"] hotSpot:NSMakePoint(1, 1)];
    m_curSubtractProduct = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"polyon-subProduct-cursor"] hotSpot:NSMakePoint(1, 1)];
    
    m_bHaveTempPoint = false;
    
    return self;
}

- (int)toolId
{
	return kPolygonLassoTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Polygonal Lasso Tool", nil);
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
		float xScale, yScale;
        PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
        IMAGE_DATA imageData = [overlayData lockDataForWrite];
        unsigned char *overlay = imageData.pBuffer;
		unsigned char *fakeOverlay;
		int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
		int fakeHeight, fakeWidth;
		int interpolation;
		int spp = [[m_idDocument contents] spp];
		int tpos;
		IntRect rect;
		GimpVector2 *gimpPoints;
		int modifier;
		
		where.x -= [layer xoff];
		where.y -= [layer yoff];

		// Get mode
		modifier = [(PolygonLassoOptions *)m_idOptions modifier];

		float anchorRadius = 4.0 / [[m_idDocument docView] zoom];
		
		// Behave differently depending on condtions
		if (!m_bIntermediate){
			
			// Fill out the variables
			m_bIntermediate = YES;
			m_poiStart = where;

			// Create the points list
			m_sPoints = malloc(kMaxLTPoints * sizeof(IntPoint));
			m_nPos = 0;
			m_sPoints[0] =  NSPointMakeIntPoint(where);
			m_poiLast = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
		}
		else if ([[NSApp currentEvent] clickCount] == 1 && m_bIntermediate && !(fabsf(m_poiStart.x - where.x) < anchorRadius && fabsf(m_poiStart.y - where.y) < anchorRadius)) {
			
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
		}
		 else if (m_bIntermediate) {
			
			// Fill out the variables
			if ([[m_idDocument docView] zoom] <= 1) {
				interpolation = GIMP_INTERPOLATION_NONE;
			}
			else {
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
			// Redraw canvas
			[[m_idDocument docView] setNeedsDisplay:YES];

			// Clear last selection
			if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode)
				[[m_idDocument selection] clearSelectionShow];
			
			// All polygons have at least 3 points
			if (m_nPos < 3){
				free(fakeOverlay);
                
                free(m_sPoints);  //add by wyl
                m_sPoints = NULL;

				m_bIntermediate = NO;
				return;
			}

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
            free(m_sPoints);   //add by wyl
            m_sPoints = NULL;

			m_bIntermediate = NO;
		}
		[[m_idDocument docView] setNeedsDisplay:YES];
	}
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	[super mouseDraggedTo:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	[super mouseUpAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];

	m_bTranslating = NO;
	m_nScalingDir = kNoDir;
}
 */


- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    if(m_bIntermediate || (![super isMovingOrScaling]))
    {
        int tpos;
        IntRect rect;
        int modifier;
        
        // Get mode
        modifier = [(PolygonLassoOptions *)m_idOptions modifier];
        
        float anchorRadius = 4.0 / [[m_idDocument docView] zoom];
        
        // Behave differently depending on condtions
        if (!m_bIntermediate){
            
            // Fill out the variables
            m_bIntermediate = YES;
            m_poiStart = NSMakePoint(where.x, where.y);
            
            // Create the points list
            m_sPoints = malloc(kMaxLTPoints * sizeof(IntPoint));
            m_nPos = 0;
            m_sPoints[0] =  where;
            m_poiLast = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
            
            
            // Clear the active selection and start the selection
            if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode){
                //[[m_idDocument selection] clearSelectionShow];
                m_bOldActive = [[m_idDocument selection] active];
                [[m_idDocument selection] setActive:NO];
            }
            
        }
        else if ([[NSApp currentEvent] clickCount] == 1 && m_bIntermediate && !(fabsf(m_poiStart.x - where.x) < anchorRadius && fabsf(m_poiStart.y - where.y) < anchorRadius))
        {
            // Check this point is different to the last
            if (m_nPos < kMaxLTPoints - 1)
            {
                if (m_sPoints[m_nPos].x != where.x || m_sPoints[m_nPos].y != where.y)
                {
                    // Add the point to the list
                    m_nPos++;
                    m_sPoints[m_nPos] = where;
                }
            }
        }
        else if (m_bIntermediate)
        {
            [self removeTempPoint];
            // Reconnect the loop
            m_nPos++;
            m_sPoints[m_nPos] = m_sPoints[0];
            
            // Redraw canvas
            [[m_idDocument docView] setNeedsDisplay:YES];
            
//            // Clear last selection
//            if([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode)
//                [[m_idDocument selection] clearSelectionShow];
            
            // All polygons have at least 3 points
            if (m_nPos < 3){
                free(m_sPoints);  //add by wyl
                m_sPoints = NULL;
                
                m_bIntermediate = NO;
                return;
            }
            
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
            
            // Then select it
            rect.origin.x += [[[m_idDocument contents] activeLayer] xoff];
            rect.origin.y += [[[m_idDocument contents] activeLayer] yoff];
            
            [[m_idDocument selection] selectPolyon:rect points:m_sPoints pointNum:m_nPos mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
            
            free(m_sPoints);   //add by wyl
            m_sPoints = NULL;
            
            m_bIntermediate = NO;
        }
        [[m_idDocument docView] setNeedsDisplay:YES];
    }
}

- (BOOL)deleteKeyPressed
{
    if (m_bIntermediate) {
        if (m_nPos >= 0) {
            m_nPos--;
        }
        
        if (m_nPos < 0) {
            free(m_sPoints);
            m_sPoints = NULL;
            
            [self removeTempPoint];
            m_bIntermediate = NO;
        }
        [[m_idDocument docView] setNeedsDisplay:YES];
        return YES;
    }
    
    
    return NO;
}

- (BOOL)enterKeyPressed
{
    if(m_bIntermediate){
        // Reconnect the loop
        [self removeTempPoint];
        m_nPos++;
        m_sPoints[m_nPos] = m_sPoints[0];
        
        // Redraw canvas
        [[m_idDocument docView] setNeedsDisplay:YES];
        
        // All polygons have at least 3 points
        if (m_nPos < 3){
            free(m_sPoints);  //add by wyl
            m_sPoints = NULL;
            m_bIntermediate = NO;
            return YES;
        }
        
        IntRect rect;
        // Find the rectangle of the selection
        rect.origin = m_sPoints[0];
        rect.size.width = rect.size.height = 1;
        for (int tpos = 1; tpos <= m_nPos; tpos++) {
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
        
        // Then select it
        rect.origin.x += [[[m_idDocument contents] activeLayer] xoff];
        rect.origin.y += [[[m_idDocument contents] activeLayer] yoff];
        
        [[m_idDocument selection] selectPolyon:rect points:m_sPoints pointNum:m_nPos mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
        
        free(m_sPoints);   //add by wyl
        m_sPoints = NULL;
        
        m_bIntermediate = NO;
        return YES;
    }
    return NO;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDraggedTo:where withEvent:event];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseUpAt:where withEvent:event];
    
    m_bTranslating = NO;
    m_nScalingDir = kNoDir;
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    [super mouseMoveTo:where withEvent:event];
    
    if(m_sPoints == NULL) return;
    
    if(m_nScalingDir <= kNoDir)
    {
        int xoff = [[[m_idDocument contents] activeLayer] xoff];
        int yoff = [[[m_idDocument contents] activeLayer] yoff];
        float xScale = [[m_idDocument contents] xscale];
        float yScale = [[m_idDocument contents] yscale];
        
        NSPoint start = NSMakePoint((m_sPoints[0].x + xoff) *xScale , (m_sPoints[0].y + yoff) * yScale );
        NSRect outside  = NSMakeRect(start.x - 4,start.y - 4,8,8);
        
        if(NSPointInRect(where, outside))
        {
            if(m_cursor){[m_cursor release]; m_cursor = nil;}
            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-close-cursor"] hotSpot:NSMakePoint(7, 7)];
        }
    }
    
    [m_cursor set];
    
    
    [self addTempPoint:where];
}


-(void)addTempPoint:(NSPoint)where
{
    if(m_bIntermediate)
    {
        m_bHaveTempPoint = true;
        
        
        float xScale = [[m_idDocument contents] xscale];
        float yScale = [[m_idDocument contents] yscale];
        IntPoint localPoint;
        localPoint.x = where.x / xScale;
        localPoint.y = where.y / yScale;
        m_sTempPoint.x = localPoint.x - [[[m_idDocument contents] activeLayer] xoff];
        m_sTempPoint.y = localPoint.y - [[[m_idDocument contents] activeLayer] yoff];
        
        [[m_idDocument docView] setNeedsDisplay:YES];
    }
}

-(void)removeTempPoint
{
    m_bHaveTempPoint = false;
}

-(BOOL)isHaveTempPoint
{
    return m_bHaveTempPoint && m_bIntermediate;
}

-(IntPoint)tempPoint
{
    return m_sTempPoint;
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
    [self removeTempPoint];
    [[m_idDocument selection] setActive:YES];
    
    return YES;
}

@end
