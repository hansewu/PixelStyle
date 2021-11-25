#import "BrushTool.h"
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
#import "PSSelection.h"

#define EPSILON 0.0001

static BOOL IntRectEqual(IntRect rect1, IntRect rect2)
{
    if(rect1.origin.x == rect2.origin.x && rect1.origin.y == rect2.origin.y && rect1.size.width == rect2.size.width && rect1.size.height == rect2.size.height)
        return YES;
    return NO;
}

@implementation BrushTool

- (id)init
{
    self = [super init];
    if(self)
    {
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt to erase. Press Shift to draw straight lines. Press Shift & Ctrl to draw lies at 45 degrees.", nil)];
    }
    return self;
}

- (int)toolId
{
    return kBrushTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Brush Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"B";
}

- (void)dealloc
{
    if(m_psPoints) free(m_psPoints);
    
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
    unsigned char *overlay = imageData.pBuffer, *brushData;
    int brushWidth = [(PSBrush *)brush fakeWidth], brushHeight = [(PSBrush *)brush fakeHeight];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int i, j, spp = [[m_idDocument contents] spp], overlayPos;
    IntPoint ipoint = NSPointMakeIntPoint(point);
    
    if ([brush usePixmap])
    {  //normally is NO
        
        // We can't handle this for anything but 4 samples per pixel
        if (spp != 4)
            return;
        
        // Get the approrpiate brush data for the point
        brushData = [brush pixmapForPoint:point];
        
        // Go through all valid points
        for (j = 0; j < brushHeight; j++)
        {
            for (i = 0; i < brushWidth; i++)
            {
                if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height)
                {
                    
                    // Change the pixel colour appropriately
                    overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * 4;
                    specialMerge(4, overlay, overlayPos, brushData, (j * brushWidth + i) * 4, pressure);
                }
            }
        }
    }
    else
    {
        // Get the approrpiate brush data for the point
        if ([(BrushOptions *)m_idOptions scale])
            brushData = [brush maskForPoint:point pressure:pressure];
        else
            brushData = [brush maskForPoint:point pressure:255];
        
        //    unsigned char *layerData = [layer getRawData];
        // Go through all valid points
        for (j = 0; j < brushHeight; j++)
        {
            for (i = 0; i < brushWidth; i++)
            {
                if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height)
                {
                    overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
                    m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];
                    specialMerge(spp, overlay, overlayPos, m_aBasePixel, 0, pressure);
                }
            }
        }
        
        //   [layer unLockRawData];
    }
    
    [overlayData unLockDataForWrite];
    // Set the last plot point appropriately
    m_poiLastPlotPoint = point;
}


- (void)combineDataToLayerInRect:(IntRect)rect
{
    [self combineWillBeProcessDataRect:rect];
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int spp = [(PSLayer *)layer spp];
    
    if (rect.origin.x < 0 || rect.origin.y < 0 || rect.size.width > width || rect.size.height > height)
    {
        return;
    }
    if (rect.size.width <= 0 || rect.size.height <= 0)
    {
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
    
    PS_EDIT_CHANNEL_TYPE editType = [layer editedChannelOfLayer];
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
        {
            
            if (i >= 0 && i < width && j >= 0 && j < height)
            {
                
                int overlayPos = (j * width + i) * spp;
                int brushAlpha = m_brushAlpha;
                if (useSelection) {
                    IntPoint tempPoint;
                    tempPoint.x = i;
                    tempPoint.y = j;
                    if (IntPointInRect(tempPoint, selectRect))
                    {
                        if (mask && !floating)
                            brushAlpha = int_mult(m_brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }
                    else
                    {
                        brushAlpha = 0;
                    }
                }
                if (brushAlpha > 0)
                {
                    /*
                     if (selectedChannel == kAllChannels && !floating)
                     {
                     if (m_overlayBehaviour == kNormalBehaviour)
                     {
                     specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                     
                     }
                     else if (m_overlayBehaviour == kErasingBehaviour)
                     {
                     eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                     }
                     }
                     else if (selectedChannel == kPrimaryChannels || floating)
                     {
                     unsigned char tempSpace[spp];
                     memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                     primaryMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO);
                     memcpy(layerData + overlayPos, tempSpace, spp);
                     }
                     else if (selectedChannel == kAlphaChannel)
                     {
                     unsigned char tempSpace[spp];
                     memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                     alphaMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha);
                     memcpy(layerData + overlayPos, tempSpace, spp);
                     }
                     */
                    
                    switch (editType)
                    {
                        case kEditAllChannels:
                        {
                            if (m_overlayBehaviour == kNormalBehaviour)
                            {
                                specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                                
                            }
                            else if (m_overlayBehaviour == kErasingBehaviour)
                            {
                                eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
                            }
                        }
                            break;
                            
                        default:
                        {
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, m_layerRawData + overlayPos, spp);
                            flexibleMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO, editType);
                            memcpy(layerData + overlayPos, tempSpace, spp);
                        }
                            break;
                    }
                    
                }
                
            }
        }
    }
    [overlayData unLockDataForWrite];
    
    [layer unLockRawData];
    
}


- (IntPoint)transformPoint:(IntPoint)srcPoint WithTranfrom:(NSAffineTransform*)transform
{
    NSPoint tempPoint = IntPointMakeNSPoint(srcPoint);
    tempPoint = [transform transformPoint:tempPoint];
    return IntMakePoint(tempPoint.x, tempPoint.y);
}


- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    //assert(0);
    [super mouseDownAt:where withEvent:event];
    
    PSLayer * layer = (PSLayer *)[[m_idDocument contents] activeLayer];
    
    [layer setFullRenderState:NO];
    
    m_rectLayerLast = [(PSLayer *)layer localRect];
    
    {
        int nDataLength = m_rectLayerLast.size.width * m_rectLayerLast.size.height *[[m_idDocument contents] spp];
        
        if(m_dataLayerLast) free(m_dataLayerLast);
        m_dataLayerLast = (unsigned char *)malloc(nDataLength);
        memcpy(m_dataLayerLast, [(PSLayer *)layer getRawData], nDataLength);
        [(PSLayer *)layer unLockRawData];
    }
    
    m_bExpanded     = [(PSLayer *)layer expandLayerTemply:nil];
    if(m_bExpanded)
    {
        [[m_idDocument whiteboard] readjustLayer:NO];
        
        IntRect rectExpanded = [(PSLayer *)layer localRect];
        where.x += (m_rectLayerLast.origin.x - rectExpanded.origin.x);
        where.y += (m_rectLayerLast.origin.y - rectExpanded.origin.y);
        
        
    }
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    if (m_layerRawData)
    {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    
    m_layerRawData = malloc(width * height * layerSpp);
    //NSLog(@"time1 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    //memcpy(m_layerRawData, [layer getRawData], width * height * layerSpp);
    //NSLog(@"time2 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    
    
    BOOL hasAlpha = [layer hasAlpha];
    id curBrush = [[[PSController utilitiesManager] brushUtilityFor:m_idDocument] activeBrush];
    id activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
    NSPoint curPoint = IntPointMakeNSPoint(where), temp;
    IntRect rect;
    NSColor *color = NULL;
    int spp = [[m_idDocument contents] spp], k;
    int pressure = [m_idOptions pressureValue:event];
    BOOL ignoreFirstTouch;
    int modifier = [(BrushOptions *)m_idOptions modifier];
    float alpha = [(BrushOptions *)m_idOptions getOpacityValue];
    
    // Determine whether operation should continue
    m_sLastWhere.x = where.x;
    m_sLastWhere.y = where.y;
    m_bMultithreaded = [[PSController m_idPSPrefs] multithreaded];
    ignoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
    if (ignoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) && [m_idOptions pressureSensitive] && (modifier != kShiftModifier && modifier != kShiftControlModifier))
    {
        m_bFirstTouchDone = NO;
        return;
    }
    else
    {
        m_bFirstTouchDone = YES;
    }
    
    BOOL isErasing = [(BrushOptions*)m_idOptions brushIsErasing];
    // Determine base pixels and hence brush colour
    if (isErasing)
    {
        color = [[m_idDocument contents] background];
        if (spp == 4)
        {
            m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
            m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
            m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
            m_aBasePixel[3] = 255;
        }
        else
        {
            m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
            m_aBasePixel[1] = 255;
        }
    }
    else if ([m_idOptions useTextures])
    {
        for (k = 0; k < spp - 1; k++)
            m_aBasePixel[k] = 0;
        m_aBasePixel[spp - 1] = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
    }
    else if (spp == 4)
    {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        //m_aBasePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
        m_aBasePixel[3] = (unsigned char)(alpha * 255.0);
    }
    else
    {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        //m_aBasePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)(alpha * 255.0);
    }
    
    m_overlayBehaviour = kNormalBehaviour;
    // Set the appropriate overlay opacity
    if (isErasing)
    {
        if (hasAlpha)
            m_overlayBehaviour = kErasingBehaviour;
        //[[m_idDocument whiteboard] setOverlayBehaviour:kErasingBehaviour];
        [[m_idDocument whiteboard] setOverlayOpacity:0]; //255
        m_brushAlpha = 255;
    }
    else
    {
        
        //		if ([m_idOptions useTextures])
        //			[[m_idDocument whiteboard] setOverlayOpacity:[(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity]];
        //		else
        //			[[m_idDocument whiteboard] setOverlayOpacity:[color alphaComponent] * 255.0];
        
        [[m_idDocument whiteboard] setOverlayOpacity:0];
        if ([m_idOptions useTextures])
            m_brushAlpha = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
        else
            m_brushAlpha = (int)(alpha * 255.0);

    }
    
    // Plot the initial point
    rect.size.width = [(PSBrush *)curBrush fakeWidth] + 1;
    rect.size.height = [(PSBrush *)curBrush fakeHeight] + 1;
    temp = NSMakePoint(curPoint.x - (float)([(PSBrush *)curBrush width] / 2) - 1.0, curPoint.y - (float)([(PSBrush *)curBrush height] / 2) - 1.0);
    rect.origin = NSPointMakeIntPoint(temp);
    rect.origin.x--; rect.origin.y--;
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
    
    IntRect selectRect = [[m_idDocument selection] localRect];
    BOOL useSelection = [[m_idDocument selection] active];
    if (useSelection)
    {
        rect = IntConstrainRect(rect, selectRect);
    }
    
    if (rect.size.width > 0 && rect.size.height > 0)
    {
        [self copyRawDataToTempInRect:rect];
        [self plotBrush:curBrush at:temp pressure:pressure];
        
        if ([m_idOptions useTextures] && ![m_idOptions brushIsErasing] && ![curBrush usePixmap])
        {
            PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
            IMAGE_DATA imageData = [overlayData lockDataForWrite];
            unsigned char *overlay = imageData.pBuffer;
            
            textureFill(spp, rect, overlay, [(PSLayer *)layer width], [(PSLayer *)layer height], [activeTexture texture:(spp == 4)], [(PSTexture *)activeTexture width], [(PSTexture *)activeTexture height]);
            [overlayData unLockDataForWrite];
        }
        
        [self combineDataToLayerInRect:rect];
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
    if (m_bMultithreaded)
    {
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
    fade = [m_idOptions fade];
    fadeValue = [m_idOptions fadeValue];
    spp = [[m_idDocument contents] spp];
    bigRect = IntMakeRect(0, 0, 0, 0);
    lastDate = [NSDate date];
    
    // While we are not done...
    do {
        
    next:
        if (m_nDrawingPos < m_nPos) {
            
            if(!m_psPoints) return;
            // Get the next record and carry on
            curPoint = IntPointMakeNSPoint(m_psPoints[m_nDrawingPos].point);
            origPressure = m_psPoints[m_nDrawingPos].pressure;
            if (m_psPoints[m_nDrawingPos].special == 2) {
                //if (bigRect.size.width != 0) [[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
                [self combineDataToLayerInRect:bigRect];
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
                
                IntRect selectRect = [[m_idDocument selection] localRect];
                BOOL useSelection = [[m_idDocument selection] active];
                if (useSelection) {
                    rect = IntConstrainRect(rect, selectRect);
                }
                
                if (fade) {
                    dtx = (double)(initial + t * dist) / fadeValue;
                    pressure = (int)(exp (- dtx * dtx * 5.541) * 255.0);
                    pressure = int_mult(pressure, origPressure, tim);
                }
                else {
                    pressure = origPressure;
                }
                if (m_sLastPressure > -1 && abs(pressure - m_sLastPressure) > 5) {
                    pressure = m_sLastPressure + 5 * sgn(pressure - m_sLastPressure);
                }
                m_sLastPressure = pressure;
                if (rect.size.width > 0 && rect.size.height > 0 && pressure > 0) {
                    [self copyRawDataToTempInRect:rect];
                    [self plotBrush:curBrush at:temp pressure:pressure];
                    if ([m_idOptions useTextures] && ![m_idOptions brushIsErasing] && ![curBrush usePixmap]){
                        PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
                        IMAGE_DATA imageData = [overlayData lockDataForWrite];
                        unsigned char *overlay = imageData.pBuffer;
                        textureFill(spp, rect, overlay, layerWidth, layerHeight, [activeTexture texture:(spp == 4)], [(PSTexture *)activeTexture width], [(PSTexture *)activeTexture height]);
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
            [self combineDataToLayerInRect:bigRect];
            //[[m_idDocument helpers] overlayChanged:bigRect inThread:YES];
            PSLayer *layer = [[m_idDocument contents] activeLayer];
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(bigRect)];
        }
        
    } while (m_bMultithreaded);
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    // Have we registerd the first touch
    if (!m_bFirstTouchDone)
    {
        [self mouseDownAt:where withEvent:event];
        m_bFirstTouchDone = YES;
        return;
    }
    
    if ([[m_idDocument docView] isLineDrawing])
    {
        [self resetBrushInfo];
    }
    
    //    id layer = [[m_idDocument contents] activeLayer];
    //    where = [self transformPoint:where WithTranfrom:[layer getInverseTransformOfLayerFilters]];
    
    // Check this is a new point
    if (where.x == m_sLastWhere.x && where.y == m_sLastWhere.y)
    {
        return;
    }
    else
    {
        m_sLastWhere = where;
    }
    
    // Add to the list
    if (m_nPos < kMaxBTPoints - 1)
    {
        m_psPoints[m_nPos].point = where;
        m_psPoints[m_nPos].pressure = [m_idOptions pressureValue:event];
        m_psPoints[m_nPos].special = 0;
        m_nPos++;
    }
    else if (m_nPos == kMaxBTPoints - 1)
    {
        m_psPoints[m_nPos].special = 2;
        m_nPos++;
    }
    
    // Draw if drawing is not multithreaded
    if (!m_bMultithreaded)
    {
        [self drawThread:NULL];
        if ([[m_idDocument docView] isLineDrawing])
        {
            [self oneLineDrawingEnd];
        }
    }
}



- (void)endLineDrawing
{
    // Tell the other thread to terminate
    
    if (m_nPos < kMaxBTPoints)
    {
        if (m_psPoints)
        {
            m_psPoints[m_nPos].special = 2;
        }
        m_nPos++;
    }
    
    // If multithreaded, wait until the other thread finishes
    if (m_bMultithreaded)
    {
        while (!m_bDrawingDone)
        {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    }
    else
    {
        [self drawThread:NULL];
    }
    
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    // Apply the changes
    [self endLineDrawing];
    m_bFirstTouchDone = NO;
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    
    [self copyRawDataToTempInRect:m_dataChangedRect];
    if (m_layerRawData)
    {
      //  [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
        IntRect rectExpanded;
        if(m_bExpanded)
        {
            rectExpanded = [(PSLayer *)layer localRect];
            [layer trimLayer];
            [[m_idDocument whiteboard] readjustLayer:NO];
        }
        
        IntRect layerRectNow = [(PSLayer *)layer localRect];
        
        [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
        
        if(!m_bExpanded)
            [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
        else if(IntRectEqual(layerRectNow, m_rectLayerLast)) //
        {
            m_dataChangedRect.origin.x -= (layerRectNow.origin.x - rectExpanded.origin.x);
            m_dataChangedRect.origin.y -= (layerRectNow.origin.y - rectExpanded.origin.y);
            [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_dataLayerLast];
        }
        else
        {
            [[layer seaLayerUndo] takeFullSnapshot:m_rectLayerLast automatic:YES date:m_dataLayerLast];
        }
    }
    
    if (m_layerRawData)
    {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    
    if (m_dataLayerLast)
    {
        free(m_dataLayerLast);
        m_dataLayerLast = NULL;
    }
    
    [layer setFullRenderState:YES];
}


- (void)resetBrushInfo
{
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [layer setFullRenderState:NO];
    
    BOOL hasAlpha = [layer hasAlpha];
    NSColor *color = NULL;
    int spp = [[m_idDocument contents] spp], k;
    
    BOOL ignoreFirstTouch;
    int modifier = [(BrushOptions *)m_idOptions modifier];
    float alpha = [(BrushOptions *)m_idOptions getOpacityValue];
    
    // Determine whether operation should continue
    
    m_bMultithreaded = [[PSController m_idPSPrefs] multithreaded];
    ignoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
    
    BOOL isErasing = [(BrushOptions*)m_idOptions brushIsErasing];
    // Determine base pixels and hence brush colour
    if (isErasing)
    {
        color = [[m_idDocument contents] background];
        if (spp == 4)
        {
            m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
            m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
            m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
            m_aBasePixel[3] = 255;
        }
        else
        {
            m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
            m_aBasePixel[1] = 255;
        }
    }
    else if ([m_idOptions useTextures])
    {
        for (k = 0; k < spp - 1; k++)
            m_aBasePixel[k] = 0;
        m_aBasePixel[spp - 1] = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
    }
    else if (spp == 4)
    {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        //m_aBasePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
        m_aBasePixel[3] = (unsigned char)(alpha * 255.0);
    }
    else
    {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        //m_aBasePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)(alpha * 255.0);
    }
    
    m_overlayBehaviour = kNormalBehaviour;
    // Set the appropriate overlay opacity
    if ([m_idOptions brushIsErasing])
    {
        if (hasAlpha)
            m_overlayBehaviour = kErasingBehaviour;
        //[[m_idDocument whiteboard] setOverlayBehaviour:kErasingBehaviour];
        [[m_idDocument whiteboard] setOverlayOpacity:0]; //255
        m_brushAlpha = 255;
    }
    else
    {
        [[m_idDocument whiteboard] setOverlayOpacity:0];
        if ([m_idOptions useTextures])
            m_brushAlpha = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
        else
            m_brushAlpha = (int)(alpha * 255.0);
    }
    
}


- (void)oneLineDrawingEnd
{
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    
    [self copyRawDataToTempInRect:m_dataChangedRect];
    if (m_layerRawData)
    {
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    }
    
    [layer setFullRenderState:YES];
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    
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
    if ([[m_idDocument docView] isLineDrawing])
    {
        m_bFirstTouchDone = NO;
        return YES;
    }
    
    return NO;
}


- (BOOL)enterKeyPressed
{
    if ([[m_idDocument docView] isLineDrawing])
    {
        m_bFirstTouchDone = NO;
        return YES;
    }
    
    return NO;
}


@end
