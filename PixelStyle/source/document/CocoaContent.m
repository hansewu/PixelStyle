#import "CocoaContent.h"
#import "CocoaLayer.h"
#import "PSController.h"
#import "PSWarning.h"
#import "PSDocumentController.h"

@implementation CocoaContent

+ (BOOL)typeIsEditable:(NSString *)aType forDoc:(id)doc
{
	PSDocumentController* controller = (PSDocumentController*)[NSDocumentController
															sharedDocumentController];				 
	if([controller type: aType isContainedInDocType: @"TIFF image (TIFF)"] ||
	   [controller type: aType isContainedInDocType: @"Portable Network Graphics image (PNG)"] ||
	   [controller type: aType isContainedInDocType: @"JPEG image (JPG)"] ||
       [controller type: aType isContainedInDocType: @"JPEG 2000 image (JP2)"]||
       [controller type: aType isContainedInDocType: @"Windows bitmap image (BMP)"]||
       [controller type: aType isContainedInDocType: @"Portable Document Format (PDF)"]||
       [controller type: aType isContainedInDocType: @"WebP Image (WEBP)"])
    {
		return YES;
	}
    else if ([controller type: aType isContainedInDocType: @"Graphics Interchange Format (GIF)"])
    {
        NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        NSString *sKey = [NSString stringWithFormat:@"%@ does not support GIF transparency or animation.",sProductName];
		[[PSController seaWarning]
		 addMessage:LOCALSTR(@"gif trans",sKey)
		 forDocument:doc level:kHighImportance];
		return YES;
	}

	return  NO;
}

+ (BOOL)typeIsViewable:(NSString *)aType forDoc:(id)doc
{
	if ([CocoaContent typeIsEditable:aType forDoc:doc]) {
		return YES;
	}
	
	PSDocumentController* controller = [PSDocumentController sharedDocumentController];
	if([controller type: aType isContainedInDocType: @"Portable Document Format (PDF)"] ||
	   [controller type: aType isContainedInDocType: @"QuickDraw picture"] ||
       [controller type: aType isContainedInDocType: @"Windows bitmap image (BMP)"] ||
       [controller type: aType isContainedInDocType: @"RAW image"]){
		return YES;
	}
	return NO;
}


- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	id imageRep;
	NSImage *image;
	id layer;
	BOOL test, res_set = NO;
	int value;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Open the image
    NSArray *types = [NSImage imageFileTypes];
	image = [[NSImage alloc] initByReferencingFile:path];
	if (image == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
				
				[image setScalesWhenResized:YES];
				[image setDataRetained:YES];
				
				[NSBundle loadNibNamed:@"CocoaContent" owner:self];
				[m_idResMenu setEnabled:YES];
				[m_idPdfPanel center];
				[m_idPageLabel setStringValue:[NSString stringWithFormat:@"of %d", (int)[imageRep pageCount]]];
				[m_idResMenu selectItemAtIndex:0];
				[NSApp runModalForWindow:m_idPdfPanel];
				[m_idPdfPanel orderOut:self];
                

				value = [m_idPageInput intValue];
				if (value > 0 && value <= [imageRep pageCount]){
					[imageRep setCurrentPage:value - 1];
				}

				NSSize sourceSize = [image size];
				NSSize size = sourceSize;
				
				value = [m_idResMenu indexOfSelectedItem];
				switch (value) {
					case 0:
						res_set = YES;
						m_nXres = m_nYres = 72.0;
					break;
					case 1:
						res_set = YES;
						size.width *= 96.0 / 72.0;
						size.height *= 96.0 / 72.0;
						m_nXres = m_nYres = 96.0;
					break;
					case 2:
						res_set = YES;
						size.width *= 150.0 / 72.0;
						size.height *= 150.0 / 72.0;
						m_nXres = m_nYres = 150.0;
					break;
					case 3:
						res_set = YES;
						size.width *= 300.0 / 72.0;
						size.height *= 300.0 / 72.0;
						m_nXres = m_nYres = 300.0;
					break;
					case 4:
						res_set = YES;
						size.width *= 600.0 / 72.0;
						size.height *= 600.0 / 72.0;
						m_nXres = m_nYres = 600.0;
					break;
					case 5:
						res_set = YES;
						size.width *= 900.0 / 72.0;
						size.height *= 900.0 / 72.0;
						m_nXres = m_nYres = 900.0;
					break;
				}
				[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
				[image setSize:size];
				NSRect destinationRect = NSMakeRect( 0, 0, size.width, size.height );
				NSImage* dest = [[NSImage alloc] initWithSize:size];
				[dest lockFocus];
				NSRectFillUsingOperation( destinationRect, NSCompositeClear );
				[image drawInRect: destinationRect
						  fromRect: destinationRect
						 operation: NSCompositeCopy fraction: 1.0];
				
				NSBitmapImageRep* newRep = [[NSBitmapImageRep alloc]
											initWithFocusedViewRect: destinationRect];
				[dest unlockFocus];
				[dest autorelease];
				imageRep = newRep;
			}else {
				imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
			}
		}
	}
	if (imageRep == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	
	// Warn if 16-bit image
	if ([imageRep bitsPerSample] == 16) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"16-bit message", @"PixelStyle does not support the editing of 16-bit images. This image has been resampled at 8-bits to be imported.") forDocument:doc level:kHighImportance];
	}
	
	// Determine the height and width of the image
	m_nHeight = [imageRep pixelsHigh];
	m_nWidth = [imageRep pixelsWide];
	
	// Determine the resolution of the image
	if (!res_set) {
		m_nXres = roundf(((float)m_nWidth / [image size].width) * 72);
		m_nYres = roundf(((float)m_nHeight / [image size].height) * 72);
	}
	
	// Determine the image type
    NSString *colorSpaceName = [imageRep colorSpaceName];
	test = [colorSpaceName isEqualToString:NSCalibratedBlackColorSpace] || [colorSpaceName isEqualToString:NSDeviceBlackColorSpace];
	test = test || [colorSpaceName isEqualToString:NSCalibratedWhiteColorSpace] || [colorSpaceName isEqualToString:NSDeviceWhiteColorSpace];
	if (test) 
		m_nType = XCF_GRAY_IMAGE;
	else
		m_nType = XCF_RGB_IMAGE;
    
    m_nType = XCF_RGB_IMAGE;  //add by lcz
		
	// Store EXIF data
	m_dicExifData = [imageRep valueForProperty:@"NSImageEXIFData"];
	if (m_dicExifData) [m_dicExifData retain];
	
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:(m_nType == XCF_RGB_IMAGE) ? 4 : 2];
	if (layer == NULL) {
		[image autorelease];
		[self autorelease];
		return NULL;
	}
	m_arrLayers = [NSArray arrayWithObject:layer];
	[m_arrLayers retain];
	
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
	// Now forget the NSImage
	[image autorelease];
	
	return self;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end
