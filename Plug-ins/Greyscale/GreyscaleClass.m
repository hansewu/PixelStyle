#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import "GreyscaleClass.h"

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

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation GreyscaleClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	
	return self;
}

- (int)type
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Convert to Grayscale" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, k, width, spp, channel;
	CMBitmap srcBitmap, destBitmap;
	CMProfileRef srcProf, destProf;
	CMDeviceID device;
	CMDeviceProfileID deviceID;
	CMProfileLocation profileLoc;
	CMProfileRef *profile;
	CMWorldRef cw;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	CMGetDefaultDevice(cmDisplayDeviceClass, &device);
	CMGetDeviceDefaultProfileID(cmDisplayDeviceClass, device, &deviceID);
	CMGetDeviceProfile(cmDisplayDeviceClass, device, deviceID, &profileLoc);
	CMOpenProfile(&srcProf, &profileLoc);
	CMGetDefaultProfileBySpace(cmGrayData, &destProf);
	NCWNewColorWorld(&cw, srcProf, destProf);
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {

		pos = j * width + selection.origin.x;

		if (channel == kPrimaryChannels) {
			srcBitmap.image = (char *)&(data[pos * 3]);
			srcBitmap.width = selection.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = selection.size.width * 3;
			srcBitmap.pixelSize = 8 * 3;
			srcBitmap.space = cmRGB24Space;
		}
		else {
			srcBitmap.image = (char *)&(data[pos * 4]);
			srcBitmap.width = selection.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = selection.size.width * 4;
			srcBitmap.pixelSize = 8 * 4;
			srcBitmap.space = cmRGBA32Space;
		}

		destBitmap.image = (char *)&(overlay[pos * 4]);
		destBitmap.width = selection.size.width;
		destBitmap.height = 1;
		destBitmap.rowBytes = selection.size.width;
		destBitmap.pixelSize = 8;
		destBitmap.space = cmGray8Space;
		
		
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
				
		//for (i = selection.size.width; i >= 0; i--)
        for (i = selection.size.width-1; i >= 0; i--)
        {
			overlay[(pos + i) * 4] = overlay[pos * 4 + i];
			overlay[(pos + i) * 4 + 1] = overlay[pos * 4 + i];
			overlay[(pos + i) * 4 + 2] = overlay[pos * 4 + i];
			if (channel == kPrimaryChannels)
				overlay[(pos + i) * 4 + 3] = 255;
			else
				overlay[(pos + i) * 4 + 3] = data[(pos + i) * 4 + 3];
			replace[pos + i] = 255;
		}
		
	}
	
	CWDisposeColorWorld(cw);
	CMCloseProfile(srcProf);
	
	[pluginData apply];
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	
	if (pluginData != NULL) {

		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	
	}
	
	return YES;
}

@end
