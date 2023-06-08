#import "AbstractExporter.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"

@implementation AbstractExporter

- (BOOL)hasOptions
{
	return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return NULL;
}

- (NSString *)extension
{
	/*if(![self title]){
		NSLog(@"This is an Abstract Class and should not be instantiated");
		return @"";
	}
	
	int i;
	NSArray* allDocumentTypes = [[[NSBundle mainBundle] infoDictionary]
								 valueForKey:@"CFBundleDocumentTypes"];
	for(i = 0; i < [allDocumentTypes count]; i++){
		NSDictionary *typeDict = [allDocumentTypes objectAtIndex:i];
		NSString* key = [typeDict objectForKey:@"CFBundleTypeName"];
		if ([key isEqual: [self title]]) {
			return [[typeDict objectForKey:@"CFBundleTypeExtensions"]objectAtIndex:0];
		}
	}*/
			 
	return @"";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	return NO;
}

- (NSString *)optionsString
{
	return @"";
}

- (BOOL)basicWriteDocument:(id)document toFile:(NSString *)path representationUsingType:(NSBitmapImageFileType)type properties:(NSDictionary*)properties
{
    int i, j, width, height, spp;
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
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    int nXRes = [(PSContent *)[document contents] xres];
    int nYRes = [(PSContent *)[document contents] yres];
    // Add EXIF data
    NSDictionary *exifData = [[document contents] exifData];
    if (exifData) [imageRep setProperty:@"NSImageEXIFData" withValue:exifData];
    if(properties == nil)
        properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
                                nil];

    imageData = [imageRep representationUsingType:type properties:properties];
    
    // Save our file and let's go
    [imageData writeToFile:path atomically:YES];
    [imageRep autorelease];
    
    // If the destination data is not equivalent to the source data free the former
    if (destData != srcData)
        free(destData);
    
    return YES;
}
@end
