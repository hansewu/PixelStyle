#include <opencv2/opencv.hpp>
#import "AISrFourXClass.h"


#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

static CGImageRef getCGImage(NSImage *image, int outWidth, int outHeight)
{
    NSSize newSize = NSMakeSize(outWidth, outHeight);
    NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
    [smallImage lockFocus];
    
    [image setSize: newSize];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationCopy fraction:1.0];
    [smallImage unlockFocus];
    
    CGImageRef imgRef = [smallImage CGImageForProposedRect:nil context:nil hints:nil];
    
    return imgRef;
}

static int  pixelBufferFromCGImage(CGImageRef image, unsigned char *pOutBuf)
{
    CVPixelBufferRef pxbuffer = NULL;
    NSCParameterAssert(NULL != image);
    size_t originalWidth = CGImageGetWidth(image);
    size_t originalHeight = CGImageGetHeight(image);
    
    NSMutableData *imageData = [NSMutableData dataWithLength:originalWidth*originalHeight*4];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate([imageData mutableBytes], originalWidth, originalHeight, 8, 4*originalWidth, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(cgContext, CGRectMake(0, 0, originalWidth, originalHeight), image);
    CGContextRelease(cgContext);
    CGImageRelease(image);
    
    unsigned char *pImageData = (unsigned char *)[imageData bytes];
    memcpy(pOutBuf, pImageData, originalWidth*4*originalHeight);
    
    return 0;
}

static cv::Mat matFromPixelBuffer(CVPixelBufferRef buffer)
{
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress( buffer );
    size_t width = CVPixelBufferGetWidth( buffer );
    size_t height = CVPixelBufferGetHeight( buffer );
    size_t stride = CVPixelBufferGetBytesPerRow( buffer );
    OSType type =  CVPixelBufferGetPixelFormatType(buffer);
    size_t extendedWidth = stride / 4;  // each pixel is 4 bytes/32 bits
    cv::Mat bgraImage = cv::Mat( (int)height, (int)extendedWidth, CV_8UC4, base );
    
    CVPixelBufferUnlockBaseAddress(buffer,0);
    
    return bgraImage;
}

static void progressFunc (float progress, void *pData)
{
    AISrFourXClass *pAISr4 = (AISrFourXClass *)pData;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [pAISr4 setProgress:progress];
             });
}

@implementation AISrFourXClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	//[NSBundle loadNibNamed:@"AISR4xInfo" owner:self];
	newdata = NULL;
    
    m_rvmProcess = nil;//[[libAISR4x alloc] init];
    //[m_rvmProcess loadModel];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"AI-4x Resize" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"AI" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void) initFisrt
{
    if(m_rvmProcess == nil)
    {
        [NSBundle loadNibNamed:@"AISR4xInfo" owner:self];
        newdata = NULL;
        
        m_rvmProcess = [[libAISR4x alloc] init];
        [m_rvmProcess loadModel];
    }
}

- (void)run
{
	PluginData *pluginData;
	
    [self initFisrt];
    
	refresh = YES;
		
	success = NO;
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
    m_outDataX4 = (unsigned char *)malloc(make_128(16 * [pluginData width] * [pluginData height] * 4));
	//}
	//[self preview:self];
    m_progress.doubleValue = 0.0;
    
    //char cInfo[2048];
    
    m_textInfo.stringValue = [gOurBundle localizedStringForKey:@"info" value:@"Use the latest AI Super Resolution technology to magnify the image of this layer by four times" table:NULL];
	[NSApp runModalForWindow:panel];
}

- (void)setProgress:(float)progress
{
    m_progress.doubleValue = progress*100.0;
}

- (void)applyDone
{
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
    [pluginData applyWithNewDocumentData:m_outDataX4  spp:4 width:[pluginData width]*4 height:[pluginData height]*4];
    
    [panel setAlphaValue:1.0];
    m_btApply.enabled = YES;
    m_btCancel.enabled = YES;
    [NSApp stopModal];
    if ([pluginData window]) [NSApp endSheet:panel];
    [panel orderOut:self];
    success = YES;
    if (newdata) { free(newdata); newdata = NULL; }
    if (m_outDataX4) { free(m_outDataX4); m_outDataX4 = NULL; }
}
- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
    m_btApply.enabled = NO;
    m_btCancel.enabled = NO;
    
	if (refresh) [self execute];
	//[pluginData apply];
    
  
    
	//[gUserDefaults setInteger:radius forKey:@"OCBilaterClass.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
    m_outDataX4 = (unsigned char *)malloc(make_128(16 * [pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
    if (m_outDataX4) { free(m_outDataX4); m_outDataX4 = NULL; }
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
    return;
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)batchProcess:(id)sender
{
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://apps.apple.com/us/app/super-ai-photo-enlarger/id1661918632?mt=12"]];
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
    if (m_outDataX4) { free(m_outDataX4); m_outDataX4 = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	refresh = YES;
	//[self preview:self];
}

- (void)execute
{
	PluginData *pluginData;

	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	if ([pluginData spp] == 2)
    {
		[self executeGrey:pluginData];
	}
	else
    {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, spp, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int max;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
    
	data    = [pluginData data];
	//overlay = [pluginData overlay];
	//replace = [pluginData replace];
	
	// Convert from GA to RGBA
	for (i = 0; i < width * height; i++)
    {
		newdata[i * 4]     = data[i * 2 ];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2 +1];
	}
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
    max = width * height;
    
	for (i = 0; i < max; i++)
    {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	/*
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		for (i = 0; i < selection.size.height; i++)
        {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[(width * (selection.origin.y + i) + selection.origin.x) * 2]), selection.size.width * 2);
		}
	}
	else
    {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}*/
    
    free(resdata);
}

- (void)executeColor:(PluginData *)pluginData
{
    
	IntRect selection;
	int i, width, height;
	unsigned char *data, *resdata, *overlay, *replace;

	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];

	data            = [pluginData data];
	//overlay     = [pluginData overlay];
	//replace     = [pluginData replace];
    
    for (i = 0; i < width * height; i++)
    {
        newdata[i * 4]     = data[i * 4 +2];
        newdata[i * 4 + 1] = data[i * 4 +1];
        newdata[i * 4 + 2] = data[i * 4];
        newdata[i * 4 + 3] = data[i * 4 +3];
    }
    //memcpy(newdata, data, width * height*4);

	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
    @try {
        resdata = [self executeChannel:pluginData withBitmap:newdata];
    }
    @catch (NSException *exception) {

        NSLog([exception reason]);
        return;
    }
    
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		//unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		//unpremultiplyBitmap(4, resdata, resdata, width * height);
	}

	/*// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		for (i = 0; i < selection.size.height; i++)
        {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]),          &(resdata[(width * (selection.origin.y + i) + selection.origin.x) * 4]),            selection.size.width * 4);
		}
	}
	else
    {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
    */
    free(resdata);
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    int nInputWidth = [pluginData width];
    int nInputHeight = [pluginData height];
    float fProgress;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [m_rvmProcess predictImage:data width:nInputWidth height:nInputHeight outImage:m_outDataX4 outProgress:progressFunc callbackData:self];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyDone];
                 });
    });
    return nil;
  
}


- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
