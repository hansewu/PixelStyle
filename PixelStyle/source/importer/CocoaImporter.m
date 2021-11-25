#import "CocoaImporter.h"
#import "CocoaLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSView.h"
#import "CenteringClipView.h"
#import "PSOperations.h"
#import "PSAlignment.h"
#import "PSController.h"
#import "PSWarning.h"

@implementation CocoaImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	id imageRep;
	NSImage *image;
	id layer;
	int value;
	// NSPoint centerPoint;
	
	// Open the image
	image = [[NSImage alloc] initByReferencingFile:path];
	if (image == NULL) {
		[image autorelease];
		return NO;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [[image representations] objectAtIndex:0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
				if ([imageRep pageCount] > 1) {
					[NSBundle loadNibNamed:@"CocoaContent" owner:self];
					[m_idResMenu setEnabled:NO];
					[m_idPdfPanel center];
					[m_idPageLabel setStringValue:[NSString stringWithFormat:@"of %d", [imageRep pageCount]]];
					[NSApp runModalForWindow:m_idPdfPanel];
					[m_idPdfPanel orderOut:self];
					value = [m_idPageInput intValue];
					if (value > 0 && value <= [imageRep pageCount])
						[imageRep setCurrentPage:value - 1];
				}
			}
			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		}
	}
	if (imageRep == NULL) {
		[image autorelease];
		return NO;
	}
		
	// Warn if 16-bit image
	if ([imageRep bitsPerSample] == 16) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"16-bit message", @"PixelStyle does not support the editing of 16-bit images. This image has been resampled at 8-bits to be imported.") forDocument: doc level:kHighImportance];
	}
		
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
	if (layer == NULL) {
		[image autorelease];
		return NO;
	}
	
	// Rename the layer
	[(PSLayer *)layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Now forget the NSImage
	[image autorelease];
	
    // Position the new layer correctly
	//[[(PSOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	//[[(PSOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
    
    [layer setOffsets:IntMakePoint(([(PSContent*)[doc contents] width] - [(PSLayer *)layer width]) / 2, ([(PSContent*)[doc contents] height] - [(PSLayer *)layer height]) / 2)];
    
	
	return YES;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

@end
