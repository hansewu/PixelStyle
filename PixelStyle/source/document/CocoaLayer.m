#import "PSDocument.h"
#import "PSContent.h"
#import "CocoaLayer.h"
#import "CocoaContent.h"
#import "Bitmap.h"

@implementation CocoaLayer

- (id)initWithImageRep32:(id)imageRep document:(id)doc
{
    int i;
    // Initialize superclass first
    if (![super initWithDocument:doc])
        return NULL;
    
    // Determine the width and height of this layer
    
    long lwidth = [(NSImageRep*)imageRep pixelsWide];
    long lheight = [(NSImageRep*)imageRep pixelsHigh];
    
    if(lwidth<kMinImageSize || lwidth > kMaxImageSize ||
       lheight < kMinImageSize || lheight > kMaxImageSize) {
        return NULL;
    }

    m_nWidth = (int)lwidth;
    m_nHeight = (int)lheight;
    
    m_nSpp = 4; //lspp;
    
    unsigned char *pData = convertRepToRGBA(imageRep);
    if(!pData){
        return NULL;
    }
    
    m_bHasAlpha = NO;
    int alphaPos = m_nSpp - 1;
    for (i = 0; i < m_nWidth * m_nHeight; i++)
    {
        if (pData[i*m_nSpp+alphaPos] != 255)
            m_bHasAlpha = YES;
    }
    if(m_bHasAlpha)
        unpremultiplyBitmap(m_nSpp, pData, pData, m_nWidth * m_nHeight);
   
    //modify by lcz
    if (!m_pImageData)
    {
        m_pImageData = [[PSSecureImageData alloc] initDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    }
    else
    {
        [m_pImageData reInitDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    }
    
    [self refreshTotalToRender];
    
    return self;
}

- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp
{
    if(lspp == 4)
        return [self initWithImageRep32:imageRep document:doc];
    
	int i, space, bps, sspp, format;
	unsigned char *srcPtr;
	CMProfileLocation cmProfileLoc;
	int bipp, bypr;
	id profile;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Fill out variables
	bps = [imageRep bitsPerSample];
	sspp = [imageRep samplesPerPixel];
	srcPtr = [imageRep bitmapData];
	format = 0;
	#ifdef MACOS_10_4_COMPILE
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		format = [imageRep bitmapFormat];
	}
	#endif
	
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
    int cmPtrBasedProfile           = 3;
	profile = NULL;//[imageRep valueForProperty:NSImageColorSyncProfileData];//
	/*if (profile)
    {
		//cmProfileLoc.locType = cmPtrBasedProfile;
        //cmProfileLoc.u.bufferLoc.buffer = (Ptr)[profile bytes];
        //cmProfileLoc.u.bufferLoc.size = (UInt32)[profile length] ;
		//cmProfileLoc.ptrLoc.p = (Ptr)[profile bytes];
	}*/
	
	// Convert data to what we want
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
	unsigned char *pData = convertBitmap(m_nSpp, (m_nSpp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcPtr, m_nWidth, m_nHeight, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, format);
	if (!pData) {
		NSLog(@"Required conversion not supported.");
		[self autorelease];
		return NULL;
	}
    
//    unsigned char temp[m_nWidth * m_nSpp];
//    for (int j = 0; j < m_nHeight / 2; j++) {
//        memcpy(temp, m_pData + j * m_nWidth * m_nSpp, m_nWidth * m_nSpp);
//        memcpy(m_pData + j * m_nWidth * m_nSpp, m_pData + (m_nHeight - j - 1) * m_nWidth * m_nSpp, m_nWidth * m_nSpp);
//        memcpy(m_pData + (m_nHeight - j - 1) * m_nWidth * m_nSpp, temp, m_nWidth * m_nSpp);
//    }
    
	// Check the alpha
	m_bHasAlpha = NO;
	for (i = 0; i < m_nWidth * m_nHeight; i++) {
		if (pData[(i + 1) * m_nSpp - 1] != 255)
			m_bHasAlpha = YES;
	}
	
	// Unpremultiply the image if required
	#ifdef MACOS_10_4_COMPILE
	if (m_bHasAlpha && !((format & NSAlphaNonpremultipliedBitmapFormat) >> 1)) {
	#endif
		unpremultiplyBitmap(m_nSpp, pData, pData, m_nWidth * m_nHeight);
	#ifdef MACOS_10_4_COMPILE
	}
	#endif
    
    //modify by lcz
    if (!m_pImageData) {
        m_pImageData = [[PSSecureImageData alloc] initDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    }else{
        [m_pImageData reInitDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    }

//    [m_pImageData reInitDataWithBuffer:pData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    
    [self refreshTotalToRender];
		
	return self;
}

@end
