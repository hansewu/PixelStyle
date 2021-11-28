//
//  PSAffinePerspectiveTransform.m
//  PixelStyle
//
//  Created by lchzh on 25/10/15.
//
//

#import "PSAffinePerspectiveTransform.h"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>


#define make_128(x) (x + 16 - (x % 16))

@implementation PSAffinePerspectiveTransform

- (id)init
{
    self = [super init];
    m_srcData = NULL;
    return self;
}

- (void)dealloc
{
    if (m_srcData) {
        free(m_srcData);
        m_srcData = NULL;
    }
    [super dealloc];
}


- (unsigned char*)makePerspectiveTransformWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl OnData:(unsigned char*)srcData FromRect:(IntRect)srcRect spp:(int)spp opaque:(BOOL)hasOpaque newWidth:(int*)newWidth newHeight:(int*)newHeight colorSpace:(CGColorSpaceRef)colorSpaceRef backColor:(NSColor *)nsBackColor
{
    NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    
    __m128i opaquea = _mm_set1_epi32(0x000000FF);
    __m128i *vdata, *voverlay, *vresdata;
    __m128i vstore;
    int vec_len;
    
    int width = srcRect.size.width;
    int height = srcRect.size.height;
    
    unsigned char *newdata = malloc((srcRect.size.width * srcRect.size.height * spp+15)/16*16); //to prevent _mm_srli_epi32 overflow
    premultiplyBitmap(4, newdata, srcData, srcRect.size.width * srcRect.size.height);
    srcData = newdata;
    
    vec_len = width * height * 4;
    if (vec_len % 16 == 0) { vec_len /= 16; }
    else { vec_len /= 16; vec_len++; }
    
    vdata = (__m128i *)newdata;
    for (int i = 0; i < vec_len; i++) {
        vstore = _mm_srli_epi32(vdata[i], 24);
        vdata[i] = _mm_slli_epi32(vdata[i], 8);
        vdata[i] = _mm_add_epi32(vdata[i], vstore);
    }
    
    CIContext *context;
    CIImage *input,  *output;
    CIFilter *filter;
    CGImageRef temp_image;
    CGImageDestinationRef temp_writer;
    NSMutableData *temp_handler;
    NSBitmapImageRep *temp_rep;
    CGSize size;
    CGRect rect;
    
    unsigned char *resdata;
    IntRect selection;
    BOOL opaque;
    CIColor *backColor;
    
    // Check if image is opaque
    opaque = hasOpaque;
    if (opaque && spp == 4) backColor = [CIColor colorWithRed:[nsBackColor redComponent] green:[nsBackColor greenComponent] blue:[nsBackColor blueComponent]];
    else if (opaque) backColor = [CIColor colorWithRed:[nsBackColor whiteComponent] green:[nsBackColor whiteComponent] blue:[nsBackColor whiteComponent]];
    
    // Find core image context
    context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)colorSpaceRef, kCIContextWorkingColorSpace, (id)colorSpaceRef, kCIContextOutputColorSpace, NULL]];
    
    
    selection = srcRect;
    
    // Create core image with data
    size.width = width;
    size.height = height;
    input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:srcData length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    
    // Run filter
    filter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPerspectiveTransform"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:input forKey:@"inputImage"]; //height -
    [filter setValue:[CIVector vectorWithX:point_tl.x Y:height - point_tl.y] forKey:@"inputTopLeft"];
    [filter setValue:[CIVector vectorWithX:point_tr.x Y:height - point_tr.y] forKey:@"inputTopRight"];
    [filter setValue:[CIVector vectorWithX:point_br.x Y:height - point_br.y] forKey:@"inputBottomRight"];
    [filter setValue:[CIVector vectorWithX:point_bl.x Y:height - point_bl.y] forKey:@"inputBottomLeft"];
    output = [filter valueForKey: @"outputImage"];
    
    NSLog(@"time1 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
    
    
    // Create output core image
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.width = width;
    rect.size.height = height;
    CGRect desrect = output.extent;
    temp_image = [context createCGImage:output fromRect:desrect];
    *newWidth = desrect.size.width;
    *newHeight = desrect.size.height;
    
    
    NSLog(@"time2 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
    // Get data from output core image
    temp_handler = [NSMutableData dataWithLength:0];
    temp_writer = CGImageDestinationCreateWithData((CFMutableDataRef)temp_handler, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(temp_writer, temp_image, NULL);
    CGImageDestinationFinalize(temp_writer);
    temp_rep = [NSBitmapImageRep imageRepWithData:temp_handler];
    resdata = [temp_rep bitmapData];
    
    for (int i = 0; i < vec_len; i++) {
        vstore = _mm_slli_epi32(vdata[i], 24);
        vdata[i] = _mm_srli_epi32(vdata[i], 8);
        vdata[i] = _mm_add_epi32(vdata[i], vstore);
    }
    
    unpremultiplyBitmap(4, resdata, resdata, (*newWidth) * (*newHeight));
    free(newdata);
    NSLog(@"time3 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
    return resdata;
    
}

- (void)initWithSrcData:(unsigned char*)srcData FromRect:(IntRect)srcRect spp:(int)spp opaque:(BOOL)hasOpaque colorSpace:(CGColorSpaceRef)colorSpaceRef backColor:(NSColor *)nsBackColor premultied:(BOOL)premultied
{
    __m128i opaquea = _mm_set1_epi32(0x000000FF);
    __m128i *vdata, *voverlay, *vresdata;
    __m128i vstore;
    int vec_len;
    
    m_fromRect = srcRect;
    int width = srcRect.size.width;
    int height = srcRect.size.height;
    
    unsigned char *newdata = malloc((srcRect.size.width * srcRect.size.height * spp+15)/16*16);
    if (premultied) {
        memcpy(newdata, srcData, srcRect.size.width * srcRect.size.height * spp);
    }else{
        premultiplyBitmap(4, newdata, srcData, srcRect.size.width * srcRect.size.height);
    }
    
    m_srcData = newdata;
    
    vec_len = width * height * 4;
    if (vec_len % 16 == 0) { vec_len /= 16; }
    else { vec_len /= 16; vec_len++; }
    
    vdata = (__m128i *)newdata;
    for (int i = 0; i < vec_len; i++) {
        vstore = _mm_srli_epi32(vdata[i], 24);
        vdata[i] = _mm_slli_epi32(vdata[i], 8);
        vdata[i] = _mm_add_epi32(vdata[i], vstore);
    }
    
    
    CGImageRef temp_image;
    CGImageDestinationRef temp_writer;
    NSMutableData *temp_handler;
    NSBitmapImageRep *temp_rep;
    CGSize size;
    CGRect rect;
    
    unsigned char *resdata;
    IntRect selection;
    BOOL opaque;
    CIColor *backColor;
    
    // Check if image is opaque
    opaque = hasOpaque;
    if (opaque && spp == 4) backColor = [CIColor colorWithRed:[nsBackColor redComponent] green:[nsBackColor greenComponent] blue:[nsBackColor blueComponent]];
    else if (opaque) backColor = [CIColor colorWithRed:[nsBackColor whiteComponent] green:[nsBackColor whiteComponent] blue:[nsBackColor whiteComponent]];
    
    // Find core image context
    m_ciContext = [[CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)colorSpaceRef, kCIContextWorkingColorSpace, (id)colorSpaceRef, kCIContextOutputColorSpace, NULL]] retain];
    
    
    selection = srcRect;
    
    // Create core image with data
    size.width = width;
    size.height = height;
    m_inputciImage = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:m_srcData length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    
    // Run filter
    m_ciFilter = [[CIFilter filterWithName:@"CIPerspectiveTransform"] retain];
    if (m_ciFilter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPerspectiveTransform"] userInfo:NULL];
    }
    [m_ciFilter setDefaults];
    [m_ciFilter setValue:m_inputciImage forKey:@"inputImage"];
}

- (CGLayerRef)makePerspectiveTransformWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl newWidth:(int*)newWidth newHeight:(int*)newHeight newXOff:(int*)newXOff newYOff:(int*)newYOff
{
    [m_ciFilter setValue:[CIVector vectorWithX:point_tl.x Y:m_fromRect.size.height - point_tl.y] forKey:@"inputTopLeft"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_tr.x Y:m_fromRect.size.height - point_tr.y] forKey:@"inputTopRight"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_br.x Y:m_fromRect.size.height - point_br.y] forKey:@"inputBottomRight"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_bl.x Y:m_fromRect.size.height - point_bl.y] forKey:@"inputBottomLeft"];
    CIImage* output = [m_ciFilter valueForKey: @"outputImage"];
    
    CGRect desrect = output.extent;
    CGImageRef resultImageRef = [m_ciContext createCGImage:output fromRect:desrect];
    *newWidth = desrect.size.width;
    *newHeight = desrect.size.height;
    
    CGLayerRef resultLayerRef = NULL;
    CGColorSpaceRef defaultColorSpace = ((m_nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, *newWidth, *newHeight, 8, m_nSpp * *newWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    
    resultLayerRef = CGLayerCreateWithContext(bitmapContext, CGSizeMake(*newWidth, *newHeight), nil);
    assert(resultLayerRef);
    CGContextRelease(bitmapContext);
    
    CGContextRef layerContext= CGLayerGetContext(resultLayerRef);
//    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, m_pAffinePreviewData, *newWidth * (*newHeight) * m_nSpp, NULL);
//    assert(dataProvider);
//    CGImageRef layerImage = CGImageCreate(m_currentAffineLayerRect.size.width, m_currentAffineLayerRect.size.height, 8, 8*m_nSpp, m_currentAffineLayerRect.size.width*m_nSpp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
//    assert(layerImage);
    CGContextClearRect(layerContext, CGRectMake(0, 0, *newWidth, *newHeight));
    CGContextDrawImage(layerContext, CGRectMake(0, 0, *newWidth, *newHeight), resultImageRef);
    
    CGColorSpaceRelease(defaultColorSpace);
    CGImageRelease(resultImageRef);

    return resultLayerRef;
}

- (CGImageRef)makePerspectiveTransformImageRefWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl newWidth:(int*)newWidth newHeight:(int*)newHeight newXOff:(int*)newXOff newYOff:(int*)newYOff
{
    
    [m_ciFilter setValue:[CIVector vectorWithX:point_tl.x Y:m_fromRect.size.height - point_tl.y] forKey:@"inputTopLeft"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_tr.x Y:m_fromRect.size.height - point_tr.y] forKey:@"inputTopRight"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_br.x Y:m_fromRect.size.height - point_br.y] forKey:@"inputBottomRight"];
    [m_ciFilter setValue:[CIVector vectorWithX:point_bl.x Y:m_fromRect.size.height - point_bl.y] forKey:@"inputBottomLeft"];
    
    CIImage* output = [m_ciFilter valueForKey: @"outputImage"];
    
    int miny = point_tl.y;
    miny = MIN(miny, point_tr.y);
    miny = MIN(miny, point_br.y);
    miny = MIN(miny, point_bl.y);
    int minx = point_tl.x;
    minx = MIN(minx, point_tr.x);
    minx = MIN(minx, point_br.x);
    minx = MIN(minx, point_bl.x);
    CGRect desrect = output.extent;
    //desrect.origin.x = minx;
    //desrect.origin.y = miny;
    
    CGImageRef resultImageRef = [m_ciContext createCGImage:output fromRect:desrect];
    //CGImageRef resultImageRef = [m_ciContext createCGImage:output fromRect:desrect format:<#(CIFormat)#> colorSpace:NULL];
    *newWidth = desrect.size.width;
    *newHeight = desrect.size.height;
    *newXOff = (int)desrect.origin.x;
    *newYOff = miny;
    
    return resultImageRef;
    
    
}



/*
 
- (unsigned char*)makePerspectiveTransformWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl OnData:(unsigned char*)srcData FromRect:(IntRect)srcRect spp:(int)spp opaque:(BOOL)hasOpaque newWidth:(int*)newWidth newHeight:(int*)newHeight colorSpace:(CGColorSpaceRef)colorSpaceRef backColor:(NSColor *)nsBackColor
{
    NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    
    __m128i opaquea = _mm_set1_epi32(0x000000FF);
    __m128i *vdata, *voverlay, *vresdata;
    __m128i vstore;
    int vec_len;
    
    int width = srcRect.size.width;
    int height = srcRect.size.height;
    
    unsigned char *newdata = malloc(srcRect.size.height * srcRect.size.height * spp);
    premultiplyBitmap(4, newdata, srcData, srcRect.size.width * srcRect.size.height);
    srcData = newdata;
    
        vec_len = width * height * 4;
        if (vec_len % 16 == 0) { vec_len /= 16; }
        else { vec_len /= 16; vec_len++; }
    
        vdata = (__m128i *)newdata;
        for (int i = 0; i < vec_len; i++) {
            vstore = _mm_srli_epi32(vdata[i], 24);
            vdata[i] = _mm_slli_epi32(vdata[i], 8);
            vdata[i] = _mm_add_epi32(vdata[i], vstore);
        }
    
    CIContext *context;
    CIImage *input, *crop_output, *imm_output, *imm_output_1, *imm_output_2, *output, *background;
    CIFilter *filter;
    CGImageRef temp_image;
    CGImageDestinationRef temp_writer;
    NSMutableData *temp_handler;
    NSBitmapImageRep *temp_rep;
    CGSize size;
    CGRect rect;
    
    unsigned char *resdata;
    IntRect selection;
    BOOL opaque;
    CIColor *backColor;
    
    // Check if image is opaque
    opaque = hasOpaque;
    if (opaque && spp == 4) backColor = [CIColor colorWithRed:[nsBackColor redComponent] green:[nsBackColor greenComponent] blue:[nsBackColor blueComponent]];
    else if (opaque) backColor = [CIColor colorWithRed:[nsBackColor whiteComponent] green:[nsBackColor whiteComponent] blue:[nsBackColor whiteComponent]];
    
    // Find core image context
    context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:[NSDictionary dictionaryWithObjectsAndKeys:(id)colorSpaceRef, kCIContextWorkingColorSpace, (id)colorSpaceRef, kCIContextOutputColorSpace, NULL]];
    
    
    selection = srcRect;
    
    // Create core image with data
    size.width = width;
    size.height = height;
    input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:srcData length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    
    imm_output_2 = input;
    
    // Run filter
    filter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPerspectiveTransform"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:imm_output_2 forKey:@"inputImage"]; //height -
    [filter setValue:[CIVector vectorWithX:point_tl.x Y:height - point_tl.y] forKey:@"inputTopLeft"];
    [filter setValue:[CIVector vectorWithX:point_tr.x Y:height - point_tr.y] forKey:@"inputTopRight"];
    [filter setValue:[CIVector vectorWithX:point_br.x Y:height - point_br.y] forKey:@"inputBottomRight"];
    [filter setValue:[CIVector vectorWithX:point_bl.x Y:height - point_bl.y] forKey:@"inputBottomLeft"];
    imm_output = [filter valueForKey: @"outputImage"];
    
    NSLog(@"time1 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
     //Add opaque background (if required)
    
//    if (opaque) {
//            filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
//            [filter setDefaults];
//            [filter setValue:backColor forKey:@"inputColor"];
//            background = [filter valueForKey: @"outputImage"];
//            filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
//            [filter setDefaults];
//            [filter setValue:background forKey:@"inputBackgroundImage"];
//            [filter setValue:imm_output forKey:@"inputImage"];
//            output = [filter valueForKey:@"outputImage"];
//        }
//        else {
//            output = imm_output;
//        }
    
    output = imm_output;
    
    
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
        CGRect desrect = output.extent;
        temp_image = [context createCGImage:output fromRect:desrect];
        *newWidth = desrect.size.width;
        *newHeight = desrect.size.height;
        
    }
    
    NSLog(@"time2 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
    // Get data from output core image
    temp_handler = [NSMutableData dataWithLength:0];
    temp_writer = CGImageDestinationCreateWithData((CFMutableDataRef)temp_handler, kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(temp_writer, temp_image, NULL);
    CGImageDestinationFinalize(temp_writer);
    temp_rep = [NSBitmapImageRep imageRepWithData:temp_handler];
    resdata = [temp_rep bitmapData];
    
        for (int i = 0; i < vec_len; i++) {
            vstore = _mm_slli_epi32(vdata[i], 24);
            vdata[i] = _mm_srli_epi32(vdata[i], 8);
            vdata[i] = _mm_add_epi32(vdata[i], vstore);
        }
    
    unpremultiplyBitmap(4, resdata, resdata, (*newWidth) * (*newHeight));
    free(newdata);
    NSLog(@"time3 %f", [NSDate timeIntervalSinceReferenceDate] -begin);
    
    return resdata;
    
}

*/
 

@end
