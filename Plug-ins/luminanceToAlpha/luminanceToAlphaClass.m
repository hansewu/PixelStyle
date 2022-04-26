#import "luminanceToAlphaClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define make_128(x) (x + 16 - (x % 16))

@implementation luminanceToAlphaClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	newdata = NULL;
	
	return self;
}

- (int)type
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Luminance to Alpha Channel" table:NULL];
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

	pluginData = [(PSPlugins *)seaPlugins data];
    
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return success;
}

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
    [self executeColor:pluginData];
}

- (void)executeColor:(PluginData *)pluginData
{

	int  width, height;
	unsigned char *data, *overlay, *replace;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
    //IntRect selectionRect = [pluginData selection];
    	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
    
    data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
    int spp = [pluginData spp];
    
    memcpy(overlay, data, width*height*spp);
    for(int y=0; y< height; y++)
    {
            for(int x=0; x< width; x++)
            {
                if(spp==2)
                    overlay[y*width*spp +x*spp + spp -1] = overlay[y*width*spp +x*spp];
                else if(spp ==4 )
                    overlay[y*width*spp +x*spp + spp -1] = ((int)overlay[y*width*spp +x*spp] * 30
                                                            + (int)overlay[y*width*spp +x*spp + 1] * 60
                                                            + (int)overlay[y*width*spp +x*spp + 2] * 10)/100;
            }
        
    }
    
    memset(replace, 0xFF, width * height);

	return;
}



- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	int i, j, vec_len, width, height, channel;
	unsigned char ormask[16], *resdata, *datatouse;
	IntRect selection;

	#ifdef __ppc__
	vector unsigned char TOALPHA = (vector unsigned char)(0x10, 0x00, 0x00, 0x00, 0x10, 0x04, 0x04, 0x04, 0x10, 0x08, 0x08, 0x08, 0x10, 0x0C, 0x0C, 0x0C);
	vector unsigned char REVERTALPHA = (vector unsigned char)(0x00, 0x01, 0x02, 0x10, 0x04, 0x05, 0x06, 0x14, 0x08, 0x09, 0x0A, 0x18, 0x0C, 0x0D, 0x0E, 0x1C);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *nvdata, *rvdata, orvmask;
	#else
	__m128i *vdata, *nvdata, orvmask;
	#endif
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) { vec_len /= 16; }
	else { vec_len /= 16; vec_len++; }
	#ifdef __ppc__
	vdata = (vector unsigned char *)data; // NB: data may equal newdata
	nvdata = (vector unsigned char *)newdata;
	#else
	vdata = (__m128i *)data;
	nvdata = (__m128i *)newdata;
	#endif
	datatouse = newdata;
	if (channel == kAlphaChannel) {
		#ifdef __ppc__
		for (i = 0; i < vec_len; i++) {
			nvdata[i] = vec_perm(vdata[i], HIGHVEC, TOALPHA);
		}
		#else
		for (i = 0; i < width * height; i++) {
			newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
			newdata[i * 4] = 255;
		}
		#endif
	}
	else {
		for (i = 0; i < 16; i++) {
			ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
		}
		memcpy(&orvmask, ormask, 16);
		#ifdef __ppc__
		for (i = 0; i < vec_len; i++) {
			nvdata[i] = vec_or(vdata[i], orvmask);
		}
		#else
		for (i = 0; i < vec_len; i++) {
			nvdata[i] = _mm_or_si128(vdata[i], orvmask);
		}
		#endif
	}
	
	// Run CoreImage effect
	resdata = [self invert:pluginData withBitmap:datatouse];
	
	// Restore alpha
	if (channel == kAllChannels) {
		#ifdef __ppc__
		rvdata = (vector unsigned char *)resdata;
		for (i = 0; i < vec_len; i++) {
			rvdata[i] = vec_perm(rvdata[i], vdata[i], REVERTALPHA);
		}
		#else
		for (i = 0; i < selection.size.height; i++) {
			for(j = 0; j < selection.size.width; j++){
				resdata[(i * selection.size.width + j) * 4 + 3] =
				data[(width * (i + selection.origin.y) +
					  j + selection.origin.x) * 4];
			}
		}
		#endif
	}
	
	return resdata;
}

- (unsigned char *)invert:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *output;
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
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIColorInvert"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIColorInvert"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
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
	return YES;
}

@end
