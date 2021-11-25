//
//  PSDodgeTool.m
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "PSDodgeTool.h"
#import "PSDodgeToolOptions.h"

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

@implementation PSDodgeTool

- (int)toolId
{
    return kDodgeTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Dodge Tool", nil);
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
    
    DodgeRange range = [m_idOptions getDodgeRange];
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
                        
                        switch (range)
                        {
                            case kDodgeRange_Highlights:
                            {
                                for (int k = 0; k < spp - 1; k++) {
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    
//                                    float factor = exposure * 0.5; //exposure;
//                                    float add = MAX(0.0, expf(value - 0.5) - 1.0); //expf(value) - 1.0;
//                                    float result = value + factor * add;
                                    
                                    float result = value * (1.0 + exposure * 0.333333);
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                                
                            }
                                break;
                                
                            case kDodgeRange_Midtones:{
                                for (int k = 0; k < spp - 1; k++) {
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    
                                    float factor = exposure * 0.25;
                                    float result = value + factor * sinf(value * PI);
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                            }
                                break;
                                
                            case kDodgeRange_Shadows:{
                                for (int k = 0; k < spp - 1; k++) {
                                    float value = m_layerRawData[overlayPos + k] / 255.0;
                                    
                                    float factor = 1.0 - exposure * 0.5;
                                    float result = factor * value + (1.0 - factor);
                                    result = MAX(0.0, MIN(1.0, result));
                                    m_aBasePixel[k] = (unsigned char)(result * 255);
                                }
                            }
                                break;
                                
                            default:
                                break;
                        }
                        
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
