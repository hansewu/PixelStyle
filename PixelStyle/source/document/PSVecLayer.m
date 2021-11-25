//
//  PSVecLayer.m
//  PixelStyle
//
//  Created by wzq on 15/11/30.
//
//

#import "PSVecLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSHelpers.h"
#import "ThressPointsAffine.h"

#import "WDLayer.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDFillTransform.h"

#import "PSTextLayer.h"
#import "WDTextRenderer.h"
#import "WDText.h"

#import "PSSmartFilterManager.h"

static CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied)
{
    if (pixelsWidth <= 0 || pixelsHigh <= 0) {
        return NULL;
    }
    
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
    int  bitmapByteCount;
    int  bitmapBytesPerRow;
    
    bitmapBytesPerRow  = (pixelsWidth * 4);
    bitmapByteCount  = (bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    //bitmapData = malloc( bitmapByteCount );
    bitmapData = pBuffer;
    //bitmapData =(char*)CGBitmapContextGetData((CGContextRef)[EAGLContext currentContext]);//   m_glContext
    if (bitmapData == NULL)
    {
        assert(false);
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    
    //  if(bAlphaPremultiplied)
    context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    //  else
    //context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big);
    if (context== NULL)
    {
        //free (bitmapData);
        assert(false);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}


@interface PSVecLayer()
{
    // polygon support
    int                 numPolygonPoints_;
    
    // rect support
    float               rectCornerRadius_;
    
    // star support
    int                 numStarPoints_;
    float               starInnerRadiusRatio_;
    float               lastStarRadius_;
    
    // spiral support
    int                 decay_;
    
    WDPath              *m_pathTemp;
}
@end

@implementation PSVecLayer
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
//    [aCoder encodeObject:m_pathTemp forKey:@"PSPath"];
    [aCoder encodeObject:m_wdLayer forKey:@"WDLayer"];
    
    NSValue *vlTransform = [NSValue valueWithBytes:&m_Transformed objCType:@encode(CGAffineTransform)];
    [aCoder encodeObject:vlTransform forKey:@"PSLayerTransform"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
//    m_pathTemp = [aDecoder decodeObjectForKey:@"PSPath"];
    m_wdLayer = [aDecoder decodeObjectForKey:@"WDLayer"];
    
    NSValue *vlTransform = [aDecoder decodeObjectForKey:@"PSLayerTransform"];
    [vlTransform getValue:&m_Transformed];
    
    return self;
}

- (id)initWithDocument:(id)doc
{
    self = [super initWithDocument:doc];
    
    m_enumLayerFormat   = PS_VECTOR_LAYER;
    m_Transformed       = CGAffineTransformIdentity;
    
    
    m_wdLayer = [WDLayer layer];
    m_wdLayer.layerDelegate = self;
    [m_wdLayer retain];
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    m_wdLayer.drawing = wdDrawingController.drawing;
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    m_contextData       = nil;
    
    m_lockMakeTransform = [[NSLock alloc] init];
    
    m_bIsEffectValid = NO;
    
    return self;
}

- (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp
{
    self = [super initWithDocument:doc width:lwidth height:lheight opaque:opaque spp:lspp];
    
    m_enumLayerFormat   = PS_VECTOR_LAYER;
    
    
    m_nXoff = m_nYoff = m_nWidth = m_nHeight = 0;
    

    [self refreshTotalToRender];
    
    
    return self;
}

- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp
{
//    self = [super initWithDocument:doc rect:lrect data:ldata spp:lspp];
//    
//    m_enumLayerFormat   = PS_VECTOR_LAYER;
    
    return nil;
    
}

- (id)initWithDocument:(id)doc layer:(PSVecLayer*)layer
{
    self = [super initWithDocument:doc layer:layer];
    
    //if([layer layerFormat] != PS_VECTOR_LAYER) return self;
    
    m_enumLayerFormat   = PS_VECTOR_LAYER;
    
    
    m_contextData       = nil;
    m_Transformed       = layer->m_Transformed;
    
//    if(!m_wdLayer)
//    {
//        m_wdLayer = [WDLayer layer];
//        m_wdLayer.layerDelegate = self;
//        [m_wdLayer retain];
//        
//        PSContent *contents = (PSContent *)[m_idDocument contents];
//        WDDrawingController *wdDrawingController = [contents wdDrawingController];
//        [wdDrawingController.drawing.layers addObject:m_wdLayer];
//    }
    
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
    
    if(m_wdLayer) [m_wdLayer release];
    m_wdLayer =[layer->m_wdLayer copyWithZone:nil];
    m_wdLayer.layerDelegate = self;
    m_wdLayer.drawing = wdDrawingController.drawing;
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
    [m_pImageData unLockDataForRead];
    
    [self drawToRawData];
    
    [self refreshTotalToRender];

    
    return self;
    

}

- (id)initWithDocument:(id)doc textLayer:(PSVecLayer*)layer
{
    if([layer layerFormat] != PS_TEXT_LAYER) return self;
    
    self = [super initWithDocument:doc layer:layer];
    
    m_enumLayerFormat   = PS_VECTOR_LAYER;
    m_contextData       = nil;
    m_Transformed       = layer->m_Transformed;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
    
    if(m_wdLayer) [m_wdLayer release];
    m_wdLayer = [layer->m_wdLayer copyWithZone:nil];
    m_wdLayer.layerDelegate = self;
    m_wdLayer.drawing = wdDrawingController.drawing;
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    for (WDElement *element in [[layer getLayer] elements])
    {
        if ([element conformsToProtocol:@protocol(WDTextRenderer)])
        {
            WDText *text = (WDText *) element;
            NSArray *paths = [text outlines];
            
            for (WDAbstractPath *path in paths)
            {
                if([path isEqual:[paths objectAtIndex:0]]) continue;  //忽略文字层初始的空格t
                
                path.fill = text.fill;
                path.fillTransform = text.fillTransform;
                path.strokeStyle = text.strokeStyle;
                path.opacity = text.opacity;
                path.shadow = text.shadow;
                
                [self addPathObject:path];
            }
        }
    }

    [self applyTransform];
    
    
    unsigned char *newData = malloc(make_128(m_nWidth * m_nHeight * m_nSpp));
    memset(newData, 0, m_nWidth * m_nHeight * m_nSpp);
    
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:true];
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
    [m_pImageData unLockDataForRead];
    
    [self drawToRawData];
    
    [self refreshTotalToRender];
    
    
    return self;
}

- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata
{
    return nil;
}

- (id)initWithDocumentAfterCoder:(id)doc layer:(PSVecLayer*)endocerLayer
{
    self = [super initWithDocumentAfterCoder:doc layer:endocerLayer];
    
    if([endocerLayer layerFormat] != PS_VECTOR_LAYER) return self;
    
    m_enumLayerFormat   = PS_VECTOR_LAYER;
    m_pathTemp          = endocerLayer->m_pathTemp;
    [m_pathTemp retain];
    
    m_contextData       = nil;
    m_Transformed       = endocerLayer->m_Transformed;
    
//    if(!m_wdLayer)
//    {
//        m_wdLayer = [WDLayer layer];
//        [m_wdLayer retain];
//    }
    
    [self performSelector:@selector(delayInitWDLayer:) withObject:endocerLayer afterDelay:.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
//    
//    if(m_wdLayer) [m_wdLayer release];
//    m_wdLayer =[endocerLayer->m_wdLayer copyWithZone:nil];
//    m_wdLayer.layerDelegate = self;
//    m_wdLayer.drawing = wdDrawingController.drawing;
//    [wdDrawingController.drawing.layers addObject:m_wdLayer];
//    
//    IMAGE_DATA data = [m_pImageData lockDataForRead];
//    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
//    [m_pImageData unLockDataForRead];
//    
//    [self drawToRawData];
//    
//    [self refreshTotalToRender];
    
    return self;
}

-(void)delayInitWDLayer:(PSVecLayer*)endocerLayer
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
    
    if(m_wdLayer) [m_wdLayer release];
    m_wdLayer =[endocerLayer->m_wdLayer copyWithZone:nil];
    m_wdLayer.layerDelegate = self;
    m_wdLayer.drawing = wdDrawingController.drawing;
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    [self invalidData];
}

- (void)dealloc
{
    if (m_contextData) {CGContextRelease(m_contextData); m_contextData = NULL ;}
    if(m_wdLayer) {[m_wdLayer release]; m_wdLayer = nil;}
    if(m_pathTemp) [m_pathTemp release];
    
    [m_lockMakeTransform release];
    
    [super dealloc];
}

- (void)compress
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if(wdDrawingController.selectedObjects)
        [wdDrawingController.selectedObjects minusSet:[NSSet setWithArray:m_wdLayer.elements]];
    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
    
    [wdDrawingController notifySelectionChanged];
    
  //  [super compress];
    if(m_pLayerRender)
    {
        [m_pLayerRender release];
        m_pLayerRender = nil;
    }
    
    [m_pImageData release];
    m_pImageData = nil;
    
    
    if (m_contextData)
    {
        CGContextRelease(m_contextData);
        m_contextData = NULL ;
    }
    
    return;

}

- (void)refreshTotalToRender
{
    if (m_bIsEffectValid == [self effectFilterIsValid])
    {
        [super refreshTotalToRender];
    }
    else
    {
        m_bIsEffectValid = [self effectFilterIsValid];
        [self invalidData];
    }
}

- (void)decompress
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    [self getRender];
    
    [self invalidData];
    
    return;

}

-(void) invalidData
{
//    SEL sel = @selector(invalidDataDelay);
//    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
//     sel object: nil];
//    [self performSelector: sel withObject: nil afterDelay: 0.05 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    
    [self invalidDataDelay];
}


//真延时的话 一些东西要改掉 如刷新等要跟着延后
-(void) invalidDataDelay
{
    //    if(!m_pathTemp) return;
    //    CGRect rectText = [m_pathTemp styleBounds];
    if(!m_wdLayer) return;
    CGRect rectText = [m_wdLayer styleBounds];
    
    if(!CGRectIsNull(rectText) )
    {
        rectText = CGRectApplyAffineTransform(rectText, m_Transformed);
        
        if ([self effectFilterIsValid])
        {
            rectText = CGRectMake(rectText.origin.x , rectText.origin.y , rectText.size.width , rectText.size.height );
        }
        else
        {
            rectText = CGRectMake(rectText.origin.x, rectText.origin.y, rectText.size.width, rectText.size.height);
        }
        
      //  CGRect rectCurrent = CGRectMake(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
        
      //  if(YES)
        { //CGRectContainsRect(rectCurrent, rectText) == false || !m_contextData
            m_nWidth  = rectText.size.width+2;
            m_nHeight = rectText.size.height+2;
            
            m_nXoff = rectText.origin.x-1;
            m_nYoff = rectText.origin.y-1;
            
            
            [self allocNewRawData:m_nWidth height:m_nHeight spp:m_nSpp opaque:FALSE];
            [self drawToRawData];
            [self refreshTotalToRender];
        }
    }
    else
    {
        m_nWidth  = 0;
        m_nHeight = 0;
      //  [self drawToRawData];
      //  [self refreshTotalToRender];
        
    }
    
    // Destroy the m_imgThumbnail m_pData
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelperForLayer:self];
}




-(void) drawToRawData
{
    if(!m_contextData) return;
    
    CGContextSaveGState(m_contextData);
    
    CGContextSetAllowsAntialiasing(m_contextData, YES);
    CGContextSetShouldAntialias(m_contextData, YES);
    CGContextSetInterpolationQuality(m_contextData, kCGInterpolationHigh);
    
    CGContextClearRect(m_contextData, CGRectMake(0, 0, m_nWidth, m_nHeight));
    
    CGContextTranslateCTM(m_contextData, -m_nXoff, m_nYoff);
    
    CGAffineTransform flip = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, m_nHeight);
    
    CGContextConcatCTM(m_contextData, flip);
    CGContextConcatCTM(m_contextData, m_Transformed);
    
    CGAffineTransform outerTrans = CGAffineTransformIdentity;
//    outerTrans = CGAffineTransformTranslate(outerTrans, -m_nXoff, m_nYoff);
//    outerTrans = CGAffineTransformConcat(outerTrans, flip);
//    outerTrans = CGAffineTransformInvert(outerTrans);
    
    outerTrans.tx = m_nXoff;
    outerTrans.ty = m_nYoff;
    
    for (WDElement *el in m_wdLayer.elements)
    {
        ((WDPath*)el).fillTransform.transform = outerTrans;
    }
    
//    [m_pathTemp renderInContext:m_contextData metaData:WDRenderingMetaDataMake(1.0, WDRenderDefault)];
    [m_wdLayer renderInContext:m_contextData clipRect:CGRectInfinite metaData:WDRenderingMetaDataMake(1.0, WDRenderDefault)];
    
    CGContextRestoreGState(m_contextData);
}

extern CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied);
-  (void)allocNewRawData:(int)nNewWidth height:( int )nNewHeight spp:(int)lspp opaque:(BOOL)opaque
{
    if (m_contextData) {CGContextRelease(m_contextData); m_contextData = NULL ;}
    
    m_nWidth = nNewWidth; m_nHeight = nNewHeight;
    
    m_nSpp  = lspp;
    
    if (m_nWidth <= 0 || m_nHeight <= 0) {
        return;
    }
    
    IMAGE_DATA data = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:true];
    
    if (opaque)
        memset(data.pBuffer, 255, m_nWidth * m_nHeight * m_nSpp);
    else
        memset(data.pBuffer, 0, m_nWidth * m_nHeight * m_nSpp);
    
    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
    
    [m_pImageData unLockDataForWrite];
    
    m_bHasAlpha = !opaque;
    
}

- (void)addPathObject:(id)obj
{
    [m_wdLayer addObject:obj];
    
}

- (void)removePathObject:(id)obj
{
    [m_wdLayer removeObject:obj];
}

-(void)refreshLayer
{
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
}

-(void)setPath:(WDPath *)path
{
    WDPath *pathOld = nil;
    if(m_pathTemp) {pathOld = [m_pathTemp retain];}
    
    if(m_pathTemp) {[m_pathTemp release]; m_pathTemp = nil;}
    if(path) m_pathTemp = [path retain];
    
    [self invalidData];
    
    [(PSVecLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setPath:pathOld];
    if(pathOld) [pathOld release];
}

- (IntRect)localRect
{
    return IntMakeRect(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
/*    CGRect rectText = [m_pathTemp styleBounds];
    rectText = CGRectApplyAffineTransform(rectText, m_Transformed);
    return IntMakeRect(rectText.origin.x, rectText.origin.y, rectText.size.width, rectText.size.height);
*/}

- (void)applyTransform
{
    [m_lockMakeTransform lock];
    
    for (WDElement *el in m_wdLayer.elements)
    {
        [el transformWithoutUndo:m_Transformed];
        //WDFillTransform             *fillTransform = ((WDPath*)el).fillTransform;
        //((WDPath*)el).fillTransform = [fillTransform transform:m_Transformed];
    }
    m_Transformed = CGAffineTransformIdentity;
    
    [self invalidData];
    
     [m_lockMakeTransform unlock];

}

//移动工具使用
- (void)setOffsetsNoTransform:(IntPoint)newOffsets
{
    if(newOffsets.x == m_nXoff && (newOffsets.y == m_nYoff))  return;    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(newOffsets.x - m_nXoff, newOffsets.y - m_nYoff);
    m_Transformed =  CGAffineTransformConcat(m_Transformed, transform);
    m_nXoff = newOffsets.x;
    m_nYoff = newOffsets.y;
    
    //[self invalidData];
    
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    
    renderInfo.flagModifiedType = OFFSET_MODIFIED_ONLY;
    
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_OFFSET];
//    [m_pLayerRender renderDirtyWithOffsetChangedOnly:CGPointMake(m_nXoff, m_nYoff)];
    
}

- (void)setOffsets:(IntPoint)newOffsets
{
    if(newOffsets.x == m_nXoff && (newOffsets.y == m_nYoff))  return;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(newOffsets.x - m_nXoff, newOffsets.y - m_nYoff);
    m_Transformed =  CGAffineTransformConcat(m_Transformed, transform);
    m_nXoff = newOffsets.x;
    m_nYoff = newOffsets.y;
    
   // [m_pLayerRender renderDirtyWithOffsetChangedOnly:CGPointMake(m_nXoff, m_nYoff)];
    //[self invalidData];
       RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
     
     renderInfo.flagModifiedType = OFFSET_MODIFIED_ONLY;
     
     [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_OFFSET];

    //[self applyTransform];
/*    SEL sel = @selector(applyTransform);
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
     sel object: nil];
    [self performSelector: sel withObject: nil afterDelay: 0.5];
 */
}




- (void)flipHorizontally
{
    int nCanvasWidth = [(PSContent *)[m_idDocument contents] width];
    int nCanvasHeight = [(PSContent *)[m_idDocument contents] height];
    
    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = 0;           pointFrom[0].y = 0;
    pointFrom[1].x = nCanvasWidth;           pointFrom[1].y = 0;
    pointFrom[2].x = 0;  pointFrom[2].y = nCanvasHeight;
    
    pointTo[0].x = nCanvasWidth;                   pointTo[0].y = 0;
    pointTo[1].x = 0;        pointTo[1].y = 0;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    pointTo[2].x = nCanvasWidth;   pointTo[2].y = nCanvasHeight;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    [self applyTransform];
    
//    //    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
//    m_nXoff = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
//    [self drawToRawData];
//    
//    [self refreshTotalToRender];
    
}

- (void)flipVertically
{
    int nCanvasWidth = [(PSContent *)[m_idDocument contents] width];
    int nCanvasHeight = [(PSContent *)[m_idDocument contents] height];
    
    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = 0;           pointFrom[0].y = 0;
    pointFrom[1].x = nCanvasWidth;           pointFrom[1].y = 0;
    pointFrom[2].x = 0;  pointFrom[2].y = nCanvasHeight;
    
    pointTo[0].x = 0;                   pointTo[0].y = nCanvasHeight;
    pointTo[1].x = nCanvasWidth;        pointTo[1].y = nCanvasHeight;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    pointTo[2].x = 0;   pointTo[2].y = 0;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    
    [self applyTransform];
    
//    m_nYoff = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
//    [self drawToRawData];
//    [self refreshTotalToRender];
}

- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    float fScaleX =  (float)newWidth / (float)m_nWidth;
    float fScaleY = (float)newHeight / (float)m_nHeight;
    
    CGAffineTransform transform = CGAffineTransformMakeScale(fScaleX, fScaleY);
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    
    [self applyTransform];
    
//    [self invalidData];    
//    transform = CGAffineTransformMakeTranslation((1.0 - fScaleX)*m_nXoff, (1.0 - fScaleY)*m_nYoff);
//    m_Transformed =  CGAffineTransformConcat(m_Transformed, transform);
}

- (void)rotateLeft
{
    int nCanvasWidth = [(PSContent *)[m_idDocument contents] width];
    int nCanvasHeight = [(PSContent *)[m_idDocument contents] height];
    
    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = 0;           pointFrom[0].y = 0;
    pointFrom[1].x = nCanvasWidth;           pointFrom[1].y = 0;
    pointFrom[2].x = nCanvasWidth;  pointFrom[2].y = nCanvasHeight;
    
    pointTo[0].x = 0;   pointTo[0].y = nCanvasWidth;
    pointTo[1].x = 0;            pointTo[1].y = 0;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    pointTo[2].x = nCanvasHeight;   pointTo[2].y = 0;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    
    [self applyTransform];
    
    
//    int oy = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
//    int ox = m_nYoff;
//    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
//    m_nXoff = ox;
//    m_nYoff = oy;
//    [self drawToRawData];
//    
//    [self refreshTotalToRender];
}

- (void)rotateRight
{
    int ox = m_nXoff;
    int oy = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
    
    int nCanvasWidth = [(PSContent *)[m_idDocument contents] width];
    int nCanvasHeight = [(PSContent *)[m_idDocument contents] height];
    
    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = 0;           pointFrom[0].y = nCanvasHeight;
    pointFrom[1].x = 0;           pointFrom[1].y = 0;
    pointFrom[2].x = nCanvasWidth;  pointFrom[2].y = 0;
    
    pointTo[0].x = 0;   pointTo[0].y = 0;
    pointTo[1].x = nCanvasHeight;            pointTo[1].y = 0;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    pointTo[2].x = nCanvasHeight;   pointTo[2].y = nCanvasWidth;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    
    [self applyTransform];
    
//    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
//    m_nXoff = oy;
//    m_nYoff = ox;
//    [self drawToRawData];
//    [self refreshTotalToRender];
}

- (void)trimLayer
{
    return;
}

- (void)setCocoaRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    return;
}

- (void)setCoreImageRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    return;
}

- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    return;
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    return;
}

- (void)setCocoaWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    return;
}


- (void)setCoreImageWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    return;
}

#pragma mark -
-(WDLayer *)getLayer
{
    return m_wdLayer;
}

#pragma mark - Perspective Transform

- (void)concatPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform withReverseTransform:(PSPerspectiveTransform)reversePerspectiveTransform
{
    NSMutableArray *arrElements = m_wdLayer.elements;
    for (int nIndex = 0; nIndex < arrElements.count; nIndex ++)
    {
        WDPath *path = [arrElements objectAtIndex:nIndex];
        [path setPerspectiveTransform:perspectiveTransform];
    }
//    [m_pathTemp setPerspectiveTransform:perspectiveTransform];
    
//    [self invalidData];
//    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] concatPerspectiveTransform:reversePerspectiveTransform withReverseTransform:perspectiveTransform];
}

#pragma mark - transform
- (CGAffineTransform)transform
{
    return m_Transformed;
}

#pragma mark - transform apply
- (void)concatAffineTransform:(CGAffineTransform) transform;
{
    CGAffineTransform newTransform = CGAffineTransformConcat(m_Transformed, transform);
    
    [self changeTransform:newTransform];
}

-(void)changeTransform:(CGAffineTransform) transform;
{
    CGAffineTransform oldTransform = m_Transformed;
    m_Transformed = transform;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSVecLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] changeTransform:oldTransform];
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    // Never if we are told not to
    if ([menuItem tag] >= 10000 && [menuItem tag] < 17500) //filter
    {
        return NO;
    }
    else if([menuItem tag] >= 330 && [menuItem tag] <= 332) //layer scale 、rotate、boundries
    {
        return NO;
    }
    else if([menuItem tag] >= 360 && [menuItem tag] <= 362) //layer trim boundries
    {
        return NO;
    }
    else if([menuItem tag] == 393)                            return NO;        //ConvertToShape
    
    return YES;
}

@end
