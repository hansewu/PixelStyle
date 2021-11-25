//
//  FilterGallery.m
//  FilterGallery
//
//  Created by Calvin on 3/9/17.
//  Copyright © 2017 Calvin. All rights reserved.
//

#import "FilterGallery.h"
#import "WindowTitleView.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define make_128(x) (x + 16 - (x % 16))

@implementation FilterGallery

- (id)initWithManager:(PSPlugins *)manager
{
    if(self = [super init]){
        seaPlugins = manager;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickConfirmBtn:) name:@"confirm" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeWindow) name:@"closeWindow" object:nil];
        [NSBundle loadNibNamed:@"filter" owner:self];
        newdata = NULL;
    }
    return self;
}

- (int)type
{
    return 0;
}

- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"FilterGallery" table:NULL];
}

- (NSString *)groupName
{
    return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)instruction
{
    return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
    return @"PixelStyle Approved (Bobo)";
}

-(NSImage*)getInputImage
{
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    unsigned char* buffer       = [pluginData data];
    NSImage* image              = [[self convertBufferToNSImage:buffer nWidth:[pluginData width] nHeight:[pluginData height]] retain];
    return image;
}

- (void)run
{
    PluginData *pluginData;
    
    pluginData = [(PSPlugins *)seaPlugins data];
    unsigned char* buffer = [pluginData data];
    NSImage* image = [self convertBufferToNSImage:buffer nWidth:[pluginData width] nHeight:[pluginData height]];
    [NSBundle loadNibNamed:@"filter" owner:self];
    
    NSRect boundsRect = [[[m_window contentView] superview] bounds];
    WindowTitleView * titleview = [[WindowTitleView alloc] initWithFrame:boundsRect];
    [titleview setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[[m_window contentView] superview] addSubview:titleview positioned:NSWindowBelow relativeTo:[[[[m_window contentView] superview] subviews] objectAtIndex:0]];
    
    [m_window setInputImage:image];
    [m_window start];
    m_window.releasedWhenClosed = YES;
    [NSApp runModalForWindow:m_window];
    
    newdata = (unsigned char  *)malloc(make_128([pluginData width] * [pluginData height] * 4));

    if (newdata) { free(newdata); newdata = NULL; }
    success = YES;

}

-(NSImage *)convertBufferToNSImage:(unsigned char *)pBuffer nWidth:(int)width nHeight:(int)height
{
    unsigned char* pBufferNew           = (unsigned char*)malloc(width*height*4);
    memset(pBufferNew,0,width*height*4);
    memcpy(pBufferNew,pBuffer,width*height*4);
    for(int i = 0;i < height;i++)
    {
        for(int j = 0;j < width; j++)
        {
            pBufferNew[i*width*4+j*4]   *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+1] *= pBufferNew[i*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+2] *= pBufferNew[i*width*4+4*j+3]/255.0;
        }
    }
    CGColorSpaceRef colorSpace      = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext      = CGBitmapContextCreate(pBufferNew,width,height,8,width*4,colorSpace,kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef             = CGBitmapContextCreateImage(bitmapContext);
    NSImage* image                  = [[[NSImage alloc]initWithCGImage:imageRef size:NSMakeSize(width,height)]autorelease];
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    free(pBufferNew);
    pBufferNew = nil;
    
    return image;
}

- (void)reapply
{
    [self run];
}

- (BOOL)canReapply
{
    return success;
}


- (BOOL)validateMenuItem:(id)menuItem
{
    return YES;
}

-(void)clickConfirmBtn:(NSNotification*)notification
{
    PluginData* pPluginData          = [(PSPlugins*)seaPlugins data];
    NSImage* effectImage = [notification object];
    
    CGImageRef cgImage = [effectImage CGImageForProposedRect:nil context:nil hints:nil];
    int nWidth = (int)CGImageGetWidth(cgImage);
    int nHeight = (int)CGImageGetHeight(cgImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate( NULL, nWidth, nHeight, 8, nWidth * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, nWidth, nHeight), cgImage);
    unsigned char* imagePointer = (unsigned char*)CGBitmapContextGetData(ctx);
    
    [self replaceBuffer:imagePointer];
    CGColorSpaceRelease(colorSpace);
    [pPluginData setOverlayOpacity:255];
    [pPluginData setOverlayBehaviour:kReplacingBehaviour];
    [pPluginData apply];
    [self closeWindow];
}

-(void)replaceBuffer:(unsigned char*)memeory
{
    PluginData* pPluginData = [(PSPlugins*)seaPlugins data];
    int nWidth               = [pPluginData width];
    int nHeight              = [pPluginData height];
    unsigned char* overlay   = [pPluginData overlay];
    memset(overlay, 0, nWidth * nHeight *4);
    for(int i = 0; i < nHeight; i++)
    {
        memcpy(overlay, memeory, nWidth * 4);
        overlay += nWidth * 4;
        memeory += nWidth * 4;
    }
}

-(void)closeWindow
{
    [NSApp stopModal];
    [NSApp endSheet:m_window];
    [m_window close];
    success = YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end
