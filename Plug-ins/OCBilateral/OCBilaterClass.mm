#include <opencv2/opencv.hpp>
#import "OCBilaterClass.h"


#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

@implementation OCBilaterClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"OCBilateral" owner:self];
	newdata = NULL;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Bilateral" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"AI" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"OCBilaterClass.radius"])
		radius = [gUserDefaults integerForKey:@"OCBilaterClass.radius"];
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
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
    if(!pluginData)  return;
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = (unsigned char *)malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
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
	//vec_len = width * height * spp;
    
	//if (vec_len % 16 == 0) { vec_len /= 16; }
	//else { vec_len /= 16; vec_len++; }
    
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
    /*
#ifdef __ppc__
	vector unsigned char TOGGLERGBF = (vector unsigned char)(0x03, 0x00, 0x01, 0x02, 0x07, 0x04, 0x05, 0x06, 0x0B, 0x08, 0x09, 0x0A, 0x0F, 0x0C, 0x0D, 0x0E);
	vector unsigned char TOGGLERGBR = (vector unsigned char)(0x01, 0x02, 0x03, 0x00, 0x05, 0x06, 0x07, 0x04, 0x09, 0x0A, 0x0B, 0x08, 0x0D, 0x0E, 0x0F, 0x0C);
	vector unsigned char OPAQUEA = (vector unsigned char)(0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF);
	vector unsigned char *vdata, *voverlay, *vresdata;
#else
	__m128i opaquea = _mm_set1_epi32(0x000000FF);
	__m128i *vdata, *voverlay, *vresdata;
	__m128i vstore;
#endif
     */
	IntRect selection;
	int i, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	//int vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	//vec_len = width * height * 4;
    
	//if (vec_len % 16 == 0) { vec_len /= 16; }
	//else { vec_len /= 16; vec_len++; }
    
	data            = [pluginData data];
	overlay     = [pluginData overlay];
	replace     = [pluginData replace];
    memcpy(newdata, data, width * height*4);
    /*
	//premultiplyBitmap(4, newdata, data, width * height);
	// Convert from RGBA to ARGB
#ifdef __ppc__
	vdata = (vector unsigned char *)newdata;
	for (i = 0; i < vec_len; i++) {
		vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBF);
	}
#else
	vdata = (__m128i *)newdata;
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
#endif
     */
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
    @try {
        resdata = [self executeChannel:pluginData withBitmap:newdata];
    }
    @catch (NSException *exception) {
        /*#ifdef __ppc__
            for (i = 0; i < vec_len; i++) {
                vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBR);
         }
         #else
            for (i = 0; i < vec_len; i++) {
            vstore = _mm_slli_epi32(vdata[i], 24);
            vdata[i] = _mm_srli_epi32(vdata[i], 8);
            vdata[i] = _mm_add_epi32(vdata[i], vstore);
         }
         #endif */
        NSLog([exception reason]);
        return;
    }
    
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
		//unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		//unpremultiplyBitmap(4, resdata, resdata, width * height);
	}

	// Convert from ARGB to RGBA
    /*
#ifdef __ppc__
	for (i = 0; i < vec_len; i++) {
		vdata[i] = vec_perm(vdata[i], vdata[i], TOGGLERGBR);
	}
#else
	for (i = 0; i < vec_len; i++) {
		vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	}
#endif
     */
	
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
    unsigned char  *resdata = [self blur:pluginData withBitmap:data];
    return resdata;
  /*
	int i, vec_len, width, height, channel;
	unsigned char ormask[16], *datatouse;
	#ifdef __ppc__
	vector unsigned char TOALPHA = (vector unsigned char)(0x10, 0x00, 0x00, 0x00, 0x10, 0x04, 0x04, 0x04, 0x10, 0x08, 0x08, 0x08, 0x10, 0x0C, 0x0C, 0x0C);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *rvdata, orvmask;
	#else
	__m128i *vdata, *rvdata, orvmask;
	#endif
	
//    int g_d = 15;
//    int g_sigmaColor = 20;
//    int g_sigmaSpace = 50;
    //cv::bilateralFilter(image1, image2, g_d, g_sigmaColor, g_sigmaSpace);
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	if (channel == kPrimaryChannels || channel == kAlphaChannel)
    {
		width = [pluginData width];
		height = [pluginData height];
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		#ifdef __ppc__
		vdata = (vector unsigned char *)data; // NB: data may equal newdata
		rvdata = (vector unsigned char *)newdata;
		#else
		vdata = (__m128i *)data;
		rvdata = (__m128i *)newdata;
		#endif
		datatouse = newdata;
		if (channel == kPrimaryChannels)
        {
			for (i = 0; i < 16; i++)
            {
				ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
			}
			memcpy(&orvmask, ormask, 16);
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++)
            {
				rvdata[i] = vec_or(vdata[i], orvmask);
			}
			#else
			for (i = 0; i < vec_len; i++)
            {
				rvdata[i] = _mm_or_si128(vdata[i], orvmask);
			}
			#endif
		}
		else if (channel == kAlphaChannel)
        {
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++)
            {
				rvdata[i] = vec_perm(vdata[i], HIGHVEC, TOALPHA);
			}
			#else
			for (i = 0; i < width * height; i++)
            {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			}
			#endif
		}
	}
	
	// Run CoreImage effect
	resdata = [self blur:pluginData withBitmap:datatouse];
	
	return resdata;
   */
}



- (unsigned char *)blur:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
    int nInputWidth = [pluginData width];
    int nInputHeight = [pluginData height];
    
    cv::Mat_<cv::Vec4b> image = cv::Mat(nInputHeight, nInputWidth, CV_8UC4, data);
    int g_d = 15;
    double g_sigmaColor = radius;//20;
    double  g_sigmaSpace = radius;
    
    std::vector<cv::Mat> old_rgb4Channels(4);
    cv::split(image, old_rgb4Channels);
    
    cv::Mat image1;
    std::vector<cv::Mat> old_rgb4Channels1(3);
    old_rgb4Channels1[0] = old_rgb4Channels[0];
    old_rgb4Channels1[1] = old_rgb4Channels[1];
    old_rgb4Channels1[2] = old_rgb4Channels[2];
    cv::merge(old_rgb4Channels1, image1);
    
    //cv::cvtColor(image, image1, cv::COLOR_RGBA2RGB);
    
    cv::Mat image2;
    cv::bilateralFilter(image1, image2, g_d, g_sigmaColor, g_sigmaSpace);
    
    std::vector<cv::Mat> new_rgb3Channels(3);
    cv::split(image2, new_rgb3Channels);
    
    std::vector<cv::Mat> cb_rgb4Channels;
    cb_rgb4Channels.push_back(new_rgb3Channels[0]);    //b
    cb_rgb4Channels.push_back(new_rgb3Channels[1]);    //g
    cb_rgb4Channels.push_back(new_rgb3Channels[2]);    //r
    cb_rgb4Channels.push_back(old_rgb4Channels[3]);
    
    unsigned char *res_data = (unsigned char *)malloc(nInputWidth * nInputHeight *4);
    cv::Mat_<cv::Vec4b> image3 = cv::Mat(nInputHeight, nInputWidth, CV_8UC4, res_data);
    cv::merge(cb_rgb4Channels, image3);
    
    if(image3.data != res_data)
        memcpy(res_data, image3.data, nInputWidth * nInputHeight *4);
    
    return res_data;
    /*
	CIContext *context;
	CIImage *unclampedInput, *clampedInput, *crop_output, *output, *background;
	CIFilter *clamp, *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int i, vec_len, width, height;
	unsigned char *resdata;
	BOOL opaque, done;
	IntRect selection;
	unsigned char ormask[16];
	#ifdef __ppc__
	vector unsigned char *vresdata, orvmask;
	#else
	__m128i *vresdata, orvmask;
	#endif

	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha] || ([pluginData channel] != kAllChannels);
	if (opaque == NO)
    {
		done = NO;
		for (i = 0; i < width * height && !done; i++)
        {
			if (data[i * 4] != 0xFF)
				done = YES;
		}
		if (done == NO) opaque = YES;
	}
	
	// Create core image with data
	size.width = width;
	size.height = height;
	unclampedInput = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
	// the content outside the borders of the image
	clamp = [CIFilter filterWithName: @"CIAffineClamp"];
	[clamp setDefaults];
	[clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	[clamp setValue:unclampedInput forKey: @"inputImage"];
	clampedInput = [clamp valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIGaussianBlur"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGaussianBlur"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:clampedInput forKey:@"inputImage"];
	[filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
	output = [filter valueForKey: @"outputImage"];
	
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:@"outputImage"];
		
		// Create output core image
		rect.origin.x = selection.origin.x;
		rect.origin.y = height - selection.size.height - selection.origin.y;
		rect.size.width = selection.size.width;
		rect.size.height = selection.size.height;
		temp_image = [context createCGImage:output fromRect:rect];		
		
	}
	else {
	
		// Create output core image
		rect.origin.x = 0;
		rect.origin.y = 0;
		rect.size.width = width;
		rect.size.height = height;
		temp_image = [context createCGImage:output fromRect:rect];
		
	}
	
	// Get data from output core image
	temp_handler = [NSMutableData dataWithLength:0];
	temp_writer = CGImageDestinationCreateWithData((CFMutableDataRef)temp_handler, kUTTypeTIFF, 1, NULL);
	CGImageDestinationAddImage(temp_writer, temp_image, NULL);
	CGImageDestinationFinalize(temp_writer);
	temp_rep = [NSBitmapImageRep imageRepWithData:temp_handler];
	resdata = [temp_rep bitmapData];
	
	// Handle opaque images
	if (opaque)
    {
		vec_len = [temp_rep pixelsWide] * [temp_rep pixelsHigh] * [temp_rep samplesPerPixel];
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		for (i = 0; i < 16; i++)
        {
			ormask[i] = (i % 4 == 3) ? 0xFF : 0x00;
		}
		memcpy(&orvmask, ormask, 16);
		#ifdef __ppc__
		vresdata = (vector unsigned char *)resdata;
		for (i = 0; i < vec_len; i++) {
			vresdata[i] = vec_or(vresdata[i], orvmask);
		}
		#else
		vresdata = (__m128i *)resdata;
		for (i = 0; i < vec_len; i++)
        {
			vresdata[i] = _mm_or_si128(vresdata[i], orvmask);
		}
		#endif
	}
	
	return resdata;
     */
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
