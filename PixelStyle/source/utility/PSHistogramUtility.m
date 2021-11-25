//
//  PSHistogramUtility.m
//  PixelStyle
//
//  Created by lchzh on 4/11/15.
//
//

#import "PSHistogramUtility.h"

#import "InfoUtility.h"
#import "PSDocument.h"
#import "ToolboxUtility.h"
#import "PSTools.h"
#import "EyedropTool.h"
#import "PSSelection.h"
#import "PSView.h"
#import "PSContent.h"
#import "PSPrefs.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSPrefs.h"
#import "PositionTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "CropTool.h"
#import "Units.h"
#import "LayerControlView.h"
#import "PSWindowContent.h"

#import "PSLayer.h"

#import "PSHistogramDrawView.h"
#import "ConfigureInfo.h"

@implementation PSHistogramUtility

- (id)init
{
    m_channelType = 0;
    m_sourceType = 0;
    memset(m_grayHistogramInfo, 0, 256);
    return self;
}

- (void)awakeFromNib
{
    // Shown By Default
    [[PSController utilitiesManager] setHistogramUtility:self for:m_idDocument];
    //[(LayerControlView *)m_idControlView setHasResizeThumb:YES];
    //[(LayerControlView *)m_idControlViewChannel setHasResizeThumb:YES];
    
    if(![self visible]){
        //[m_idToggleButton setImage:[NSImage imageNamed:@"show-info"]];
    }
    
    [m_idHistogramView setCustomDelegate:self];
    
    
//    for (int i = 0; i < [m_idChooseChannel numberOfItems]; i++)
//    {
//        NSMenuItem *menuItem = (NSMenuItem *)[m_idChooseChannel itemAtIndex:i];
//        [menuItem setTitle:@""];
//    }
    
    [m_idChooseChannel selectItemAtIndex:m_channelType];
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_idChooseChannel itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Color", nil)];
    
    menuItem = [(NSPopUpButton *)m_idChooseChannel itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Luminosity", nil)];
//    [self initView];
}

-(void)initView
{
    CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
    CIColor *color = [CIColor colorWithRed:[TEXT_COLOR redComponent] green:[TEXT_COLOR greenComponent] blue:[TEXT_COLOR blueComponent] alpha:[TEXT_COLOR alphaComponent]];
    [filter setValue:color forKey:@"inputColor0"];
    [filter setValue:color forKey:@"inputColor1"];
    [m_idChooseChannel setContentFilters:[NSArray arrayWithObject:filter]];
}

- (void)shutdown
{
}

- (void)activate
{
    if([self visible]){
        [self update];
    }
}

- (void)deactivate
{
    
}

- (IBAction)show:(id)sender
{
    [[[m_idDocument window] contentView] setVisibility: YES forRegion: kPointInformation];
    //[m_idToggleButton setImage:[NSImage imageNamed:@"hide-info"]];
}

- (IBAction)hide:(id)sender
{
    [[[m_idDocument window] contentView] setVisibility: NO forRegion: kPointInformation];
    //[m_idToggleButton setImage:[NSImage imageNamed:@"show-info"]];
}

- (IBAction)toggle:(id)sender
{
    if ([self visible]) {
        [self hide:sender];
    }
    else {
        [self show:sender];
    }
}


- (void)updateHistogramInfo
{
    // Show no values
    if (!m_idDocument) {
        memset(m_grayHistogramInfo, 0, 256);
        memset(m_rgbHistogramInfo, 0, 256 * 3);
        return;
    }
    
    BOOL useSelection = [[m_idDocument selection] active];
    PSLayer* activeLayer = [[m_idDocument contents] activeLayer];
    IntRect selection = [[m_idDocument selection] localRect];
    
    int spp = [activeLayer spp];
    int width = [activeLayer width];
    int height = [activeLayer height];
    if (!useSelection) {
        selection = IntMakeRect(0, 0, width, height);
    }else{
        selection = IntConstrainRect(selection, IntMakeRect(0, 0, width, height));
    }
    unsigned char *data = [activeLayer getRawData];
    
    if(!data) return;
    
    int pos, i, j;
    int nStepX, nStepY;
    
    nStepX = selection.size.width/200;
    if(nStepX == 0) nStepX = 1;
    nStepY = selection.size.height/200;
    if(nStepY == 0) nStepY = 1;
    
    if (m_channelType == Histogram_Channel_COLOR) {
        float histogramInfo[256 * 3];
        memset(histogramInfo, 0, 256 * 3 * sizeof(float));
        
        for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j+=nStepY) {
            for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i+=nStepX) {
                pos = j * width + i;
                if (data[pos * spp + 3] != 0) {
                    histogramInfo[data[pos * spp + 0]] += 1.0f;
                    histogramInfo[256 + data[pos * spp + 1]] += 1.0f;
                    histogramInfo[512 + data[pos * spp + 2]] += 1.0f;
                }
            }
        }
        
        for (int channel = 0; channel < 3; channel++) {
            float max = histogramInfo[256 * channel + 0];
            for (int i = 1; i < 256; i++) {
                if (histogramInfo[256 * channel + i] > max) {
                    max = histogramInfo[256 * channel + i];
                }
            }
            max = MIN(max, 0.05 * selection.size.height * selection.size.width);
            max = MAX(max, 1.0);
            for (int i = 0; i < 256; i++) {
                m_rgbHistogramInfo[256 * channel + i] = (unsigned char)(MIN(histogramInfo[256 * channel + i], max) / max * 255.0);
            }

        }
        
        [activeLayer unLockRawData];
        return;

    }

    float histogramInfo[256];
    memset(histogramInfo, 0, 256 * sizeof(float));
    switch (m_channelType) {
        case Histogram_Channel_LUMINANCE:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j+=nStepY) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i+=nStepX) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        float grayf = (float)data[pos * spp] * 0.299 + (float)data[pos * spp + 1] * 0.587 + (float)data[pos * spp + 2] * 0.114;
                        grayf = MIN(255.0, grayf);
                        unsigned char grayn = (unsigned char)grayf;
                        histogramInfo[grayn] += 1.0f;
                    }
                    
//                    float grayf = (float)data[pos * spp] * 0.299 + (float)data[pos * spp + 1] * 0.587 + (float)data[pos * spp + 2] * 0.114;
////                    float grayf = (float)data[pos * spp] * 0.3333 + (float)data[pos * spp + 1] * 0.33333 + (float)data[pos * spp + 2] * 0.3333;
//                    grayf = MIN(255.0, grayf);
//                    unsigned char grayn = (unsigned char)grayf;
//                    histogramInfo[grayn] += 1.0f;
//                    
////                    for (int k = 0; k < 3; k++) {
////                        unsigned char grayn = (unsigned char)data[pos * spp + k];
////                        histogramInfo[grayn] += 1.0f;
////                    }
                }
            }
            break;
        }
        case Histogram_Channel_RED:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j+=nStepY) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i+=nStepX) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp]] += 1.0f;
                    }
                }
            }
            break;
        }
        case Histogram_Channel_GREEN:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j+=nStepY) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i+=nStepX) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp + 1]] += 1.0f;
                    }
                }
            }
            break;
        }
        case Histogram_Channel_BLUE:{
            for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j+=nStepY) {
                for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i+=nStepX) {
                    pos = j * width + i;
                    if (data[pos * spp + 3] != 0) {
                        histogramInfo[data[pos * spp + 2]] += 1.0f;
                    }
                }
            }
            break;
        }
        
        default:
            break;
    }
    
    float max = histogramInfo[0];
    for (int i = 1; i < 256; i++) {
        if (histogramInfo[i] > max) {
            max = histogramInfo[i];
        }
    }
    
    max = MIN(max, 0.05 * selection.size.height * selection.size.width);
    max = MAX(max, 1.0);
    for (int i = 0; i < 256; i++) {
        m_grayHistogramInfo[i] = (unsigned char)(MIN(histogramInfo[i], max) / max * 255.0);
    }
    
    [activeLayer unLockRawData];
    
}


- (int)getSelectedColorIndex
{
    return m_channelType;
}

- (unsigned char*)getGrayHistogramInfo
{
    return m_grayHistogramInfo;
}

- (unsigned char*)getRGBHistogramInfo
{
    return m_rgbHistogramInfo;
}


- (void)update
{
    [self updateHistogramInfo];
    [m_idHistogramView setNeedsDisplay:YES];
}

- (BOOL)visible
{
    return [[[m_idDocument window] contentView] visibilityForRegion: kPointInformation];
}


#pragma mark -  Channel
- (IBAction)changeChannel:(id)sender
{
    m_channelType = [m_idChooseChannel indexOfSelectedItem];
    [self update];
}

-(void)setChannel:(int)nChannelType
{
    if (m_channelType == nChannelType)  return;
    
    m_channelType = nChannelType;
    
    [m_idChooseChannel selectItemAtIndex:nChannelType];
}

@end
