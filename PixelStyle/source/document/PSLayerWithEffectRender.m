//
//  PSLayerWithEffectRender.m
//  PixelStyle
//
//  Created by lchzh on 19/11/15.
//
//

#import "PSLayerWithEffectRender.h"
#import "PSLayerEffect.h"
#import "PSMemoryManager.h"
#import "PSLayer.h"
#import "PSDocument.h"

#import "PSSmartFilterManager.h"

@implementation PSLayerWithEffectRender

#define EXPAND_RADIUS 200
- (id)initWithRenderInfo:(RENDER_INFO)renderInfo bfullslice:(BOOL)bFullSlice
{
    self = [super init];
    m_idRenderSlice = [[PSRenderSlice alloc] initWithRenderInfo:renderInfo bfullslice:bFullSlice];
    
    
    m_toRenderInfo = renderInfo;
    m_dataDirtyRect = CGRectNull;
    m_renderIsReady = NO;
    
    m_lockRenderInfo = [[NSRecursiveLock alloc] init];
    
    m_bCanBeginRender = YES;
    
    [self performSelector:@selector(startRenderThread) withObject:NULL afterDelay:0.01];
    
    return self;
}

-(void)exitRenderThread
{
    if(m_renderThread)
    {
        if([m_renderThread isExecuting])
        {
            [m_renderThread cancel];
            
            while ([m_renderThread isExecuting])
            {
                [NSThread sleepForTimeInterval: 0.05];
            }
        }
        m_renderThread = nil;
    }
}

-(void)dealloc
{
    if(m_renderThread)
    {
        [self exitRenderThread];
        
        [m_renderThread release];
        m_renderThread = nil;
    }
    
    if(m_idRenderSlice)   {[m_idRenderSlice release]; m_idRenderSlice = nil;}
    if(m_lockRenderInfo) {[m_lockRenderInfo release]; m_lockRenderInfo = nil;}
    
    
    
    [super dealloc];
}

- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager
{
    m_smartFilterManager = smartFilterManager;
    [m_idRenderSlice setSmartFilterManager:smartFilterManager];
}

- (void)startRenderThread
{
    m_renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderThreadSelector) object:NULL];
    
    [m_renderThread setStackSize: 2*1024*1024];
    [m_renderThread start];
}

- (void)reRenderWithInfo:(RENDER_INFO)renderInfo
{
    return;
    [m_lockRenderInfo lock];
    m_toRenderInfo = renderInfo;
    [m_idRenderSlice reRenderToSliceWithInfo:renderInfo];
    
    [m_lockRenderInfo unlock];
}

- (void)setCanBeginRender:(BOOL)canBegin
{
    m_bCanBeginRender = canBegin;
    if (!m_bCanBeginRender)
    {
        [m_smartFilterManager cancleCurrentFullProcess];
    }
}

- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew
{
    [m_lockRenderInfo lock];
    
    m_pointOffsetChangedOnly = pointOffsetNew;
    m_toRenderInfo.pointImageDataOffset = pointOffsetNew;
    m_renderIsReady = NO;

    [m_lockRenderInfo unlock];
}

//dataDirtyRect current layer coordinate
- (void)renderDirtyWithInfo:(RENDER_INFO)renderInfo dirtyRect:(CGRect) dataDirtyRect
{
//    NSLog(@"renderDirtyWithInfo2 %@,%@",NSStringFromRect(dataDirtyRect),NSStringFromRect(m_dataDirtyRect));
    if (dataDirtyRect.size.width < 0.5 || dataDirtyRect.size.height < 0.5)
    {
        return;
    }
    [m_lockRenderInfo lock];
    m_toRenderInfo = renderInfo;
    if (m_dataDirtyRect.size.width < 0.5 || m_dataDirtyRect.size.height < 0.5)
    {
        m_dataDirtyRect = CGRectNull;
    }
    m_dataDirtyRect = CGRectUnion(m_dataDirtyRect, dataDirtyRect);
    
    m_renderIsReady = NO;
    //NSLog(@"renderDirtyWithInfo %@ %@ %d %d", NSStringFromRect(m_dataDirtyRect), NSStringFromRect(dataDirtyRect),[m_idRenderSlice isFullSlice], m_bCanBeginRender);
    [m_lockRenderInfo unlock];
}


- (BOOL)isRenderedToSlice
{
    [m_lockRenderInfo lock];
    BOOL bIsRenderdToSlide = NO;
    
    if ([m_idRenderSlice isFullSlice])
    {
        bIsRenderdToSlide = m_renderIsReady && [m_idRenderSlice isRenderedForInfo:m_renderingInfo radiusEdge:EXPAND_RADIUS ];
        //NSLog(@"11%@",NSStringFromRect(m_dataDirtyRect));
    }
    else
    {
        bIsRenderdToSlide = CGRectIsNull(m_dataDirtyRect) && m_renderIsReady && [m_idRenderSlice isRenderedForInfo:m_renderingInfo radiusEdge:EXPAND_RADIUS];
    }
    
    //BOOL bIsRenderdToSlide = NO;//CGRectIsNull(m_dataDirtyRect) && [m_idRenderSlice isRenderedForInfo:m_renderingInfo];
    [m_lockRenderInfo unlock];
    
    return bIsRenderdToSlide;
}

- (BOOL)isRenderedToSlice:(RENDER_CONTEXT_INFO)contextInfo
{
    [m_lockRenderInfo lock];
    BOOL bIsRenderdToSlide = NO;
    
    if ([m_idRenderSlice isFullSlice])
    {
        bIsRenderdToSlide = m_renderIsReady && [m_idRenderSlice isRenderedForInfo:m_renderingInfo radiusEdge:EXPAND_RADIUS];
    }
    else
    {
        
        if (!CGRectEqualToRect(m_renderingInfo.rectSliceInCanvas, contextInfo.rectSliceInCanvas) || !CGSizeEqualToSize(m_renderingInfo.sizeScale, contextInfo.sizeScale) || !CGPointEqualToPoint(m_renderingInfo.pointImageDataOffset, contextInfo.pointImageDataOffset))
        {
            [m_lockRenderInfo unlock];
            return NO;
        }
        bIsRenderdToSlide = CGRectIsNull(m_dataDirtyRect) && m_renderIsReady && [m_idRenderSlice isRenderedForInfo:m_renderingInfo radiusEdge:EXPAND_RADIUS];
    }
    
    //BOOL bIsRenderdToSlide = NO;//CGRectIsNull(m_dataDirtyRect) && [m_idRenderSlice isRenderedForInfo:m_renderingInfo];
    [m_lockRenderInfo unlock];
    
    return bIsRenderdToSlide;
}

- (void)setDelegateRenderNotify:(id)delegate
{
    m_delegateToRender = delegate;
}

- (void)reRenderToRTSlice:(RENDER_CONTEXT_INFO)contextInfo
{
    assert(false);
    if (![m_idRenderSlice isFullSlice])
    {
        [m_lockRenderInfo lock];
        
        if (!CGRectEqualToRect(m_renderingInfo.rectSliceInCanvas, contextInfo.rectSliceInCanvas) || !CGSizeEqualToSize(m_renderingInfo.sizeScale, contextInfo.sizeScale) || !CGPointEqualToPoint(m_renderingInfo.pointImageDataOffset, contextInfo.pointImageDataOffset))
        {
            
            m_toRenderInfo.rectSliceInCanvas = contextInfo.rectSliceInCanvas;
            m_toRenderInfo.sizeScale = contextInfo.sizeScale;
            m_toRenderInfo.pointImageDataOffset = contextInfo.pointImageDataOffset;
            CGRect rectDirty = contextInfo.rectSliceInCanvas;
            rectDirty.origin.x -= m_toRenderInfo.pointImageDataOffset.x;
            rectDirty.origin.y -= m_toRenderInfo.pointImageDataOffset.y;
            [m_lockRenderInfo unlock];
            //NSLog(@"renderToContext");
            [self renderDirtyWithInfo:m_toRenderInfo dirtyRect:rectDirty];
            
            return;
        }
        [m_lockRenderInfo unlock];
    }
}

- (void)renderOldToContext:(int)nMode alpha:(CGFloat)fAlpha
{
  //  [m_idRenderSlice renderOldToContext:nMode alpha:fAlpha];
}


- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha
{
    if (![m_idRenderSlice isFullSlice])
    {
        [m_lockRenderInfo lock];
        
        
        if (!CGRectEqualToRect(m_toRenderInfo.rectSliceInCanvas, contextInfo.rectSliceInCanvas) || !CGSizeEqualToSize(m_toRenderInfo.sizeScale, contextInfo.sizeScale) || !CGPointEqualToPoint(m_toRenderInfo.pointImageDataOffset, contextInfo.pointImageDataOffset))
        {
            //系统触发，如放大，缩小，滚屏
            [m_idRenderSlice renderToContext:contextInfo mode:nMode alpha:fAlpha radiusEdge:EXPAND_RADIUS];
            
            m_toRenderInfo.rectSliceInCanvas    = contextInfo.rectSliceInCanvas;
            m_toRenderInfo.sizeScale            = contextInfo.sizeScale;
            m_toRenderInfo.pointImageDataOffset = contextInfo.pointImageDataOffset;
            m_toRenderInfo.flagModifiedType     = VIEWSCALE_MODIFIED_ONLY;
            
            CGRect rectDirty = contextInfo.rectSliceInCanvas;
            
            rectDirty.origin.x -= m_toRenderInfo.pointImageDataOffset.x;
            rectDirty.origin.y -= m_toRenderInfo.pointImageDataOffset.y;
            
           /* IMAGE_DATA data = [m_toRenderInfo.dataImage lockDataForRead];
            CGRect rectDirty;
            rectDirty.origin = m_toRenderInfo.pointImageDataOffset;
            rectDirty.size.width  = data.nWidth;
            rectDirty.size.height = data.nHeight;
            
            [m_toRenderInfo.dataImage unLockDataForRead];
            */
            [m_lockRenderInfo unlock];
            
          //  NSLog(@"renderToContext no renderDirtyWithInfo// ???????????");
            [self renderDirtyWithInfo:m_toRenderInfo dirtyRect:rectDirty]; // ???????????
            
            return;
        }
        
        [m_lockRenderInfo unlock];
    }
    
    [m_idRenderSlice renderToContext:contextInfo mode:nMode alpha:fAlpha radiusEdge:EXPAND_RADIUS];
}


- (int)copyToCache:(PSSecureImageData   *)cacheImage from:(PSSecureImageData   *)dataImage rect: (CGRect)dataDirtyRect info:(IMAGE_DATA *)lastImageInfo flagModified:(enumDATAModifiedType)flagModified
{
    IMAGE_DATA currentImageInfo = [dataImage lockDataForRead];
 
     if(!currentImageInfo.nWidth || !currentImageInfo.nHeight)
    {
        [dataImage unLockDataForRead]; return -1;
    }

    if(memcmp(lastImageInfo, &currentImageInfo, sizeof(IMAGE_DATA)) != 0)
    {
        [cacheImage copyFromAndExpand:dataImage expand:EXPAND_RADIUS];
        
        *lastImageInfo = currentImageInfo;
    }
    else if(flagModified == IMAGE_FILTER_MODIFIED ||  flagModified == IMAGE_FILTER_FULL_MODIFIED||  flagModified == IMAGE_MODIFIED_ONLY)
    {
        dataDirtyRect = CGRectIntersection(dataDirtyRect, CGRectMake(0, 0, currentImageInfo.nWidth, currentImageInfo.nHeight));
        
        if(CGRectIsNull(dataDirtyRect) || dataDirtyRect.size.width < 1.0 || dataDirtyRect.size.height < 1.0)
        {
            [dataImage unLockDataForRead]; return -2;
        }
        
        IMAGE_DATA cacheImageInfo = [cacheImage lockDataForWrite];
        
        NSCAssert((cacheImageInfo.nWidth == lastImageInfo->nWidth + EXPAND_RADIUS*2)
                  && (cacheImageInfo.nHeight == lastImageInfo->nHeight + EXPAND_RADIUS*2), @"");

        for(int y = 0; y < dataDirtyRect.size.height; y++ )
        {
            int nOffset = (((y + EXPAND_RADIUS) + (int)dataDirtyRect.origin.y)*cacheImageInfo.nWidth + EXPAND_RADIUS + (int)dataDirtyRect.origin.x) * cacheImageInfo.nSpp;
            int nOffset1 = (((y ) + (int)dataDirtyRect.origin.y)*currentImageInfo.nWidth +  (int)dataDirtyRect.origin.x) * currentImageInfo.nSpp;
            
            memcpy(cacheImageInfo.pBuffer + nOffset, currentImageInfo.pBuffer + nOffset1, dataDirtyRect.size.width * cacheImageInfo.nSpp);
        }
        
        [cacheImage unLockDataForWrite];
    }
    
    [dataImage unLockDataForRead];
    
    return 0;
}

#define CGPOINT_INVALID CGPointMake(1000000.0, 1000000.0)
- (void)renderThreadSelector
{
    //[NSThread setThreadPriority:0.0];
    PSSecureImageData   *cacheImage = [[PSSecureImageData alloc] initData:0 height:0 spp:4 alphaPremultiplied:false];
    IMAGE_DATA  lastImageInfo;
    
    memset(&lastImageInfo, 0, sizeof(lastImageInfo));
    
    while(![[NSThread currentThread] isCancelled])
    {
        //NSLog(@"renderThreadSelector %@",[NSThread currentThread]);
        @autoreleasepool
        {
            [m_lockRenderInfo lock];
            
            if ((CGRectIsNull(m_dataDirtyRect) && CGPointEqualToPoint(m_pointOffsetChangedOnly, CGPOINT_INVALID)) ||!m_bCanBeginRender)
            {
                [m_lockRenderInfo unlock];
                [NSThread sleepForTimeInterval:0.05];
                //NSLog(@"ddddddd %@ %d", NSStringFromRect(m_dataDirtyRect), m_bCanBeginRender);
                continue;
            }
            else
            {
                
                [m_lockRenderInfo unlock];
            }
            
            m_renderIsReady = NO;
            
            [m_lockRenderInfo lock];
            
            if(CGPointEqualToPoint(m_pointOffsetChangedOnly, CGPOINT_INVALID) == NO)
            {
                [m_idRenderSlice renderDirtyWithOffsetChangedOnly:m_pointOffsetChangedOnly radiusEdge:EXPAND_RADIUS];
                m_renderIsReady = YES;
                m_pointOffsetChangedOnly = CGPOINT_INVALID;
                m_renderingInfo.pointImageDataOffset = m_pointOffsetChangedOnly;
                [m_lockRenderInfo unlock];
                
              //  [m_delegateToRender displayRenderedInfo:resultRect];
                
                continue;
            }
            
            CGRect dataDirtyRect = m_dataDirtyRect;
            RENDER_INFO renderInfo = m_toRenderInfo;
            m_dataDirtyRect = CGRectNull;
            
            [self copyToCache:cacheImage from:renderInfo.dataImage rect: dataDirtyRect info:&lastImageInfo flagModified:renderInfo.flagModifiedType];
            renderInfo.dataImage = cacheImage;
            
            m_renderingInfo = renderInfo;
            
            [m_lockRenderInfo unlock];
            
            
            if (!CGRectIsNull(dataDirtyRect) && dataDirtyRect.size.width > 0 && dataDirtyRect.size.height > 0)
            {
                //NSLog(@"displayRenderedInfo1 %@",NSStringFromRect(dataDirtyRect));
                CGRect resultRect = [m_idRenderSlice renderToSliceDirtyWithInfo:renderInfo rectDirty:dataDirtyRect radiusEdge:EXPAND_RADIUS ];
                if (CGRectIsNull(resultRect))
                {
                    [m_lockRenderInfo lock];
                    m_dataDirtyRect = CGRectUnion(m_dataDirtyRect, dataDirtyRect);
                    [m_lockRenderInfo unlock];
                }
                else
                {
                    m_renderIsReady = YES;
                    [m_delegateToRender displayRenderedInfo:resultRect];
                    
                }
                //NSLog(@"displayRenderedInfo2 %@,%@",NSStringFromRect(dataDirtyRect),NSStringFromRect(resultRect));
            }
            else
            {
                m_renderIsReady = YES;
            }
            
          
            [NSThread sleepForTimeInterval:0.005];
        }
    }
    
    [cacheImage release];
    //free(pCacheBuf);
}


@end


@implementation PSRenderEffect

- (id)initWithRenderInfo:(RENDER_INFO)renderInfo 
{
    self = [super init];
    m_renderRT = [[PSLayerWithEffectRender alloc] initWithRenderInfo:renderInfo bfullslice:NO];

    m_renderFull = [[PSLayerWithEffectRender alloc] initWithRenderInfo:renderInfo bfullslice:YES];

    
//    m_renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderThreadSelector) object:NULL];
//    [m_renderThread start];
//    [NSThread detachNewThreadSelector:@selector(judgePreviewRenderIsCompleted) toTarget:self withObject:NULL];
    
    return self;
}



- (void)reRenderWithInfo:(RENDER_INFO)renderInfo
{
    [m_renderRT reRenderWithInfo:renderInfo];
    [m_renderFull reRenderWithInfo:renderInfo];
    
}

-(void)dealloc
{
    if(m_renderRT)
    {
        [m_renderRT exitRenderThread];
        [m_renderRT release];
        m_renderRT = nil;
    }
    if(m_renderFull)
    {
        [m_renderFull exitRenderThread];
        [m_renderFull release];
        m_renderFull = nil;
    }
    
    [super dealloc];
}

- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager
{
    [m_renderFull setSmartFilterManager:smartFilterManager];
    [m_renderRT setSmartFilterManager:smartFilterManager];
    
}

- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew
{
    [m_renderFull renderDirtyWithOffsetChangedOnly:pointOffsetNew];
    [m_renderRT renderDirtyWithOffsetChangedOnly:pointOffsetNew];
}

- (void)renderDirtyWithInfo:(RENDER_INFO)renderInfo dirtyRect:(NSRect) dataDirtyRect refreshType:(REFRESH_TYPE)type
{
    switch (type)
    {
        case REFRESH_TYPE_DEFAULT:
            [m_renderRT setCanBeginRender:YES];
            [m_renderRT renderDirtyWithInfo:renderInfo dirtyRect:dataDirtyRect];  //wzq
            [m_renderFull renderDirtyWithInfo:renderInfo dirtyRect:dataDirtyRect];
            break;
            
        case REFRESH_TYPE_PREVIEW:
            [m_renderRT setCanBeginRender:YES];
            [m_renderRT renderDirtyWithInfo:renderInfo dirtyRect:dataDirtyRect];
            break;
            
        case REFRESH_TYPE_FULL:
            [m_renderFull renderDirtyWithInfo:renderInfo dirtyRect:dataDirtyRect];
            break;
        case REFRESH_TYPE_OFFSET:
            [m_renderFull renderDirtyWithOffsetChangedOnly:renderInfo.pointImageDataOffset];
            [m_renderRT renderDirtyWithInfo:renderInfo dirtyRect:dataDirtyRect];
        default:
            break;
    }
    
}

- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha
{
    switch (contextInfo.refreshMode)
    {
        case 0:
        {
            NSLog(@"if ([m_renderFull isRenderedToSlice]) to test");
        /*    if (![m_renderFull isRenderedToSlice])
            {
                NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
                while (![m_renderFull isRenderedToSlice])
                {
                    [NSThread sleepForTimeInterval:0.01];

                    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate] - begin;
                    if(time > 0.15) break;;
                }
            }
         */
            if ([m_renderFull isRenderedToSlice])
            {
                [m_renderFull renderToContext:contextInfo mode:nMode alpha:fAlpha];
            }
            else
            {
                [m_renderRT renderToContext:contextInfo mode:nMode alpha:fAlpha];
            }
        }
            break;
            
        case 1: //preview
        {
            //[m_renderRT renderToContext:contextInfo mode:nMode alpha:fAlpha];
            if ([m_renderRT isRenderedToSlice:contextInfo] && [m_renderFull isRenderedToSlice])
            {
                [m_renderRT renderToContext:contextInfo mode:nMode alpha:fAlpha];
                //NSLog(@"gggg3");
            }
            else if(![m_renderRT isRenderedToSlice:contextInfo] && [m_renderFull isRenderedToSlice])
            {
             //   NSLog(@"preview  renderToContext no reRenderToRTSlice// ???????????");
                [m_renderFull renderToContext:contextInfo mode:nMode alpha:fAlpha]; // wzq 0923
             //   [m_renderRT reRenderToRTSlice:contextInfo];  //影响缩放速度
              //  [m_renderRT renderToContext:contextInfo mode:nMode alpha:fAlpha];
                //NSLog(@"gggg1");
            }
            else
            {
                if(m_renderRT)
                    [m_renderRT renderToContext:contextInfo mode:nMode alpha:fAlpha];
                else
                    [m_renderFull renderToContext:contextInfo mode:nMode alpha:fAlpha]; //test
                //NSLog(@"gggg2");
            }
        }
            break;
            
        case 2: //full
        {
            NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
            while (![m_renderFull isRenderedToSlice] && contextInfo.state != NULL)
            {
                [NSThread sleepForTimeInterval:0.01];
                if (*contextInfo.state == 1)
                {
                    return;
                }
                NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate] - begin;
                assert(time < 5.0);
            }
            
            [m_renderFull renderToContext:contextInfo mode:nMode alpha:fAlpha];
        }
            break;
            
        default:
            break;
    }
    

}



- (void)setDelegateRenderNotify:(id)delegate
{
    [m_renderRT setDelegateRenderNotify:delegate];
    [m_renderFull setDelegateRenderNotify:delegate];
}

- (void)setFullRenderState:(BOOL)canBegin
{
//    NSLog(@"setFullRenderState emprty to test");
 //   return;
    [m_renderFull setCanBeginRender:canBegin];
}

- (BOOL)isRenderCompleted:(BOOL)isFull
{
    if (isFull)
    {
        return [m_renderFull isRenderedToSlice];
    }
    else
    {
        return [m_renderRT isRenderedToSlice];
    }
    
    return YES;
}

-(void)removeCache
{
}

-(void)exitRenderThread
{
    [m_renderRT exitRenderThread];
    [m_renderFull exitRenderThread];
}

@end

