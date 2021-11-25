#import "PSFlip.h"
#import "PSHelpers.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWhiteboard.h"
#import "PSSelection.h"
#import "PSLayer.h"
#import "PSSelection.h"

@implementation PSFlip

- (void)floatingFlip:(int)type
{	
	// Fill out variables
	[self simpleFlipOf:[(PSLayer *)[[m_idDocument contents] activeLayer] getRawData] width: [(PSLayer *)[[m_idDocument contents] activeLayer] width] height: [(PSLayer *)[[m_idDocument contents] activeLayer] height] spp: [[m_idDocument contents] spp] type: type];
	
    [(PSLayer *)[[m_idDocument contents] activeLayer] unLockRawData];
	// Reflect the changes
	[[m_idDocument helpers] layerContentsChanged:kActiveLayer];
	
	// Select the opaque part
	[[m_idDocument selection] selectOpaque];
	
	// Make action undoable
	if (type == kHorizontalFlip)
		[[[m_idDocument undoManager] prepareWithInvocationTarget:self] floatingHorizontalFlip];
	else
		[[[m_idDocument undoManager] prepareWithInvocationTarget:self] floatingVerticalFlip];
}

- (void)simpleFlipOf:(unsigned char*)data width:(int)width height:(int)height spp:(int)spp type:(int)type
{
	unsigned char temp;
	int i, j, k;
	
	// Do the correct flip
	if (type == kHorizontalFlip) {
		for (i = 0; i < width / 2; i++) {
			for (j = 0; j < height; j++) {
				for (k = 0; k < spp; k++) {
					temp = data[(j * width + i) * spp + k];
					data[(j * width + i) * spp + k] = data[(j * width + (width - i - 1)) * spp + k];
					data[(j * width + (width - i - 1)) * spp + k] = temp;
				}
			}
		}
	}
	else {
		for (i = 0; i < width; i++) {
			for (j = 0; j < height / 2; j++) {
				for (k = 0; k < spp; k++) {
					temp = data[(j * width + i) * spp + k];
					data[(j * width + i) * spp + k] = data[((height - j - 1) * width + i) * spp + k];
					data[((height - j - 1) * width + i) * spp + k] = temp;
				}
			}
		}
	}
}

- (void)floatingHorizontalFlip
{
	[self floatingFlip:kHorizontalFlip];
}

- (void)floatingVerticalFlip
{
	[self floatingFlip:kVerticalFlip];
}

- (void)standardFlip:(int)type
{
	unsigned char *overlay, *data, *replace, *edata = NULL;
	int i, j, k, width, height, spp;
	int src, dest;
	IntRect rect;
	BOOL complex;
	
	// Fill out variables
	overlay = [[m_idDocument whiteboard] overlay];
	data = [(PSLayer *)[[m_idDocument contents] activeLayer] getRawData];
	replace = [[m_idDocument whiteboard] replace];
	width = [(PSLayer *)[[m_idDocument contents] activeLayer] width];
	height = [(PSLayer *)[[m_idDocument contents] activeLayer] height];
	spp = [[m_idDocument contents] spp];
    if ([[m_idDocument selection] active]){
		rect = [[m_idDocument selection] localRect];
        rect = IntConstrainRect(rect, IntMakeRect(0, 0, width, height));
    }    
	else
		rect = IntMakeRect(0, 0, width, height);
	complex = [[m_idDocument selection] active] && [[m_idDocument selection] mask];
	
	// Erase selection if it is complex
	if (complex) {
		edata = malloc(rect.size.width * rect.size.height * spp);
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				memcpy(&(edata[(j * rect.size.width + i) * spp]), &(data[((j + rect.origin.y) * width +  (i + rect.origin.x)) * spp]), spp);
			}
		}
		[[m_idDocument selection] deleteSelection];
	}
	
	// Do the correct flip
	if (type == kHorizontalFlip) {
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				replace[(j + rect.origin.y) * width + (i + rect.origin.x)] = 255;
				if (complex)
					src = (j * rect.size.width + (rect.size.width - i - 1)) * spp;
				else
					src = ((j + rect.origin.y) * width + ((rect.size.width - i - 1) + rect.origin.x)) * spp;
				dest =((j + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				for (k = 0; k < spp; k++) {
					if (complex)
						overlay[dest + k] = edata[src + k];
					else
						overlay[dest + k] = data[src + k];
				}
			}
		}
	}
	else {
		for (i = 0; i < rect.size.width; i++) {
			for (j = 0; j < rect.size.height; j++) {
				replace[(j + rect.origin.y) * width + (i + rect.origin.x)] = 255;
				if (complex)
					src = ((rect.size.height - j - 1) * rect.size.width + i) * spp;
				else
					src = (((rect.size.height - j - 1) + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				dest =((j + rect.origin.y) * width + (i + rect.origin.x)) * spp;
				for (k = 0; k < spp; k++) {
					if (complex)
						overlay[dest + k] = edata[src + k];
					else
						overlay[dest + k] = data[src + k];
				}
			}
		}
	}
	
    [(PSLayer *)[[m_idDocument contents] activeLayer] unLockRawData];
	// Free used memory
	if (complex) free(edata);
	
	// Flip the selection
	[[m_idDocument selection] flipSelection:type];
	
	// Apply the changes
	[[m_idDocument whiteboard] setOverlayOpacity:255];
	[[m_idDocument whiteboard] setOverlayBehaviour:kReplacingBehaviour];
	[(PSHelpers *)[m_idDocument helpers] applyOverlay];
}

- (void)run:(int)type
{
	if ([(PSLayer *)[[m_idDocument contents] activeLayer] floating])
		[self floatingFlip:type];
	else
		[self standardFlip:type];	
}

@end
