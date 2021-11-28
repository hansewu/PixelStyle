//
//  MyBrushTool.m
//  PixelStyle
//
//  Created by wyl on 15/9/8.
//
//

#import "MyBrushTool.h"
#import "PSTools.h"


#import "PSDocument.h"
#import "PSContent.h"
#import "PSController.h"
#import "PSLayer.h"
#import "PSWhiteboard.h"
#import "MyBrushOptions.h"
#import "PSView.h"
#import "PSHelpers.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "MyBrushUtility.h"
#import "PSPrefs.h"
#import "ipaintapi.h"

#import "PSSelection.h"
#import "PSLayerUndo.h"

static BOOL IntRectEqual(IntRect rect1, IntRect rect2)
{
    if(rect1.origin.x == rect2.origin.x && rect1.origin.y == rect2.origin.y && rect1.size.width == rect2.size.width && rect1.size.height == rect2.size.height)
        return YES;
    return NO;
}

@implementation MyBrushTool

- (id)init
{
    self = [super init];
    
//    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
//    m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"mybrushes-cursor"] hotSpot:NSMakePoint(10, 10)];

    m_mdStrokeBufferCache = [[NSMutableDictionary alloc] initWithCapacity:5];
    m_hCanvas = IP_CreateCanvas();
    IP_SetContext(m_hCanvas, self);
    
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press '[' to decrease radius. Press ']' to increase radius.", nil)];
    
    m_imageDrawed = nil;
    
    return self;
}

- (int)toolId
{
    return kMyBrushTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Art Brush Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"B";
}

- (void)dealloc
{
    if(m_imageDrawed)
        [m_imageDrawed release];
    
    if(m_mdStrokeBufferCache)
        [m_mdStrokeBufferCache release];
    
    if(m_hCanvas) IP_DestroyCanvas(m_hCanvas);
    
    [super dealloc];
}



- (BOOL)useMouseCoalescing
{
    return NO;
}

- (void) expandLayer:(PSLayer *)layer atPoint:(IntPoint *)where
{
    int nDataLength = m_rectLayerLast.size.width * m_rectLayerLast.size.height *[[m_idDocument contents] spp];
    
    if(m_dataLayerLast) free(m_dataLayerLast);
    m_dataLayerLast = (unsigned char *)malloc(nDataLength);
    memcpy(m_dataLayerLast, [(PSLayer *)layer getRawData], nDataLength);
    
    [(PSLayer *)layer unLockRawData];
    
    if(where)
    {
        m_bExpanded     = [(PSLayer *)layer expandLayerTemply:where];
        m_bAutoExpand   = NO;
    }
    else
    {
        m_bExpanded     = [(PSLayer *)layer expandLayerTemply:nil];
        m_bAutoExpand   = YES;
    }
    
    if(m_bExpanded)
    {
        [[m_idDocument whiteboard] readjustLayer:NO];
     }
    else
    {
        if(m_dataLayerLast) free(m_dataLayerLast);
        m_dataLayerLast = NULL;
    }
    
}

#define BRUSH_OPAQUE 0
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    PSLayer *layer = (PSLayer *)[[m_idDocument contents] activeLayer];
    
    [layer setFullRenderState:NO];
    
    int nModifier = [(MyBrushOptions *)m_idOptions modifier];
    
    // Determine whether operation should continue
    BOOL bIgnoreFirstTouch = [[PSController m_idPSPrefs] ignoreFirstTouch];
    if (bIgnoreFirstTouch && ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown) && (nModifier != kShiftModifier && nModifier != kShiftControlModifier))
    {
        m_bFirstTouchDone = NO;
        return;
    }
    else
    {
        m_bFirstTouchDone = YES;
    }
    
    m_rectLayerLast = [(PSLayer *)layer localRect];
    
    m_bExpanded = NO;
    if([(PSLayer *)layer isEdgeInCanvas])
    {
        if([layer width]* [layer height] >= 2048*768*2 && (where.x < 0 || where.y < 0 || where.x > m_rectLayerLast.origin.x + m_rectLayerLast.size.width || where.y > m_rectLayerLast.origin.y + m_rectLayerLast.size.height))
            [self expandLayer:layer atPoint:&where];
        else if([layer width]* [layer height] < 2048*768*2)
            [self expandLayer:layer atPoint:NULL];
        
        if(m_bExpanded)
        {
            IntRect rectExpanded = [(PSLayer *)layer localRect];
            where.x += (m_rectLayerLast.origin.x - rectExpanded.origin.x);
            where.y += (m_rectLayerLast.origin.y - rectExpanded.origin.y);
        }
    }
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay]; //lcz add
    
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    m_overlayBehaviour = kNormalBehaviour;
    
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    
    if(!m_imageDrawed)
        m_imageDrawed = [[PSSecureImageData alloc] initData:width height:height spp:layerSpp alphaPremultiplied:false];
    
    IMAGE_DATA imageData = [m_imageDrawed lockDataForWrite];

    if(imageData.nWidth != width || imageData.nHeight != height || imageData.nSpp != layerSpp)
    {
        [m_imageDrawed reInitData:width height:height spp:height alphaPremultiplied:false];
    }
    
    [m_imageDrawed unLockDataForWrite];
    
    m_layerRawData = imageData.pBuffer ;
/*    if (m_layerRawData)
    {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    m_layerRawData = malloc(width * height * layerSpp);
*/
    // Determine base pixels and hence brush colour
    NSColor *color;
    if (nModifier == kAltModifier)
        color = [[m_idDocument contents] background];
    else
        color = [[m_idDocument contents] foreground];
    
    int nSpp = [[m_idDocument contents] spp];
    unsigned char aBasePixel[4];
    //float fAlpha = [color alphaComponent];
    if (nSpp == 4)
    {
        aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
    }
    else
    {
        aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        aBasePixel[1] = (unsigned char)([color whiteComponent] * 255.0);
        aBasePixel[2] = (unsigned char)([color whiteComponent] * 255.0);
    }
    
    
    if ((aBasePixel[0]>=0 && aBasePixel[0]<=255) && (aBasePixel[1]>=0 && aBasePixel[1]<=255) && (aBasePixel[2]>=0 && aBasePixel[2]<=255))
    {
        m_nCurrentColor = ( aBasePixel[0]| (aBasePixel[1]<<8) | (aBasePixel[2]<<16));
    }
    
    // Set the appropriate overlay opacity
    [[m_idDocument whiteboard] setOverlayOpacity:0];
    
    if ([event subtype] == 1)
    {
        float eventPressure = [event pressure];
        //NSLog(@"eventPressure %f,%hd",eventPressure,[event subtype]);
        [(MyBrushOptions *)m_idOptions setPressure:eventPressure];
    }
    
    float fPressure = [(MyBrushOptions *)m_idOptions pressure];
    HANDLE_PAINT_CANVAS hCanvas = m_hCanvas;
    assert(hCanvas);
    
    HANDLE_PAINT_BRUSH hBrush = [[[PSController utilitiesManager] myBrushUtilityFor:m_idDocument] activeMyBrush];
    assert(hBrush);
    IP_SetBrushParam(hCanvas, hBrush, BRUSH_OPAQUE, 1.0); //fAlpha);
    m_brushAlpha = 255;
    IP_BeginOneStroke(hCanvas);
    [self strokeTo:hCanvas brush:hBrush color:m_nCurrentColor point:where pressure:fPressure intervalTime:5.1];
    
    m_dPreTime = [[NSDate date] timeIntervalSince1970];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    // Have we registerd the first touch
    if (!m_bFirstTouchDone)
    {
        [self mouseDownAt:where withEvent:event];
        m_bFirstTouchDone = YES;
    }

    
    //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
    HANDLE_PAINT_CANVAS hCanvas = m_hCanvas;
    assert(hCanvas);
    
    HANDLE_PAINT_BRUSH hBrush = [[[PSController utilitiesManager] myBrushUtilityFor:m_idDocument] activeMyBrush];
    assert(hBrush);
    double dCurTime = [[NSDate date] timeIntervalSince1970];
   
    
    if ([event subtype] == 1)
    {
        float eventPressure = [event pressure];
        //NSLog(@"eventPressure %f,%hd",eventPressure,[event subtype]);
        [(MyBrushOptions *)m_idOptions setPressure:eventPressure];
    }
    
    float fPressure = [(MyBrushOptions *)m_idOptions pressure];
    [self strokeTo:hCanvas brush:hBrush color:m_nCurrentColor point:where pressure:fPressure intervalTime:dCurTime - m_dPreTime];
    
    m_dPreTime = dCurTime;
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    //HANDLE_PAINT_CANVAS hCanvas = [[m_idDocument whiteboard] getCanvas];
    HANDLE_PAINT_CANVAS hCanvas = m_hCanvas;
    assert(hCanvas);
    
    HANDLE_PAINT_BRUSH hBrush = [[[PSController utilitiesManager] myBrushUtilityFor:m_idDocument] activeMyBrush];
    assert(hBrush);
    
    if ([event subtype] == 1)
    {
        float eventPressure = [event pressure];
        [(MyBrushOptions *)m_idOptions setPressure:eventPressure];
    }
    
    float fPressure = [(MyBrushOptions *)m_idOptions pressure];
    [self strokeTo:hCanvas brush:hBrush color:m_nCurrentColor point:where pressure:fPressure intervalTime:-1.0];
    
    
    IP_EndOneStroke(hCanvas);
    
    m_bFirstTouchDone = NO;
  
    // Apply the changes
    //[(PSHelpers *)[m_idDocument helpers] applyOverlay];

    [self copyRawDataToTempInRect:m_dataChangedRect];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    
    IntRect rectExpanded;
    if(m_bExpanded)
    {
        rectExpanded = [(PSLayer *)layer localRect];
        if(m_bAutoExpand)
        {
            [layer trimLayer];
            [[m_idDocument whiteboard] readjustLayer:NO];
        }
    }
    
   IntRect layerRectNow = [(PSLayer *)layer localRect];
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];

    if(!m_bExpanded)
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    else if(IntRectEqual(layerRectNow, m_rectLayerLast)) //
    {
        NSCAssert(m_dataLayerLast, @"");
        m_dataChangedRect.origin.x -= (layerRectNow.origin.x - rectExpanded.origin.x);
        m_dataChangedRect.origin.y -= (layerRectNow.origin.y - rectExpanded.origin.y);
        [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_dataLayerLast];
    }
    else
    {
         NSCAssert(m_dataLayerLast, @"");
        [[layer seaLayerUndo] takeFullSnapshot:m_rectLayerLast automatic:YES date:m_dataLayerLast];
    }
 
    //[[m_idDocument whiteboard] freeAllocCellBuffer];
    [self freeAllocCellBuffer];
    
 /*   if (m_layerRawData)
    {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
  */
    m_bExpanded = NO;
    if(m_imageDrawed)
    {
        [m_imageDrawed release];
        m_imageDrawed = nil;
    }
    if (m_dataLayerLast)
    {
        free(m_dataLayerLast);
        m_dataLayerLast = NULL;
    }
    
    [layer setFullRenderState:YES];
}


-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    [self updateCursor];
    
    [super mouseMoveTo:where withEvent:event];
}

-(void)updateCursor
{

    float fRadius = [(MyBrushOptions *)m_idOptions radius];
    fRadius = 3.0 * expf(1.1*fRadius);
    float fScale = [[m_idDocument docView] zoom];

    float fDiameter = 2*fScale*fRadius;
    
    if(fDiameter <= 5)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"minor-paint-cursor"] hotSpot:NSMakePoint(7, 7)] ;
        
        return;
    }
    
    NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(fDiameter, fDiameter)] autorelease];
    [image lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    [[NSColor whiteColor] set];
    CGContextStrokeEllipseInRect(context, CGRectMake(0, 0, fDiameter, fDiameter));
    
    [[NSColor blackColor] set];
    CGContextStrokeEllipseInRect(context, CGRectMake(1, 1, fDiameter - 2, fDiameter - 2));
    
    [image unlockFocus];
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(fDiameter/2.0, fDiameter/2.0)] ;
}

#define CELL_HEIGHT 64
#define CELL_WIDTH 64
-(void)strokeTo:(HANDLE_PAINT_CANVAS)hCanvas brush:(HANDLE_PAINT_BRUSH)hBrush color:(int)nColor point:(IntPoint)point pressure:(float)fPressure intervalTime:(float)fIntervalTime
{
    IP_StrokeTo(hCanvas, hBrush, nColor, point.x, point.y, fPressure, fIntervalTime);
    
    int nCount = IP_GetDirtyCellCount(hCanvas);
    if(nCount == 0 && fIntervalTime < 5.0) return;
    
    id layer = [[m_idDocument contents] activeLayer];
    int nSpp = [[m_idDocument contents] spp];
    int nWidth = [(PSLayer *)layer width];
    int nHeight = [(PSLayer *)layer height];
    
    for (int nIndex = 0; nIndex < nCount; nIndex++)
    {
        int nCellX,nCellY;
        unsigned char *pBuf = (unsigned char *)IP_GetDirtyCellInfo(hCanvas, nIndex, &nCellX, &nCellY);
        assert(pBuf);
        
        IntRect rect = {{nCellX * CELL_WIDTH , nCellY * CELL_HEIGHT}, {CELL_WIDTH, CELL_HEIGHT}};
        rect = IntConstrainRect(rect, IntMakeRect(0, 0, nWidth, nHeight));
        float fAlpha;
        
        IntRect selectRect = [[m_idDocument selection] localRect];
        unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
        IntPoint maskOffset = [[m_idDocument selection] maskOffset];
        IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
        IntSize maskSize = [[m_idDocument selection] maskSize];
        BOOL useSelection = [[m_idDocument selection] active];
        int selectedChannel = [[m_idDocument contents] selectedChannel];
        BOOL floating = [layer floating];
        int t1;
        
        if (useSelection)
        {
            rect = IntConstrainRect(rect, selectRect);
        }
        
        [self copyRawDataToTempInRect:rect];
        [self combineWillBeProcessDataRect:rect];
        unsigned char *layerData = [layer getRawData];
        
        PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
        IMAGE_DATA imageData = [overlayData lockDataForWrite];
        unsigned char *overlay = imageData.pBuffer;
        
        int endy = rect.origin.y + rect.size.height - nCellY * CELL_HEIGHT;
        int endx = rect.origin.x + rect.size.width - nCellX * CELL_WIDTH;
        
        for(int j = rect.origin.y - nCellY * CELL_HEIGHT; j < endy; j++)
        {
            for(int i = rect.origin.x - nCellX * CELL_WIDTH; i < endx; i++)
            {
                fAlpha = pBuf[j*CELL_WIDTH*4 + i*4 + 3];
                fAlpha = fmaxf(fminf(fAlpha/255.0, 1.0),0.0);
//                fAlpha = 1.0;
                
                int overlayPos = (nCellY * CELL_HEIGHT + j) * nWidth * nSpp + nCellX * CELL_WIDTH * nSpp + i * nSpp;
                int brushAlpha = 255; //pBuf[j*CELL_WIDTH*4 + i*4 + 3];  //
                //NSLog(@"alpha %f",fAlpha);
                if (useSelection) {
                    IntPoint tempPoint;
                    tempPoint.x = nCellX * CELL_WIDTH + i ;
                    tempPoint.y = nCellY * CELL_HEIGHT + j;
                    if (IntPointInRect(tempPoint, selectRect))
                    {
                        if (mask && !floating)
                            brushAlpha = int_mult(brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }
                    else
                    {
                        brushAlpha = 0;
                    }
                }
                else
                {
                    
                }
                
                if (brushAlpha > 0)
                {
                    for(int k = 0; k < nSpp-1; k++)
                    {
                        if (fAlpha < 0.000001)
                        {
                            overlay[(nCellY * CELL_HEIGHT + j) * nWidth * nSpp + nCellX * CELL_WIDTH * nSpp + i * nSpp + k] = 0.0;
                        }
                        else
                        {
                            int nValue = pBuf[j*CELL_WIDTH*4 + i*4 + k] / fAlpha;
                            nValue = (int)fmaxf(fminf(nValue, 255.0),0.0);
                            overlay[(nCellY * CELL_HEIGHT + j) * nWidth * nSpp + nCellX * CELL_WIDTH * nSpp + i * nSpp + k] = nValue;
                        }
                        
                    }
                    
                    
                    overlay[(nCellY * CELL_HEIGHT + j) * nWidth * nSpp + nCellX * CELL_WIDTH * nSpp + i * nSpp + (nSpp - 1)] = pBuf[j*CELL_WIDTH*4 + i*4 + 3];
                    //NSLog(@"brushAlpha %d",brushAlpha);
                    
                    
                    if (selectedChannel == kAllChannels && !floating)
                    {
                        if (m_overlayBehaviour == kNormalBehaviour)
                        {
                            replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha, 0);
                        }
                    }
                    else if (selectedChannel == kPrimaryChannels || floating)
                    {
                        replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha, 1);
                    }
                    else if (selectedChannel == kAlphaChannel)
                    {
                        replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha, 2);
                    }
                    
                }
            }
        }
        
        
       
        [overlayData unLockDataForWrite];
        [layer unLockRawData];
        //[[m_idDocument helpers] overlayChanged:rect inThread:YES];
       // PSLayer *layer = [[m_idDocument contents] activeLayer];
        [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
    }
    
    IP_ClearDirty(hCanvas);
}



- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return NO;
    
    return YES;
}


- (void*)getCanvas
{
    return m_hCanvas;
}


-(void)allocCellBuffer:(unsigned char **)pCellBuf cellX:(int)nCellX cellY:(int)nCellY read:(BOOL)bReadOnly
{
    //NSLog(@"allocCellBuffer");
    NSData *data = [m_mdStrokeBufferCache objectForKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
    if(data)
    {
        *pCellBuf = (unsigned char *)[data bytes];
        return;
    }
    
    unsigned char *pCell = malloc(CELL_WIDTH * CELL_HEIGHT * 4);
    memset(pCell, 0, CELL_WIDTH * CELL_HEIGHT * 4);
    
    //    unsigned char *overlay = [[m_idDocument whiteboard] overlay];
    
    id layer = [[m_idDocument contents] activeLayer];
    int nWidth = [(PSLayer *)layer width];
    int nHeight = [(PSLayer *)layer height];
    int nSpp = [[m_idDocument contents] spp];
    
    unsigned char *overlay = [layer getRawData]; //m_layerRawData; //
    IntRect rect = {{nCellX * CELL_WIDTH , nCellY * CELL_HEIGHT}, {CELL_WIDTH, CELL_HEIGHT}};
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, nWidth, nHeight));
    
    for(int j = 0; j < rect.size.height; j++)
    {
        for(int i = 0; i < rect.size.width; i++)
        {
            float fAlpha = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + (nSpp - 1)];
            pCell[j * CELL_WIDTH * 4 + i * 4 + 3] = fAlpha;
            fAlpha = fmaxf(fminf(fAlpha/255.0, 1.0),0.0);
            //            fAlpha = 1.0;
            if (nSpp == 2)
            {
                int nGray = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp] * fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4] = nGray;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 1] = nGray;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 2] = nGray;
            }
            else
            {
                pCell[j * CELL_WIDTH * 4 + i * 4] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp] * fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 1] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + 1]* fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 2] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + 2] * fAlpha;
                
                //NSLog(@"%d,%d,%f",overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp],pCell[j * CELL_WIDTH * 4 + i * 4],fAlpha);
            }
        }
    }
    
    [(PSLayer *)layer unLockRawData];
    *pCellBuf = pCell;
    
    data = [NSData dataWithBytesNoCopy:*pCellBuf length:CELL_WIDTH * CELL_HEIGHT * 4 freeWhenDone:NO];
    [m_mdStrokeBufferCache setObject:data forKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
    
    return;
}

-(void)freeAllocCellBuffer
{
    NSEnumerator * enumerator = [m_mdStrokeBufferCache keyEnumerator];
    NSString *sKey;
    //遍历输出
    while(sKey = [enumerator nextObject])
    {
        //        NSLog(@"键值为：%@",sKey);
        NSData *data = [m_mdStrokeBufferCache objectForKey:sKey];
        if (data)
        {
            unsigned char *pCellBuf = (unsigned char *)[data bytes];
            free(pCellBuf);
        }
    }
    [m_mdStrokeBufferCache removeAllObjects];
}

//左上角是 0，0
void *IPD_GetTileMemory(void *pContext, int nCellX, int nCellY, int nReadOnly)
{
    //    PSWhiteboard *pThis = (PSWhiteboard *)pContext;
    
    unsigned char *pCellBuf = NULL;
    [pContext allocCellBuffer:&pCellBuf cellX:nCellX cellY:nCellY read:nReadOnly];
    return pCellBuf;
}



@end
