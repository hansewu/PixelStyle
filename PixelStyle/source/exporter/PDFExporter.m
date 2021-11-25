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
    [image unlockFocus];
    
    
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
