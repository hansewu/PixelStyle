//
//  robustVideoMatting.m
//  roboHumanMatting
//
//  Created by apple on 1/22/22.
//
#import <AppKit/AppKit.h>
#import "roboHumanMatting.h"
#import "rvm_mobilenetv3_1280x720_s0_375_fp16.h"


@import CoreImage;
@import CoreML;
@import Vision;

@interface robustVideoMatting ()

@property (nonatomic, strong) rvm_mobilenetv3_1280x720_s0_375_fp16 *rvmModel;
@property (nonatomic, strong) VNCoreMLModel *model;
@property (nonatomic, strong) VNCoreMLRequest *request;
@property (nonatomic, strong) VNImageRequestHandler *handler;
@end


static CGImageRef createCGImageFromBuffer(unsigned char *pBuffer, int width, int height)
{
    unsigned char* pBufferNew           = (unsigned char*)malloc(width*height*4);
    memset(pBufferNew,0,width*height*4);
    memcpy(pBufferNew,pBuffer,width*height*4);
    for(int i = 0;i < height;i++)
    {
        for(int j = 0;j < width; j++)
        {
            pBufferNew[i*width*4+j*4]   *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+1] *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+2] *= pBufferNew[i*width*4+4*j+3]/255.0;
        }
    }
    CGColorSpaceRef colorSpace      = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext      = CGBitmapContextCreate(pBufferNew,width,height,8,width*4,colorSpace,kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef             = CGBitmapContextCreateImage(bitmapContext);
    //NSImage* image                  = [[[NSImage alloc]initWithCGImage:imageRef size:NSMakeSize(width,height)]autorelease];
    
    CGColorSpaceRelease(colorSpace);
    //CGImageRelease(imageRef);
    free(pBufferNew);
    pBufferNew = nil;
    
    return imageRef;
}


CGImageRef getCGImage(NSImage *image, int outWidth, int outHeight)
{
    NSSize newSize = NSMakeSize(outWidth, outHeight);
    NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
    [smallImage lockFocus];
    
    [image setSize: newSize];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationCopy fraction:1.0];
    [smallImage unlockFocus];
    
    CGImageRef imgRef = [smallImage CGImageForProposedRect:nil context:nil hints:nil];
    
    return imgRef;
}

NSImage *nsImageFromCVImage(CVPixelBufferRef bufferRef)
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer: bufferRef];

    CIContext *context = [CIContext context];//(options: nil)

//From here you can go to both GCImage and NSImage:

    size_t width = CVPixelBufferGetWidth(bufferRef);
    size_t height = CVPixelBufferGetHeight(bufferRef);
    
    CGImageRef imageRef = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, width, height)];

    NSImage *nsImage = [[NSImage alloc] initWithCGImage: imageRef  size: CGSizeMake(width, height)];
    
    return nsImage;
}

CVPixelBufferRef  pixelBufferFromCGImage(CGImageRef image)
{
    CVPixelBufferRef pxbuffer = NULL;
    NSCParameterAssert(NULL != image);
    size_t originalWidth = CGImageGetWidth(image);
    size_t originalHeight = CGImageGetHeight(image);
    
    NSMutableData *imageData = [NSMutableData dataWithLength:originalWidth*originalHeight*4];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate([imageData mutableBytes], originalWidth, originalHeight, 8, 4*originalWidth, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(cgContext, CGRectMake(0, 0, originalWidth, originalHeight), image);
    CGContextRelease(cgContext);
    CGImageRelease(image);
    unsigned char *pImageData = (unsigned char *)[imageData bytes];
    
    
    CFDictionaryRef empty;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    
    CFMutableDictionaryRef m_pPixelBufferAttribs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                      3,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferOpenGLCompatibilityKey, empty);
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferCGBitmapContextCompatibilityKey, empty);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, originalWidth, originalHeight, kCVPixelFormatType_32BGRA, pImageData, originalWidth * 4, NULL, NULL, m_pPixelBufferAttribs, &pxbuffer);
    CFRelease(empty);
    CFRelease(m_pPixelBufferAttribs);
    
    
    return pxbuffer;
}

static int matFromPixelBuffer(CVPixelBufferRef bufferRef, unsigned char *pOutBuf)
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer: bufferRef];

    CIContext *context = [CIContext context];//(options: nil)

    size_t width = CVPixelBufferGetWidth(bufferRef);
    size_t height = CVPixelBufferGetHeight(bufferRef);
    
    CGImageRef imageRef = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, width, height)];
    
    NSMutableData *imageData = [NSMutableData dataWithLength:width*height*4];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate([imageData mutableBytes], width, height, 8, 4*width, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(cgContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(cgContext);
    CGImageRelease(imageRef);
    
    unsigned char *pImageData = (unsigned char *)[imageData bytes];
    memcpy(pOutBuf, pImageData, width*height*4);

    return 0;
}

@implementation robustVideoMatting

- (void)loadModel
{
    NSError *error = nil;
    rvm_mobilenetv3_1280x720_s0_375_fp16 *rvmModel = [[rvm_mobilenetv3_1280x720_s0_375_fp16 alloc] init];
    VNCoreMLModel *model = [VNCoreMLModel modelForMLModel:rvmModel.model error:&error];
    
    self.rvmModel = rvmModel;
    self.model = model;
}

-(NSImage *)predictImage:(NSImage *)image outForeground:(NSImage **)outForeground
{
    NSError *error = nil;
    CGImageRef imageRef = getCGImage(image, 1280, 720);
    
    rvm_mobilenetv3_1280x720_s0_375_fp16Input *input =
        [[rvm_mobilenetv3_1280x720_s0_375_fp16Input alloc] initWithSrcFromCGImage: imageRef  error:&error];
    
    rvm_mobilenetv3_1280x720_s0_375_fp16Output *output = [self.rvmModel predictionFromFeatures:input error:&error];
    
    CVPixelBufferRef fgr = output.fgr;
    CVPixelBufferRef pha = output.pha;
    
    *outForeground = nsImageFromCVImage(fgr);
    
    return nsImageFromCVImage(pha);
}


-(int)predictImage1280x720:(unsigned char *)pBuffer  outAlpha:(unsigned char *)outAlpha outForeground:(unsigned char *)outForeground
{
    NSError *error = nil;
    
    CGImageRef imageRef = createCGImageFromBuffer(pBuffer, 1280, 720);
    //CGImageRef imageRef = getCGImage(image, 1280, 720);
    
    rvm_mobilenetv3_1280x720_s0_375_fp16Input *input =
        [[rvm_mobilenetv3_1280x720_s0_375_fp16Input alloc] initWithSrcFromCGImage: imageRef  error:&error];
    
    rvm_mobilenetv3_1280x720_s0_375_fp16Output *output = [self.rvmModel predictionFromFeatures:input error:&error];
    
    CGImageRelease(imageRef);
    
    if(!error)
    {
        matFromPixelBuffer(output.fgr, outForeground);
        matFromPixelBuffer(output.pha, outAlpha);
        
        return 0;
    }
    
    return -1;
}

@end
