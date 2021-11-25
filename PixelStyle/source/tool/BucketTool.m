#import "BucketTool.h"
#import "PSWhiteboard.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "Bucket.h"
#import "OptionsUtility.h"
#import "BucketOptions.h"
#import "StandardMerge.h"
#import "PSTexture.h"
#import "PSTools.h"
#import "PSHelpers.h"
#import "PSSelection.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"

@implementation BucketTool

- (int)toolId
{
	return kBucketTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Paint Bucket Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"G";
}

- (id)init
{
	self = [super init];
	if(self){
		m_bIsPreviewing = NO;
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"bucket-cursor"] hotSpot:NSMakePoint(14, 14)];
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt to flood all selection. Press Shift to preview flood.", nil)];
    }
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
	m_sStartPoint = where;
	
	m_poiStart = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
	m_poiCurrent = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
	if([(BucketOptions *)m_idOptions modifier] == kShiftModifier){
		m_bIsPreviewing = YES;
	}
	
	m_bIntermediate = YES;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	m_poiCurrent = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
	
	BOOL optionDown = [(BucketOptions *)m_idOptions modifier] == kAltModifier;

	id layer = [[m_idDocument contents] activeLayer];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	
	[[m_idDocument whiteboard] clearOverlay];
	[[m_idDocument helpers] overlayChanged:m_sRect inThread:NO];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		m_sRect.size.width = m_sRect.size.height = 0;
	}else if(m_bIsPreviewing){
		[self fillAtPoint:where useTolerance:!optionDown delay:YES];
	}
    
	[[m_idDocument docView] setNeedsDisplay: YES];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id layer = [[m_idDocument contents] activeLayer];
	int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
	BOOL optionDown = [(BucketOptions *)m_idOptions modifier] == kAltModifier;
	
	[[m_idDocument whiteboard] clearOverlay];
	[[m_idDocument helpers] overlayChanged:m_sRect inThread:NO];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		m_sRect.size.width = m_sRect.size.height = 0;
	} else if(!m_bIsPreviewing || [(BucketOptions *)m_idOptions modifier] != kShiftModifier){
		//[self fillAtPoint:where useTolerance:!optionDown delay:NO];
	}
    [self fillAtPoint:where useTolerance:!optionDown delay:NO];
	m_bIsPreviewing = NO;
	m_bIntermediate = NO;
}

- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance delay:(BOOL)delay
{
	id layer = [[m_idDocument contents] activeLayer], activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
	int tolerance, width = [(PSLayer *)layer width], height = [(PSLayer *)layer height], spp = [[m_idDocument contents] spp];
	int textureWidth = [(PSTexture *)activeTexture width], textureHeight = [(PSTexture *)activeTexture height];
    
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
    unsigned char *data = NULL;
	unsigned char *texture = [activeTexture texture:(spp == 4)];
	unsigned char basePixel[4];
	NSColor *color = [[m_idDocument contents] foreground];
	int k, channel;
	
	// Set the overlay to fully opaque
	[[m_idDocument whiteboard] setOverlayOpacity:255];
    
    float alpha = [m_idOptions getOpacityValue];
	
	// Determine the bucket's colour
	if ([m_idOptions useTextures]) {
		for (k = 0; k < spp - 1; k++)
			basePixel[k] = 0;
		basePixel[spp - 1] = [(TextureUtility *)[[PSController utilitiesManager] textureUtilityFor:m_idDocument] opacity];
	}
	else {
		if (spp == 4) {
			basePixel[0] = (unsigned char)([color redComponent] * 255.0);
			basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
			basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
			basePixel[3] = (unsigned char)(alpha * 255.0);
		}
		else {
			basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
			basePixel[1] = (unsigned char)(alpha * 255.0);
		}
	}
		
	
	int intervals = [m_idOptions numIntervals];
	
	IntPoint* seeds = malloc(sizeof(IntPoint) * (intervals + 1));
	
	int seedIndex;
	int xDelta = point.x - m_sStartPoint.x;
	int yDelta = point.y - m_sStartPoint.y;
	for(seedIndex = 0; seedIndex <= intervals; seedIndex++){
		int x = m_sStartPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
		int y = m_sStartPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
		seeds[seedIndex] = IntMakePoint(x, y);				
	}

	
	// Fill everything
	if (useTolerance)
		tolerance = [(BucketOptions *)m_idOptions tolerance];
	else
		tolerance = 255;
	if ([layer floating])
		channel = kPrimaryChannels;
	else
		channel = [[m_idDocument contents] selectedChannel];
    
    data = [(PSLayer *)layer getRawData];
    if ([[m_idDocument selection] active]){
        IntRect localRect = IntConstrainRect([[m_idDocument selection] localRect], IntMakeRect(0, 0, width, height));
		m_sRect = bucketFill(spp, localRect, overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
    }
	else
		m_sRect = bucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
    
    [layer unLockRawData];
    
    
	if ([m_idOptions useTextures] && IntContainsRect(IntMakeRect(0, 0, width, height), m_sRect)) {
		if ([[m_idDocument selection] active])
			textureFill(spp, m_sRect, overlay, width, height, texture, textureWidth, textureHeight);
		else
			textureFill(spp, m_sRect, overlay, width, height, texture, textureWidth, textureHeight);
	}
    
    [overlayData unLockDataForWrite];
	
    //NSLog(@"overlayChanged");
	// Do the update
    if (delay){
		[[m_idDocument helpers] overlayChanged:IntMakeRect(0, 0, width, height) inThread:NO];
    }
    else{
		[(PSHelpers *)[m_idDocument helpers] applyOverlay];
        [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    }
    
    
}

- (NSPoint)start
{
	return m_poiStart;
}

-(NSPoint)current
{
	return m_poiCurrent;
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return NO;
    
    return YES;
}


@end
