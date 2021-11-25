#import "PencilTool.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "StandardMerge.h"
#import "PSWhiteboard.h"
#import "PSLayerUndo.h"
#import "PSView.h"
#import "PencilOptions.h"
#import "PSController.h"
#import "OptionsUtility.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSLayer.h"
#import "PSTexture.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "Bucket.h"

#import "PSSelection.h"

static BOOL IntRectEqual(IntRect rect1, IntRect rect2)
{
    if(rect1.origin.x == rect2.origin.x && rect1.origin.y == rect2.origin.y && rect1.size.width == rect2.size.width && rect1.size.height == rect2.size.height)
        return YES;
    return NO;
}

@implementation PencilTool

- (int)toolId
{
	return kPencilTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Pencil Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"B";
}

- (id)init
{
    self = [super init];
    if(self)
    {
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt to erase. Press Shift to draw straight lines. Press Shift & Ctrl to draw lies at 45 degrees.", nil)];
    }
    return self;
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

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
    
	id activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
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
    
    BOOL hasAlpha = [layer hasAlpha];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int layerSpp = [layer spp];
    
    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay];
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    m_layerRawData = malloc(width * height * layerSpp);
    
    
    m_bFirstTouchDone = YES;
	
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
	int i, j, k, spp = [[m_idDocument contents] spp];
	int halfSize;
	IntPoint curPoint;
	NSColor *color = NULL;
	IntRect rect;
	int modifier = [(PencilOptions *)m_idOptions modifier];
    float alpha = [m_idOptions getOpacityValue];
	
	// Determine base pixels and hence pencil colour
    BOOL isErasing = [(PencilOptions*)m_idOptions pencilIsErasing];
	if (isErasing) {
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
	}
	else if ([m_idOptions useTextures]) {
		for (k = 0; k < spp - 1; k++)
			m_aBasePixel[k] = 0;
		m_aBasePixel[spp - 1] = 255;
	}
	else if (spp == 4) {
		color = [[m_idDocument contents] foreground];
		m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
		m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
		m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
		m_aBasePixel[3] = 255;
        
	}
	else {
		color = [[m_idDocument contents] foreground];
		m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
		m_aBasePixel[1] = 255;
	}
	
    m_overlayBehaviour = kNormalBehaviour;
	// Set the appropriate overlay opacity
	if ([m_idOptions pencilIsErasing]) {
//		if (hasAlpha)
//			[[m_idDocument whiteboard] setOverlayBehaviour:kErasingBehaviour];
//		[[m_idDocument whiteboard] setOverlayOpacity:255];
        if (hasAlpha)
            m_overlayBehaviour = kErasingBehaviour;
        m_brushAlpha = 255;
        [[m_idDocument whiteboard] setOverlayOpacity:0];
	}
	else {        
        if ([m_idOptions useTextures])
            m_brushAlpha = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
        else
            m_brushAlpha = (int)(alpha * 255.0);
        [[m_idDocument whiteboard] setOverlayOpacity:0];
	}
	
	// Determine the pencil size
	m_nSize = [m_idOptions pencilSize];
	halfSize = (m_nSize % 2 == 0) ? m_nSize / 2 - 1 : m_nSize / 2;
	
	// Work out the update rectangle
	rect = IntMakeRect(where.x - halfSize, where.y - halfSize, m_nSize, m_nSize);
	rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
    
    IntRect selectRect = [[m_idDocument selection] localRect];
    BOOL useSelection = [[m_idDocument selection] active];
    if (useSelection) {
        rect = IntConstrainRect(rect, selectRect);
    }
    
//    unsigned char *layerData = [layer getRawData];
//    IntRect selectRect = [[m_idDocument selection] localRect];
//    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
//    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
//    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
//    IntSize maskSize = [[m_idDocument selection] maskSize];
//    BOOL useSelection = [[m_idDocument selection] active];
//    int selectedChannel = [[m_idDocument contents] selectedChannel];
//    BOOL floating = [layer floating];
//    int t1;

    
	if (rect.size.width > 0 && rect.size.height > 0) {
		[self copyRawDataToTempInRect:rect];
		// Draw the initial dot
		for (j = 0; j < m_nSize; j++) {
			for (i = 0; i < m_nSize; i++) {
				curPoint.x = where.x - halfSize + i;
				curPoint.y = where.y - halfSize + j;
				if (curPoint.x >= 0 && curPoint.x < width && curPoint.y >= 0 && curPoint.y < height) {
					for (k = 0; k < spp; k++)
						overlay[(curPoint.y * width + curPoint.x) * spp + k] = m_aBasePixel[k];
                    
//                    int overlayPos = (curPoint.y * width + curPoint.x) * spp;
//                    int brushAlpha = m_brushAlpha;
//                    if (useSelection) {
//                        IntPoint tempPoint;
//                        tempPoint.x = curPoint.x;
//                        tempPoint.y = curPoint.y;
//                        if (IntPointInRect(tempPoint, selectRect)) {
//                            if (mask && !floating)
//                                brushAlpha = int_mult(m_brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
//                        }else{
//                            brushAlpha = 0;
//                        }
//                    }
//                    if (brushAlpha != 0) {
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
//                    }

				}
			}
		}
		
		// Do the update
		if ([m_idOptions useTextures] && ![m_idOptions pencilIsErasing])
			textureFill(spp, rect, overlay, [(PSLayer *)layer width], [(PSLayer *)layer height], [activeTexture texture:(spp == 4)], [(PSTexture *)activeTexture width], [(PSTexture *)activeTexture height]);
        [self combineDataToLayerInRect:rect];
        //[[m_idDocument helpers] overlayChanged:rect inThread:NO];
        PSLayer *layer = [[m_idDocument contents] activeLayer];
        [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
	
	}
	
    [overlayData unLockDataForWrite];
	// Record the position as the last point
	m_sLastPoint = where;
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
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    
    PS_EDIT_CHANNEL_TYPE editType = [layer editedChannelOfLayer];
    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++) {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++) {
            
            if (i >= 0 && i < width && j >= 0 && j < height) {
                
                int overlayPos = (j * width + i) * spp;
                int brushAlpha = m_brushAlpha;
                if (useSelection) {
                    IntPoint tempPoint;
                    tempPoint.x = i;
                    tempPoint.y = j;
                    if (IntPointInRect(tempPoint, selectRect)) {
                        if (mask && !floating)
                            brushAlpha = int_mult(m_brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }else{
                        brushAlpha = 0;
                    }
                }
                if (brushAlpha > 0) {
//                    if (selectedChannel == kAllChannels && !floating) {
//                        if (m_overlayBehaviour == kNormalBehaviour) {
//                            specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                            
//                        }else if (m_overlayBehaviour == kErasingBehaviour){
//                            eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                        }
//                    }
//                    else if (selectedChannel == kPrimaryChannels || floating) {
//                        unsigned char tempSpace[spp];
//                        memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                        primaryMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO);
//                        memcpy(layerData + overlayPos, tempSpace, spp);
//                    }
//                    else if (selectedChannel == kAlphaChannel) {
//                        unsigned char tempSpace[spp];
//                        memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                        alphaMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha);
//                        memcpy(layerData + overlayPos, tempSpace, spp);
//                    }
                    
                    switch (editType) {
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


- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if (!m_bFirstTouchDone) {
        [self mouseDownAt:where withEvent:event];
        m_bFirstTouchDone = YES;
        return;
    }
    
    if ([[m_idDocument docView] isLineDrawing]) {
        [self resetBrushInfo];
    }
    
	id activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
	id layer = [[m_idDocument contents] activeLayer];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	int xMod = (m_sLastPoint.x > where.x) ? -1 : 1, yMod = (m_sLastPoint.y > where.y) ? -1 : 1;
	int xDist = abs(m_sLastPoint.x - where.x), yDist = abs(m_sLastPoint.y - where.y);
	int i, i2, j2, k, spp = [[m_idDocument contents] spp];
	IntPoint curPoint, revisedCurPoint, newLastPoint;
	int halfSize = (m_nSize % 2 == 0) ? m_nSize / 2 - 1 : m_nSize / 2;
	IntRect rect;
	
	// Only continue if the current point is different from the last point
	if (m_sLastPoint.x == where.x && m_sLastPoint.y == where.y)
		return;
	
	// If nothing changes we want the new last point to be the same as the old one
	newLastPoint = m_sLastPoint;
    
    
//    unsigned char *layerData = [layer getRawData];
//    IntRect selectRect = [[m_idDocument selection] localRect];
//    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
//    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
//    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
//    IntSize maskSize = [[m_idDocument selection] maskSize];
//    BOOL useSelection = [[m_idDocument selection] active];
//    int selectedChannel = [[m_idDocument contents] selectedChannel];
//    BOOL floating = [layer floating];
//    int t1;
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
	
	// Draw a line between the last point and this point
	for (i = 1; i <= MAX(xDist, yDist); i++) {
		if (xDist > yDist) {
			curPoint.x = m_sLastPoint.x + i * xMod;
			curPoint.y = m_sLastPoint.y + (i * yDist) / xDist * yMod;
		}
		else {
			curPoint.x = m_sLastPoint.x + (i * xDist) / yDist * xMod;
			curPoint.y = m_sLastPoint.y + i * yMod;
		}
		
		rect = IntMakeRect(curPoint.x - halfSize, curPoint.y - halfSize, m_nSize, m_nSize);
		rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]));
        
        IntRect selectRect = [[m_idDocument selection] localRect];
        BOOL useSelection = [[m_idDocument selection] active];
        if (useSelection) {
            rect = IntConstrainRect(rect, selectRect);
        }
        
		if (rect.size.width > 0 && rect.size.height > 0) {
            [self copyRawDataToTempInRect:rect];
			for (i2 = 0; i2 < m_nSize; i2++) {
				for (j2 = 0; j2 < m_nSize; j2++) {
					revisedCurPoint.x = curPoint.x - halfSize + i2;
					revisedCurPoint.y = curPoint.y - halfSize + j2;
					if (revisedCurPoint.x >= 0 && revisedCurPoint.x < width && revisedCurPoint.y >= 0 && revisedCurPoint.y < height) {
						for (k = 0; k < spp; k++)
							overlay[(revisedCurPoint.y * width + revisedCurPoint.x) * spp + k] = m_aBasePixel[k];
                        
//                        int overlayPos = (revisedCurPoint.y * width + revisedCurPoint.x) * spp;
//                        int brushAlpha = m_brushAlpha;
//                        if (useSelection) {
//                            IntPoint tempPoint;
//                            tempPoint.x = revisedCurPoint.x;
//                            tempPoint.y = revisedCurPoint.y;
//                            if (IntPointInRect(tempPoint, selectRect)) {
//                                if (mask && !floating)
//                                    brushAlpha = int_mult(m_brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
//                            }else{
//                                brushAlpha = 0;
//                            }
//                        }
//                        if (brushAlpha > 0) {
//                            if (selectedChannel == kAllChannels && !floating) {
//                                if (m_overlayBehaviour == kNormalBehaviour) {
//                                    specialMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                                }else if (m_overlayBehaviour == kErasingBehaviour){
//                                    eraseMergeCustom(spp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, brushAlpha);
//                                }
//                            }
//                            else if (selectedChannel == kPrimaryChannels || floating) {
//                                unsigned char tempSpace[spp];
//                                memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                                primaryMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha, NO);
//                                memcpy(layerData + overlayPos, tempSpace, spp);
//                            }
//                            else if (selectedChannel == kAlphaChannel) {
//                                unsigned char tempSpace[spp];
//                                memcpy(tempSpace, m_layerRawData + overlayPos, spp);
//                                alphaMerge(spp, tempSpace, 0, overlay, overlayPos, brushAlpha);
//                                memcpy(layerData + overlayPos, tempSpace, spp);
//                            }
//                        }

					}
				}
			}
		
			if ([m_idOptions useTextures] && ![m_idOptions pencilIsErasing])
				textureFill(spp, rect, overlay, [(PSLayer *)layer width], [(PSLayer *)layer height], [activeTexture texture:(spp == 4)], [(PSTexture *)activeTexture width], [(PSTexture *)activeTexture height]);
            
            [self combineDataToLayerInRect:rect];
			
            [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
            
		}
		newLastPoint = curPoint;
	}
    
    [overlayData unLockDataForWrite];
	m_sLastPoint = newLastPoint;
    
    if ([[m_idDocument docView] isLineDrawing]) {
        [self oneLineDrawingEnd];
    }
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


- (void)resetBrushInfo
{    
    id layer = [[m_idDocument contents] activeLayer];
    [layer setFullRenderState:NO];
    
    BOOL hasAlpha = [layer hasAlpha];
  
    int k, spp = [[m_idDocument contents] spp];
    
    NSColor *color = NULL;
    
    int modifier = [(PencilOptions *)m_idOptions modifier];
    float alpha = [m_idOptions getOpacityValue];
    
    BOOL isErasing = [(PencilOptions*)m_idOptions pencilIsErasing];
    // Determine base pixels and hence pencil colour
    if (isErasing) {
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
    }
    else if ([m_idOptions useTextures]) {
        for (k = 0; k < spp - 1; k++)
            m_aBasePixel[k] = 0;
        m_aBasePixel[spp - 1] = 255;
    }
    else if (spp == 4) {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        m_aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        m_aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        m_aBasePixel[3] = 255;
        
    }
    else {
        color = [[m_idDocument contents] foreground];
        m_aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        m_aBasePixel[1] = 255;
    }
    
    m_overlayBehaviour = kNormalBehaviour;
    // Set the appropriate overlay opacity
    if ([m_idOptions pencilIsErasing]) {
        if (hasAlpha)
            m_overlayBehaviour = kErasingBehaviour;
        m_brushAlpha = 255;
        [[m_idDocument whiteboard] setOverlayOpacity:0];
    }
    else {
        if ([m_idOptions useTextures])
            m_brushAlpha = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
        else
            m_brushAlpha = (int)(alpha * 255.0);
        [[m_idDocument whiteboard] setOverlayOpacity:0];
    }
    
    // Determine the pencil size
    m_nSize = [m_idOptions pencilSize];
    
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if (!m_layerRawData) {
        return;
    }
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    
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
    //[[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    
    if (m_layerRawData) {
        free(m_layerRawData);
        m_layerRawData = NULL;
    }
    
    if (m_dataLayerLast)
    {
        free(m_dataLayerLast);
        m_dataLayerLast = NULL;
    }
    
    [layer setFullRenderState:YES];
    
    
    m_bFirstTouchDone = NO;
	
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
    m_nSize = [m_idOptions pencilSize];
    float fRadius = (m_nSize % 2 == 0) ? m_nSize / 2 - 1 : m_nSize / 2;
    
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
    CGContextStrokeRect(ctx, CGRectMake(0, 0, 2 * fRadius * fScale + 1, 2 * fRadius * fScale + 1));
    
    [[NSColor blackColor] set];
    CGContextStrokeRect(ctx, CGRectMake(1, 1, 2 * fRadius * fScale - 1, 2 * fRadius * fScale - 1));
    
    CGContextFillRect(ctx, NSMakeRect(fRadius * fScale/2.0 + 0.5 , fRadius * fScale, fRadius * fScale, 1));
    
    CGContextFillRect(ctx, NSMakeRect(fRadius * fScale, fRadius * fScale/2.0 + 0.5, 1, fRadius * fScale));
    
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
