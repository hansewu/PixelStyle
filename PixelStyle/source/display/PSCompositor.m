#import "PSCompositor.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "PSSelection.h"
#import "PSTools.h"
#import "AbstractTool.h"

@implementation PSCompositor

- (id)initWithDocument:(id)doc
{
	int i;
	
	// Remember the document we are compositing for
	m_idDocument = doc;
	
	// Work out the random table for the dissolve effect
	srandom(RANDOM_SEED);
	for (i = 0; i < 4096; i++)
		m_aRandomTable[i] = random();
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}



- (void)compositeLayersToContext:(CGContextRef)context inRect:(CGRect)rect isBitmap:(BOOL)isBitmap
{
    int nLayerCount = [[m_idDocument contents] layerCount];
    
    NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    CGContextSaveGState(context);
    // Go through compositing each visible layer
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
        if ([layer visible])
        {
            BOOL isHasPreview = NO;
            for (int i = 0; i < [previewLayers count]; i++) {
                if (layer == [previewLayers objectAtIndex:i]) {
                    isHasPreview = YES;
                    break;
                }
            }
            RENDER_CONTEXT_INFO info;
            info.context = context;
            info.offset = CGPointMake(0, 0);
            float xScale = [[m_idDocument contents] xscale];
            float yScale = [[m_idDocument contents] yscale];
            info.scale = CGSizeMake(1.0, 1.0);
            info.refreshMode = 1;
            info.state = NULL;
            if (isHasPreview) {
                [(AbstractTool*)[[m_idDocument tools] currentTool] drawLayerToolPreview:info layerid:layer];
            }else{
                //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
                //[layer render:context viewRect:rect];
                
                [layer renderToContext:info];
                //NSLog(@"drawContext: %f",[NSDate timeIntervalSinceReferenceDate] - begin);
            }
            
        }
    }
    CGContextRestoreGState(context);
}

//for save context 1:1 not bitmap
- (void)compositeLayersToContextFull:(CGContextRef)context
{
    int nLayerCount = [[m_idDocument contents] layerCount];
    
    NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    CGContextSaveGState(context);
    // Go through compositing each visible layer
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
        if ([layer visible])
        {
            BOOL isHasPreview = NO;
            for (int i = 0; i < [previewLayers count]; i++) {
                if (layer == [previewLayers objectAtIndex:i]) {
                    isHasPreview = YES;
                    break;
                }
            }
            RENDER_CONTEXT_INFO info;
            info.context = context;
            info.offset = CGPointMake(0, 0);
            info.scale = CGSizeMake(1.0, 1.0);
            info.refreshMode = 2;
            int state = 0;
            info.state = &state;
            if (isHasPreview) {
                [(AbstractTool*)[[m_idDocument tools] currentTool] drawLayerToolPreview:info layerid:layer];
            }else{
                
                [layer renderToContext:info];
            }
            
        }
    }
    CGContextRestoreGState(context);
}



- (void)compositeLayersToContext:(RENDER_CONTEXT_INFO)contextInfo
{
    int nLayerCount = [[m_idDocument contents] layerCount];
     NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    CGContextRef context = contextInfo.context;
    CGContextSaveGState(context);
    // Go through compositing each visible layer
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
        if ([layer visible])
        {
            BOOL isHasPreview = NO;
            for (int i = 0; i < [previewLayers count]; i++)
            {
                if (layer == [previewLayers objectAtIndex:i])
                {
                    isHasPreview = YES;
                    break;
                }
            }
            if (isHasPreview)
            {
                [(AbstractTool*)[[m_idDocument tools] currentTool] drawLayerToolPreview:contextInfo layerid:layer];
            }
            else
            {
                [layer renderToContext:contextInfo];
            }
            
        }
    }
    
    CGContextRestoreGState(context);
}


/*
- (void)compositeLayersToContext:(CGContextRef)context inRect:(CGRect)rect isBitmap:(BOOL)isBitmap
{
    int nWidth = [(PSContent *)[m_idDocument contents] width];
    int nHeight = [(PSContent *)[m_idDocument contents] height];
    float fScaleX = rect.size.width/(float)nWidth;
    float fScaleY = rect.size.height/(float)nHeight;
    
    int nMode,nLayerWidth,nLayerHeight;
    int nOffsetX, nOffsetY;
    int nLayerAlpha;
    LAYER_SHADOW sLayerShadow;
    BOOL isLayerShadowEnable;
    int nLayerCount = [[m_idDocument contents] layerCount];
    
    NSMutableArray *previewLayers = [(AbstractTool*)[[m_idDocument tools] currentTool] getToolPreviewEnabledLayer];
    
    
    CGContextSaveGState(context);
    // Go through compositing each visible layer
    for (int i = nLayerCount - 1; i >= 0; i--)
    {
        if ([[[m_idDocument contents] layer:i] visible])
        {
            PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] layer:i];
            nMode = [layer mode];
            nOffsetX = [layer xoff];
            nOffsetY = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] yoff];
            nLayerWidth = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] width];
            nLayerHeight = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] height];
            nLayerAlpha = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] opacity];
            
//            sLayerShadow = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] getLayerShadow];
//            isLayerShadowEnable = [(PSLayer*)layer getLayerShadowEnable];
            PSLayerEffect *effect = [(PSAbstractLayer *)[[m_idDocument contents] layer:i] getLayerEffect];
            sLayerShadow = [effect getShadow];
            isLayerShadowEnable = [effect shadowIsEnable];
            
            if ([layer layerFormat] == PS_RASTER_LAYER || [layer layerFormat] == PS_TEXT_LAYER)
            {
                BOOL isHasPreview = NO;
                for (int i = 0; i < [previewLayers count]; i++) {
                    if (layer == [previewLayers objectAtIndex:i]) {
                        isHasPreview = YES;
                        break;
                    }
                }
                if (isHasPreview) {
                    [(AbstractTool*)[[m_idDocument tools] currentTool] drawLayerToolPreview:context layerid:layer];
                }else{
                    CGContextSaveGState(context);
                    if (isLayerShadowEnable) {
                        if (isBitmap) {
                            sLayerShadow.offset.height = -sLayerShadow.offset.height;
                        }
                        CGColorRef shadowColor = CGColorCreateGenericRGB(sLayerShadow.color[0]/255.0,sLayerShadow.color[1]/255.0, sLayerShadow.color[2]/255.0, sLayerShadow.color[3]/255.0);
                        CGContextSetShadowWithColor(context, CGSizeMake(sLayerShadow.offset.width, sLayerShadow.offset.height), sLayerShadow.fBlur,shadowColor);
                        CGColorRelease(shadowColor);
                    }else{
                        CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
                    }
                    CGContextSetAlpha(context, nLayerAlpha/255.0);
                    CGContextSetBlendMode(context, nMode);
                    CGRect destRect = CGRectMake(nOffsetX *fScaleX + rect.origin.x, nOffsetY * fScaleY+rect.origin.y, nLayerWidth * fScaleX, nLayerHeight *fScaleY);
                    CGLayerRef cgLayer = [(PSLayer *)layer getCGLayer];
                    if (cgLayer) {
                        CGContextDrawLayerInRect(context, destRect, cgLayer);
                    }
                    CGContextRestoreGState(context);
                }
                
            }
            else
            {
            
            }
            
        }
    }
    CGContextRestoreGState(context);
}
 */

- (void)compositeLayer:(PSLayer *)layer withOptions:(CompositorOptions)options
{
	[self compositeLayer: layer withOptions: options andData: NULL];
}

- (void)compositeLayer:(PSLayer *)layer withOptions:(CompositorOptions)options andData:(unsigned char *)destPtr
{
    //NSLog(@"lcz compositeLayer");
	unsigned char *srcPtr, *overlay, *mask, *replace;
	int lwidth = [layer width], lheight = [layer height], mode = [layer mode];
	int opacity = [layer opacity];
	int selectedChannel = [[m_idDocument contents] selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int startX, startY, endX, endY, t1;
	int i, j, k, srcLoc, destLoc;
	unsigned char tempSpace[4], tempSpace2[4];
	BOOL insertOverlay, overlayOkay;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
	BOOL floating;
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([(PSContent *)[m_idDocument contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([(PSContent *)[m_idDocument contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [(PSSelection *)[m_idDocument selection] localRect];
    srcPtr = [layer getRawData];
    
//    PSLayer *activeLayer = [[m_idDocument contents] activeLayer];
//    if (activeLayer == layer && options.updateRawData) {
//        srcPtr = [layer getFullDataWithFilter]; //[layer getRawData];
//    }else{
//        srcPtr = [layer getFullDataWithFilter]; //[layer getRawData];
//    }
    
	if(!destPtr) destPtr = [(PSWhiteboard *)[m_idDocument whiteboard] data];
	overlay = [(PSWhiteboard *)[m_idDocument whiteboard] overlay];
        
	replace = [(PSWhiteboard *)[m_idDocument whiteboard] replace];
	mask = [(PSSelection*)[m_idDocument selection] mask];
	maskOffset = [[m_idDocument selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[m_idDocument selection] maskSize];
	floating = [layer floating];
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Go through each row
	for (j = startY; j < endY; j++) {
	
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(m_aRandomTable[(j + yoff) % 4096]);
			for (k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (i = startX; i < endX; i++) {
		
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (k = 0; k < options.spp; k++)
                tempSpace2[k] = srcPtr[srcLoc + k];
			if (insertOverlay) {
				
				// Check if we should apply the overlay for this pixel
				overlayOkay = NO;
				switch (options.overlayBehaviour) {
					case kReplacingBehaviour:
					case kMaskingBehaviour:
						selectOpacity = replace[j * lwidth + i];
					break;
					default:
						selectOpacity = options.overlayOpacity;
					break;
				}
				if (options.useSelection) {
					point.x = i;
					point.y = j;
					if (IntPointInRect(point, selectRect)) {
						overlayOkay = YES;
						if (mask && !floating)
							selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
					}
				}
				else {
					overlayOkay = YES;
				}
				
				// Don't do anything if there's no point
				if (selectOpacity == 0)
					overlayOkay = NO;
				
				// Apply the overlay if we get the okay
				if (overlayOkay) {
					if (selectedChannel == kAllChannels && !floating) {
						switch (options.overlayBehaviour) {
							case kErasingBehaviour:
								eraseMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
							case kReplacingBehaviour:
								replaceMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
							default:
								specialMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
							break;
						}
					}
					else if (selectedChannel == kPrimaryChannels || floating) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case kReplacingBehaviour:
									replacePrimaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								default:
									primaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity, YES);
								break;
							}
						}
					}
					else if (selectedChannel == kAlphaChannel) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case kReplacingBehaviour:
									replaceAlphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								default:
									alphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
							}
						}
					}
				}
				
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {

				// Copy pixel from destination in to temporary memory
				for (k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				selectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			
			}
			else {
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			
			}
			
		}
	}
}

- (void)compositeLayer:(PSLayer *)layer withFloat:(PSLayer *)floatingLayer andOptions:(CompositorOptions)options
{
	unsigned char  *destPtr, *overlay, *mask, *replace;
	int lwidth = [layer width], lheight = [layer height], mode = [layer mode];
	int lfwidth = [floatingLayer width], lfheight = [floatingLayer height];
	int opacity = [layer opacity], selectedChannel = [[m_idDocument contents] selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int xfoff = [floatingLayer xoff], yfoff = [floatingLayer yoff];
	int startX, startY, endX, endY;
	int i, j, k, srcLoc, destLoc, floatLoc, tx, ty;
	unsigned char tempSpace[4], tempSpace2[4], tempSpace3[4];
	BOOL insertOverlay;
	IntPoint maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
	BOOL floating;
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([(PSContent *)[m_idDocument contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([(PSContent *)[m_idDocument contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [(PSSelection *)[m_idDocument selection] localRect];

	destPtr = [(PSWhiteboard *)[m_idDocument whiteboard] data];
	overlay = [(PSWhiteboard *)[m_idDocument whiteboard] overlay];
	replace = [(PSWhiteboard *)[m_idDocument whiteboard] replace];
	mask = [[m_idDocument selection] mask];
	maskOffset = [[m_idDocument selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[m_idDocument selection] maskSize];
	floating = [layer floating];
	
	// Check what we are doing has a point
	if (endX - startX <= 0 ||endY - startY <= 0)
        return;
    
    unsigned char *srcPtr, *floatPtr;
    srcPtr = [layer getRawData];
    floatPtr = [floatingLayer getRawData];
	
	// Go through each row
	for (j = startY; j < endY; j++) {
	
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(m_aRandomTable[(j + yoff) % 4096]);
			for (k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (i = startX; i < endX; i++) {
		
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (k = 0; k < options.spp; k++)
				tempSpace2[k] = srcPtr[srcLoc + k];
				
			// Insert floating layer
			ty = yoff - yfoff + j;
			tx = xoff - xfoff + i;
			if (ty >= 0 && ty < lfheight) {
				if (tx >= 0 && tx < lfwidth) {
					floatLoc = (ty * lfwidth + tx) * options.spp;
					for (k = 0; k < options.spp; k++)
						tempSpace3[k] = floatPtr[floatLoc + k];
					if (insertOverlay) {
						switch (options.overlayBehaviour) {
							case kReplacingBehaviour:
							case kMaskingBehaviour:
								selectOpacity = replace[ty * lfwidth + tx];
							break;
							default:
								selectOpacity = options.overlayOpacity;
							break;
						}
						if (selectOpacity > 0) {
							primaryMerge(options.spp, tempSpace3, 0, overlay, floatLoc, selectOpacity, YES);
						}
					}
					if (selectedChannel == kAllChannels) {
						normalMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					}
					else if (selectedChannel == kPrimaryChannels) {
						primaryMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255, YES);
					}
					else if (selectedChannel == kAlphaChannel) {
						alphaMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					}
				}
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {

				// Copy pixel from destination in to temporary memory
				for (k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				selectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			
			}
			else {
				
				// Then merge the pixel in temporary memory with the destination pixel
				normalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			
			}
			
		}
	}
    
    [layer unLockRawData];
    [floatingLayer unLockRawData];
}

@end
