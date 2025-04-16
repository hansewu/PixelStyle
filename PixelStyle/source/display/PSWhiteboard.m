#import "PSWhiteboard.h"
#import "StandardMerge.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSLayerUndo.h"
#import "PSView.h"
#import "PSSelection.h"
#import "Bitmap.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"

#import "ipaintapi.h"

//No define in ColorSyncDeprecated.h
/* Standard type for ColorSync and other system error codes */
typedef OSStatus                        CMError DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultDevice(
  CMDeviceClass   deviceClass,
  CMDeviceID *    deviceID)                                   DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDeviceDefaultProfileID(
  CMDeviceClass        deviceClass,
  CMDeviceID           deviceID,
  CMDeviceProfileID *  defaultProfID)                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDeviceProfile(
  CMDeviceClass        deviceClass,
  CMDeviceID           deviceID,
  CMDeviceProfileID    profileID,
  CMProfileLocation *  profileLoc)                            DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMOpenProfile(
  CMProfileRef *             prof,
  const CMProfileLocation *  theProfile)                      DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultProfileBySpace(
  OSType          dataColorSpace,
  CMProfileRef *  prof)                                       DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
NCWNewColorWorld(
  CMWorldRef *   cw,
  CMProfileRef   src,
  CMProfileRef   dst)                                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CWMatchBitmap(
  CMWorldRef            cw,
  CMBitmap *            bitmap,
  CMBitmapCallBackUPP   progressProc,
  void *                refCon,
  CMBitmap *            matchedBitmap)                        DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN void
CWDisposeColorWorld(CMWorldRef cw)                            DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMCloseProfile(CMProfileRef prof)                             DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultProfileBySpace(
  OSType          dataColorSpace,
  CMProfileRef *  prof)                                       DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CWMatchColors(
  CMWorldRef   cw,
  CMColor *    myColors,
  size_t       count)                                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

extern BOOL useAltiVec;

extern IntPoint gScreenResolution;

@implementation PSWhiteboard

- (id)initWithDocument:(id)doc
{
	CMProfileRef destProf;
	int layerWidth, layerHeight;
	NSString *pluginPath;
	NSBundle *bundle;
	
	// Remember the document we are representing
	m_idDocument = doc;
	
	// Initialize the compostior
	m_idCompositor = NULL;
	if (useAltiVec)
    {
		pluginPath = [NSString stringWithFormat:@"%@/CompositorAV.bundle", [gMainBundle builtInPlugInsPath]];
		if ([gFileManager fileExistsAtPath:pluginPath])
        {
			bundle = [NSBundle bundleWithPath:pluginPath];
			if (bundle && [bundle principalClass])
            {
				m_idCompositor = [[bundle principalClass] alloc];
			}
		}
	}
	if (m_idCompositor == NULL)	m_idCompositor = [PSCompositor alloc];
	[m_idCompositor initWithDocument:m_idDocument];
	
	// Record the width, height and use of greys
	m_nWidth = [(PSContent *)[m_idDocument contents] width];
	m_nHeight = [(PSContent *)[m_idDocument contents] height];
    
    if([[m_idDocument contents] activeLayer])
    {
        layerWidth = [(PSLayer *)[[m_idDocument contents] activeLayer] width];
        layerHeight = [(PSLayer *)[[m_idDocument contents] activeLayer] height];
    }
    else
    {
        layerWidth = 0;
        layerHeight = 0;
    }
    

	
	// Record the samples per pixel used by the whiteboard
	m_nSpp = [[m_idDocument contents] spp];
	
	// Set the view type to show all channels
	m_nViewType = kAllChannelsView;
	m_bCMYKPreview = NO;
	
	// Allocate the whiteboard data
//	m_pData = (unsigned char *)malloc(make_128(m_nWidth * m_nHeight * m_nSpp));
	
    unsigned char * overlay = (unsigned char *)malloc(make_128(layerWidth * layerHeight * m_nSpp));
	memset(overlay, 0, layerWidth * layerHeight * m_nSpp);
    BOOL alphaPremulti = [(PSLayer *)[[m_idDocument contents] activeLayer] alphaPremultiplied];
    m_pOverlayData = [[PSSecureImageData alloc] initDataWithBuffer:overlay width:layerWidth height:layerHeight spp:m_nSpp alphaPremultiplied:alphaPremulti];
    
	m_pReplace = (unsigned char *)malloc(make_128(layerWidth * layerHeight));
	memset(m_pReplace, 0, layerWidth * layerHeight);
	m_pAltData = NULL;
    
//    [self createCGLayerTotoal];
//    [self createCGLayerTempOverLayer];
	
	// Create the colour world
	OpenDisplayProfile(&m_cpDisplayProf);
	m_ccsDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(m_cpDisplayProf);
	CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
	//NCWNewColorWorld(&m_cwColourSpace, m_cpDisplayProf, destProf);
    m_cwColourSpace = nil;
    
	// Set the locking thread to NULL
	m_thrLockingThread = NULL;
	
    
    m_dataLock = [[NSRecursiveLock alloc] init];
   
    
	return self;
}

- (PSCompositor *)compositor
{
	return m_idCompositor;
}

- (void)dealloc
{	
	// Free the room we took for everything else
	if (m_cpDisplayProf) CloseDisplayProfile(m_cpDisplayProf);
	if (m_ccsDisplayProf) CGColorSpaceRelease(m_ccsDisplayProf);
	if (m_idCompositor) [m_idCompositor autorelease];
	if (m_imgWhiteboard) [m_imgWhiteboard autorelease];
	if (m_cwColourSpace) CWDisposeColorWorld(m_cwColourSpace);
	if (m_pData) free(m_pData);
	//if (m_pOverlay) free(m_pOverlay);
    if (m_pOverlayData) [m_pOverlayData autorelease];
    
	if (m_pReplace) free(m_pReplace);
	if (m_pAltData) free(m_pAltData);
    if (m_dataLock){[m_dataLock release]; m_dataLock = nil;}

//    if(m_mdStrokeBufferCache)
//        [m_mdStrokeBufferCache release];
//
//    if(m_hCanvas) IP_DestroyCanvas(m_hCanvas);
    
    [self destroyCGLayerTotoal];
    
	[super dealloc];
}

- (void)setOverlayBehaviour:(int)value
{
	m_nOverlayBehaviour = value;
}

- (int)getOverlayBehaviour
{
    return m_nOverlayBehaviour;
}

- (void)setOverlayOpacity:(int)value
{
	m_nOverlayOpacity = value;
}

- (int)getOverlayOpacity
{
    return m_nOverlayOpacity;
}

- (IntRect)applyOverlay
{
	id layer;
	int leftOffset, rightOffset, topOffset, bottomOffset;
	int i, j, k, srcLoc, selectedChannel;
	int xoff, yoff;
	unsigned char  *mask;
	int lwidth, lheight, selectOpacity, t1;
	IntRect rect, selectRect;
	BOOL overlayOkay, overlayReplacing;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	BOOL floating;
	
	// Fill out the local variables
	selectRect = [[m_idDocument selection] localRect];
	selectedChannel = [[m_idDocument contents] selectedChannel];
	layer = [[m_idDocument contents] activeLayer];
	floating = [layer floating];

	lwidth = [(PSLayer *)layer width];
	lheight = [(PSLayer *)layer height];
	xoff = [layer xoff];
	yoff = [layer yoff];
	mask = [(PSSelection*)[m_idDocument selection] mask];
	maskOffset = [[m_idDocument selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[m_idDocument selection] maskSize];
	overlayReplacing = (m_nOverlayBehaviour == kReplacingBehaviour);
	
	// Calculate offsets
	leftOffset = lwidth + 1;
	rightOffset = -1;
	bottomOffset = -1;
	topOffset = lheight + 1;
    
    IMAGE_DATA overlayData = [m_pOverlayData lockDataForWrite];
    unsigned char * overlay = overlayData.pBuffer;
    if (overlayData.nWidth != lwidth || overlayData.nHeight != lheight)
    {
        [m_pOverlayData unLockDataForWrite];
        return rect;
    }
    
	for (j = 0; j < lheight; j++)
    {
		for (i = 0; i < lwidth; i++)
        {
			if (overlayReplacing)
            {
				if (m_pReplace[j * lwidth + i] != 0)
                {
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
				else
                {
					overlay[(j * lwidth + i + 1) * m_nSpp - 1] = 0;
				}
			}
			else
            {
				if (overlay[(j * lwidth + i + 1) * m_nSpp - 1] != 0)
                {
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
			}
		}
	}
	
	// If we didn't find any pixels, all of the offsets will be in their original
	// state, but we only need to test one ...
    if (leftOffset < 0)
    {
        [m_pOverlayData unLockDataForWrite];
        return IntMakeRect(0, 0, 0, 0);
    }
	
	// Create the rectangle
	rect = IntMakeRect(leftOffset, topOffset, rightOffset - leftOffset, bottomOffset - topOffset);
	
	// Allow the undo
	[[layer seaLayerUndo] takeSnapshot:rect automatic:YES];
	
	// Go through each column and row
	for (j = rect.origin.y; j < rect.origin.y + rect.size.height; j++)
    {
		for (i = rect.origin.x; i < rect.origin.x + rect.size.width; i++)
        {
			
			// Determine the source location
			srcLoc = (j * lwidth + i) * m_nSpp;
			
			// Check if we should apply the m_pOverlay for this pixel
			overlayOkay = NO;
			switch (m_nOverlayBehaviour)
            {
				case kReplacingBehaviour:
				case kMaskingBehaviour:
					selectOpacity = m_pReplace[j * lwidth + i];
				break;
				default:
					selectOpacity = m_nOverlayOpacity;
				break;
			}
            
			if ([[m_idDocument selection] active])
            {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect))
                {
					overlayOkay = YES;
					if (mask && !floating)
						selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
				}
			}
			else
            {
				overlayOkay = YES;
			}
			
			// Don't do anything if there's no point
			if (selectOpacity == 0)
				overlayOkay = NO;
			
			// Apply the m_pOverlay
			if (overlayOkay)
            {
                unsigned char *srcPtr = [(PSLayer *)layer getRawData];
                
                if(!srcPtr)
                {
                    [m_pOverlayData unLockDataForWrite];
                    return rect;
                }
                
				if (selectedChannel == kAllChannels && !floating)
                {
					
					// For the general case
					switch (m_nOverlayBehaviour)
                    {
						case kErasingBehaviour:
							eraseMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						case kReplacingBehaviour:
							replaceMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							specialMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
				else if (selectedChannel == kPrimaryChannels || floating)
                {
				
					// For the primary channels
					switch (m_nOverlayBehaviour)
                    {
						case kReplacingBehaviour:
							replacePrimaryMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							primaryMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity, NO);
						break;
					}
					
				}
				else if (selectedChannel == kAlphaChannel)
                {
					
					// For the alpha channels
					switch (m_nOverlayBehaviour)
                    {
						case kReplacingBehaviour:
							replaceAlphaMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							alphaMerge(m_nSpp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
                [(PSLayer *)layer unLockRawData];
			}
			
			// Clear the m_pOverlay
			for (k = 0; k < m_nSpp; k++)
				overlay[srcLoc + k] = 0;
			m_pReplace[j * lwidth + i] = 0;
			
		}
	}
    
	[m_pOverlayData unLockDataForWrite];
    
    // add by lcz
    [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
    
	// Put the rectangle in the document's co-ordinates
	rect.origin.x += xoff;
	rect.origin.y += yoff;
	
	// Reset the overlay's opacity and behaviour
	m_nOverlayOpacity = 0;
	m_nOverlayBehaviour = kNormalBehaviour;

	
	return rect;
}

- (void)clearOverlay
{
	id layer = [[m_idDocument contents] activeLayer];

    IMAGE_DATA imageData = [m_pOverlayData lockDataForWrite];
    memset(imageData.pBuffer, 0, [(PSLayer *)layer width] * [(PSLayer *)layer height] * m_nSpp);
    [m_pOverlayData unLockDataForRead];
	//memset(m_pOverlay, 0, [(PSLayer *)layer width] * [(PSLayer *)layer height] * m_nSpp);
	memset(m_pReplace, 0, [(PSLayer *)layer width] * [(PSLayer *)layer height]);
	m_nOverlayOpacity = 0;
	m_nOverlayBehaviour = kNormalBehaviour;
}

- (PSSecureImageData*)overlaySecureData
{
    return m_pOverlayData;
}
// for plugin only 不要删除，有时间要统一到 overlaySecureData
- (unsigned char *)overlay
{
    IMAGE_DATA imageData = [m_pOverlayData lockDataForWrite];
    [m_pOverlayData unLockDataForWrite];
	return imageData.pBuffer;
}

- (unsigned char *)replace
{
	return m_pReplace;
}

- (BOOL)whiteboardIsLayerSpecific
{
	return m_nViewType == kPrimaryChannelsView || m_nViewType == kAlphaChannelView;
}

- (void)readjust
{	
	// Resize the memory allocated to the data 
	m_nWidth = [(PSContent *)[m_idDocument contents] width];
	m_nHeight = [(PSContent *)[m_idDocument contents] height];
	
	// Change the samples per pixel if required
	if (m_nSpp != [[m_idDocument contents] spp])
    {
		m_nSpp = [[m_idDocument contents] spp];
		m_nViewType = kAllChannelsView;
		m_bCMYKPreview = NO;
	}
	
	// Revise the data
//	if (m_pData) free(m_pData);
//	m_pData = (unsigned char *)malloc(make_128(m_nWidth * m_nHeight * m_nSpp));
    
    
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	//if (m_pOverlay) free(m_pOverlay);
	unsigned char * overlay = (unsigned char *)malloc(make_128([(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height] * m_nSpp));
	memset(overlay, 0, [(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height] * m_nSpp);
    BOOL alphaPremulti = [(PSLayer *)[[m_idDocument contents] activeLayer] alphaPremultiplied];
    [m_pOverlayData reInitDataWithBuffer:overlay width:[(PSLayer *)[[m_idDocument contents] activeLayer] width] height:[(PSLayer *)[[m_idDocument contents] activeLayer] height] spp:m_nSpp alphaPremultiplied:alphaPremulti];
    
    
//    [self createCGLayerTempOverLayer];
	if (m_pReplace) free(m_pReplace);
	m_pReplace = (unsigned char *)malloc(make_128([(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height]));
	memset(m_pReplace, 0, [(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height]);

	// Update ourselves  //注释add by wyl合成整个图层，当前层数据没有变换
//	[self update];
}

- (void)readjustLayer:(BOOL)update
{
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	//if (m_pOverlay) free(m_pOverlay);
	unsigned char * overlay = (unsigned char *)malloc(make_128([(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height] * m_nSpp));
   
	memset(overlay, 0, [(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height] * m_nSpp);
    BOOL alphaPremulti = [(PSLayer *)[[m_idDocument contents] activeLayer] alphaPremultiplied];
    [m_pOverlayData reInitDataWithBuffer:overlay width:[(PSLayer *)[[m_idDocument contents] activeLayer] width] height:[(PSLayer *)[[m_idDocument contents] activeLayer] height] spp:m_nSpp alphaPremultiplied:alphaPremulti];
    
//    [self createCGLayerTempOverLayer];
	if (m_pReplace) free(m_pReplace);
	m_pReplace = (unsigned char *)malloc(make_128([(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height]));
	memset(m_pReplace, 0, [(PSLayer *)[[m_idDocument contents] activeLayer] width] * [(PSLayer *)[[m_idDocument contents] activeLayer] height]);
	
	// Update ourselves
//	[self update];
    if (update)
        [self update];
}

- (void)readjustAltData:(BOOL)update
{
	id contents = [m_idDocument contents];
	int selectedChannel = [contents selectedChannel];
	BOOL trueView = [contents trueView];
	id layer;
	int xwidth, xheight;
	
	// Free existing data
	m_nViewType = kAllChannelsView;
	if (m_pAltData) free(m_pAltData);
	m_pAltData = NULL;
	
	// Change layer if appropriate
	if ([[m_idDocument selection] floating])
    {
		layer = [contents layer:[contents activeLayerIndex] + 1];
	}
	else
    {
		layer = [contents activeLayer];
	}
	
	// Create room for alternative data if necessary
	if (!trueView && selectedChannel == kPrimaryChannels)
    {
		m_nViewType = kPrimaryChannelsView;
		xwidth = [(PSLayer *)layer width];
		xheight = [(PSLayer *)layer height];
		m_pAltData = (unsigned char *)malloc(make_128(xwidth * xheight * (m_nSpp - 1)));
	}
	else if (!trueView && selectedChannel == kAlphaChannel)
    {
		m_nViewType = kAlphaChannelView;
		xwidth = [(PSLayer *)layer width];
		xheight = [(PSLayer *)layer height];
		m_pAltData = (unsigned char *)malloc(make_128(xwidth * xheight));
	}
	else if (m_bCMYKPreview && m_nSpp == 4)
    {
		m_nViewType = kCMYKPreviewView;
		xwidth = [(PSContent *)contents width];
		xheight = [(PSContent *)contents height];
		m_pAltData = (unsigned char *)malloc(make_128(xwidth * xheight * 4));
	}
	
	// Update ourselves (if advised to)
	if (update)
		[self update];
}

- (BOOL)CMYKPreview
{
	return m_bCMYKPreview;
}

- (BOOL)canToggleCMYKPreview
{
	return m_nSpp == 4;
}

- (void)toggleCMYKPreview
{
	// Do nothing if we can't do anything
	if (![self canToggleCMYKPreview])
		return;
		
	// Otherwise make the change
	m_bCMYKPreview = !m_bCMYKPreview;
	[self readjustAltData:YES];
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:NO];
}

- (NSColor *)matchColor:(NSColor *)color
{
	CMColor cmColor;
	NSColor *result;
	
	// Determine the RGB color
	cmColor.rgb.red = ([color redComponent] * 65535.0);
	cmColor.rgb.green = ([color greenComponent] * 65535.0);
	cmColor.rgb.blue = ([color blueComponent] * 65535.0);
	
	// Match color
	CWMatchColors(m_cwColourSpace, &cmColor, 1);
	
	// Calculate result
	result = [NSColor colorWithDeviceCyan:(float)cmColor.cmyk.cyan / 65536.0 magenta:(float)cmColor.cmyk.magenta / 65536.0 yellow:(float)cmColor.cmyk.yellow / 65536.0 black:(float)cmColor.cmyk.black / 65536.0 alpha:[color alphaComponent]];
	
	return result;
}

- (void)forcedChannelUpdate
{
	id layer, flayer;
	int layerWidth, layerHeight, lxoff, lyoff;
    unsigned char *layerData, tempSpace[4], tempSpace2[4], *mask;
	int i, j, k, temp, tx, ty, t, selectOpacity, nextOpacity;
	IntRect selectRect, minorUpdateRect;
	IntSize maskSize = IntMakeSize(0, 0);
	IntPoint point, maskOffset = IntMakePoint(0, 0);
	BOOL useSelection, floating;
	
	// Prepare variables for later use
	mask = NULL;
	selectRect = IntMakeRect(0, 0, 0, 0);
	useSelection = [[m_idDocument selection] active];
	floating = [[m_idDocument selection] floating];
	
	if (useSelection && floating)
    {
		layer = [[m_idDocument contents] layer:[[m_idDocument contents] activeLayerIndex] + 1];
	}
	else
    {
		layer = [[m_idDocument contents] activeLayer];
	}
    
	if (useSelection)
    {
		if (floating)
        {
			flayer = [[m_idDocument contents] activeLayer];
			selectRect = IntMakeRect([(PSLayer *)flayer xoff] - [(PSLayer *)layer xoff], [(PSLayer *)flayer yoff] - [(PSLayer *)layer yoff], [(PSLayer *)flayer width], [(PSLayer *)flayer height]);
		}
		else
        {
			selectRect = [[m_idDocument selection] globalRect];
		}
        
		mask = (unsigned char *)[[m_idDocument selection] mask];
		maskOffset = [[m_idDocument selection] maskOffset];
		maskSize = [[m_idDocument selection] maskSize];
	}
    
	selectOpacity = 255;
	layerWidth = [(PSLayer *)layer width];
	layerHeight = [(PSLayer *)layer height];
	lxoff = [(PSLayer *)layer xoff];
	lyoff = [(PSLayer *)layer yoff];
	layerData = [(PSLayer *)layer getRawData];
	
	// Determine the minor update rect
	if (m_bUseUpdateRect)
    {
		minorUpdateRect = m_sUpdateRect;
		IntOffsetRect(&minorUpdateRect, -[layer xoff],  -[layer yoff]);
		minorUpdateRect = IntConstrainRect(minorUpdateRect, IntMakeRect(0, 0, layerWidth, layerHeight));
	}
	else
    {
		minorUpdateRect = IntMakeRect(0, 0, layerWidth, layerHeight);
	}
    
    unsigned char * overlay = [m_pOverlayData lockDataForWrite].pBuffer;
	
    unsigned char *floatingData = [(PSLayer *)[[m_idDocument contents] activeLayer] getRawData];
	// Go through pixel-by-pixel working out the channel update
	for (j = minorUpdateRect.origin.y; j < minorUpdateRect.origin.y + minorUpdateRect.size.height; j++)
    {
		for (i = minorUpdateRect.origin.x; i < minorUpdateRect.origin.x + minorUpdateRect.size.width; i++)
        {
			temp = j * layerWidth + i;
			
			// Determine what we are compositing to
			if (m_nViewType == kPrimaryChannelsView)
            {
				for (k = 0; k < m_nSpp - 1; k++)
					tempSpace[k] = layerData[temp * m_nSpp + k];
				tempSpace[m_nSpp - 1] =  0xFF;
			}
			else
            {
				tempSpace[0] = layerData[(temp + 1) * m_nSpp - 1];
				tempSpace[1] =  0xFF;
			}
			
			// Make changes necessary if a selection is active
			if (useSelection)
            {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect))
                {
					if (floating)
                    {
						tx = i - selectRect.origin.x;
						ty = j - selectRect.origin.y;
                        
                        
						if (m_nViewType == kPrimaryChannelsView)
                        {
							memcpy(&tempSpace2, &(floatingData[(ty * selectRect.size.width + tx) * m_nSpp]), m_nSpp);
						}
						else
                        {
							tempSpace2[0] = floatingData[(ty * selectRect.size.width + tx) * m_nSpp];
							tempSpace2[1] = floatingData[(ty * selectRect.size.width + tx + 1) * m_nSpp - 1];
						}
						normalMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, 255);
					}
					if (mask)
						selectOpacity = mask[(point.y - selectRect.origin.y - maskOffset.y) * maskSize.width + (point.x - selectRect.origin.x - maskOffset.x)];
				}
			}
			
			// Check for floating layer
			if (useSelection && floating)
            {
			
				// Insert the overlay
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect))
                {
					tx = i - selectRect.origin.x;
					ty = j - selectRect.origin.y;
					if (selectOpacity > 0)
                    {
						if (m_nViewType == kPrimaryChannelsView)
                        {
							memcpy(&tempSpace2, &(overlay[(ty * selectRect.size.width + tx) * m_nSpp]), m_nSpp);
							if (m_nOverlayOpacity < 255)
								tempSpace2[m_nSpp - 1] = int_mult(tempSpace2[m_nSpp - 1], m_nOverlayOpacity, t);
						}
						else
                        {
							tempSpace2[0] = overlay[(ty * selectRect.size.width + tx) * m_nSpp];
							if (m_nOverlayOpacity == 255)
								tempSpace2[1] = overlay[(ty * selectRect.size.width + tx + 1) * m_nSpp - 1];
							else
								tempSpace2[1] = int_mult(overlay[(ty * selectRect.size.width + tx + 1) * m_nSpp - 1], m_nOverlayOpacity, t);
						}
                        
						if (m_nOverlayBehaviour == kReplacingBehaviour)
                        {
							nextOpacity = int_mult(m_pReplace[ty * selectRect.size.width + tx], selectOpacity, t); 
							replaceMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else if (m_nOverlayBehaviour ==  kMaskingBehaviour)
                        {
							nextOpacity = int_mult(m_pReplace[ty * selectRect.size.width + tx], selectOpacity, t); 
							normalMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else
                        {
							normalMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
						}
					}
				}
				
			}
			else {
				
				// Insert the m_pOverlay
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect) || !useSelection)
                {
					if (selectOpacity > 0)
                    {
						if (m_nViewType == kPrimaryChannelsView)
                        {
							memcpy(&tempSpace2, &(overlay[temp * m_nSpp]), m_nSpp);
							if (m_nOverlayOpacity < 255)
								tempSpace2[m_nSpp - 1] = int_mult(tempSpace2[m_nSpp - 1], m_nOverlayOpacity, t);
						}
						else
                        {
							tempSpace2[0] = overlay[temp * m_nSpp];
							if (m_nOverlayOpacity == 255)
								tempSpace2[1] = overlay[(temp + 1) * m_nSpp - 1];
							else
								tempSpace2[1] = int_mult(overlay[(temp + 1) * m_nSpp - 1], m_nOverlayOpacity, t);
						}
						if (m_nOverlayBehaviour == kReplacingBehaviour)
                        {
							nextOpacity = int_mult(m_pReplace[temp], selectOpacity, t); 
							replaceMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else if (m_nOverlayBehaviour ==  kMaskingBehaviour)
                        {
							nextOpacity = int_mult(m_pReplace[temp], selectOpacity, t); 
							normalMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else
							normalMerge((m_nViewType == kPrimaryChannelsView) ? m_nSpp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
					}
				}
				
			}
			
			// Finally update the channel
			if (m_nViewType == kPrimaryChannelsView)
            {
				for (k = 0; k < m_nSpp - 1; k++)
					m_pAltData[temp * (m_nSpp - 1) + k] = tempSpace[k];
			}
			else
            {
				m_pAltData[j * layerWidth + i] = tempSpace[0];
			}
			
		}
	}
    [m_pOverlayData unLockDataForWrite];
    [(PSLayer *)layer unLockRawData];
    [(PSLayer *)[[m_idDocument contents] activeLayer] unLockRawData];
}

- (void)forcedCMYKUpdate:(IntRect)majorUpdateRect
{
	unsigned char *tempData;
	CMBitmap srcBitmap, destBitmap;
	int i;

	// Define the source
	if (m_bUseUpdateRect)
    {
		for (i = 0; i < majorUpdateRect.size.height; i++)
        {
		
			// Define the source
			tempData = (unsigned char *)malloc(majorUpdateRect.size.width * 3);
			stripAlphaToWhite(4, tempData, m_pData + ((majorUpdateRect.origin.y + i) * m_nWidth + majorUpdateRect.origin.x) * 4, majorUpdateRect.size.width);
			srcBitmap.image = (char *)tempData;
			srcBitmap.width = majorUpdateRect.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = majorUpdateRect.size.width * 3;
			srcBitmap.pixelSize = 8 * 3;
			srcBitmap.space = cmRGB24Space;
		
			// Define the destination
			destBitmap = srcBitmap;
			destBitmap.image = (char *)m_pAltData + ((majorUpdateRect.origin.y + i) * m_nWidth + majorUpdateRect.origin.x) * 4;
			destBitmap.rowBytes = majorUpdateRect.size.width * 4;
			destBitmap.pixelSize = 8 * 4;
			destBitmap.space = cmCMYK32Space;
			
			// Execute the conversion
			CWMatchBitmap(m_cwColourSpace, &srcBitmap, NULL, 0, &destBitmap);
			
			// Clean up after ourselves
			free(tempData);
			
		}
	}
	else
    {
	
		// Define the source
		tempData = (unsigned char *)malloc(m_nWidth * m_nHeight * 3);
		stripAlphaToWhite(4, tempData, m_pData, m_nWidth * m_nHeight);
		srcBitmap.image = (char *)tempData;
		srcBitmap.width = m_nWidth;
		srcBitmap.height = m_nHeight;
		srcBitmap.rowBytes = m_nWidth * 3;
		srcBitmap.pixelSize = 8 * 3;
		srcBitmap.space = cmRGB24Space;
	
		// Define the destination
		destBitmap.image = (char *)m_pAltData;
		destBitmap.width = m_nWidth;
		destBitmap.height = m_nHeight;
		destBitmap.rowBytes = m_nWidth * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmCMYK32Space;
		
		// Execute the conversion
		CWMatchBitmap(m_cwColourSpace, &srcBitmap, NULL, 0, &destBitmap);

		// Clean up after ourselves
		free(tempData);

	}
}

/*
- (void)forcedUpdate
{
	int i, count = 0, layerCount = [[m_idDocument contents] layerCount];
	IntRect majorUpdateRect;
	CompositorOptions options;
	BOOL floating;

	// Determine the major update rect
	if (m_bUseUpdateRect)
    {
		majorUpdateRect = IntConstrainRect(m_sUpdateRect, IntMakeRect(0, 0, m_nWidth, m_nHeight));
	}
	else
    {
		majorUpdateRect = IntMakeRect(0, 0, m_nWidth, m_nHeight);
	}
	
	// Handle non-channel updates here
	if (majorUpdateRect.size.width > 0 && majorUpdateRect.size.height > 0)
    {
		
		// Clear the whiteboard
		for (i = 0; i < majorUpdateRect.size.height; i++)
			memset(m_pData + ((majorUpdateRect.origin.y + i) * m_nWidth + majorUpdateRect.origin.x) * m_nSpp, 0, majorUpdateRect.size.width * m_nSpp);
			
		// Determine how many layers are visible
		for (i = 0; count < 2 && i < layerCount; i++)
        {
			if ([[[m_idDocument contents] layer:i] visible])
				count++;
		}
		
		// Set the composting options
		options.spp = m_nSpp;
		options.forceNormal = (count == 1);
		options.rect = majorUpdateRect;
		options.destRect = IntMakeRect(0, 0, m_nWidth, m_nHeight);
		options.overlayOpacity = m_nOverlayOpacity;
		options.overlayBehaviour = m_nOverlayBehaviour;
		options.useSelection = NO;
        
        
        if ([[m_idDocument selection] floating])
        {
            
            // Go through compositing each visible layer
            for (i = layerCount - 1; i >= 0; i--)
            {
                if (i >= 1) floating = [[[m_idDocument contents] layer:i - 1] floating];
                else floating = NO;
                if ([[[m_idDocument contents] layer:i] visible])
                {
                    options.insertOverlay = floating;
                    if (floating)
                        [m_idCompositor compositeLayer:[[m_idDocument contents] layer:i] withFloat:[[m_idDocument contents] layer:i - 1] andOptions:options];
//                        if(i == [[m_idDocument contents] activeLayerIndex])
//                        {
//                            options.insertOverlay = YES;
//                            options.useSelection = (i == [[m_idDocument contents] activeLayerIndex]) && [[m_idDocument selection] active];
//                            [m_idCompositor renderOneLayerToCGLayer:[[m_idDocument contents] layer:i] withOptions:options];
//                        }
                    else
                        if(i == [[m_idDocument contents] activeLayerIndex])
                        {
                            options.insertOverlay = YES;
                            options.useSelection = (i == [[m_idDocument contents] activeLayerIndex]) && [[m_idDocument selection] active];
                            [m_idCompositor renderOneLayerToCGLayer:[[m_idDocument contents] layer:i] withOptions:options];
                        }
                }
                if (floating) i--;
            }
            
        }
        else
        {
            // Go through compositing each visible layer
            for (i = layerCount - 1; i >= 0; i--)
            {
                if ([[[m_idDocument contents] layer:i] visible])
                {
                    if(i == [[m_idDocument contents] activeLayerIndex])
                    {
                        options.insertOverlay = YES;
                        options.useSelection = (i == [[m_idDocument contents] activeLayerIndex]) && [[m_idDocument selection] active];
                        [m_idCompositor renderOneLayerToCGLayer:[[m_idDocument contents] layer:i] withOptions:options];
                    }
                }
            }
            
        }

        
//        CGLayerRef cgLayerTotoal = [[m_idDocument whiteboard] getCGLayerTotoal];
//        CGContextRef context = CGLayerGetContext(cgLayerTotoal);
//        CGContextClearRect(context, CGRectMake(0, 0, m_nWidth, m_nHeight));
//        
//		if ([[m_idDocument selection] floating])
//        {
//	
//			// Go through compositing each visible layer
//			for (i = layerCount - 1; i >= 0; i--)
//            {
//				if (i >= 1) floating = [[[m_idDocument contents] layer:i - 1] floating];
//				else floating = NO;
//				if ([[[m_idDocument contents] layer:i] visible])
//                {
//					options.insertOverlay = floating;
//					if (floating)
//						[m_idCompositor compositeLayer:[[m_idDocument contents] layer:i] withFloat:[[m_idDocument contents] layer:i - 1] andOptions:options];
//					else
////						[m_idCompositor compositeLayer:[[m_idDocument contents] layer:i] withOptions:options];
//				}
//				if (floating) i--;
//			}
//			
//		}
//		else
//        {
//            
//            
//			// Go through compositing each visible layer
//			for (i = layerCount - 1; i >= 0; i--)
//            {
//				if ([[[m_idDocument contents] layer:i] visible])
//                {
//                    options.insertOverlay = (i == [[m_idDocument contents] activeLayerIndex]); // NO;//
//					options.useSelection = (i == [[m_idDocument contents] activeLayerIndex]) && [[m_idDocument selection] active];
////					[m_idCompositor compositeLayer:[[m_idDocument contents] layer:i] withOptions:options];
//				}
//			}
//			
//		}
		
	}
	
	// Handle channel updates here
	if (m_nViewType == kPrimaryChannelsView || m_nViewType == kAlphaChannelView)
    {
		[self forcedChannelUpdate];
	}
	
	// If the user has requested a CMYK preview take the extra steps necessary
	if (m_nViewType == kCMYKPreviewView)
    {
		[self forcedCMYKUpdate:majorUpdateRect];
	}
}*/

- (void)update
{
//	m_bUseUpdateRect = NO;
//	[self forcedUpdate];
//    [[m_idDocument docView] setNeedsDisplay:YES];
    
	[[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)Refresh:(IntRect)rect isAllContent:(BOOL)bAllContent
{
    if (bAllContent)
    {
        [[m_idDocument docView] setNeedsDisplay:YES];
        return;
    }
    
    NSRect displayUpdateRect = IntRectMakeNSRect(rect);
    float zoom = [[m_idDocument docView] zoom];
    int xres = [[m_idDocument contents] xres], yres = [[m_idDocument contents] yres];
    
    if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
    {
        displayUpdateRect.origin.x /= ((float)xres / gScreenResolution.x);
        displayUpdateRect.size.width /= ((float)xres / gScreenResolution.x);
    }
    if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
    {
        displayUpdateRect.origin.y /= ((float)yres / gScreenResolution.y);
        displayUpdateRect.size.height /= ((float)yres / gScreenResolution.y);
    }
    displayUpdateRect.origin.x *= zoom;
    displayUpdateRect.size.width *= zoom;
    displayUpdateRect.origin.y *= zoom;
    displayUpdateRect.size.height *= zoom;
    
    // Free us from hairlines
    displayUpdateRect.origin.x = floor(displayUpdateRect.origin.x);
    displayUpdateRect.origin.y = floor(displayUpdateRect.origin.y);
    displayUpdateRect.size.width = ceil(displayUpdateRect.size.width) + 1.0;
    displayUpdateRect.size.height = ceil(displayUpdateRect.size.height) + 1.0;
    
    // Now do the rest of the update
    m_bUseUpdateRect = YES;
    m_sUpdateRect = rect;
    
    
    [[m_idDocument docView] setNeedsDisplayInRect:displayUpdateRect];
}

- (void)updateColorWorld
{
	CMProfileRef destProf;
	
	if (m_cwColourSpace) CWDisposeColorWorld(m_cwColourSpace);
	if (m_cpDisplayProf) CloseDisplayProfile(m_cpDisplayProf);
	if (m_ccsDisplayProf) CGColorSpaceRelease(m_ccsDisplayProf);
    
	OpenDisplayProfile(&m_cpDisplayProf);
	m_ccsDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(m_cpDisplayProf);
	CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
	//NCWNewColorWorld(&m_cwColourSpace, m_cpDisplayProf, destProf);
    m_cwColourSpace = nil;
    
	if ([self CMYKPreview])
		[self update];
}

- (IntRect)imageRect
{
	id layer;
	
	if (m_nViewType == kPrimaryChannelsView || m_nViewType == kAlphaChannelView)
    {
		if ([[m_idDocument selection] floating])
			layer = [[m_idDocument contents] layer:[[m_idDocument contents] activeLayerIndex] + 1];
		else
			layer = [[m_idDocument contents] activeLayer];
		return IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
	}
	else
    {
		return IntMakeRect(0, 0, m_nWidth, m_nHeight);
	}
}

- (NSImage *)image
{
	NSBitmapImageRep *imageRep;
	NSBitmapImageRep *altImageRep = NULL;
	id contents = [m_idDocument contents];
	int xwidth, xheight;
	id layer;
	
	if (m_imgWhiteboard) [m_imgWhiteboard autorelease];
	m_imgWhiteboard = [[NSImage alloc] init];
	
	if (m_pAltData)
    {
		if ([[m_idDocument selection] floating])
        {
			layer = [contents layer:[contents activeLayerIndex] + 1];
		}
		else
        {
			layer = [contents activeLayer];
		}
		if (m_nViewType == kPrimaryChannelsView)
        {
			xwidth = [(PSLayer *)layer width];
			xheight = [(PSLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pAltData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:m_nSpp - 1 hasAlpha:NO isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:xwidth * (m_nSpp - 1) bitsPerPixel:8 * (m_nSpp - 1)];
		}
		else if (m_nViewType == kAlphaChannelView)
        {
			xwidth = [(PSLayer *)layer width];
			xheight = [(PSLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pAltData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:xwidth * 1 bitsPerPixel:8];
		}
		else if (m_nViewType == kCMYKPreviewView)
        {
			xwidth = [(PSContent *)contents width];
			xheight = [(PSContent *)contents height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pAltData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:4 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceCMYKColorSpace bytesPerRow:xwidth * 4 bitsPerPixel:8 * 4];
		}
		[m_imgWhiteboard addRepresentation:altImageRep];
	}
	else
    {
		imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
		[m_imgWhiteboard addRepresentation:imageRep];
	}
	
	return m_imgWhiteboard;
}

- (NSImage *)printableImage
{
//	NSBitmapImageRep *imageRep;
//	
//	if (m_imgWhiteboard) [m_imgWhiteboard autorelease];
//	m_imgWhiteboard = [[NSImage alloc] init];
//	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
//	[m_imgWhiteboard addRepresentation:imageRep];
//	
//	return m_imgWhiteboard;
    
 
    //每次重新生成太浪费，可从PSSynthesizeImageRender获取
    
    float fScreenScale = 1.0; //[[NSScreen mainScreen] backingScaleFactor];
    int nWidth = [(PSContent *)[m_idDocument contents] width];
    int nHeight = [(PSContent *)[m_idDocument contents] height];
    NSSize imageSize = NSMakeSize(nWidth/fScreenScale, nHeight/fScreenScale);
    
    
    //画到NSImage
    NSImage *image = [[[NSImage alloc] initWithSize:NSSizeFromCGSize(imageSize)] autorelease];
    [image lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextConcatCTM(context, CGAffineTransformMakeScale(1/fScreenScale, 1/fScreenScale));
    NSAffineTransform *transform = [NSAffineTransform transform];
  //  [transform translateXBy:0 yBy:nHeight];
    //[transform scaleXBy:1.0 yBy:-1.0];
  //  [transform concat];
    
    [m_idCompositor compositeLayersToContextFull:context];
    CGContextRestoreGState(context);
    
    [image unlockFocus];
    return image;

}

- (unsigned char *)data
{
    [m_dataLock lock];
    
    BOOL needReset = [[m_idDocument docView] getNeedResetCombineData];
    if (needReset) {
        if (m_pData) {
            free(m_pData);
            m_pData = NULL;
        }
    }
    if (!m_pData) {
        //NSLog(@"combined data");
        int width = [(PSContent *)[m_idDocument contents] width];
        int height = [(PSContent *)[m_idDocument contents] height];
        int spp = [(PSContent *)[m_idDocument contents] spp];
        m_pData = malloc(make_128(width * height * spp));
        memset(m_pData, 0, width * height * spp);
        
        CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
        CGContextRef bitmapContext = CGBitmapContextCreate(m_pData, width, height, 8, spp * width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
        assert(bitmapContext);

        [m_idCompositor compositeLayersToContextFull:bitmapContext];
        
        unsigned char temp[spp * width];
        int j;
        for (j = 0; j < height / 2; j++) {
            memcpy(temp, m_pData + (j * width) * spp, spp * width);
            memcpy(m_pData + (j * width) * spp, m_pData + ((height - j - 1) * width) * spp, spp * width);
            memcpy(m_pData + ((height - j - 1) * width) * spp, temp, spp * width);
        }
        
        unpremultiplyBitmap(spp, m_pData, m_pData, width * height);
        
        CGColorSpaceRelease(defaultColorSpace);
        CGContextRelease(bitmapContext);
        
        [self performSelector:@selector(releaseCombinedDataDelay) withObject:NULL afterDelay:5.0];
    }
    
    [m_dataLock unlock];

	return m_pData;
}

- (void)releaseCombinedDataDelay
{
    [m_dataLock lock];
    if (m_pData) {
        free(m_pData);
        m_pData = NULL;
    }
    [m_dataLock unlock];
}

- (unsigned char *)altData
{
	return m_pAltData;
}

- (CGColorSpaceRef)displayProf
{
	return m_ccsDisplayProf;
}

-(void *)getCanvas
{
    return m_hCanvas;
}

/*
 
#define CELL_HEIGHT 64
#define CELL_WIDTH 64
-(void)allocCellBuffer:(unsigned char **)pCellBuf cellX:(int)nCellX cellY:(int)nCellY read:(BOOL)bReadOnly
{
    NSLog(@"allocCellBuffer");
    NSData *data = [m_mdStrokeBufferCache objectForKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
    if(data)
    {
        *pCellBuf = (unsigned char *)[data bytes];
        return;
    }
    
    unsigned char *pCell = malloc(CELL_WIDTH * CELL_HEIGHT * 4);
    memset(pCell, 0, CELL_WIDTH * CELL_HEIGHT * 4);
    
//    unsigned char *overlay = [[m_idDocument whiteboard] overlay];
    
    id layer = [[m_idDocument contents] activeLayer];
    int nWidth = [(PSLayer *)layer width];
    int nHeight = [(PSLayer *)layer height];
    int nSpp = [[m_idDocument contents] spp];
    
    unsigned char *overlay = [layer getRawData];
    IntRect rect = {{nCellX * CELL_WIDTH , nCellY * CELL_HEIGHT}, {CELL_WIDTH, CELL_HEIGHT}};
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, nWidth, nHeight));
    int t1;
    for(int j = 0; j < rect.size.height; j++)
    {
        for(int i = 0; i < rect.size.width; i++)
        {
            float fAlpha = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + (nSpp - 1)];
            pCell[j * CELL_WIDTH * 4 + i * 4 + 3] = fAlpha;
            fAlpha = fmaxf(fminf(fAlpha/255.0, 1.0),0.0);
//            fAlpha = 1.0;
            if (nSpp == 2)
            {
                int nGray = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp] * fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4] = nGray;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 1] = nGray;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 2] = nGray; 
            }
            else
            {
                pCell[j * CELL_WIDTH * 4 + i * 4] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp] * fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 1] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + 1]* fAlpha;
                pCell[j * CELL_WIDTH * 4 + i * 4 + 2] = overlay[(nCellY * CELL_HEIGHT + j)*nWidth*nSpp + nCellX * CELL_WIDTH *nSpp + i * nSpp + 2] * fAlpha;
            }
        }
    }
    
    [(PSLayer *)layer unLockRawData];
    *pCellBuf = pCell;
    
    data = [NSData dataWithBytesNoCopy:*pCellBuf length:CELL_WIDTH * CELL_HEIGHT * 4 freeWhenDone:NO];
    [m_mdStrokeBufferCache setObject:data forKey:[NSString stringWithFormat:@"cellX = %d,cellY = %d",nCellX,nCellY]];
    
    return;
}

-(void)freeAllocCellBuffer
{
    NSEnumerator * enumerator = [m_mdStrokeBufferCache keyEnumerator];
    NSString *sKey;
    //遍历输出
    while(sKey = [enumerator nextObject])
    {
//        NSLog(@"键值为：%@",sKey);
        NSData *data = [m_mdStrokeBufferCache objectForKey:sKey];
        if (data)
        {
            unsigned char *pCellBuf = (unsigned char *)[data bytes];
            free(pCellBuf);
        }
    }
    [m_mdStrokeBufferCache removeAllObjects];
}

//左上角是 0，0
void *IPD_GetTileMemory(void *pContext, int nCellX, int nCellY, int nReadOnly)
{
//    PSWhiteboard *pThis = (PSWhiteboard *)pContext;
    
    unsigned char *pCellBuf = NULL;
    [pContext allocCellBuffer:&pCellBuf cellX:nCellX cellY:nCellY read:nReadOnly];
    return pCellBuf;
}
 
 */

#pragma mark - CGLayer

-(void)createCGLayerTotoal
{
    CGColorSpaceRef defaultColorSpace = NULL;
    defaultColorSpace = (m_nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray();
    
    CGContextRef context = CGBitmapContextCreate(NULL, m_nWidth, m_nHeight, 8, (int)m_nSpp * m_nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(context);
    CGColorSpaceRelease(defaultColorSpace);
    
    if (m_cgLayerTotal) CGLayerRelease(m_cgLayerTotal);
    m_cgLayerTotal = CGLayerCreateWithContext(context, CGSizeMake(m_nWidth, m_nHeight), nil);
    CGContextRelease(context);
}

-(void)destroyCGLayerTotoal
{
    if(m_cgLayerTotal) CGLayerRelease(m_cgLayerTotal);
}

-(CGLayerRef)getCGLayerTotoal
{
    return m_cgLayerTotal;
}


//-(void)createCGLayerTempOverLayer
//{
//    CGColorSpaceRef defaultColorSpace = NULL;
//    defaultColorSpace = (m_nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray();
//    
//    CGContextRef context = CGBitmapContextCreate(m_pOverlay, m_nWidth, m_nHeight, 8, m_nSpp * m_nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
//    assert(context);
//    CGColorSpaceRelease(defaultColorSpace);
//    
//    if (m_cgLayerTempOverlayer) CGLayerRelease(m_cgLayerTempOverlayer);
//    m_cgLayerTempOverlayer = CGLayerCreateWithContext(context, CGSizeMake(m_nWidth, m_nHeight), nil);
//    CGContextRelease(context);
//}

//-(CGLayerRef)getCGLayerBottom
//{
//    return m_cgLayerBottom;
//}

- (PSSecureImageData*)getOverlayImageData
{
    return m_pOverlayData;
}


@end
