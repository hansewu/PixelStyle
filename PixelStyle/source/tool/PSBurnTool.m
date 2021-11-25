//
//  PSBurnTool.m
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "PSBurnTool.h"
#import "PSBurnToolOptions.h"

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
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "Bucket.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSSelection.h"


#define EPSILON 0.0001


@implementation PSBurnTool

- (int)toolId
{
    return kBurnTool;
}


-(NSString *)toolTip
{
    return NSLocalizedString(@"Burn Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"O";
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
    
    BurnRange range = [m_idOptions getBurnRange];
    float exposure = [m_idOptions getExposureValue];
    
    if (NO) { //[brush usePixmap]
        
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
//        if ([(BrushOptions *)boptions scale])
//            brushData = [brush maskForPoint:point pressure:pressure];
//        else
//            brushData = [brush maskForPoint:point pressure:255];
        
        brushData = [brush maskForPoint:point pressure:255];
        
        // Go through all valid points
        for (j = 0; j < brushHeight; j++) {
            for (i = 0; i < brushWidth; i++) {
                if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
                    
                    // Change the pixel colour appropriately
                    overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
//                    m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];

//                    int nAlpha = (int)(m_imageBuffer.pBuffer[j* m_imageBuffer.nWidth*4 + i *4 + 3]);
//                    int nBrushData = brushData[j * brushWidth + i];
//                    m_aBasePixel[spp - 1] = int_mult(brushData[j * brushWidth + i], nBrushData/255.0 * 0.5 * nAlpha, t1);
                    
                    int y,x;
                    if(j <= brushHeight/2.0)
                        y = j + brushHeight/5.0;
                    else
                        y = m_imageBuffer.nHeight - brushHeight - brushHeight/5.0+ j;
                    
                    if(i <= brushWidth/2.0)
                        x = i + brushWidth/5.0;
                    else
                        x = m_imageBuffer.nWidth - brushWidth - brushWidth/5.0+ i;
                    int nAlpha = 255;
                   
                    if(x >= 0 && (y >= 0))
                        nAlpha = (int)(m_imageBuffer.pBuffer[y* m_imageBuffer.nWidth*4 + x *4 + 3]);                    
                    m_aBasePixel[spp - 1] = int_mult(brushData[j * brushWidth + i], nAlpha, t1);
                    
                    //m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];

                    specialAlphaMerge(spp, overlay, overlayPos, m_aBasePixel, 0, pressure);
                    unsigned char overlayAlpha = overlay[overlayPos + spp - 1];
                    
//                    int overlayPos1 = (width * (ipoint.y + j) + ipoint.x + i - 1) * spp + spp - 1;
//                    int overlayPos2 = (width * (ipoint.y + j) + ipoint.x + i + 1) * spp + spp - 1;
//                    int overlayPos3 = (width * (ipoint.y + j - 1) + ipoint.x + i) * spp + spp - 1;
//                    int overlayPos4 = (width * (ipoint.y + j + 1) + ipoint.x + i) * spp + spp - 1;
//                    int t2, t3,t4;
//                    int sum = int_mult(overlay[overlayPos1], 62, t1) + int_mult(overlay[overlayPos2], 62, t2) + int_mult(overlay[overlayPos3], 62, t3) + int_mult(overlay[overlayPos4], 62, t4);
//                    overlayAlpha = MIN(255, sum);
                    
                    
                    int brushAlpha = 255;
//                    int nAlpha = (int)(m_imageBuffer.pBuffer[j* m_imageBuffer.nWidth*4 + i *4 + 3]);
//                    brushAlpha = int_mult(255, nAlpha, t1);
                    
                    if (useSelection) {
                        IntPoint tempPoint;
                        tempPoint.x = ipoint.x + i;
                        tempPoint.y = ipoint.y + j;
                        if (IntPointInRect(tempPoint, selectRect)) {
                            if (mask && !floating)
                                brushAlpha = int_mult(brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                        }else{
                            brushAlpha = 0;
                        }
                    }
                    if (brushAlpha > 0) {
                        
                        switch (range)
                        {
                            case kBurnRange_Highlights:
                            {
                                for (int k = 0; k < spp - 1; k++) {
                                    float factor = (1.0 - exposure * 0.75);
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    float result = value * factor;
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                            }
                                break;
                                
                            case kBurnRange_Midtones:{
                                for (int k = 0; k < spp - 1; k++) {
                                    float factor = exposure * 0.25;
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    float result = value - factor * sinf(value * PI);
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                            }
                               
                                break;
                                
                                
                            case kBurnRange_Shadows:{
                                for (int k = 0; k < spp - 1; k++) {
                                    float factor = exposure;
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    float result = value + factor * (1.0 - expf(1.0 - value));
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                            }
                                
                                break;
                                
                            default:
                                break;
                        }
                        

                        brushAlpha = int_mult(brushAlpha, overlayAlpha, t1);
                        //brushAlpha = overlay[overlayPos + spp - 1];
                        if (brushAlpha > 0) {
                            replacePrimaryMergeCustomSimple(spp, layerData, overlayPos, m_aBasePixel, 0, m_layerRawData, overlayPos, brushAlpha);
                        }
                        
                        //replaceMerge(spp, layerData, overlayPos, aBasePixel, 0, brushAlpha);
                        
                        //normalMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                        
                    }
                }
            }
        }
    }
    
    [overlayData unLockDataForWrite];
    [layer unLockRawData];
    // Set the last plot point appropriately
    m_poiLastPlotPoint = point;
}



- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    id layer = [[m_idDocument contents] activeLayer];
    
    [layer setFullRenderState:NO];
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    
    m_layerRawData = malloc(width * height * layerSpp);
    
    
    //BOOL hasAlpha = [layer hasAlpha];
    id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
    
    int nBrushWidth = [curBrush fakeWidth];
    int nBrushHeight = [curBrush fakeHeight];
    float fFeather = nBrushWidth < nBrushHeight ? nBrushWidth : nBrushHeight;
    fFeather = fFeather/2.0;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    int nRet = CreateImageBufferFromRect(&m_imageBuffer, CGRectMake(2*fFeather, 2*fFeather, fFeather, fFeather), colorFill, true, colorFill, fFeather);

//    fFeather = fFeather/5.0 > 30 ? 30 : fFeather/5.0;
//    int nRet = CreateImageBufferFromRect(&m_imageBuffer, CGRectMake(2*fFeather, 2*fFeather, nBrushWidth - 4*fFeather, nBrushHeight - 4*fFeather),  colorFill, true, colorFill, fFeather);
    
    //id activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
    NSPoint curPoint = IntPointMakeNSPoint(where), temp;
    IntRect rect;
    NSColor *color = NULL;
    int spp = [[m_idDocument contents] spp], k;
    int pressure = 255;//[m_idOptions pressureValue:event];
    BOOL ignoreFirstTouch;
    int modifier = [(PSBurnToolOptions *)m_idOptions modifier];
    
    // Determine whether operation should continue
    m_sLastWhere.x = where.x;
    m_sLastWhere.y = where.y;
    m_bMultithreaded = [[PSController m_idPSPrefs] multithreaded];
    ignoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
    
//    if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) && [m_idOptions pressureSensitive] && (modifier != kShiftModifier && modifier != kShiftControlModifier)) {
//        m_bFirstTouchDone = NO;
//        return;
//    }
//    else {
//        m_bFirstTouchDone = YES;
//    }
    
    m_bFirstTouchDone = YES;
    
    // Determine base pixels and hence brush colour

    
    m_overlayBehaviour = kNormalBehaviour;
    // Set the appropriate overlay opacity
    [[m_idDocument whiteboard] setOverlayOpacity:0];
    
    
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
        //[[m_idDocument helpers] overlayChanged:rect inThread:YES];
        PSLayer *layer = [[m_idDocument contents] activeLayer];
        [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
    }
    
    // Record the position as the last point
    m_poiLast = m_poiLastPlotPoint = curPoint;
    m_dDistance = 0;
    
    // Create the points list
    //if(m_psPoints) free(m_psPoints);
    BTPointRecord * tempPoints = m_psPoints;
    
    m_psPoints = malloc(kMaxBTPoints * sizeof(BTPointRecord));
    if (tempPoints) free(tempPoints);
    
    m_nPos = m_nDrawingPos = 0;
    m_sLastPressure = -1;
    
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
    brushSpacing = (double)[(BrushUtility*)[[PSController utilitiesManager] brushUtilityFor:m_idDocument] spacing] / 100.0;
    
    spp = [[m_idDocument contents] spp];
    bigRect = IntMakeRect(0, 0, 0, 0);
    lastDate = [NSDate date];
    
    // While we are not done...
    do {
        
    next:
        if (m_nDrawingPos < m_nPos) {
            
            // Get the next record and carry on
            curPoint = IntPointMakeNSPoint(m_psPoints[m_nDrawingPos].point);
            origPressure = m_psPoints[m_nDrawingPos].pressure;
            if (m_psPoints[m_nDrawingPos].special == 2) {
                //if (bigRect.size.width != 0) [[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
                [self combineWillBeProcessDataRect:bigRect];
                PSLayer *layer = [[m_idDocument contents] activeLayer];
                [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(bigRect)];
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
                if (x == (int)floor(m_poiLastPlotPoint.x) && y == (int)floor(m_poiLastPlotPoint.y)) {
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
            
            // NSLog(@"Draw all the points");
            // Draw all the points
            for (n = 0; n < num_points; n++) {
                t = t0 + n * dt;
                rect.size.width = brushWidth + 1;
                rect.size.height = brushHeight + 1;
                temp = NSMakePoint(m_poiLast.x + deltaX * t - (float)(brushWidth / 2), m_poiLast.y + deltaY * t - (float)(brushHeight / 2));
                rect.origin = NSPointMakeIntPoint(temp);
                rect.origin.x--; rect.origin.y--;
                rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
//                if (fade) {
//                    dtx = (double)(initial + t * dist) / fadeValue;
//                    pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
//                    pressure = int_mult(pressure, origPressure, tim);
//                }
//                else {
//                    pressure = origPressure;
//                }
                pressure = origPressure;
                if (m_sLastPressure > -1 && abs(pressure - m_sLastPressure) > 5) {
                    pressure = m_sLastPressure + 5 * sgn(pressure - m_sLastPressure);
                }
                m_sLastPressure = pressure;
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
            //[[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
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
    }
    
    //    id layer = [[m_idDocument contents] activeLayer];
    //    where = [self transformPoint:where WithTranfrom:[layer getInverseTransformOfLayerFilters]];
    
    // Check this is a new point
    if (where.x == m_sLastWhere.x && where.y == m_sLastWhere.y) {
        return;
    }
    else {
        m_sLastWhere = where;
    }
    
    // Add to the list
    if (m_nPos < kMaxBTPoints - 1) {
        m_psPoints[m_nPos].point = where;
        m_psPoints[m_nPos].pressure = 255; //[m_idOptions pressureValue:event];
        m_psPoints[m_nPos].special = 0;
        m_nPos++;
    }
    else if (m_nPos == kMaxBTPoints - 1) {
        m_psPoints[m_nPos].special = 2;
        m_nPos++;
    }
    
    // Draw if drawing is not multithreaded
    if (!m_bMultithreaded) {
        [self drawThread:NULL];
    }
}

- (void)endLineDrawing
{
    // Tell the other thread to terminate
    if (m_nPos < kMaxBTPoints) {
        if (m_psPoints) {
            m_psPoints[m_nPos].special = 2;
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

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    // Apply the changes
    [self endLineDrawing];
    //[(PSHelpers *)[m_idDocument helpers] applyOverlay];
    m_bFirstTouchDone = NO;
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    if (m_layerRawData) {
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    }
    
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    
    [layer setFullRenderState:YES];
    
    DestroyImageBuffer(&m_imageBuffer);
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    [self updateCursor];
    
    [super mouseMoveTo:where withEvent:event];
}



-(void)updateCursor
{
    //float fRadius = 5; //[(PSRedEyeRemoveOptions *)m_idOptions getRadiusSize];
    
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
    
    //CGContextFillRect(ctx, NSMakeRect(fRadius * fScale/2.0 + 0.5 , fRadius * fScale, fRadius * fScale, 1));
    
    //CGContextFillRect(ctx, NSMakeRect(fRadius * fScale, fRadius * fScale/2.0 + 0.5, 1, fRadius * fScale));
    
    [image unlockFocus];
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(fRadius * fScale, fRadius * fScale)];
}


- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return NO;
    
    return YES;
}




@end
