#import "JPEGExporter.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"
#import "PSDocument.h"
#import "Bitmap.h"

static unsigned char *cmData;
static unsigned int cmLen;

static BOOL JPEGReviseResolution(unsigned char *input, unsigned int len, int xres, int yres)
{
	int dataPos;
	short *temp;
	unsigned short xress, yress;
	
	for (dataPos = 0; dataPos < len; dataPos++) {
		if (input[dataPos] == 'J') {
			if (memcmp(&(input[dataPos]), "JFIF\x00\x01", 6) == 0) {
				dataPos = dataPos + 7;
				xress = xres;
				yress = yres;
				xress = htons(xress);
				yress = htons(yress);
				input[dataPos] = 0x01;
				dataPos++;
				temp = (short *)&(input[dataPos]);
				temp[0] = xress;
				temp[1] = yress;
				return YES;
			}
		}
	}
	
	return NO;
}

static OSErr getcm(SInt32 command, SInt32 *size, void *data, void *refCon)
{
	if (cmData == NULL) {
		cmData = malloc(*size);
		memcpy(cmData, data, *size);
		cmLen = *size;
	}
	else {
		cmData = realloc(cmData, cmLen + *size);
		memcpy(&(cmData[cmLen]), data, *size);
		cmLen += *size;
	}
	
	return 0;
}

@implementation JPEGExporter

-(void)awakeFromNib
{
    [m_idCompressImageView setToolTip:NSLocalizedString(@"Preview the output effect of the central portion of the canvas", nil)];
}

- (id)init
{
	int value;
	
	if ([gUserDefaults objectForKey:@"jpeg target"] == NULL)
		m_bTargetWeb = YES;
	else
		m_bTargetWeb = [gUserDefaults boolForKey:@"jpeg target"];
	
	if ([gUserDefaults objectForKey:@"jpeg web compression"] == NULL) {
		value = 26;
	}
	else {
		value = [gUserDefaults integerForKey:@"jpeg web compression"];
		if (value < 0 || value > kMaxCompression)
			value = 26;
	}
	m_nWebCompression = value;
	
	if ([gUserDefaults objectForKey:@"jpeg print compression"] == NULL) {
		value = 30;
	}
	else {
		value = [gUserDefaults integerForKey:@"jpeg print compression"];
		if (value < 0 || value > kMaxCompression)
			value = 30;
	}
	m_nPrintCompression = value;
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)hasOptions
{
	return YES;
}

- (float)reviseCompression
{
	float result;
	
	if (m_bTargetWeb) {
		if (m_nWebCompression < 5) {
			result = 0.1 + 0.08 * (float)m_nWebCompression;
		}
		else if (m_nWebCompression < 10) {
			result = 0.3 + 0.04 * (float)m_nWebCompression;
		}
		else if (m_nWebCompression < 20) {
			result = 0.5 + 0.02 * (float)m_nWebCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)m_nWebCompression;
		}
	}
	else {
		if (m_nPrintCompression < 5) {
			result = 0.1 + 0.08 * (float)m_nPrintCompression;
		}
		else if (m_nPrintCompression < 10) {
			result = 0.3 + 0.04 * (float)m_nPrintCompression;
		}
		else if (m_nPrintCompression < 20) {
			result = 0.5 + 0.02 * (float)m_nPrintCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)m_nPrintCompression;
		}
	}
	[m_idCompressLabel setStringValue:[NSString stringWithFormat:@"Compressed - %d%%", (int)roundf(result * 100.0)]];
	
	return result;
}

-(int)getWhiteBoardData:(id)document width:(int)nWidth height:(int)nHeight bufferOut:(unsigned char *)pBufRGBA
{
    memset(pBufRGBA, 0, nWidth*nHeight*4);
    CGContextRef context = MyCreateBitmapContext(nWidth , nHeight, pBufRGBA, true);
    assert(nil != context);
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:nHeight];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    
    [[[document whiteboard] compositor] compositeLayersToContextFull:context];
    
    unsigned char *pBuf1 = (unsigned char *)CGBitmapContextGetData(context);
    assert(pBuf1 == pBufRGBA);
    
    CGContextRelease(context);
    
    return 0;
}

- (void)showOptions:(id)document
{
	unsigned char *temp, *data;
	int width = [(PSContent *)[document contents] width], height = [(PSContent *)[document contents] height], spp = [[document contents] spp];
	int i, j, k, x, y;
	id realImage, compressImage;
	float value;
	
	// Work things out
	if (m_bTargetWeb)
		[m_idTargetRadios selectCellAtRow:0 column:0];
	else
		[m_idTargetRadios selectCellAtRow:0 column:1];
	
	// Revise the compression
	if (m_bTargetWeb)
		[m_idCompressSlider setIntValue:m_nWebCompression];
	else
		[m_idCompressSlider setIntValue:m_nPrintCompression];
	value = [self reviseCompression];
	
	// Set-up the sample data
//	data = [(PSWhiteboard *)[document whiteboard] data];
    data = malloc(width * height * spp);
    [self getWhiteBoardData:document width:width height:height bufferOut:data];
    
	m_pSampleData = malloc(40 * 40 * 3);
	temp = malloc(40 * 40 * 4);
	memset(temp, 0x00, 40 * 40 * 4);
	for (j = 0; j < 40; j++) {
		for (i = 0; i < 40; i++) {
			x = width / 2 - 20 + i;
			y = height / 2 - 20 + j;
			if (x >= 0 && x < width && y >= 0 && y < height) {
				if (spp == 4) {
					for (k = 0; k < 4; k++)
						temp[(j * 40 + i) * 4 + k] = data[(y * width + x) * 4 + k];
				}
				else {
					for (k = 0; k < 3; k++)
						temp[(j * 40 + i) * 4 + k] = data[(y * width + x) * 2];
					temp[(j * 40 + i) * 4 + 3] = data[(y * width + x) * 2 + 1];
				}
			}
		}
	}
	stripAlphaToWhite(4, m_pSampleData, temp, 40 * 40);
	free(temp);
	
    free(data); data = nil;
    
	// Now make an image for the view
	m_idRealImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pSampleData pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:40 * 3 bitsPerPixel:8 * 3];
	realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
	[realImage addRepresentation:m_idRealImageRep];
	[m_idRealImageView setImage:realImage];
	compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[m_idCompressImageView setImage:compressImage];
	[compressImage autorelease];
	
	// Display the options dialog
	[m_idPanel center];
	[NSApp runModalForWindow:m_idPanel];
	[m_idPanel orderOut:self];
	
	// Clean-up
	[gUserDefaults setObject:(m_bTargetWeb ? @"YES" : @"NO") forKey:@"jpeg target"];
	if (m_bTargetWeb)
		[gUserDefaults setInteger:m_nWebCompression forKey:@"jpeg web compression"];
	else
		[gUserDefaults setInteger:m_nPrintCompression forKey:@"jpeg print compression"];
	free(m_pSampleData);
	[m_idRealImageRep autorelease];
	[realImage autorelease];
}

- (IBAction)compressionChanged:(id)sender
{
	id compressImage;
	float value;
	
	if (m_bTargetWeb)
		m_nWebCompression = [m_idCompressSlider intValue];
	else
		m_nPrintCompression = [m_idCompressSlider intValue];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImage autorelease];
	[m_idCompressImageView setImage:compressImage];
	[m_idCompressImageView display];
}

- (IBAction)targetChanged:(id)sender
{
	id compressImage;
	float value;
	
	// Determine the target
	if ([m_idTargetRadios selectedColumn] == 0)
		m_bTargetWeb = YES;
	else
		m_bTargetWeb = NO;
	
	// Revise the compression
	if (m_bTargetWeb)
		[m_idCompressSlider setIntValue:m_nWebCompression];
	else
		[m_idCompressSlider setIntValue:m_nPrintCompression];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImage autorelease];
	[m_idCompressImageView setImage:compressImage];
	[m_idCompressImageView display];
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"JPEG image (JPG)";
}

- (NSString *)extension
{
	return @"jpg";
}

- (NSString *)optionsString
{
	if (m_bTargetWeb)
		return [NSString stringWithFormat:@"Web %.0f%%", [self reviseCompression] * 100.0];
	else
		return [NSString stringWithFormat:@"Print %.0f%%", [self reviseCompression] * 100.0];
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    int nXRes = [(PSContent *)[document contents] xres];
    int nYRes = [(PSContent *)[document contents] yres];
    
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:[self reviseCompression]], kCGImageDestinationLossyCompressionQuality,
                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
                                nil];
    return [self basicWriteDocument:document toFile:path representationUsingType:NSJPEGFileType properties:properties];
/*
    float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
    int nWidth = [(PSContent *)[document contents] width];
    int nHeight = [(PSContent *)[document contents] height];
    NSSize imageSize = NSMakeSize(nWidth/fScreenScale, nHeight/fScreenScale);
    
    
    //画到NSImage
    NSImage *image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(imageSize)];
    [image lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextConcatCTM(context, CGAffineTransformMakeScale(1/fScreenScale, 1/fScreenScale));
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:nHeight];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    [[[document whiteboard] compositor] compositeLayersToContextFull:context];
    CGContextRestoreGState(context);
    //存到文件中，设置imageData的格式
//    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)] autorelease];
    
    [image unlockFocus];
    
    int nXRes = [(PSContent *)[document contents] xres];
    int nYRes = [(PSContent *)[document contents] yres];
    NSBitmapImageRep* savedImageBitmapRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1.0]];
    
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:[self reviseCompression]], kCGImageDestinationLossyCompressionQuality,
                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
                                nil];
    
    NSMutableData* imageData = [NSMutableData data];
    CGImageDestinationRef imageDest =  CGImageDestinationCreateWithData((CFMutableDataRef) imageData, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(imageDest, [savedImageBitmapRep CGImage], (CFDictionaryRef) properties);
    CGImageDestinationFinalize(imageDest);
    
//    int nXRes = [(PSContent *)[document contents] xres];
//    int nYRes = [(PSContent *)[document contents] yres];
//    bitmap.pixelsWide = imageSize.width * nXRes/72.0;
//    bitmap.pixelsHigh = imageSize.height * nYRes/72.0;
//    
//    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
//                                [NSNumber numberWithFloat:[self reviseCompression]], NSImageCompressionFactor,
//                                [NSNumber numberWithInteger:nYRes], kCGImagePropertyDPIHeight,
//                                [NSNumber numberWithInteger:nXRes], kCGImagePropertyDPIWidth,
//                                nil];
//    
//     //Save to a file
//    NSData *imageData = [bitmap representationUsingType:NSJPEGFileType properties:properties];
    
    // Now add in the resolution settings
    // Notice how we are working on [imageData bytes] despite being explicitly told not to in Cocoa's documentation - well if Cocoa gave us proper resolution handling that wouldn't be a problem
    int xres = [[document contents] xres];
    int yres = [[document contents] yres];
    if (!JPEGReviseResolution((unsigned char *)[imageData bytes], [imageData length], xres, yres))
        NSLog(@"The resolution of the current JPEG file could not be saved. This indicates a change in the approach with which Cocoa saves JPEG files. Please contact the author, quoting this log message, for further assistance.");
    
    //写文件
    [imageData writeToFile:path atomically:YES];
    
    [image release];
    if (imageDest)
        CFRelease(imageDest);
    
    return YES;
    */
//    int width, height, xres, yres, spp;
//    unsigned char *srcData, *destData;
//    NSBitmapImageRep *imageRep;
//    NSData *imageData;
//    NSDictionary *exifData;
//    CMProfileRef cmProfile;
//    Boolean cmmNotFound;
//    
//    // Get the data to write
//    srcData = [(PSWhiteboard *)[document whiteboard] data];
//    width = [(PSContent *)[document contents] width];
//    height = [(PSContent *)[document contents] height];
//    spp = [(PSContent *)[document contents] spp];
//    xres = [[document contents] xres];
//    yres = [[document contents] yres];
//    
//    // Strip the alpha channel if necessary
//    destData = malloc(width * height * (spp - 1));
//    stripAlphaToWhite(spp, destData, srcData, width * height);
//    spp--;
//    
//    // Make an image representation from the data
//    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:NO isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
//    
//    // Add EXIF data
//    exifData = [[document contents] exifData];
//    if (exifData) [imageRep setProperty:@"NSImageEXIFData" withValue:exifData];
//    
//    // Embed ColorSync profile
//    if (!m_bTargetWeb) {
//        if (spp < 3)
//            CMGetDefaultProfileBySpace(cmGrayData, &cmProfile);
//        else
//            OpenDisplayProfile(&cmProfile);
//        cmData = NULL;
//        //CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
//		if (cmData) {
//			[imageRep setProperty:NSImageColorSyncProfileData withValue:[NSData dataWithBytes:cmData length:cmLen]];
//			free(cmData);
//		}
//		if (spp >= 3) CloseDisplayProfile(cmProfile);
//	}
//	
//	// Finally build the JPEG data
//	imageData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]];
//	
//	// Now add in the resolution settings
//	// Notice how we are working on [imageData bytes] despite being explicitly told not to in Cocoa's documentation - well if Cocoa gave us proper resolution handling that wouldn't be a problem
//	if (!JPEGReviseResolution((unsigned char *)[imageData bytes], [imageData length], xres, yres))
//		NSLog(@"The resolution of the current JPEG file could not be saved. This indicates a change in the approach with which Cocoa saves JPEG files. Please contact the author, quoting this log message, for further assistance."); 
//
//	// Save our file and let's go
//	[imageData writeToFile:path atomically:YES];
//	[imageRep autorelease];
//	
//	// If the destination data is not equivalent to the source data free the former
//	if (destData != srcData)
//		free(destData);
//	
//	return YES;
}

static CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied)
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
    int  bitmapByteCount;
    int  bitmapBytesPerRow;
    
    bitmapBytesPerRow  = (pixelsWidth * 4);
    bitmapByteCount  = (bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    //bitmapData = malloc( bitmapByteCount );
    bitmapData = pBuffer;
    //bitmapData =(char*)CGBitmapContextGetData((CGContextRef)[EAGLContext currentContext]);//   m_glContext
    if (bitmapData == NULL)
    {
        assert(false);
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    
    //  if(bAlphaPremultiplied)
    context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    //  else
    //context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big);
    if (context== NULL)
    {
        //free (bitmapData);
        assert(false);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

@end
