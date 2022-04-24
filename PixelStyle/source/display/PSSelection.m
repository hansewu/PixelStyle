#import "PSSelection.h"
#import "PSView.h"
#import "PSDocument.h"
#import "PSFlip.h"
#import "PSHelpers.h"
#import "PSOperations.h"
#import "PSContent.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSLayer.h"
#import "Bitmap.h"
#import "PSWhiteboard.h"
#import "PSFlip.h"
#import <GIMPCore/GIMPCore.h>
#import "GraphicsToBuffer.h"
#import "PSSelectionEventInfo.h"
#import "PSWarning.h"
#import "Bucket.h"

@implementation PSSelection

- (id)initWithDocument:(id)doc
{
    // Remember the document we are representing
    m_idDocument = doc;
    
    // Sets the data members to appropriate initial values
    m_bActive = NO;
    m_pMask = NULL;
    
    m_selectionEventArray = [[NSMutableArray alloc] init];
    m_selectionUndoEventArray = [[NSMutableArray alloc] init];
    m_lastUndoEventIndex = -1;
    
    return self;
}

- (void)dealloc
{
    if (m_pMask) free(m_pMask);
    if (m_pMaskBitmap) { free(m_pMaskBitmap); [m_imgMask autorelease]; }
    if (m_selectionEventArray) {
        [m_selectionEventArray release];
        m_selectionEventArray = nil;
    }
    if (m_selectionUndoEventArray) {
        [m_selectionUndoEventArray release];
        m_selectionUndoEventArray = nil;
    }
    [super dealloc];
}

- (BOOL)active
{
    return m_bActive;
}

- (void)setActive:(BOOL)isAvtive
{
    m_bActive = isAvtive;
}

- (BOOL)floating
{
    return [[[m_idDocument contents] activeLayer] floating];
}

- (unsigned char *)mask
{
    return m_pMask;
}

- (NSImage *)maskImage
{
    int i;
    unsigned char basePixel[3];
    id selectionColor;
    
    if (m_imgMask && m_nSelectionColorIndex != [[PSController m_idPSPrefs] selectionColorIndex]) {
        selectionColor = [[PSController m_idPSPrefs] selectionColor:0.4];
        basePixel[0] = roundf([selectionColor redComponent] * 255.0);
        basePixel[1] = roundf([selectionColor greenComponent] * 255.0);
        basePixel[2] = roundf([selectionColor blueComponent] * 255.0);
        for (i = 0; i < m_sRect.size.width * m_sRect.size.height; i++) {
            m_pMaskBitmap[i * 4] = basePixel[0];
            m_pMaskBitmap[i * 4 + 1] = basePixel[1];
            m_pMaskBitmap[i * 4 + 2] = basePixel[2];
        }
        premultiplyBitmap(4, m_pMaskBitmap, m_pMaskBitmap, m_sRect.size.width * m_sRect.size.height);
        m_nSelectionColorIndex = [[PSController m_idPSPrefs] selectionColorIndex];
    }
    [m_imgMask setFlipped:YES];
    
    return m_imgMask;
}

- (IntPoint)maskOffset
{
    IntRect m_sGlobalRect = [self globalRect];
    return IntMakePoint(m_sGlobalRect.origin.x - m_sRect.origin.x, m_sGlobalRect.origin.y - m_sRect.origin.y);
}

- (IntSize)maskSize
{
    return IntMakeSize(m_sRect.size.width, m_sRect.size.height);
}

- (IntRect)trueLocalRect
{
    id layer = [[m_idDocument contents] activeLayer];
    IntRect localRect = m_sRect;
    
    localRect.origin.x -= [layer xoff];
    localRect.origin.y -= [layer yoff];
    
    return localRect;
}

- (IntRect)globalRect
{
    id layer = [[m_idDocument contents] activeLayer];
    
    if(!layer)  return IntMakeRect(0,0,0,0);
    
    IntRect layerRect;
    layerRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    
    IntRect m_sGlobalRect = IntConstrainRect(m_sRect, layerRect);
    
    return m_sGlobalRect;
}

- (IntRect)localRect
{
    id layer = [[m_idDocument contents] activeLayer];
    IntRect m_sGlobalRect = [self globalRect];
    IntRect localRect = m_sGlobalRect;
    
    /*
     if ([layer layerFormat] != PS_RASTER_LAYER) { //readjust
     IntRect layerRect;
     layerRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
     layerRect = IntConstrainRect(m_sRect, layerRect);
     localRect = layerRect;
     }
     */
    
    localRect.origin.x -= [layer xoff];
    localRect.origin.y -= [layer yoff];
    
    assert(localRect.origin.x >= 0 && localRect.origin.y >=0);
    //localRect = IntConstrainRect(localRect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
    
    return localRect;
}

- (void)updateMaskImage
{
    int i;
    unsigned char basePixel[3];
    id selectionColor;
    
    if (m_pMask)
    {
        m_nSelectionColorIndex = [[PSController m_idPSPrefs] selectionColorIndex];
        
        selectionColor = [[PSController m_idPSPrefs] selectionColor:0.4];
        
        m_pMaskBitmap = malloc(m_sRect.size.width * m_sRect.size.height * 4);
        
        basePixel[0] = roundf([selectionColor redComponent] * 255.0);
        basePixel[1] = roundf([selectionColor greenComponent] * 255.0);
        basePixel[2] = roundf([selectionColor blueComponent] * 255.0);
        
        for (i = 0; i < m_sRect.size.width * m_sRect.size.height; i++)
        {
            m_pMaskBitmap[i * 4] = basePixel[0];
            m_pMaskBitmap[i * 4 + 1] = basePixel[1];
            m_pMaskBitmap[i * 4 + 2] = basePixel[2];
            m_pMaskBitmap[i * 4 + 3] = 0xFF - m_pMask[i];
        }
        
        premultiplyBitmap(4, m_pMaskBitmap, m_pMaskBitmap, m_sRect.size.width * m_sRect.size.height);
        
        m_birMaskBitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pMaskBitmap pixelsWide:m_sRect.size.width pixelsHigh:m_sRect.size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:m_sRect.size.width * 4 bitsPerPixel:8 * 4];
        
        m_imgMask = [[NSImage alloc] init];
        
        [m_imgMask addRepresentation:m_birMaskBitmapRep];
        
        [m_birMaskBitmapRep autorelease];
    }
}



- (void)redoSelectionEvent:(PSSelectionEventInfo *)eventInfo index:(int)eventIndex
{
    if (eventIndex >= [m_selectionUndoEventArray count])
    {
        return;
    }
    
    [m_selectionEventArray addObject:eventInfo];
    [m_selectionUndoEventArray removeObjectAtIndex:eventIndex];
    
    PSSelectionEventInfo *info = eventInfo;
    switch (info.selectionType)
    {
        case 0:
            [self selectRectForUndo:info.selectionRect mode:info.selectionMode feather:info.selectionFeather];
            break;
        case 1:
            [self selectRoundedRectForUndo:info.selectionRect radius:info.selectionRadius mode:info.selectionMode feather:info.selectionFeather];
            break;
        case 2:
            [self selectEllipseForUndo:info.selectionRect mode:info.selectionMode feather:info.selectionFeather];
            break;
        case 3:
            [self selectPolyonForUndo:info.selectionRect points:info.selectionPoints pointNum:info.selectionPointsCount mode:info.selectionMode feather:info.selectionFeather];
            break;
        case 4:
            [self selectOverlayForUndo:info.wandInfo];
            break;
        case 5:
            [self invertSelectionForUndo];
            break;
        case 6:
            [self selectOpaqueNeedUndo:NO];
            break;
        case 10:
            [self clearSelectionNoUndo];
            break;
            
            
        default:
            break;
    }
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:eventInfo index:[m_selectionEventArray count] - 1];
}



- (void)undoSelectionEvent:(PSSelectionEventInfo *)eventInfo index:(int)eventIndex
{
    if (eventIndex >= [m_selectionEventArray count])
    {
        return;
    }
    [self clearSelectionNoUndo];
    
    [m_selectionUndoEventArray addObject:eventInfo];
    [m_selectionEventArray removeObjectAtIndex:eventIndex];
    
    int fromIndex = 0;
    for (int i = eventIndex - 1; i >= 0; i--)
    {
        PSSelectionEventInfo *info = [m_selectionEventArray objectAtIndex:i];
        if (info.selectionType == 10)
        {
            fromIndex = i + 1;
            break;
        }
        if (info.selectionMode == kForceNewMode || info.selectionMode == kDefaultMode)
        {
            fromIndex = i;
            break;
        }
    }
    
    for (int i = fromIndex; i < eventIndex; i++)
    {
        PSSelectionEventInfo *info = [m_selectionEventArray objectAtIndex:i];
        switch (info.selectionType)
        {
            case 0:
                [self selectRectForUndo:info.selectionRect mode:info.selectionMode feather:info.selectionFeather];
                break;
            case 1:
                [self selectRoundedRectForUndo:info.selectionRect radius:info.selectionRadius mode:info.selectionMode feather:info.selectionFeather];
                break;
            case 2:
                [self selectEllipseForUndo:info.selectionRect mode:info.selectionMode feather:info.selectionFeather];
                break;
            case 3:
                [self selectPolyonForUndo:info.selectionRect points:info.selectionPoints pointNum:info.selectionPointsCount mode:info.selectionMode feather:info.selectionFeather];
                break;
            case 4:
                [self selectOverlayForUndo:info.wandInfo];
                break;
            case 5:
                [self invertSelectionForUndo];
                break;
            case 6:
                [self selectOpaqueNeedUndo:NO];
                break;
            case 10:
                [self clearSelectionNoUndo];
                break;
                
            default:
                break;
        }
    }
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] redoSelectionEvent:eventInfo index:[m_selectionUndoEventArray count] - 1];
}

- (void)selectRect:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromRect(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height),  colorFill, true, colorFill, (float)nFeather);
    if(nRet <0 )  return;
    
    if (selectionRect.size.width == 0 || selectionRect.size.height == 0)
    {
        if (mode == kForceNewMode || mode == kDefaultMode)
        {
            [self clearSelectionNoUndo];
            PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
            info.selectionType = 10;
            [m_selectionEventArray addObject:info];
            [m_selectionUndoEventArray removeAllObjects];
            [info release];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
        }
        return;
    }
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    info.selectionType = 0;
    info.selectionMode = mode;
    info.selectionRect = selectionRect;
    info.selectionFeather = nFeather;
    [m_selectionEventArray addObject:info];
    [m_selectionUndoEventArray removeAllObjects];
    [info release];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}

- (void)selectRectForUndo:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromRect(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height),  colorFill, true, colorFill, (float)nFeather);
    if(nRet <0 )  return;
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    info.selectionType = 0;
    info.selectionMode = mode;
    info.selectionRect = selectionRect;
    info.selectionFeather = nFeather;
    if (m_bActive)
    {
        PSSelectionEventInfo *lastInfo = [m_selectionEventArray lastObject];
        info.selectionFirstActive = lastInfo.selectionFirstActive;
    }
    else
    {
        info.selectionFirstActive = (int)[m_selectionEventArray count];
    }
    
    [m_selectionEventArray addObject:info];
    [info release];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}


- (void)selectEllipse:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromEllipse(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height), colorFill, true, colorFill, (float)nFeather);
    if(nRet <0 )  return;
    
    if (selectionRect.size.width == 0 || selectionRect.size.height == 0)
    {
        if (mode == kForceNewMode || mode == kDefaultMode)
        {
            [self clearSelectionNoUndo];
            PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
            info.selectionType = 10;
            [m_selectionEventArray addObject:info];
            [m_selectionUndoEventArray removeAllObjects];
            [info release];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
        }
        return;
    }
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    
    info.selectionType = 2;
    info.selectionMode = mode;
    info.selectionRect = selectionRect;
    info.selectionFeather = nFeather;
    
    [m_selectionEventArray addObject:info];
    [m_selectionUndoEventArray removeAllObjects];
    
    [info release];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}

- (void)selectEllipseForUndo:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromEllipse(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height), colorFill, true, colorFill, (float)nFeather);
    if(nRet <0 )  return;
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}




- (void)selectRoundedRect:(IntRect)selectionRect radius:(int)radius mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromRoundRect(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height), colorFill, true, colorFill, radius, (float)nFeather);
    if(nRet <0 )  return;
    
    if (selectionRect.size.width == 0 || selectionRect.size.height == 0)
    {
        if (mode == kForceNewMode || mode == kDefaultMode)
        {
            [self clearSelectionNoUndo];
            PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
            info.selectionType = 10;
            [m_selectionEventArray addObject:info];
            [m_selectionUndoEventArray removeAllObjects];
            [info release];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
        }
        return;
    }
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    info.selectionType = 1;
    info.selectionMode = mode;
    info.selectionRect = selectionRect;
    info.selectionFeather = nFeather;
    info.selectionRadius = radius;
    
    if (m_bActive)
    {
        PSSelectionEventInfo *lastInfo = [m_selectionEventArray lastObject];
        info.selectionFirstActive = lastInfo.selectionFirstActive;
    }
    else
    {
        info.selectionFirstActive = (int)[m_selectionEventArray count];
    }
    
    [m_selectionEventArray addObject:info];
    [m_selectionUndoEventArray removeAllObjects];
    
    [info release];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}

- (void)selectRoundedRectForUndo:(IntRect)selectionRect radius:(int)radius mode:(int)mode feather:(int)nFeather
{
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromRoundRect(&imageBuffer, CGRectMake(selectionRect.origin.x, selectionRect.origin.y, selectionRect.size.width, selectionRect.size.height), colorFill, true, colorFill, radius, (float)nFeather);
    if(nRet <0 )  return;
    
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
    
}


- (void)selectPolyon:(IntRect)selectionRect points:(IntPoint *)points pointNum:(int)nPointNumber mode:(int)mode feather:(int)nFeather
{
    CGPoint cgpoints[nPointNumber];
    for (int nIndex = 0; nIndex < nPointNumber; nIndex++)
        cgpoints[nIndex] = CGPointMake(points[nIndex].x, points[nIndex].y);
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromPolygon(&imageBuffer, cgpoints, nPointNumber, colorFill, true, colorFill, nFeather);
    if(nRet < 0 )  return;
    
    if (selectionRect.size.width == 0 || selectionRect.size.height == 0)
    {
        if (mode == kForceNewMode || mode == kDefaultMode)
        {
            [self clearSelectionNoUndo];
            PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
            info.selectionType = 10;
            [m_selectionEventArray addObject:info];
            [m_selectionUndoEventArray removeAllObjects];
            [info release];
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
        }
        return;
    }
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    info.selectionType = 3;
    info.selectionMode = mode;
    info.selectionRect = selectionRect;
    info.selectionFeather = nFeather;
    
    IntPoint *selectionPoints = malloc(nPointNumber * sizeof(IntPoint));
    memcpy(selectionPoints, points, nPointNumber * sizeof(IntPoint));
    
    info.selectionPoints = selectionPoints;
    info.selectionPointsCount = nPointNumber;
    
    [m_selectionEventArray addObject:info];
    [m_selectionUndoEventArray removeAllObjects];
    [info release];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    [self flipImageBuffer:imageBuffer.pBuffer width:imageBuffer.nWidth height:imageBuffer.nHeight];
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
}

- (void)selectPolyonForUndo:(IntRect)selectionRect points:(IntPoint *)points pointNum:(int)nPointNumber mode:(int)mode feather:(int)nFeather
{
    CGPoint cgpoints[nPointNumber];
    for (int nIndex = 0; nIndex < nPointNumber; nIndex++)
        cgpoints[nIndex] = CGPointMake(points[nIndex].x, points[nIndex].y);
    IMAGE_BUFFER imageBuffer;
    COLOR_STRUCT colorFill = {255, 255, 255, 255};
    
    int nRet = CreateImageBufferFromPolygon(&imageBuffer, cgpoints, nPointNumber, colorFill, true, colorFill, nFeather);
    if(nRet < 0 )  return;
    
    [self flipImageBuffer:imageBuffer.pBuffer width:imageBuffer.nWidth height:imageBuffer.nHeight];
    [self select:imageBuffer selectionRect:selectionRect mode:mode feather:nFeather];
    
    DestroyImageBuffer(&imageBuffer);
}


-(void)flipImageBuffer:(unsigned char *)pImageBuffer width:(int)nWidth height:(int)nHeight
{
    unsigned char *pBufferTemp= (unsigned char *)malloc(nWidth * 4);
    
    for(int y=0; y< nHeight/2; y++)
    {
        memcpy(pBufferTemp, pImageBuffer + y* nWidth * 4, nWidth * 4);
        memcpy(pImageBuffer + y* nWidth * 4, pImageBuffer + (nHeight -y -1)* nWidth * 4, nWidth * 4);
        memcpy(pImageBuffer + (nHeight -y -1)* nWidth * 4, pBufferTemp, nWidth * 4);
    }
    
    free(pBufferTemp);
}


/*
 
 -(void)select:(IMAGE_BUFFER) imageBuffer selectionRect:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
 {
 id layer = [[m_idDocument contents] activeLayer];
 int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
 unsigned char *newMask, *tempMask, oldMaskPoint, newMaskPoint;
 IntRect newRect, oldRect, tempRect;
 int tempMaskPoint, tempMaskProduct;
 int i, j;
 int nOffsetX = 0;
 int nOffsetY = 0;
 
 selectionRect.origin.x -= 2*nFeather;
 selectionRect.origin.y -= 2*nFeather;
 selectionRect.size.width += 4*nFeather;
 selectionRect.size.height += 4*nFeather;
 
 if(!m_pMask)
 mode = kDefaultMode;
 
 // Get the rectangles
 if(mode){
 oldRect = [self localRect];
 newRect = selectionRect;
 m_sRect = IntSumRects(oldRect, newRect);
 } else {
 newRect = m_sRect = selectionRect;
 }
 
 m_bActive = NO;
 
 // Draw the circle
 newMask = malloc(m_sRect.size.width * m_sRect.size.height);
 memset(newMask, 0x00, m_sRect.size.width * m_sRect.size.height);
 
 // Constrain to the layer
 if(m_sRect.origin.x + m_sRect.size.width > width || m_sRect.origin.y + m_sRect.size.height > height || m_sRect.origin.x < 0 || m_sRect.origin.y < 0){
 tempRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, width, height));
 newRect = IntConstrainRect(newRect, IntMakeRect(0, 0, width, height));
 nOffsetX = tempRect.origin.x - m_sRect.origin.x;
 nOffsetY = tempRect.origin.y - m_sRect.origin.y;
 tempMask = malloc(tempRect.size.width * tempRect.size.height);
 memset(tempMask, 0x00, tempRect.size.width * tempRect.size.height);
 
 m_sRect = tempRect;
 free(newMask);
 newMask = tempMask;
 }
 
 for (i = 0; i < m_sRect.size.width; i++) {
 for (j = 0; j < m_sRect.size.height; j++) {
 // If we are in the rectangle of the new selection
 if(j >= newRect.origin.y - m_sRect.origin.y && j < newRect.origin.y - m_sRect.origin.y + newRect.size.height
 && i >= newRect.origin.x - m_sRect.origin.x && i < newRect.origin.x - m_sRect.origin.x + newRect.size.width)
 newMask[(j  * m_sRect.size.width + i)] = imageBuffer.pBuffer[(j - (newRect.origin.y - m_sRect.origin.y) + nOffsetY)*imageBuffer.nWidth*4 + (i - (newRect.origin.x - m_sRect.origin.x) + nOffsetX)*4 + 3];
 }
 }
 
 
 
 if(mode){
 for (i = 0; i < m_sRect.size.width; i++) {
 for (j = 0; j < m_sRect.size.height; j++) {
 newMaskPoint = newMask[j * m_sRect.size.width + i];
 
 // If we are in the m_sRect of the old m_pMask
 if(j >= oldRect.origin.y - m_sRect.origin.y && j < oldRect.origin.y - m_sRect.origin.y + oldRect.size.height
 && i >= oldRect.origin.x - m_sRect.origin.x && i < oldRect.origin.x - m_sRect.origin.x + oldRect.size.width)
 oldMaskPoint = m_pMask[(j - oldRect.origin.y + m_sRect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + m_sRect.origin.x)];
 else
 oldMaskPoint = 0x00;
 
 // Do the math
 switch(mode){
 case kAddMode:
 tempMaskPoint = oldMaskPoint + newMaskPoint;
 if(tempMaskPoint > 0xFF)
 tempMaskPoint = 0xFF;
 newMaskPoint = (unsigned char)tempMaskPoint;
 break;
 case kSubtractMode:
 tempMaskPoint = oldMaskPoint - newMaskPoint;
 if(tempMaskPoint < 0x00)
 tempMaskPoint = 0x00;
 newMaskPoint = (unsigned char)tempMaskPoint;
 break;
 case kMultiplyMode:
 tempMaskPoint = oldMaskPoint * newMaskPoint;
 tempMaskPoint /= 0xFF;
 newMaskPoint = (unsigned char)tempMaskPoint;
 break;
 case kSubtractProductMode:
 tempMaskProduct = oldMaskPoint * newMaskPoint;
 tempMaskProduct /= 0xFF;
 tempMaskPoint = oldMaskPoint + newMaskPoint;
 if(tempMaskPoint > 0xFF)
 tempMaskPoint = 0xFF;
 tempMaskPoint -= tempMaskProduct;
 if(tempMaskPoint < 0x00)
 tempMaskPoint = 0x00;
 newMaskPoint = (unsigned char)tempMaskPoint;
 break;
 default:
 NSLog(@"Selection mode not supported.");
 break;
 }
 newMask[j * m_sRect.size.width + i] = newMaskPoint;
 if(newMaskPoint > 0x00)
 m_bActive=YES;
 }
 }
 } else {
 if (m_sRect.size.width > 0 && m_sRect.size.height > 0)
 m_bActive = YES;
 }
 
 // Free previous mask information
 if (m_pMask) { free(m_pMask); m_pMask = NULL; }
 if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
 
 // Commit the new stuff
 m_sRect.origin.x += [layer xoff];
 m_sRect.origin.y += [layer yoff];
 m_sGlobalRect = m_sRect;
 
 if(m_bActive){
 m_pMask = newMask;
 [self trimSelection];
 [self updateMaskImage];
 }else{
 free(newMask);
 }
 
 // Update the changes
 [[m_idDocument helpers] selectionChanged];
 
 [self showAlphaBoundaries];
 }
 
 */

-(void)select:(IMAGE_BUFFER) imageBuffer selectionRect:(IntRect)selectionRect mode:(int)mode feather:(int)nFeather
{
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    unsigned char *newMask, *tempMask, oldMaskPoint, newMaskPoint;
    IntRect newRect, oldRect, tempRect;
    int tempMaskPoint, tempMaskProduct;
    int i, j;
    int nOffsetX = 0;
    int nOffsetY = 0;
    
    selectionRect.origin.x -= 2*nFeather;
    selectionRect.origin.y -= 2*nFeather;
    selectionRect.size.width += 4*nFeather;
    selectionRect.size.height += 4*nFeather;
    
    if(!m_pMask)
        mode = kDefaultMode;
    
    // Get the rectangles
    if(mode)
    {
        //        oldRect = [self localRect];
        //        newRect = selectionRect;
        //        m_sRect = IntSumRects(oldRect, newRect);
        
        oldRect = m_sRect;
        newRect = selectionRect;
        m_sRect = IntSumRects(m_sRect, selectionRect);
    }
    else
    {
        newRect = m_sRect = selectionRect;
    }
    
    m_bActive = NO;
    
    // Draw the circle
    newMask = malloc(m_sRect.size.width * m_sRect.size.height);
    memset(newMask, 0x00, m_sRect.size.width * m_sRect.size.height);
    
    //    // Constrain to the layer
    //    if(m_sRect.origin.x + m_sRect.size.width > width || m_sRect.origin.y + m_sRect.size.height > height || m_sRect.origin.x < 0 || m_sRect.origin.y < 0){
    //        tempRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, width, height));
    //        newRect = IntConstrainRect(newRect, IntMakeRect(0, 0, width, height));
    //        nOffsetX = tempRect.origin.x - m_sRect.origin.x;
    //        nOffsetY = tempRect.origin.y - m_sRect.origin.y;
    //        tempMask = malloc(tempRect.size.width * tempRect.size.height);
    //        memset(tempMask, 0x00, tempRect.size.width * tempRect.size.height);
    //
    //        m_sRect = tempRect;
    //        free(newMask);
    //        newMask = tempMask;
    //    }
    
    for (i = 0; i < m_sRect.size.width; i++)
    {
        for (j = 0; j < m_sRect.size.height; j++)
        {
            // If we are in the rectangle of the new selection
            if(j >= newRect.origin.y - m_sRect.origin.y && j < newRect.origin.y - m_sRect.origin.y + newRect.size.height
               && i >= newRect.origin.x - m_sRect.origin.x && i < newRect.origin.x - m_sRect.origin.x + newRect.size.width)
                newMask[(j  * m_sRect.size.width + i)] = imageBuffer.pBuffer[(j - (newRect.origin.y - m_sRect.origin.y) + nOffsetY)*imageBuffer.nWidth*4 + (i - (newRect.origin.x - m_sRect.origin.x) + nOffsetX)*4 + 3];
        }
    }
    
    
    
    if(mode)
    {
        for (i = 0; i < m_sRect.size.width; i++)
        {
            for (j = 0; j < m_sRect.size.height; j++)
            {
                newMaskPoint = newMask[j * m_sRect.size.width + i];
                
                // If we are in the m_sRect of the old m_pMask
                if(j >= oldRect.origin.y - m_sRect.origin.y && j < oldRect.origin.y - m_sRect.origin.y + oldRect.size.height
                   && i >= oldRect.origin.x - m_sRect.origin.x && i < oldRect.origin.x - m_sRect.origin.x + oldRect.size.width)
                    oldMaskPoint = m_pMask[(j - oldRect.origin.y + m_sRect.origin.y) * oldRect.size.width + (i - oldRect.origin.x + m_sRect.origin.x)];
                else
                    oldMaskPoint = 0x00;
                
                // Do the math
                switch(mode)
                {
                    case kAddMode:
                        tempMaskPoint = oldMaskPoint + newMaskPoint;
                        if(tempMaskPoint > 0xFF)
                            tempMaskPoint = 0xFF;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kSubtractMode:
                        tempMaskPoint = oldMaskPoint - newMaskPoint;
                        if(tempMaskPoint < 0x00)
                            tempMaskPoint = 0x00;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kMultiplyMode:
                        tempMaskPoint = oldMaskPoint * newMaskPoint;
                        tempMaskPoint /= 0xFF;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    case kSubtractProductMode:
                        tempMaskProduct = oldMaskPoint * newMaskPoint;
                        tempMaskProduct /= 0xFF;
                        tempMaskPoint = oldMaskPoint + newMaskPoint;
                        if(tempMaskPoint > 0xFF)
                            tempMaskPoint = 0xFF;
                        tempMaskPoint -= tempMaskProduct;
                        if(tempMaskPoint < 0x00)
                            tempMaskPoint = 0x00;
                        newMaskPoint = (unsigned char)tempMaskPoint;
                        break;
                    default:
                        //NSLog(@"Selection mode not supported.");
                        break;
                }
                newMask[j * m_sRect.size.width + i] = newMaskPoint;
                if(newMaskPoint > 0x00)
                    m_bActive=YES;
            }
        }
    }
    else
    {
        if (m_sRect.size.width > 0 && m_sRect.size.height > 0)
            m_bActive = YES;
    }
    
    // Free previous mask information
    if (m_pMask) { free(m_pMask); m_pMask = NULL; }
    if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
    
    // Commit the new stuff
    //    m_sRect.origin.x += [layer xoff];
    //    m_sRect.origin.y += [layer yoff];
    
    //   m_sGlobalRect = m_sRect;
    
    if(m_bActive)
    {
        m_pMask = newMask;
        [self trimSelection];
        [self updateMaskImage];
    }
    else
    {
        free(newMask);
    }
    
    // Update the changes
    [[m_idDocument helpers] selectionChanged];
    
    [self showAlphaBoundaries];
}

-(void)showAlphaBoundaries
{
    if (m_pMask)
    {
        for (int i = 0; i < m_sRect.size.width; i++)
        {
            for (int j = 0; j < m_sRect.size.height ; j++)
            {
                if (m_pMask[j * m_sRect.size.width + i] >= 128)
                {
                    return;
                }
            }
        }
        
        NSBeep();
        
        //[[PSController seaWarning] addMessage:LOCALSTR(@"The selection boundaries will not be visible if any pixel is less than 50%.", nil) forDocument: m_idDocument level:kHighImportance];
        
        [[PSController seaWarning] showAlertInfo:NSLocalizedString(@"The selection boundaries will not be visible if any pixel is less than 50%.", nil) infoText:@""];
    }
}


- (void)processOverlayInfo:(MAKE_OVERLAYER_INFO*)info
{
    id layer = [[m_idDocument contents] layer:info->activeLayer];
    int tolerance, width = [(PSLayer *)layer width], height = [(PSLayer *)layer height], spp = [[m_idDocument contents] spp], k;
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    unsigned char *data = NULL;
    unsigned char basePixel[4];
    IntRect rect;
    
    for (k = 0; k < spp - 1; k++)
        basePixel[k] = 0;
    basePixel[spp - 1] = 255;
    tolerance = info->tolerance;
    int intervals = info->intervals;
    
    IntPoint* seeds = malloc(sizeof(IntPoint) * (intervals + 1));
    
    int seedIndex;
    int xDelta = info->endPoint.x - info->startPoint.x;
    int yDelta = info->endPoint.y - info->startPoint.y;
    
    for(seedIndex = 0; seedIndex <= intervals; seedIndex++)
    {
        int x = info->startPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
        int y = info->startPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
        seeds[seedIndex] = IntMakePoint(x, y);
    }
    
    data = [(PSLayer *)layer getRawData];
    rect = bucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals + 1, basePixel, tolerance, [[m_idDocument contents] selectedChannel]);
    
    int nFeather = info->nFeather;
    rect.origin.x -= 2*nFeather;
    rect.origin.y -= 2*nFeather;
    rect.size.width += 4*nFeather;
    rect.size.height += 4*nFeather;
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, width, height));
    
    IMAGE_BUFFER pImageBuff;    //overlay考虑目前只支持4通道，所以直接overlay
    pImageBuff.nWidth = width;
    pImageBuff.nHeight = height;
    pImageBuff.pBuffer = overlay;
    
    GaussianBlurImageBuffer(&pImageBuff, nFeather);
    
    
    //    IntRect rectResult = rect;
    //    int nFeather = info->nFeather;
    //    rectResult.origin.x -= 2*nFeather;
    //    rectResult.origin.y -= 2*nFeather;
    //
    //    rectResult.size.width += 4*nFeather;
    //    rectResult.size.height += 4*nFeather;
    //
    //    rectResult = IntConstrainRect(rectResult, IntMakeRect(0, 0, width, height));
    //
    //    IMAGE_BUFFER pImageBuff;
    //    pImageBuff.nWidth = rectResult.size.width;
    //    pImageBuff.nHeight = rectResult.size.height;
    //    pImageBuff.pBuffer = malloc(rectResult.size.width * rectResult.size.height * 4);
    //    memset(pImageBuff.pBuffer, 0x00, rectResult.size.width * rectResult.size.height * 4);
    //    for (int i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
    //    {
    //        for (int j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    //        {
    //            int nX = i - rectResult.origin.x;
    //            int nY = j - rectResult.origin.y;
    //            pImageBuff.pBuffer[(nY  * rectResult.size.width + nX) * 4 + 3] = overlay[(j  * width + i) * spp + (spp - 1)];
    //        }
    //    }
    //
    //    GaussianBlurImageBuffer(&pImageBuff, nFeather);
    //    info->rect = rectResult;
    
    
    info->rect = rect;
    free(seeds);
    
    [(PSLayer *)layer unLockRawData];
    [overlayData unLockDataForWrite];
}

- (void)selectOverlay:(MAKE_OVERLAYER_INFO)info
{
    [self processOverlayInfo:&info];
    [self makeSelectionData:info isUndo:NO];
}

- (void)selectOverlayForUndo:(MAKE_OVERLAYER_INFO)info
{
    [[m_idDocument contents] setActiveLayerIndexComplete:info.activeLayer];
    
    [self processOverlayInfo:&info];
    [self makeSelectionData:info isUndo:YES];
}

- (void)makeSelectionData:(MAKE_OVERLAYER_INFO)makeInfo isUndo:(BOOL)isUndo
{
    IntRect selectionRect = makeInfo.rect;
    int mode = makeInfo.mode;
    
    id layer = [[m_idDocument contents] layer:makeInfo.activeLayer];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int xoff = [(PSLayer *)layer xoff];
    int yoff = [(PSLayer *)layer yoff];
    
    if (!isUndo)
    {
        if (selectionRect.size.width == 0 || selectionRect.size.height == 0)
        {
            if (mode == kForceNewMode || mode == kDefaultMode)
            {
                [self clearSelectionNoUndo];
                
                PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
                
                info.selectionType = 10;
                [m_selectionEventArray addObject:info];
                [m_selectionUndoEventArray removeAllObjects];
                [info release];
                
                [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
            }
            
            return;
        }
        
        PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
        info.selectionType = 4;
        info.selectionMode = mode;
        
        info.selectionRect = selectionRect;
        info.wandInfo = makeInfo;
        [m_selectionEventArray addObject:info];
        [m_selectionUndoEventArray removeAllObjects];
        [info release];
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    }
    
    
    int i, j, spp = [[m_idDocument contents] spp];
    unsigned char *overlay, *newMask, oldMaskPoint, newMaskPoint;
    IntRect newRect, oldRect;
    int tempMask, tempMaskProduct;
    
    // Get the rectangles
    
    //    newRect = selectionRect;
    //    newRect.origin.x += xoff;
    //    newRect.origin.y += yoff;
    
    newRect = IntConstrainRect(selectionRect, IntMakeRect(0, 0, width, height));
    
    if(!m_pMask || !m_bActive)
    {
        mode = kDefaultMode;
        m_sRect = newRect;
    }
    else
    {
        oldRect = m_sRect;
        oldRect.origin.x -= xoff;
        oldRect.origin.y -= yoff;
        m_sRect = IntSumRects(oldRect, newRect);
    }
    
    if(!mode)
        m_bActive = YES;
    else
        m_bActive = NO;
    
    newMask = malloc(m_sRect.size.width * m_sRect.size.height);
    memset(newMask, 0x00, m_sRect.size.width * m_sRect.size.height);
    overlay = [[m_idDocument whiteboard] overlay];
    
    for (i = m_sRect.origin.x; i < m_sRect.size.width + m_sRect.origin.x; i++)
    {
        for (j = m_sRect.origin.y; j < m_sRect.size.height + m_sRect.origin.y; j++)
        {
            if(mode)
            {
                // Find the mask of the new point
                if(i >= newRect.origin.x && j >= newRect.origin.y && i < newRect.size.width + newRect.origin.x && j < newRect.size.height + newRect.origin.y)
                {
                    if (i >= 0 && i < width && j >=0 && j < height)
                    {
                        newMaskPoint = overlay[(j  * width + i) * spp + (spp - 1)];
                    }
                    else
                    {
                        newMaskPoint = 0x00;
                    }
                    
                }
                else
                    newMaskPoint = 0x00;
                
                // Find the mask of the old point
                if(i >= oldRect.origin.x && j >= oldRect.origin.y && i < oldRect.size.width + oldRect.origin.x && j < oldRect.size.height + oldRect.origin.y)
                    oldMaskPoint = m_pMask[((j - oldRect.origin.y )* oldRect.size.width + i - oldRect.origin.x )];
                else
                    oldMaskPoint = 0x00;
                
                // Do the math
                switch(mode)
                {
                    case kAddMode:
                        tempMask = oldMaskPoint + newMaskPoint;
                        if(tempMask > 0xFF)
                            tempMask = 0xFF;
                        newMaskPoint = (unsigned char)tempMask;
                        break;
                    case kSubtractMode:
                        tempMask = oldMaskPoint - newMaskPoint;
                        if(tempMask < 0x00)
                            tempMask = 0x00;
                        newMaskPoint = (unsigned char)tempMask;
                        break;
                    case kMultiplyMode:
                        tempMask = oldMaskPoint * newMaskPoint;
                        tempMask /= 0xFF;
                        newMaskPoint = (unsigned char)tempMask;
                        break;
                    case kSubtractProductMode:
                        tempMaskProduct = oldMaskPoint * newMaskPoint;
                        tempMaskProduct /= 0xFF;
                        tempMask = oldMaskPoint + newMaskPoint;
                        if(tempMask > 0xFF)
                            tempMask = 0xFF;
                        tempMask -= tempMaskProduct;
                        if(tempMask < 0x00)
                            tempMask = 0x00;
                        newMaskPoint = (unsigned char)tempMask;
                        break;
                    default:
                        //NSLog(@"Selection mode not supported.");
                        break;
                }
                
                newMask[(j - m_sRect.origin.y) * m_sRect.size.width + i - m_sRect.origin.x] = newMaskPoint;
                if(newMaskPoint > 0x00)
                    m_bActive=YES;
            }
            else
            {
                // Store the new mask
                if (i >= 0 && i < width && j >=0 && j < height)
                {
                    newMask[(j - m_sRect.origin.y) * m_sRect.size.width + i - m_sRect.origin.x] = overlay[(j  * width + i) * spp + (spp - 1)];
                }
                
            }
            
            if (makeInfo.destructively)
            {
                if (i >= 0 && i < width && j >=0 && j < height)
                {
                    overlay[(j * width + i) * spp + (spp - 1)] = 0x00;
                }
                
            }
        }
    }
    
    // Free previous mask information
    if (m_pMask) { free(m_pMask); m_pMask = NULL; }
    if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
    
    // Commit the new stuff
    m_sRect.origin.x += xoff;
    m_sRect.origin.y += yoff;
    //  m_sGlobalRect = m_sRect;
    
    if(m_bActive)
    {
        m_pMask = newMask;
        [self trimSelection];
        [self updateMaskImage];
    }
    else
    {
        free(newMask);
    }
    //    [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
    // Update the changes
    [[m_idDocument helpers] selectionChanged];
}


//先不处理
- (void)selectOpaque
{
    [self selectOpaqueNeedUndo:YES];
}

- (void)selectOpaqueNeedUndo:(BOOL)isUndo
{
    id layer = [[m_idDocument contents] activeLayer];
    unsigned char *data = [(PSLayer *)layer getRawData];
    int spp = [[m_idDocument contents] spp], i;
    
    if (isUndo)
    {
        PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
        info.selectionType = 6;
        info.selectionMode = 0;
        info.selectionRect = IntMakeRect(0, 0, 0, 0);
        info.selectionFeather = 0;
        [m_selectionEventArray addObject:info];
        [m_selectionUndoEventArray removeAllObjects];
        [info release];
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    }
    
    
    // Free previous mask information
    if (m_pMask) { free(m_pMask); m_pMask = NULL; }
    if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
    
    // Adjust the rectangle
    m_sRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    //  m_sGlobalRect = m_sRect;
    
    // Activate the selection
    m_bActive = YES;
    
    // Make the mask
    m_pMask = malloc(m_sRect.size.width * m_sRect.size.height);
    for (i = 0; i < m_sRect.size.width * m_sRect.size.height; i++)
    {
        m_pMask[i] = data[(i + 1) * spp - 1];
    }
    
    [(PSLayer *)layer unLockRawData];
    [self trimSelection];
    [self updateMaskImage];
    
    //    [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
    // Make the change
    [[m_idDocument helpers] selectionChanged];
}

- (void)moveSelection:(IntPoint)newOrigin
{
    // Adjust the selection
    m_sRect.origin.x = newOrigin.x;
    m_sRect.origin.y = newOrigin.y;
    //    m_sGlobalRect = m_sRect;
    
    // Make the change
    [[m_idDocument helpers] selectionChanged];
}

/*
 - (void)moveSelection:(IntPoint)newOrigin
 {
 //[[[m_idDocument undoManager] prepareWithInvocationTarget:self] moveSelection:m_sGlobalRect.origin];
 
 id layer = [[m_idDocument contents] activeLayer];
 int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
 
 // Adjust the selection
 m_sRect.origin.x = newOrigin.x;
 m_sRect.origin.y = newOrigin.y;
 m_sGlobalRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, width, height));
 m_sRect.origin.x += [layer xoff];
 m_sRect.origin.y += [layer yoff];
 m_sGlobalRect.origin.x += [layer xoff];
 m_sGlobalRect.origin.y += [layer yoff];
 
 // Make the change
 [[m_idDocument helpers] selectionChanged];
 }
 
 */



- (void)readjustSelection
{
    //   return;
    id layer = [[m_idDocument contents] activeLayer];
    /*    if ([layer layerFormat] != PS_RASTER_LAYER)
     {
     return;
     }
     */
    IntRect layerRect;
    layerRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    
    IntRect m_sGlobalRect = [self globalRect];//IntConstrainRect(m_sRect, layerRect);
    
    if (m_sGlobalRect.size.width == 0 || m_sGlobalRect.size.height == 0)
    {
        m_bActive = NO;
        if (m_pMask) { free(m_pMask); m_pMask = NULL; }
    }
}

- (void)clearSelection
{
    if (![self floating])
    {
        m_bActive = NO;
        if (m_pMask) { free(m_pMask); m_pMask = NULL; }
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [[m_idDocument helpers] selectionChanged];
        
        //add by lcz
        m_sRect = IntMakeRect(0, 0, 0, 0);
        //  m_sGlobalRect = IntMakeRect(0, 0, 0, 0);
        
        PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
        info.selectionType = 10;
        [m_selectionEventArray addObject:info];
        [m_selectionUndoEventArray removeAllObjects];
        [info release];
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
        
    }
}

- (void)clearSelectionNoUndo
{
    if (![self floating])
    {
        m_bActive = NO;
        if (m_pMask) { free(m_pMask); m_pMask = NULL; }
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [[m_idDocument helpers] selectionChanged];
        
        //add by lcz
        m_sRect = IntMakeRect(0, 0, 0, 0);
        //  m_sGlobalRect = IntMakeRect(0, 0, 0, 0);
    }
}

- (void)clearSelectionShow
{
    if (![self floating])
    {
        m_bActive = NO;
        if (m_pMask) { free(m_pMask); m_pMask = NULL; }
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [[m_idDocument helpers] selectionChanged];
        
        //add by lcz
        m_sRect = IntMakeRect(0, 0, 0, 0);
        //    m_sGlobalRect = IntMakeRect(0, 0, 0, 0);
    }
}

- (void)invertSelection
{
    id layer = [[m_idDocument contents] activeLayer];
    int lwidth = [(PSContent *)[m_idDocument contents] width], lheight = [(PSContent *)[m_idDocument contents] height];
    //int xoff = [layer xoff], yoff = [layer yoff];
    int xoff = 0, yoff = 0;
    IntRect localRect = m_sRect;
    unsigned char *newMask;
    BOOL done = NO;
    int i, j, src, dest;
    
    PSSelectionEventInfo *info = [[PSSelectionEventInfo alloc] init];
    info.selectionType = 5;
    info.selectionMode = 0;
    info.selectionRect = IntMakeRect(0, 0, 0, 0);
    info.selectionFeather = 0;
    [m_selectionEventArray addObject:info];
    [m_selectionUndoEventArray removeAllObjects];
    [info release];
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoSelectionEvent:info index:(int)[m_selectionEventArray count] - 1];
    
    // Deal with simple inversions first
    if (!m_pMask)
    {
        if (localRect.origin.x == 0 && localRect.origin.y == 0)
        {
            if (localRect.size.width == lwidth)
            {
                m_sRect = IntMakeRect(0, localRect.size.height, lwidth, lheight - localRect.size.height);
                done = YES;
            }
            else if (localRect.size.height == lheight)
            {
                m_sRect = IntMakeRect(localRect.size.width, 0, lwidth - localRect.size.width, lheight);
                done = YES;
            }
        }
        else if (localRect.origin.x + localRect.size.width == lwidth && localRect.size.height == lheight)
        {
            m_sRect = IntMakeRect(0, 0, localRect.origin.x, lheight);
            done = YES;
        }
        else if (localRect.origin.y + localRect.size.height == lheight && localRect.size.width == lwidth)
        {
            m_sRect = IntMakeRect(0, 0, lwidth, localRect.origin.y);
            done = YES;
        }
    }
    
    // Then if that didn't work we have a complex inversions
    if (!done)
    {
        newMask = malloc(lwidth * lheight);
        memset(newMask, 0xFF, lwidth * lheight);
        for (j = 0; j < m_sRect.size.height; j++)
        {
            for (i = 0; i < m_sRect.size.width; i++)
            {
                if (m_pMask)
                {
                    if ((m_sRect.origin.y - yoff) + j >= 0 && (m_sRect.origin.y - yoff) + j < lheight &&
                        (m_sRect.origin.x - xoff) + i >= 0 && (m_sRect.origin.x - xoff) + i < lwidth)
                    {
                        src = j * m_sRect.size.width + i;
                        dest = ((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i;
                        newMask[dest] = 0xFF - m_pMask[src];
                    }
                }
                else
                {
                    newMask[((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i] = 0x00;
                }
            }
        }
        m_sRect = IntMakeRect(0, 0, lwidth, lheight);
        free(m_pMask);
        m_pMask = newMask;
    }
    
    // Finally clean everything up
    m_sRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, lwidth, lheight));
    //	m_sRect.origin.x += [layer xoff];
    //	m_sRect.origin.y += [layer yoff];
    //	m_sGlobalRect = m_sRect;
    if (m_sRect.size.width > 0 && m_sRect.size.height > 0)
    {
        m_bActive = YES;
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [self trimSelection];
        [self updateMaskImage];
    }
    else
    {
        m_bActive = NO;
    }
    [[m_idDocument helpers] selectionChanged];
}

- (void)invertSelectionForUndo
{
    id layer = [[m_idDocument contents] activeLayer];
    int lwidth = [(PSContent *)[m_idDocument contents] width], lheight = [(PSContent *)[m_idDocument contents] height];
    //int xoff = [layer xoff], yoff = [layer yoff];
    int xoff = 0, yoff = 0;
    IntRect localRect = m_sRect;
    unsigned char *newMask;
    BOOL done = NO;
    int i, j, src, dest;
    
    
    // Deal with simple inversions first
    if (!m_pMask) {
        if (localRect.origin.x == 0 && localRect.origin.y == 0)
        {
            if (localRect.size.width == lwidth)
            {
                m_sRect = IntMakeRect(0, localRect.size.height, lwidth, lheight - localRect.size.height);
                done = YES;
            }
            else if (localRect.size.height == lheight)
            {
                m_sRect = IntMakeRect(localRect.size.width, 0, lwidth - localRect.size.width, lheight);
                done = YES;
            }
        }
        else if (localRect.origin.x + localRect.size.width == lwidth && localRect.size.height == lheight)
        {
            m_sRect = IntMakeRect(0, 0, localRect.origin.x, lheight);
            done = YES;
        }
        else if (localRect.origin.y + localRect.size.height == lheight && localRect.size.width == lwidth)
        {
            m_sRect = IntMakeRect(0, 0, lwidth, localRect.origin.y);
            done = YES;
        }
    }
    
    // Then if that didn't work we have a complex inversions
    if (!done)
    {
        newMask = malloc(lwidth * lheight);
        memset(newMask, 0xFF, lwidth * lheight);
        for (j = 0; j < m_sRect.size.height; j++)
        {
            for (i = 0; i < m_sRect.size.width; i++)
            {
                if (m_pMask)
                {
                    if ((m_sRect.origin.y - yoff) + j >= 0 && (m_sRect.origin.y - yoff) + j < lheight &&
                        (m_sRect.origin.x - xoff) + i >= 0 && (m_sRect.origin.x - xoff) + i < lwidth) {
                        src = j * m_sRect.size.width + i;
                        dest = ((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i;
                        newMask[dest] = 0xFF - m_pMask[src];
                    }
                }
                else
                {
                    newMask[((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i] = 0x00;
                }
            }
        }
        m_sRect = IntMakeRect(0, 0, lwidth, lheight);
        free(m_pMask);
        m_pMask = newMask;
    }
    
    // Finally clean everything up
    m_sRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, lwidth, lheight));
    //	m_sRect.origin.x += [layer xoff];
    //	m_sRect.origin.y += [layer yoff];
    //  m_sGlobalRect = m_sRect;
    if (m_sRect.size.width > 0 && m_sRect.size.height > 0)
    {
        m_bActive = YES;
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [self trimSelection];
        [self updateMaskImage];
    }
    else
    {
        m_bActive = NO;
    }
    [[m_idDocument helpers] selectionChanged];
    
}



/*
 
 - (void)invertSelection
 {
 id layer = [[m_idDocument contents] activeLayer];
 int lwidth = [(PSLayer *)layer width], lheight = [(PSLayer *)layer height];
 int xoff = [layer xoff], yoff = [layer yoff];
 IntRect localRect = [self localRect];
 unsigned char *newMask;
 BOOL done = NO;
 int i, j, src, dest;
 
 // Deal with simple inversions first
 if (!m_pMask) {
 if (localRect.origin.x == 0 && localRect.origin.y == 0) {
 if (localRect.size.width == lwidth) {
 m_sRect = IntMakeRect(0, localRect.size.height, lwidth, lheight - localRect.size.height);
 done = YES;
 }
 else if (localRect.size.height == lheight) {
 m_sRect = IntMakeRect(localRect.size.width, 0, lwidth - localRect.size.width, lheight);
 done = YES;
 }
 }
 else if (localRect.origin.x + localRect.size.width == lwidth && localRect.size.height == lheight) {
 m_sRect = IntMakeRect(0, 0, localRect.origin.x, lheight);
 done = YES;
 }
 else if (localRect.origin.y + localRect.size.height == lheight && localRect.size.width == lwidth) {
 m_sRect = IntMakeRect(0, 0, lwidth, localRect.origin.y);
 done = YES;
 }
 }
 
 // Then if that didn't work we have a complex inversions
 if (!done) {
 newMask = malloc(lwidth * lheight);
 memset(newMask, 0xFF, lwidth * lheight);
 for (j = 0; j < m_sRect.size.height; j++) {
 for (i = 0; i < m_sRect.size.width; i++) {
 if (m_pMask) {
 if ((m_sRect.origin.y - yoff) + j >= 0 && (m_sRect.origin.y - yoff) + j < lheight &&
 (m_sRect.origin.x - xoff) + i >= 0 && (m_sRect.origin.x - xoff) + i < lwidth) {
 src = j * m_sRect.size.width + i;
 dest = ((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i;
 newMask[dest] = 0xFF - m_pMask[src];
 }
 }
 else {
 newMask[((m_sRect.origin.y - yoff) + j) * lwidth + (m_sRect.origin.x - xoff) + i] = 0x00;
 }
 }
 }
 m_sRect = IntMakeRect(0, 0, lwidth, lheight);
 free(m_pMask);
 m_pMask = newMask;
 }
 
 // Finally clean everything up
 m_sRect = IntConstrainRect(m_sRect, IntMakeRect(0, 0, lwidth, lheight));
 m_sRect.origin.x += [layer xoff];
 m_sRect.origin.y += [layer yoff];
 m_sGlobalRect = m_sRect;
 if (m_sRect.size.width > 0 && m_sRect.size.height > 0) {
 m_bActive = YES;
 if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
 [self trimSelection];
 [self updateMaskImage];
 }
 else {
 m_bActive = NO;
 }
 
 //    [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
 [[m_idDocument helpers] selectionChanged];
 }
 
 */

- (void)flipSelection:(int)type
{
    unsigned char tmp;
    int i, j, src, dest;
    
    // There's nothing to do if there's no mask
    if (m_pMask) {
        
        if (type == kHorizontalFlip)
        {
            for (i = 0; i < m_sRect.size.width / 2; i++)
            {
                for (j = 0; j < m_sRect.size.height; j++)
                {
                    src = j * m_sRect.size.width + m_sRect.size.width - i - 1;
                    dest = j * m_sRect.size.width + i;
                    tmp = m_pMask[dest];
                    m_pMask[dest] = m_pMask[src];
                    m_pMask[src] = tmp;
                }
            }
        }
        else
        {
            for (i = 0; i < m_sRect.size.width; i++)
            {
                for (j = 0; j < m_sRect.size.height / 2; j++)
                {
                    src = (m_sRect.size.height - j - 1) * m_sRect.size.width + i;
                    dest = j * m_sRect.size.width + i;
                    tmp = m_pMask[dest];
                    m_pMask[dest] = m_pMask[src];
                    m_pMask[src] = tmp;
                }
            }
        }
        
        if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
        [self trimSelection];
        [self updateMaskImage];
        
        
        //        [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
        [[m_idDocument helpers] selectionChanged];
        
        
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] flipSelection:type];
        
    }
}

- (unsigned char *)selectionData:(BOOL)premultiplied
{
    id layer = [[m_idDocument contents] activeLayer];
    int spp = [[m_idDocument contents] spp], width = [(PSLayer *)layer width];
    unsigned char *destPtr;
    //	IntRect localRect = [self localRect];
    IntPoint maskOffset = [self maskOffset];
    int i, j, k, selectedChannel, t1;
    
    // Get the selected channel
    selectedChannel = [[m_idDocument contents] selectedChannel];
    IntRect m_sGlobalRect = [self globalRect];
    
    // Copy the image data
    
    destPtr = malloc(make_128(m_sGlobalRect.size.width * m_sGlobalRect.size.height * spp));
    NSCAssert(destPtr, @"destPtr = malloc(make_128(m_sGlobalRect.size.width * m_sGlobalRect.size.height * spp));");
    
    
    {
        IntRect localRect = [self localRect];
        NSCAssert(localRect.origin.y >= 0 && localRect.origin.x >= 0, @"- (unsigned char *)selectionData:(BOOL)premultiplied");
        unsigned char *srcPtr = [(PSLayer *)layer getRawData];
        
        NSCAssert(((m_sGlobalRect.size.height -1 + localRect.origin.y) * width + localRect.origin.x) * spp + m_sGlobalRect.size.width * spp <= width * [(PSLayer *)layer height] * spp, @"rect range error in - (unsigned char *)selectionData:(BOOL)premultiplied");
        
        
        for (i = 0; i < m_sGlobalRect.size.height; i++)
        {
            memcpy(&(destPtr[i * m_sGlobalRect.size.width * spp]), &(srcPtr[((i + localRect.origin.y) * width + localRect.origin.x) * spp]), m_sGlobalRect.size.width * spp);
        }
        
        [(PSLayer *)layer unLockRawData];
    }
    
    // Apply the mask
    for (j = 0; j < m_sGlobalRect.size.height; j++)
    {
        for (i = 0; i < m_sGlobalRect.size.width; i++)
        {
            switch (selectedChannel)
            {
                case kAllChannels:
                    destPtr[(j * m_sGlobalRect.size.width + i + 1) * spp - 1] = int_mult(destPtr[(j * m_sGlobalRect.size.width + i + 1) * spp - 1], (m_pMask) ? m_pMask[(j + maskOffset.y) * m_sRect.size.width + i + maskOffset.x] : 255, t1);
                    break;
                case kPrimaryChannels:
                    destPtr[(j * m_sGlobalRect.size.width + i + 1) * spp - 1] = (m_pMask) ? m_pMask[(j + maskOffset.y) * m_sRect.size.width + i + maskOffset.x] : 255;
                    break;
                case kAlphaChannel:
                    for (k = 0; k < spp - 1; k++)
                        destPtr[(j * m_sGlobalRect.size.width + i ) * spp + k] = destPtr[(j * m_sGlobalRect.size.width + i + 1) * spp - 1];
                    destPtr[(j * m_sGlobalRect.size.width + i + 1) * spp - 1] = (m_pMask) ? m_pMask[(j + maskOffset.y) * m_sRect.size.width + i + maskOffset.x] : 255;
                    break;
            }
        }
    }
    
    if ([layer layerFormat] == PS_TEXT_LAYER || [layer layerFormat] == PS_VECTOR_LAYER)
    {
        unpremultiplyBitmap(spp, destPtr, destPtr, m_sGlobalRect.size.width * m_sGlobalRect.size.height);
    }
    // If we need to premultiply
    if (premultiplied)
        premultiplyBitmap(spp, destPtr, destPtr, m_sGlobalRect.size.width * m_sGlobalRect.size.height);
    
    return destPtr;
}

- (BOOL)selectionSizeMatch:(IntSize)inp_size
{
    if (inp_size.width == m_sSelSize.width && inp_size.height == m_sSelSize.height)
        return YES;
    else
        return NO;
}

- (IntPoint)selectionPoint
{
    return m_sSelPoint;
}

- (void)cutSelection
{
    [self copySelection];
    [self deleteSelection];
    [self clearSelection];
}

- (void)copySelection
{
    id pboard = [NSPasteboard generalPasteboard];
    int spp = [[m_idDocument contents] spp], i;
    NSBitmapImageRep *imageRep;
    unsigned char *data;
    BOOL containsNothing;
    
    if (m_bActive) {
        
        // Get the selection data
        data = [self selectionData:YES];
        
        // Check for nothingness
        containsNothing = YES;
        IntRect m_sGlobalRect = [self globalRect];
        
        for (i = 0; containsNothing && (i < m_sGlobalRect.size.width * m_sGlobalRect.size.height); i++) {
            if (data[(i + 1) * spp - 1] != 0x00)
                containsNothing = NO;
        }
        if (containsNothing) {
            free(data);
            NSRunAlertPanel(LOCALSTR(@"empty selection copy title", @"Selection empty"), LOCALSTR(@"empty selection copy body", @"The selection cannot be copied since it is empty."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
            return;
        }
        
        // Declare the data being added to the pasteboard
        [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];
        
        // Add it to the pasteboard
        imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:m_sGlobalRect.size.width pixelsHigh:m_sGlobalRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_sGlobalRect.size.width * spp bitsPerPixel:8 * spp];
        [pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType];
        [imageRep autorelease];
        
        // Stores the point of the last copied selection and its size
        m_sSelPoint = m_sGlobalRect.origin;
        m_sSelSize = m_sGlobalRect.size;
        
    }
}

- (void)deleteSelection
{
    id layer = [[m_idDocument contents] activeLayer], color;
    int i, j, spp = [[m_idDocument contents] spp], width = [(PSLayer *)layer width];
    IntRect localRect = [self localRect];
    unsigned char *overlay = [[m_idDocument whiteboard] overlay];
    unsigned char basePixel[4];
    int channel = [[m_idDocument contents] selectedChannel];
    
    localRect = IntConstrainRect(localRect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
    
    // Get the background colour
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
    
    // Set the overlay to erasing

    
    // Fill the overlay with the base pixel
    if(channel != kAlphaChannel)
    {
        if (YES) //[layer hasAlpha]
            [[m_idDocument whiteboard] setOverlayBehaviour:kErasingBehaviour];
        [[m_idDocument whiteboard] setOverlayOpacity:255];
        
        for (j = 0; j < localRect.size.height; j++) {
            for (i = 0; i < localRect.size.width; i++) {
                memcpy(&(overlay[((localRect.origin.y + j) * width + (localRect.origin.x + i)) * spp]), &basePixel, spp);
            }
        }
    }
    else
    {
        [[m_idDocument whiteboard] setOverlayBehaviour:kReplacingBehaviour];
        [[m_idDocument whiteboard] setOverlayOpacity:255];
        unsigned char *replace = [[m_idDocument whiteboard] replace];
        
        for (j = 0; j < localRect.size.height; j++) {
            for (i = 0; i < localRect.size.width; i++) {
                overlay[((localRect.origin.y + j) * width + (localRect.origin.x + i)) * spp + spp -1] = 0;
                replace[(localRect.origin.y + j) * width + (localRect.origin.x + i) ] = 0xff;
            }
        }
    }
    
    // Apply the overlay
    [(PSHelpers *)[m_idDocument helpers] applyOverlay];
}

- (void)adjustOffset:(IntPoint)offset
{
    m_sRect.origin.x += offset.x;
    m_sRect.origin.y += offset.y;
    //	m_sGlobalRect.origin.x += offset.x;
    //	m_sGlobalRect.origin.y += offset.y;
}

- (void)scaleSelectionHorizontally:(float)xScale vertically:(float)yScale interpolation:(int)interpolation
{
    IntRect newRect;
    
    if (m_bActive) {
        
        // Work out the new rectangle and allocate space for the new mask
        newRect = m_sRect;
        newRect.origin.x *= xScale;
        newRect.origin.y *= yScale;
        newRect.size.width *= xScale;
        newRect.size.height *= yScale;
        [self scaleSelectionTo: newRect from: m_sRect interpolation: interpolation usingMask: NULL];
    }
}

- (void)scaleSelectionTo:(IntRect)newRect from: (IntRect)oldRect interpolation:(int)interpolation usingMask: (unsigned char*)oldMask
{
    
    BOOL hFlip = NO;
    BOOL vFlip = NO;
    unsigned char *newMask = NULL;
    if(m_bActive && newRect.size.width != 0 && newRect.size.height != 0){
        // Create the new mask (if required)
        if(newRect.size.width < 0){
            newRect.origin.x += newRect.size.width;
            newRect.size.width *= -1;
            hFlip = YES;
        }
        
        if(newRect.size.height < 0){
            newRect.origin.y += newRect.size.height;
            newRect.size.height *= -1;
            vFlip = YES;
        }
        if(!oldMask)
            oldMask = m_pMask;
        
        if (oldMask) {
            unsigned char* flippedMask = malloc(oldRect.size.width * oldRect.size.height);
            memcpy(flippedMask, oldMask, oldRect.size.width * oldRect.size.height);
            if(hFlip)
                [(PSFlip *)[[(PSDocument *)gCurrentDocument operations] seaFlip] simpleFlipOf:flippedMask width:oldRect.size.width height:oldRect.size.height spp:1 type:kHorizontalFlip];
            if(vFlip)
                [(PSFlip *)[[(PSDocument *)gCurrentDocument operations] seaFlip] simpleFlipOf:flippedMask width:oldRect.size.width height:oldRect.size.height spp:1 type:kVerticalFlip];
            
            newMask = malloc(newRect.size.width * newRect.size.height);
            GCScalePixels(newMask, newRect.size.width, newRect.size.height, flippedMask, oldRect.size.width, oldRect.size.height, interpolation, 1);
            free(m_pMask);
            free(flippedMask);
            m_pMask = newMask;
        }
        
        // Substitute in the new stuff
        m_sRect = newRect;
        //    m_sGlobalRect = m_sRect;
        [self readjustSelection];
        if (m_pMask) {
            if (m_pMaskBitmap) { free(m_pMaskBitmap); m_pMaskBitmap = NULL; [m_imgMask autorelease]; m_imgMask = NULL; }
            [self updateMaskImage];
        }
        
        //        [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
        //        [[m_idDocument docView] setRefreshWhiteboardImage:false];
        //		[[m_idDocument docView] setNeedsDisplay: YES];
        
        // Update the changes
        [[m_idDocument helpers] selectionChanged];
        
    }
}

- (void)trimSelection
{
    //return;
    int selectionLeft = -1, selectionRight = -1, selectionTop = -1, selectionBottom = -1;
    int newWidth, newHeight, i, j;
    unsigned char *newMask;
    BOOL fullyOpaque = YES;
    
    // We only trim if the selction has a mask
    if (m_pMask) {
        
        // Determine left selection margin (do not swap iteration order)
        for (i = 0; i < m_sRect.size.width && selectionLeft == -1; i++) {
            for (j = 0; j < m_sRect.size.height && selectionLeft == -1; j++) {
                if (m_pMask[j * m_sRect.size.width + i] != 0) {
                    selectionLeft = i;
                }
            }
        }
        
        // Determine right selection margin (do not swap iteration order)
        for (i = m_sRect.size.width - 1; i >= 0 && selectionRight == -1; i--) {
            for (j = 0; j < m_sRect.size.height && selectionRight == -1; j++) {
                if (m_pMask[j * m_sRect.size.width + i] != 0) {
                    selectionRight = m_sRect.size.width - 1 - i;
                }
            }
        }
        
        // Determine top selection margin (do not swap iteration order)
        for (j = 0; j < m_sRect.size.height && selectionTop == -1; j++) {
            for (i = 0; i < m_sRect.size.width && selectionTop == -1; i++) {
                if (m_pMask[j * m_sRect.size.width + i] != 0) {
                    selectionTop = j;
                }
            }
        }
        
        // Determine bottom selection margin (do not swap iteration order)
        for (j = m_sRect.size.height - 1; j >= 0 && selectionBottom == -1; j--) {
            for (i = 0; i < m_sRect.size.width && selectionBottom == -1; i++) {
                if (m_pMask[j * m_sRect.size.width + i] != 0) {
                    selectionBottom = m_sRect.size.height - 1 - j;
                }
            }
        }
        
        // Check the mask for fully opacity
        newWidth = m_sRect.size.width - selectionLeft - selectionRight;
        newHeight = m_sRect.size.height - selectionTop - selectionBottom;
        for (j = 0; j < newHeight && fullyOpaque; j++) {
            for (i = 0; i < newWidth && fullyOpaque; i++) {
                if (m_pMask[(j + selectionTop) * m_sRect.size.width + (i + selectionLeft)] != 255) {
                    fullyOpaque = NO;
                }
            }
        }
        
        // If the revised mask is fully opaque
        if (fullyOpaque) {
            
            // Remove the mask and make the change
            m_sRect = IntMakeRect(m_sRect.origin.x + selectionLeft, m_sRect.origin.y + selectionTop, newWidth, newHeight);
            //		m_sGlobalRect = m_sRect;
            newMask = malloc(newWidth * newHeight);
            memset(newMask, 0xFF, newWidth * newHeight);
            free(m_pMask);
            m_pMask = newMask;
        }
        else {
            
            // Now make the change if required
            if (selectionLeft != 0 || selectionRight != 0 || selectionTop != 0 || selectionBottom != 0) {
                
                // Calculate the new mask
                newMask = malloc(newWidth * newHeight);
                for (j = 0; j < newHeight; j++) {
                    for (i = 0; i < newWidth; i++) {
                        newMask[j * newWidth + i] = m_pMask[(j + selectionTop) * m_sRect.size.width + (i + selectionLeft)];
                    }
                }
                
                // Finally make the change
                m_sRect = IntMakeRect(m_sRect.origin.x + selectionLeft, m_sRect.origin.y + selectionTop, newWidth, newHeight);
                free(m_pMask);
                m_pMask = newMask;
                //		m_sGlobalRect = m_sRect;
                
            }
            
        }
    }
    
}

@end
