#import "GIFExporter.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"

@implementation GIFExporter

- (BOOL) hasOptions
{
	return NO;
}

- (IBAction) showOptions: (id) sender
{
	
}

- (NSString *) title
{
	return @"Graphics Interchange Format (GIF)";
}

- (NSString *) extension
{
	return @"gif";
}

- (BOOL) writeDocument: (id) document toFile: (NSString *) path
{
    float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
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
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)] autorelease];
    
    [image unlockFocus];
    
    
//     With these GIF properties, we will let the OS do the dithering
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSImageDitherTransparency, NULL];
    // Save to a file
    NSData *imageData = [bitmap representationUsingType:NSGIFFileType properties:gifProperties];
    
    //写文件
    [imageData writeToFile:path atomically:YES];
    
    [image release];
    
    
    return YES;
    
//    // Get the image data
//    unsigned char* srcData = [(PSWhiteboard *)[document whiteboard] data];
//    int width = [(PSContent *)[document contents] width];
//    int height = [(PSContent *)[document contents] height];
//    int spp = [(PSContent *)[document contents] spp];
//    
//    // Strip the alpha channel (there is no alpha in then GIF format)
//    unsigned char* destData = malloc(width * height * (spp - 1));
//    stripAlphaToWhite(spp, destData, srcData, width * height);
//    spp--;
//    
//    // Make an image representation from the data
//    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]	initWithBitmapDataPlanes: &destData
//                                                                         pixelsWide: width
//                                                                         pixelsHigh: height
//                                                                      bitsPerSample: 8
//                                                                    samplesPerPixel: spp
//                                                                           hasAlpha: NO
//                                                                           isPlanar: NO
//                                                                     colorSpaceName: (spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace
//                                                                        bytesPerRow:width * spp 
//                                                                       bitsPerPixel: 8 * spp];
//    
//    // With these GIF properties, we will let the OS do the dithering
//    NSDictionary *gifProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSImageDitherTransparency, NULL];
//    
//    // Save to a file
//    NSData* imageData = [imageRep representationUsingType: NSGIFFileType properties: gifProperties];
//    [imageData writeToFile: path atomically: YES];
//	
//	// Cleanup
//	[imageRep autorelease];
//	free(destData);
//	
//	return YES;
}

@end
