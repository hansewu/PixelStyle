//
//  CISeamCarving.m
//  SeamCarving
//
//  Created by Calvin on 8/17/16.
//  Copyright © 2016 EffectMatrix. All rights reserved.
//

#import "CISeamCarving.h"
#import "PSPlugins.h"

//#include "seamCarving/seamCarving/SeamCarveApi.h"
#include "SeamCarveApi.h"
#import "MyImageView.h"

@implementation CISeamCarving
{
    //the indicator for progressing
    IBOutlet NSProgressIndicator *m_indicatorCircularProgress;
    //the slider for width
    IBOutlet NSSlider           *m_sliderWidth;
    //the slider for height
    IBOutlet NSSlider           *m_sliderHeight;
    // the textfield for width value
    IBOutlet NSTextField        *m_textfieldWidth;
    // the textfield for height value
    IBOutlet NSTextField        *m_textfieldHeight;
    // the instance for m_imageViewPreview
    IBOutlet MyImageView        *m_imageViewPreview;
    //the instance for windoow
    IBOutlet NSWindow           *m_panel;
    IBOutlet NSTextField        *m_labelNotice;
    IBOutlet NSButton           *m_btnReset;
    IBOutlet NSButton           *m_btnCancel;
    IBOutlet NSButton           *m_btnApply;
    
    IMAGE_DATA                  m_horizontalSeamsData;
    IMAGE_DATA                  m_verticalSeamsData;
    IMAGE_DATA                  m_expandHorizontalSeamData;
    IMAGE_DATA                  m_expandVerticalSeamData;
    
    NSRect                      m_rectShowImage;
    NSRect                      m_rectTransparent;
    
    // the width'value of the crystallization
    int                         m_nOutputWidthValue;
    // the height'value of the crystallization
    int                         m_nOutputHeightValue;
    
    int                         m_nOutputPreviousWidthValue;
    int                         m_nOutputPreviousHeightValue;
    // invoke the new thread
    NSThread                    *m_pThreadActive;
    // the scaling of the width and height
    int                         m_nScale;
    float                       m_fRatioScale;
}
-(id)initWithManager:(PSPlugins*)manager{
    if(self = [super init]){
        m_idSeaPlugins = manager;
        [NSBundle loadNibNamed:@"SeamCarving" owner:self];
           }
    return self;
}

-(NSString *)name{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"name" value:@"SeamCarving" table:NULL];
}

-(NSString *)groupName{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"groupName" value:@"AI" table:NULL];
}

-(int)type
{
    return 0;
}

-(NSString*) sanity{
    return @"PixelStyle Approved (Bobo)";
}

-(void)dealloc
{
    if(m_pThreadActive!=nil)
        [m_pThreadActive release];
    [super dealloc];
}

-(NSImage *)convertBufferToNSImage:(unsigned char *)pBuffer nWidth:(int)width nHeight:(int)height
{
    unsigned char* pBufferNew           = (unsigned char*)malloc(width*height*4);
    memset(pBufferNew,0,width*height*4);
    memcpy(pBufferNew,pBuffer,width*height*4);
    for(int i = 0;i < height;i++)
    {
        for(int j = 0;j < width; j++)
        {
            pBufferNew[i*width*4+j*4]   *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+1] *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+2] *= pBufferNew[i*width*4+4*j+3]/255.0;
        }
    }
    CGColorSpaceRef colorSpace      = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext      = CGBitmapContextCreate(pBufferNew,width,height,8,width*4,colorSpace,kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef             = CGBitmapContextCreateImage(bitmapContext);
    NSImage* image                  = [[[NSImage alloc]initWithCGImage:imageRef size:NSMakeSize(width,height)]autorelease];
    
    CGColorSpaceRelease(colorSpace);
    
    free(pBufferNew);
    pBufferNew = nil;
    
    return image;
}

-(void)refreshImage
{
    PluginData* pPluginData  = [(PSPlugins*)m_idSeaPlugins data];
    
    float fInputImageWidth    = [pPluginData width];
    float fInputImageHeight   = [pPluginData height];
    float fOutputImageWidth   = m_nOutputWidthValue;
    float fOutputImageHeight  = m_nOutputHeightValue;
    
    float fImageMaxWidth  = (fInputImageWidth > fOutputImageWidth) ? fInputImageWidth : fOutputImageWidth;
    float fImageMaxHeight = (fInputImageHeight > fOutputImageHeight) ? fInputImageHeight : fOutputImageHeight;
    
    float fImageInViewWidth, fImageInViewHeight;
    if(fImageMaxWidth > fImageMaxHeight)
    {
        fImageInViewWidth   = m_imageViewPreview.frame.size.width;
        fImageInViewHeight  = fImageMaxHeight/fImageMaxWidth * m_imageViewPreview.frame.size.width;
        m_fRatioScale       = fImageMaxWidth / fImageInViewWidth;
    }
    else
    {
        fImageInViewWidth   = fImageMaxWidth/fImageMaxHeight * m_imageViewPreview.frame.size.height;
        fImageInViewHeight  = m_imageViewPreview.frame.size.height;
        m_fRatioScale       = fImageMaxHeight / fImageInViewHeight;
    }
    
    float fOriginalImageInViewWidth = fInputImageWidth/fImageMaxWidth*fImageInViewWidth;
    float fOriginalImageInViewHeight = fInputImageHeight/fImageMaxHeight*fImageInViewHeight;
    
    m_rectTransparent = NSMakeRect((m_imageViewPreview.frame.size.width-fOriginalImageInViewWidth)/2 ,(m_imageViewPreview.frame.size.height-fOriginalImageInViewHeight)/2, fOriginalImageInViewWidth,fOriginalImageInViewHeight);

    [m_imageViewPreview setCenterTransparentRect:m_rectTransparent];
    
    float fWidth = m_nOutputWidthValue/fImageMaxWidth*fImageInViewWidth;
    float fHeight = m_nOutputHeightValue/fImageMaxHeight*fImageInViewHeight;
    m_rectShowImage = NSMakeRect((m_imageViewPreview.frame.size.width-fWidth)/2,(m_imageViewPreview.frame.size.height-fHeight)/2,fWidth,fHeight);

    [m_imageViewPreview setShowImageRect:m_rectShowImage];
}

static const int multiple = 2;
-(void)run{
    PluginData* pPluginData;
    pPluginData  = [(PSPlugins*)m_idSeaPlugins data];
    
    m_nOutputWidthValue  = [pPluginData width];
    m_nOutputHeightValue = [pPluginData height];
    m_nOutputPreviousWidthValue = [pPluginData width];
    m_nOutputPreviousHeightValue = [pPluginData height];
    
    [self setTheOriginalUI];

    unsigned char* buffer       = [pPluginData data];
    NSImage* image              = [[self convertBufferToNSImage:buffer nWidth:m_nOutputWidthValue nHeight:m_nOutputHeightValue] retain];
    [m_imageViewPreview setImage:image];
    
    
    [self refreshImage];
    [m_imageViewPreview setNeedsDisplay:YES];
    [image release];
    [NSApp runModalForWindow:m_panel];
}

-(void)setTheOriginalUI
{
    m_nScale    = [self resizeImageWithWidth:&m_nOutputWidthValue andHeight:&m_nOutputHeightValue];
    
    m_sliderWidth.continuous  = YES;
    m_sliderHeight.continuous = YES;
    
    [m_textfieldWidth setStringValue:[NSString stringWithFormat:@"%d",m_nOutputWidthValue]];
    [m_textfieldHeight setStringValue:[NSString stringWithFormat:@"%d",m_nOutputHeightValue]];
    
    [m_textfieldWidth.window makeFirstResponder:nil];
    
    m_sliderWidth.minValue        = m_nScale;
    m_sliderWidth.maxValue        = multiple * m_nOutputWidthValue;
    
    m_sliderHeight.minValue       = m_nScale;
    m_sliderHeight.maxValue       = multiple *m_nOutputHeightValue;
    
    [m_sliderWidth setIntValue:m_nOutputWidthValue];
    [m_sliderHeight setIntValue:m_nOutputHeightValue];
    
    m_bSuccess                     = NO;
    
    m_textfieldWidth.delegate     = self;
    m_textfieldHeight.delegate    = self;
}

-(void)reapply{
    PluginData* pPluginData;
    pPluginData = [(PSPlugins*)m_idSeaPlugins data];
    [pPluginData apply];
}


-(BOOL)canReapply{
    return m_bSuccess;
}

- (unsigned char*)scalePreviousImageAndReturnBuffer
{
    PluginData* pPluginData;
    pPluginData                  = [(PSPlugins*)m_idSeaPlugins data];
    
    IMAGE_DATA pluginImageData;
    pluginImageData.nChannels   = 4;
    pluginImageData.nWidth      = [pPluginData width];
    pluginImageData.nHeight     = [pPluginData height];
    pluginImageData.pData       = [pPluginData data];
    
    m_nScale = [self resizeImageWithWidth:&pluginImageData.nWidth andHeight:&pluginImageData.nHeight];
    
    IMAGE_DATA resizedInput;
    resizedInput.nChannels      = 4;
    resizedInput.nHeight        = pluginImageData.nHeight/m_nScale;
    resizedInput.nWidth         = pluginImageData.nWidth/m_nScale;
    resizedInput.pData          = (unsigned char*)malloc(resizedInput.nWidth * resizedInput.nHeight * resizedInput.nChannels);

    resizeImage(&pluginImageData, &resizedInput, 1);

    IMAGE_DATA output;
    output.nChannels            = 4;
    output.nHeight              = m_nOutputHeightValue/m_nScale;
    output.nWidth               = m_nOutputWidthValue/m_nScale;
    unsigned char* outBuffer    = (unsigned char*)malloc(output.nHeight * output.nWidth * 4);
    output.pData                = outBuffer;
    
    
    if(m_horizontalSeamsData.pData != nil)
    {
        free(m_horizontalSeamsData.pData);
        m_horizontalSeamsData.pData = nil;
    }
    m_horizontalSeamsData.nChannels = 1;
    m_horizontalSeamsData.nHeight   = resizedInput.nHeight;
    m_horizontalSeamsData.nWidth    = resizedInput.nWidth;
    m_horizontalSeamsData.pData  = (unsigned char*)malloc(m_horizontalSeamsData.nHeight * m_horizontalSeamsData.nWidth * m_horizontalSeamsData.nChannels);
    memset( m_horizontalSeamsData.pData , 0, m_horizontalSeamsData.nHeight * m_horizontalSeamsData.nWidth * m_horizontalSeamsData.nChannels);
   
    
    if(m_verticalSeamsData.pData      != nil)
    {
        free(m_verticalSeamsData.pData);
        m_verticalSeamsData.pData     = nil;
    }
    m_verticalSeamsData.nChannels     = 1;
    m_verticalSeamsData.nHeight       = output.nHeight;
    m_verticalSeamsData.nWidth        = resizedInput.nWidth;
    m_verticalSeamsData.pData = (unsigned char*)malloc(m_verticalSeamsData.nHeight * m_verticalSeamsData.nWidth * m_verticalSeamsData.nChannels);
    memset( m_verticalSeamsData.pData, 0, m_verticalSeamsData.nHeight * m_verticalSeamsData.nWidth * m_verticalSeamsData.nChannels);
    
    seamcarveImage(&resizedInput, &output,&m_horizontalSeamsData,&m_verticalSeamsData);
    
    free(resizedInput.pData);
    resizedInput.pData = nil;
    
    return output.pData;
}

-(IMAGE_DATA)excuteAlgorithmThenReturnBuffer
{
    PluginData* pPluginData = [(PSPlugins*)m_idSeaPlugins data];
    int nWidth = [pPluginData width];
    int nHeight = [pPluginData height];
    
    if(m_horizontalSeamsData.nWidth != 0 &&m_horizontalSeamsData.nHeight != 0 &&m_verticalSeamsData.nHeight != 0 && m_verticalSeamsData.nWidth != 0)
    {
        IMAGE_DATA pluginImageData;
        pluginImageData.nChannels   = 4;
        pluginImageData.nWidth      = nWidth;
        pluginImageData.nHeight     = nHeight;
        pluginImageData.pData       = [pPluginData data];
        
        IMAGE_DATA applyOutputImageData;
        applyOutputImageData.nChannels  = 4;
        applyOutputImageData.nWidth        = m_nOutputWidthValue;
        applyOutputImageData.nHeight       = m_nOutputHeightValue;
        applyOutputImageData.pData          = (unsigned char*)malloc(applyOutputImageData.nWidth * applyOutputImageData.nHeight * applyOutputImageData.nChannels);

        m_expandHorizontalSeamData.nHeight    = pluginImageData.nHeight;
        m_expandHorizontalSeamData.nWidth     = pluginImageData.nWidth;
        m_expandHorizontalSeamData.nChannels  = 1;
        m_expandHorizontalSeamData.pData      = (unsigned char*)malloc(m_expandHorizontalSeamData.nWidth * m_expandHorizontalSeamData.nHeight * m_expandHorizontalSeamData.nChannels);
        resizeImage(&m_horizontalSeamsData, &m_expandHorizontalSeamData, 0);
  
        m_expandVerticalSeamData.nHeight      = applyOutputImageData.nHeight;
        m_expandVerticalSeamData.nWidth       = pluginImageData.nWidth;
        m_expandVerticalSeamData.nChannels    = 1;
        m_expandVerticalSeamData.pData         = (unsigned char*)malloc(m_expandVerticalSeamData.nHeight * m_expandVerticalSeamData.nWidth * m_expandVerticalSeamData.nChannels);
        resizeImage(&m_verticalSeamsData, &m_expandVerticalSeamData, 0);
        
        //seamcarveImage(&pluginImageData, &applyOutputImageData, NULL, NULL);
        resizeImageWithSeams(&pluginImageData, &applyOutputImageData, &m_expandHorizontalSeamData, &m_expandVerticalSeamData);
        
        return applyOutputImageData;
    }
    else{
        //unsigned char * pAlloc = (unsigned char*)malloc(nWidth * nHeight *4);
        //memcpy(pAlloc, [pPluginData data], nWidth * nHeight * 4);
        IMAGE_DATA data;
        data.nWidth = nWidth;  data.nHeight = nHeight; data.nChannels = 4;
        data.pData =  (unsigned char*)malloc(nWidth * nHeight *4);
        memcpy(data.pData, [pPluginData data], nWidth * nHeight * 4);
        return data;
    }
}

static const float fMaxWidthForPreview   = 400;
static const float fMaxHeightForPreview  = 300;

-(int)resizeImageWithWidth:(int*)pWidth andHeight:(int*)pHeight
{
    int fScaleW = (*pWidth)/fMaxWidthForPreview;
    int fScaleH = (*pHeight)/fMaxHeightForPreview;
    return fScaleW > fScaleH ? fScaleW : fScaleH;
}

-(void)stopProgressIndicator
{
    m_btnReset.enabled     = YES;
    m_btnCancel.enabled    = YES;
    m_btnApply.enabled     = YES;
    [m_indicatorCircularProgress stopAnimation:self];
    [m_labelNotice setHidden:YES];
}

-(void)enableButton
{
    m_btnReset.enabled     = NO;
    m_btnCancel.enabled    = NO;
    m_btnApply.enabled     = NO;
}
//to progress in the sub thread
- (void)processInSubThread
{
    [self performSelectorOnMainThread:@selector(enableButton) withObject:nil waitUntilDone:NO];
    unsigned char* pChangedBuffer = [self scalePreviousImageAndReturnBuffer];
    if(m_bStopThread)
    {
        free(pChangedBuffer);
        pChangedBuffer                = nil;
        free(m_horizontalSeamsData.pData);
        m_horizontalSeamsData.pData   = nil;
        free(m_verticalSeamsData.pData);
        m_verticalSeamsData.pData     = nil;
        return;
    }
    NSImage* image      = [[self convertBufferToNSImage:pChangedBuffer nWidth:m_nOutputWidthValue/m_nScale nHeight:m_nOutputHeightValue/m_nScale]retain];
    
    [m_imageViewPreview setImage:image];
    [m_imageViewPreview setNeedsDisplay:YES];
    
    [image release];
    
    [self performSelectorOnMainThread:@selector(stopProgressIndicator) withObject:nil waitUntilDone:NO];
    free(pChangedBuffer);
    pChangedBuffer = nil;
}

-(void)updateUiAndStartSubThread
{
    if(m_nOutputPreviousWidthValue != m_nOutputWidthValue || m_nOutputPreviousHeightValue != m_nOutputHeightValue || !CGRectEqualToRect(NSRectToCGRect(m_rectShowImage), NSRectToCGRect([m_imageViewPreview showImageRect])))
    {
        [self refreshImage];
        [m_indicatorCircularProgress startAnimation:self];
        [m_labelNotice setHidden:NO];
        
        if(!m_pThreadActive)
        {
            m_bStopThread   = NO;
            stopSeamcarveImage(m_bStopThread);
            m_pThreadActive    = [[NSThread alloc]initWithTarget:self selector:@selector(processInSubThread) object:nil];
            [m_pThreadActive start];
        }else{
            m_bStopThread   = YES;
            stopSeamcarveImage(m_bStopThread);
            
            do
            {
                sleep(0.005);
                
            }while([m_pThreadActive isExecuting]);
            
            [m_pThreadActive release];
            m_pThreadActive    = nil;
            
            m_bStopThread   = NO;
            stopSeamcarveImage(m_bStopThread);
            
            m_pThreadActive    = [[NSThread alloc]initWithTarget:self selector:@selector(processInSubThread) object:nil];
            [m_pThreadActive start];
        }
    }
}
- (IBAction)upateWidthSlider:(NSSlider *)sender{
    m_nOutputPreviousWidthValue  = m_nOutputWidthValue;
    m_nOutputWidthValue          = [m_sliderWidth intValue];
    [m_textfieldWidth setStringValue:[NSString stringWithFormat:@"%d",m_nOutputWidthValue]];
    [self updateUiAndStartSubThread];
    }



- (IBAction)updateHeightSlider:(NSSlider *)sender{
    m_nOutputPreviousHeightValue  = m_nOutputHeightValue;
    m_nOutputHeightValue         = [m_sliderHeight intValue];
    [m_textfieldHeight setStringValue:[NSString stringWithFormat:@"%d",m_nOutputHeightValue]];
   [self updateUiAndStartSubThread];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
        PluginData* pPluginData;
        pPluginData              = [(PSPlugins*)m_idSeaPlugins data];

        if(control == m_textfieldWidth)
        {
            int nWidthValue    = [m_textfieldWidth intValue];
            if(nWidthValue>=multiple*m_nScale && nWidthValue<=multiple*[pPluginData width])
            {
                m_nOutputPreviousWidthValue = m_nOutputWidthValue;
                m_nOutputWidthValue      = nWidthValue;
                [m_sliderWidth setIntValue:m_nOutputWidthValue];
                [m_textfieldWidth setStringValue:[NSString stringWithFormat:@"%d",m_nOutputWidthValue]];
            }else{
                [m_textfieldWidth setStringValue:[NSString stringWithFormat:@"%d",m_nOutputWidthValue]];
                return YES;
            }
            
            [self updateUiAndStartSubThread];
            return YES;
        }else{
            int nHeightValue   = [m_textfieldHeight intValue];
            if(nHeightValue>=multiple*m_nScale &&nHeightValue<=multiple*[pPluginData height])
            {
                m_nOutputPreviousHeightValue = m_nOutputHeightValue;
                m_nOutputHeightValue     = nHeightValue;
                [m_sliderHeight setIntValue:m_nOutputHeightValue];
                [m_textfieldHeight setStringValue:[NSString stringWithFormat:@"%d",m_nOutputHeightValue]];
            }else{
                [m_textfieldHeight setStringValue:[NSString stringWithFormat:@"%d",m_nOutputHeightValue]];
                return YES;
            }
            [self updateUiAndStartSubThread];
            return YES;
        }
}

- (IBAction)cancel:(id)sender{
    [m_panel setAlphaValue:1.0];
    [NSApp stopModal];
    [NSApp endSheet:m_panel];
    [m_panel orderOut:self];
    m_bSuccess = NO;
}

-(void)replaceMemory:(unsigned char*)memory
{
    PluginData* pPluginData  = [(PSPlugins*)m_idSeaPlugins data];
    int nWidth               = [pPluginData width];
    int nHeight              = [pPluginData height];
    unsigned char* overlay   = [pPluginData overlay];
    memset(overlay, 0, nWidth * nHeight *4);
    
    NSRect imageRect         = [m_imageViewPreview showImageRect];
    NSRect transparentRect   = [m_imageViewPreview centerTransparentRect];
    
    float fDeltaX            = transparentRect.origin.x - imageRect.origin.x;
    float fDeltaY            = transparentRect.origin.y + transparentRect.size.height -(imageRect.origin.y + imageRect.size.height);
    
    float fOffsetXForOverlay = ceilf(fDeltaX * m_fRatioScale);
    float fOffsetYForOverlay = ceilf(fDeltaY * m_fRatioScale);
    int nOffsetXForOverlay = fOffsetXForOverlay;
    int nOffsetYForOverlay = fOffsetYForOverlay;
    nOffsetXForOverlay      = nOffsetXForOverlay >= 0 ? 0 : -nOffsetXForOverlay + 1;
    nOffsetYForOverlay      = nOffsetYForOverlay > 0 ? nOffsetYForOverlay : 0;
//    fOffsetXForOverlay       = fOffsetXForOverlay > 0 ? 0 : -fOffsetXForOverlay;
//    fOffsetYForOverlay       = fOffsetYForOverlay > 0 ? fOffsetYForOverlay : 0;
    
    overlay                         += nOffsetXForOverlay * 4 + nOffsetYForOverlay * nWidth * 4;
    
    int nOffSetXInOutputImage = ceilf((fDeltaX * m_fRatioScale)) * 4 > 0 ? ceilf((fDeltaX * m_fRatioScale)) * 4 : 0;
    int nOffSetYInOutputImage = ceilf((fDeltaY * m_fRatioScale)) * 4 > 0 ? 0 : -ceilf(fDeltaY * m_fRatioScale) * 4;

    memory                   += nOffSetYInOutputImage * m_nOutputWidthValue + nOffSetXInOutputImage;
    
    NSRect intersectRect      = NSIntersectionRect(transparentRect, imageRect);
  
    NSLog(@"%@",NSStringFromPoint(intersectRect.origin));
    NSPoint point ={transparentRect.origin.x + transparentRect.size.width,intersectRect.origin.y};
    NSLog(@"%@",NSStringFromPoint(point));
    for(int i = 0; i < (int)(intersectRect.size.height * m_fRatioScale); i++)
    {
//         NSLog(@"%f,%d",intersectRect.size.height * m_fRatioScale,(int)(intersectRect.size.width * m_fRatioScale));
        memcpy(overlay, memory, (int)(intersectRect.size.width * m_fRatioScale) * 4);
        overlay += nWidth * 4;
        memory  += m_nOutputWidthValue * 4;
    }
}

- (IBAction)resetImage:(id)sender {
    PluginData* pPluginData  = [(PSPlugins*)m_idSeaPlugins data];
    int nWidth               = [pPluginData width];
    int nHeight              = [pPluginData height];
    m_nOutputWidthValue      = nWidth;
    m_nOutputHeightValue     = nHeight;
    
    [m_sliderWidth setIntValue:m_nOutputWidthValue];
    [m_sliderHeight setIntValue:m_nOutputHeightValue];
    
    [m_textfieldWidth setStringValue:[NSString stringWithFormat:@"%d",m_nOutputWidthValue]];
    [m_textfieldHeight setStringValue:[NSString stringWithFormat:@"%d",m_nOutputHeightValue]];
    
    if(m_horizontalSeamsData.pData != nil)
    {
        free(m_horizontalSeamsData.pData);
        m_horizontalSeamsData.pData = nil;
    }
    if(m_verticalSeamsData.pData != nil)
    {
        free(m_verticalSeamsData.pData);
        m_verticalSeamsData.pData = nil;
    }
    
    [self updateUiAndStartSubThread];
}

-(void)closePanel
{
    [m_panel  setAlphaValue:1.0];
    [NSApp stopModal];
    [NSApp endSheet:m_panel];
    [m_panel orderOut:self];
    m_bSuccess = YES;
}

- (IBAction)apply:(id)sender{
    [m_indicatorCircularProgress startAnimation:nil];
    [m_labelNotice setHidden:NO];
 //   [self performSelectorInBackground:@selector(applyImage) withObject:nil];
    [self applyImage];
}

-(void)applyImage
{
    PluginData* pPluginData          = [(PSPlugins*)m_idSeaPlugins data];
    IMAGE_DATA pChangedMemory    = [self excuteAlgorithmThenReturnBuffer];
    
    [pPluginData applyWithNewDocumentData:pChangedMemory.pData  spp:pChangedMemory.nChannels width:pChangedMemory.nWidth height:pChangedMemory.nHeight];
  //  [self replaceMemory:pChangedMemory];
    if(pChangedMemory.pData != nil)
    {
        free(pChangedMemory.pData);
        pChangedMemory.pData                   = nil;
    }
    if(m_horizontalSeamsData.pData != nil)
    {
        free(m_horizontalSeamsData.pData);
        m_horizontalSeamsData.pData       = nil;
    }
    if(m_verticalSeamsData.pData != nil)
    {
        free(m_verticalSeamsData.pData);
        m_verticalSeamsData.pData         = nil;
    }
    NSLog(@"%p",m_expandHorizontalSeamData.pData);
    if(m_expandHorizontalSeamData.pData != nil)
    {
        free(m_expandHorizontalSeamData.pData);
        m_expandHorizontalSeamData.pData  = nil;
    }
    if(m_expandVerticalSeamData.pData != nil)
    {
        free(m_expandVerticalSeamData.pData);
        m_expandVerticalSeamData.pData    = nil;
    }

    [self performSelectorOnMainThread:@selector(stopProgressIndicator) withObject:nil waitUntilDone:NO];
    
    /*[pPluginData setOverlayOpacity:255];
    [pPluginData setOverlayBehaviour:kReplacingBehaviour];
    [pPluginData apply];*/
    [self closePanel];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    return YES;
}
@end
