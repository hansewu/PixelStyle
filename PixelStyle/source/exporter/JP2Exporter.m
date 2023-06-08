#import "JP2Exporter.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "Bitmap.h"
#import "PSDocument.h"
#import "Bitmap.h"

static unsigned char *cmData;
static unsigned int cmLen;

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

@implementation JP2Exporter

-(void)awakeFromNib
{
    [m_idCompressImageView setToolTip:NSLocalizedString(@"Preview the output effect of the central portion of the canvas", nil)];
}

- (id)init
{
    self  = [super init];
    
    int value;
    
    if ([gUserDefaults objectForKey:@"jp2 target"] == NULL)
        m_bTargetWeb = YES;
    else
        m_bTargetWeb = [gUserDefaults boolForKey:@"jp2 target"];
    
    if ([gUserDefaults objectForKey:@"jp2 web compression"] == NULL) {
        value = 26;
    }
    else {
        value = [gUserDefaults integerForKey:@"jp2 web compression"];
        if (value < 0 || value > kMaxCompression)
            value = 26;
    }
    m_nWebCompression = value;
    
    if ([gUserDefaults objectForKey:@"jp2 print compression"] == NULL) {
        value = 30;
    }
    else {
        value = [gUserDefaults integerForKey:@"jp2 print compression"];
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
#ifdef MACOS_10_4_COMPILE
    return YES;
#else
    return NO;
#endif
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

/*
	if (spp == 4) {
 for (k = 0; k < 3; k++)
 m_pSampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 4 + k];
 m_pSampleData[(j * 40 + i) * 4] = data[(y * width + x) * 4 + 3];
	}
	else {
 for (k = 0; k < 3; k++)
 m_pSampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 2];
 m_pSampleData[(j * 40 + i) * 4] = data[(y * width + x) * 2 + 1];
	}
 */

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
#ifdef MACOS_10_4_COMPILE
    unsigned char *data;
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
//    data = [(PSWhiteboard *)[document whiteboard] data];
    data = malloc(width * height * spp);
    [self getWhiteBoardData:document width:width height:height bufferOut:data];
    
    m_pSampleData = malloc(40 * 40 * 4);
    memset(m_pSampleData, 0x00, 40 * 40 * 4);
    for (j = 0; j < 40; j++) {
        for (i = 0; i < 40; i++) {
            x = width / 2 - 20 + i;
            y = height / 2 - 20 + j;
            if (x >= 0 && x < width && y >= 0 && y < height) {
                if (spp == 4) {
                    for (k = 0; k < 4; k++)
                        m_pSampleData[(j * 40 + i) * 4 + k] = data[(y * width + x) * 4 + k];
                }
                else {
                    for (k = 0; k < 3; k++)
                        m_pSampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 2];
                    m_pSampleData[(j * 40 + i) * 4] = data[(y * width + x) * 2 + 1];
                }
            }
        }
    }
    premultiplyBitmap(4, m_pSampleData, m_pSampleData, 40 * 40);
    
    free(data); data = nil;
    // Now make an image for the view
    m_idRealImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pSampleData pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:40 * 4 bitsPerPixel:8 * 4];
    realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
    [realImage addRepresentation:m_idRealImageRep];
    [m_idRealImageView setImage:realImage];
    compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [m_idCompressImageView setImage:compressImage];
    [compressImage autorelease];
    
    // Display the options dialog
    [m_idPanel center];
    [NSApp runModalForWindow:m_idPanel];
    [m_idPanel orderOut:self];
    
    // Clean-up
    [gUserDefaults setObject:(m_bTargetWeb ? @"YES" : @"NO") forKey:@"jp2 target"];
    if (m_bTargetWeb)
        [gUserDefaults setInteger:m_nWebCompression forKey:@"jp2 web compression"];
    else
        [gUserDefaults setInteger:m_nPrintCompression forKey:@"jp2 print compression"];
    free(m_pSampleData);
    [m_idRealImageRep autorelease];
    [realImage autorelease];
#endif
}

- (IBAction)compressionChanged:(id)sender
{
#ifdef MACOS_10_4_COMPILE
    id compressImage;
    float value;
    
    if (m_bTargetWeb)
        m_nWebCompression = [m_idCompressSlider intValue];
    else
        m_nPrintCompression = [m_idCompressSlider intValue];
    value = [self reviseCompression];
    compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [compressImage autorelease];
    [m_idCompressImageView setImage:compressImage];
    [m_idCompressImageView display];
#endif
}

- (IBAction)targetChanged:(id)sender
{
#ifdef MACOS_10_4_COMPILE
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
    compressImage = [[NSImage alloc] initWithData:[m_idRealImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [compressImage autorelease];
    [m_idCompressImageView setImage:compressImage];
    [m_idCompressImageView display];
#endif
}

- (IBAction)endPanel:(id)sender
{
#ifdef MACOS_10_4_COMPILE
    [NSApp stopModal];
#endif
}

- (NSString *)title
{
    return @"JPEG 2000 image (JP2)";
}

- (NSString *)extension
{
    return @"jp2";
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
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:[self reviseCompression]], NSImageCompressionFactor,nil];
    return [self basicWriteDocument:document toFile:path representationUsingType:NSJPEG2000FileType properties:properties];
/*
#ifdef MACOS_10_4_COMPILE
    
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
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)] autorelease];
    
    [image unlockFocus];
    
    
    
    NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:[self reviseCompression]], NSImageCompressionFactor,nil];
    
    // Save to a file
    NSData *imageData = [bitmap representationUsingType:NSJPEG2000FileType properties:properties];
    
    //写文件
    [imageData writeToFile:path atomically:YES];
    
    [image release];
    
    
    return YES;
    
    
//    int width, height, spp;
//    unsigned char *srcData, *destData;
//    NSBitmapImageRep *imageRep;
//    NSData *imageData;
//    CMProfileRef cmProfile;
//    Boolean cmmNotFound;
//    BOOL hasAlpha = NO;
//    int i, j;
//    
//    // Get the data to write
//    srcData = [(PSWhiteboard *)[document whiteboard] data];
//    width = [(PSContent *)[document contents] width];
//    height = [(PSContent *)[document contents] height];
//    spp = [(PSContent *)[document contents] spp];
//    
//    // Determine whether or not an alpha channel would be redundant
//    for (i = 0; i < width * height && hasAlpha == NO; i++) {
//        if (srcData[(i + 1) * spp - 1] != 255)
//            hasAlpha = YES;
//    }
//    
//    // Strip the alpha channel if necessary
//    if (!hasAlpha) {
//        spp--;
//        destData = malloc(width * height * spp);
//        for (i = 0; i < width * height; i++) {
//            for (j = 0; j < spp; j++)
//                destData[i * spp + j] = srcData[i * (spp + 1) + j];
//        }
//    }
//    else
//        destData = srcData;
//    
//    // Make an image representation from the data
//    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
//    
//    // Embed ColorSync profile
//    if (!m_bTargetWeb) {
//        if (spp < 3)
//            CMGetDefaultProfileBySpace(cmGrayData, &cmProfile);
//        else
//            OpenDisplayProfile(&cmProfile);
//        cmData = NULL;
//        //CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
//        if (cmData) {
//            [imageRep setProperty:NSImageColorSyncProfileData withValue:[NSData dataWithBytes:cmData length:cmLen]];
//            free(cmData);
//        }
//        if (spp >= 3) CloseDisplayProfile(cmProfile);
//    }
//    
//    // Finally build the JPEG 2000 data
//    imageData = [imageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]];
//    
//    // Save our file and let's go
//    [imageData writeToFile:path atomically:YES];
//    [imageRep autorelease];
//    
//    // If the destination data is not equivalent to the source data free the former
//    if (destData != srcData)
//        free(destData);
//    
//    return YES;
#else
    return NO;
#endif
 */
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
