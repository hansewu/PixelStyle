#import "CloneTool.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSController.h"
#import "PSLayer.h"
#import "StandardMerge.h"
#import "PSWhiteboard.h"
#import "PSLayerUndo.h"
#import "PSView.h"
#import "PSBrush.h"
#import "BrushUtility.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSTexture.h"
#import "BrushOptions.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "Bucket.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "CloneOptions.h"
#import "OptionsUtility.h"

#import "PSSelection.h"

#define EPSILON 0.0001

@implementation CloneTool

- (int)toolId
{
	return kCloneTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Clone Stamp Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"S";
}

- (id)init
{
	if(![super init])
		return NULL;
	m_bSourceSet = NO;
	m_pMergedData = NULL;
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"brush-cursor"] hotSpot:NSMakePoint(1, 14)];
    
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@.",NSLocalizedString(@"Opt - Define a source", nil)];
    
	return self;
}

- (void)dealloc
{    
	[super dealloc];
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)plotBrush:(id)brush at:(NSPoint)point pressure:(int)pressure
{
    //NSLog(@"dddddd %d",pressure);
	id layer = [[m_idDocument contents] activeLayer];
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
	unsigned char *brushData;
	int brushWidth = [(PSBrush *)brush fakeWidth], brushHeight = [(PSBrush *)brush fakeHeight];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	int i, j, spp = [[m_idDocument contents] spp], overlayPos;
	IntPoint ipoint = NSPointMakeIntPoint(point);
	
	if ([brush usePixmap]) {
	
		// We can't handle this for anything but 4 samples per pixel
        if (spp != 4){
            [overlayData unLockDataForWrite];
			return;
        }
		
		// Get the approrpiate brush data for the point
		brushData = [brush pixmapForPoint:point];
		
		// Go through all valid points
		for (j = 0; j < brushHeight; j++) {
			for (i = 0; i < brushWidth; i++) {
				if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
					
					// Change the pixel colour appropriately
					overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * 4;
					specialMerge(4, overlay, overlayPos, brushData, (j * brushWidth + i) * 4, pressure);
					
				}
			}
		}
	}
	else {
		
		// Get the approrpiate brush data for the point
		brushData = [brush maskForPoint:point pressure:255];
	
		// Go through all valid points
		for (j = 0; j < brushHeight; j++) {
			for (i = 0; i < brushWidth; i++) {
				if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
					
					// Change the pixel colour appropriately
					overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
					m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];
					specialMerge(spp, overlay, overlayPos, m_aBasePixel, 0, pressure);
					
				}
			}
		}
		
	}
    [overlayData unLockDataForWrite];
	// Set the last plot point appropriately
	m_poiLastPlot = point;
}

- (BOOL)sourceSet
{
	return m_bSourceSet;
}

- (int)sourceSetting
{
	return m_nSourceSetting;
}

- (IntPoint)sourcePoint:(BOOL)local
{
	IntPoint outPoint;
	
	if (local) {
		outPoint.x = m_sSourcePoint.x;
		outPoint.y = m_sSourcePoint.y;
	}
	else {
        IntPoint tempPoint = m_sSourcePoint;
		outPoint.x = tempPoint.x + m_sLayerOff.x;
		outPoint.y = tempPoint.y + m_sLayerOff.y;
	}
	
	return outPoint;
}

- (NSString *)sourceName
{
	if (m_bSourceMerged == NO)
		return [(PSLayer *)m_idSourceLayer name];
	else
		return NULL;
}

- (IntPoint)transformPoint:(IntPoint)srcPoint WithTranfrom:(NSAffineTransform*)transform
{
    NSPoint tempPoint = IntPointMakeNSPoint(srcPoint);
    tempPoint = [transform transformPoint:tempPoint];
    return IntMakePoint(tempPoint.x, tempPoint.y);
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
	id layer = [[m_idDocument contents] activeLayer];
    
    id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
    
	id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
	NSPoint curPoint = IntPointMakeNSPoint(where), temp;
	IntRect rect;
	int spp = [[m_idDocument contents] spp];
	int pressure = [boptions pressureValue:event];
	BOOL ignoreFirstTouch;
	unsigned char *sourceData;
	int sourceWidth, sourceHeight;
	IntPoint spt;
	float xScale, yScale;
	int modifier = [(CloneOptions *)m_idOptions modifier];
    
    
	if (modifier == kAltModifier) {
		xScale = [[m_idDocument contents] xscale];
		yScale = [[m_idDocument contents] yscale];
		if (m_nSourceSetting > 0) {
			m_nSourceSetting = 0;
			[[m_idDocument docView] setNeedsDisplayInRect:NSMakeRect((m_sSourcePoint.x + m_sLayerOff.x) * xScale - 12, (m_sSourcePoint.y + m_sLayerOff.y) * yScale - 10, 25, 26)];
		}
		m_bSourceMerged = [m_idOptions mergedSample];
		if (m_bSourceMerged) {
			m_sLayerOff.x = [[[m_idDocument contents] activeLayer] xoff];
			m_sLayerOff.y = [[[m_idDocument contents] activeLayer] yoff];
			m_sSourcePoint = where;
			m_bSourceSet = NO;
            //modify by lcz
			//sourceWidth = [(PSContent *)[m_idDocument contents] width];
			//sourceHeight = [(PSContent *)[m_idDocument contents] height];
			m_nSourceSetting = 100;
		}
		else {
			m_sLayerOff.x = [[[m_idDocument contents] activeLayer] xoff];
			m_sLayerOff.y = [[[m_idDocument contents] activeLayer] yoff];
			m_sSourcePoint = where;
			m_bSourceSet = NO;
			m_idSourceLayer = [[m_idDocument contents] activeLayer];
			m_nSourceSetting = 100;
		}
		[[m_idDocument docView] setNeedsDisplayInRect:NSMakeRect((m_sSourcePoint.x + m_sLayerOff.x) * xScale - 12, (m_sSourcePoint.y + m_sLayerOff.y) * yScale - 10, 25, 26)];
	}
	else if (m_bSourceSet) {
        int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
        int layerSpp = [layer spp];
        
        [[m_idDocument whiteboard] clearOverlay];
        memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
        if (m_layerRawData) {
            free(m_layerRawData);
            m_layerRawData = nil;
        }
        unsigned char *layerData = [layer getRawData];
        m_layerRawData = malloc(width * height * layerSpp);
        //memcpy(m_layerRawData, layerData, width * height * layerSpp);
        [layer unLockRawData];
        
        
		// Find the source
		if (m_bSourceMerged) {
			sourceWidth = [(PSContent *)[m_idDocument contents] width];
			sourceHeight = [(PSContent *)[m_idDocument contents] height];
			if (m_pMergedData) {
				free(m_pMergedData);
				m_pMergedData = NULL;
			}
			m_pMergedData = malloc(make_128(sourceWidth * sourceHeight * spp));
			memcpy(m_pMergedData, [(PSWhiteboard *)[m_idDocument whiteboard] data], sourceWidth * sourceHeight * spp);
			sourceData = m_pMergedData;
		}
		else {
			sourceData = m_layerRawData;
			sourceWidth = [(PSLayer *)m_idSourceLayer width];
			sourceHeight = [(PSLayer *)m_idSourceLayer height];
		}
		
		// Determine whether operation should continue
		m_sStartPoint.x = where.x;
		m_sStartPoint.y = where.y;
		m_sLastWhere.x = where.x;
		m_sLastWhere.y = where.y;
		m_bMultithreaded = [[PSController m_idPSPrefs] multithreaded];
		ignoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
		if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) && [boptions pressureSensitive] && !(modifier == kAltModifier)) {
			m_bFirstTouchDone = NO;
			return;
		}
		else {
			m_bFirstTouchDone = YES;
		}
		
		// Set the appropriate overlay opacity
		m_bIsErasing = NO;
//		[[m_idDocument whiteboard] setOverlayOpacity:255];
//		[[m_idDocument whiteboard] setOverlayBehaviour:kMaskingBehaviour];
        
        [[m_idDocument whiteboard] setOverlayOpacity:0];
        m_overlayBehaviour = kMaskingBehaviour;
		
		// Plot the initial point
		rect.size.width = [(PSBrush *)curBrush fakeWidth] + 1;
		rect.size.height = [(PSBrush *)curBrush fakeHeight] + 1;
		temp = NSMakePoint(curPoint.x - (float)([(PSBrush *)curBrush width] / 2) - 1.0, curPoint.y - (float)([(PSBrush *)curBrush height] / 2) - 1.0);
		rect.origin = NSPointMakeIntPoint(temp);
		rect.origin.x--; rect.origin.y--;
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
        IntRect selectRect = [[m_idDocument selection] localRect];
        BOOL useSelection = [[m_idDocument selection] active];
        if (useSelection) {
            rect = IntConstrainRect(rect, selectRect);
        }
        
		if (rect.size.width > 0 && rect.size.height > 0)
        {
			[self plotBrush:curBrush at:temp pressure:pressure];
			if (!m_bIsErasing)
            {
				spt.x = m_sSourcePoint.x + (rect.origin.x - m_sStartPoint.x) - 1;
				spt.y = m_sSourcePoint.y + (rect.origin.y - m_sStartPoint.y) - 1;
                
                IntRect srcRect = rect;
                srcRect.origin = spt;
                [self copyRawDataToTempInRect:srcRect];
                
                PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
                IMAGE_DATA imageData = [overlayData lockDataForWrite];
                unsigned char *overlay = imageData.pBuffer;
				cloneFill(spp, rect, overlay, [[m_idDocument whiteboard] replace], [(PSLayer *)layer width], [(PSLayer *)layer height], sourceData, sourceWidth, sourceHeight, spt);
                [overlayData unLockDataForWrite];
                
			}
            
            [self combineDataToLayerInRect:rect];
			//[[m_idDocument helpers] overlayChanged:rect inThread:YES];
            PSLayer *layer = [[m_idDocument contents] activeLayer];
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
		}
		
		// Record the position as the last point
		m_poiLast = m_poiLastPlot = curPoint;
		m_dDistance = 0;
		
		// Create the points list
		m_pCTPRPoints = malloc(kMaxBTPoints * sizeof(CTPointRecord));
		m_nPos = m_nDrawingPos = 0;
		m_nLastPressure = -1;
		
		// Detach the thread
		if (m_bMultithreaded) {
			m_bDrawingDone = NO;
			[NSThread detachNewThreadSelector:@selector(drawThread:) toTarget:self withObject:NULL];
		}
	
    }else{
        //warning for setting source
        [[PSController seaWarning] showAlertInfo:NSLocalizedString(@"Could not use the clone stamp because the area to clone has not been defined (option-click or right-click to define a source point).", nil) infoText:NSLocalizedString(@"", nil)];
    }
}

- (void)combineDataToLayerInRect:(IntRect)rect
{
    [self combineWillBeProcessDataRect:rect];
    [self copyRawDataToTempInRect:rect];
    
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
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    unsigned char *replace = [[m_idDocument whiteboard] replace];
    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++) {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++) {
            
            if (i >= 0 && i < width && j >= 0 && j < height) {
                
                int overlayPos = (j * width + i) * spp;
                int brushAlpha = replace[j * width + i];
                if (useSelection) {
                    IntPoint tempPoint;
                    tempPoint.x = i;
                    tempPoint.y = j;
                    if (IntPointInRect(tempPoint, selectRect)) {
                        if (mask && !floating)
                            brushAlpha = int_mult(brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }else{
                        brushAlpha = 0;
                    }
                }
                if (brushAlpha > 0) {
                    if (selectedChannel == kAllChannels && !floating) {
                        specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                        if (m_overlayBehaviour == kNormalBehaviour) {
//                            specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                        }else if (m_overlayBehaviour == kErasingBehaviour){
//                            eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                        }
                    }
                    else if (selectedChannel == kPrimaryChannels || floating) {
                        unsigned char tempSpace[spp];
                        memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                        primaryMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO);
                        memcpy(layerData + overlayPos, tempSpace, spp);
                    }
                    else if (selectedChannel == kAlphaChannel) {
                        unsigned char tempSpace[spp];
                        memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                        alphaMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha);
                        memcpy(layerData + overlayPos, tempSpace, spp);
                    }
                }
                
            }
        }
    }
    [overlayData unLockDataForWrite];
    [layer unLockRawData];
}

- (void)drawThread:(id)object
{
	NSAutoreleasePool *pool = NULL;
	NSPoint curPoint;
	id layer;
	int layerWidth, layerHeight;
	id curBrush, activeTexture;
	int brushWidth, brushHeight;
	double brushSpacing;
	double deltaX, deltaY, mag, xd, yd, dist;
	double stFactor, stOffset;
	double t0, dt, tn, t;
	double total, initial;
	int n, num_points, spp;
	IntRect rect, trect, bigRect;
	NSPoint temp;
	int pressure, origPressure;
	NSDate *lastDate;
	unsigned char *sourceData;
	int sourceWidth, sourceHeight;
	IntPoint spt;

	// Create autorelease pool if needed
	if (m_bMultithreaded) {
		pool = [[NSAutoreleasePool alloc] init];
	}

	// Set-up variables
	layer = [[m_idDocument contents] activeLayer];
    
    //curBrush = m_idUsedBrush;
	curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
	layerWidth = [(PSLayer *)layer width];
	layerHeight = [(PSLayer *)layer height];
	brushWidth = [(PSBrush *)curBrush fakeWidth];
	brushHeight = [(PSBrush *)curBrush fakeHeight];
	activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
	brushSpacing = (double)[(BrushUtility *)[[PSController utilitiesManager] brushUtilityFor:m_idDocument] spacing] / 100.0;
	spp = [[m_idDocument contents] spp];
	bigRect = IntMakeRect(0, 0, 0, 0);
	lastDate = [NSDate date];
    
	if (m_bSourceMerged)
    {
		sourceData = m_pMergedData;
		sourceWidth = [(PSContent *)[m_idDocument contents] width];
		sourceHeight = [(PSContent *)[m_idDocument contents] height];
	}
	else
    {
        sourceData = m_layerRawData;
		sourceWidth = [(PSLayer *)m_idSourceLayer width];
		sourceHeight = [(PSLayer *)m_idSourceLayer height];
	}
	
	// While we are not done...
	do {

next:
		if (m_nDrawingPos < m_nPos)
        {
            if(!m_pCTPRPoints) return;
			// Get the next record and carry on
			curPoint = IntPointMakeNSPoint(m_pCTPRPoints[m_nDrawingPos].point);
			origPressure = m_pCTPRPoints[m_nDrawingPos].pressure;
			if (m_pCTPRPoints[m_nDrawingPos].special == 2) {
                if (bigRect.size.width != 0){
                    [self combineDataToLayerInRect:bigRect];
                    PSLayer *layer = [[m_idDocument contents] activeLayer];
                    [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(bigRect)];
                    //[[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
                }
				m_bDrawingDone = YES;
				if (m_bMultithreaded) [pool release];
				return;
			}
			m_nDrawingPos++;
		
			// Determine the change in the x and y directions
			deltaX = curPoint.x - m_poiLast.x;
			deltaY = curPoint.y - m_poiLast.y;
			if (deltaX == 0.0 && deltaY == 0.0) {
				if (m_bMultithreaded)
					goto next;
                else{
					return;
                }
			}
			
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
				if (m_bMultithreaded)
					goto next;
                else{
					return;
                }
				
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
				if (t0 < 0.0 && !(x == (int)floor(m_poiLast.x) && y == (int)floor(m_poiLast.y))) {
					s0 += direction;
				}
				if (x == (int)floor(m_poiLastPlot.x) && y == (int)floor(m_poiLastPlot.y)) {
					s0 += direction;
				}
				x = (int)floor(m_poiLast.x + tn * deltaX);
				y = (int)floor(m_poiLast.y + tn * deltaY);
				if (tn > 1.0 && !(x == (int)floor(m_poiLast.x) && y == (int)floor(m_poiLast.y))) {
					sn -= direction;
				}
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
				temp = NSMakePoint(m_poiLast.x + deltaX * t - (float)(brushWidth / 2), m_poiLast.y + deltaY * t - (float)(brushHeight / 2));
				rect.origin = NSPointMakeIntPoint(temp);
				rect.origin.x--; rect.origin.y--;
				rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
                IntRect selectRect = [[m_idDocument selection] localRect];
                BOOL useSelection = [[m_idDocument selection] active];
                if (useSelection) {
                    rect = IntConstrainRect(rect, selectRect);
                }
                
				pressure = origPressure;
				if (m_nLastPressure > -1 && abs(pressure - m_nLastPressure) > 5) {
					pressure = m_nLastPressure + 5 * sgn(pressure - m_nLastPressure);
				}
				m_nLastPressure = pressure;
				if (rect.size.width > 0 && rect.size.height > 0 && pressure > 0) {
                    
					[self plotBrush:curBrush at:temp pressure:pressure];
					if (!m_bIsErasing) {
						spt.x = m_sSourcePoint.x + (rect.origin.x - m_sStartPoint.x) - 1;
						spt.y = m_sSourcePoint.y + (rect.origin.y - m_sStartPoint.y) - 1;
                        
                        IntRect srcRect = rect;
                        srcRect.origin = spt;
                        [self copyRawDataToTempInRect:srcRect];
                        
                        PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
                        IMAGE_DATA imageData = [overlayData lockDataForWrite];
                        unsigned char *overlay = imageData.pBuffer;
						cloneFill(spp, rect, overlay, [[m_idDocument whiteboard] replace], [(PSLayer *)layer width], [(PSLayer *)layer height], sourceData, sourceWidth, sourceHeight, spt);
                        [overlayData unLockDataForWrite];
                        
					}
					if (bigRect.size.width == 0) {
						bigRect = rect;
					}
					else {
						trect.origin.x = MIN(rect.origin.x, bigRect.origin.x);
						trect.origin.y = MIN(rect.origin.y, bigRect.origin.y);
						trect.size.width = MAX(rect.origin.x + rect.size.width - trect.origin.x, bigRect.origin.x + bigRect.size.width - trect.origin.x);
						trect.size.height = MAX(rect.origin.y + rect.size.height - trect.origin.y, bigRect.origin.y + bigRect.size.height - trect.origin.y);
						bigRect = trect;
					}
                    
				}
			}
			
			// Update the distance and plot points
			m_dDistance = total;
			m_poiLast.x = m_poiLast.x + deltaX;
			m_poiLast.y = m_poiLast.y + deltaY; 
		
		}
		else {
			if (m_bMultithreaded) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
        
		// Update periodically
		if (m_bMultithreaded) {
			if (bigRect.size.width != 0 && [[NSDate date] timeIntervalSinceDate:lastDate] > 0.02) {
				[[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
				lastDate = [NSDate date];
				bigRect = IntMakeRect(0, 0, 0, 0);
			}
		}
		else {
			//[[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
            
            //NSLog(@"rentL %@,%@",NSStringFromRect(IntRectMakeNSRect(rect)),NSStringFromRect(IntRectMakeNSRect(bigRect)));
            [self combineDataToLayerInRect:bigRect];
            PSLayer *layer = [[m_idDocument contents] activeLayer];
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(bigRect)];
		}
		
	} while (m_bMultithreaded);
    
    
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
    
	if (m_bSourceSet) {

		// Have we registerd the first touch
		if (!m_bFirstTouchDone) {
			[self mouseDownAt:where withEvent:event];
			m_bFirstTouchDone = YES;
		}
		
		// Check this is a new point
		if (where.x == m_sLastWhere.x && where.y == m_sLastWhere.y) {
			return;
		}
		else {
			m_sLastWhere = where;
		}

		// Add to the list
		if (m_nPos < kMaxBTPoints - 1) {
			m_pCTPRPoints[m_nPos].point = where;
			m_pCTPRPoints[m_nPos].pressure = [boptions pressureValue:event];
            m_pCTPRPoints[m_nPos].special = 0;
			m_nPos++;
		}
		else if (m_nPos == kMaxBTPoints - 1) {
			m_pCTPRPoints[m_nPos].special = 2;
			m_nPos++;
		}
		
		// Draw if drawing is not multithreaded
		if (!m_bMultithreaded) {
			[self drawThread:NULL];
		}

	}
}

- (void)endLineDrawing
{
	// Tell the other thread to terminate
	if (m_nPos < kMaxBTPoints) {
        if (m_pCTPRPoints) {
            m_pCTPRPoints[m_nPos].special = 2;
        }
		
		m_nPos++;
	}

	// If multithreaded, wait until the other thread finishes
	if (m_bMultithreaded) {
		while (!m_bDrawingDone) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
	}
	else {
		[self drawThread:NULL];
	}
}

- (IBAction)fade:(id)sender
{
	float xScale, yScale;
	
	if (m_nSourceSetting > 0) {
		m_nSourceSetting -= 20;
		m_idFadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
		xScale = yScale = 1.0;
		xScale = [[m_idDocument contents] xscale];
		yScale = [[m_idDocument contents] yscale];
       
        IntPoint tempPoint = m_sSourcePoint;
        
		[[m_idDocument docView] setNeedsDisplayInRect:NSMakeRect((tempPoint.x + m_sLayerOff.x) * xScale - 12, (tempPoint.y + m_sLayerOff.y) * yScale - 10, 25, 26)];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    
	float xScale, yScale;
	
	if (m_nSourceSetting) {
		
		// Start the source setting
		m_idFadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
		m_bSourceSet = YES;
		xScale = [[m_idDocument contents] xscale];
		yScale = [[m_idDocument contents] yscale];
		[[m_idDocument docView] setNeedsDisplayInRect:NSMakeRect((m_sSourcePoint.x + m_sLayerOff.x) * xScale - 12, (m_sSourcePoint.y + m_sLayerOff.y) * yScale - 10, 25, 26)];
		[m_idOptions update];
	
	}
	else if (m_bSourceSet) {
		// Apply the changes
		[self endLineDrawing];
		//[(PSHelpers *)[m_idDocument helpers] applyOverlay];
		
	}
    m_bFirstTouchDone = NO;
    
//    [m_idUsedBrush deactivate];
//    [m_idOldBrush activate];
    
	// Free merged data
	if (m_pMergedData) {
		free(m_pMergedData);
		m_pMergedData = NULL;
	}
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    if (m_dataChangedRect.size.width != 0 && m_dataChangedRect.size.height != 0) {
        [self copyRawDataToTempInRect:m_dataChangedRect];
        if (m_layerRawData) {
            [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
        }
    }
    
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    int modifier = [(CloneOptions *)m_idOptions modifier];
    if (modifier == kAltModifier)
        [self updateMakeSourceCursor];
    else
        [self updateCursor];
    
    [super mouseMoveTo:where withEvent:event];
}

-(void)updateCursor
{
    id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
    float fRadius = ([(PSBrush *)curBrush fakeWidth] + 1.0) / 2.0;
    
    float fScale = [[m_idDocument docView] zoom];
    
    if(2 * fRadius * fScale + 1 <= 5)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"minor-paint-cursor"] hotSpot:NSMakePoint(7, 7)] ;
        
        return;
    }
    
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(2 * fRadius * fScale + 1, 2 * fRadius * fScale + 1)] autorelease];
    [image lockFocus];
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [[NSColor whiteColor] set];
    CGContextStrokeEllipseInRect(ctx, CGRectMake(0, 0, 2 * fRadius * fScale + 1, 2 * fRadius * fScale + 1));
    
    [[NSColor blackColor] set];
    CGContextStrokeEllipseInRect(ctx, CGRectMake(1, 1, 2 * fRadius * fScale - 1, 2 * fRadius * fScale - 1));
    
    [image unlockFocus];
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(fRadius * fScale, fRadius * fScale)];
}

-(void)updateMakeSourceCursor
{
    id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
    float fRadius = ([(PSBrush *)curBrush fakeWidth] + 1.0) / 2.0;
    
    float fScale = [[m_idDocument docView] zoom];
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(2 * fRadius * fScale + 1, 2 * fRadius * fScale + 1)] autorelease];
    [image lockFocus];
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [[NSColor whiteColor] set];
    CGContextStrokeEllipseInRect(ctx, CGRectMake(0.25*fRadius * fScale, 0.25*fRadius * fScale,  1.5*fRadius * fScale + 1,  1.5*fRadius * fScale + 1));
    
    [[NSColor blackColor] set];
    CGContextStrokeEllipseInRect(ctx, CGRectMake(0.25*fRadius * fScale + 1, 0.25*fRadius * fScale+1,  1.5*fRadius * fScale - 1,  1.5*fRadius * fScale - 1));
    
    CGContextFillRect(ctx, NSMakeRect(0 , fRadius * fScale, 2* fRadius * fScale, 1));
    
    CGContextFillRect(ctx, NSMakeRect(fRadius * fScale, 0, 1, 2*fRadius * fScale));
    
    [image unlockFocus];
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(fRadius * fScale, fRadius * fScale)];
}

- (void)unset
{
	m_bSourceSet = NO;
	[m_idOptions update];
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

-(BOOL)isAffectedBySelection
{
    int modifier = [(CloneOptions *)m_idOptions modifier];
    if (modifier == kAltModifier)
        return NO;
    
    return YES;
}

@end
