#import "CIAffineTransformClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define make_128(x) (x + 16 - (x % 16))

@implementation CIAffineTransformClass

- (id)initWithManager:(PSPlugins *)manager
{
	seaPlugins = manager;
	newdata = NULL;
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Scale and Rotate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Transform" table:NULL];
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
	[self determineContentBorders:pluginData];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
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
	return NO;
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
*/
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
    //vec_len = width * height * spp;
    //if (vec_len % 16 == 0) { vec_len /= 16; }
    //else { vec_len /= 16; vec_len++; }
    data = [pluginData data];
    overlay = [pluginData overlay];
    replace = [pluginData replace];
    
    int channelMode = [pluginData channel];
    
    preProcessToARGB(data, spp, width, height, newdata, channelMode);
    
    // Run CoreImage effect
    resdata = [self transform:pluginData withBitmap:newdata];
    
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
	resdata = [self transform:pluginData withBitmap:datatouse];
	
	return resdata;
}
*/
- (void)determineContentBorders:(PluginData *)pluginData
{
	int contentLeft, contentRight, contentTop, contentBottom;
	int width, height;
	int spp;
	unsigned char *data;
	int i, j, k;
	id layer;
	IntRect selection;
	
	// Start out with invalid content borders
	contentLeft = contentRight = contentTop = contentBottom =  -1;
	
	// Select the appropriate data for working out the content borders
	data = [pluginData data];
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	spp = [pluginData spp];
	
	// Determine left content margin
	for (i = 0; i < width && contentLeft == -1; i++) {
		for (j = 0; j < height && contentLeft == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentLeft = i;
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && contentRight == -1; i--) {
		for (j = 0; j < height && contentRight == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentRight = i;
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && contentTop == -1; j++) {
		for (i = 0; i < width && contentTop == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentTop = j;
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && contentBottom == -1; j--) {
		for (i = 0; i < width && contentBottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentBottom = j;
			}
		}
	}
	
	// Put into bounds
	if (contentLeft != -1 && contentTop != -1 && contentRight != -1 && contentBottom != -1) {
		bounds.origin.x = contentLeft;
		bounds.origin.y = contentTop;
		bounds.size.width = contentRight - contentLeft + 1;
		bounds.size.height = contentBottom - contentTop + 1;
		boundsValid = YES;
	}
	else {
		boundsValid = NO;
	}
}

#define PI 3.14159265

- (unsigned char *)transform:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *unclampedInput, *clampedInput, *crop_output, *imm_output, *imm_output_1, *imm_output_2, *output, *background;
	CIFilter *clamp, *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	IntRect selection;
	IntPoint point, apoint;
	float scale, angle;
	int baselen;
	BOOL opaque;
	CIColor *backColor;
	NSAffineTransform *offsetTransform, *trueTransform;
	
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
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	baselen = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
	baselen = sqrt(baselen);
	if (boundsValid) scale = (float)baselen / (float)bounds.size.width;
	else scale = (float)baselen / (float)width;
	if (apoint.x - point.x != 0)
		angle = atan((float)(point.y - apoint.y) / (float)(apoint.x - point.x));
	else
		angle = PI / 2 * ((point.y - apoint.y > 0) ? 1 : -1);
	trueTransform = [NSAffineTransform transform];
	[trueTransform translateXBy:point.x yBy:height - point.y];
	[trueTransform scaleBy:scale];
	[trueTransform rotateByRadians:angle];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	unclampedInput = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData dataColorSpace]];
		
	// We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
	// the content outside the borders of the image
	clamp = [CIFilter filterWithName: @"CIAffineClamp"];
	[clamp setDefaults];
	[clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	[clamp setValue:unclampedInput forKey: @"inputImage"];
	clampedInput = [clamp valueForKey: @"outputImage"];
	
	// Position correctly
	if (boundsValid) {
	
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:clampedInput forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:bounds.origin.x Y:height - bounds.size.height - bounds.origin.y Z:bounds.size.width W:bounds.size.height] forKey:@"inputRectangle"];
		imm_output_1 = [filter valueForKey:@"outputImage"];
		
		// Offset properly
		filter = [CIFilter filterWithName:@"CIAffineTransform"];
		[filter setDefaults];
		[filter setValue:imm_output_1 forKey:@"inputImage"];
		offsetTransform = [NSAffineTransform transform];
		[offsetTransform translateXBy:-bounds.origin.x yBy:-height + bounds.origin.y + bounds.size.height];
		[filter setValue:offsetTransform forKey:@"inputTransform"];
		imm_output_2 = [filter valueForKey:@"outputImage"];
		
	
	}
	else {
		imm_output_2 = clampedInput;
	}
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIAffineTransform"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIAffineTransform"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:imm_output_2 forKey:@"inputImage"];
	[filter setValue:trueTransform forKey:@"inputTransform"];
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
/*
- (unsigned char *)prepareAlphaAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height
{
	unsigned char *ndata;
	int i;

	ndata = malloc(make_128(width * height * 4));
	
	for (i = 0; i < width * height; i++) {
		ndata[i * 4] = 0xFF;
		ndata[i * 4 + 1] = data[(i + 1) * spp - 1];
		ndata[i * 4 + 2] = data[(i + 1) * spp - 1];
		ndata[i * 4 + 3] = data[(i + 1) * spp - 1];
	}

	return ndata;
}


- (unsigned char *)prepareAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height
{
	#ifdef __ppc__
	vector unsigned char TOGGLERGBF = (vector unsigned char)(0x13, 0x00, 0x01, 0x02, 0x17, 0x04, 0x05, 0x06, 0x1B, 0x08, 0x09, 0x0A, 0x1F, 0x0C, 0x0D, 0x0E);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *rvdata;
	#else
	__m128i *vdata, *rvdata, vstore, orvmask;
	unsigned char ormask[16];
	#endif
	unsigned char *ndata;
	int i, vec_len;

	ndata = malloc(make_128(width * height * 4));
	
	if (spp == 2) {
		
		// Convert from GA to ARGB
		for (i = 0; i < width * height; i++) {
			ndata[i * 4] = 0xFF;
			ndata[i * 4 + 1] = data[i * 2];
			ndata[i * 4 + 2] = data[i * 2];
			ndata[i * 4 + 3] = data[i * 2];
		}
	
	}
	else {
	
		// I'm writing this on an Intel machine but AltiVec still kicks ass
	
		// Determine vector length and prepare vector arrays
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		#ifdef __ppc__
		vdata = (vector unsigned char *)data;
		rvdata = (vector unsigned char *)ndata;
		#else
		vdata = (__m128i *)data;
		rvdata = (__m128i *)ndata;
		#endif
		
		// Convert from RGBA to ARGB with A = 0xFF
		#ifdef __ppc__
		vdata = (vector unsigned char *)data;
		for (i = 0; i < vec_len; i++) {
			rvdata[i] = vec_perm(vdata[i], HIGHVEC, TOGGLERGBF);
		}
		#else
		for (i = 0; i < 16; i++) {
			ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
		}
		memcpy(&orvmask, ormask, 16);
		for (i = 0; i < vec_len; i++) {
			rvdata[i] = _mm_slli_epi32(vdata[i], 8);
			rvdata[i] = _mm_or_si128(rvdata[i], orvmask);
		}
		#endif
		
	}
	
	return ndata;
}

- (unsigned char *)executeAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data width:(int)width height:(int)height newWidth:(int *)newWidth newHeight:(int *)newHeight newSpp:(int *)nspp
{
	CIContext *context;
	CIImage *unclampedInput, *clampedInput, *output;
	CIFilter *clamp, *filter;
	CGImageRef temp_image;
	CGImageDestinationRef temp_writer;
	NSMutableData *temp_handler;
	NSBitmapImageRep *temp_rep;
	CGSize size;
	CGRect rect;
	unsigned char *resdata;
	CIColor *backColor;
	NSPoint point[4], minPoint, maxPoint;
	PluginData *pluginData;
	
	// Find core image context
	pluginData = [(PSPlugins *)seaPlugins data];
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)[pluginData displayProf], kCIContextWorkingColorSpace, (id)[pluginData displayProf], kCIContextOutputColorSpace, NULL]];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	unclampedInput = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData dataColorSpace]];

	// We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
	// the content outside the borders of the image
	clamp = [CIFilter filterWithName: @"CIAffineClamp"];
	[clamp setDefaults];
	[clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	[clamp setValue:unclampedInput forKey: @"inputImage"];
	clampedInput = [clamp valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIAffineTransform"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIAffineTransform"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:clampedInput forKey:@"inputImage"];
	[filter setValue:at forKey:@"inputTransform"];
	output = [filter valueForKey: @"outputImage"];

	// Figure out transformation
	point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
	minPoint = point[0]; maxPoint = point[0];
	point[1] = [at transformPoint:NSMakePoint(width, 0.0)];
	minPoint.x = MIN(point[1].x, minPoint.x); minPoint.y = MIN(point[1].y, minPoint.y);
	maxPoint.x = MAX(point[1].x, maxPoint.x); maxPoint.y = MAX(point[1].y, maxPoint.y);
	point[2] = [at transformPoint:NSMakePoint(0.0, height)];
	minPoint.x = MIN(point[2].x, minPoint.x); minPoint.y = MIN(point[2].y, minPoint.y);
	maxPoint.x = MAX(point[2].x, maxPoint.x); maxPoint.y = MAX(point[2].y, maxPoint.y);
	point[3] = [at transformPoint:NSMakePoint(width, height)];
	minPoint.x = MIN(point[3].x, minPoint.x); minPoint.y = MIN(point[3].y, minPoint.y);
	maxPoint.x = MAX(point[3].x, maxPoint.x); maxPoint.y = MAX(point[3].y, maxPoint.y);

	// Create output core image
	rect.origin.x = minPoint.x;
	rect.origin.y = minPoint.y;
	rect.size.width = maxPoint.x - minPoint.x;
	rect.size.height = maxPoint.y - minPoint.y;
	temp_image = [context createCGImage:output fromRect:rect];

	// Get data from output core image
	temp_handler = [NSMutableData dataWithLength:0];
	temp_writer = CGImageDestinationCreateWithData((CFMutableDataRef)temp_handler, kUTTypeTIFF, 1, NULL);
	CGImageDestinationAddImage(temp_writer, temp_image, NULL);
	CGImageDestinationFinalize(temp_writer);
	temp_rep = [NSBitmapImageRep imageRepWithData:temp_handler];
	resdata = [temp_rep bitmapData];
	
	// Record the new width and height
	*newWidth = [temp_rep pixelsWide];
	*newHeight = [temp_rep pixelsHigh];
	*nspp = [temp_rep samplesPerPixel];
	
	return resdata;
}

- (unsigned char *)unprepareImage:(unsigned char *)data spliceAlpha:(unsigned char *)alpha spp:(int)spp ispp:(int)ispp width:(int)width height:(int)height
{
	#ifdef __ppc__
	vector unsigned char TOGGLERGBR = (vector unsigned char)(0x00, 0x01, 0x02, 0x13, 0x04, 0x05, 0x06, 0x17, 0x08, 0x09, 0x0A, 0x1B, 0x0C, 0x0D, 0x0E, 0x1F);
	vector unsigned char HIGHVEC = (vector unsigned char)(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
	vector unsigned char *vdata, *rvdata, *ovdata;
	int vec_len;
	#endif
	unsigned char *ndata;
	int i;

	ndata = malloc(make_128(width * height * 4));
	
	if (spp == 2) {
	
		for (i = 0; i < width * height; i++) {
			// The transformation apparently will always return spp as 4, which means that when
			// transforming something that's greyscale, if we force the spp of the output to have been
			// 2, then we'll never get the data. Conviently, by just taking the first channel, we're
			// able to get perfectly fine data.
			//if (ispp == 2) {
				ndata[i * 2] = data[i * ispp];
				ndata[i * 2 + 1] = (alpha ?  alpha[i * ispp] : 0xFF);
			//}
		}
		
	}
	else {
		
		// I'm writing this on an Intel machine but AltiVec still kicks ass
		// Maybe, if it worked...
		#if __ppc__
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		vdata = (vector unsigned char *)data;
		rvdata = (vector unsigned char *)ndata;
		
		if (alpha) {
			ovdata = (vector unsigned char *)alpha;
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_perm(vdata[i], ovdata[i], TOGGLERGBR);
			}
		}
		else {
			for (i = 0; i < vec_len; i++) {
				rvdata[i] = vec_perm(vdata[i], HIGHVEC, TOGGLERGBR);
			}
		}
		#else
		for (i = 0; i < width * height; i++) {
			ndata[i * 4] = data[i * ispp];
			ndata[i * 4 + 1] = data[i * ispp + 1];
			ndata[i * 4 + 2] = data[i * ispp + 2];
			ndata[i * 4 + 3] = (alpha ? alpha[i * ispp] : 0xFF);
		}
		//#endif
		
	}
	
	return ndata;
}

- (unsigned char *)runAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height opaque:(BOOL)opaque newWidth:(int *)newWidth newHeight:(int *)newHeight
{
	unsigned char *ndata, *nadata, *mdata, *madata, *odata;
	int nspp;
	
	madata = NULL;
	ndata = [self prepareAffineTransform:at withImage:data spp:spp width:width height:height];
	mdata = [self executeAffineTransform:at withImage:ndata width:width height:height newWidth:newWidth newHeight:newHeight newSpp:&nspp];
	free(ndata);
	if (!opaque) {
		nadata = [self prepareAlphaAffineTransform:at withImage:data spp:spp width:width height:height];
		madata = [self executeAffineTransform:at withImage:nadata width:width height:height newWidth:newWidth newHeight:newHeight newSpp:&nspp];
		free(nadata);
	}
	odata = [self unprepareImage:mdata spliceAlpha:madata spp:spp ispp:nspp width:*newWidth height:*newHeight];
	
	return odata;
}
*/

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
