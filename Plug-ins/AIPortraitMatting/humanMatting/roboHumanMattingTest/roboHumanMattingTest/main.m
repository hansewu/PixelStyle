//
//  main.m
//  roboHumanMattingTest
//
//  Created by apple on 1/23/22.
//

#import <Foundation/Foundation.h>
#import <roboHumanMatting/roboHumanMatting.h>
#import <AppKit/AppKit.h>

void saveNSImage(NSImage *image, NSString *fileName)
{
        NSData *imageData = [image TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
        imageData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:imageProps];
        [imageData writeToFile:fileName atomically:NO];
}
    
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        robustVideoMatting *rvmProcess;
        
        rvmProcess = [[robustVideoMatting alloc] init];
        [rvmProcess loadModel];
        
        NSImage *image = [[NSImage alloc]  initWithContentsOfFile:@"/Volumes/D/wzq/MATLAB/matting/data/input_lowres/9feb-9bbac81f3792edd4a95c7ae76ecb2d0d.jpg"];//@"/Users/apple/Pictures/屏幕快照 2020-11-30 上午11.08.28.png"];//690a-iuvaazp1405786.jpg"];
        
        NSImage *imAlpha, *imForeground = nil;
        
        imAlpha = [rvmProcess predictImage:image outForeground:&imForeground];
        
        saveNSImage(imAlpha,  @"alpha1.png");
        saveNSImage(imForeground, @"forground1.png");
    }
    return 0;
}
