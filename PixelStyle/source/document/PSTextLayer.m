#import "PSAbstractLayer.h"
#import "PSTextLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSLayerUndo.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "Bitmap.h"
#import "PSWarning.h"
#import "PSPrefs.h"
#import "PSPlugins.h"
#import "PSHelpers.h"

#import <ApplicationServices/ApplicationServices.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <GIMPCore/GIMPCore.h>
#import "WDLayer.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"
#import "WDText.h"
#import "WDTextPath.h"
#import "WDFontManager.h"
#import "WDColor.h"
#import "NSString+Additions.h"
#import "ThressPointsAffine.h"

static CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied)
{
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

int GetImageBuffer(NSImage *Image, int nWidth, int nHeight, unsigned char *pBufRGBA, int bAlphaPremultiplied)
{
    assert(nil != Image);
    
    bool bUpsideDown = false;
    
    if(nHeight < 0)
    {
        bUpsideDown = false;
        nHeight = - (nHeight);
    }
    
    memset(pBufRGBA, 0, nWidth*nHeight*4);
    CGContextRef context = MyCreateBitmapContext(nWidth , nHeight, pBufRGBA, bAlphaPremultiplied);
    
    assert(nil != context);
    
    CGRect rect=CGRectMake(0,0, nWidth , nHeight);
    
    CGImageRef imageRef = [Image CGImageForProposedRect:nil context:nil hints:nil];
    
    CGContextDrawImage(context, rect, imageRef);
    
    unsigned char *pBuf1 = (unsigned char *)CGBitmapContextGetData(context);
    
    assert(pBuf1 == pBufRGBA);
    
    CGContextRelease(context);
    
    
    if(bUpsideDown)
    {
        unsigned char *pOneLine= (unsigned char *)malloc(nWidth * 4);
        
        for(int y=0; y< nHeight/2; y++)
        {
            memcpy(pOneLine, pBuf1 + y* nWidth * 4, nWidth * 4);
            memcpy(pBuf1 + y* nWidth * 4, pBuf1 + (nHeight -y -1)* nWidth * 4, nWidth * 4);
            memcpy(pBuf1 + (nHeight -y -1)* nWidth * 4, pOneLine, nWidth * 4);
        }
        
        free(pOneLine);
    }
    return 0;
}


@implementation PSTextLayer

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:m_idLastTextObject forKey:@"PSTextObject"];
    
//    NSValue *vlTransform = [NSValue valueWithBytes:&m_Transformed objCType:@encode(CGAffineTransform)];
//    [aCoder encodeObject:vlTransform forKey:@"PSLayerTransform"];
    
    NSValue *pointObj = [NSValue valueWithBytes:&m_pointTextStart objCType:@encode(CGPoint)];
    [aCoder encodeObject:pointObj forKey:@"PSpointTextStart"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    m_idLastTextObject = [aDecoder decodeObjectForKey:@"PSTextObject"];
    
//    NSValue *vlTransform = [aDecoder decodeObjectForKey:@"PSLayerTransform"];
//    [vlTransform getValue:&m_Transformed];
    
    NSValue *vlPoint = [aDecoder decodeObjectForKey:@"PSpointTextStart"];
    [vlPoint getValue:&m_pointTextStart];
    
    return self;
}

 - (id)initWithDocumentAfterCoder:(id)doc layer:(PSTextLayer*)endocerLayer
 {
     // Call the core initializer
     self = [super initWithDocumentAfterCoder:doc layer:endocerLayer];
     //    if (![self initWithDocument:doc])
     //        return NULL;
//     m_idLastTextObject  = endocerLayer->m_idLastTextObject;
//     [m_idLastTextObject retain];
//     
     m_idLastTextObject = [endocerLayer->m_idLastTextObject copyWithZone:nil];
     m_contextData       = nil;
     m_Transformed       = endocerLayer->m_Transformed;
     m_nTextCursorPos    = 0;
     m_pointTextStart    = endocerLayer->m_pointTextStart;
     
     m_enumLayerFormat   = PS_TEXT_LAYER;
     
     [self performSelector:@selector(delayInitWDLayer:) withObject:endocerLayer afterDelay:.5];

     
//     if(!m_wdLayer)
//     {
//         m_wdLayer = [WDLayer layer];
//         [m_wdLayer retain];
//     }
//     
//     [m_wdLayer addObject:m_idLastTextObject];
//     
//     IMAGE_DATA data = [m_pImageData lockDataForRead];
//     m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
//     [m_pImageData unLockDataForRead];
//     
//     [self drawToRawData];
//     
//     [self refreshTotalToRender];
     
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
    
    m_idLastTextObject = [m_wdLayer getLastObject];
    
    if(m_nWidth != 0 && m_nHeight != 0)
    {
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
        [m_pImageData unLockDataForRead];
        
        [self drawToRawData];
    }
    
    [self refreshTotalToRender];
}


- (id)initWithDocument:(id)doc
{
    self = [super initWithDocument:doc];
    
    m_wdLayer = [WDLayer layer];
    [m_wdLayer retain];
    
    m_idLastTextObject  = nil;
    m_contextData       = nil;
    m_Transformed       = CGAffineTransformIdentity;
    m_nTextCursorPos    = 0;
    m_pointTextStart    = CGPointMake(10, 10);
    
    m_enumLayerFormat   = PS_TEXT_LAYER;
    
    return self;
}

- (void)setTextInfo:(WDTextPath *)textObject
{
    if(m_idLastTextObject != textObject)
    {
        if(m_idLastTextObject != nil)  [m_wdLayer removeObject:m_idLastTextObject];
        [m_wdLayer addObject:textObject];
        
        m_idLastTextObject = textObject;
    }
    [self invalidData];
    
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
}



- (void) createTextObjectWithTextAtPath:(NSString *)string atPoint:(CGPoint) pointStart
{
    
    WDTextPath      *typePath = nil;
    
  //  WDPath *pathRect2 = [WDPath pathWithStart:CGPointMake(0, 0) end:CGPointMake(2000, 0)];
    WDPath *pathRect2 = [WDPath pathWithStart:CGPointMake(pointStart.x, pointStart.y) end:CGPointMake(pointStart.x+2000, pointStart.y)];////
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    WDStrokeStyle *stroke = [propertyManager activeStrokeStyle];
    
    pathRect2.strokeStyle   = [stroke strokeStyleSansArrows];
    pathRect2.fill          = [propertyManager activeFillStyle];
    pathRect2.opacity       = 0.9;//[[propertyManager defaultValueForProperty:WDOpacityProperty] floatValue];
    pathRect2.shadow        = [propertyManager activeShadow];
    
    typePath                = [WDTextPath textPathWithPath:pathRect2];
    
    [typePath setBaseBounds:CGRectMake(pointStart.x, pointStart.y, 1000, 500)];
    
    [typePath setBlinkCursor:2 batvie:NO];
    CUSTOM_TRANSFORM transformCustom1 = {0, 0, 0, 0, 0};
    typePath.transformCustom        =  transformCustom1;
    typePath.text                   = string;
    NSString *fontName              = [[WDFontManager sharedInstance] defaultFontForFamily:@"Arial"];
    typePath.fontName               = fontName;//[propertyManager defaultValueForProperty:WDFontNameProperty];
    typePath.fontSize               = 40;//[[propertyManager defaultValueForProperty:WDFontSizeProperty] floatValue];
    typePath.fill                   = [WDColor colorWithRed:1.0 green:0.62 blue:0.11 alpha:1.0];//[propertyManager defaultFillStyle];
    typePath.fillTransform          = pathRect2.fillTransform;
    typePath.shadow                 = nil;//pathRect2.shadow;
    typePath.opacity                = 1.0;//pathRect2.opacity;
    typePath.blendMode              =  kCGBlendModeCopy;
    typePath.strokeStyle            = nil;/*[WDStrokeStyle strokeStyleWithWidth:0
                                
                                cap:0
                                join:1
                                color:[WDColor colorWithRed:1.0 green:0.62 blue:0.11 alpha:1.0];
                                dashPattern:nil];*/

    if(m_idLastTextObject != nil)
        [m_wdLayer removeObject:m_idLastTextObject];
    [m_wdLayer addObject:typePath];
    m_idLastTextObject = typePath;
    
    //  [self invalidData];
    
}

-(void) invalidData
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    [textPath styleBounds]; //重新计算bounds
    CGRect rectText = [textPath textBounds];
    
    if (rectText.size.width <= 0 || rectText.size.height <= 0) {
        rectText = CGRectMake(m_pointTextStart.x, m_pointTextStart.y, 1, 1);
    }

    
    rectText = CGRectApplyAffineTransform(rectText, m_Transformed);
  
//    if ([self effectFilterIsValid]) {
//        rectText = CGRectMake(rectText.origin.x - 200, rectText.origin.y - 200, rectText.size.width + 400, rectText.size.height + 400);
//    }else{
//        rectText = CGRectMake(rectText.origin.x, rectText.origin.y, rectText.size.width  + 0, rectText.size.height  + 0);
//    }
    
    rectText = CGRectMake(rectText.origin.x , rectText.origin.y , rectText.size.width  , rectText.size.height  );
   
    
    CGRect rectCurrent = CGRectMake(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
    
    if(YES)
    { //CGRectContainsRect(rectCurrent, rectText) == false
        m_nWidth  = rectText.size.width+2;
        m_nHeight = rectText.size.height+2;
        
        m_nXoff = rectText.origin.x-1;
        m_nYoff = rectText.origin.y-1;
        
        //NSLog(@"CGRectContainsRect1");
        
        [self allocNewRawData:m_nWidth height:m_nHeight spp:m_nSpp opaque:FALSE];
        [self drawToRawData];
        [self refreshTotalToRender];
        //NSLog(@"CGRectContainsRect2");
    }
    else
    {
        [self drawToRawData];
        [self refreshTotalToRender];
        
    }
}


-(void) drawToRawData
{
    
    CGContextSaveGState(m_contextData);
    
    CGContextSetShouldAntialias(m_contextData, YES);
    CGContextSetInterpolationQuality(m_contextData, kCGInterpolationHigh);
    
    CGContextClearRect(m_contextData, CGRectMake(0, 0, m_nWidth, m_nHeight));
  
    CGContextTranslateCTM(m_contextData, -m_nXoff, m_nYoff);
    
  //  CGContextTranslateCTM(m_contextData, 201, -201);
    CGAffineTransform flip = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, m_nHeight);
    
    CGContextConcatCTM(m_contextData, flip);
    CGContextConcatCTM(m_contextData, m_Transformed);
    
   // CGRect rect = CGRectApplyAffineTransform(CGRectMake(m_nXoff, m_nYoff, m_nWidth, m_nHeight), m_Transformed);
   // CGContextBeginTransparencyLayer(m_contextData, NULL);
    [m_wdLayer renderInContext:m_contextData clipRect:CGRectInfinite metaData:WDRenderingMetaDataMake(1.0, WDRenderDefault)];
  //  CGContextEndTransparencyLayer(m_contextData);
  //    CGContextStrokePath(m_contextData);
    
    CGContextRestoreGState(m_contextData);
}

-  (void)allocNewRawData:(int)nNewWidth height:( int )nNewHeight spp:(int)lspp opaque:(BOOL)opaque
{
    //  if(m_pData) free(m_pData);
    if (m_contextData) {CGContextRelease(m_contextData); m_contextData = NULL ;}
    
    m_nWidth = nNewWidth; m_nHeight = nNewHeight;
    
    m_nSpp  = lspp;
    
    IMAGE_DATA data = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:true];
    
    if (opaque)
        memset(data.pBuffer, 255, m_nWidth * m_nHeight * m_nSpp);
    else
        memset(data.pBuffer, 0, m_nWidth * m_nHeight * m_nSpp);
    
    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
    
    [m_pImageData unLockDataForWrite];
    
    m_bHasAlpha = !opaque;
    
}

-  (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp
{
    self = [super initWithDocument:doc width:lwidth height:lheight opaque:opaque spp:lspp];
    
    return self;
}

-  (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp  atPoint:(CGPoint)pointStart
{
    self = [super initWithDocument:doc width:lwidth height:lheight opaque:opaque spp:lspp];
    
    m_enumLayerFormat = PS_TEXT_LAYER;

//    IMAGE_DATA data = [m_pImageData lockDataForRead];
//    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
//    [m_pImageData unLockDataForRead];
    // Remember the alpha situation
    m_bHasAlpha = !opaque;
    
    m_nXoff = m_nYoff = m_nWidth = m_nHeight = 0;
    
    m_pointTextStart = pointStart;
    [self createTextObjectWithTextAtPath:@" " atPoint:pointStart];
    [self invalidData];
    
   // [self createCGLayer];
    [self refreshTotalToRender];
  //  [self updateFullDataWithFilterAfterDataChangeInRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)];

    return self;
}

- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp
{
    return nil;
}

- (id)initWithDocument:(id)doc layer:(PSTextLayer*)layer
{
    self = [super initWithDocument:doc layer:(PSVecLayer *)layer];
    
//    m_idLastTextObject  = layer->m_idLastTextObject;
//    [m_idLastTextObject retain];
    
    //[self createTextObjectWithTextAtPath:@" " atPoint:layer->m_pointTextStart];
    
//    m_idLastTextObject = [layer->m_idLastTextObject copyWithZone:nil];
//    m_contextData       = nil;
//    m_Transformed       = layer->m_Transformed;
    m_nTextCursorPos    = layer->m_nTextCursorPos;
    m_pointTextStart    = layer->m_pointTextStart;
    
    m_enumLayerFormat   = PS_TEXT_LAYER;
    
//    if(!m_wdLayer)
//    {
//        m_wdLayer = [WDLayer layer];
//        [m_wdLayer retain];
//    }
//    [m_wdLayer addObject:m_idLastTextObject];
//    
//    IMAGE_DATA data = [m_pImageData lockDataForRead];
//    m_contextData = MyCreateBitmapContext(m_nWidth , m_nHeight, data.pBuffer, true);
//    [m_pImageData unLockDataForRead];
    
    m_idLastTextObject = [m_wdLayer getLastObject];
    
    //[self drawToRawData];
    [self invalidData];
    
    [self refreshTotalToRender];
    
    return self;
    
}

- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata
{
    return nil;

}

- (void)dealloc
{
    if (m_contextData) {CGContextRelease(m_contextData); m_contextData = NULL ;}
    if(m_wdLayer) {[m_wdLayer release]; m_wdLayer = nil;}

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
    
 //   [super compress];
    return;
    /*
     FILE *file;
     
     // If the image data is not already compressed
     if (m_pData)
     {
     
     // Do a check of the disk space
     if ([m_idPSLayerUndo checkDiskSpace])
     {
     
     // Open a file for writing the memory cache
     file = fopen([m_strUndoFilePath fileSystemRepresentation], "w");
     
     // Check we have a valid file handle
     if (file != NULL)
     {
     
     // Write the image data to disk
     fwrite(m_pData, sizeof(char), m_nWidth * m_nHeight * m_nSpp, file);
     
     // Close the memory cache
     fclose(file);
     
     // Free the memory currently occupied the document's data
     free(m_pData);
     m_pData = NULL;
     
     }
     
     // Get rid of the m_imgThumbnail
     if (m_imgThumbnail) [m_imgThumbnail autorelease];
     if (m_pThumbData) free(m_pThumbData);
     m_imgThumbnail = NULL; m_pThumbData = NULL;
     
     }
     
     }*/
}

- (void)decompress
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    [self getRender];
   
    [self invalidData];
    
}

- (id)document
{
    return m_idDocument;
}

- (int)width
{
    return m_nWidth;
}

- (int)height
{
    return m_nHeight;
}

- (int)xoff
{
    return m_nXoff;
}

- (int)yoff
{
    return m_nYoff;
}

- (IntRect)localRect
{
    return IntMakeRect(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
}

- (void)setOffsets:(IntPoint)newOffsets
{
    //if(newOffsets.x == m_nXoff && (newOffsets.y == m_nYoff))  return;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(newOffsets.x - m_nXoff, newOffsets.y - m_nYoff);
    m_Transformed =  CGAffineTransformConcat(m_Transformed, transform);
    m_nXoff = newOffsets.x;
    m_nYoff = newOffsets.y;

   [self invalidData];
    
//    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
//    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_PREVIEW];
}

- (void)trimLayer
{
    return;
    /*
     int i, j;
     int left, right, top, bottom;
     
     // Start out with invalid content borders
     left = right = top = bottom =  -1;
     
     // Determine left content margin
     for (i = 0; i < m_nWidth && left == -1; i++)
     {
     for (j = 0; j < m_nHeight && left == -1; j++)
     {
     if (m_pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
     {
     left = i;
     }
     }
     }
     
     // Determine right content margin
     for (i = m_nWidth - 1; i >= 0 && right == -1; i--)
     {
     for (j = 0; j < m_nHeight && right == -1; j++)
     {
     if (m_pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
     {
     right = m_nWidth - 1 - i;
     }
     }
     }
     
     // Determine top content margin
     for (j = 0; j < m_nHeight && top == -1; j++)
     {
     for (i = 0; i < m_nWidth && top == -1; i++)
     {
     if (m_pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
     {
     top = j;
     }
     }
     }
     
     // Determine bottom content margin
     for (j = m_nHeight - 1; j >= 0 && bottom == -1; j--)
     {
     for (i = 0; i < m_nWidth && bottom == -1; i++)
     {
     if (m_pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
     {
     bottom = m_nHeight - 1 - j;
     }
     }
     }
     
     // Make the change
     if (left != 0 || top != 0 || right != 0 || bottom != 0)
     [self setMarginLeft:-left top:-top right:-right bottom:-bottom];
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
    
//    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
    m_nXoff = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    [self drawToRawData];
    
    [self refreshTotalToRender];
    
//    m_nXoff = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    return;

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

    m_nYoff = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
//    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];

    [self drawToRawData];
    
    [self refreshTotalToRender];
    
//    m_nYoff = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
}

- (void)rotateLeft
{

/*    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = m_nXoff;           pointFrom[0].y = m_nYoff+m_nHeight;
    pointFrom[1].x = m_nXoff;           pointFrom[1].y = m_nYoff;
    pointFrom[2].x = m_nXoff+m_nWidth;  pointFrom[2].y = m_nYoff;
   
    pointTo[0].x = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;   pointTo[0].y = m_nXoff;
    pointTo[1].x = pointTo[0].x+m_nHeight;            pointTo[1].y = m_nXoff;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    
    pointTo[2].x = pointTo[0].x+m_nHeight;   pointTo[2].y = m_nXoff+m_nWidth;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    m_Transformed = CGAffineTransformConcat(transform, m_Transformed);*/
    
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
    
    int oy = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    int ox = m_nYoff;
    
    
    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
    
    m_nXoff = ox;
    m_nYoff = oy;
    [self drawToRawData];
    
    [self refreshTotalToRender];
}

- (void)rotateRight
{
/*
    CGPoint pointFrom[3];
    CGPoint pointTo[3];
    
    pointFrom[0].x = m_nXoff;           pointFrom[0].y = m_nYoff;
    pointFrom[1].x = m_nXoff;           pointFrom[1].y = m_nYoff+m_nHeight;
    pointFrom[2].x = m_nXoff+m_nWidth;  pointFrom[2].y = m_nYoff+m_nHeight;
    
    pointTo[0].x = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;   pointTo[0].y = m_nXoff;
    pointTo[1].x = pointTo[0].x+m_nHeight;            pointTo[1].y = m_nXoff;//[(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    
    pointTo[2].x = pointTo[0].x+m_nHeight;   pointTo[2].y = m_nXoff+m_nWidth;
    
    CGAffineTransform transform = GetTransformPoints3(pointFrom, pointTo);
    m_Transformed = CGAffineTransformConcat(transform, m_Transformed);
   */
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
    
//    m_Transformed = CGAffineTransformTranslate(m_Transformed, nCanvasWidth/2.0, nCanvasHeight/2.0);
//    m_Transformed = CGAffineTransformRotate(m_Transformed, M_PI/2.0);
//    m_Transformed = CGAffineTransformTranslate(m_Transformed, -nCanvasHeight/2.0, -nCanvasWidth/2.0);
    
    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];

    m_nXoff = oy;
    m_nYoff = ox;
    
    [self drawToRawData];
  
    [self refreshTotalToRender];
}

- (void)setCocoaRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    return;
    /*
     NSAffineTransform *at, *tat;
     unsigned char *srcData;
     NSImage *image_out;
     NSBitmapImageRep *in_rep, *final_rep;
     NSPoint point[4], minPoint, maxPoint, transformPoint;
     int i, oldHeight, oldWidth;
     int ispp, bipp, bypr, ispace, ibps;
     
     // Define the rotation
     at = [NSAffineTransform transform];
     [at rotateByDegrees:degrees];
     
     // Determine the input image
     premultiplyBitmap(m_nSpp, m_pData, m_pData, m_nWidth * m_nHeight);
     in_rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
     
     // Determine the output size
     point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
     point[1] = [at transformPoint:NSMakePoint(m_nWidth, 0.0)];
     point[2] = [at transformPoint:NSMakePoint(0.0, m_nHeight)];
     point[3] = [at transformPoint:NSMakePoint(m_nWidth, m_nHeight)];
     minPoint = point[0];
     for (i = 0; i < 4; i++) {
     if (point[i].x < minPoint.x)
     minPoint.x = point[i].x;
     if (point[i].y < minPoint.y)
     minPoint.y = point[i].y;
     }
     maxPoint = point[0];
     for (i = 0; i < 4; i++) {
     if (point[i].x > maxPoint.x)
     maxPoint.x = point[i].x;
     if (point[i].y > maxPoint.y)
     maxPoint.y = point[i].y;
     }
     oldWidth = m_nWidth;
     oldHeight = m_nHeight;
     m_nWidth = ceilf(maxPoint.x - minPoint.x);
     m_nHeight = ceilf(maxPoint.y - minPoint.y);
     m_nXoff += oldWidth / 2 - m_nWidth / 2;
     m_nYoff += oldHeight / 2 - m_nHeight / 2;
     
     // Determine the output image
     image_out = [[NSImage alloc] initWithSize:NSMakeSize(m_nWidth, m_nHeight)];
     [image_out setCachedSeparately:YES];
     [image_out recache];
     [image_out lockFocus];
     
     // Work out full transform
     tat = [NSAffineTransform transform];
     transformPoint.x = -minPoint.x;
     transformPoint.y = -minPoint.y;
     [tat translateXBy:transformPoint.x yBy:transformPoint.y];
     [at appendTransform:tat];
     
     [[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
     [[NSAffineTransform transform] set];
     [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)] setClip];
     [at set];
     [in_rep drawAtPoint:NSMakePoint(0.0, 0.0)];
     [[NSAffineTransform transform] set];
     final_rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, m_nWidth, m_nHeight)];
     [image_out unlockFocus];
     
     // Start clean up
     [in_rep autorelease];
     free(m_pData);
     
     // Make the swap
     srcData = [final_rep bitmapData];
     ispp = [final_rep samplesPerPixel];
     bipp = [final_rep bitsPerPixel];
     bypr = [final_rep bytesPerRow];
     ispace = (ispp > 2) ? kRGBColorSpace : kGrayColorSpace;
     ibps = [final_rep bitsPerPixel] / [final_rep samplesPerPixel];
     m_pData = convertBitmap(m_nSpp, (m_nSpp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcData, m_nWidth, m_nHeight, ispp, bipp, bypr, ispace, NULL, ibps, 0);
     
     // Clean up
     [final_rep autorelease];
     [image_out autorelease];
     unpremultiplyBitmap(m_nSpp, m_pData, m_pData, m_nWidth * m_nHeight);
     
     // Make margin changes
     if (trim) [self trimLayer];*/
}

- (void)setCoreImageRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    return;
    /*
     unsigned char *newData;
     NSAffineTransform *at;
     int newWidth, newHeight, i;
     NSPoint point[4], minPoint, maxPoint;
     
     // Determine affine transform
     at = [NSAffineTransform transform];
     [at rotateByDegrees:degrees];
     
     // Determine the output size
     point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
     point[1] = [at transformPoint:NSMakePoint(m_nWidth, 0.0)];
     point[2] = [at transformPoint:NSMakePoint(0.0, m_nHeight)];
     point[3] = [at transformPoint:NSMakePoint(m_nWidth, m_nHeight)];
     minPoint = point[0];
     for (i = 0; i < 4; i++) {
     if (point[i].x < minPoint.x)
     minPoint.x = point[i].x;
     if (point[i].y < minPoint.y)
     minPoint.y = point[i].y;
     }
     maxPoint = point[0];
     for (i = 0; i < 4; i++) {
     if (point[i].x > maxPoint.x)
     maxPoint.x = point[i].x;
     if (point[i].y > maxPoint.y)
     maxPoint.y = point[i].y;
     }
     newWidth = ceilf(maxPoint.x - minPoint.x);
     newHeight = ceilf(maxPoint.y - minPoint.y);
     
     // Run the transform
     newData = [m_idAffinePlugin runAffineTransform:at withImage:m_pData spp:m_nSpp width:m_nWidth height:m_nHeight opaque:NO newWidth:&newWidth newHeight:&newHeight];
     
     // Replace the old bitmap with the new bitmap
     free(m_pData);
     m_pData = newData;
     m_nXoff += m_nWidth / 2 - newWidth / 2;
     m_nYoff += m_nHeight / 2 - newHeight / 2;
     m_nWidth = newWidth; m_nHeight = newHeight;
     
     // Destroy the m_imgThumbnail m_pData
     if (m_imgThumbnail) [m_imgThumbnail autorelease];
     if (m_pThumbData) free(m_pThumbData);
     m_imgThumbnail = NULL; m_pThumbData = NULL;
     
     // Make margin changes
     if (trim) [self trimLayer];*/
}


- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
//    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI * degrees/180);
//    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
//    
//    [self allocNewRawData:m_nHeight height:m_nWidth spp:m_nSpp opaque:FALSE];
//    
////    m_nXoff = oy;
////    m_nYoff = ox;
//    
//    [self drawToRawData];
//    
//    [self refreshTotalToRender];
    
    
    
    return;
    /*
     if (m_idAffinePlugin && [[PSController m_idPSPrefs] useCoreImage]) {
     [self setCoreImageRotation:degrees interpolation:interpolation withTrim:trim];
     }
     else {
     [self setCocoaRotation:degrees interpolation:interpolation withTrim:trim];
     }*/
}

- (BOOL)visible
{
    return m_bVisible;
}

- (void)setVisible:(BOOL)value
{
    m_bVisible = value;
}

- (BOOL)locked
{
    return m_bLockd;
}

- (BOOL)linked
{
    return m_bLinked;
}

- (void)setLinked:(BOOL)value
{
    m_bLinked = value;
}

- (int)opacity
{
    return m_nOpacity;
}

- (void)setOpacity:(int)value
{
    m_nOpacity = value;
}

-(int)spp
{
    return m_nSpp;
}

- (int)mode
{
    return m_nMode;
}

- (void)setMode:(int)value
{
    m_nMode = value;
}

- (NSString *)name
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSString *textOld = textPath.text;
    return textOld;
    
//    return m_strName;
}

- (void)setName:(NSString *)newName
{
    if (m_strName) {
        [m_arrOldNames autorelease];
        m_arrOldNames = [m_arrOldNames arrayByAddingObject:m_strName];
        [m_arrOldNames retain]; [m_strName autorelease];
        m_strName = newName;
        [m_strName retain];
    }
}



- (void)toggleAlpha
{
    // Do nothing if we can't do anything
    if (![self canToggleAlpha])
        return;
    
    // Change the alpha channel treatment
    m_bHasAlpha = !m_bHasAlpha;
    
    // Update the Pegasus utility
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] toggleAlpha];
}

- (void)introduceAlpha
{
    m_bHasAlpha = YES;
}

- (BOOL)canToggleAlpha
{
    return NO;
    /*  int i;
     
     if (m_bFloating)
     return NO;
     
     if (m_bHasAlpha) {
     for (i = 0; i < m_nWidth * m_nHeight; i++) {
     if (m_pData[(i + 1) * m_nSpp - 1] != 255)
     return NO;
     }
     }
     
     return YES;*/
}

- (char *)lostprops
{
    return m_pLostprops;
}

- (int)lostprops_len
{
    return m_nLostpropsLen;
}

- (int)uniqueLayerID
{
    return m_nUniqueLayerID;
}

- (int)index
{
    int i;
    
    for (i = 0; i < [[m_idDocument contents] layerCount]; i++) {
        if ([[m_idDocument contents] layer:i] == self)
            return i;
    }
    
    return -1;
}

- (BOOL)floating
{
    return m_bFloating;
}

- (id)seaLayerUndo
{
    return m_idPSLayerUndo;
}

- (NSImage *)thumbnail
{
    NSBitmapImageRep *tempRep;
    
    // Check if we need an update
    if (m_pThumbData == NULL)
    {
        
        // Determine the size for the image
        m_nThumbWidth = m_nWidth; m_nThumbHeight = m_nHeight;
        if (m_nWidth > 40 || m_nHeight > 32)
        {
            if ((float)m_nWidth / 40.0 > (float)m_nHeight / 32.0)
            {
                m_nThumbHeight = (int)((float)m_nHeight * (40.0 / (float)m_nWidth));
                m_nThumbWidth = 40;
            }
            else
            {
                m_nThumbWidth = (int)((float)m_nWidth * (32.0 / (float)m_nHeight));
                m_nThumbHeight = 32;
            }
        }
        if(m_nThumbWidth <= 0)
        {
            m_nThumbWidth = 1;
        }
        if(m_nThumbHeight <= 0)
        {
            m_nThumbHeight = 1;
        }
        // Create the thumbnail
        m_pThumbData = malloc(m_nThumbWidth * m_nThumbHeight * m_nSpp);
        
        // Determine the thumbnail data
        [self updateThumbnail];
        
    }
    
    // Create the representation
    tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pThumbData pixelsWide:m_nThumbWidth pixelsHigh:m_nThumbHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nThumbWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
    
    // Wrap it up in an NSImage
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    m_imgThumbnail = [[NSImage alloc] initWithSize:NSMakeSize(m_nThumbWidth, m_nThumbHeight)];
    [m_imgThumbnail addRepresentation:tempRep];
    [tempRep autorelease];
    
    return m_imgThumbnail;
}

- (void)updateThumbnail
{
    float horizStep, vertStep;
    int i, j, k, temp;
    int srcPos, destPos;
    
    if (m_pThumbData)
    {
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        unsigned char *pData = data.pBuffer;
        
        // Determine the thumbnail data
        horizStep = (float)m_nWidth / (float)m_nThumbWidth;
        vertStep = (float)m_nHeight / (float)m_nThumbHeight;
        for (j = 0; j < m_nThumbHeight; j++)
        {
            for (i = 0; i < m_nThumbWidth; i++)
            {
                srcPos = ((int)(j * vertStep) * m_nWidth + (int)(i * horizStep)) * m_nSpp;
                destPos = (j * m_nThumbWidth + i) * m_nSpp;
                
                if (pData[srcPos + (m_nSpp - 1)] == 255)
                {
                    for (k = 0; k < m_nSpp; k++)
                        m_pThumbData[destPos + k] = pData[srcPos + k];
                }
                else if (pData[srcPos + (m_nSpp - 1)] == 0)
                {
                    for (k = 0; k < m_nSpp; k++)
                        m_pThumbData[destPos + k] = 0;
                }
                else
                {
                    for (k = 0; k < m_nSpp - 1; k++)
                        m_pThumbData[destPos + k] = int_mult(pData[srcPos + k], pData[srcPos + (m_nSpp - 1)], temp);
                    m_pThumbData[destPos + (m_nSpp - 1)] = pData[srcPos + (m_nSpp - 1)];
                }
            }
        }
        
        [m_pImageData unLockDataForRead];
    }
}

- (NSData *)TIFFRepresentation
{
    return nil;
    /*  NSBitmapImageRep *imageRep;
     NSData *imageTIFFData;
     unsigned char *pmImageData;
     int i, j, tspp;
     
     // Allocate room for the premultiplied image data
     if (m_bHasAlpha)
     pmImageData = malloc(m_nWidth * m_nHeight * m_nSpp);
     else
     pmImageData = malloc(m_nWidth * m_nHeight * (m_nSpp - 1));
     
     // If there is an alpha channel...
     if (m_bHasAlpha) {
     
     // Formulate the premultiplied data from the data
     premultiplyBitmap(m_nSpp, pmImageData, m_pData, m_nWidth * m_nHeight);
     
     }
     else {
     
     // Strip the alpha channel
     for (i = 0; i < m_nWidth * m_nHeight; i++) {
     for (j = 0; j < m_nSpp - 1; j++) {
     pmImageData[i * (m_nSpp - 1) + j] = m_pData[i * m_nSpp + j];
     }
     }
     
     }
     
     // Then create the representation
     tspp = (m_bHasAlpha ? m_nSpp : m_nSpp - 1);
     imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pmImageData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:tspp hasAlpha:m_bHasAlpha isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * tspp bitsPerPixel:8 * tspp];
     
     // Work out the image data
     imageTIFFData = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:255];
     
     // Release the representation and the image data
     [imageRep autorelease];
     free(pmImageData);
     
     return imageTIFFData;*/
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    return;
    /*    unsigned char *newImageData;
     int i, j, k, destPos, srcPos, newWidth, newHeight;
     
     // Allocate an appropriate amount of memory for the new bitmap
     newWidth = m_nWidth + left + right;
     newHeight = m_nHeight + top + bottom;
     newImageData = malloc(make_128(newWidth * newHeight * m_nSpp));
     // do_128_clean(newImageData, make_128(newWidth * newHeight * m_nSpp));
     
     // Fill the new bitmap with the appropriate values
     for (j = 0; j < newHeight; j++)
     {
     for (i = 0; i < newWidth; i++)
     {
     
     destPos = (j * newWidth + i) * m_nSpp;
     
     if (i < left || i >= left + m_nWidth || j < top || j >= top + m_nHeight)
     {
     if (!m_bHasAlpha) { for (k = 0; k < m_nSpp; k++) newImageData[destPos + k] = 255; }
     else { for (k = 0; k < m_nSpp; k++) newImageData[destPos + k] = 0; }
     }
     else
     {
     srcPos = ((j - top) * m_nWidth + (i - left)) * m_nSpp;
     for (k = 0; k < m_nSpp; k++)
     newImageData[destPos + k] = m_pData[srcPos + k];
     }
     
     }
     }
     
     // Replace the old bitmap with the new bitmap
     free(m_pData);
     m_pData = newImageData;
     m_nWidth = newWidth; m_nHeight = newHeight;
     m_nXoff -= left; m_nYoff -= top;
     
     // Destroy the thumbnail data
     if (m_imgThumbnail) [m_imgThumbnail autorelease];
     if (m_pThumbData) free(m_pThumbData);
     m_imgThumbnail = NULL; m_pThumbData = NULL;*/
}


- (void)setCocoaWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    /*  unsigned char *newData;
     
     // Allocate an appropriate amount of memory for the new bitmap
     newData = malloc(make_128(newWidth * newHeight * m_nSpp));
     
     // Do the scale
     GCScalePixels(newData, newWidth, newHeight, m_pData, m_nWidth, m_nHeight, interpolation, m_nSpp);
     
     // Replace the old bitmap with the new bitmap
     free(m_pData);
     m_pData = newData;
     m_nWidth = newWidth; m_nHeight = newHeight;
     
     // Destroy the thumbnail data
     if (m_imgThumbnail) [m_imgThumbnail autorelease];
     if (m_pThumbData) free(m_pThumbData);
     m_imgThumbnail = NULL; m_pThumbData = NULL;
     */
    return;
}


- (void)setCoreImageWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    /*   unsigned char *newData;
     NSAffineTransform *at;
     
     // Determine affine transform
     at = [NSAffineTransform transform];
     [at scaleXBy:(float)newWidth / (float)m_nWidth yBy:(float)newHeight / (float)m_nHeight];
     
     // Run the transform
     newData = [m_idAffinePlugin runAffineTransform:at withImage:m_pData spp:m_nSpp width:m_nWidth height:m_nHeight opaque:!m_bHasAlpha newWidth:&newWidth newHeight:&newHeight];
     
     // Replace the old bitmap with the new bitmap
     free(m_pData);
     m_pData = newData;
     m_nWidth = newWidth; m_nHeight = newHeight;
     
     // Destroy the thumbnail data
     if (m_imgThumbnail) [m_imgThumbnail autorelease];
     if (m_pThumbData) free(m_pThumbData);
     
     m_imgThumbnail = NULL; m_pThumbData = NULL;
     */return;
}


- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    float fScaleX =  (float)newWidth / (float)m_nWidth;
    float fScaleY = (float)newHeight / (float)m_nHeight;
    
    CGAffineTransform transform = CGAffineTransformMakeScale(fScaleX, fScaleY);
    m_Transformed = CGAffineTransformConcat(m_Transformed, transform);
    
//    m_Transformed = CGAffineTransformScale(m_Transformed, (float)newWidth / (float)m_nWidth, (float)newHeight / (float)m_nHeight);
//  //  m_nXoff = m_nXoff*newWidth / m_nWidth;
//  //  m_nYoff = m_nYoff*newHeight / m_nHeight;
//    m_Transformed = CGAffineTransformTranslate(m_Transformed, (1.0 - (float)newWidth / (float)m_nWidth)*m_nXoff, (1.0 - (float)newHeight / (float)m_nHeight)*m_nYoff);

   // [self allocNewRawData:newWidth height:newHeight spp:m_nSpp opaque:FALSE];
    
    [self invalidData];
    
    transform = CGAffineTransformMakeTranslation((1.0 - fScaleX)*m_nXoff, (1.0 - fScaleY)*m_nYoff);
    m_Transformed =  CGAffineTransformConcat(m_Transformed, transform);
    
//    m_Transformed = CGAffineTransformTranslate(m_Transformed, (1.0 - fScaleX)*m_nXoff, (1.0 - fScaleY)*m_nYoff);

    // The issue here is it looks like we're not smart enough to pass anything
    // to the affine plugin besides cubic, so if we're not cupbic we have to use cocoa
    /*	if (m_idAffinePlugin && [[PSController m_idPSPrefs] useCoreImage] && interpolation == GIMP_INTERPOLATION_CUBIC) {
     [self setCoreImageWidth:newWidth height:newHeight interpolation:interpolation];
     }
     else {
     [self setCocoaWidth:newWidth height:newHeight interpolation:interpolation];
     }
     */
}

- (void)convertFromType:(int)srcType to:(int)destType
{
    [super convertFromType:srcType to:destType];
}

- (NSRect)getValidRect
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSRect glyphRect = CGRectNull;
    
    if(textPath)
    {
        glyphRect = NSRectFromCGRect([textPath textBounds]);
//        glyphRect = CGRectApplyAffineTransform(glyphRect, m_Transformed);//在这里若文字旋转下，得到的rect会很大，不是文字真是边界的rect
    }
    
    if (CGRectIsNull(glyphRect)) {
        glyphRect = NSMakeRect(m_pointTextStart.x - 20, m_pointTextStart.y - 20, 40, 40);
    }
    glyphRect.origin.x -= 10;
    glyphRect.size.width += 20;
    
    
    return glyphRect;
}

- (NSString *)getText
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.text;
    
}

-(void)textCursorPosChanged:(int)nIndex
{
    m_nTextCursorPos = nIndex;
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}

-(void)textChanged:(NSString *)text
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSString *textOld = textPath.text;
    [textOld retain];
    textPath.text = text;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] textChanged:textOld];
    [textOld release];
}

-(void)textSelectedChanged:(NSRange)rangeSelect
{
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSRect glyphRect = CGRectNull;
    
    if(textPath)
    {
        glyphRect = NSRectFromCGRect([textPath styleBounds]);
        
    }
    
    return glyphRect;
    
}

static CGFloat  minDistanceToRect(CGPoint point, CGRect rect)
{
    CGPoint pointRect[] = {rect.origin,
        {rect.origin.x, rect.origin.y+rect.size.height},
        {rect.origin.x+rect.size.width, rect.origin.y},
        {rect.origin.x+rect.size.width, rect.origin.y+rect.size.height}};
    CGFloat  fDistance = 10000000000.0f;
    for(int i=0; i<4; i++)
    {
        float fDist = ((point.x - pointRect[i].x)*(point.x - pointRect[i].x) + (point.y - pointRect[i].y)*(point.y - pointRect[i].y));
        if(fDist < fDistance)
            fDistance = fDist;
    }
    
    return fDistance;
    
}


//- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint
//{
//    CGPoint cgPoint = NSPointToCGPoint(aPoint);
//    CGAffineTransform transformInvert = CGAffineTransformInvert(m_Transformed);
//    CGPoint pointTransformInvert = CGPointApplyAffineTransform(cgPoint, transformInvert);
//    
//    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
//    CGFloat  fDistance = 10000000000.0f;
//    int  nIndex = 0;
//    
//    for(int i=0; i< textPath.text.length; i++)
//    {
//        CGRect rect = [textPath getBoundRectForCharacter:i];
//        CGFloat fDist = minDistanceToRect(pointTransformInvert, rect);
//        if(fDistance > fDist)
//        {
//            fDistance = fDist;
//            nIndex = i;
//        }
//    }
//    
//    return nIndex;
//}

//change by wyl
- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint
{
    CGPoint cgPoint = NSPointToCGPoint(aPoint);
    CGAffineTransform transformInvert = CGAffineTransformInvert(m_Transformed);
    CGPoint pointTransformInvert = CGPointApplyAffineTransform(cgPoint, transformInvert);
    
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nIndex = textPath.text.length;
    
    for(int i=0; i< textPath.text.length; i++)
    {
        CGRect rect = [textPath getBoundRectForCharacter:i];
        
        if(rect.origin.x + rect.size.width/2.0 > pointTransformInvert.x)
        {
            nIndex = i;
            break;
        }
    }
    
    return nIndex;
}

- (CGPathRef) getBlinkCursor
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    if(textPath)
    {
        CGPathRef path = [textPath getBlinkCursor: m_nTextCursorPos];
        CGPathRef copyPath = CGPathCreateCopyByTransformingPath(path, &m_Transformed);
        return  copyPath;
    }
    return nil;
}


- (void)setFontName:(NSString *)strFontName
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSString *fontOld = textPath.fontName;
    [fontOld retain];
    textPath.fontName = strFontName;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontName:fontOld];
    [fontOld release];
}

- (void)setFontSize:(CGFloat)fSize
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    CGFloat fOldSize = textPath.fontSize;
    textPath.fontSize = fSize;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontSize:fOldSize];
}
- (void)setCustomTransform:(struct CUSTOM_TRANSFORM_)transform
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    CUSTOM_TRANSFORM oldTrans = textPath.transformCustom;
    textPath.transformCustom = transform;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setCustomTransform:oldTrans];
    
}

- (void)setPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    PSPerspectiveTransform oldTrans = textPath.perspectiveTransform;
    textPath.perspectiveTransform = perspectiveTransform;
    
    [self invalidData];
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setPerspectiveTransform:oldTrans];
}

- (void)concatPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform withReverseTransform:(PSPerspectiveTransform)reversePerspectiveTransform
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    PSPerspectiveTransform newTransform = productTransform(perspectiveTransform, textPath.perspectiveTransform);
    [self setPerspectiveTransform:newTransform];
    
}

- (void)setStrokeStyle:(BOOL)bStroke width:(int)nWidth color:(NSColor *)color
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    WDStrokeStyle *oldStrokeStyle   = textPath.strokeStyle;
    int nOldWidth                   = oldStrokeStyle.width;
    NSColor *colorOld               = [oldStrokeStyle.color copy];
    textPath.strokeStyle = [WDStrokeStyle strokeStyleWithWidth:nWidth
                                                           cap:0
                                                          join:1
                                                         color:[WDColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent alpha:color.alphaComponent]
                                                   dashPattern:nil];
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setStrokeStyle:YES width:nOldWidth color:colorOld];
    
}

- (void)setStartPoint:(CGPoint)pointStart
{
    WDTextPath *textOldPath = (WDTextPath *)m_idLastTextObject;
    [textOldPath retain];
    
    [self createTextObjectWithTextAtPath:textOldPath.text atPoint:pointStart];
    
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    textPath.fontName           = textOldPath.fontName;
    textPath.fontSize           = textOldPath.fontSize;
    textPath.transformCustom    = textOldPath.transformCustom;
    textPath.fill               = textOldPath.fill;
    textPath.nFontBoldWidth     = textOldPath.nFontBoldWidth;
    textPath.nFontItalicsValue  = textOldPath.nFontItalicsValue;
    textPath.nFontUnderlineValue  = textOldPath.nFontUnderlineValue;
    textPath.nFontStrikethroughValue  = textOldPath.nFontStrikethroughValue;
    textPath.nFontCharacterSpace  = textOldPath.nFontCharacterSpace;
    textPath.perspectiveTransform = textOldPath.perspectiveTransform;
    
    CGPoint poinStartOld = m_pointTextStart;
    m_pointTextStart = pointStart;
    [textOldPath release];
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setStartPoint:poinStartOld];
}

- (NSString *)getFontName
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.fontName;
}

- (CGFloat)getFontSize
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    return textPath.fontSize;
}

- (struct CUSTOM_TRANSFORM_ )getCustomTransform
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return ([textPath transformCustom]);
}

- (CGPoint)getStartPoint
{
    return m_pointTextStart;
}

- (NSColor *)getStrokeStyle:(BOOL *)bStroke width:(int *)nWidth
{
    return nil;
}


- (void)setFillColor:(NSColor *)color
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSObject * colorOldO = textPath.fill;
    WDColor *colorOld = nil;
    
    if([colorOldO isKindOfClass:[WDColor class]] == NO) return;
    
    colorOld = (WDColor *)colorOldO;
    [colorOld retain];
    
    WDColor *colorNew = [WDColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent alpha:color.alphaComponent];
    textPath.fill = colorNew;
    
    int nOldSize = textPath.nFontBoldWidth;
    textPath.nFontBoldWidth = nOldSize;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    NSColor *nsColorOld = [NSColor colorWithDeviceRed:colorOld.red green:colorOld.green blue:colorOld.blue alpha:colorOld.alpha];
    [colorOld release];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFillColor:nsColorOld];
}

- (void)setFontBold:(int)nWidth
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nOldSize = textPath.nFontBoldWidth;
    textPath.nFontBoldWidth = nWidth;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontBold:nOldSize];
}

- (void)setFontItalics:(int)nItalicsValue
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nOldSize = textPath.nFontItalicsValue;
    textPath.nFontItalicsValue = nItalicsValue;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontItalics:nOldSize];
}

- (void)setFontUnderline:(int)nUnderlineValue
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nOldSize = textPath.nFontUnderlineValue;
    textPath.nFontUnderlineValue = nUnderlineValue;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontUnderline:nOldSize];
}

- (void)setFontStrikethrough:(int)nStrikethroughValue
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nOldSize = textPath.nFontStrikethroughValue;
    textPath.nFontStrikethroughValue = nStrikethroughValue;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setFontStrikethrough:nOldSize];
}

- (void)setCharacterSpace:(int)CharacterSpace
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    int nOldSize = textPath.nFontCharacterSpace;
    textPath.nFontCharacterSpace = CharacterSpace;
    
    [self invalidData];
    [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] setCharacterSpace:nOldSize];
}

- (NSColor *)getFillColor
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    NSObject * colorOldO = textPath.fill;
    WDColor *colorOld = nil;
    
    if([colorOldO isKindOfClass:[WDColor class]] == NO) return nil;
    
    colorOld = (WDColor *)colorOldO;
    
    NSColor *nsColorOld = [NSColor colorWithDeviceRed:colorOld.red green:colorOld.green blue:colorOld.blue alpha:colorOld.alpha];
    
    return nsColorOld;
}

- (int)getFontBold
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.nFontBoldWidth;
}

- (int)getFontItalics
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.nFontItalicsValue;
}
- (int)getFontUnderline
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.nFontUnderlineValue;
}
- (int)getFontStrikethrough
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.nFontStrikethroughValue;
}

- (int)getCharacterSpace
{
    WDTextPath *textPath = (WDTextPath *)m_idLastTextObject;
    
    return textPath.nFontCharacterSpace;
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
    
    [(PSTextLayer *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] changeTransform:oldTransform];
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
    else if ([menuItem tag] >= 500 && [menuItem tag] < 600)     return NO;          //shape menu
    
    return YES;
}

@end
