#import "CISunbeamsClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

@implementation CISunbeamsClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CISunbeams" owner:self];
	newdata = NULL;
	mainNSColor = NULL;
	running = NO;
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sunbeams" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
    pluginData = [(PSPlugins *)seaPlugins data];
	
	if ([gUserDefaults objectForKey:@"CISunbeams.strength"])
		strength = [gUserDefaults floatForKey:@"CISunbeams.strength"];
	else
		strength = 0.5;
	if ([gUserDefaults objectForKey:@"CISunbeams.contrast"])
		contrast = [gUserDefaults floatForKey:@"CISunbeams.contrast"];
	else
		contrast = 1.0;
	
	if (strength < 0.0 || strength > 3.0)
		strength = 0.5;
	if (contrast < 0.0 || contrast > 5.0)
		contrast = 1.0;
	
	[strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
	[strengthSlider setFloatValue:strength];
	[contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
	[contrastSlider setFloatValue:contrast];
	
	if (mainNSColor) [mainNSColor autorelease];
	mainNSColor = [[mainColorWell color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[mainNSColor retain];
    
    int width = [pluginData width];
    int height = [pluginData height];
    [m_positionXSlider setMinValue:0.0];
    [m_positionXSlider setMaxValue:width];
    [m_positionXSlider setFloatValue:width / 2.0];
    [m_positionYSlider setMinValue:0.0];
    [m_positionYSlider setMaxValue:height];
    [m_positionYSlider setFloatValue:height / 2.0];
    [m_radiusSlider setMinValue:0];
    float maxValue = sqrtf((float)width * width + (float)height * height) * 0.3;
    [m_radiusSlider setMaxValue:maxValue];
    [m_radiusSlider setFloatValue:maxValue * 0.1];
    
    [m_widthSlider setMinValue:0];
    [m_widthSlider setMaxValue:maxValue];
    [m_widthSlider setFloatValue:maxValue * 0.3];
	
    [m_positionXLabel setIntValue:[m_positionXSlider floatValue]];
    [m_positionYLabel setIntValue:[m_positionYSlider floatValue]];
    [m_radiusLabel setStringValue:[NSString stringWithFormat:@"%.2f",[m_radiusSlider floatValue]]];
    [m_widthLabel setStringValue:[NSString stringWithFormat:@"%.2f",[m_widthSlider floatValue]]];
    
	refresh = YES;
	success = NO;
	running = YES;
	
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
    
    [gColorPanel close];
    [gColorPanel setShowsAlpha:YES];
        
	[self preview:self];
	[NSApp runModalForWindow:panel];
    
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	running = NO;
	if (newdata) { free(newdata); newdata = NULL; }
	
	[gUserDefaults setFloat:strength forKey:@"CISunbeams.strength"];
	[gUserDefaults setFloat:contrast forKey:@"CISunbeams.contrast"];
	
	[gColorPanel orderOut:self];

}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
}

- (BOOL)canReapply
{
	return NO;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
	running = NO;
	[gColorPanel orderOut:self];
}

- (void)setColor:(NSColor *)color
{
	PluginData *pluginData;
	
	if (mainNSColor) [mainNSColor autorelease];
	mainNSColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[mainNSColor retain];
	if (running) {
		refresh = YES;
		[self preview:self];
		
    }
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	strength = [strengthSlider floatValue];
	contrast = [contrastSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[strengthLabel setStringValue:[NSString stringWithFormat:@"%.1f", strength]];
	[contrastLabel setStringValue:[NSString stringWithFormat:@"%.1f", contrast]];
    
    [m_positionXLabel setIntValue:[m_positionXSlider floatValue]];
    [m_positionYLabel setIntValue:[m_positionYSlider floatValue]];
    [m_radiusLabel setStringValue:[NSString stringWithFormat:@"%.2f",[m_radiusSlider floatValue]]];
    [m_widthLabel setStringValue:[NSString stringWithFormat:@"%.2f",[m_widthSlider floatValue]]];
	
	refresh = YES;
	[self preview:self];
}

- (void)execute
{
    PluginData *pluginData;

    pluginData = [(PSPlugins *)seaPlugins data];
    
    IntRect selection;
    int i, width, height;
    unsigned char *data, *resdata, *overlay, *replace;
    int vec_len;
    
    // Set-up plug-in
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    selection = [pluginData selection];
    
    int spp = [pluginData spp];
    
    // Get plug-in data
    width = [pluginData width];
    height = [pluginData height];

    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    
    int channelMode = [pluginData channel];
    
    preProcessToARGB(data, spp, width, height, newdata, channelMode);
    // Run CoreImage effect
    resdata = [self halftone:pluginData withBitmap:newdata];
    
    postProcessToRGBA(data, selection, width, height, resdata, spp, selection.size.width, selection.size.height, newdata, channelMode);
    
    // Copy to destination
    
    if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
    {
        for (i = 0; i < selection.size.height; i++)
        {
            memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
            memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * spp]), &(newdata[selection.size.width * spp * i]), selection.size.width * spp);
        }
    }
    else
    {
        memset(replace, 0xFF, width * height);
        memcpy(overlay, newdata, width * height * spp);
    }
    
}
/*
- (void)execute
{
	PluginData *pluginData;

	pluginData = [(PSPlugins *)seaPlugins data];
	if ([pluginData spp] == 2) {
		[self executeGrey:pluginData];
	}
	else {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int i, spp, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int vec_len, max;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	vec_len = width * height * spp;
	if (vec_len % 16 == 0) { vec_len /= 16; }
	else { vec_len /= 16; vec_len++; }
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	// Convert from GA to ARGB
	for (i = 0; i < width * height; i++) {
		newdata[i * 4] = data[i * 2 + 1];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2];
	}
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
	// Convert from output to GA
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
		max = selection.size.width * selection.size.height;
	else
		max = width * height;
	for (i = 0; i < max; i++) {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[selection.size.width * 2 * i]), selection.size.width * 2);
		}
	}
	else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
}

- (void)executeColor:(PluginData *)pluginData
{
#ifdef __ppc__
	vector unsigned char TOGGLERGBF = (vector unsigned char)(0x03, 0x00, 0x01, 0x02, 0x07, 0x04, 0x05, 0x06, 0x0B, 0x08, 0x09, 0x0A, 0x0F, 0x0C, 0x0D, 0x0E);
	vector unsigned char TOGGLERGBR = (vector unsigned char)(0x01, 0x02, 0x03, 0x00, 0x05, 0x06, 0x07, 0x04, 0x09, 0x0A, 0x0B, 0x08, 0x0D, 0x0E, 0x0F, 0x0C);
	vector unsigned char *vdata, *voverlay, *vresdata;
#else
	__m128i opaquea = _mm_set1_epi32(0x000000FF);
	__m128i *vdata, *voverlay, *vresdata;
	__m128i vstore;
#endif
	IntRect selection;
	int i, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	int vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) { vec_len /= 16; }
	else { vec_len /= 16; vec_len++; }
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	premultiplyBitmap(4, newdata, data, width * height);
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
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
@try {
	resdata = [self executeChannel:pluginData withBitmap:newdata];
}
@catch (NSException *exception) {
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
	NSLog([exception reason]);
	return;
}
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	}else {
		unpremultiplyBitmap(4, resdata, resdata, width * height);
	}
	// Convert from ARGB to RGBA
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
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		}
	}
	else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	int i, vec_len, width, height, channel;
	unsigned char ormask[16], *resdata, *datatouse;
	#ifdef __ppc__
	vector unsigned char TOALPHA = (vector unsigned char)(0x10, 0x00, 0x00, 0x00, 0x10, 0x04, 0x04, 0x04, 0x10, 0x08, 0x08, 0x08, 0x10, 0x0C, 0x0C, 0x0C);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *rvdata, orvmask;
	#else
	__m128i *vdata, *rvdata, orvmask;
	#endif
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	if (channel == kPrimaryChannels || channel == kAlphaChannel) {
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
		if (channel == kPrimaryChannels) {
			for (i = 0; i < 16; i++) {
				ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
			}
			memcpy(&orvmask, ormask, 16);
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_or(vdata[i], orvmask);
			}
			#else
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = _mm_or_si128(vdata[i], orvmask);
			}
			#endif
		}
		else if (channel == kAlphaChannel) {
			#ifdef __ppc__
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_perm(vdata[i], HIGHVEC, TOALPHA);
			}
			#else
			for (i = 0; i < width * height; i++) {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			}
			#endif
		}
	}
	
	// Run CoreImage effect
	resdata = [self halftone:pluginData withBitmap:datatouse];
	
	return resdata;
}
*/
- (unsigned char *)halftone:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *halo, *output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	CIColor *mainColor;
	IntPoint point1, point2, point3;
	float halo_width, halo_radius;
	
	// Get relevant color
	mainColor = [CIColor colorWithRed:[mainNSColor redComponent] green:[mainNSColor greenComponent] blue:[mainNSColor blueComponent] alpha:[mainNSColor alphaComponent]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
//    point1 = [pluginData point:0];
//	point2 = [pluginData point:1];
//	point3 = [pluginData point:2];
//	halo_radius = abs(point2.x - point1.x) * abs(point2.x - point1.x) + abs(point2.y - point1.y) * abs(point2.y - point1.y);
//	halo_radius = sqrt(halo_radius);
//	halo_width = abs(point3.x - point1.x) * abs(point3.x - point1.x) + abs(point3.y - point1.y) * abs(point3.y - point1.y);
//	halo_width = sqrt(halo_width);
//	halo_width = abs(halo_width - halo_radius);
    
    point1.x = [m_positionXSlider floatValue];
    point1.y = [m_positionYSlider floatValue];
    halo_radius = [m_radiusSlider floatValue];
    halo_width = [m_widthSlider floatValue];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData dataColorSpace]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CISunbeamsGenerator"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISunbeamsGenerator"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
	[filter setValue:mainColor forKey:@"inputColor"];
	[filter setValue:[NSNumber numberWithFloat:halo_radius] forKey:@"inputSunRadius"];
	[filter setValue:[NSNumber numberWithFloat:halo_width] forKey:@"inputMaxStriationRadius"];
	[filter setValue:[NSNumber numberWithFloat:strength] forKey:@"inputStriationStrength"];
	[filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputStriationContrast"];
	[filter setValue:[NSNumber numberWithInt:0] forKey:@"inputTime"];
	halo = [filter valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
	[filter setDefaults];
	[filter setValue:halo forKey:@"inputImage"];
	[filter setValue:input forKey:@"inputBackgroundImage"];
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
		
	return resdata;
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
