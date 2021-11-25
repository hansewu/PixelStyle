//
//  WaterReflection.m
//  WaterReflection
//
//  Created by lchzh on 1/3/16.
//  Copyright © 2016 lchzh. All rights reserved.
//

#import "WaterReflection.h"
#import "PerlinNoise.h"

@implementation WaterReflection

- (id)initWithManager:(PSPlugins *)manager
{
    self = [super init];
    
    seaPlugins = manager;
    [NSBundle loadNibNamed:@"WaterReflection" owner:self];
    
    return self;

}


- (int)type
{
    return kSpecialEffectPlugin;
}
- (NSString *)name
{
    return @"Water Reflection";
}
- (NSString *)groupName
{
    return @"Special Effect";
}
- (NSString *)sanity
{
    return @"PixelStyle Approved (Bobo)";
}


- (void)run
{
    PluginData *pluginData;
    pluginData = [(PSPlugins *)seaPlugins data];
    unsigned char* srcData = [pluginData data];
    int width = [pluginData width];
    int height = [pluginData height];
    int spp = [pluginData spp];
    if (m_desData) {
        free(m_desData);
        m_desData = NULL;
    }
    m_desData = malloc(width * height * spp * 2);
    memcpy(m_desData, srcData, width * height * spp);
    
    for (int j = 0; j < height; j++)
    {
        memcpy(m_desData + (2 * height - j - 1) * width * spp, srcData + j * width * spp, width * spp);
    }
    [self processData];
    
    [NSApp runModalForWindow:panel];

}

- (void)processData
{
    PluginData *pluginData;
    pluginData = [(PSPlugins *)seaPlugins data];
    unsigned char* srcData = [pluginData data];
    int width = [pluginData width];
    int height = [pluginData height];
    int spp = [pluginData spp];
    
    int seed = 20;
    PerlinNoise *plNoise = [[PerlinNoise alloc] initWithSeed:seed];
    for (int j = height; j < height * 2; j++) {
        for (int i = 0; i < width; i++) {
            int value = [plNoise perlin2DValueForPoint:i :j] - seed / 2;
            int si = i + value;
            int sj = height * 2 - 1 - j + value;
            if (si >= 0 && si <= width && sj >= 0 && sj <= height)
            {
                memcpy(m_desData + (j * width + i) * spp, srcData + (sj * width + si) * spp, spp);
            }else{
                si = i;
                sj = height * 2 - 1 - j;
                memcpy(m_desData + (j * width + i) * spp, srcData + (sj * width + si) * spp, spp);
            }
        }
    }
    
    CGImageRef imageRef = [self makeImageRefFromData:m_desData width:width height:height * 2 spp:spp alphaPremultiplied:NO];
    [self savePNGImage:imageRef path:@"/Users/lchzh/Desktop/Untitled-12.png"];
}

- (void)savePNGImage:(CGImageRef)imageRef path:(NSString *)path
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    CGImageDestinationRef dr = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypePNG , 1, NULL);
    
    CGImageDestinationAddImage(dr, imageRef, NULL);
    CGImageDestinationFinalize(dr);
    
    CFRelease(dr);
}

- (CGImageRef)makeImageRefFromData:(unsigned char*)data width:(int)width height:(int)height spp:(int)spp alphaPremultiplied:(int) bAlphaPremultiplied
{
    if (width <= 0.5 || height <= 0.5 || spp <= 0.5) {
        return NULL;
    }
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, width * height * spp, NULL);
    assert(dataProvider);
    
    CGImageRef cgImage;
    if(bAlphaPremultiplied)
        cgImage = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    else
        cgImage = CGImageCreate(width, height, 8, 8 * spp, width * spp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    assert(cgImage);
    
    CGColorSpaceRelease(defaultColorSpace);
    CGDataProviderRelease(dataProvider);
    
    return cgImage;
}


- (void)reapply
{
    
}

- (BOOL)canReapply
{
    return NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    return YES;
}

- (IBAction)apply:(id)sender
{
    [NSApp stopModal];
    [NSApp endSheet:panel];
    [panel orderOut:self];
}
- (IBAction)cancel:(id)sender
{
    [NSApp stopModal];
    [NSApp endSheet:panel];
    [panel orderOut:self];
}

@end
