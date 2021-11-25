#import "PSPrintView.h"
#import "PSView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "UtilitiesManager.h"
#import "TransparentUtility.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSLayer.h"
#import "ToolboxUtility.h"
#import "PSWhiteboard.h"
#import "PSTools.h"
#import "PositionTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "PSLayerUndo.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "PSPrefs.h"
#import "PSController.h"

@implementation PSPrintView

- (id)initWithDocument:(id)doc 
{	
	NSRect frame;
		
	// Remember the document this view is displaying
	m_idDocument = doc;

	// Determine the frame at 100% 72-dpi
	frame = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * (72.0 / (float)[[m_idDocument contents] xres]), [(PSContent *)[m_idDocument contents] height] * (72.0 / (float)[[m_idDocument contents] yres]));

	// Initialize superclass
	if ([super initWithFrame:frame] == NULL)
		return NULL;
	
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSRect srcRect = rect, destRect = rect;
	NSImage *image = NULL;
	int xres = [[m_idDocument contents] xres], yres = [[m_idDocument contents] yres];

	// Get the correct image for displaying
	image = [[m_idDocument whiteboard] printableImage];
	
	// Set the background color
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRect:destRect] fill];
	
	// We want our image flipped
	[image setFlipped:YES];
	
	// For non 72 dpi resolutions we must scale here
	if (xres != 72) {
		srcRect.origin.x *= ((float)xres / 72.0);
		srcRect.size.width *= ((float)xres / 72.0);
	}
	if (yres != 72) {
		srcRect.origin.y *= ((float)yres / 72.0);
		srcRect.size.height *= ((float)yres / 72.0);
	}
	
	// Set interpolation (image smoothing) appropriately
	if ([[PSController m_idPSPrefs] smartInterpolation]) {
		if (srcRect.size.width > destRect.size.width)
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		else
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	}
	else {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	}
	
	// Fix for Jaguar
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2)
		srcRect.origin.y = [image size].height - srcRect.origin.y - srcRect.size.height;
    
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);//4
    CGContextTranslateCTM(context, 0, rect.size.height);//3
    CGContextScaleCTM(context, 1.0, -1.0);//2
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);//1
    
	// Draw the image to screen
	[image drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
    
    CGContextRestoreGState(context);
}

/*
- (BOOL)knowsPageRange:(NSRangePointer)range
{
	NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
	NSRect bounds;
	NSRect paper;
	float scale;
	
	// Work out the image's bounds
	bounds = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * (72.0 / (float)[[m_idDocument contents] xres]), [(PSContent *)[m_idDocument contents] height] * (72.0 / (float)[[m_idDocument contents] yres]));
	
	// Work out the paper's bounding rectangle
	paper.size = [pi paperSize];
	paper.size.height -= [pi topMargin] + [pi bottomMargin];
	paper.size.width -= [pi leftMargin] + [pi rightMargin];
	scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor] floatValue];
	paper.size.height /= scale;
	paper.size.width /= scale;
    
	if (bounds.size.width < paper.size.width && bounds.size.height < paper.size.height) {
		
		// Handle one page documents
		range->location = 1;
		range->length = 1;
		[pi setHorizontallyCentered:YES];
		[pi setVerticallyCentered:YES];
		
	}
	else {
		
		// Otherwise do tiling
		range->location = 1;
		range->length = ceil((float)bounds.size.width / (float)paper.size.width) * ceil((float)bounds.size.height / (float)paper.size.height);
		[pi setHorizontallyCentered:NO];
		[pi setVerticallyCentered:NO];
		
	}
	
	return YES;
}
*/



 float mod(float a, float b)
{
	float result;
	
	result = fabsf(a);
	while (result - b > 0.0) {
		result -= b;
	}
	
	return result;
}



/*
- (NSRect)rectForPage:(int)page
{
	NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
	NSRect bounds, paper, result;
	float scale;
	int horizPages, vertPages;
	
	// Work out the image's bounds
	bounds = NSMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * (72.0 / (float)[[m_idDocument contents] xres]), [(PSContent *)[m_idDocument contents] height] * (72.0 / (float)[[m_idDocument contents] yres]));
	
	// Work out the paper's bounding rectangle
	paper.size = [pi paperSize];
	paper.size.height -= [pi topMargin] + [pi bottomMargin];
	paper.size.width -= [pi leftMargin] + [pi rightMargin];
	scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor] floatValue];
	paper.size.height /= scale;
	paper.size.width /= scale;
	
	if (bounds.size.width < paper.size.width && bounds.size.height < paper.size.height) {
	
		// Handle one page documents
		return bounds;
		
	}
	else {
	
		// Correct page (we work from page zero)
		page--;
	
		// Otherwise do tiling
		horizPages = ceil((float)bounds.size.width / (float)paper.size.width);
		vertPages = ceil((float)bounds.size.height / (float)paper.size.height);
		
		// Work out origin
		result.origin.x = (page % horizPages) * paper.size.width;
		result.origin.y = (page / horizPages) * paper.size.height;
		
		// Work out width
		if (page % horizPages == horizPages - 1)
			result.size.width = mod(bounds.size.width, paper.size.width);
		else
			result.size.width = paper.size.width;
		
		// Work out height
		if (page / horizPages == vertPages - 1)
			result.size.height = mod(bounds.size.height, paper.size.height);
		else
			result.size.height = paper.size.height;
		
	}
	
	return result;
}
*/

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

@end
