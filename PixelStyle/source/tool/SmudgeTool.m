#import "SmudgeTool.h"
#import "PSTools.h"
#import "PSBrush.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "BrushUtility.h"
#import "PSLayer.h"
#import "StandardMerge.h"
#import "PSHelpers.h"
#import "PSWhiteboard.h"
#import "SmudgeOptions.h"

#import "PSSelection.h"
#import "PSLayerUndo.h"

#define EPSILON 0.0001

@implementation SmudgeTool

- (id)init
{
    self = [super init];
    if(self)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"smudge-cursor"] hotSpot:NSMakePoint(1, 15)];
    }
    return self;
}

- (int)toolId
{
	return kSmudgeTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Smudge Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"O";
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)smudgeWithBrush:(id)brush at:(NSPoint)point
{
	id contents = [m_idDocument contents];
	id layer = [contents activeLayer];
    
	unsigned char *replace = [(PSWhiteboard *)[m_idDocument whiteboard] replace];
	unsigned char *brushData, basePixel[4];
	int brushWidth = [(PSBrush *)brush fakeWidth], brushHeight = [(PSBrush *)brush fakeHeight];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	int i, j, k, tx, ty, t1, t2, pos, spp = [[m_idDocument contents] spp];
	int rate = [(SmudgeOptions *)m_idOptions rate];
	IntPoint ipoint = NSPointMakeIntPoint(point);
	int selectedChannel = [[m_idDocument contents] selectedChannel];
	
	// Get the approrpiate brush data for the point
	brushData = [brush maskForPoint:point pressure:255];
    
//    unsigned char *data = [(PSLayer *)layer getRawData];
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;

	// Go through all valid points
	for (j = 0; j < brushHeight; j++) {
		for (i = 0; i < brushWidth; i++) {
			tx = ipoint.x + i;
			ty = ipoint.y + j;
			if (tx >= 0 && ty >= 0 && tx < width && ty < height) {
				
				// Change the pixel colour appropriately
				pos = ty * width + tx;
//				if (replace[pos] == 255) {
//					if (selectedChannel == kAlphaChannel)
//						basePixel[spp - 1] = overlay[pos * spp];
//					else
//						memcpy(basePixel, &(overlay[pos * spp]), spp);
//				}
//				else
//                    if (replace[pos] == 0) {
//					memcpy(basePixel, &(data[pos * spp]), spp);
//				}
//				else
//                {
//					if (selectedChannel == kAlphaChannel) {
//						basePixel[spp - 1] = int_mult(overlay[pos * spp], replace[pos], t1) + int_mult(data[(pos + 1) * spp - 1], 255 - replace[pos], t2);
//					}
//					else
                    {
						for (k = 0; k < spp; k++)
                        {
                            basePixel[k] = int_mult((overlay[pos * spp + k]), replace[pos], t1) + int_mult(m_layerRawData[pos * spp + k], 255 - replace[pos], t2);
                        }
					}
//				}
//				if (selectedChannel == kPrimaryChannels) {
//					basePixel[spp - 1] = 255;
//				}
//				else if (selectedChannel == kAlphaChannel) {
//					for (k = 0; k < spp - 1; k++)
//						basePixel[k] = basePixel[spp - 1];
//					basePixel[spp - 1] = 255;
//				}
				blendPixel(spp, m_pAccumData, (j * brushWidth + i) * spp, basePixel, 0, rate);
				replace[pos] = brushData[j * brushWidth + i] + int_mult((255 - brushData[j * brushWidth + i]), replace[pos], t1);
				memcpy(&(overlay[pos * spp]), &(m_pAccumData[(j * brushWidth + i) * spp]), spp);
				
			}
		}
	}
	
    [overlayData unLockDataForWrite];
//    [(PSLayer *)layer unLockRawData];
	// Set the last plot point appropriately
	m_poiLastPlot = point;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
	id layer = [[m_idDocument contents] activeLayer];
    
    [layer setFullRenderState:NO];
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    
	int layerWidth = [(PSLayer *)layer width], layerHeight = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    if (m_layerRawData) {free(m_layerRawData);m_layerRawData = NULL;}
    m_layerRawData = malloc(layerWidth * layerHeight * layerSpp);
    
    
    
	id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
	int brushWidth = [(PSBrush *)curBrush fakeWidth], brushHeight = [(PSBrush *)curBrush fakeHeight];
	int i, j, k, tx, ty, spp = [[m_idDocument contents] spp];
	NSPoint curPoint = IntPointMakeNSPoint(where), temp;
	int selectedChannel = [[m_idDocument contents] selectedChannel];
	unsigned char basePixel[4];
	NSColor *color = NULL;
	IntRect rect;
	
	// Prepare for the accumulating data
	m_sLastWhere.x = where.x;
	m_sLastWhere.y = where.y;
	if (m_pAccumData) { free(m_pAccumData); m_pAccumData = NULL; }
	m_pAccumData = malloc(brushWidth * brushHeight * spp);
	memset(m_pAccumData, 0, brushWidth * brushHeight * spp);
	if (![layer hasAlpha]) {
		color = [[m_idDocument contents] background];
		if (spp == 4) {
			basePixel[0] = (unsigned char)([color redComponent] * 255.0);
			basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
			basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
			basePixel[3] = 255;
		}
		else {
			basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
			basePixel[1] = 255;
		}
		for (i = 0; i < brushWidth * brushHeight; i++)
			memcpy(&(m_pAccumData[i * spp]), basePixel, spp);
	}
	
	// Fill the accumulator with what's beneath the brush to start with
    unsigned char *data = [(PSLayer *)layer getRawData];
    
	for (j = 0; j < brushHeight; j++) {
		for (i = 0; i < brushWidth; i++) {
			tx = where.x - brushWidth / 2 + i;
			ty = where.y - brushHeight / 2 + j;
			if (tx >= 0 && tx < layerWidth && ty >= 0 && ty < layerHeight) {
				memcpy(&(m_pAccumData[(j * brushWidth + i) * spp]), &(data[(ty * layerWidth + tx) * spp]), spp);
				if (selectedChannel == kPrimaryChannels) {
					m_pAccumData[(j * brushWidth + i + 1) * spp - 1] = 255;
				}
				else if (selectedChannel == kAlphaChannel) {
					for (k = 0; k < spp - 1; k++)
						m_pAccumData[(j * brushWidth + i) * spp + k] = m_pAccumData[(j * brushWidth + i + 1) * spp - 1];
					m_pAccumData[(j * brushWidth + i + 1) * spp - 1] = 255;
				}
			}
		}
	}
    
    [(PSLayer *)layer unLockRawData];
    
	// Make the overlay opaque
    [[m_idDocument whiteboard] setOverlayOpacity:255];
//	[[m_idDocument whiteboard] setOverlayBehaviour:kReplacingBehaviour];
//
	// Plot the intial point
	rect.size.width = [(PSBrush *)curBrush fakeWidth] + 1;
	rect.size.height = [(PSBrush *)curBrush fakeHeight] + 1;
	temp = NSMakePoint((int)curPoint.x - [(PSBrush *)curBrush width] / 2, (int)curPoint.y - [(PSBrush *)curBrush height] / 2);
	rect.origin = NSPointMakeIntPoint(temp);
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
    
    IntRect selectRect = [[m_idDocument selection] localRect];
    BOOL useSelection = [[m_idDocument selection] active];
    if (useSelection) {
        rect = IntConstrainRect(rect, selectRect);
    }
    
	if (rect.size.width > 0 && rect.size.height > 0) {
        [self copyRawDataToTempInRect:rect];
		[self smudgeWithBrush:curBrush at:temp];
//		[[m_idDocument helpers] overlayChanged:rect inThread:NO];
        
        [self combineDataToLayerInRect:rect];
        [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
	}
	// Record the position as the last point
	m_poiLast = m_poiLastPlot = IntPointMakeNSPoint(where);
	m_dDistance = 0;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	int layerWidth = [(PSLayer *)layer width], layerHeight = [(PSLayer *)layer height];
	id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
	int brushWidth = [(PSBrush *)curBrush fakeWidth], brushHeight = [(PSBrush *)curBrush fakeHeight];
	NSPoint curPoint = IntPointMakeNSPoint(where);
	double brushSpacing = 1.0 / 100.0;
	double deltaX, deltaY, mag, xd, yd, dist;
	double stFactor, stOffset;
	double t0, dt, tn, t;
	double total, initial;
	int n, num_points;
	IntRect rect;
	NSPoint temp;
	
	// Check this is a new point
	if (where.x == m_sLastWhere.x && where.y == m_sLastWhere.y) {
		return;
	}
	else {
		m_sLastWhere = where;
	}
	
	// Determine the change in the x and y directions
	deltaX = curPoint.x - m_poiLast.x;
	deltaY = curPoint.y - m_poiLast.y;
	if (deltaX == 0.0 && deltaY == 0.0)
		return;
	
	// Determine the number of brush strokes in the x and y directions
	mag = (float)(brushWidth / 2);
	xd = (mag * deltaX) / sqr(mag);
	mag = (float)(brushHeight / 2);
	yd = (mag * deltaY) / sqr(mag);
	
	// Determine the brush stroke distance and hence determine the initial and total distance
	dist = 0.5 * sqrt(sqr(xd) + sqr(yd));		// Why is this halved?
	total = dist + m_dDistance;
	initial = m_dDistance;
	
	// Determine the stripe factor and offset
	if (sqr(deltaX) > sqr(deltaY)) {
		stFactor = deltaX;
		stOffset = m_poiLast.x - 0.5;
	}
	else {
		stFactor = deltaY;
		stOffset = m_poiLast.y - 0.5;
	}
	
	if (fabs(stFactor) > dist / brushSpacing) {
		
		// We want to draw the maximum number of points
		dt = brushSpacing / dist;
		n = (int)(initial / brushSpacing + 1.0 + EPSILON);
		t0 = (n * brushSpacing - initial) / dist;
		num_points = 1 + (int)floor((1 + EPSILON - t0) / dt);
		
	}
	else if (fabs(stFactor) < EPSILON) {
	
		// We can't draw any points - this does actually get called albeit once in a blue moon
		m_poiLast = curPoint;
		return;
		
    }
	else {
		
		// We want to draw a number of points
		int direction = stFactor > 0 ? 1 : -1;
		int x, y;
		int s0, sn;
		
		s0 = (int)floor(stOffset + 0.5);
		sn = (int)floor(stOffset + stFactor + 0.5);
		
		t0 = (s0 - stOffset) / stFactor;
		tn = (sn - stOffset) / stFactor;
		
		x = (int)floor(m_poiLast.x + t0 * deltaX);
		y = (int)floor(m_poiLast.y + t0 * deltaY);
		if ((t0 < 0.0 && !(x == (int)floor(m_poiLast.x) && y == (int)floor(m_poiLast.y))) || (x == (int)floor(m_poiLastPlot.x) && y == (int)floor(m_poiLastPlot.y))) s0 += direction;
		x = (int)floor(m_poiLast.x + tn * deltaX);
		y = (int)floor(m_poiLast.y + tn * deltaY);
		if (tn > 1.0 && !(x == (int)floor(m_poiLast.x) && y == (int)floor(m_poiLast.y))) sn -= direction;
		t0 = (s0 - stOffset) / stFactor;
		tn = (sn - stOffset) / stFactor;
		dt = direction * 1.0 / stFactor;
		num_points = 1 + direction * (sn - s0);
		
		if (num_points >= 1) {
			if (tn < 1)
				total = initial + tn * dist;
			total = brushSpacing * (int) (total / brushSpacing + 0.5);
			total += (1.0 - tn) * dist;
		}
		
	}
	
	// Draw all the points
	for (n = 0; n < num_points; n++) {
		t = t0 + n * dt;
		rect.size.width = brushWidth + 1;
		rect.size.height = brushHeight + 1;
		temp = NSMakePoint(m_poiLast.x + deltaX * t - (double)(brushWidth / 2) + 1.0, m_poiLast.y + deltaY * t - (float)(brushHeight / 2) + 1.0);
		rect.origin = NSPointMakeIntPoint(temp);
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
        
        IntRect selectRect = [[m_idDocument selection] localRect];
        BOOL useSelection = [[m_idDocument selection] active];
        if (useSelection) {
            rect = IntConstrainRect(rect, selectRect);
        }
        
		if (rect.size.width > 0 && rect.size.height > 0) {
//			[self smudgeWithBrush:curBrush at:temp];
//			[[m_idDocument helpers] overlayChanged:rect inThread:NO];
            [self copyRawDataToTempInRect:rect];
            [self smudgeWithBrush:curBrush at:temp];
            
            [self combineDataToLayerInRect:rect];
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
        }
    }
	// Update the distance and plot points
	m_dDistance = total;
	m_poiLast.x = m_poiLast.x + deltaX;
	m_poiLast.y = m_poiLast.y + deltaY;
}

- (void)combineDataToLayerInRect:(IntRect)rect
{
    [self combineWillBeProcessDataRect:rect];
    
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int spp = [(PSLayer *)layer spp];
    
    if (rect.origin.x < 0 || rect.origin.y < 0 || rect.size.width > width || rect.size.height > height) {
        return;
    }
    if (rect.size.width <= 0 || rect.size.height <= 0) {
        return;
    }
    
    unsigned char *layerData = [layer getRawData];
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    int selectedChannel = [[m_idDocument contents] selectedChannel];
    BOOL floating = [layer floating];
    int t1;
    int i, j;
    int selectOpacity;
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    unsigned char *replace = [[m_idDocument whiteboard] replace];

    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
        {
            if (i >= 0 && i < width && j >= 0 && j < height)
            {
                int overlayPos = (j * width + i) * spp;
                // Check if we should apply the overlay for this pixel
                BOOL overlayOkay = NO;
                selectOpacity = replace[j * width + i];
                
                if (useSelection)
                {
                    IntPoint tempPoint;
                    tempPoint.x = i;
                    tempPoint.y = j;
                    if (IntPointInRect(tempPoint, selectRect))
                    {
                        overlayOkay = YES;
                        if (mask && !floating)
                            selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }
                }
                else
                    overlayOkay = YES;
                
                // Don't do anything if there's no point
                if (selectOpacity == 0)
                    overlayOkay = NO;
                
                // Apply the overlay if we get the okay
                if (overlayOkay) {
                    if (selectedChannel == kAllChannels && !floating)
                        replaceMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, selectOpacity, 0);
                    else if (selectedChannel == kPrimaryChannels || floating)
                    {
                        if (selectOpacity > 0)
                            replaceMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, selectOpacity, 1);
                    }
                    else if (selectedChannel == kAlphaChannel)
                    {
                        if (selectOpacity > 0)
                            replaceMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, selectOpacity, 2);
                        
                    }
                }
            }
        }
    }
    [overlayData unLockDataForWrite];
    
    [layer unLockRawData];
    
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    if (m_layerRawData) {
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    }
    
    if (m_layerRawData) {free(m_layerRawData);m_layerRawData = NULL;}
    
    [layer setFullRenderState:YES];

////	// Apply the changes
//	[(PSHelpers *)[m_idDocument helpers] applyOverlay];
//
//	// Free the accumulating data
	if (m_pAccumData) { free(m_pAccumData); m_pAccumData = NULL; }
}

- (void)startStroke:(IntPoint)where;
{
	[self mouseDownAt:where withEvent:NULL];
}

- (void)intermediateStroke:(IntPoint)where
{
	[self mouseDraggedTo:where withEvent:NULL];
}

- (void)endStroke:(IntPoint)where
{
	[self mouseUpAt:where withEvent:NULL];
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return NO;
    
    return YES;
}

@end
