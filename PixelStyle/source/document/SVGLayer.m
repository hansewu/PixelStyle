#import "PSDocument.h"
#import "PSContent.h"
#import "SVGLayer.h"
#import "SVGContent.h"
#import "Bitmap.h"

#import "WDDrawingController.h"
#import "WDLayer.h"

@implementation SVGLayer

-(id)initWithLayer:(WDLayer *)layer document:(id)doc
{
    // Call the core initializer
    if (![self initWithDocument:doc])   return NULL;
    
    m_bVisible = [layer visible];
    m_nOpacity = [layer opacity] * 255.0;
    [m_strName autorelease];
    m_strName = [NSString stringWithString:[layer name]];
    [m_strName retain];
    
    // Assume we always have alpha
    m_bHasAlpha = YES;
    
    [self performSelector:@selector(delayInitWDLayer:) withObject:layer afterDelay:.05];
//    PSContent *contents = (PSContent *)[doc contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
//    
//    if(m_wdLayer) [m_wdLayer release];
//    m_wdLayer =[layer copyWithZone:nil];
//    m_wdLayer.layerDelegate = self;
//    m_wdLayer.drawing = wdDrawingController.drawing;
//    [wdDrawingController.drawing.layers addObject:m_wdLayer];
//    
//    [self invalidData];
//    [self refreshTotalToRender];
    
    return self;
}

-(void)delayInitWDLayer:(WDLayer *)layer
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.drawing.layers removeObject:m_wdLayer];
    
    if(m_wdLayer) [m_wdLayer release];
    m_wdLayer =[layer copyWithZone:nil];
    m_wdLayer.layerDelegate = self;
    m_wdLayer.drawing = wdDrawingController.drawing;
    [wdDrawingController.drawing.layers addObject:m_wdLayer];
    
    [self invalidData];
    [self refreshTotalToRender];
}

- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp
{
	int i, space, bps = [imageRep bitsPerSample], sspp = [imageRep samplesPerPixel];
	unsigned char *srcPtr = [imageRep bitmapData];
	CMProfileLocation cmProfileLoc;
	int bipp, bypr;
	id profile;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Determine the width and height of this layer
	m_nWidth = [imageRep pixelsWide];
	m_nHeight = [imageRep pixelsHigh];
	
	// Determine samples per pixel
	m_nSpp = lspp;

	// Determine the color space
	space = -1;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
		space = kGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
		space = kInvertedGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
		space = kRGBColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
		space = kCMYKColorSpace;
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		[self autorelease];
		return NULL;
	}
	
	// Extract color profile
	profile = NULL;//[imageRep valueForProperty:NSImageColorSyncProfileData];
/*	if (profile) {
		cmProfileLoc.locType = cmPtrBasedProfile;
		cmProfileLoc.u.ptrLoc.p = (Ptr)[profile bytes];
	}
*/	
	// Convert data to what we want
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
    
    
	unsigned char *pData = convertBitmap(m_nSpp, (m_nSpp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcPtr, m_nWidth, m_nHeight, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, 0);
	if (!pData) {
		NSLog(@"Required conversion not supported.");
		[self autorelease];
		return NULL;
	}    
    
	// Check the alpha
	m_bHasAlpha = NO;
	for (i = 0; i < m_nWidth * m_nHeight; i++) {
		if (pData[(i + 1) * m_nSpp - 1] != 255)
			m_bHasAlpha = YES;
	}
	
	// Unpremultiply the image
	if (m_bHasAlpha)
		unpremultiplyBitmap(m_nSpp, pData, pData, m_nWidth * m_nHeight);
    
//    [m_pImageData reInitDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    
    //modify by lcz
    if (!m_pImageData) {
        m_pImageData = [[PSSecureImageData alloc] initDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    }else{
        [m_pImageData reInitDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    }
    
    [self refreshTotalToRender];
    
	return self;
}

@end
