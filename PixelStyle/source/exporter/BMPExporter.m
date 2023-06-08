//
//  BMPExporter.m
//  PixelStyle
//
//  Created by wyl on 15/12/6.
//
//

#import "BMPExporter.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"

@implementation BMPExporter

- (BOOL)hasOptions
{
    return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
    return @"Windows bitmap image (BMP)";
}

- (NSString *)extension
{
    return @"bmp";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    return [self basicWriteDocument:document toFile:path representationUsingType:NSBMPFileType properties:nil];
/*    float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
    int nWidth = [(PSContent *)[document contents] width];
    int nHeight = [(PSContent *)[document contents] height];
    NSSize imageSize = NSMakeSize(nWidth/fScreenScale, nHeight/fScreenScale);
    
    
    //画到NSImage
    NSImage *image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(imageSize)];
    [image lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextConcatCTM(context, CGAffineTransformMakeScale(1/fScreenScale, 1/fScreenScale));
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:nHeight];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    [[[document whiteboard] compositor] compositeLayersToContextFull:context];
    CGContextRestoreGState(context);
    //存到文件中，设置imageData的格式
//    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)] autorelease];
    
    [image unlockFocus];
    
    int nXRes = [(PSContent *)[document contents] xres];
    int nYRes = [(PSContent *)[document contents] yres];
    NSBitmapImageRep* savedImageBitmapRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1.0]];
    
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
                                nil];
    
    NSMutableData* imageData = [NSMutableData data];
    CGImageDestinationRef imageDest =  CGImageDestinationCreateWithData((CFMutableDataRef) imageData, kUTTypeBMP, 1, NULL);
    CGImageDestinationAddImage(imageDest, [savedImageBitmapRep CGImage], (CFDictionaryRef) properties);
    CGImageDestinationFinalize(imageDest);

//    // Save to a file
//    NSData *imageData = [bitmap representationUsingType:NSBMPFileType properties:properties];
    
    //写文件
    [imageData writeToFile:path atomically:YES];
    
    [image release];
    if (imageDest)
        CFRelease(imageDest);
    
    return YES;
*/
 /*   int i, j, width, height, spp;
    unsigned char *srcData, *destData;
    NSBitmapImageRep *imageRep;
    NSData *imageData;
    BOOL hasAlpha = NO;
    
    // Get the data to write
    srcData = [(PSWhiteboard *)[document whiteboard] data];
    width = [(PSContent *)[document contents] width];
    height = [(PSContent *)[document contents] height];
    spp = [(PSContent *)[document contents] spp];
    
    // Determine whether or not an alpha channel would be redundant
    for (i = 0; i < width * height && hasAlpha == NO; i++) {
        if (srcData[(i + 1) * spp - 1] != 255)
            hasAlpha = YES;
    }
    
    // Strip the alpha channel if necessary
    if (!hasAlpha) {
        spp--;
        destData = malloc(width * height * spp);
        for (i = 0; i < width * height; i++) {
            for (j = 0; j < spp; j++)
                destData[i * spp + j] = srcData[i * (spp + 1) + j];
        }
    }
    else
    {
        destData = malloc(width * height * spp);
        premultiplyBitmap(spp, destData, srcData, width*height);
    }
    
    // Make an image representation from the data
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    int nXRes = [(PSContent *)[document contents] xres];
    int nYRes = [(PSContent *)[document contents] yres];
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
                                nil];
    imageData = [imageRep representationUsingType:NSBMPFileType properties:properties];
    
    // Save our file and let's go
    [imageData writeToFile:path atomically:YES];
    [imageRep autorelease];
    
    // If the destination data is not equivalent to the source data free the former
    if (destData != srcData)
        free(destData);
    
    return YES;*/
}


@end
