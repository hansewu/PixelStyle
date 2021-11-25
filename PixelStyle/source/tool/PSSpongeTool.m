//
//  PSSpongeTool.m
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "PSSpongeTool.h"
#import "PSSpongeToolOptions.h"

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


@implementation PSSpongeTool


- (int)toolId
{
    return kSpongeTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Sponge Tool", nil);
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
    
    unsigned char *layerData = [layer getRawData];
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    
    BOOL floating = [layer floating];
    int t1;
    
    SpongeMode mode = [m_idOptions getSpongeMode];
    float flow = [m_idOptions getFlowValue];
    
    if (mode == kSpongeMode_Saturate) {
        flow = 1.0 + flow;
    }else if (mode == kSpongeMode_Desaturate){
        flow = 1.0 - flow;
    }
    
    brushData = [brush maskForPoint:point pressure:255];
    
    // Go through all valid points
    for (j = 0; j < brushHeight; j++) {
        for (i = 0; i < brushWidth; i++) {
            if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
                
                // Change the pixel colour appropriately
                overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
//                m_aBasePixel[spp - 1] = brushData[j * brushWidth + i];
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
                
                specialAlphaMerge(spp, overlay, overlayPos, m_aBasePixel, 0, pressure);
                
                unsigned char overlayAlpha = overlay[overlayPos + spp - 1];
                
                int brushAlpha = 255;
                if (useSelection) {
                    IntPoint tempPoint;
                    tempPoint.x = ipoint.x + i;
                    tempPoint.y = ipoint.y + j;
                    if (IntPointInRect(tempPoint, selectRect)) {
                        if (mask && !floating)
                            brushAlpha = int_mult(255, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    }else{
                        brushAlpha = 0;
                    }
                }
                if (brushAlpha > 0) {
                    if (spp == 4) {
                        
                        float red = m_layerRawData[overlayPos] / 255.0;
                        float green = m_layerRawData[overlayPos + 1] / 255.0;
                        float blue = m_layerRawData[overlayPos + 2] / 255.0;
                        float luminance = 0.2125 * red + 0.7154 * green + 0.0721 * blue;
                        
                        red = luminance * (1.0 - flow) + red * flow;
                        green = luminance * (1.0 - flow) + green * flow;
                        blue = luminance * (1.0 - flow) + blue * flow;
                        
                        red = MAX(0.0, MIN(1.0, red));
                        green = MAX(0.0, MIN(1.0, green));
                        blue = MAX(0.0, MIN(1.0, blue));
                        
                        m_aBasePixel[0] = (unsigned char)(red * 255);
                        m_aBasePixel[1] = (unsigned char)(green * 255);
                        m_aBasePixel[2] = (unsigned char)(blue * 255);
                        
                        brushAlpha = int_mult(brushAlpha, overlayAlpha, t1);
                        if (brushAlpha > 0) {
                            replacePrimaryMergeCustomSimple(spp, layerData, overlayPos, m_aBasePixel, 0, m_layerRawData, overlayPos, brushAlpha);
                        }
                        
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



@end
