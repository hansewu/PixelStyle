//#include <opencv2/opencv.hpp>
#include "./sam-cpp-macos/interface.h"
#import "AISegClass.h"


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
/*
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
}*/

@implementation AISegClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
//	[NSBundle loadNibNamed:@"MattingInfo" owner:self];
	newdata = NULL;
    m_bLoaded = 0;
    
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"AI Segmentation" table:NULL];
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
    if(m_bLoaded == 0)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        //NSString *path = [bundle resourcePath];
        //[[NSBundle mainBundle] loadNibNamed:@"SegInfo" owner:self options:nil];
        [NSBundle  loadNibNamed:@"SegInfo" owner:self];
        newdata = NULL;
        NSString *sam_preprocessPath = [bundle pathForResource:@"mobile_sam_preprocess" ofType:@"onnx"];
        NSString *sam_processPath = [bundle pathForResource:@"mobile_sam" ofType:@"onnx"];
        printf("%s, %s\n", [sam_preprocessPath UTF8String],  [sam_processPath UTF8String]);
        if(sam_preprocessPath != nil && sam_processPath != nil)
        {
            int nRet = SAMSEG_LoadModel((char *)[sam_preprocessPath UTF8String], (char *)[sam_processPath UTF8String]);
            if(nRet == 0)
                m_bLoaded = 1;
        }
        else assert(false);
    }
}
- (void)exitEngine
{
    SAMSEG_Exit();
    m_bLoaded = 0;
}
- (void)run
{
	PluginData *pluginData;
	
    [self initFisrt];
    
	if ([gUserDefaults objectForKey:@"AISeg.radius"])
		radius = [gUserDefaults integerForKey:@"AISeg.radius"];
	else
		radius = 10;
	refresh = YES;
	
	if (radius < 1 || radius > 100)
		radius = 10;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	
	[radiusSlider setIntValue:radius];
	
	success = NO;
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self preview:self];
	[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
    
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) { free(newdata); newdata = NULL; }
		
	[gUserDefaults setInteger:radius forKey:@"OCBilaterClass.radius"];
    [self exitEngine];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
    [self initFisrt];
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
    [self exitEngine];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData) return;
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
    
    [self exitEngine];
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	radius = roundf([radiusSlider floatValue]);
		
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	refresh = YES;
	[self preview:self];
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
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
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
	
	// Convert output to GA
//	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
//		max = selection.size.width * selection.size.height;
//	else
    max = width * height;
    
	for (i = 0; i < max; i++)
    {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	
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
	}
    
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
	overlay     = [pluginData overlay];
	replace     = [pluginData replace];
    memcpy(newdata, data, width * height*4);

	
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

	// Copy to destination
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
    
    free(resdata);
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    unsigned char  *resdata = [self aiSegment:pluginData withBitmap:data];
    return resdata;
  
}

- (unsigned char *)aiSegment:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    int nInputWidth = [pluginData width];
    int nInputHeight = [pluginData height];
    
    unsigned char *pAlpha = (unsigned char *)malloc(nInputWidth*nInputHeight);
    IntRect selection = [pluginData selection];
    
    int nRet = SAMSEG_GetMaskForRect(pAlpha, data, nInputWidth, nInputHeight, (float)selection.origin.x, (float)selection.origin.y, (float)selection.size.width, (float)selection.size.height);
 
    unsigned char *res_data = (unsigned char *)malloc(nInputWidth * nInputHeight *4);
    
    for(int y=0; y< nInputHeight; y++)
    {
        for(int x=0; x< nInputWidth; x++)
        {
            int pos = (y*nInputWidth+x) * 4;
            
           // if(pAlpha[pos/4] > 200)
            {
                res_data[pos]   = data[pos];
                res_data[pos+1] = data[pos+1];
                res_data[pos+2] = data[pos+2];
                res_data[pos+3] = 255- pAlpha[pos/4];
            }
           /* else
            {
                res_data[pos]   = pImage[pos];
                res_data[pos+1] = pImage[pos+1];
                res_data[pos+2] = pImage[pos+2];
                res_data[pos+3] = pAlpha[pos];
            }*/
        }
    }
       
    free(pAlpha);

    
    return res_data;
 
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
