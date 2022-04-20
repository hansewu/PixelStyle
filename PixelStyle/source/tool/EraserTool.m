#import "EraserTool.h"
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
#import "EraserOptions.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "OptionsUtility.h"

#import "PSSelection.h"

#import "ocInpaint.h"

#define EPSILON 0.0001

@implementation EraserTool

- (id)init
{
    self = [super init];
    if(self)
    {
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Shift to draw straight lines. Press Shift & Ctrl to draw lies at 45 degrees.", nil)];
        m_pErasedFlagBuf = NULL;
    }
    
    return self;
}

- (int)toolId
{
	return kEraserTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Eraser Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"E";
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)acceptsLineDraws
{
	return YES;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)plotBrush:(id)brush at:(NSPoint)point pressure:(int)pressure
{
	id layer = [[m_idDocument contents] activeLayer];
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
	unsigned char *brushData;
	int brushWidth = [(PSBrush *)brush fakeWidth], brushHeight = [(PSBrush *)brush fakeHeight];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	int i, j, spp = [[m_idDocument contents] spp], overlayPos;
	IntPoint ipoint = NSPointMakeIntPoint(point);
	id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
	
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
    
    PS_EDIT_CHANNEL_TYPE editType = [layer editedChannelOfLayer];
    
	if ([brush usePixmap]) {
	
		// We can't handle this for anything but 4 samples per pixel
		if (spp != 4)
			return;
		
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
		if ([(BrushOptions *)boptions scale])
			brushData = [brush maskForPoint:point pressure:pressure];
		else
			brushData = [brush maskForPoint:point pressure:255];
	
		// Go through all valid points
		for (j = 0; j < brushHeight; j++) {
			for (i = 0; i < brushWidth; i++) {
				if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
					
					// Change the pixel colour appropriately
					overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
					m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];
					specialMerge(spp, overlay, overlayPos, m_aBasePixel, 0, pressure);
                    
                    //m_aBasePixel[spp - 1] = 254;
                    //eraseMerge(spp, layerData, overlayPos, m_aBasePixel, 0, pressure);
                    
                    int brushAlpha = m_brushAlpha;
                    if (useSelection) {
                        IntPoint tempPoint;
                        tempPoint.x = ipoint.x + i;
                        tempPoint.y = ipoint.y + j;
                        if (IntPointInRect(tempPoint, selectRect)) {
                            if (mask && !floating)
                                brushAlpha = int_mult(m_brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                        }else{
                            brushAlpha = 0;
                        }
                    }
                    if (brushAlpha > 0) {
//                        if (selectedChannel == kAllChannels && !floating) {
//                            if (m_overlayBehaviour == kNormalBehaviour) {
//                                specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                            }else if (m_overlayBehaviour == kErasingBehaviour){
//                                eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                            }
//                        }
//                        else if (selectedChannel == kPrimaryChannels || floating) {
//                            unsigned char tempSpace[spp];
//                            memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                            primaryMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO);
//                            memcpy(layerData + overlayPos, tempSpace, spp);
//                        }
//                        else if (selectedChannel == kAlphaChannel) {
//                            unsigned char tempSpace[spp];
//                            memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                            alphaMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha);
//                            memcpy(layerData + overlayPos, tempSpace, spp);
//                        }
                        
                        switch (editType) {
                            case kEditAllChannels:
                            {
                                if (m_overlayBehaviour == kNormalBehaviour)
                                {
                                    specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                                    
                                }
                                else if (m_overlayBehaviour == kErasingBehaviour)
                                {
                                    eraseMergeCustomWithFlag(spp, layerData, m_pErasedFlagBuf, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                                }
                            }
                                break;
                                
                            default:
                            {
                                unsigned char tempSpace[spp];
                                memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                                flexibleEraseMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, editType);
                                memcpy(layerData + overlayPos, tempSpace, spp);
                            }
                                break;
                        }

                        
                    }
				}
			}
		}
		
	}
	
    [overlayData unLockDataForWrite];
    [layer unLockRawData];
	// Set the last plot point appropriately
	m_poiLastPlot = point;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
	id layer = [[m_idDocument contents] activeLayer];
    [layer setFullRenderState:NO];
    
    BOOL hasAlpha = YES;//[layer hasAlpha]; //no background layer concept process to normal layer
	id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
	NSPoint curPoint = IntPointMakeNSPoint(where), temp;
	IntRect rect;
	NSColor *color = NULL;
	int spp = [[m_idDocument contents] spp];
	int pressure;
	BOOL ignoreFirstTouch;
	id boptions;
    
    
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    
    m_pErasedFlagBuf = (unsigned char *)malloc(width * height);
    memset(m_pErasedFlagBuf, 0, width * height);
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay];
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = nil;
    }
    m_layerRawData = malloc(width * height * layerSpp);
	
	// Determine whether operation should continue
	m_sLastWhere.x = where.x;
	m_sLastWhere.y = where.y;
	boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
	m_bMultithreaded = [[PSController m_idPSPrefs] multithreaded];
	ignoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
	if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown)  && !([(EraserOptions*)m_idOptions modifier] == kShiftModifier)) {
		m_bFirstTouchDone = NO;
		return;
	}
	else {
		m_bFirstTouchDone = YES;
	}
	if ([m_idOptions mimicBrush])
		pressure = [boptions pressureValue:event];
	else
		pressure = 255;
	
	// Determine background colour and hence the brush colour
	color = [[m_idDocument contents] background];
	if (spp == 4) {
		m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
		m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
		m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
		m_aBasePixel[3] = 255;
	}
	else {
		m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
		m_aBasePixel[1] = 255;
	}
	
	// Set the appropriate overlay opacity
//	if (hasAlpha)
//		[[m_idDocument whiteboard] setOverlayBehaviour:kErasingBehaviour];
//	[[m_idDocument whiteboard] setOverlayOpacity:[(EraserOptions*)m_idOptions opacity]];
	m_overlayBehaviour = kNormalBehaviour;
    if (hasAlpha)
        m_overlayBehaviour = kErasingBehaviour;
    m_brushAlpha = [(EraserOptions*)m_idOptions opacity] + 1;
    
	// Plot the initial point
	rect.size.width = [(PSBrush *)curBrush fakeWidth] + 1;
	rect.size.height = [(PSBrush *)curBrush fakeHeight] + 1;
	temp = NSMakePoint(curPoint.x - (float)([(PSBrush *)curBrush width] / 2) - 1.0, curPoint.y - (float)([(PSBrush *)curBrush height] / 2) - 1.0);
	rect.origin = NSPointMakeIntPoint(temp);
	rect.origin.x--; rect.origin.y--;
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
	if (rect.size.width > 0 && rect.size.height > 0) {
        [self copyRawDataToTempInRect:rect];
		[self plotBrush:curBrush at:temp pressure:pressure];
        
		[self combineWillBeProcessDataRect:rect];
        PSLayer *layer = [[m_idDocument contents] activeLayer];
        [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
	}
	
	// Record the position as the last point
	m_poiLast = m_poiLastPlot = curPoint;
	m_dDistance = 0;
	
	// Create the points list
    ETPointRecord *m_pTempETPRPoints = m_pETPRPoints;
	m_pETPRPoints = malloc(kMaxETPoints * sizeof(ETPointRecord));
    if (m_pTempETPRPoints) free(m_pTempETPRPoints);
	m_nPos = m_nDrawingPos = 0;
	
	// Detach the thread
	if (m_bMultithreaded) {
		m_bDrawingDone = NO;
		[NSThread detachNewThreadSelector:@selector(drawThread:) toTarget:self withObject:NULL];
	}
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
	double t0, dt, tn, t, dtx;
	double total, initial;
	double fadeValue;
	BOOL fade;
	int n, num_points, spp;
	IntRect rect, trect, bigRect;
	NSPoint temp;
	int pressure, origPressure;
	int tim;
	NSDate *lastDate;
	id boptions;
	
   // Create autorelease pool if needed
   if (m_bMultithreaded) {
		pool = [[NSAutoreleasePool alloc] init];
   }
   
   // Set-up variables
   layer = [[m_idDocument contents] activeLayer];
   curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
   layerWidth = [(PSLayer *)layer width];
   layerHeight = [(PSLayer *)layer height];
   brushWidth = [(PSBrush *)curBrush fakeWidth];
   brushHeight = [(PSBrush *)curBrush fakeHeight];
   activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
   boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
   brushSpacing = (double)[(BrushUtility*)[[PSController utilitiesManager] brushUtilityFor:m_idDocument] spacing] / 100.0;
   fade = [m_idOptions mimicBrush] && [boptions fade];
   fadeValue = [boptions fadeValue];
   spp = [[m_idDocument contents] spp];
   bigRect = IntMakeRect(0, 0, 0, 0);
   lastDate = [NSDate date];
   
	// While we are not done...
	do {

next:
		if (m_nDrawingPos < m_nPos) {
			
			// Get the next record and carry on
			curPoint = IntPointMakeNSPoint(m_pETPRPoints[m_nDrawingPos].point);
			origPressure = m_pETPRPoints[m_nDrawingPos].pressure;
			if (m_pETPRPoints[m_nDrawingPos].special == 2) {
				if (bigRect.size.width != 0) [[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
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
				else
					return;
			}
			
			// Determine the number of brush strokes in the x and y directions
			mag = (float)(brushWidth / 2);
			xd = (mag * deltaX) / sqr(mag);
			mag = (float)(brushHeight / 2);
			yd = (mag * deltaY) / sqr(mag);
			
			// Determine the brush stroke distance and hence determine the initial and total m_dDistance
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
				else
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
				if (fade) {
					dtx = (double)(initial + t * dist) / fadeValue;
					pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
					pressure = int_mult(pressure, origPressure, tim);
				}
				else {
					pressure = origPressure;
				}
				if (rect.size.width > 0 && rect.size.height > 0 && pressure > 0) {
                    [self copyRawDataToTempInRect:rect];
					[self plotBrush:curBrush at:temp pressure:pressure];
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
			[self combineWillBeProcessDataRect:bigRect];
            PSLayer *layer = [[m_idDocument contents] activeLayer];
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(bigRect)];
		}
		
	} while (m_bMultithreaded);
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    // Have we registerd the first touch
    if (!m_bFirstTouchDone) {
        [self mouseDownAt:where withEvent:event];
        m_bFirstTouchDone = YES;
        return;
    }
    
    if ([[m_idDocument docView] isLineDrawing]) {
        [self resetBrushInfo];
    }
    
	id boptions = [[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] getOptions:kBrushTool];
		
	// Check this is a new point
	if (where.x == m_sLastWhere.x && where.y == m_sLastWhere.y) {
		return;
	}
	else {
		m_sLastWhere = where;
	}
	
	// Add to the list
	if (m_nPos < kMaxETPoints - 1) {
		m_pETPRPoints[m_nPos].point = where;
		if ([m_idOptions mimicBrush])
			m_pETPRPoints[m_nPos].pressure = [boptions pressureValue:event];
		else
			m_pETPRPoints[m_nPos].pressure = 255;
        m_pETPRPoints[m_nPos].special = 0;
		m_nPos++;
	}
	else if (m_nPos == kMaxETPoints - 1) {
		m_pETPRPoints[m_nPos].special = 2;
		m_nPos++;
	}
	
	// Draw if drawing is not multithreaded
	if (!m_bMultithreaded) {
		[self drawThread:NULL];
        if ([[m_idDocument docView] isLineDrawing]) {
            [self oneLineDrawingEnd];
        }
	}
}

- (void)resetBrushInfo
{
    
    id layer = [[m_idDocument contents] activeLayer];
    [layer setFullRenderState:NO];
    
    BOOL hasAlpha = YES;//[layer hasAlpha]; //no background layer concept process to normal layer
    
    NSColor *color = NULL;
    int spp = [[m_idDocument contents] spp];
    
    
    // Determine background colour and hence the brush colour
    color = [[m_idDocument contents] background];
    if (spp == 4) {
        m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        m_aBasePixel[3] = 255;
    }
    else {
        m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        m_aBasePixel[1] = 255;
    }
    
    m_overlayBehaviour = kNormalBehaviour;
    if (hasAlpha)
        m_overlayBehaviour = kErasingBehaviour;
    m_brushAlpha = [(EraserOptions*)m_idOptions opacity] + 1;
    
}



- (void)oneLineDrawingEnd
{
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    if (m_layerRawData) {
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    }
    
    [layer setFullRenderState:YES];
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    
}

- (void)endLineDrawing
{
	// Tell the other thread to terminate
	if (m_nPos < kMaxETPoints) {
        if (m_pETPRPoints) {
            m_pETPRPoints[m_nPos].special = 2;
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

-(void)inpaint
{
    if([(EraserOptions*)m_idOptions fillType] ==1)  return;
    
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width];
    int height = [(PSLayer *)layer height];
    ocInpaint([layer getDirectData], m_pErasedFlagBuf, width, height, [(EraserOptions*)m_idOptions fillType]);
    [layer refreshTotalToRender];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	// Apply the changes
	[self endLineDrawing];
    m_bFirstTouchDone = NO;
    
    [self inpaint];
    if(m_pErasedFlagBuf)
    {
        free(m_pErasedFlagBuf);
        m_pErasedFlagBuf = NULL;
    }
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    [layer setFullRenderState:YES];
    
	//[(PSHelpers *)[m_idDocument helpers] applyOverlay];
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


-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
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


-(BOOL)exitTool:(int)newTool
{
    m_bFirstTouchDone = NO;
    return [super exitTool:newTool];
}

- (BOOL)stopCurrentOperation
{
    if ([[m_idDocument docView] isLineDrawing]) {
        m_bFirstTouchDone = NO;
        return YES;
    }
    return NO;
}


- (BOOL)enterKeyPressed
{
    if ([[m_idDocument docView] isLineDrawing]) {
        m_bFirstTouchDone = NO;
        return YES;
    }
    return NO;
}


@end
