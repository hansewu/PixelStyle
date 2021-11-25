//
//  PSRenderSlice.h
//  PixelStyle
//
//  Created by wzq on 15/11/21.
//
//

#import <Foundation/Foundation.h>
#import "Globals.h"


@class PSSecureImageData;

@class PSSmartFilterManager;

//1 完成图像块对m_cgLayer相对于某个view port的映射和转换
//2 线程安全，可以多线程访问
//所有坐标都是相对于 canvas 的

typedef enum DATAModifiedType
{
    IMAGE_FILTER_MODIFIED =0,
    IMAGE_FILTER_FULL_MODIFIED =1,
    IMAGE_MODIFIED_ONLY =2,
    EFFECT_MODIFIED_ONLY,
    EFFECT_DISABLE_ONLY,
    OFFSET_MODIFIED_ONLY,
    VIEWSCALE_MODIFIED_ONLY
}enumDATAModifiedType;

typedef struct
{
    PSSecureImageData   *dataImage;
    
    CGPoint             pointImageDataOffset;
    
    CGRect              rectSliceInCanvas;
    CGSize              sizeScale;
    enumDATAModifiedType  flagModifiedType;
  //  PSSmartFilterManager *smartFilterManager;
}RENDER_INFO;

typedef struct
{
    RENDER_INFO     renderInfo;
    CGLayerRef      cgLayerSlice;
}RENDER_INFO_TOCGLAYER;

@interface PSRenderSlice : NSObject
{
    RENDER_INFO_TOCGLAYER  m_renderInfoToCGLayer;
//    CGLayerRef      m_cgLayerSlice;
    
//    RENDER_INFO     m_infoForCGLayer;
  //  CGSize m_sizeCGLayerScale;
    
    BOOL            m_bFullSlice;
    
    // thread safe that protect m_cgLayer and m_infoForCGLayer while create, write, read
   // NSRecursiveLock   *m_lockProtectCGLayer;
    NSRecursiveLock   *m_lockRenderInfoCGLayer;
    
    PSSmartFilterManager *m_smartFilterManager;
    
}

- (id)initWithRenderInfo:(RENDER_INFO)renderInfo bfullslice:(BOOL)bFullSlice;

//clear (, maybe recreate m_cgLayer) and render to slice
//- (void)reRenderToSliceWithInfo:(RENDER_INFO)renderInfo;

- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew   radiusEdge:(int)nRadiusEdge;
- (CGRect)renderToSliceDirtyWithInfo:(RENDER_INFO)renderInfo  rectDirty:(CGRect)rectDirty radiusEdge:(int)nRadius;

- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha radiusEdge:(int)nRadius;

- (BOOL)isRenderedForInfo:(RENDER_INFO)renderInfo  radiusEdge:(int)nRadiusEdge;
- (BOOL)isFullSlice;

- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager;

@end
