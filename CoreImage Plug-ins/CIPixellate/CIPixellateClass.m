#import "CIPixellateClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

@implementation CIPixellateClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIPixellate" owner:self];
	newdata = NULL;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Pixellate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)sanity
{
	return @"PixelStyle Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"CIPixellate.scale"])
		scale = [gUserDefaults floatForKey:@"CIPixellate.scale"];
	else
		scale = 8;
	
	if ([gUserDefaults objectForKey:@"CIPixellate.centerBased"])
		centerBased = [gUserDefaults boolForKey:@"CIPixellate.centerBased"];
	else
		centerBased = YES;
	
	if (scale < 1 || scale > 100)
		scale = 8;
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
	[scaleSlider setIntValue:scale];

	[typeRadios setState:scale atRow:0 column:(centerBased) ? 1 : 0];
	
	refresh = YES;
	success = NO;
	pluginData = [(PSPlugins *)seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
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
	if (newdata) { free(newdata); newdata = NULL; }
		
	[gUserDefaults setInteger:scale forKey:@"CIPixellate.scale"];
	[gUserDefaults setObject:(centerBased) ? @"YES" : @"NO" forKey:@"CIPixellate.scale"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
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
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	scale = [scaleSlider intValue];
	centerBased = ([typeRadios selectedColumn] == 1);
	[panel setAlphaValue:1.0];
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
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
    resdata = [self pixellate:pluginData withBitmap:newdata];
    
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
	[self finishing];
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
	resdata = [self pixellate:pluginData withBitmap:datatouse];
	
	return resdata;
}
*/
- (unsigned char *)pixellate:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *output, *imm_output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	BOOL opaque;
	CIColor *backColor;
	IntRect selection;
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha];
	if (opaque && [pluginData spp] == 4) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] redComponent] green:[[pluginData backColor:YES] greenComponent] blue:[[pluginData backColor:YES] blueComponent]];
	else if (opaque) backColor = [CIColor colorWithRed:[[pluginData backColor:YES] whiteComponent] green:[[pluginData backColor:YES] whiteComponent] blue:[[pluginData backColor:YES] whiteComponent]];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData dataColorSpace]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIPixellate"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPixellate"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:[NSNumber numberWithInt:scale] forKey:@"inputScale"];
	if (centerBased)
		[filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
	else
		[filter setValue:[CIVector vectorWithX:scale Y:height - scale] forKey:@"inputCenter"];
	imm_output = [filter valueForKey: @"outputImage"];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	}
	else {
		output = imm_output;
	}
	
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

- (void)finishing
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace, newPixel[4];
	int pos, i, j, k, i2, j2, width, height, spp, channel;
	int total[4], n, x_stblk, x_endblk, y_stblk, y_endblk;
	int loop;
	
	if (centerBased) return;
	
	pluginData = [(PSPlugins *)seaPlugins data];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	height = [pluginData height];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (loop = 0; loop < 2; loop++) {
	
		if (loop == 0) {
		
			if ((selection.origin.x + selection.size.width) % scale != 0) {
				x_stblk = (selection.origin.x + selection.size.width) / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + 1;
				y_stblk = selection.origin.y / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + ((selection.origin.y + selection.size.height) % scale != 0);
			}
			else {
				continue;
			}
		
		}
		else {
		
			if ((selection.origin.y + selection.size.height) % scale != 0) {
				x_stblk = selection.origin.x / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + ((selection.origin.x + selection.size.width) % scale != 0);
				y_stblk = (selection.origin.y + selection.size.height) / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + 1;
			}
			else {
				continue;
			}
			
		}
		
		for (j = y_stblk; j < y_endblk; j++) {
			for (i = x_stblk; i < x_endblk; i++) {
			
				// Sum and count the present pixels in the  block
				total[0] = total[1] = total[2] = total[3] = 0;
				n = 0;
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								total[k] += data[pos * spp + k];
							}
							n++;
						}
					}
				}
				
				// Determine the revised pixel
				switch (channel) {
					case kAllChannels:
						for (k = 0; k < spp; k++) {
							newPixel[k] = total[k] / n;
						}
					break;
					case kPrimaryChannels:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[k] / n;
						}
						newPixel[spp - 1] = 255;
					break;
					case kAlphaChannel:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[spp - 1] / n;
						}
						newPixel[spp - 1] = 255;
					break;
				}
				
				// Fill the block with this pixel
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						pos = (j * scale + j2) * width + (i * scale + i2);
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								overlay[pos * spp + k] = newPixel[k];
							}
							replace[pos] = 255;
						}
					}
				}
				
			}
		}
		
	}
}


- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
