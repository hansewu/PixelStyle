//
//  PSRenderSlice.m
//  PixelStyle
//
//  Created by wzq on 15/11/21.
//
//

#import "PSRenderSlice.h"
#import "PSSecureImageData.h"
#import "Rects.h"

#import "PSSmartFilterManager.h"

@implementation PSRenderSlice

- (id)initWithRenderInfo:(RENDER_INFO)renderInfo bfullslice:(BOOL)bFullSlice
{
    self = [super init];
    m_bFullSlice = bFullSlice;
    
    m_lockRenderInfoCGLayer = [[NSRecursiveLock alloc] init];
    
    [m_lockRenderInfoCGLayer lock];
    m_renderInfoToCGLayer.renderInfo.dataImage              = nil;
    m_renderInfoToCGLayer.renderInfo.pointImageDataOffset   = CGPointMake(0, 0);
    m_renderInfoToCGLayer.renderInfo.rectSliceInCanvas      = CGRectNull;
    m_renderInfoToCGLayer.renderInfo.sizeScale              = CGSizeZero;
    
    m_renderInfoToCGLayer.cgLayerSlice = nil;
  //  m_sizeCGLayerScale = CGSizeMake(1.0, 1.0);
    [m_lockRenderInfoCGLayer unlock];
    
  //  [self reRenderToSliceWithInfo:renderInfo];
    
    m_smartFilterManager = nil;
    
    return self;
    
}

- (void)dealloc
{
    [self destroyCGLayer];
    
    [m_lockRenderInfoCGLayer release];
    
    [super dealloc];
}

- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager
{
    m_smartFilterManager = smartFilterManager;
}

//clear (, maybe recreate m_cgLayer) and render to slice
- (void)reRenderToSliceWithInfo:(RENDER_INFO)renderInfo
{
    [m_lockRenderInfoCGLayer lock];
    assert(false);
//    m_infoForCGLayer = renderInfo;
    [m_lockRenderInfoCGLayer unlock];
}


- (CGLayerRef)reCreateCGLayer:(RENDER_INFO)renderInfo
{
    CGLayerRef cgLayer = nil;
    
    if (m_bFullSlice)
    {
     //   [m_lockRenderInfoCGLayer lock];
        IMAGE_DATA imageData = [renderInfo.dataImage lockDataForRead];
        int height = imageData.nHeight;
        int width = imageData.nWidth;
        [renderInfo.dataImage unLockDataForRead];
        
        if (width > 0.5 && height > 0.5)
        {
   /*         if (m_cgLayerSlice) {
                CGLayerRelease(m_cgLayerSlice);
                m_cgLayerSlice = NULL;
            }*/
            cgLayer = [self createCGLayerWidth:width height:height spp:4];
        }
     //   [m_lockRenderInfoCGLayer unlock];
    }
    else
    {
    //    [m_lockRenderInfoCGLayer lock];
        CGRect cglayerRect = [self getCGLayerRectWithRenderInfo:renderInfo];
        IntRect cglayerIntRect = NSRectMakeIntRect(cglayerRect);
        
        if (cglayerIntRect.size.width > 0.5 && cglayerIntRect.size.height > 0.5)
        {
      /*      if (m_cgLayerSlice)
            {
                CGLayerRelease(m_cgLayerSlice);
                m_cgLayerSlice = NULL;
            } */
            cgLayer = [self createCGLayerWidth:cglayerIntRect.size.width height:cglayerIntRect.size.height spp:4]; //[renderInfo.dataImage getSPP]
        }
        else
        {
        /*
            if (m_cgLayerSlice)
            {
                CGLayerRelease(m_cgLayerSlice);
                m_cgLayerSlice = NULL;
//                assert(false);
            }
         */
        }
     //   [m_lockRenderInfoCGLayer unlock];
        
    }
    
    return cgLayer;
}


- (BOOL)judgeNeedRefreshAllWithInfo:(RENDER_INFO)renderInfo oldInfo:(RENDER_INFO)renderInfoOld
{
    if (!CGRectEqualToRect(renderInfo.rectSliceInCanvas, renderInfoOld.rectSliceInCanvas))
    {
        return YES;
    }
    
    if (!CGSizeEqualToSize(renderInfo.sizeScale, renderInfoOld.sizeScale))
    {
        return YES;
    }
    return NO;
}

- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew   radiusEdge:(int)nRadiusEdge
{
    [m_lockRenderInfoCGLayer lock];
    
    m_renderInfoToCGLayer.renderInfo.pointImageDataOffset = CGPointMake(pointOffsetNew.x - (CGFloat)nRadiusEdge, pointOffsetNew.y - (CGFloat)nRadiusEdge);
    
    [m_lockRenderInfoCGLayer unlock];
}

- (CGRect)renderToSliceDirtyWithInfo:(RENDER_INFO)renderInfo  rectDirty:(CGRect)rectDirty  radiusEdge:(int)nRadiusEdge
{
    renderInfo.pointImageDataOffset.x -= nRadiusEdge;
    renderInfo.pointImageDataOffset.y -= nRadiusEdge;
    rectDirty.origin.x += nRadiusEdge;
    rectDirty.origin.y += nRadiusEdge;
    
    CGRect displayRect = rectDirty;
    
 //   [m_lockRenderInfoCGLayer lock];
    BOOL isNeedRecreate = [self isNeedRecreateCGLayer:renderInfo isFullSlice:m_bFullSlice];
//    BOOL needRefreshAll = [self judgeNeedRefreshAllWithInfo:renderInfo oldInfo:m_infoForCGLayer];
    
  //  m_infoForCGLayer = renderInfo;
    CGLayerRef cgLayerNew = nil;
    
    if (!m_bFullSlice)
    {
        if (isNeedRecreate)
        {
            cgLayerNew = [self reCreateCGLayer:renderInfo];
            
            rectDirty           = renderInfo.rectSliceInCanvas;
            rectDirty.origin.x -= renderInfo.pointImageDataOffset.x;
            rectDirty.origin.y -= renderInfo.pointImageDataOffset.y;
          //  displayRect = [self renderToSliceDirtyWithInfo:m_infoForCGLayer rectDirty:rectDirty];
            //     [m_lockRenderInfoCGLayer unlock];
            
        }

   //     if (!isNeedRecreate)
        {
         /*   if (!m_cgLayerSlice)
            {
           //     [m_lockRenderInfoCGLayer unlock];
                return displayRect;
            }
            */
            CGRect canvasRect = renderInfo.rectSliceInCanvas;
            canvasRect.origin.x -= renderInfo.pointImageDataOffset.x;
            canvasRect.origin.y -= renderInfo.pointImageDataOffset.y;
            
            CGRect visibleRect  = CGRectIntersection(rectDirty, canvasRect);
            if (visibleRect.size.width <= 0.5 || visibleRect.size.height <= 0.5)
            {
               // [m_lockRenderInfoCGLayer unlock];
                if(cgLayerNew)  CGLayerRelease(cgLayerNew);
                
                displayRect.origin.x -= nRadiusEdge;
                displayRect.origin.y -= nRadiusEdge;
                return displayRect;
            }
            
           // CGRect visibleRect  = rectDirty;
            
            INPUT_DATA_INFO inputDataInfo;
            
            memset(&inputDataInfo, 0, sizeof(inputDataInfo));
            inputDataInfo.dirtyRect = visibleRect;
            inputDataInfo.mask = nil;
            inputDataInfo.precision = 0;
            inputDataInfo.sizeScale = renderInfo.sizeScale;
            inputDataInfo.dataImage = renderInfo.dataImage;
            
         //   [m_lockRenderInfoCGLayer unlock];
            PSSmartFilterManager *filters = [m_smartFilterManager customCopy];
            OUTPUT_DATA_INFO outputDataInfo = [filters getFilteredDataForSrcData:inputDataInfo];
            [filters release];
            
         //   [m_lockRenderInfoCGLayer lock];
            
            IMAGE_DATA imageData = [inputDataInfo.dataImage lockDataForRead];
            outputDataInfo.bAlphaPremultiplied = imageData.bAlphaPremultiplied;
            [inputDataInfo.dataImage unLockDataForRead];
            
            if (outputDataInfo.state)
            {
            //    [m_lockRenderInfoCGLayer unlock];
                if(cgLayerNew)  CGLayerRelease(cgLayerNew);
                return CGRectNull;
            }
            
            unsigned char *updateData = outputDataInfo.pBuffer;
            CGRect bufferRect = outputDataInfo.bufferRect;
            
            CGImageRef cgImage = [self makeImageRefFromData:updateData width:bufferRect.size.width height:bufferRect.size.height spp:outputDataInfo.nSpp alphaPremultiplied:outputDataInfo.bAlphaPremultiplied];
            
             //从bufferrect 转成 1:1 visiblerect
            visibleRect.origin.x    = bufferRect.origin.x / outputDataInfo.sizeScale.width;
            visibleRect.origin.y    = bufferRect.origin.y / outputDataInfo.sizeScale.height;
            visibleRect.size.width  = bufferRect.size.width / outputDataInfo.sizeScale.width;
            visibleRect.size.height = bufferRect.size.height / outputDataInfo.sizeScale.height;
            
            displayRect = visibleRect;
            
            CGRect shadowRect = [self getDisplayShadowRect:rectDirty];
            
            shadowRect = CGRectIntersection(shadowRect, CGRectMake(0, 0, imageData.nWidth, imageData.nHeight));
            displayRect = CGRectUnion(displayRect, shadowRect);
            
            CGRect drawRect = visibleRect;
            
            CGRect cglayerRect = [self getCGLayerRectWithRenderInfo:renderInfo];
            
            //层的rect转成对应1比1画布的rect
            drawRect.origin.x += renderInfo.pointImageDataOffset.x;
            drawRect.origin.y += renderInfo.pointImageDataOffset.y;
            
            //1：1画布rect转成缩放后整个view的rect
            
            float xCGLayerScale = renderInfo.sizeScale.width;
            float yCGLayerScale = renderInfo.sizeScale.height;
            
            xCGLayerScale = MIN(1.0, xCGLayerScale);
            yCGLayerScale = MIN(1.0, yCGLayerScale);
            
            drawRect.origin.x *= xCGLayerScale;
            drawRect.origin.y *= yCGLayerScale;
            drawRect.size.width *= xCGLayerScale;
            drawRect.size.height *= yCGLayerScale;
            
            //整个view的rect再转到当前层cglayer的rect
            drawRect.origin.x -= cglayerRect.origin.x;
            drawRect.origin.y -= cglayerRect.origin.y;
            
            BOOL interpolate = YES;
            if (drawRect.size.width / bufferRect.size.width > 5.9 || drawRect.size.height / bufferRect.size.height > 5.9)
            {
                interpolate = NO;
            }
            
            [m_lockRenderInfoCGLayer lock];
            
            if(!cgLayerNew)  cgLayerNew = m_renderInfoToCGLayer.cgLayerSlice;
            
            CGContextRef context = CGLayerGetContext(cgLayerNew);
            if(renderInfo.flagModifiedType == IMAGE_FILTER_FULL_MODIFIED || renderInfo.flagModifiedType == EFFECT_MODIFIED_ONLY || renderInfo.flagModifiedType == EFFECT_DISABLE_ONLY ||
               renderInfo.flagModifiedType == OFFSET_MODIFIED_ONLY)
            {
                CGSize sizeLayer = CGLayerGetSize(cgLayerNew);
                CGContextClearRect(context, CGRectMake(0, 0, sizeLayer.width, sizeLayer.height));
            }
            [self drawImageToCGContext:context image:cgImage rect:drawRect  interpolate:interpolate];
            
            if(cgLayerNew != m_renderInfoToCGLayer.cgLayerSlice)
                CGLayerRelease(m_renderInfoToCGLayer.cgLayerSlice);

            m_renderInfoToCGLayer.renderInfo    = renderInfo;
            m_renderInfoToCGLayer.cgLayerSlice  = cgLayerNew;
            
            [m_lockRenderInfoCGLayer unlock];
            
            free(updateData);
            CGImageRelease(cgImage);

        }
  /*      else
        {
            
            [self reCreateCGLayer];
          
            rectDirty = renderInfo.rectSliceInCanvas;
            rectDirty.origin.x -= renderInfo.pointImageDataOffset.x;
            rectDirty.origin.y -= renderInfo.pointImageDataOffset.y;
            displayRect = [self renderToSliceDirtyWithInfo:m_infoForCGLayer rectDirty:rectDirty];
       //     [m_lockRenderInfoCGLayer unlock];
            
        }
*/
    }
    else
    {
        if(isNeedRecreate)
        {
            cgLayerNew = [self reCreateCGLayer:renderInfo];
            
            IMAGE_DATA imageData = [renderInfo.dataImage lockDataForRead];
            int height          = imageData.nHeight;
            int width           = imageData.nWidth;
            [renderInfo.dataImage unLockDataForRead];
            
            rectDirty = CGRectMake(0, 0, width, height);
           // displayRect = [self renderToSliceDirtyWithInfo:m_infoForCGLayer rectDirty:rectDirty];
        }
  //      if (!isNeedRecreate)
        {
       /*     if (!m_cgLayerSlice)
            {
                [m_lockRenderInfoCGLayer unlock];
                return displayRect;
            }
           */
            
            INPUT_DATA_INFO inputDataInfo;
            
            memset(&inputDataInfo, 0, sizeof(inputDataInfo));
            inputDataInfo.dirtyRect = rectDirty;
            inputDataInfo.mask      = nil;
            inputDataInfo.precision = 1; // wzq test
            inputDataInfo.sizeScale = renderInfo.sizeScale;
            inputDataInfo.dataImage = renderInfo.dataImage;
            
      //      [m_lockRenderInfoCGLayer unlock];
            PSSmartFilterManager *filters = [m_smartFilterManager customCopy];
            OUTPUT_DATA_INFO outputDataInfo = [filters getFilteredDataForSrcData:inputDataInfo];
            [filters release];
     //       [m_lockRenderInfoCGLayer lock];
            
            IMAGE_DATA imageData = [inputDataInfo.dataImage lockDataForRead];
            outputDataInfo.bAlphaPremultiplied = imageData.bAlphaPremultiplied;
            [inputDataInfo.dataImage unLockDataForRead];
            
            if (outputDataInfo.state)
            {
               // [m_lockRenderInfoCGLayer unlock];
                return CGRectNull;
            }
            
            unsigned char *updateData = outputDataInfo.pBuffer;
            CGRect bufferRect = outputDataInfo.bufferRect;
            CGImageRef cgImage = [self makeImageRefFromData:updateData width:bufferRect.size.width height:bufferRect.size.height spp:outputDataInfo.nSpp alphaPremultiplied:outputDataInfo.bAlphaPremultiplied];
            
            displayRect = bufferRect;
            
            CGRect shadowRect = [self getDisplayShadowRect:rectDirty];
            shadowRect = CGRectIntersection(shadowRect, CGRectMake(0, 0, imageData.nWidth, imageData.nHeight));
            displayRect = CGRectUnion(displayRect, shadowRect);
            //刷屏幕，滚动屏幕后，防止出现显示的是预览图
            
            [m_lockRenderInfoCGLayer lock];
            
            BOOL needRefreshAll = [self judgeNeedRefreshAllWithInfo:renderInfo oldInfo:m_renderInfoToCGLayer.renderInfo];
            if (needRefreshAll)
            {
                displayRect = renderInfo.rectSliceInCanvas;
                displayRect.origin.x -= renderInfo.pointImageDataOffset.x;
                displayRect.origin.y -= renderInfo.pointImageDataOffset.y;
                
            }
            
            if(!cgLayerNew)  cgLayerNew = m_renderInfoToCGLayer.cgLayerSlice;
            CGContextRef context = CGLayerGetContext(cgLayerNew);
            //CGContextClearRect(context, bufferRect);
            if(renderInfo.flagModifiedType == EFFECT_MODIFIED_ONLY || renderInfo.flagModifiedType == EFFECT_DISABLE_ONLY)
            {
                CGSize sizeLayer = CGLayerGetSize(cgLayerNew);
                CGContextClearRect(context, CGRectMake(0, 0, sizeLayer.width, sizeLayer.height));
            }
            [self drawImageToCGContext:context image:cgImage rect:bufferRect interpolate: YES];
            
            if(cgLayerNew != m_renderInfoToCGLayer.cgLayerSlice)
                CGLayerRelease(m_renderInfoToCGLayer.cgLayerSlice);
            
            m_renderInfoToCGLayer.renderInfo    = renderInfo;
            m_renderInfoToCGLayer.cgLayerSlice  = cgLayerNew;
            
            [m_lockRenderInfoCGLayer unlock];
       //     NSLog(@"drawImageToCGContext: rect = %@", NSStringFromRect(bufferRect));
            
            free(updateData);
            CGImageRelease(cgImage);

      //      [m_lockRenderInfoCGLayer unlock];
        }
 /*       else
        {
         //   [m_lockRenderInfoCGLayer unlock];
            [self reCreateCGLayer];
            IMAGE_DATA imageData = [m_infoForCGLayer.dataImage lockDataForRead];
            int height = imageData.nHeight;
            int width = imageData.nWidth;
            [m_infoForCGLayer.dataImage unLockDataForRead];
            rectDirty = CGRectMake(0, 0, width, height);
            displayRect = [self renderToSliceDirtyWithInfo:m_infoForCGLayer rectDirty:rectDirty];

        }
  */
    }
    
  //  [m_lockRenderInfoCGLayer unlock];
    
    //NSLog(@"displayRect %@,%d",NSStringFromRect(displayRect),m_bFullSlice);
    displayRect.origin.x -= nRadiusEdge;
    displayRect.origin.y -= nRadiusEdge;
    
    return displayRect;
}

- (CGRect)getDisplayShadowRect:(CGRect)dirtyRect
{
    CGRect displayRect = dirtyRect;
    int filterCount = [m_smartFilterManager getSmartFiltersCount];
    int filterIndex = [m_smartFilterManager getSmartFiltersCount] - 2;
    
    if (filterCount > 0)
    {
        int isLayerShadowEnable = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]].nIntValue;
        float shadowDistance = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowDistance" UTF8String]].fFloatValue;
        float extension = shadowDistance;
        
        if (isLayerShadowEnable)
        {
            displayRect.origin.x -= extension;
            displayRect.origin.y -= extension;
            displayRect.size.width += 2 * extension;
            displayRect.size.height += 2 * extension;
        }
    }

    return displayRect;
}

- (void)setShadowInfoForContext:(CGContextRef)context scale:(CGSize)scale
{
    int filterCount = [m_smartFilterManager getSmartFiltersCount];
    int filterIndex = [m_smartFilterManager getSmartFiltersCount] - 2;
    
    if (filterCount > 0)
    {
        int isLayerShadowEnable = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]].nIntValue;
        float colorAlpha = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColorAlpha" UTF8String]].fFloatValue;
        float lightAngle = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowLightAngle" UTF8String]].fFloatValue;
        float shadowDistance = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowDistance" UTF8String]].fFloatValue;
        float shadowBlur = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowBlur" UTF8String]].fFloatValue * scale.width;
        unsigned int colorValue = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColor" UTF8String]].nUnsignedValue;
        int red = colorValue & 0xFF;
        int green = (colorValue >> 8) & 0xFF;
        int blue = colorValue >> 16;
        float xoffset = -shadowDistance * sin(lightAngle * M_PI / 180) * scale.width;
        float yoffset = shadowDistance * cos(lightAngle * M_PI / 180) * scale.height;
        
        if (isLayerShadowEnable)
        {
            CGAffineTransform trans = CGContextGetCTM(context);
            printf("CGAffineTransform = %.3f %.3f %.3f %.3f %.3f %.3f\n", trans.a, trans.b, trans.c, trans.d, trans.tx, trans.ty);
            //if(trans.d < 0.0 && fabs(fabs(trans.d) -1.0) < 1.0e-6)
            //    yoffset = -yoffset;
            CGColorRef shadowColor = CGColorCreateGenericRGB(red / 255.0, green / 255.0,  blue / 255.0, colorAlpha);
            CGContextSetShadowWithColor(context, CGSizeMake(xoffset, yoffset), shadowBlur, shadowColor);
            CGColorRelease(shadowColor);
        }
        else
        {
            CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
        }
    }
    else
    {
        //CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
    }
}

- (void)setShadowInfoForContext:(CGContextRef)context
{
    int filterCount = [m_smartFilterManager getSmartFiltersCount];
    int filterIndex = [m_smartFilterManager getSmartFiltersCount] - 2;
    
    if (filterCount > 0)
    {
        int isLayerShadowEnable = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]].nIntValue;
        float colorAlpha = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColorAlpha" UTF8String]].fFloatValue;
        float lightAngle = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowLightAngle" UTF8String]].fFloatValue;
        float shadowDistance = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowDistance" UTF8String]].fFloatValue;
        float shadowBlur = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowBlur" UTF8String]].fFloatValue;
        unsigned int colorValue = [m_smartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColor" UTF8String]].nUnsignedValue;
        int red = colorValue & 0xFF;
        int green = (colorValue >> 8) & 0xFF;
        int blue = colorValue >> 16;
        float xoffset = -shadowDistance * sin(lightAngle * M_PI / 180);
        float yoffset = shadowDistance * cos(lightAngle * M_PI / 180);
        
        if (isLayerShadowEnable)
        {
            CGColorRef shadowColor = CGColorCreateGenericRGB(red / 255.0, green / 255.0,  blue / 255.0, colorAlpha);
            CGContextSetShadowWithColor(context, CGSizeMake(xoffset, yoffset), shadowBlur, shadowColor);
            CGColorRelease(shadowColor);
        }
        else
        {
            CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
        }
    }
    else
    {
        //CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
    }
    
}

- (void)renderOldToContext:(int)nMode alpha:(CGFloat)fAlpha
{
 //   [self renderToContext:m_infoForCGLayer mode:nMode alpha:fAlpha];
}

- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha  radiusEdge:(int)nRadius
{
    
    [m_lockRenderInfoCGLayer lock];
    
    if (!m_renderInfoToCGLayer.cgLayerSlice)
    {
        [m_lockRenderInfoCGLayer unlock];
        return;
    }
    
   // if (m_bFullSlice) // wzq
   //     m_infoForCGLayer.pointImageDataOffset = contextInfo.pointImageDataOffset;
    
    CGContextRef context = contextInfo.context;
    CGSize contextScale = contextInfo.scale;
    
    if (m_bFullSlice)
    {
        int xOffset = m_renderInfoToCGLayer.renderInfo.pointImageDataOffset.x;
        int yOffset = m_renderInfoToCGLayer.renderInfo.pointImageDataOffset.y;
        
        int xOffset1 = contextInfo.offset.x;
        int yOffset1 = contextInfo.offset.y;
        
        float xScale = contextScale.width;
        float yScale = contextScale.height;
        
        CGSize cgLayerSize = CGLayerGetSize(m_renderInfoToCGLayer.cgLayerSlice);
      //  IMAGE_DATA imageData = [m_infoForCGLayer.dataImage lockDataForRead];
        int width = (int)(cgLayerSize.width + 0.001);
        int height =  (int)(cgLayerSize.height + 0.001);
      //  [m_infoForCGLayer.dataImage unLockDataForRead];
        
        
        CGContextSaveGState(context);
        
        //CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        
        [self setShadowInfoForContext:context scale:contextScale];
        CGContextSetAlpha(context, fAlpha);
        CGContextSetBlendMode(context, nMode);
        CGRect destRect = CGRectMake((xOffset - xOffset1 ) * xScale, (yOffset - yOffset1) * yScale, width * xScale, height * yScale);
        
  //      if (m_cgLayerSlice)
        {
            CGContextDrawLayerInRect(context, destRect, m_renderInfoToCGLayer.cgLayerSlice);
        }
        
        CGContextRestoreGState(context);
    }
    else
    {
        
        CGContextSaveGState(context);
        //CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        
        [self setShadowInfoForContext:context scale:contextScale];
        CGContextSetAlpha(context, fAlpha);
        CGContextSetBlendMode(context, nMode);
        
        CGRect destRect = [self getDesRectWithRenderInfo:m_renderInfoToCGLayer.renderInfo contextInfo:contextInfo edgeRadius:0 ];
        
     //   if (m_cgLayerSlice)
        {
            CGContextDrawLayerInRect(context, destRect, m_renderInfoToCGLayer.cgLayerSlice);
            //CGContextDrawLayerAtPoint(context, destRect.origin, m_cgLayerSlice);
        }
        
        CGContextRestoreGState(context);
    }
    
    [m_lockRenderInfoCGLayer unlock];
}

/*
- (void)renderToContext_old:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha
{

    [m_lockRenderInfoCGLayer lock];
    if (!m_cgLayerSlice)
    {
        [m_lockRenderInfoCGLayer unlock];
        return;
    }
    
    if (m_bFullSlice) // wzq
        m_infoForCGLayer.pointImageDataOffset = contextInfo.pointImageDataOffset;
    
    CGContextRef context = contextInfo.context;
    CGSize contextScale = contextInfo.scale;
    
    if (m_bFullSlice)
    {
        int xOffset = m_infoForCGLayer.pointImageDataOffset.x;
        int yOffset = m_infoForCGLayer.pointImageDataOffset.y;
        
        int xOffset1 = contextInfo.offset.x;
        int yOffset1 = contextInfo.offset.y;
        
        float xScale = contextScale.width;
        float yScale = contextScale.height;
        
        IMAGE_DATA imageData = [m_infoForCGLayer.dataImage lockDataForRead];
        int height = imageData.nHeight;
        int width = imageData.nWidth;
        [m_infoForCGLayer.dataImage unLockDataForRead];
        
        
        CGContextSaveGState(context);
        
        //CGContextSetInterpolationQuality(context, kCGInterpolationNone);

        [self setShadowInfoForContext:context scale:contextScale];
        CGContextSetAlpha(context, fAlpha);
        CGContextSetBlendMode(context, nMode);
        CGRect destRect = CGRectMake((xOffset - xOffset1) * xScale, (yOffset - yOffset1) * yScale, width * xScale, height * yScale);
        
        if (m_cgLayerSlice)
        {
            CGContextDrawLayerInRect(context, destRect, m_cgLayerSlice);
        }
        
        CGContextRestoreGState(context);
    }
    else
    {
        
        CGContextSaveGState(context);
        //CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        
        [self setShadowInfoForContext:context scale:contextScale];
        CGContextSetAlpha(context, fAlpha);
        CGContextSetBlendMode(context, nMode);
        
        CGRect destRect = [self getDesRectWithRenderInfo:m_infoForCGLayer contextInfo:contextInfo];
        
        if (m_cgLayerSlice)
        {
            CGContextDrawLayerInRect(context, destRect, m_cgLayerSlice);
            //CGContextDrawLayerAtPoint(context, destRect.origin, m_cgLayerSlice);
        }
        
        CGContextRestoreGState(context);
    }
    
    [m_lockRenderInfoCGLayer unlock];
}
*/
- (BOOL)isRenderedForInfo:(RENDER_INFO)renderInfo  radiusEdge:(int)nRadiusEdge
{
    renderInfo.pointImageDataOffset.x -= (CGFloat)nRadiusEdge;
    renderInfo.pointImageDataOffset.y -= (CGFloat)nRadiusEdge;
    
    if (m_bFullSlice)
    {
        [m_lockRenderInfoCGLayer lock];
        BOOL isEqual = ![self isNeedRecreateCGLayer:renderInfo isFullSlice:m_bFullSlice];
        [m_lockRenderInfoCGLayer unlock];
        
        return isEqual;
    }
    else
    {
        [m_lockRenderInfoCGLayer lock];
        BOOL isEqual = ![self isNeedRecreateCGLayer:renderInfo isFullSlice:m_bFullSlice];
        [m_lockRenderInfoCGLayer unlock];
        
        return isEqual;
    }
}

- (BOOL)isFullSlice
{
    return m_bFullSlice;
}




#pragma mark -
#pragma mark assistant function

- (BOOL)isNeedRecreateCGLayer:(RENDER_INFO)renderInfo isFullSlice:(BOOL)isFullSlice
{
    if (isFullSlice)
    {
        CGSize cglayerSize      = CGLayerGetSize(m_renderInfoToCGLayer.cgLayerSlice);
        IntSize cglayerIntSize  = NSSizeMakeIntSize(cglayerSize);
        IMAGE_DATA imageData    = [renderInfo.dataImage lockDataForRead];
        
        if (cglayerIntSize.width != imageData.nWidth || cglayerIntSize.height != imageData.nHeight)
        {
            [renderInfo.dataImage unLockDataForRead];
            return YES;
        }
        
        [renderInfo.dataImage unLockDataForRead];
    }
    else
    {
        CGSize cglayerSize = CGLayerGetSize(m_renderInfoToCGLayer.cgLayerSlice);
        IntSize cglayerIntSize = NSSizeMakeIntSize(cglayerSize);
        CGRect cglayerRect = [self getCGLayerRectWithRenderInfo:renderInfo];
        IntSize cglayerIntSize1 = NSSizeMakeIntSize(cglayerRect.size);
        
        if (m_renderInfoToCGLayer.cgLayerSlice == nil && (cglayerIntSize1.width <= 0 || cglayerIntSize1.height <= 0))
        {
            return NO;
        }
        
        if (cglayerIntSize.width != cglayerIntSize1.width || cglayerIntSize.height != cglayerIntSize1.height)
        {
            return YES;
        }
        
        if (!CGRectEqualToRect(renderInfo.rectSliceInCanvas, m_renderInfoToCGLayer.renderInfo.rectSliceInCanvas))
        {
            return YES;
        }
        
        if (!CGSizeEqualToSize(renderInfo.sizeScale, m_renderInfoToCGLayer.renderInfo.sizeScale))
        {
            return YES;
        }
    }
    return NO;
}



- (BOOL)isRenderInfo:(RENDER_INFO)renderInfoA equalTo:(RENDER_INFO)renderInfoB
{
    IMAGE_DATA imageDataA = [renderInfoA.dataImage lockDataForRead];
    IMAGE_DATA imageDataB = [renderInfoB.dataImage lockDataForRead];
    
    if (imageDataA.nWidth != imageDataB.nWidth || imageDataA.nHeight != imageDataB.nHeight || imageDataA.pBuffer != imageDataB.pBuffer)
    {
        [renderInfoA.dataImage unLockDataForRead];
        [renderInfoB.dataImage unLockDataForRead];
        return NO;
    }
    
    [renderInfoA.dataImage unLockDataForRead];
    [renderInfoB.dataImage unLockDataForRead];
    
    
    if (!CGRectEqualToRect(renderInfoA.rectSliceInCanvas, renderInfoB.rectSliceInCanvas))
    {
        return NO;
    }
    
    if (!CGSizeEqualToSize(renderInfoA.sizeScale, renderInfoB.sizeScale))
    {
        return NO;
    }
    
    if (!CGPointEqualToPoint(renderInfoA.pointImageDataOffset, renderInfoB.pointImageDataOffset))
    {
        return NO;
    }

    return YES;
   
}

- (BOOL)isFullDataRenderInfo:(RENDER_INFO)renderInfoA equalTo:(RENDER_INFO)renderInfoB
{
    IMAGE_DATA imageDataA = [renderInfoA.dataImage lockDataForRead];
    IMAGE_DATA imageDataB = [renderInfoB.dataImage lockDataForRead];
    
    if (imageDataA.nWidth != imageDataB.nWidth || imageDataA.nHeight != imageDataB.nHeight || imageDataA.pBuffer != imageDataB.pBuffer)
    {
        [renderInfoA.dataImage unLockDataForRead];
        [renderInfoB.dataImage unLockDataForRead];
        return NO;
    }
    
    [renderInfoA.dataImage unLockDataForRead];
    [renderInfoB.dataImage unLockDataForRead];
    
    return YES;
}

// renderInfo对应 cglayer 映射到 contextInfo 显示
- (CGRect)getDesRectWithRenderInfo:(RENDER_INFO)renderInfo contextInfo:(RENDER_CONTEXT_INFO)contextInfo edgeRadius:(int)edgeRaidus
{
    CGRect cgLayerRect = renderInfo.rectSliceInCanvas;
    
    int xOffset = renderInfo.pointImageDataOffset.x; //contextInfo.pointImageDataOffset.x;//
    int yOffset = renderInfo.pointImageDataOffset.y; //contextInfo.pointImageDataOffset.y;//
    //  NSLog(@"contextInfo %d %d renderinfo %d %d", (int)contextInfo.pointImageDataOffset.x, (int)contextInfo.pointImageDataOffset.y, (int)renderInfo.pointImageDataOffset.x, (int)renderInfo.pointImageDataOffset.y);
    
    float xScale = contextInfo.scale.width;
    float yScale = contextInfo.scale.height;
    float xCGLayerScale = renderInfo.sizeScale.width;
    float yCGLayerScale = renderInfo.sizeScale.height;
    
    xCGLayerScale = MIN(1.0, xCGLayerScale);
    yCGLayerScale = MIN(1.0, yCGLayerScale);
    
    IMAGE_DATA imageData = [renderInfo.dataImage lockDataForRead];
    int height = imageData.nHeight;
    int width = imageData.nWidth;
    [renderInfo.dataImage unLockDataForRead];
    
    CGRect visibleRect = CGRectIntersection(CGRectMake(xOffset, yOffset, width, height), cgLayerRect);
    
    visibleRect.origin.x -= contextInfo.offset.x + edgeRaidus;
    visibleRect.origin.y -= contextInfo.offset.y + edgeRaidus;
    visibleRect.origin.x *= xScale;
    visibleRect.origin.y *= yScale;
    
    visibleRect.origin.x = floorf(visibleRect.origin.x);
    visibleRect.origin.y = floorf(visibleRect.origin.y);
    
    CGSize cglayerSize = CGLayerGetSize(m_renderInfoToCGLayer.cgLayerSlice);
    
    visibleRect.size.width = cglayerSize.width * xScale / xCGLayerScale;
    visibleRect.size.height = cglayerSize.height * yScale / yCGLayerScale;
    //    visibleRect.size.width = cglayerSize.width;
    //    visibleRect.size.height = cglayerSize.height;
    
    return visibleRect;
    
}

- (CGRect)getDesRectWithRenderInfo_old:(RENDER_INFO)renderInfo contextInfo:(RENDER_CONTEXT_INFO)contextInfo
{
    CGRect cgLayerRect = renderInfo.rectSliceInCanvas;
    
    int xOffset = renderInfo.pointImageDataOffset.x; //contextInfo.pointImageDataOffset.x;//
    int yOffset = renderInfo.pointImageDataOffset.y; //contextInfo.pointImageDataOffset.y;//
  //  NSLog(@"contextInfo %d %d renderinfo %d %d", (int)contextInfo.pointImageDataOffset.x, (int)contextInfo.pointImageDataOffset.y, (int)renderInfo.pointImageDataOffset.x, (int)renderInfo.pointImageDataOffset.y);
    
    float xScale = contextInfo.scale.width;
    float yScale = contextInfo.scale.height;
    float xCGLayerScale = renderInfo.sizeScale.width;
    float yCGLayerScale = renderInfo.sizeScale.height;
    
    xCGLayerScale = MIN(1.0, xCGLayerScale);
    yCGLayerScale = MIN(1.0, yCGLayerScale);
    
    IMAGE_DATA imageData = [renderInfo.dataImage lockDataForRead];
    int height = imageData.nHeight;
    int width = imageData.nWidth;
    [renderInfo.dataImage unLockDataForRead];
    
    CGRect visibleRect = CGRectIntersection(CGRectMake(xOffset, yOffset, width, height), cgLayerRect);
    visibleRect.origin.x -= contextInfo.offset.x;
    visibleRect.origin.y -= contextInfo.offset.y;
    visibleRect.origin.x *= xScale;
    visibleRect.origin.y *= yScale;
    
    visibleRect.origin.x = floorf(visibleRect.origin.x);
    visibleRect.origin.y = floorf(visibleRect.origin.y);
    CGSize cglayerSize = CGLayerGetSize(m_renderInfoToCGLayer.cgLayerSlice);
    visibleRect.size.width = cglayerSize.width * xScale / xCGLayerScale;
    visibleRect.size.height = cglayerSize.height * yScale / yCGLayerScale;
//    visibleRect.size.width = cglayerSize.width;
//    visibleRect.size.height = cglayerSize.height;
    
    
    
    return visibleRect;
    
}



//获取当前层可见部分对应整个view的rect，放缩过
- (CGRect)getCGLayerRectWithRenderInfo:(RENDER_INFO)renderInfo
{
    CGRect cgLayerRect = renderInfo.rectSliceInCanvas;
   
    
    int xOffset = renderInfo.pointImageDataOffset.x;
    int yOffset = renderInfo.pointImageDataOffset.y;
    float xCGLayerScale = renderInfo.sizeScale.width;
    float yCGLayerScale = renderInfo.sizeScale.height;
    
    xCGLayerScale = MIN(1.0, xCGLayerScale);
    yCGLayerScale = MIN(1.0, yCGLayerScale);
    
    
    IMAGE_DATA imageData = [renderInfo.dataImage lockDataForRead];
    int height = imageData.nHeight;
    int width = imageData.nWidth;
    [renderInfo.dataImage unLockDataForRead];
    
    CGRect visibleRect = CGRectIntersection(CGRectMake(xOffset, yOffset, width, height), cgLayerRect);
    
    //NSLog(@"size %@ %@", NSStringFromRect(cgLayerRect), NSStringFromRect(visibleRect));
    if (CGRectIsNull(visibleRect))
    {
        return CGRectMake(0, 0, 0, 0);
    }
    
    visibleRect.origin.x *= xCGLayerScale;
    visibleRect.origin.y *= yCGLayerScale;
    visibleRect.size.width *= xCGLayerScale;
    visibleRect.size.height *= yCGLayerScale;
    
    visibleRect.origin.x = floorf(visibleRect.origin.x);
    visibleRect.origin.y = floorf(visibleRect.origin.y);
    visibleRect.size.width = ceilf(visibleRect.size.width) + 1;
    visibleRect.size.height = ceilf(visibleRect.size.height) + 1;
    
    return visibleRect;
    
}

- (CGLayerRef)createCGLayerWidth:(int)width height:(int)height spp:(int)spp
{
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, width, height, 8, spp * width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    CGLayerRef cglayerRef = NULL;
    
    cglayerRef = CGLayerCreateWithContext(bitmapContext, CGSizeMake(width, height), NULL);
    assert(cglayerRef);
    CGContextRelease(bitmapContext);
    
    return cglayerRef;
}

-(void)destroyCGLayer
{
    [m_lockRenderInfoCGLayer lock];
    if (m_renderInfoToCGLayer.cgLayerSlice) CGLayerRelease(m_renderInfoToCGLayer.cgLayerSlice);
    
    m_renderInfoToCGLayer.cgLayerSlice = nil;
    [m_lockRenderInfoCGLayer unlock];
}

//不清理CGContextClearRect,直接覆盖原有数据
- (void)drawImageToCGContext:(CGContextRef)context image:(CGImageRef)image rect:(CGRect)rect interpolate:(BOOL)interpolate
{
    if (!context)
    {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);//4
    CGContextTranslateCTM(context, 0, rect.size.height);//3
    CGContextScaleCTM(context, 1.0, -1.0);//2
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);//1
    
    if (interpolate)
    {
//        CGContextSetInterpolationQuality(context, kCGInterpolationDefault);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh); //wzq
    }
    else
    {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    }
    
    
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, rect, image);
    CGContextRestoreGState(context);
    
}

- (CGImageRef)makeImageRefFromData:(unsigned char*)data width:(int)width height:(int)height spp:(int)spp alphaPremultiplied:(int) bAlphaPremultiplied
{
    if (width <= 0.5 || height <= 0.5 || spp <= 0.5)
    {
        return NULL;
    }
    
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, data, width * height * spp, NULL);
    assert(dataProvider);
    
    CGImageRef cgImage;
    if(bAlphaPremultiplied)
        cgImage = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    else
        cgImage = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    assert(cgImage);
    
    CGColorSpaceRelease(defaultColorSpace);
    CGDataProviderRelease(dataProvider);
    
    return cgImage;
}

#pragma mark -
#pragma mark assistant function - compute Decimal Fraction

- (float)getGreatCommonDivisor:(float)c value2:(float)d
{
    int o = 1,p = 1;
    
    while(c/o != d/p)
    {
        while(c/o > d/p)
            o++;
        
        while(c/o < d/p)
            p++;
    }
    
   if(c/o==d/p)
        return (c/o);
    
    return 1;
}


- (void)getDecimalFraction:(float)m numerator:(int*)numerator denominator:(int*)denominator
{
    int mInt = round(m * 100.0);
    int j = 100;
    int l = [self getGreatCommonDivisor:mInt value2:j];
    
    mInt = mInt / l;
    j = j / l;
    *numerator = abs(mInt);
    *denominator = abs(j);
}

- (CGRect)getIntergerRectFor:(CGRect)srcRect xscale:(float)xscale yscale:(float)yscale
{
    CGRect desRect = srcRect;
    
    int numerator = 1;
    int denominator = 1;
    
    [self getDecimalFraction:xscale numerator:&numerator denominator:&denominator];
    desRect.origin.x = floor(srcRect.origin.x / denominator) * denominator;
    desRect.size.width = ceil(srcRect.size.width / denominator) * denominator + denominator;
    
    [self getDecimalFraction:yscale numerator:&numerator denominator:&denominator];
    desRect.origin.y = floor(srcRect.origin.y / denominator) * denominator;
    desRect.size.height = ceil(srcRect.size.height / denominator) * denominator + denominator;
    
    return desRect;
}

@end
