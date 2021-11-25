//
//  PSLayerRender.m
//  testDelegate
//
//  Created by mac on 15-11-19.
//  Copyright (c) 2015年 effectmatrix. All rights reserved.
//

#import "PSLayerRender.h"
#import "PSLayer.h"

@implementation PSLayerRender

- (id)initWithLayer:(PSLayer *)layer
{
    self = [super init];
    m_idLayer = layer;
    
    m_layerRendered.m_cgLayerRender = NULL;
    
    m_refreshLock = [[NSLock alloc] init];
    //[m_refreshLock unlock];
    
    m_bTotalLayerReady = NO;
    m_bRenderLayerReady = NO;
    
    m_layerRendered.xScale = 1.0;
    m_layerRendered.yScale = 1.0;
    
    m_refreshThread = [[NSThread alloc] initWithTarget:self selector:@selector(RefreshThread) object:nil];
    [m_refreshThread start];
    
    
    
    return self;
}

- (void)startRefresh:(REFRESH_INSTANCE)needRefresh
{
    //NSThread
    m_refreshThread = [[NSThread alloc] initWithTarget:self selector:@selector(RefreshThread) object:nil];
    [m_refreshThread start];
    
}

- (NSRect)combineSrcRect:(NSRect)srcRect desRect:(NSRect)desRect
{
    //NSLog(@"m_willBeProcessDataRect1 %@ %@",NSStringFromRect(srcRect),NSStringFromRect(m_willBeProcessDataRect));
    if (srcRect.size.width <= 0 || srcRect.size.height <= 0) {
        //NSLog(@"combineWillBeProcessDataRect1");
        return desRect;
    }
    if (desRect.size.width <= 0.0 || desRect.size.height <= 0.0) {
        if (srcRect.size.width > 0 && srcRect.size.height > 0) {
            desRect = srcRect;
        }
        return desRect;
    }
    CGFloat minx = desRect.origin.x;
    CGFloat maxx = desRect.origin.x + desRect.size.width;
    CGFloat miny = desRect.origin.y;
    CGFloat maxy = desRect.origin.y + desRect.size.height;
    NSRect temp = srcRect;
    if (temp.origin.x < minx) {
        minx = temp.origin.x;
    }
    if (temp.origin.x + temp.size.width > maxx) {
        maxx = temp.origin.x + temp.size.width;
    }
    if (temp.origin.y < miny) {
        miny = temp.origin.y;
    }
    if (temp.origin.y + temp.size.height > maxy) {
        maxy = temp.origin.y + temp.size.height;
    }
    
    desRect = NSMakeRect(minx, miny, maxx - minx, maxy - miny);
    
    return desRect;
}


- (void)setDirty:(NSRect)dataDirtyRect
{
    m_needRefresh.rectDirty = dataDirtyRect;
    m_rectNeedRefresh = [self combineSrcRect:dataDirtyRect desRect:m_rectNeedRefresh];
}

- (void) setCanvasRect:(NSRect) rectCanvas
{
    m_needRefresh.rectCanvasToRender = rectCanvas;
}

- (void) setViewXScale:(float)fScale
{
    m_needRefresh.xScale = fScale;
}

- (void) setViewYScale:(float) fScale
{
    m_needRefresh.yScale = fScale;
}

- (void)render:(CGContextRef)context viewRect:(NSRect)viewRect
{
    //view rect to layer rect
    
    
    if (m_bTotalLayerReady) {
        
    }else{
        if (m_bRenderLayerReady) {
            
        }else{
            [self renderTotalLayerToContext:context];
        }
    }
}

- (void)renderTotalLayerToContext:(CGContextRef)context
{
    
}

- (void)renderScreenLayerToContext:(CGContextRef)context
{
    int newXOffset = [m_idLayer xoff];
    int newYOffset = [m_idLayer yoff];
    int width = [m_idLayer width];
    int height = [m_idLayer height];
    int mode = [m_idLayer mode];
    int layerAlpha = [m_idLayer opacity];
    
    float xScale = m_needRefresh.xScale;
    float yScale = m_needRefresh.yScale;
    
    CGContextSaveGState(context);
    CGContextSetAlpha(context, layerAlpha/255.0);
    CGContextSetBlendMode(context, mode);
    CGRect destRect = CGRectMake(newXOffset * xScale, newYOffset * yScale, width * xScale, height * yScale);
    
    if (m_cgLayerTotal) {
        CGContextDrawLayerInRect(context, destRect, m_cgLayerTotal);
    }
    CGContextRestoreGState(context);

}



- (void)setRefreshSleep
{
    
}

- (void)waitRefreshSleep
{
    m_rectNeedRefresh = NSMakeRect(0, 0, -1, -1);
    m_bWakeUp = 0;
    [m_refreshLock lock];
    [m_refreshLock unlock];
}

- (void)RefreshThread
{
    while(1)
    {
        
        [m_refreshLock lock];
        if (m_rectNeedRefresh.size.width > 0 && m_rectNeedRefresh.size.height > 0) {
            
        }
        
        
//        if(m_rectNeedRefresh == CGRectNULL)
//        {
//            while(1){
//                
//                if(m_WakeUp)	{m_WakeUp = 0; break;}
//                sleep(100);
//            }
//        }
//        
//        
//        REFRESH_INSTANCE refreshInstace = m_needRefresh;
//        mutext.lock();
//        
//        CGLAYER_INFO RenderDataToCGLayer(refreshInstace, layerOld, m_rectNeedRefresh)
//        
//        EnterSleep()
//        { //rectNeedRefresh += dataRect; 																mutext.unlock(); continue;}
//            
//            最后更新 CGLAYER_INFO
//            通知刷新界面
//            
//            m_rectNeedRefresh = CGRectNULL;
//            mutext.unlock();
//            
//            
//        }
        
        
        [NSThread sleepForTimeInterval:0.005];
   
    }
}





//-(NSRect)getDirtyRect:(REFRESH_INSTANCE)refreshInstace
//{
//    return refreshInstace.rectCanvasToRender;
//}
//-(CGLayerRef)getCGLayer:(REFRESH_INSTANCE)refreshInstace layerinfo: (CGLAYER_INFO)layerOld
//{
//    
//}
//- (NSRect)getValidData:(IMAGE_DATA *)data
//{
//    
//}
//- drawToCGLayer:(IMAGE_DATA *)data rect:(NSRect)rect
//{
//    
//}
//
//-(CGLAYER_INFO)renderDataToCGLayer:(REFRESH_INSTANCE)refreshInstace layerinfo: (CGLAYER_INFO)layerOld
//{
//    
//}

    
@end
