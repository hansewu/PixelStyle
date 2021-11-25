//
//  PSSynthesizeImageRender.m
//  PixelStyle
//
//  Created by wyl on 16/1/5.
//
//

#import "PSSynthesizeImageRender.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSCompositor.h"
#import "PSWhiteboard.h"
#import "PSView.h"
#import "PSTools.h"
#import "PSAbstractLayer.h"
#import "AbstractTool.h"
#import "Globals.h"

@interface NSObject (PSSynthesizeImageRenderDelegate)

- (id)getCurrentDocumnet;

@end


@implementation PSSynthesizeImageRender


-(id)init
{
    self = [super init];
    if(self)
    {
        m_cgLayerSynthesizedImage = nil;
        
        m_bCanSynthesizeImage = true;
        m_bFinishedThread = YES;
        
        m_lockCGlayer = [[NSRecursiveLock alloc] init];
        
        m_threadRenderImage = [[NSThread alloc] initWithTarget:self selector:@selector(renderImageInThread) object:nil];
        [self performSelector:@selector(delayeStartThread) withObject:nil afterDelay:0.5];
    }
    
    return self;
}

-(id)initWithDocument:(id)document
{
    self = [self init];
    m_idDocument = document;
    return self;
}

-(void)delayeStartThread
{
    [m_threadRenderImage start];
}

-(void)dealloc
{
    if(m_threadRenderImage)
    {
        [self exitRenderImageThread];
        
        [m_threadRenderImage release]; m_threadRenderImage = nil;
    }
    
    [m_lockCGlayer lock];
    if(m_cgLayerSynthesizedImage)  { CGLayerRelease(m_cgLayerSynthesizedImage); m_cgLayerSynthesizedImage = nil;}
    [m_lockCGlayer unlock];
    
    [m_lockCGlayer release]; m_lockCGlayer = nil;
    
    [super dealloc];
}

-(void)exitRenderImageThread
{
    if(m_threadRenderImage)
    {
        if([m_threadRenderImage isExecuting])
            [m_threadRenderImage cancel];
        
        while ([m_threadRenderImage isExecuting])
        {
            [NSThread sleepForTimeInterval: 0.05];
        }
    }
}

-(void)renderImageInThread
{
    do
    {
        if(m_bCanSynthesizeImage)
        {
            m_bFinishedThread = NO;
            
            do {
                [NSThread sleepForTimeInterval:0.005];
            } while (![m_threadRenderImage isCancelled] && ![self isCanRenderImage] && m_bCanSynthesizeImage);
            
            [self renderImage];
            [m_idDocument refreshTempDocumentFile];
            m_bCanSynthesizeImage = false;
        }
        
        m_bFinishedThread = YES;
        
        [NSThread sleepForTimeInterval:0.05];
        
    } while (![m_threadRenderImage isCancelled]);
}

-(bool)isCanRenderImage
{
    int nLayerCount = [[m_idDocument contents] layerCount];
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
        if (![layer isRenderCompleted:YES])     return false;
    }
    
    return true;
}

-(void)renderImage
{
    if(!m_bCanSynthesizeImage) return;
    if(![m_idDocument contents]) return;
    
    int nSpp = [(PSContent *)[m_idDocument contents] spp];
    int nWidth = [(PSContent *)[m_idDocument contents] width];
    int nHeight = [(PSContent *)[m_idDocument contents] height];
    float fScaleX = [(PSContent *)[m_idDocument contents] xscale];
    float fScaleY = [(PSContent *)[m_idDocument contents] yscale];
    fScaleX = (fScaleX < 0.9999) ? fScaleX : 1.0;
    fScaleY = (fScaleY < 0.9999) ? fScaleY : 1.0;
    fScaleX = 1.0;
    fScaleY = 1.0;
//    nWidth = (float)nWidth*fScaleX;
//    nHeight = (float)nHeight*fScaleY;
    nWidth = ceilf((float)nWidth*fScaleX);
    nHeight = ceilf((float)nHeight*fScaleY);
    NSRect rect = NSMakeRect(0, 0, nWidth, nHeight);
    
    CGColorSpaceRef defaultColorSpace = ((nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, nWidth, nHeight, 8, nSpp * nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    //NSLog(@"1111");
    if(m_bCanSynthesizeImage)
    {
        [m_lockCGlayer lock];
        if(m_cgLayerSynthesizedImage)  { CGLayerRelease(m_cgLayerSynthesizedImage); m_cgLayerSynthesizedImage = nil; }
        
        m_cgLayerSynthesizedImage = CGLayerCreateWithContext(bitmapContext, CGSizeMake(nWidth, nHeight), nil);
        assert(m_cgLayerSynthesizedImage);
        CGContextRef imageLayerRef = CGLayerGetContext(m_cgLayerSynthesizedImage);
        assert(imageLayerRef);
        
        
        RENDER_CONTEXT_INFO contextInfo;
        contextInfo.context = imageLayerRef;
        contextInfo.offset = CGPointMake(0, 0);
        contextInfo.scale = CGSizeMake(fScaleX, fScaleY);
        contextInfo.refreshMode = 2;
        contextInfo.state = NULL;
        [self compositeLayersToContext:contextInfo inRect:NSRectToCGRect(rect) isBitmap:YES];
        
        [m_lockCGlayer unlock];
    }
    //NSLog(@"2222");
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);
    
    if(m_bCanSynthesizeImage)
    {
        [[m_idDocument docView] setNeedsDisplay:YES];
    }
}

- (void)compositeLayersToContext:(RENDER_CONTEXT_INFO)contextInfo inRect:(CGRect)rect isBitmap:(BOOL)isBitmap
{
    int nLayerCount = [[m_idDocument contents] layerCount];
    
    NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    CGContextSaveGState(contextInfo.context);
    // Go through compositing each visible layer
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        if(!m_bCanSynthesizeImage)
        {
            CGContextRestoreGState(contextInfo.context);
            return;
        }
        
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
        if ([layer visible])
        {
            BOOL isHasPreview = NO;
            for (int i = 0; i < [previewLayers count]; i++) {
                if (layer == [previewLayers objectAtIndex:i]) {
                    isHasPreview = YES;
                    break;
                }
            }
            
            if(!m_bCanSynthesizeImage)
            {
                CGContextRestoreGState(contextInfo.context);
                return;
            }
            
            if (isHasPreview) {
                [(AbstractTool*)[[m_idDocument tools] currentTool] drawLayerToolPreview:contextInfo layerid:layer];
            }else{
                [layer renderToContext:contextInfo];
                //[layer render:context viewRect:rect];
                //NSLog(@"drawContext: %f",[NSDate timeIntervalSinceReferenceDate] - begin);
            }            
        }
    }
    CGContextRestoreGState(contextInfo.context);
}


-(void)beginSynthesizeImageRender
{
    m_bCanSynthesizeImage = YES;
}

-(void)stopSynthesizeImageRender
{
    m_bCanSynthesizeImage = false;
}

-(void)waitForStopSynthesizeImageRender
{
    m_bCanSynthesizeImage = false;
    
    if([m_threadRenderImage isExecuting])
    {
        NSTimeInterval beginTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval delTime;
        do
        {
            [NSThread sleepForTimeInterval:0.00000005];
            delTime = [NSDate timeIntervalSinceReferenceDate] - beginTime;
        }while (!m_bFinishedThread && (delTime < 8.0));
    }
}

-(void)resetSynthesizedImageCGlayer
{
    [self waitForStopSynthesizeImageRender];
    
    [m_lockCGlayer lock];
    if(m_cgLayerSynthesizedImage) {CGLayerRelease(m_cgLayerSynthesizedImage); m_cgLayerSynthesizedImage = nil;}
    [m_lockCGlayer unlock];

    //[self beginSynthesizeImageRender];

    SEL sel = @selector(beginSynthesizeImageRenderDelayInThread);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: sel object: nil];
    //[self performSelector: sel withObject: nil afterDelay: 0.3];
    [self performSelector:@selector(beginSynthesizeImageRenderDelayInThread) withObject:nil afterDelay:0.3 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];

}

-(void)beginSynthesizeImageRenderDelayInThread
{
    [self beginSynthesizeImageRender];
}

-(CGLayerRef)getSynthesizedImageCGlayer:(bool *)bWantUnlock
{
    *bWantUnlock = false;
    
    [m_lockCGlayer lock];
    *bWantUnlock = true;
    
 //   assert(m_cgLayerSynthesizedImage);
    return m_cgLayerSynthesizedImage;  // wzq
    
    if([m_lockCGlayer tryLock])
    {
        *bWantUnlock = true;
        
        return m_cgLayerSynthesizedImage;
    }
    else
        return nil;
}

-(void)unlockSynthesizedImageCGlayer
{
    [m_lockCGlayer unlock];
}

-(void)shutdown
{
    [self exitRenderImageThread];
}

@end
