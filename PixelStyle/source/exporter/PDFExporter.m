//
//  PDFExporter.m
//  PixelStyle
//
//  Created by lchzh on 16/1/16.
//
//

#import "PDFExporter.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"

@implementation PDFExporter


- (BOOL)hasOptions
{
    return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
    return @"Portable Document Format (PDF)";
}

- (NSString *)extension
{
    return @"pdf";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    int i, j, width, height, spp;
    unsigned char *srcData, *destData;
    NSBitmapImageRep *imageRep;

    BOOL hasAlpha = NO;
    
    // Get the data to write
    srcData = [(PSWhiteboard *)[document whiteboard] data];
    width = [(PSContent *)[document contents] width];
    height = [(PSContent *)[document contents] height];
    spp = [(PSContent *)[document contents] spp];
   
    // Determine whether or not an alpha channel would be redundant
    for (i = 0; i < width * height && hasAlpha == NO; i++)
    {
        if (srcData[(i + 1) * spp - 1] != 255)
            hasAlpha = YES;
    }
    
    // Strip the alpha channel if necessary
    if (!hasAlpha)
    {
        spp--;
        destData = malloc(width * height * spp);
        for (i = 0; i < width * height; i++)
        {
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
    imageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp] autorelease];
    
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:imageRep];
    
  /*  float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
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
    [image unlockFocus];
    */
    
    NSImageView *myView;
    NSRect vFrame;
    NSData *pdfData;
    vFrame = NSZeroRect;
    vFrame.size = [image size];
    myView = [[NSImageView alloc] initWithFrame:vFrame];
    
    [myView setImage:image];
    [image release];
    
    /* Generate data */
    pdfData = [myView dataWithPDFInsideRect:vFrame];
    [pdfData retain];
    [myView release];
    
    /* Write data to file */
    bool success = [pdfData writeToFile:path options:0 error:NULL];
    [pdfData release];
    if(!success) {
        NSLog(@"Failed to create image");
    }

    
    
    return YES;
    
 
}


@end
