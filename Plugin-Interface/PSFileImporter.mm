//
//  PSFileImporter.cpp
//  PixelStyle
//
//  Created by lchzh on 6/6/17.
//
//

#include "PSFileImporter.h"
#include "PluginCommon.h"

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

#import "CocoaImporter.h"
#import "CocoaLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSView.h"
#import "CenteringClipView.h"
#import "PSOperations.h"
#import "PSAlignment.h"
#import "PSController.h"
#import "PSWarning.h"



#pragma mark host callback for plugin

int getPluginPath(char* path)
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pluginPath = [bundle.builtInPlugInsPath stringByAppendingPathComponent:@"/Importer"];
    
    strcpy(path, [pluginPath UTF8String]);
    return 0;
}

int getCachePath(char* path)
{
    NSString *applcationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *CacheDir = [NSString stringWithFormat:@"%@/%@", applcationSupport, bundleIdentifier];
    CacheDir = [CacheDir stringByAppendingPathComponent:@"CachePath"];
    strcpy(path, [CacheDir UTF8String]);
    return 0;
}

int freeImageBuffer(GM_IMAGE_BUFFER* imageBuffer)
{
    if (imageBuffer->pBuffer) {
        free(imageBuffer->pBuffer);
    }
    if (imageBuffer) {
        free(imageBuffer);
    }
    return 0;
}

GM_IMAGE_BUFFER* mallocImageBuffer(int nImageWidth, int nImageHeight, int nChannel)
{
    GM_IMAGE_BUFFER *imageBuffer = (GM_IMAGE_BUFFER *)malloc(sizeof(GM_IMAGE_BUFFER));
    imageBuffer->nWidth = nImageWidth;
    imageBuffer->nHeight = nImageHeight;
    imageBuffer->nChannel = nChannel;
    imageBuffer->pBuffer = (unsigned char*)malloc(nImageWidth * nImageHeight * nChannel);
    return imageBuffer;
}

PS_AcquireParaInfo *mallocAndInitAcquireParaInfo(const char* pluginPath)
{
    PS_AcquireParaInfo *acquireParam = new PS_AcquireParaInfo;
    acquireParam->hostProcs = new PS_HostProcs;
    acquireParam->hostProcs->mallocBufferProc = mallocImageBuffer;
    acquireParam->hostProcs->freeBufferProc = freeImageBuffer;
    acquireParam->hostProcs->getPluginPathProc = getPluginPath;
    acquireParam->hostProcs->getCachePathProc = getCachePath;
    
    acquireParam->importerProcs = new PS_ImporterProcs;
    acquireParam->exporterProcs = new PS_ExporterProcs;
    
    strcpy(acquireParam->pluginPath, pluginPath);
    
    return acquireParam;
}

void freeAcquirParaInfo(PS_AcquireParaInfo *acquireParam)
{
    if (acquireParam->hostProcs) {
        delete acquireParam->hostProcs;
    }
    if (acquireParam->importerProcs) {
        delete acquireParam->importerProcs;
    }
    if (acquireParam->exporterProcs) {
        delete acquireParam->exporterProcs;
    }
    if (acquireParam) {
        delete acquireParam;
    }
}

#pragma mark- main interface for importer


static CGImageRef makeImageRefFromData(unsigned char*data, int width, int height, int spp,  int bAlphaPremultiplied)
{
    if (width <= 0.5 || height <= 0.5 || spp <= 0.5)
    {
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


int createCocoaLayerWithBuffer(GM_IMAGE_BUFFER *bufferInfo, void* document, const char*layerName)
{
    id doc = (id)document;
    CGImageRef imageRef = makeImageRefFromData(bufferInfo->pBuffer, bufferInfo->nWidth, bufferInfo->nHeight, bufferInfo->nChannel, 0);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(bufferInfo->nWidth, bufferInfo->nHeight)];
    
    id imageRep;
    id layer;
    
    // Form a bitmap representation of the file at the specified path
    imageRep = NULL;
    if ([[image representations] count] > 0) {
        imageRep = [[image representations] objectAtIndex:0];
        if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
        }
    }
    if (imageRep == NULL) {
        [image autorelease];
        return -1;
    }
    
    // Warn if 16-bit image
    if ([imageRep bitsPerSample] == 16) {
        [[PSController seaWarning] addMessage:LOCALSTR(@"16-bit message", @"PixelStyle does not support the editing of 16-bit images. This image has been resampled at 8-bits to be imported.") forDocument: doc level:kHighImportance];
    }
    
    // Create the layer
    layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
    if (layer == NULL) {
        [image autorelease];
        return -1;
    }
    
    // Rename the layer
    [(PSLayer *)layer setName:[NSString stringWithUTF8String:layerName]];
    
    // Add the layer
    [[doc contents] addLayerObject:layer];
    
    // Now forget the NSImage
    [image autorelease];
    
    // Position the new layer correctly
    //[[(PSOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
    //[[(PSOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
    
    IntPoint offset = {([(PSContent*)[doc contents] width] - [(PSLayer *)layer width]) / 2, ([(PSContent*)[doc contents] height] - [(PSLayer *)layer height]) / 2};
    [layer setOffsets:offset];
    
    return 0;
}

int plugin_ImportImageToDocument(const char* filePath, void* document)
{
    NSBundle *main = [NSBundle mainBundle];
    NSArray *allPlugins = [main pathsForResourcesOfType:@"plugin" inDirectory:@"../PlugIns/Importer"];

    int status = -1;
    for (NSString *path in allPlugins)
    {
        CFURLRef bundleURL;
        CFBundleRef myBundle;
        CFStringRef bundlePath = (__bridge CFStringRef)path;
        bundleURL = CFURLCreateWithFileSystemPath(
                                                  kCFAllocatorDefault,
                                                  bundlePath,
                                                  kCFURLPOSIXPathStyle,
                                                  true );
        
        // Make a bundle instance using the URLRef.
        myBundle = CFBundleCreate( kCFAllocatorDefault, bundleURL );
        CFRelease( bundleURL );
        Boolean success = CFBundleLoadExecutable(myBundle);
        if (success == false) {
            printf("CFBundleLoadExecutable fail");
        }else{
            printf("CFBundleLoadExecutable success");
        }
        
        CFStringRef functionName = CFSTR("PS_PluginMain");
        PluginMainEntryPro pluginMainPointer = (PluginMainEntryPro)CFBundleGetFunctionPointerForName(myBundle, functionName);
        if (pluginMainPointer != NULL) {
            PS_AcquireParaInfo *acquireParam = mallocAndInitAcquireParaInfo([[path stringByDeletingLastPathComponent] UTF8String]);
            
            int result = 0;
            pluginMainPointer(PS_SelectorType_Prepare, acquireParam, &result);
            NSString *stringPath = [NSString stringWithUTF8String:filePath];
            NSString *stringName = [[stringPath lastPathComponent] stringByDeletingPathExtension];
            NSString *stringExtension = [[stringPath lastPathComponent] pathExtension];
            bool support = acquireParam->importerProcs->isSupportProc([stringExtension UTF8String]);
            if (support) {
                char nonConstFilePath[512] = "";
                strcpy(nonConstFilePath, filePath);
                GM_IMAGE_BUFFER *bufferInfo = acquireParam->importerProcs->getBufferProc(nonConstFilePath);
                if (bufferInfo != NULL) {
                    status = createCocoaLayerWithBuffer(bufferInfo, document, [stringName UTF8String]);
                    freeImageBuffer(bufferInfo);;
                }else{
                    
                }
            }
            pluginMainPointer(PS_SelectorType_Finish, acquireParam, &result);
            freeAcquirParaInfo(acquireParam);
        }
        CFBundleUnloadExecutable(myBundle);
        CFRelease( myBundle );

    }
    
    return status;
}

char** plugin_GetAllSupportedTypes(int* count)
{
    printf("plugin_GetAllSupportedTypes");
    int typeMaxCount = 200; //max 200
    char **typesTemp = (char**)malloc(sizeof(char*) * typeMaxCount);
    int indexType = 0;
    
    NSBundle *main = [NSBundle mainBundle];
    NSArray *allPlugins = [main pathsForResourcesOfType:@"plugin" inDirectory:@"../PlugIns/Importer"];
    
    for (NSString *path in allPlugins)
    {
        CFURLRef bundleURL;
        CFBundleRef myBundle;
        CFStringRef bundlePath = (__bridge CFStringRef)path;
        
        bundleURL = CFURLCreateWithFileSystemPath(
                                                  kCFAllocatorDefault,
                                                  bundlePath,
                                                  kCFURLPOSIXPathStyle,
                                                  true );
        
        // Make a bundle instance using the URLRef.
        myBundle = CFBundleCreate( kCFAllocatorDefault, bundleURL );
        CFRelease( bundleURL );
        Boolean success = CFBundleLoadExecutable(myBundle);
//        Boolean isloaded = CFBundleIsExecutableLoaded(myBundle);
        if (success == false) {
            printf("CFBundleLoadExecutable fail");
        }else{
            printf("CFBundleLoadExecutable success");
        }
        
        
        CFStringRef functionName = CFSTR("PS_PluginMain");
        PluginMainEntryPro pluginMainPointer = (PluginMainEntryPro)CFBundleGetFunctionPointerForName(myBundle, functionName);
        
        if (pluginMainPointer != NULL) {
            PS_AcquireParaInfo *acquireParam = mallocAndInitAcquireParaInfo([[path stringByDeletingLastPathComponent] UTF8String]);
            int result = 0;
            pluginMainPointer(PS_SelectorType_Prepare, acquireParam, &result);
            int count = 0;
            GM_FORMAT_INFO **formatInfo = acquireParam->importerProcs->getSupportProc(&count);
            for (int i = 0; i < count; i++) {
                typesTemp[indexType] = (char*)malloc(sizeof(char) * 512);
                strcpy(typesTemp[indexType], formatInfo[i]->name);
                indexType++;
//                printf(formatInfo[i]->name);
//                printf("%d%d", formatInfo[i]->readable, formatInfo[i]->writeable);
//                printf("\n");
            }
            if (count > 0 && formatInfo != NULL) {
                for (int i = 0; i < count; i++) {
                    free(formatInfo[i]);
                }
                free(formatInfo);
            }
            pluginMainPointer(PS_SelectorType_Finish, acquireParam, &result);
            freeAcquirParaInfo(acquireParam);
        }
        
        CFBundleUnloadExecutable(myBundle);
        CFRelease( myBundle );
    }

    *count = indexType;
    char **types = (char**)malloc(sizeof(char*) * indexType);
    memcpy(types, typesTemp, sizeof(char*) * indexType);
    free(typesTemp);
    return types;
}

#pragma mark- main interface for exporter

GM_IMAGE_BUFFER* getImageBufferInfo(PSDocument* document)
{
    float fScreenScale = [[NSScreen mainScreen] backingScaleFactor];
    int nWidth = [(PSContent *)[document contents] width];
    int nHeight = [(PSContent *)[document contents] height];
    NSSize imageSize = NSMakeSize(nWidth/fScreenScale, nHeight/fScreenScale);
    
    int spp = 4;
    GM_IMAGE_BUFFER* bufferinfo = mallocImageBuffer(nWidth, nHeight, 4);
    unsigned char* data = bufferinfo->pBuffer;
    //画到NSImage
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(data, nWidth, nHeight, 8, spp * nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    
    [[[document whiteboard] compositor] compositeLayersToContextFull:bitmapContext];
    
    unsigned char temp[spp * nWidth];
    int j;
    
    for (j = 0; j < nHeight / 2; j++)
    {
        memcpy(temp, data + (j * nWidth) * spp, spp * nWidth);
        memcpy(data + (j * nWidth) * spp, data + ((nHeight - j - 1) * nWidth) * spp, spp * nWidth);
        memcpy(data + ((nHeight - j - 1) * nWidth) * spp, temp, spp * nWidth);
    }
    
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);
    
    return bufferinfo;
    
}

typedef struct CALL_PARAMETERS
{
    const char* filePath;
    void* document;
    int status;
    
}CALL_PARAMETERS;

//此函数要放到线程里面出来，不可以在主线程，容易引起阻塞崩溃，待处理
int plugin_ExportBufferToFile(const char* filePath, void* document)
{
    GM_IMAGE_BUFFER* bufferinfo = getImageBufferInfo((PSDocument*)document);
    
    NSBundle *main = [NSBundle mainBundle];
    NSArray *allPlugins = [main pathsForResourcesOfType:@"plugin" inDirectory:@"../PlugIns/Exporter"];
    
    int status = -1;
    for (NSString *path in allPlugins)
    {
        CFURLRef bundleURL;
        CFBundleRef myBundle;
        CFStringRef bundlePath = (__bridge CFStringRef)path;
        
        bundleURL = CFURLCreateWithFileSystemPath(
                                                  kCFAllocatorDefault,
                                                  bundlePath,
                                                  kCFURLPOSIXPathStyle,
                                                  true );
        
        // Make a bundle instance using the URLRef.
        myBundle = CFBundleCreate( kCFAllocatorDefault, bundleURL );
        CFRelease( bundleURL );
        Boolean success = CFBundleLoadExecutable(myBundle);
        if (success == false) {
            printf("CFBundleLoadExecutable fail");
        }else{
            printf("CFBundleLoadExecutable success");
        }
        
        CFStringRef functionName = CFSTR("PS_PluginMain");
        PluginMainEntryPro pluginMainPointer = (PluginMainEntryPro)CFBundleGetFunctionPointerForName(myBundle, functionName);
        if (pluginMainPointer != NULL) {
            PS_AcquireParaInfo *acquireParam = mallocAndInitAcquireParaInfo([[path stringByDeletingLastPathComponent] UTF8String]);
            int result = 0;
            
            pluginMainPointer(PS_SelectorType_Prepare, acquireParam, &result);
            NSString *stringPath = [NSString stringWithUTF8String:filePath];
            NSString *stringName = [[stringPath lastPathComponent] stringByDeletingPathExtension];
            NSString *stringExtension = [[stringPath lastPathComponent] pathExtension];
            bool support = acquireParam->exporterProcs->isSupportProc([stringExtension UTF8String]);
            if (support) {
                char nonConstFilePath[512] = "";
                strcpy(nonConstFilePath, filePath);
                status = acquireParam->exporterProcs->writeBufferProc(bufferinfo, nonConstFilePath);
            }else{
                
            }
            pluginMainPointer(PS_SelectorType_Finish, acquireParam, &result);
            freeAcquirParaInfo(acquireParam);
            
        }
        CFBundleUnloadExecutable(myBundle);
        CFRelease( myBundle );
        
        if (status == 0) {
            freeImageBuffer(bufferinfo);
            return 0;
        }
        
    }
    freeImageBuffer(bufferinfo);
    return -1;

}

char** plugin_exporter_GetAllSupportedTypes(int* count)
{
    NSBundle *main = [NSBundle mainBundle];
    NSArray *allPlugins = [main pathsForResourcesOfType:@"plugin" inDirectory:@"../PlugIns/Exporter"];
    if ([allPlugins count] <= 0) {
        *count = 0;
        return nil;
    }
    *count = 5;
    char **types = (char**)malloc(sizeof(char*) * (*count));
    for (int i = 0; i < *count; i++) {
        types[i] = (char*)malloc(sizeof(char) * 512);
    }
    
    strcpy(types[0], "tga");
    strcpy(types[1], "psd");
    strcpy(types[2], "webp");
    strcpy(types[3], "pcx");
    strcpy(types[4], "eps");
    
    return types;
}
