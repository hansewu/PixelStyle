//
//  WEBPExporter.m
//  PixelStyle
//
//  WebP export using libwebp (dynamically loaded at runtime).
//  Both arm64 and x86_64 use libwebp because CGImageDestination
//  on macOS 15.3 does NOT natively support WebP encoding.
//  libwebp.7.dylib (arm64, Homebrew 1.2.2) lives in:
//    Extralibs/libwebp.7.dylib  (copied to app bundle Frameworks/ at build time)
//
//  Symbol table:
//    WebPEncodeBGRA(uint8_t *bgr, int w, int h, int stride, float quality, uint8_t **out)
//    free()  — use C free to release encoded buffer
//

#import "WEBPExporter.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import <dlfcn.h>
#import <WebP/encode.h>

// Typedefs for dlsym
typedef uint8_t *(*WebPEncodeBGRAFunc)(const uint8_t *, int, int, int, float, uint8_t **);
// Note: free() is the standard C library function — no typedef needed.

@implementation WEBPExporter

#pragma mark - Initialization and cleanup

- (id)init
{
    self = [super init];
    if (self) {
        // Default quality is 80% (0.8)
        m_fQuality = 0.8f;
        
        // Load saved quality from user defaults if available
        if ([gUserDefaults objectForKey:@"webp quality"] != NULL) {
            float savedQuality = [gUserDefaults floatForKey:@"webp quality"];
            if (savedQuality >= 0.0f && savedQuality <= 1.0f) {
                m_fQuality = savedQuality;
            }
        }
    }
    return self;
}

- (void)dealloc
{
    if (m_pSampleData) {
        free(m_pSampleData);
        m_pSampleData = NULL;
    }
    [super dealloc];
}

#pragma mark - AbstractExporter required methods

- (NSString *)title
{
    // Must match CFBundleTypeName in Info.plist CFBundleDocumentTypes
    return @"WebP Image (WEBP)";
}

- (NSString *)extension
{
    return @"webp";
}

- (BOOL)hasOptions
{
    return YES;
}

- (NSString *)optionsString
{
    return [NSString stringWithFormat:@"Webp:%d%%", (int)roundf(m_fQuality * 100.0)];
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    // Get raw pixel data from document
    unsigned char *srcData = [(PSWhiteboard *)[document whiteboard] data];
    int width  = [(PSContent *)[document contents] width];
    int height = [(PSContent *)[document contents] height];

    // All data treated as 32-bit BGRA
    int outStride = width * 4;
    int outSize   = outStride * height;
    unsigned char *outBuf = (unsigned char *)malloc(outSize);
    if (!outBuf) {
        NSLog(@"WebP export failed: could not allocate %d bytes.", outSize);
        return NO;
    }

    // Copy as-is (always 4 bytes per pixel)
    //memcpy(outBuf, srcData, outSize);
    unsigned char *src = (unsigned char *)srcData;
    for (int i = 0; i < width * height; i++) {
        unsigned char r = src[i*4 + 0];
        unsigned char g = src[i*4 + 1];
        unsigned char b = src[i*4 + 2];
        unsigned char a = src[i*4 + 3];
        outBuf[i*4 + 0] = b;   // B → position 0
        outBuf[i*4 + 1] = g;   // G stays
        outBuf[i*4 + 2] = r; //r;   // R → position 2
        outBuf[i*4 + 3] = a;   // A stays
    }
    BOOL ok = [self writeWebP:outBuf
                         width:width
                        height:height
                        stride:outStride
                  qualityFactor:m_fQuality
                            to:path];
    free(outBuf);
    return ok;
}

#pragma mark - Public export entry point
/*
- (BOOL)writeToPath:(NSString *)path
              width:(int)width
             height:(int)height
           withData:(NSData *)srcData
          sourceRep:(NSBitmapImageRep *)sourceRep
{
    if (!srcData || width <= 0 || height <= 0) {
        NSLog(@"WebP export failed: invalid input.");
        return NO;
    }

    const unsigned char *srcPixels = srcData.bytes;

    // All data treated as 32-bit BGRA
    int outStride = width * 4;
    int outSize   = outStride * height;
    unsigned char *outBuf = (unsigned char *)malloc(outSize);
    if (!outBuf) {
        NSLog(@"WebP export failed: could not allocate %d bytes.", outSize);
        return NO;
    }

    // Copy and swap RGBA → BGRA (exchange R and B channels)
    unsigned char *src = (unsigned char *)srcPixels;
    for (int i = 0; i < width * height; i++) {
        unsigned char r = src[i*4 + 0];
        unsigned char g = src[i*4 + 1];
        unsigned char b = src[i*4 + 2];
        unsigned char a = src[i*4 + 3];
        outBuf[i*4 + 0] = 0xff;   // B → position 0
        outBuf[i*4 + 1] = 0xff;   // G stays
        outBuf[i*4 + 2] = 0xff; //r;   // R → position 2
        outBuf[i*4 + 3] = a;   // A stays
    }

    // Encode with libwebp (both arm64 and x86_64)
    BOOL ok = [self writeWebP:outBuf
                         width:width
                        height:height
                        stride:outStride
                  qualityFactor:m_fQuality
                            to:path];

    free(outBuf);
    return ok;
}
*/

#pragma mark - libwebp core (all architectures)

- (BOOL)writeWebP:(unsigned char *)bgra
             width:(int)width
            height:(int)height
            stride:(int)stride
      qualityFactor:(float)quality
                to:(NSString *)path
{
    static void *sHandle = NULL;   // loaded once per process
    static WebPEncodeBGRAFunc sEncode = NULL;

    if (sHandle == NULL) {
        // ----------------------------------------------------------------
        // Locate libwebp.7.dylib
        //
        // Strategy:
        //   1. @executable_path/../Frameworks/libwebp.7.dylib  (normal bundle layout)
        //   2. @executable_path/../Resources/Extralibs/libwebp.7.dylib
        //   3. [[NSBundle mainBundle] privateFrameworksPath]/libwebp.7.dylib
        //   4. [[NSBundle mainBundle] executablePath]/../Frameworks/libwebp.7.dylib
        // ----------------------------------------------------------------
        NSBundle *main = [NSBundle mainBundle];
        NSArray *searchPaths = @[
            [main.bundlePath stringByAppendingPathComponent:@"Contents/Frameworks/libwebp.7.dylib"],
            [main.bundlePath stringByAppendingPathComponent:@"Contents/Resources/Extralibs/libwebp.7.dylib"],
            [[main privateFrameworksPath] stringByAppendingPathComponent:@"libwebp.7.dylib"],
            [[[main executablePath] stringByDeletingLastPathComponent]
                                         stringByAppendingPathComponent:@"Frameworks/libwebp.7.dylib"]
        ];

        NSString *dylibPath = nil;
        for (NSString *p in searchPaths) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
                dylibPath = p;
                break;
            }
        }

        if (!dylibPath) {
            NSLog(@"WebP export failed: libwebp.7.dylib not found. Searched:\n%@",
                  [searchPaths componentsJoinedByString:@"\n"]);
            return NO;
        }

        dlerror();   // clear any stale error
        sHandle = dlopen([dylibPath UTF8String], RTLD_NOW);
        if (!sHandle) {
            NSLog(@"WebP export failed: dlopen(%@) error: %s", dylibPath, dlerror());
            return NO;
        }

        sEncode = (WebPEncodeBGRAFunc)dlsym(sHandle, "WebPEncodeBGRA");

        if (!sEncode) {
            NSLog(@"WebP export failed: could not resolve symbol WebPEncodeBGRA");
            dlclose(sHandle);
            sHandle = NULL;
            return NO;
        }

        NSLog(@"WebP export: loaded libwebp from %@", dylibPath);
    }

    // Encode
    // WebPEncodeBGRA: returns size_t (encoded byte count); sets *output to
    // the malloc'd buffer.  The buffer must be freed with free().
    uint8_t *webpData = NULL;
    size_t   webpSize = sEncode(bgra, width, height, stride, quality, &webpData);

    if (!webpData || webpSize == 0) {
        NSLog(@"WebP export failed: WebPEncodeBGRA returned size=0 (data=%p).", webpData);
        return NO;
    }

    // freeWhenDone=NO: we manage the buffer lifetime ourselves.
    NSData *webpNSData = [NSData dataWithBytesNoCopy:webpData
                                              length:webpSize
                                        freeWhenDone:NO];
    NSError *error = nil;
    BOOL ok = [webpNSData writeToFile:path options:NSDataWritingAtomic error:&error];
    free(webpData);   // always free after write

    if (!ok) {
        NSLog(@"WebP export failed: could not write to %@: %@", path, error);
        return NO;
    }

    return YES;
}

#pragma mark - Quality options panel

- (float)reviseQuality
{
    // Update quality label if it exists
    if (m_idQualityLabel) {
        [m_idQualityLabel setStringValue:[NSString stringWithFormat:@"Quality: %d%%", (int)roundf(m_fQuality * 100.0)]];
    }
    return m_fQuality;
}

- (IBAction)qualityChanged:(id)sender
{
    // Get new quality from slider (0-100 range)
    int sliderValue = [m_idQualitySlider intValue];
    m_fQuality = (float)sliderValue / 100.0f;
    
    // Update label
    [self reviseQuality];
    
    // Update preview if available
    if (m_idRealImageRep && m_idCompressImageView) {
        // For WebP, we could regenerate preview, but for now just update label
        // In the future, we could encode a small preview image
    }
}

- (IBAction)endPanel:(id)sender
{
    // Determine if OK (tag=1) or Cancel (tag=0) was clicked
    if ([sender isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)sender;
        if ([button tag] == 0) {
            // Cancel: restore original quality
            m_fQuality = m_fOriginalQuality;
        } else {
            // OK: save quality to user defaults
            [gUserDefaults setFloat:m_fQuality forKey:@"webp quality"];
        }
    } else {
        // Default: save quality
        [gUserDefaults setFloat:m_fQuality forKey:@"webp quality"];
    }
    
    // Close the modal panel
    [NSApp stopModal];
    [m_idPanel orderOut:self];
}

- (void)showOptions:(id)document
{
    // Save original quality in case user cancels
    m_fOriginalQuality = m_fQuality;
    
    // Create options panel dynamically (similar to JPEG exporter)
    NSRect panelRect = NSMakeRect(0, 0, 400, 200);
    m_idPanel = [[NSWindow alloc] initWithContentRect:panelRect
                                            styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask)
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
    [m_idPanel setTitle:@"WebP Export Options"];
    [m_idPanel setReleasedWhenClosed:NO];
    
    // Create quality slider (0-100)
    NSRect sliderRect = NSMakeRect(50, 120, 300, 25);
    m_idQualitySlider = [[NSSlider alloc] initWithFrame:sliderRect];
    [m_idQualitySlider setMinValue:0];
    [m_idQualitySlider setMaxValue:100];
    [m_idQualitySlider setIntValue:(int)roundf(m_fQuality * 100.0f)];
    [m_idQualitySlider setTarget:self];
    [m_idQualitySlider setAction:@selector(qualityChanged:)];
    [[m_idPanel contentView] addSubview:m_idQualitySlider];
    
    // Create quality label
    NSRect labelRect = NSMakeRect(50, 150, 300, 20);
    m_idQualityLabel = [[NSTextField alloc] initWithFrame:labelRect];
    [m_idQualityLabel setStringValue:@""];
    [m_idQualityLabel setBezeled:NO];
    [m_idQualityLabel setDrawsBackground:NO];
    [m_idQualityLabel setEditable:NO];
    [m_idQualityLabel setSelectable:NO];
    [[m_idPanel contentView] addSubview:m_idQualityLabel];
    
    // Create OK button (tag = 1)
    NSRect okButtonRect = NSMakeRect(200, 50, 80, 30);
    NSButton *okButton = [[NSButton alloc] initWithFrame:okButtonRect];
    [okButton setTitle:@"OK"];
    [okButton setButtonType:NSMomentaryPushInButton];
    [okButton setBezelStyle:NSRoundedBezelStyle];
    [okButton setTarget:self];
    [okButton setAction:@selector(endPanel:)];
    [okButton setTag:1];
    [[m_idPanel contentView] addSubview:okButton];
    [okButton release];
    
    // Create Cancel button (tag = 0)
    NSRect cancelButtonRect = NSMakeRect(290, 50, 80, 30);
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:cancelButtonRect];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setButtonType:NSMomentaryPushInButton];
    [cancelButton setBezelStyle:NSRoundedBezelStyle];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(endPanel:)];
    [cancelButton setTag:0];
    [[m_idPanel contentView] addSubview:cancelButton];
    [cancelButton release];
    
    // Update quality label
    [self reviseQuality];
    
    // Display the options dialog
    [m_idPanel center];
    [NSApp runModalForWindow:m_idPanel];
    
    // Clean up (panel will be released when closed)
    [m_idQualitySlider release];
    [m_idQualityLabel release];
    [m_idPanel release];
    m_idPanel = nil;
    m_idQualitySlider = nil;
    m_idQualityLabel = nil;
}

#pragma mark - Preview helper (similar to JPEGExporter)

static CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied);

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
