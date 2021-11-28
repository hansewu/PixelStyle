//
//  GraphicsToBuffer.mm
//  MyBrushesPlugin_mac
//
//  Created by wu zhiqiang on 1/22/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
//#import <map>
//#import <vector>
#import "GraphicsToBuffer.h"
#import <GIMPCore/GIMPCore.h>

//using namespace std;

typedef  struct
{
    CIImage *image;
    unsigned char *pBuf;
}CIImage_Buf;
static CIImage_Buf CICreateCIImage(unsigned char *pBuf, int nWidth, int nHeight, float fRadiusGauusian)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //int nLength = nWidth * nHeight;
    unsigned int *pData = (unsigned int *)malloc((nWidth * nHeight*sizeof(int)+15)/16*16);
    
    unsigned int *pDataFrom = (unsigned int *)pBuf;
    unsigned int *pDataTo = pData;
    // memcpy(pData, pBuf, nWidth * nHeight*4);
    
  //  pDataFrom += (nHeight -1)*nWidth;
    for(int y=0;y<nHeight; y++)
    {
        for(int x=0; x< nWidth; x++)
        {
            *pDataTo = ((*pDataFrom)<<8) |(( (*pDataFrom))>>24);
            
            pDataTo++;
            pDataFrom++;
        }
       // pDataFrom -= 2*nWidth;
  
    }
    
    NSData *data = [NSData dataWithBytesNoCopy:pData length:nWidth*nHeight*4 freeWhenDone:NO];
    CIImage *image = [CIImage imageWithBitmapData:data bytesPerRow:nWidth*4 size:CGSizeMake(nWidth, nHeight) format:kCIFormatARGB8 colorSpace:colorSpace];
    
    if(fRadiusGauusian < 0.0001)
    {
        [image retain];

        CGColorSpaceRelease( colorSpace );
        
        CIImage_Buf ImageBuf = {image, (unsigned char *)pData};
        
        return ImageBuf;
    }
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];//@"CISepiaTone"];
    [filter setValue:image forKey:@"inputImage"];
    //[filter setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputIntensity"];
    [filter setValue:[NSNumber numberWithFloat:fRadiusGauusian] forKey:@"inputRadius"];
    
    CIImage *ciimage = [filter valueForKey:@"outputImage"];
    
    [ciimage retain];
    
    CIImage_Buf ImageBuf = {ciimage, (unsigned char *)pData};
    
    CGColorSpaceRelease( colorSpace );
    
    return ImageBuf;
}

static void CIDestroyCIImage(CIImage_Buf CIImageBuf)
{
    CIImage *ciimage = (CIImage *)CIImageBuf.image;
    
    [ciimage release];
    
    free(CIImageBuf.pBuf);
}

static void RenderCIImage(CGContextRef contextCG, CIImage *pCIImage, IntRect rectTo, IntRect rectFrom )
{
    CIImage *image = (CIImage *)pCIImage;
    
    CIContext *iContext = [CIContext contextWithCGContext:contextCG options:nil];

    [iContext drawImage:image inRect:CGRectMake(rectTo.origin.x, rectTo.origin.y, rectTo.size.width, rectTo.size.height) fromRect:CGRectMake(rectFrom.origin.x, rectFrom.origin.y, rectFrom.size.width, rectFrom.size.height)];
}


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
    bitmapData = pBuffer;
    if (bitmapData == NULL)
    {
        assert(false);
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    
    if(bAlphaPremultiplied)
        context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    else
        context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big);
    if (context== NULL)
    {
        assert(false);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}


static void CGDrawEllipseToContext(CGContextRef  contextCG, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, CGPoint offset)
{
    CGContextSetAllowsAntialiasing(contextCG, true);
    CGContextSetShouldAntialias(contextCG, true);
    const CGFloat components[] = {(float)colorFill.byteRed/255.0, (float)colorFill.byteGreen/255.0, (float)colorFill.byteBlue/255.0, (float)colorFill.byteAlpha/255.0};
    CGContextSetFillColor(contextCG, components);
    
    CGRect rectNow = rect;
    rectNow.origin.x -= offset.x;
    rectNow.origin.y -= offset.y;
    
    CGContextFillEllipseInRect(contextCG, rectNow);
}

static void CGDrawRoundRectToContext(CGContextRef  contextCG, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, CGPoint offset, float fCornerRadius)
{
    CGContextSetAllowsAntialiasing(contextCG, true);
    CGContextSetShouldAntialias(contextCG, true);
    const CGFloat components[] = {(float)colorFill.byteRed/255.0, (float)colorFill.byteGreen/255.0, (float)colorFill.byteBlue/255.0, (float)colorFill.byteAlpha/255.0};
    CGContextSetFillColor(contextCG, components);
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-offset.x, -offset.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    float fCornerRadiusX, fCornerRadiusY;
    fCornerRadiusX = fCornerRadiusY = fCornerRadius;
    if(rect.size.width < 2*fCornerRadiusX) fCornerRadiusX = rect.size.width/2.0;
    if(rect.size.height < 2 * fCornerRadiusY) fCornerRadiusY = rect.size.height / 2.0;
    
    CGPathAddRoundedRect(path, &transform, rect, fCornerRadiusX, fCornerRadiusY);
    CGContextAddPath(contextCG, path);
    CGContextFillPath(contextCG);
    
    CGPathRelease(path);
}




static void CGDrawPolygonToContext(CGContextRef  contextCG, CGPoint *points, int nPointNum, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, CGPoint offset)
{
    CGContextSetAllowsAntialiasing(contextCG, true);
    CGContextSetShouldAntialias(contextCG, true);
    const CGFloat components[] = {(float)colorFill.byteRed/255.0, (float)colorFill.byteGreen/255.0, (float)colorFill.byteBlue/255.0, (float)colorFill.byteAlpha/255.0};
    CGContextSetFillColor(contextCG, components);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-offset.x, -offset.y);
    CGPathAddLines(path, &transform, points, nPointNum);
    
    CGContextAddPath(contextCG, path);
    CGContextFillPath(contextCG);
    
    CGPathRelease(path);
}

void DestroyImageBuffer(IMAGE_BUFFER *pBuf)
{
    if(pBuf->pBuffer)
    {
        free(pBuf->pBuffer);
        pBuf->pBuffer = NULL;
    }
}

int CreateImageBufferFromPolygon(IMAGE_BUFFER *pBufOut, CGPoint *points, int nPointNum, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius)
{
    if(nPointNum <3) return -1;
    
    int nMinX, nMinY, nMaxX, nMaxY;
    nMinX = nMaxX = points[0].x;
    nMinY = nMaxY = points[0].y;
    for (int i = 1; i < nPointNum; i++)
    {
        if (nMinX > points[i].x)    nMinX = points[i].x;
        if (nMinY > points[i].y)    nMinY = points[i].y;
        if (nMaxX < points[i].x)    nMaxX = points[i].x;
        if (nMaxY < points[i].y)    nMaxY = points[i].y;

    }
    CGPoint offsetOut;
    offsetOut.x = nMinX - 2*fGaussanRadius;
    offsetOut.y = nMinY - 2*fGaussanRadius;
    
    pBufOut->nWidth   = nMaxX - nMinX + 4*fGaussanRadius + 1;
    pBufOut->nHeight  = nMaxY - nMinY  + 4*fGaussanRadius + 1;
    
    pBufOut->pBuffer = (unsigned char *)malloc((pBufOut->nWidth * 4 * pBufOut->nHeight+15)/16*16);
    memset(pBufOut->pBuffer, 0, pBufOut->nWidth * 4 * pBufOut->nHeight);
    
    CGContextRef contextCG = MyCreateBitmapContext(pBufOut->nWidth, pBufOut->nHeight, pBufOut->pBuffer, true);
    if(contextCG == NULL) return -2;
    
    CGDrawPolygonToContext(contextCG, points, nPointNum,  color, bFill,  colorFill, offsetOut);

    if(fGaussanRadius > 0.0001)
    {
        CIImage_Buf imageCII = CICreateCIImage(pBufOut->pBuffer, pBufOut->nWidth, pBufOut->nHeight, fGaussanRadius);
        memset(pBufOut->pBuffer, 0, pBufOut->nWidth * 4 * pBufOut->nHeight);
        IntRect rect = {{0.0,0.0},{(float)pBufOut->nWidth, (float)pBufOut->nHeight}};
        RenderCIImage(contextCG, imageCII.image, rect, rect);
        
        CIDestroyCIImage(imageCII);
    }
    
    CGContextRelease(contextCG);
    
    return 0;
}

int CreateImageBufferFromRect(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius)
{
    if (rect.size.width < 1.0 || rect.size.height < 1.0) {
        return 0;
    }
    
    CGPoint points[4];
    
    points[0].x = rect.origin.x;                        points[0].y = rect.origin.y;
    points[1].x = rect.origin.x;                        points[1].y = rect.origin.y + rect.size.height;
    points[2].x = rect.origin.x + rect.size.width;      points[2].y = rect.origin.y + rect.size.height;
    points[3].x = rect.origin.x + rect.size.width;      points[3].y = rect.origin.y;
    
    return CreateImageBufferFromPolygon(pBufOut, points, 4, color, bFill, colorFill,fGaussanRadius);
}

int CreateImageBufferFromEllipse(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius)
{
    if (rect.size.width < 1.0 || rect.size.height < 1.0) {
        return 0;
    }
    
    CGPoint offsetOut;
    offsetOut.x = rect.origin.x - 2*fGaussanRadius;
    offsetOut.y = rect.origin.y - 2*fGaussanRadius;
    
    pBufOut->nWidth   = rect.size.width + 4*fGaussanRadius;
    pBufOut->nHeight  = rect.size.height + 4*fGaussanRadius;
    
    pBufOut->pBuffer = (unsigned char *)malloc((pBufOut->nWidth * 4 * pBufOut->nHeight+15)/16*16);
    
    memset(pBufOut->pBuffer, 0, pBufOut->nWidth * 4 * pBufOut->nHeight);
    CGContextRef contextCG = MyCreateBitmapContext(pBufOut->nWidth,pBufOut->nHeight, pBufOut->pBuffer, true);
    if(contextCG == NULL) return -2;
    
    
    CGDrawEllipseToContext(contextCG, rect,  color, bFill,  colorFill, offsetOut);
    
    
    if(fGaussanRadius > 0.0001)
    {
        CIImage_Buf imageCII = CICreateCIImage(pBufOut->pBuffer, pBufOut->nWidth, pBufOut->nHeight, fGaussanRadius);
        memset(pBufOut->pBuffer, 0,  pBufOut->nWidth * 4 *  pBufOut->nHeight);
        IntRect rect = {{0.0,0.0},{(float) pBufOut->nWidth, (float) pBufOut->nHeight}};
        RenderCIImage(contextCG, imageCII.image, rect, rect);
        
        CIDestroyCIImage(imageCII);
    }
    CGContextRelease(contextCG);
    
    return 0;
}

int CreateImageBufferFromRoundRect(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fCornerRadius, float fGaussanRadius)
{
    if (rect.size.width < 1.0 || rect.size.height < 1.0) {
        return 0;
    }
    CGPoint offsetOut;
    offsetOut.x = rect.origin.x - 2*fGaussanRadius;
    offsetOut.y = rect.origin.y - 2*fGaussanRadius;
    
    pBufOut->nWidth   = rect.size.width + 4*fGaussanRadius;
    pBufOut->nHeight  = rect.size.height + 4*fGaussanRadius;
    
    pBufOut->pBuffer = (unsigned char *)malloc((pBufOut->nWidth * 4 * pBufOut->nHeight+15)/16*16);
    
    memset(pBufOut->pBuffer, 0, pBufOut->nWidth * 4 * pBufOut->nHeight);
    CGContextRef contextCG = MyCreateBitmapContext(pBufOut->nWidth,pBufOut->nHeight, pBufOut->pBuffer, true);
    if(contextCG == NULL) return -2;
    
    CGDrawRoundRectToContext(contextCG, rect,  color, bFill,  colorFill, offsetOut, fCornerRadius);
    
    
    if(fGaussanRadius > 0.0001)
    {
        CIImage_Buf imageCII = CICreateCIImage(pBufOut->pBuffer, pBufOut->nWidth, pBufOut->nHeight, fGaussanRadius);
        memset(pBufOut->pBuffer, 0,  pBufOut->nWidth * 4 *  pBufOut->nHeight);
        IntRect rect = {{0.0,0.0},{(float) pBufOut->nWidth, (float) pBufOut->nHeight}};
        RenderCIImage(contextCG, imageCII.image, rect, rect);
        
        CIDestroyCIImage(imageCII);
    }
    CGContextRelease(contextCG);
    
    return 0;
}

int GetNSImageBuffer(NSImage *image, int nWidth, int nHeight, unsigned char *pBufRGBA, int bAlphaPremultiplied)
{
    assert(nil != image);
    
    bool bUpsideDown = true;
    
    if(nHeight < 0)
    {
        bUpsideDown = false;
        nHeight = - (nHeight);
    }
    
    memset(pBufRGBA, 0, nWidth*nHeight*4);
    CGContextRef context = MyCreateBitmapContext(nWidth , nHeight, pBufRGBA, bAlphaPremultiplied);
    
    assert(nil != context);
    
    CGRect rect=CGRectMake(0,0, nWidth, nHeight);
    
    CGImageRef imageRef = [image CGImageForProposedRect:nil context:nil hints:nil];
    
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

int GaussianBlurImageBuffer(IMAGE_BUFFER *pBufOut, float fGaussanRadius)
{
    CGContextRef contextCG = MyCreateBitmapContext(pBufOut->nWidth,pBufOut->nHeight, pBufOut->pBuffer, true);
    if(contextCG == NULL) return -1;
    
    
    if(fGaussanRadius > 0.0001)
    {
        CIImage_Buf imageCII = CICreateCIImage(pBufOut->pBuffer, pBufOut->nWidth, pBufOut->nHeight, fGaussanRadius);
        memset(pBufOut->pBuffer, 0,  pBufOut->nWidth * 4 *  pBufOut->nHeight);
        IntRect rect = {{0.0,0.0},{(float) pBufOut->nWidth, (float) pBufOut->nHeight}};
        RenderCIImage(contextCG, imageCII.image, rect, rect);
        
        CIDestroyCIImage(imageCII);
    }
    CGContextRelease(contextCG);
    
    return 0;
}
