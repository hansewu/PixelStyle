//
//  PSLayerWithEffectRender.h
//  PixelStyle
//
//  Created by lchzh on 19/11/15.
//
//

#import <Foundation/Foundation.h>
#import "PSRenderSlice.h"

@protocol protocolRenderNotify <NSObject>

- (void)displayRenderedInfo:(CGRect)rect;

@end


//多线程render
@interface PSLayerWithEffectRender : NSObject
{
    PSRenderSlice           *m_idRenderSlice;
    
    CGPoint                 m_pointOffsetChangedOnly;
    RENDER_INFO             m_toRenderInfo;
    
    RENDER_INFO             m_renderingInfo;
    
    CGRect                  m_dataDirtyRect;
    volatile BOOL           m_renderIsReady;
    
    NSRecursiveLock                  *m_lockRenderInfo;

    NSThread                *m_renderThread;
    
    
    id<protocolRenderNotify>    m_delegateToRender;
    
    volatile                int m_NotifyThreadExit;
    
    volatile  BOOL m_bCanBeginRender;
    
    PSSmartFilterManager *m_smartFilterManager;
}


- (id)initWithRenderInfo:(RENDER_INFO)renderInfo bfullslice:(BOOL)bFullSlice;
- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager;
- (void)reRenderWithInfo:(RENDER_INFO)renderInfo;
- (void)renderDirtyWithInfo:(RENDER_INFO)renderInfo dirtyRect:(NSRect) dataDirtyRect;
- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew;


- (BOOL)isRenderedToSlice;
- (BOOL)isRenderedToSlice:(RENDER_CONTEXT_INFO)contextInfo;
- (void)setDelegateRenderNotify:(id)delegate;


- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha;
- (void)reRenderToRTSlice:(RENDER_CONTEXT_INFO)contextInfo;

- (void)setCanBeginRender:(BOOL)canBegin;

-(void)exitRenderThread;

@end

typedef enum
{
    REFRESH_TYPE_DEFAULT = 0,
    REFRESH_TYPE_PREVIEW,
    REFRESH_TYPE_FULL,
    REFRESH_TYPE_OFFSET
    
}REFRESH_TYPE;

@interface PSRenderEffect : NSObject
{
    PSLayerWithEffectRender  *m_renderRT;
    PSLayerWithEffectRender  *m_renderFull;
    
}

- (id)initWithRenderInfo:(RENDER_INFO)renderInfo;

- (void)setSmartFilterManager:(PSSmartFilterManager *)smartFilterManager;
- (void)renderDirtyWithOffsetChangedOnly:(CGPoint)pointOffsetNew;
- (void)reRenderWithInfo:(RENDER_INFO)renderInfo;
- (void)renderDirtyWithInfo:(RENDER_INFO)renderInfo dirtyRect:(NSRect) dataDirtyRect refreshType:(REFRESH_TYPE)type;

- (void)renderToContext:(RENDER_CONTEXT_INFO)contextInfo mode:(int)nMode alpha:(CGFloat)fAlpha;

- (void)setDelegateRenderNotify:(id)delegate;

- (void)setFullRenderState:(BOOL)canBegin;

- (BOOL)isRenderCompleted:(BOOL)isFull;

-(void)exitRenderThread;

-(void)removeCache;

@end
