//
//  PSRedEyeRemove.m
//  PixelStyle
//
//  Created by wyl on 16/4/20.
//
//

#import "PSRedEyeRemoveTool.h"
#import "PSRedEyeRemoveOptions.h"
#import "PSTools.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSSelection.h"
#import "PSWhiteboard.h"
#import "PSHelpers.h"
#import "PSView.h"
#import "PSLayerUndo.h"

@implementation PSRedEyeRemoveTool

- (int)toolId
{
    return kRedEyeRemoveTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Red Eye Remove Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"R";
}

- (id)init
{
    if(![super init])
        return NULL;
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    id layer = [[m_idDocument contents] activeLayer];
    [layer setFullRenderState:NO];

    m_dataChangedRect = IntMakeRect(0, 0, 0, 0);
    [[m_idDocument whiteboard] clearOverlay];
    memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
    m_overlayBehaviour = kNormalBehaviour;
    // Set the appropriate overlay opacity
    [[m_idDocument whiteboard] setOverlayOpacity:0];
    
    int nWidth = [(PSAbstractLayer *)layer width];
    int nHeight = [(PSAbstractLayer *)layer height];
    int nSpp = [[m_idDocument contents] spp];
    if(nSpp == 2) return;

    if (m_layerRawData) { free(m_layerRawData); m_layerRawData = NULL; }
    m_layerRawData = malloc(nWidth * nHeight * nSpp);
    
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    int selectedChannel = [[m_idDocument contents] selectedChannel];
    BOOL floating = [layer floating];
    
    float fRadius = [(PSRedEyeRemoveOptions *)m_idOptions getRadiusSize];
    IntRect rect = {{where.x - fRadius , where.y - fRadius}, {fRadius * 2 +1, fRadius * 2 +1}};
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, nWidth, nHeight));

    
    [self copyRawDataToTempInRect:rect];
    [self combineWillBeProcessDataRect:rect];
    
    unsigned char *layerData = [layer getRawData];
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    
    int t1, nAlpha = 255;
    int nPixelR, nPixelG, nPixelB;
    
    for(int x = where.x - fRadius; x <= where.x + fRadius; x ++)
        for (int y = where.y - fRadius; y <= where.y + fRadius; y++)
        {
            if (x >= 0 && y >= 0 && x < nWidth && y < nHeight)
            {
                if( (x - where.x) * (x - where.x) + (y - where.y) * (y - where.y) > fRadius * fRadius) continue;
                int overlayPos = y * nWidth * nSpp + x * nSpp;
                
                nAlpha = 255;
                if (useSelection)
                {
                    nAlpha = 0;
                    
                    IntPoint tempPoint;
                    tempPoint.x = x;
                    tempPoint.y = y;
                    if (IntPointInRect(tempPoint, selectRect))
                    {
                        if (mask)
                            nAlpha = int_mult(255, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }
                }
                
                if(nAlpha > 0)
                {
                    nPixelR = layerData[y*nWidth*nSpp + x *nSpp];
                    nPixelG = layerData[y*nWidth*nSpp + x *nSpp + 1];
                    nPixelB = layerData[y*nWidth*nSpp + x *nSpp + 2];
                    
                    float fRedIntensity = ((float)nPixelR / ((nPixelG + nPixelB) / 2.0));
                    if(fRedIntensity > 1.0f) // 1.5 because it gives the best results
                        nPixelR = nAlpha/255.0 * (nPixelG + nPixelB) / 2 + (1- nAlpha/255.0) * nPixelR;
                    
                    overlay[y * nWidth * nSpp + x * nSpp] = nPixelR;
                    overlay[y * nWidth * nSpp + x * nSpp + 1] = nPixelG;
                    overlay[y * nWidth * nSpp + x * nSpp + 2] = nPixelB;
                    overlay[y * nWidth * nSpp + x * nSpp + (nSpp - 1)] = layerData[y * nWidth * nSpp + x * nSpp + (nSpp - 1)];
                    
                    
                    if (selectedChannel == kAllChannels && !floating) {
                        if (m_overlayBehaviour == kNormalBehaviour) {
                            replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, nAlpha, 0);
                        }
                    }
                    else if (selectedChannel == kPrimaryChannels || floating) {
                        replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, nAlpha, 1);
                    }
                    else if (selectedChannel == kAlphaChannel) {
                        replaceMergeCustom(nSpp, layerData, overlayPos, overlay, overlayPos, m_layerRawData, overlayPos, nAlpha, 2);
                    }

                }
            }
        }
    
    
    [overlayData unLockDataForWrite];
    [(PSLayer *)layer unLockRawData];
    
    [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{

}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    PSLayer *layer = [[m_idDocument contents] activeLayer];
    [self copyRawDataToTempInRect:m_dataChangedRect];
    [[layer seaLayerUndo] takeSnapshot:m_dataChangedRect automatic:YES date:m_layerRawData];
    
    if (m_layerRawData) { free(m_layerRawData); m_layerRawData = NULL;}
    
    [layer setFullRenderState:YES];
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    [self updateCursor];
    
    [super mouseMoveTo:where withEvent:event];
}

-(void)updateCursor
{
    float fRadius = [(PSRedEyeRemoveOptions *)m_idOptions getRadiusSize];
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
    
    CGContextFillRect(ctx, NSMakeRect(fRadius * fScale/2.0 + 0.5 , fRadius * fScale, fRadius * fScale, 1));
    
    CGContextFillRect(ctx, NSMakeRect(fRadius * fScale, fRadius * fScale/2.0 + 0.5, 1, fRadius * fScale));
    
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
