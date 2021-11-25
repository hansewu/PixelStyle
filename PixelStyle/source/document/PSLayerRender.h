//
//  PSLayerRender.h
//  testDelegate
//
//  Created by mac on 15-11-19.
//  Copyright (c) 2015年 effectmatrix. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    unsigned char *m_pData;
    int m_nSpp;
    int m_nWidth;
    int m_nHeight;
}IMAGE_DATA;

typedef struct
{
 //   IMAGE_DATA data;
    NSRect rectDirty;
    NSRect rectCanvasToRender;
    float	xScale;
    float	yScale;
    
    BOOL needRefreshDistance;
    BOOL isPreview;
    
}REFRESH_INSTANCE;

typedef struct
{
    CGLayerRef	m_cgLayerRender;
    NSRect      m_rectCGLayer; //对应整个layer缩放后cglayer区域
    //float       m_fCGScale;
    
    NSRect rectCanvasToRender;
    float	xScale;
    float	yScale;
    
    NSRect      m_rectRefresh;
}CGLAYER_INFO;

typedef struct
{
    NSRect rectCanvasToRender;
    float	xScale;
    float	yScale;
    
}CANVAS_RENDER_INFO;

@class PSLayer;
@interface PSLayerRender : NSObject
{
    CGLAYER_INFO        m_layerRendered;
    REFRESH_INSTANCE    m_needRefresh;
    
    NSRect m_rectNeedRefresh;
    NSRect m_rectTotalNeedRefresh; //for total layer
    
    PSLayer *m_idLayer;
    
    
    NSThread *m_refreshThread;
    BOOL m_bWakeUp;
    NSLock *m_refreshLock;
    
    BOOL m_bRenderLayerReady;
    
    BOOL m_bTotalLayerReady;
    CGLayerRef	m_cgLayerTotal;
}

- (id)initWithLayer:(PSLayer *)layer;

- (NSRect)combineSrcRect:(NSRect)srcRect desRect:(NSRect)desRect;

- (void)startRefresh:(REFRESH_INSTANCE)needRefresh;

- (void)setDirty:(NSRect) dataDirtyRect needRefreshDistance:(BOOL)refreshDistance isPreview:(BOOL)isPreview;
//- (void) setCanvasRect:(NSRect)  rectCanvas;
//- (void) setViewScale:(float) fScale;

- (void)render:(CGContextRef)context viewRect:(NSRect)viewRect;

//in thread



@end
