#import "PSAbstractLayer.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSLayerUndo.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "Bitmap.h"
#import "PSWarning.h"
#import "PSPrefs.h"
#import "PSPlugins.h"
#import "CIAffineTransformClass.h"
#import <ApplicationServices/ApplicationServices.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <GIMPCore/GIMPCore.h>


#import "PSLayerEffect.h"
#import "NSData+Additions.h"
#import "PSMemoryManager.h"
#import "PSSelection.h"
#import "StandardMerge.h"
#import "PSAffinePerspectiveTransform.h"
#import "PSWhiteboard.h"

#import "PSLayerWithEffectRender.h"
#import "PSSmartFilterManager.h"

#import "NSData+SecureCompress.h"

//No define in ColorSyncDeprecated.h
/* Standard type for ColorSync and other system error codes */
typedef OSStatus                        CMError DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultDevice(
  CMDeviceClass   deviceClass,
  CMDeviceID *    deviceID)                                   DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDeviceDefaultProfileID(
  CMDeviceClass        deviceClass,
  CMDeviceID           deviceID,
  CMDeviceProfileID *  defaultProfID)                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDeviceProfile(
  CMDeviceClass        deviceClass,
  CMDeviceID           deviceID,
  CMDeviceProfileID    profileID,
  CMProfileLocation *  profileLoc)                            DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMOpenProfile(
  CMProfileRef *             prof,
  const CMProfileLocation *  theProfile)                      DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultProfileBySpace(
  OSType          dataColorSpace,
  CMProfileRef *  prof)                                       DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
NCWNewColorWorld(
  CMWorldRef *   cw,
  CMProfileRef   src,
  CMProfileRef   dst)                                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CWMatchBitmap(
  CMWorldRef            cw,
  CMBitmap *            bitmap,
  CMBitmapCallBackUPP   progressProc,
  void *                refCon,
  CMBitmap *            matchedBitmap)                        DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN void
CWDisposeColorWorld(CMWorldRef cw)                            DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMCloseProfile(CMProfileRef prof)                             DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CMGetDefaultProfileBySpace(
  OSType          dataColorSpace,
  CMProfileRef *  prof)                                       DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;

CSEXTERN CMError
CWMatchColors(
  CMWorldRef   cw,
  CMColor *    myColors,
  size_t       count)                                         DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER;


extern IntPoint gScreenResolution;


@implementation PSLayer

- (PSRenderEffect *)getRender
{
    if(!m_pLayerRender)
    {
        RENDER_INFO renderInfo;
        renderInfo.dataImage = nil;
        renderInfo.pointImageDataOffset = CGPointMake(0, 0);
        renderInfo.rectSliceInCanvas     = CGRectNull;
        renderInfo.sizeScale            = CGSizeZero;

        m_pLayerRender = [[PSRenderEffect alloc] initWithRenderInfo:renderInfo];
        [m_pLayerRender setSmartFilterManager:m_pSmartFilterManager];
        [m_pLayerRender setDelegateRenderNotify:self];
    }
    
    return m_pLayerRender;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:[NSNumber numberWithInt:m_nSpp] forKey:@"spp"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nMode] forKey:@"blendMode"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bHasAlpha] forKey:@"hasAlpha"];
    
    if(m_pImageData)
    {
        
        if (m_enumLayerFormat == PS_RASTER_LAYER) { //YES ||
            IMAGE_DATA ImageData = [m_pImageData lockDataForRead];
            NSData *layerData = [NSData dataWithBytes:ImageData.pBuffer length:ImageData.nWidth * ImageData.nHeight * ImageData.nSpp];
            assert(layerData);
            [m_pImageData unLockDataForRead];
            //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
            [aCoder encodeObject:[layerData compress] forKey:@"data"];
            //NSLog(@"timeendoce1 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
            
        }
        
        IMAGE_DATA ImageData = [m_pImageData lockDataForRead];
        [aCoder encodeObject:[NSNumber numberWithBool:ImageData.bAlphaPremultiplied] forKey:@"alphaPremultiplied"];
        [m_pImageData unLockDataForRead];
        
        
        
    }
    
    [aCoder encodeObject:m_pSmartFilterManager forKey:@"PSSmartFilterManager"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    
    //    m_nVersionMajor = [aDecoder decodeObjectForKey:@"versionMajor"];
    //    nVersionMinor = [aDecoder decodeObjectForKey:@"versionMinor"];
    
    if(m_nVersionMajor == 1 && m_nVersionMinor == 0)
    {
        m_nSpp = [[aDecoder decodeObjectForKey:@"spp"] intValue];
        m_nMode = [[aDecoder decodeObjectForKey:@"blendMode"] intValue];
        //m_maLayerFilters = [aDecoder decodeObjectForKey:@"filters"];
        m_bHasAlpha = [[aDecoder decodeObjectForKey:@"hasAlpha"] boolValue];
        
        bool bAlphaPremultiplied = false;
        if ([aDecoder containsValueForKey:@"alphaPremultiplied"])
            bAlphaPremultiplied = [[aDecoder decodeObjectForKey:@"alphaPremultiplied"] boolValue];
        
        if(!m_pImageData)
            m_pImageData = [[PSSecureImageData alloc] initData:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:bAlphaPremultiplied];
        
        NSData *data = [aDecoder decodeObjectForKey:@"data"];
        if(data)
        {
            IMAGE_DATA ImageData = [m_pImageData lockDataForWrite];
            memcpy(ImageData.pBuffer,(unsigned char *)[[data decompress] bytes],m_nWidth * m_nHeight * m_nSpp);
            [m_pImageData unLockDataForWrite];
        }
        
        m_pSmartFilterManager = [aDecoder decodeObjectForKey:@"PSSmartFilterManager"];
    }
    else if(m_nVersionMajor > 1 || (m_nVersionMajor == 1 && m_nVersionMinor > 0))//大于当前应用程序支持版本，查找当前版本应用的变量，若获取到，就赋值，获取不到就不赋值
    {
        return NULL;
    }
    else //小于当前应用程序支持版本，查找当前版本应用的变量，若获取到，就赋值，获取不到就赋初值
    {
        // Set the data members to reasonable values
        m_enumLayerFormat = PS_RASTER_LAYER;
        m_nMode = 0;
        m_nSpp = 4;
        //  m_pData = NULL;
        m_bHasAlpha = YES;
        
        if([aDecoder decodeObjectForKey:@"spp"])
            m_nSpp = [[aDecoder decodeObjectForKey:@"spp"] intValue];
        if([aDecoder decodeObjectForKey:@"blendMode"])
            m_nMode = [[aDecoder decodeObjectForKey:@"blendMode"] intValue];
        //m_maLayerFilters = [aDecoder decodeObjectForKey:@"filters"];
        
        if([aDecoder decodeObjectForKey:@"hasAlpha"])
            m_bHasAlpha = [[aDecoder decodeObjectForKey:@"hasAlpha"] boolValue];
        bool bAlphaPremultiplied = false;
        if ([aDecoder containsValueForKey:@"alphaPremultiplied"])
            bAlphaPremultiplied = [[aDecoder decodeObjectForKey:@"alphaPremultiplied"] boolValue];
        
        if([aDecoder decodeObjectForKey:@"data"])
        {
            NSData *data = [aDecoder decodeObjectForKey:@"data"];
            if(data)
            {
                if(!m_pImageData)
                    m_pImageData = [[PSSecureImageData alloc] initData:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:bAlphaPremultiplied];
                
                IMAGE_DATA ImageData = [m_pImageData lockDataForWrite];
                memcpy(ImageData.pBuffer,(unsigned char *)[[data decompress] bytes],m_nWidth * m_nHeight * m_nSpp);
                [m_pImageData unLockDataForWrite];
            }
        }
    }
    
    return self;
}

- (id)initWithDocumentAfterCoder:(id)doc layer:(PSLayer*)endocerLayer
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    // Synchronize properties
    //    if ([endocerLayer versionMajor] == 1 && [endocerLayer versionMinor] == 0)
    //    {
    m_nWidth = [endocerLayer width];
    m_nHeight = [endocerLayer height];
    m_nMode = [endocerLayer mode];
    m_nSpp = [endocerLayer spp];
    
    if (m_pSmartFilterManager)
    {
        [m_pSmartFilterManager release];
    }
    m_pSmartFilterManager = [[endocerLayer getSmartFilterManager] customCopy];
    [m_pSmartFilterManager setDelegateForManager:self];
    
    if (m_pLayerRender)
    {
        [m_pLayerRender release];
        m_pLayerRender = nil;
    }
    
    [self getRender];
    
    if([endocerLayer getRawData])
    {
        if(!m_pImageData)
            m_pImageData = [[PSSecureImageData alloc] initData:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:[endocerLayer alphaPremultiplied]];
        
        IMAGE_DATA ImageData = [m_pImageData lockDataForWrite];
        memcpy(ImageData.pBuffer, [endocerLayer getRawData], m_nWidth * m_nHeight * m_nSpp);
        [m_pImageData unLockDataForWrite];
        [endocerLayer unLockRawData];
        
        
        
    }
    
    m_nXoff = [endocerLayer xoff];
    m_nYoff = [endocerLayer yoff];
    m_bVisible = [endocerLayer visible];
    m_bLockd = [endocerLayer locked];
    m_bLinked = [endocerLayer linked];
    m_bFloating = [endocerLayer floating];
    m_nOpacity = [endocerLayer opacity];
    
    if([endocerLayer name])
    {
        [m_strName autorelease];
        m_strName = [NSString stringWithString:[endocerLayer name]];
        [m_strName retain];
    }
    
    m_bHasAlpha = YES;

    if([self isEmpty] == NO)
        [self refreshTotalToRender];
    
    return self;
}

- (IMAGE_DATA)initImageAndLockWrite:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied
{
    if(!m_pImageData)
        m_pImageData = [[PSSecureImageData alloc] initData:nWidth height:nHeight spp:nSpp alphaPremultiplied:bAlphaPremultiplied];
    
    IMAGE_DATA ImageData = [m_pImageData lockDataForWrite];
    
    if(ImageData.nWidth != nWidth || ImageData.nHeight != nHeight || ImageData.nSpp != nSpp)
    {
        m_nWidth = nWidth;
        m_nHeight = nHeight;
        m_nSpp      = nSpp;
        [m_pImageData unLockDataForWrite];
        [m_pImageData reInitData:nWidth height:nHeight spp:nSpp alphaPremultiplied:bAlphaPremultiplied];
        ImageData = [m_pImageData lockDataForWrite];
    }
    
    return ImageData;
}

- (id)initWithDocument:(id)doc
{
    // Set the data members to reasonable values
    m_enumLayerFormat = PS_RASTER_LAYER;
    m_nHeight = m_nWidth = m_nMode = 0;
    m_nOpacity = 255;
    m_nXoff = m_nYoff = 0;
    m_nSpp = 4;
    m_bVisible = YES;
    m_pImageData = nil;
    m_bHasAlpha = YES;
    m_pLostprops = NULL;
    m_nLostpropsLen = 0;
    m_bCompressed = NO;
    m_idDocument = doc;
    m_imgThumbnail = NULL;
    m_pThumbData = NULL;
    m_bFloating = NO;
    m_idPSLayerUndo = [[PSLayerUndo alloc] initWithDocument:doc forLayer:self];
    m_nUniqueLayerID = [(PSDocument *)doc uniqueLayerID];
    
    if (m_nUniqueLayerID == 0)
        m_strName = [[NSString alloc] initWithString:LOCALSTR(@"background layer", @"Background")];
    else
        m_strName = [[NSString alloc] initWithFormat:LOCALSTR(@"layer title", @"Layer %d"), m_nUniqueLayerID];
    
    m_arrOldNames = [[NSArray alloc] init];
    
    m_strUndoFilePath = [[NSString alloc] initWithFormat:@"%@/psundo-d%d-l%d", [self getUndoSavePath], [m_idDocument uniqueDocID], [self uniqueLayerID]];
    m_idAffinePlugin = [[PSController seaPlugins] affinePlugin];
    
    m_pImageData = nil;
    
  
    if (m_pSmartFilterManager == nil)
    {
        m_pSmartFilterManager = [[PSSmartFilterManager alloc] init];
        [m_pSmartFilterManager setDelegateForManager:self];
        [m_pSmartFilterManager addNewSmartFilter:@"Effect"];
        [m_pSmartFilterManager addNewSmartFilter:@"Channel"];
    }
    
    [self getRender];

    return self;
}

-  (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    m_enumLayerFormat = PS_RASTER_LAYER;
    // Extract appropriate values of master
    m_nWidth = lwidth; m_nHeight = lheight;
    
    // Get the appropriate samples per pixel
    m_nSpp = lspp;
    
    // Remember the alpha situation
    m_bHasAlpha = !opaque;
    
    // Create a representation in memory of the blank canvas
    IMAGE_DATA ImageData = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    if (opaque)
        memset(ImageData.pBuffer, 255, m_nWidth * m_nHeight * m_nSpp);
    else
        memset(ImageData.pBuffer, 0, m_nWidth * m_nHeight * m_nSpp);
    
    [m_pImageData unLockDataForWrite];
    
    //[m_idDocument docView] 为空
    [self performSelector:@selector(refreshTotalToRender) withObject:NULL afterDelay:0.1];
    //[self refreshTotalToRender];
    
    return self;
}

- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    m_enumLayerFormat = PS_RASTER_LAYER;
    // Derive the width and height from the imageRep
    m_nXoff = lrect.origin.x; m_nYoff = lrect.origin.y;
    m_nWidth = lrect.size.width; m_nHeight = lrect.size.height;
    
    // Get the appropriate samples per pixel
    m_nSpp = lspp;
    
    // Copy over the bitmap data
    IMAGE_DATA ImageData = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    memcpy(ImageData.pBuffer, ldata, m_nWidth * m_nHeight * m_nSpp);
    [m_pImageData unLockDataForWrite];
    
    // We should always have an alpha layer unless you turn it off
    m_bHasAlpha = YES;
    
    [self refreshTotalToRender];
    
    return self;
}

- (id)initWithDocument:(id)doc layer:(PSLayer*)layer
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    m_enumLayerFormat = PS_RASTER_LAYER;
    // Synchronize properties
    m_nWidth = [layer width];
    m_nHeight = [layer height];
    m_nMode = [layer mode];
    m_nSpp = [[[layer document] contents] spp];
    
    IMAGE_DATA ImageData = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:[layer alphaPremultiplied]];
    
    memcpy(ImageData.pBuffer, [layer getRawData], m_nWidth * m_nHeight * m_nSpp);
    [layer unLockRawData];
    [m_pImageData unLockDataForWrite];
    
    m_nXoff     = [layer xoff];
    m_nYoff     = [layer yoff];
    m_bVisible  = [layer visible];
    m_bLockd    = [layer locked];
    m_bLinked   = [layer linked];
    m_bFloating = [layer floating];
    m_nOpacity  = [layer opacity];
    [m_strName autorelease];
    m_strName   = [NSString stringWithString:[layer name]];
    [m_strName retain];
    
    // Assume we always have alpha
    m_bHasAlpha = YES;
    
    // Finally convert the bitmap to the correct type
    [self convertFromType:[(PSContent *)[[layer document] contents] type] to:[(PSContent *)[m_idDocument contents] type]];
    
    if (m_pSmartFilterManager) {
        [m_pSmartFilterManager release];
    }
    m_pSmartFilterManager = [[layer getSmartFilterManager] customCopy];
    [m_pSmartFilterManager setDelegateForManager:self];
    if (m_pLayerRender) {
        [m_pLayerRender release];
        m_pLayerRender = nil;
    }
    
    [self getRender];
    
    [self refreshTotalToRender];
    
    return self;
}

- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata
{
    m_enumLayerFormat = PS_RASTER_LAYER;
    // Set the offsets, height and width
    m_nXoff = lrect.origin.x;
    m_nYoff = lrect.origin.y;
    m_nWidth = lrect.size.width;
    m_nHeight = lrect.size.height;
    
    // Set the other variables according to the arguments
    m_idDocument = doc;
    
    m_nSpp = [[m_idDocument contents] spp];
    
    IMAGE_DATA ImageData = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    memcpy(ImageData.pBuffer, ldata, m_nWidth * m_nHeight * m_nSpp);
    free(ldata);
    [m_pImageData unLockDataForWrite];
    
    
    
    // And then make some sensible choices for the other variables
    m_nMode = 0;
    m_nOpacity = 255;
    
    m_bVisible = YES;
    m_bHasAlpha = YES;
    m_bCompressed = NO;
    m_imgThumbnail = NULL; m_pThumbData = NULL;
    m_bFloating = YES;
    m_idAffinePlugin = [[PSController seaPlugins] affinePlugin];
    
    // Setup for undoing
    m_idPSLayerUndo = [[PSLayerUndo alloc] initWithDocument:doc forLayer:self];
    m_nUniqueLayerID = [(PSDocument *)doc uniqueFloatingLayerID];
    m_strName = NULL; m_arrOldNames = NULL;
    m_strUndoFilePath = [[NSString alloc] initWithFormat:@"%@/psundo-d%d-l%d", [self getUndoSavePath], [m_idDocument uniqueDocID], [self uniqueLayerID]];
    
    [self refreshTotalToRender];
    return self;
}


- (void)dealloc
{
    if (m_strName) [m_strName autorelease];
    if (m_arrOldNames) [m_arrOldNames autorelease];
    if (m_pImageData) [m_pImageData autorelease];
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    if (m_idPSLayerUndo) [m_idPSLayerUndo autorelease];
    if (m_pImageData == NULL)
    {
        struct stat sb;
        
        if (stat([m_strUndoFilePath fileSystemRepresentation], &sb) == 0)
        {
            unlink([m_strUndoFilePath fileSystemRepresentation]);
        }
    }
    
    if(m_pLayerRender) [m_pLayerRender release];
    
    if(m_pSmartFilterManager) [m_pSmartFilterManager release];
    
    if(m_pLostprops) { free(m_pLostprops); m_pLostprops = NULL; }
    
    if (m_strUndoFilePath) [m_strUndoFilePath autorelease];
    
    
    [super dealloc];
}

- (void)shutdown
{
    [m_pLayerRender exitRenderThread];
}

- (NSString *)getUndoSavePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachedPath = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([paths count] > 0) {
        cachedPath = [paths objectAtIndex:0];
        cachedPath = [cachedPath stringByAppendingPathComponent:bundleID];
        cachedPath = [cachedPath stringByAppendingPathComponent:@"temp"];
    }
    if (![fileManager fileExistsAtPath:cachedPath]) {
        [fileManager createDirectoryAtPath:cachedPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cachedPath;
}

- (void)compress
{
    FILE *file;
    
    // If the image data is not already compressed
    if (m_pImageData)
    {
        // Do a check of the disk space
        if ([m_idPSLayerUndo checkDiskSpace])
        {
            
            // Open a file for writing the memory cache
            file = fopen([m_strUndoFilePath fileSystemRepresentation], "w");
            
            // Check we have a valid file handle
            if (file != NULL)
            {
                [self setFullRenderState:NO];
                IMAGE_DATA data = [m_pImageData lockDataForRead];
                // Write the image data to disk
                fwrite(data.pBuffer, sizeof(char), m_nWidth * m_nHeight * m_nSpp, file);
                [m_pImageData unLockDataForRead];
                // Close the memory cache
                fclose(file);
                
                // Free the memory currently occupied the document's data
                PSSecureImageData *olddata = m_pImageData;
                [self performSelector:@selector(releaseDataDelay:) withObject:olddata afterDelay:1.0];
                m_pImageData = NULL;
                
            }
            
            // Get rid of the m_imgThumbnail
            if (m_imgThumbnail) [m_imgThumbnail autorelease];
            if (m_pThumbData) free(m_pThumbData);
            m_imgThumbnail = NULL; m_pThumbData = NULL;
            
            if(m_pLayerRender)
            {
                [m_pLayerRender release];
                m_pLayerRender = nil;
            }
        }
    }
}

- (void)releaseDataDelay:(PSSecureImageData *)data
{
    [data release];
}

- (void)decompress
{
    FILE *file;
    
    // If the image data is not already decompressed
    if (m_pImageData == NULL)
    {
        [self getRender];

        // Create space for the decompressed image data
        bool alphaPremultiplied = false;
        if (m_enumLayerFormat == PS_TEXT_LAYER || (m_enumLayerFormat == PS_VECTOR_LAYER)) {
            alphaPremultiplied = true;
        }
        IMAGE_DATA data = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:alphaPremultiplied];
        
        [self refreshTotalToRender];
        
        // Open a file for writing the image data
        file = fopen([m_strUndoFilePath fileSystemRepresentation], "r");
        
        // Check we have a valid file handle
        if (file != NULL)
        {
            
            // Write the image data to disk
            fread(data.pBuffer, sizeof(char), m_nWidth * m_nHeight * m_nSpp, file);
            
            // Close the file
            fclose(file);
            
            // Delete the file (we have its contents in memory now)
            unlink([m_strUndoFilePath fileSystemRepresentation]);
            
        }
        
        [m_pImageData unLockDataForWrite];
        
    }
}


- (int)width
{
    return m_nWidth;
}

- (int)height
{
    return m_nHeight;
}

- (int)xoff
{
    return m_nXoff;
}

- (int)yoff
{
    return m_nYoff;
}

- (IntRect)localRect
{
    return IntMakeRect(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
}

- (void)setOffsets:(IntPoint)newOffsets
{
    m_nXoff = newOffsets.x;
    m_nYoff = newOffsets.y;
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
//    [m_pLayerRender renderDirtyWithOffsetChangedOnly:CGPointMake(m_nXoff, m_nYoff)];
//    NSLog(@"setOffsets renderDirtyWithInfo:renderInfo no// ?????????????????");
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    renderInfo.flagModifiedType = OFFSET_MODIFIED_ONLY;
    
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_OFFSET];
 
}


//修剪当前层，只保留有内容的部分，以后会用到。之前在floating时用，取消了
- (void)trimLayer
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    int i, j;
    int left, right, top, bottom;
    
    // Start out with invalid content borders
    left = right = top = bottom =  -1;
    
    // Determine left content margin
    for (i = 0; i < m_nWidth && left == -1; i++)
    {
        for (j = 0; j < m_nHeight && left == -1; j++)
        {
            if (pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
            {
                left = i;
            }
        }
    }
    
    // Determine right content margin
    for (i = m_nWidth - 1; i >= 0 && right == -1; i--)
    {
        for (j = 0; j < m_nHeight && right == -1; j++)
        {
            if (pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
            {
                right = m_nWidth - 1 - i;
            }
        }
    }
    
    // Determine top content margin
    for (j = 0; j < m_nHeight && top == -1; j++)
    {
        for (i = 0; i < m_nWidth && top == -1; i++)
        {
            if (pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
            {
                top = j;
            }
        }
    }
    
    // Determine bottom content margin
    for (j = m_nHeight - 1; j >= 0 && bottom == -1; j--)
    {
        for (i = 0; i < m_nWidth && bottom == -1; i++)
        {
            if (pData[j * m_nWidth * m_nSpp + i * m_nSpp + (m_nSpp - 1)] != 0)
            {
                bottom = m_nHeight - 1 - j;
            }
        }
    }
    
    [m_pImageData unLockDataForWrite];
    // Make the change
    if (left != 0 || top != 0 || right != 0 || bottom != 0)
        [self setMarginLeft:-left top:-top right:-right bottom:-bottom];
}

- (BOOL)isEdgeInCanvas
{
    if (m_pImageData == NULL) return NO;
    
    int left, right, top, bottom;
    
    // Start out with invalid content borders
    left = right = top = bottom =  0;
    
    int contentW = [(PSContent *)[m_idDocument contents] width];
    int contentH = [(PSContent *)[m_idDocument contents] height];
    
    if (m_nXoff > 0)
    {
        left = m_nXoff;
    }
    if (m_nYoff > 0)
    {
        top = m_nYoff;
    }
    if (m_nXoff + m_nWidth < contentW)
    {
        right = contentW - (m_nXoff + m_nWidth);
    }
    if (m_nYoff + m_nHeight < contentH)
    {
        bottom = contentH - (m_nYoff + m_nHeight);
    }
    
    // [m_pImageData unLockDataForWrite];
    // Make the change
    if (left != 0 || top != 0 || right != 0 || bottom != 0)
        return YES;
    
    return NO;
}

- (BOOL)expandLayerTemply:(IntPoint *)where
{
    if (m_pImageData == NULL) return NO;
    
    
    int left, right, top, bottom;
    
    // Start out with invalid content borders
    left = right = top = bottom =  0;
    
    int contentW = [(PSContent *)[m_idDocument contents] width];
    int contentH = [(PSContent *)[m_idDocument contents] height];
    
    if(where == NULL)
    {
        if (m_nXoff > 0)
        {
            left = m_nXoff;
        }
        if (m_nYoff > 0)
        {
            top = m_nYoff;
        }
        if (m_nXoff + m_nWidth < contentW)
        {
            right = contentW - (m_nXoff + m_nWidth);
        }
        if (m_nYoff + m_nHeight < contentH)
        {
            bottom = contentH - (m_nYoff + m_nHeight);
        }
    }
    else
    {
        if (m_nXoff > 0 && where->x < 0)
        {
            left = MIN(m_nXoff, -(where->x - 100));
        }
        if (m_nYoff > 0  && where->y < 0)
        {
            top = MIN(m_nYoff, -(where->y - 100));
        }
        if (m_nXoff + m_nWidth < contentW && where->x > m_nWidth)
        {
            right = MIN(contentW - (m_nXoff + m_nWidth),  where->x -(m_nWidth) +100);
        }
        if (m_nYoff + m_nHeight < contentH && where->y > m_nHeight)
        {
            bottom = MIN(contentH - (m_nYoff + m_nHeight),  where->y -(m_nHeight) +100);
        }
    }
    
    // [m_pImageData unLockDataForWrite];
    // Make the change
    if (left != 0 || top != 0 || right != 0 || bottom != 0)
    {
        [self setMarginLeft:left top:top right:right bottom:bottom];
        
        return YES;
    }
    
    return NO;
}

- (void)flipHorizontally
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    unsigned char temp[4];
    int i, j;
    float tempDis = 0;
    for (j = 0; j < m_nHeight; j++)
    {
        for (i = 0; i < m_nWidth / 2; i++)
        {
            memcpy(temp, &(pData[(j * m_nWidth + i) * m_nSpp]), m_nSpp);
            memcpy(&(pData[(j * m_nWidth + i) * m_nSpp]), &(pData[(j * m_nWidth + (m_nWidth - i - 1)) * m_nSpp]), m_nSpp);
            memcpy(&(pData[(j * m_nWidth + (m_nWidth - i - 1)) * m_nSpp]), temp, m_nSpp);
        }
    }
    
    [m_pImageData unLockDataForWrite];
    
   	
    m_nXoff = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    
    //[self combineWillBeProcessDataRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)];
    [self refreshTotalToRender];
    
}

- (void)flipVertically
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    unsigned char temp[4];
    int i, j;
    float tempDis = 0;
    for (j = 0; j < m_nHeight / 2; j++)
    {
        for (i = 0; i < m_nWidth; i++)
        {
            memcpy(temp, &(pData[(j * m_nWidth + i) * m_nSpp]), m_nSpp);
            memcpy(&(pData[(j * m_nWidth + i) * m_nSpp]), &(pData[((m_nHeight - j - 1) * m_nWidth + i) * m_nSpp]), m_nSpp);
            memcpy(&(pData[((m_nHeight - j - 1) * m_nWidth + i) * m_nSpp]), temp, m_nSpp);
        }
    }
    
    [m_pImageData unLockDataForWrite];
   	
    m_nYoff = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
    
    //[self combineWillBeProcessDataRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)];
    [self refreshTotalToRender];
}

- (void)rotateLeft
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    int newWidth, newHeight, ox, oy;
    unsigned char *newData;
    int i, j, k;
    
    newWidth = m_nHeight;
    newHeight = m_nWidth;
    
    PSSecureImageData *newImageData = [[PSSecureImageData alloc] initData:newWidth height:newHeight spp:m_nSpp alphaPremultiplied:false];
    IMAGE_DATA dataNew = [newImageData lockDataForWrite];
    newData = dataNew.pBuffer;
    
    for (j = 0; j < m_nHeight; j++)
    {
        for (i = 0; i < m_nWidth; i++)
        {
            for (k = 0; k < m_nSpp; k++)
            {
                newData[((newHeight - i - 1) * newWidth + j) * m_nSpp + k] = pData[(j * m_nWidth + i) * m_nSpp + k];
            }
        }
    }
    
    [m_pImageData unLockDataForWrite];
    [newImageData unLockDataForWrite];
    
    
    ox = [(PSContent *)[m_idDocument contents] width] - m_nXoff - m_nWidth;
    oy = m_nYoff;
    
    m_nWidth = newWidth;
    m_nHeight = newHeight;
    
    m_nXoff = oy;
    m_nYoff = ox;
    
    
    [m_pImageData transferFrom:newImageData];
    //  [newImageData lockAndTransferData];
    [newImageData release];
    
    [self refreshTotalToRender];
}

- (void)rotateRight
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    int newWidth, newHeight, ox, oy;
    unsigned char *newData;
    int i, j, k;
    
    newWidth = m_nHeight;
    newHeight = m_nWidth;
    newData = malloc(make_128(newWidth * newHeight * m_nSpp));
    
    for (j = 0; j < m_nHeight; j++)
    {
        for (i = 0; i < m_nWidth; i++)
        {
            for (k = 0; k < m_nSpp; k++)
            {
                newData[(i * newWidth + (newWidth - j - 1)) * m_nSpp + k] = pData[(j * m_nWidth + i) * m_nSpp + k];
            }
        }
    }
    
    [m_pImageData unLockDataForWrite];
    //free(m_pData);
    
    
    ox = m_nXoff;
    oy = [(PSContent *)[m_idDocument contents] height] - m_nYoff - m_nHeight;
    
    m_nWidth = newWidth;
    m_nHeight = newHeight;
    
    //    [m_pImageData release];
    //    m_pImageData = [[PSSecureImageData alloc] initDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    
    //	m_pData = newData;
    m_nXoff = oy;
    m_nYoff = ox;
    
    [self refreshTotalToRender];
}

- (void)setCocoaRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    NSAffineTransform *at, *tat;
    unsigned char *srcData;
    NSImage *image_out;
    NSBitmapImageRep *in_rep, *final_rep;
    NSPoint point[4], minPoint, maxPoint, transformPoint;
    int i, oldHeight, oldWidth;
    int ispp, bipp, bypr, ispace, ibps;
    
    // Define the rotation
    at = [NSAffineTransform transform];
    [at rotateByDegrees:degrees];
    
    // Determine the input image
    premultiplyBitmap(m_nSpp, pData, pData, m_nWidth * m_nHeight);
    in_rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
    
    // Determine the output size
    point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
    point[1] = [at transformPoint:NSMakePoint(m_nWidth, 0.0)];
    point[2] = [at transformPoint:NSMakePoint(0.0, m_nHeight)];
    point[3] = [at transformPoint:NSMakePoint(m_nWidth, m_nHeight)];
    minPoint = point[0];
    for (i = 0; i < 4; i++) {
        if (point[i].x < minPoint.x)
            minPoint.x = point[i].x;
        if (point[i].y < minPoint.y)
            minPoint.y = point[i].y;
    }
    maxPoint = point[0];
    for (i = 0; i < 4; i++) {
        if (point[i].x > maxPoint.x)
            maxPoint.x = point[i].x;
        if (point[i].y > maxPoint.y)
            maxPoint.y = point[i].y;
    }
    oldWidth = m_nWidth;
    oldHeight = m_nHeight;
    m_nWidth = ceilf(maxPoint.x - minPoint.x);
    m_nHeight = ceilf(maxPoint.y - minPoint.y);
    m_nXoff += oldWidth / 2 - m_nWidth / 2;
    m_nYoff += oldHeight / 2 - m_nHeight / 2;
    
    // Determine the output image
    image_out = [[NSImage alloc] initWithSize:NSMakeSize(m_nWidth, m_nHeight)];
    [image_out setCachedSeparately:YES];
    [image_out recache];
    [image_out lockFocus];
    
    // Work out full transform
    tat = [NSAffineTransform transform];
    transformPoint.x = -minPoint.x;
    transformPoint.y = -minPoint.y;
    [tat translateXBy:transformPoint.x yBy:transformPoint.y];
    [at appendTransform:tat];
    
    [[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
    [[NSAffineTransform transform] set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)] setClip];
    [at set];
    [in_rep drawAtPoint:NSMakePoint(0.0, 0.0)];
    [[NSAffineTransform transform] set];
    final_rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, m_nWidth, m_nHeight)];
    [image_out unlockFocus];
    
    // Start clean up
    [in_rep autorelease];
    
    [m_pImageData unLockDataForWrite];
    //free(m_pData);
    
    // Make the swap
    srcData = [final_rep bitmapData];
    ispp = [final_rep samplesPerPixel];
    bipp = [final_rep bitsPerPixel];
    bypr = [final_rep bytesPerRow];
    ispace = (ispp > 2) ? kRGBColorSpace : kGrayColorSpace;
    ibps = [final_rep bitsPerPixel] / [final_rep samplesPerPixel];
    unsigned char *newData = convertBitmap(m_nSpp, (m_nSpp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcData, m_nWidth, m_nHeight, ispp, bipp, bypr, ispace, NULL, ibps, 0);
    
    // Clean up
    [final_rep autorelease];
    [image_out autorelease];
    unpremultiplyBitmap(m_nSpp, newData, newData, m_nWidth * m_nHeight);
    
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    
    //free(newData);
    
    // Make margin changes
    if (trim) [self trimLayer];
}

- (void)setCoreImageRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    unsigned char *newData;
    NSAffineTransform *at;
    int newWidth, newHeight, i;
    NSPoint point[4], minPoint, maxPoint;
    
    // Determine affine transform
    at = [NSAffineTransform transform];
    [at rotateByDegrees:degrees];
    
    // Determine the output size
    point[0] = [at transformPoint:NSMakePoint(0.0, 0.0)];
    point[1] = [at transformPoint:NSMakePoint(m_nWidth, 0.0)];
    point[2] = [at transformPoint:NSMakePoint(0.0, m_nHeight)];
    point[3] = [at transformPoint:NSMakePoint(m_nWidth, m_nHeight)];
    minPoint = point[0];
    for (i = 0; i < 4; i++) {
        if (point[i].x < minPoint.x)
            minPoint.x = point[i].x;
        if (point[i].y < minPoint.y)
            minPoint.y = point[i].y;
    }
    maxPoint = point[0];
    for (i = 0; i < 4; i++) {
        if (point[i].x > maxPoint.x)
            maxPoint.x = point[i].x;
        if (point[i].y > maxPoint.y)
            maxPoint.y = point[i].y;
    }
    newWidth = ceilf(maxPoint.x - minPoint.x);
    newHeight = ceilf(maxPoint.y - minPoint.y);
    
    // Run the transform
    newData = [m_idAffinePlugin runAffineTransform:at withImage:pData spp:m_nSpp width:m_nWidth height:m_nHeight opaque:NO newWidth:&newWidth newHeight:&newHeight];
    
    // Replace the old bitmap with the new bitmap
    
    //m_pData = newData;
    m_nXoff += m_nWidth / 2 - newWidth / 2;
    m_nYoff += m_nHeight / 2 - newHeight / 2;
    m_nWidth = newWidth; m_nHeight = newHeight;
    
    [m_pImageData unLockDataForWrite];
    
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    // Destroy the m_imgThumbnail m_pData
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
    
    // Make margin changes
    if (trim) [self trimLayer];
}


- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim
{
    if (m_idAffinePlugin && [[PSController m_idPSPrefs] useCoreImage])
    {
        [self setCoreImageRotation:degrees interpolation:interpolation withTrim:trim];
    }
    else
    {
        [self setCocoaRotation:degrees interpolation:interpolation withTrim:trim];
    }
    
    
    [self refreshTotalToRender];
    
}


- (BOOL)visible
{
    return m_bVisible;
}

- (void)setVisible:(BOOL)value
{
    m_bVisible = value;
}

- (BOOL)locked
{
    return m_bLockd;
}

- (BOOL)linked
{
    return m_bLinked;
}

- (void)setLinked:(BOOL)value
{
    m_bLinked = value;
}

- (int)opacity
{
    return m_nOpacity;
}

- (void)setOpacity:(int)value
{
    m_nOpacity = value;
}

- (int)spp
{
    return m_nSpp;
}

- (bool)alphaPremultiplied
{
    if(!m_pImageData) return false;
    
    IMAGE_DATA imageData = [m_pImageData lockDataForRead];
    bool bAlphaPremultiplied = imageData.bAlphaPremultiplied;
    [m_pImageData unLockDataForRead];
    
    return bAlphaPremultiplied;
}

- (int)mode
{
    return m_nMode;
}

- (void)setMode:(int)value
{
    m_nMode = value;
}

- (NSString *)name
{
    return m_strName;
}

- (void)setName:(NSString *)newName
{
    if (m_strName) {
        [m_arrOldNames autorelease];
        m_arrOldNames = [m_arrOldNames arrayByAddingObject:m_strName];
        [m_arrOldNames retain]; [m_strName autorelease];
        m_strName = newName;
        [m_strName retain];
    }
}

- (unsigned char *)getRawData
{
    if (m_pImageData == NULL) return NULL;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    
    return data.pBuffer;
}

- (void)unLockRawData
{
    [m_pImageData unLockDataForWrite];
}

- (unsigned char *)getDirectData
{
    if (m_pImageData == NULL) return NULL;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    [m_pImageData unLockDataForWrite];
    
    return data.pBuffer;
}

- (unsigned char *)getRawDataForRead
{
    if (m_pImageData == NULL) return NULL;
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    
    return data.pBuffer;
}

- (void)unLockRawDataForRead
{
    if (m_pImageData == NULL) return;
    
    [m_pImageData unLockDataForRead];
}

- (BOOL)hasAlpha
{
    return YES; //m_bHasAlpha;
}

- (void)toggleAlpha
{
    // Do nothing if we can't do anything
    if (![self canToggleAlpha])
        return;
    
    // Change the alpha channel treatment
    m_bHasAlpha = !m_bHasAlpha;
    
    // Update the Pegasus utility
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] toggleAlpha];
}

- (void)introduceAlpha
{
    m_bHasAlpha = YES;
}

- (BOOL)canToggleAlpha
{
    int i;
    
    if (m_bFloating)
        return NO;
    
    if (m_bHasAlpha)
    {
        if (m_pImageData == NULL) return NO;
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        unsigned char *pData = data.pBuffer;
        
        for (i = 0; i < m_nWidth * m_nHeight; i++)
        {
            if (pData[(i + 1) * m_nSpp - 1] != 255)
            {
                [m_pImageData unLockDataForRead];
                return NO;
            }
        }
        [m_pImageData unLockDataForRead];
    }
    
    return YES;
}

- (char *)lostprops
{
    return m_pLostprops;
}

- (int)lostprops_len
{
    return m_nLostpropsLen;
}

- (int)uniqueLayerID
{
    return m_nUniqueLayerID;
}

- (int)index
{
    int i;
    
    for (i = 0; i < [[m_idDocument contents] layerCount]; i++) {
        if ([[m_idDocument contents] layer:i] == self)
            return i;
    }
    
    return -1;
}

- (BOOL)floating
{
    return m_bFloating;
}

- (id)seaLayerUndo
{
    return m_idPSLayerUndo;
}


- (NSImage *)thumbnailForChannel:(int)channel
{
    NSBitmapImageRep *tempRep;
    
    // Determine the size for the image
    int nThumbWidth = m_nWidth;
    int nThumbHeight = m_nHeight;
    if (m_nWidth > 40 || m_nHeight > 32) {
        if ((float)m_nWidth / 40.0 > (float)m_nHeight / 32.0) {
            nThumbHeight = (int)((float)m_nHeight * (40.0 / (float)m_nWidth));
            nThumbWidth = 40;
        }
        else {
            nThumbWidth = (int)((float)m_nWidth * (32.0 / (float)m_nHeight));
            nThumbHeight = 32;
        }
    }
    if(nThumbWidth <= 0){
        nThumbWidth = 1;
    }
    if(nThumbHeight <= 0){
        nThumbHeight = 1;
    }
    
    // Create the thumbnail
    unsigned char * pThumbData = NULL;
    switch (channel) {
        case 0:
            if (m_pThumbDataRed) {
                free(m_pThumbDataRed);
            }
            m_pThumbDataRed = malloc(nThumbWidth * nThumbHeight);
            pThumbData = m_pThumbDataRed;
            break;
        case 1:
            if (m_pThumbDataGreen) {
                free(m_pThumbDataGreen);
            }
            m_pThumbDataGreen = malloc(nThumbWidth * nThumbHeight);
            pThumbData = m_pThumbDataGreen;
            break;
        case 2:
            if (m_pThumbDataBlue) {
                free(m_pThumbDataBlue);
            }
            m_pThumbDataBlue = malloc(nThumbWidth * nThumbHeight);
            pThumbData = m_pThumbDataBlue;
            break;
        case 3:
            if (m_pThumbDataAlpha) {
                free(m_pThumbDataAlpha);
            }
            m_pThumbDataAlpha = malloc(nThumbWidth * nThumbHeight);
            pThumbData = m_pThumbDataAlpha;
            break;
            
        default:
            break;
    }
    
    // Determine the thumbnail data
    [self updateThumbnailData:pThumbData width:nThumbWidth height:nThumbHeight channel:channel];
    
    
    // Create the representation
    tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pThumbData pixelsWide:nThumbWidth pixelsHigh:nThumbHeight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:nThumbWidth bitsPerPixel:8];
    
    // Wrap it up in an NSImage
    NSImage *imgThumbnail;
    imgThumbnail = [[NSImage alloc] initWithSize:NSMakeSize(nThumbWidth, nThumbHeight)];
    [imgThumbnail addRepresentation:tempRep];
    [tempRep autorelease];
    
    return imgThumbnail;
}

- (void)updateThumbnailData:(unsigned char*)pThumbData width:(int)nThumbWidth height:(int)nThumbHeight channel:(int)channel
{
    float horizStep, vertStep;
    int i, j, k, temp;
    int srcPos, destPos;
    
    if (pThumbData) {
        
        if (m_pImageData == NULL) return;
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        unsigned char *pData = data.pBuffer;
        
        // Determine the thumbnail data
        horizStep = (float)m_nWidth / (float)nThumbWidth;
        vertStep = (float)m_nHeight / (float)nThumbHeight;
        for (j = 0; j < nThumbHeight; j++)
        {
            for (i = 0; i < nThumbWidth; i++)
            {
                srcPos = ((int)(j * vertStep) * m_nWidth + (int)(i * horizStep)) * m_nSpp;
                destPos = j * nThumbWidth + i;
                
                pThumbData[destPos] = pData[srcPos + channel];
            }
        }
        
        [m_pImageData unLockDataForRead];
        
    }
}


- (NSImage *)thumbnail
{
    NSBitmapImageRep *tempRep;
    
    // Check if we need an update
    if (m_pThumbData == NULL) {
        
        // Determine the size for the image
        m_nThumbWidth = m_nWidth; m_nThumbHeight = m_nHeight;
        if (m_nWidth > 40 || m_nHeight > 32) {
            if ((float)m_nWidth / 40.0 > (float)m_nHeight / 32.0) {
                m_nThumbHeight = (int)((float)m_nHeight * (40.0 / (float)m_nWidth));
                m_nThumbWidth = 40;
            }
            else {
                m_nThumbWidth = (int)((float)m_nWidth * (32.0 / (float)m_nHeight));
                m_nThumbHeight = 32;
            }
        }
        if(m_nThumbWidth <= 0){
            m_nThumbWidth = 1;
        }
        if(m_nThumbHeight <= 0){
            m_nThumbHeight = 1;
        }
        // Create the thumbnail
        m_pThumbData = malloc(m_nThumbWidth * m_nThumbHeight * m_nSpp);
        
        // Determine the thumbnail data
        [self updateThumbnail];
        
    }
    
    // Create the representation
    tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pThumbData pixelsWide:m_nThumbWidth pixelsHigh:m_nThumbHeight bitsPerSample:8 samplesPerPixel:m_nSpp hasAlpha:YES isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nThumbWidth * m_nSpp bitsPerPixel:8 * m_nSpp];
    
    // Wrap it up in an NSImage
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    m_imgThumbnail = [[NSImage alloc] initWithSize:NSMakeSize(m_nThumbWidth, m_nThumbHeight)];
    [m_imgThumbnail addRepresentation:tempRep];
    [tempRep autorelease];
    
    return m_imgThumbnail;
}


- (void)updateThumbnail
{
    float horizStep, vertStep;
    int i, j, k, temp;
    int srcPos, destPos;
    
    if (m_pThumbData) {
        
        if (m_pImageData == NULL) return;
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        
        if(data.nWidth == 0 || data.nHeight == 0 || data.pBuffer == NULL)
        {
            [m_pImageData unLockDataForRead];
            return;
        }
        
        unsigned char *pData = data.pBuffer;
        
        // Determine the thumbnail data
        horizStep = (float)m_nWidth / (float)m_nThumbWidth;
        vertStep = (float)m_nHeight / (float)m_nThumbHeight;
        for (j = 0; j < m_nThumbHeight; j++)
        {
            for (i = 0; i < m_nThumbWidth; i++)
            {
                srcPos = ((int)(j * vertStep) * m_nWidth + (int)(i * horizStep)) * m_nSpp;
                destPos = (j * m_nThumbWidth + i) * m_nSpp;
                
                if (pData[srcPos + (m_nSpp - 1)] == 255)
                {
                    for (k = 0; k < m_nSpp; k++)
                        m_pThumbData[destPos + k] = pData[srcPos + k];
                }
                else if (pData[srcPos + (m_nSpp - 1)] == 0)
                {
                    for (k = 0; k < m_nSpp; k++)
                        m_pThumbData[destPos + k] = 0;
                }
                else
                {
                    for (k = 0; k < m_nSpp - 1; k++)
                        m_pThumbData[destPos + k] = int_mult(pData[srcPos + k], pData[srcPos + (m_nSpp - 1)], temp);
                    m_pThumbData[destPos + (m_nSpp - 1)] = pData[srcPos + (m_nSpp - 1)];
                }
            }
        }
        
        [m_pImageData unLockDataForRead];
        
    }
}

- (NSData *)TIFFRepresentation
{
    if (m_pImageData == NULL) return nil;
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    NSBitmapImageRep *imageRep;
    NSData *imageTIFFData;
    unsigned char *pmImageData;
    int i, j, tspp;
    
    // Allocate room for the premultiplied image data
    if (m_bHasAlpha)
        pmImageData = malloc(m_nWidth * m_nHeight * m_nSpp);
    else
        pmImageData = malloc(m_nWidth * m_nHeight * (m_nSpp - 1));
    
    // If there is an alpha channel...
    if (m_bHasAlpha) {
        
        // Formulate the premultiplied data from the data
        premultiplyBitmap(m_nSpp, pmImageData, pData, m_nWidth * m_nHeight);
        
    }
    else {
        
        // Strip the alpha channel
        for (i = 0; i < m_nWidth * m_nHeight; i++) {
            for (j = 0; j < m_nSpp - 1; j++) {
                pmImageData[i * (m_nSpp - 1) + j] = pData[i * m_nSpp + j];
            }
        }
        
    }
    
    // Then create the representation
    tspp = (m_bHasAlpha ? m_nSpp : m_nSpp - 1);
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pmImageData pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:tspp hasAlpha:m_bHasAlpha isPlanar:NO colorSpaceName:(m_nSpp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:m_nWidth * tspp bitsPerPixel:8 * tspp];
    
    // Work out the image data
    imageTIFFData = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:255];
    
    // Release the representation and the image data
    [imageRep autorelease];
    free(pmImageData);
    
    [m_pImageData unLockDataForRead];
    
    return imageTIFFData;
}



- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    unsigned char *newImageData;
    int i, j, k, destPos, srcPos, newWidth, newHeight;
    
    // Allocate an appropriate amount of memory for the new bitmap
    newWidth = m_nWidth + left + right;
    newHeight = m_nHeight + top + bottom;
    newImageData = malloc(make_128(newWidth * newHeight * m_nSpp));
    // do_128_clean(newImageData, make_128(newWidth * newHeight * m_nSpp));
    
    // Fill the new bitmap with the appropriate values
    for (j = 0; j < newHeight; j++)
    {
        for (i = 0; i < newWidth; i++)
        {
            
            destPos = (j * newWidth + i) * m_nSpp;
            
            if (i < left || i >= left + m_nWidth || j < top || j >= top + m_nHeight)
            {
              //  if (!m_bHasAlpha) { for (k = 0; k < m_nSpp; k++) newImageData[destPos + k] = 255; }
              //  else
                { for (k = 0; k < m_nSpp; k++) newImageData[destPos + k] = 0; }
            }
            else
            {
                srcPos = ((j - top) * m_nWidth + (i - left)) * m_nSpp;
                for (k = 0; k < m_nSpp; k++)
                    newImageData[destPos + k] = pData[srcPos + k];
            }
            
        }
    }
    
    [m_pImageData unLockDataForRead];
    
    // Replace the old bitmap with the new bitmap
    //free(m_pData);
    //m_pData = newImageData;
    m_nWidth = newWidth; m_nHeight = newHeight;
    m_nXoff -= left; m_nYoff -= top;
    [m_pImageData reInitDataWithBuffer:newImageData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    
    // Destroy the thumbnail data
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
    
    [self refreshTotalToRender];
    
}


- (void)setCocoaWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    unsigned char *newData;
    
    // Allocate an appropriate amount of memory for the new bitmap
    newData = malloc(make_128(newWidth * newHeight * m_nSpp));
    
    // Do the scale
    GCScalePixels(newData, newWidth, newHeight, pData, m_nWidth, m_nHeight, interpolation, m_nSpp);
    
    [m_pImageData unLockDataForRead];
    
    // Replace the old bitmap with the new bitmap
    //free(m_pData);
    //m_pData = newData;
    m_nWidth = newWidth; m_nHeight = newHeight;
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    
    // Destroy the thumbnail data
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
}


- (void)setCoreImageWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    unsigned char *newData;
    NSAffineTransform *at;
    
    // Determine affine transform
    at = [NSAffineTransform transform];
    [at scaleXBy:(float)newWidth / (float)m_nWidth yBy:(float)newHeight / (float)m_nHeight];
    
    // Run the transform
    newData = [m_idAffinePlugin runAffineTransform:at withImage:pData spp:m_nSpp width:m_nWidth height:m_nHeight opaque:!m_bHasAlpha newWidth:&newWidth newHeight:&newHeight];
    
    [m_pImageData unLockDataForRead];
    
    // Replace the old bitmap with the new bitmap
    //free(m_pData);
    //m_pData = newData;
    m_nWidth = newWidth; m_nHeight = newHeight;
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    
    // Destroy the thumbnail data
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
}


- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation
{
    // The issue here is it looks like we're not smart enough to pass anything
    // to the affine plugin besides cubic, so if we're not cupbic we have to use cocoa
    if (m_idAffinePlugin && [[PSController m_idPSPrefs] useCoreImage] && interpolation == GIMP_INTERPOLATION_CUBIC) {
        [self setCoreImageWidth:newWidth height:newHeight interpolation:interpolation];
    }
    else {
        [self setCocoaWidth:newWidth height:newHeight interpolation:interpolation];
    }
    [self refreshTotalToRender];
}

- (void)convertFromType:(int)srcType to:(int)destType
{
    CMBitmap srcBitmap, destBitmap;
    CMProfileRef srcProf, destProf;
    CMWorldRef cw;
    unsigned char *newData, *oldData;
    int i;
    
    // Destroy the thumbnail data
    if (m_imgThumbnail) [m_imgThumbnail autorelease];
    if (m_pThumbData) free(m_pThumbData);
    m_imgThumbnail = NULL; m_pThumbData = NULL;
    
    // Don't do anything if there is nothing to do
    if (srcType == destType)
        return;
    
    if (srcType == XCF_RGB_IMAGE && destType == XCF_GRAY_IMAGE)
    {
        if (m_pImageData == NULL) return;
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        unsigned char *pData = data.pBuffer;
        
        // Create colour world
        OpenDisplayProfile(&srcProf);
        CMGetDefaultProfileBySpace(cmGrayData, &destProf);
        NCWNewColorWorld(&cw, srcProf, destProf);
        
        // Define the source
        oldData = pData;
        srcBitmap.image = (char *)oldData;
        srcBitmap.width = m_nWidth;
        srcBitmap.height = m_nHeight;
        srcBitmap.rowBytes = m_nWidth * 4;
        srcBitmap.pixelSize = 8 * 4;
        srcBitmap.space = cmRGBA32Space;
        
        // Define the destination
        newData = malloc(make_128(m_nWidth * m_nHeight * 2));
        destBitmap.image = (char *)newData;
        destBitmap.width = m_nWidth;
        destBitmap.height = m_nHeight;
        destBitmap.rowBytes = m_nWidth * 2;
        destBitmap.pixelSize = 8 * 2;
        destBitmap.space = cmGrayA16Space;
        
        // Execute the conversion
        CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
        for (i = 0; i < m_nWidth * m_nHeight; i++)
            newData[i * 2 + 1] = oldData[i * 4 + 3];
        
        [m_pImageData unLockDataForRead];
        
        //m_pData = newData;
        //free(oldData);
        m_nSpp = 2;
        [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
        
        // Get rid of the colour world - we no longer need it
        CWDisposeColorWorld(cw);
        CloseDisplayProfile(srcProf);
        
    }
    else if (srcType == XCF_GRAY_IMAGE && destType == XCF_RGB_IMAGE)
    {
        if (m_pImageData == NULL) return;
        
        IMAGE_DATA data = [m_pImageData lockDataForRead];
        unsigned char *pData = data.pBuffer;
        
        // Create colour world
        CMGetDefaultProfileBySpace(cmGrayData, &srcProf);
        OpenDisplayProfile(&destProf);
        NCWNewColorWorld(&cw, srcProf, destProf);
        
        // Define the source
        oldData = pData;
        srcBitmap.image = (char *)oldData;
        srcBitmap.width = m_nWidth;
        srcBitmap.height = m_nHeight;
        srcBitmap.rowBytes = m_nWidth * 2;
        srcBitmap.pixelSize = 8 * 2;
        srcBitmap.space = cmGrayA16Space;
        
        // Define the destination
        newData = malloc(make_128(m_nWidth * m_nHeight * 4));
        destBitmap.image = (char *)newData;
        destBitmap.width = m_nWidth;
        destBitmap.height = m_nHeight;
        destBitmap.rowBytes = m_nWidth * 4;
        destBitmap.pixelSize = 8 * 4;
        destBitmap.space = cmRGBA32Space;
        
        // Execute the conversion
        CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
        for (i = 0; i < m_nWidth * m_nHeight; i++)
            newData[i * 4 + 3] = oldData[i * 2 + 1];
        
        [m_pImageData unLockDataForRead];
        //m_pData = newData;
        free(oldData);
        
        m_nSpp = 4;
        
        [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
        // Get rid of the colour world - we no longer need it
        CWDisposeColorWorld(cw);
        CloseDisplayProfile(destProf);
        
    }
    
    [self refreshTotalToRender];
    
}



#pragma mark -
#pragma mark raw data layer effect

- (void)notifyLayerActive:(BOOL)isActive
{
    //free distance info
    if (isActive) {
        
    }
}

- (void)refreshTotalToRender
{
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    [self setFullRenderState:NO];
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    renderInfo.flagModifiedType = IMAGE_FILTER_FULL_MODIFIED;
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_DEFAULT];
    //[self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2];
    [self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
    
}

- (void)refreshTotalToRenderForEffect
{
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    [self setFullRenderState:NO];
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    renderInfo.flagModifiedType = EFFECT_MODIFIED_ONLY;
    
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_DEFAULT];
    //[self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2];
    [self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
}

- (void)refreshTotalToRenderDisableEffect
{
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    [self setFullRenderState:NO];
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    renderInfo.flagModifiedType = EFFECT_DISABLE_ONLY;
    
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:CGRectMake(0, 0, m_nWidth, m_nHeight) refreshType:REFRESH_TYPE_DEFAULT];
    //[self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2];
    [self performSelector:@selector(setFullRenderStateDelay:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.2 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
}


//update data to m_pDataWithFilter
- (NSRect)updateFullDataWithFilterAfterDataChangeInRect:(NSRect)rect
{
    if (rect.size.width <= 0.5 || rect.size.height <= 0.5) {
        return rect;
    }
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    //    NSLog(@"rect %@",NSStringFromRect(rect));
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:rect refreshType:REFRESH_TYPE_DEFAULT];
    
    return rect;
}

- (int)selectedChannelOfLayer
{
    if([m_pSmartFilterManager getSmartFiltersCount] <= 0)
        return kAllChannels;
    
    int filterIndex = [m_pSmartFilterManager getSmartFiltersCount] - 1;
    BOOL redVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
    BOOL greenVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
    BOOL blueVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
    BOOL alphaVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;
    
    if (!redVisible && !greenVisible && !blueVisible && alphaVisible) {
        return kAlphaChannel;
    }
    if (redVisible && greenVisible && blueVisible && !alphaVisible) {
        return kPrimaryChannels;
    }
    return kAllChannels;
}

- (PS_EDIT_CHANNEL_TYPE)editedChannelOfLayer
{
    if([m_pSmartFilterManager getSmartFiltersCount] <= 0)
        return kAllChannels;
    
    int filterIndex = [m_pSmartFilterManager getSmartFiltersCount] - 1;
    BOOL redVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"redVisible" UTF8String]].nIntValue;
    BOOL greenVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"greenVisible" UTF8String]].nIntValue;
    BOOL blueVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"blueVisible" UTF8String]].nIntValue;
    BOOL alphaVisible = [m_pSmartFilterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"alphaVisible" UTF8String]].nIntValue;
    
    if (!redVisible && !greenVisible && !blueVisible && alphaVisible) {
        return kEditAlphaChannel;
    }else if (redVisible && greenVisible && blueVisible && !alphaVisible){
        return kEditPrimaryChannels;
    }else if (redVisible && !greenVisible && !blueVisible) {
        return kEditRedChannels;
    }else if (!redVisible && greenVisible && !blueVisible) {
        return kEditGreenChannels;
    }else if (!redVisible && !greenVisible && blueVisible) {
        return kEditBlueChannels;
    }else if (redVisible && greenVisible && !blueVisible) {
        return kEditRedGreenChannel;
    }else if (redVisible && !greenVisible && blueVisible) {
        return kEditRedBlueChannel;
    }else if (!redVisible && greenVisible && blueVisible) {
        return kEditGreenBlueChannel;
    }
    
    return kEditAllChannels;
}



#pragma mark -
#pragma mark preview data effect


- (BOOL)isHasEffect
{
    int filterIndex = [m_pSmartFilterManager getSmartFiltersCount] - 2;
    FILTER_PARAMETER_INFO paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    
    return NO;
}


- (void)InitialPreviewDataForRect:(IntRect)rect
{
    //return;
    if (IntEqualRects(rect, IntMakeRect(0, 0, m_nWidth, m_nHeight))) {
        return;
    }
    rect.origin.x -= 2;
    rect.origin.y -= 2;
    rect.size.width += 4;
    rect.size.height += 4;
    
    int filterIndex = [m_pSmartFilterManager getSmartFiltersCount] - 2;
    BOOL hasEffect = [m_pSmartFilterManager getFilterIsValidAtIndex:filterIndex];
    if (hasEffect) {
        rect = IntMakeRect(0, 0, m_nWidth, m_nHeight);
    }
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    IMAGE_DATA dataPreview = [[[m_idDocument whiteboard] getOverlayImageData] lockDataForRead]; //overlay
    unsigned char *previewData = dataPreview.pBuffer;
    
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, m_nWidth, m_nHeight));
    
    for (int j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    {
        for (int i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
        {
            int overlayPos = (j * m_nWidth + i) * m_nSpp;
            
            memcpy(previewData + overlayPos, pData + overlayPos, m_nSpp);
            
        }
    }
    [m_pImageData unLockDataForWrite];
    [[[m_idDocument whiteboard] getOverlayImageData] unLockDataForRead];
    
}

//- (void)InitialPreviewDataForRect:(IntRect)rect
//{
//    BOOL hasEffect = [m_pLayerEffect getEffectFilterIsEnable];
//    if (m_isLayerEffectEnable && hasEffect) {
//        if (rect.size.width == m_nWidth && rect.size.height == m_nHeight) {
//            return;
//        }
//        if (rect.size.width <= 0|| rect.size.height <= 0) {
//            return;
//        }
//        NSRect neededRect = [m_pLayerEffect getNeededRectForEffectOfRect:IntRectMakeNSRect(rect)];
//        neededRect = CGRectIntersection(neededRect, CGRectMake(0, 0, m_nWidth, m_nHeight));
//        IntRect neededIntRect = NSRectMakeIntRect(neededRect);
//
//        if (m_pImageData == NULL) return;
//
//        IMAGE_DATA data = [m_pImageData lockDataForRead];
//        unsigned char *pData = data.pBuffer;
//
//        for (int i = neededIntRect.origin.y; i < neededIntRect.origin.y + neededIntRect.size.height; i++) {
//            int srcPos = (i * m_nWidth + neededIntRect.origin.x) * m_nSpp;
//            int desPos = (i * m_nWidth + neededIntRect.origin.x) * m_nSpp;
//            memcpy(m_pPreviewData + desPos, pData + srcPos, neededIntRect.size.width * m_nSpp);
//        }
//
//        [m_pImageData unLockDataForRead];
//    }
//}


- (void)canclePreviewInRect:(NSRect)rect
{
 //   m_previewCancled = YES;
 //   m_previewEffectState = 0;
 //   m_previewRect = rect;
    
    
    [self updateFullDataWithFilterAfterDataChangeInRect:rect];
    //[self refreshTotalToRender];
    
}

- (void)applyPreviewInRect:(IntRect)rect changeDis:(BOOL)changeDis
{
    //[m_idPSLayerUndo takeSnapshot:IntMakeRect(rect.origin.x - m_nXoff, rect.origin.y - m_nYoff, rect.size.width, rect.size.height) automatic:YES];
    [m_idPSLayerUndo takeSnapshot:rect automatic:YES];
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    BOOL floating = [self floating];
    int t1;
    int i, j;
    int selectedChannel = [[m_idDocument contents] selectedChannel];
    int spp = [self spp];
    
    if (m_pImageData == NULL) return;
    
    IMAGE_DATA data = [m_pImageData lockDataForWrite];
    unsigned char *pData = data.pBuffer;
    
    IMAGE_DATA dataPreview = [[[m_idDocument whiteboard] getOverlayImageData] lockDataForRead]; //overlay
    unsigned char *previewData = dataPreview.pBuffer;
    
    int overlayBehaviour = [[m_idDocument whiteboard] getOverlayBehaviour];
    unsigned char *replace = [[m_idDocument whiteboard] replace];
    unsigned char *overlay = [[m_idDocument whiteboard] overlay];
    int overlayOpacity = [[m_idDocument whiteboard] getOverlayOpacity];
    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
        {
            
            int overlayPos = (j * m_nWidth + i) * m_nSpp;
            
            //            IntPoint tempPoint;
            //            tempPoint.x = i;
            //            tempPoint.y = j;
            
            //            int  brushAlpha = 255;
            //            switch (overlayBehaviour) {
            //                case kReplacingBehaviour:
            //                case kMaskingBehaviour:
            //                    brushAlpha = replace[j * m_nWidth + i];
            //                    break;
            //                default:
            //                    brushAlpha = overlayOpacity;
            //                    break;
            //            }
            //
            //            if (mask && useSelection && !floating)
            //            {
            //                if (IntPointInRect(tempPoint, selectRect))
            //                {
            //                    brushAlpha = int_mult(brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
            //
            //                }
            //            }
            //            if (brushAlpha > 0) {
            //                if (selectedChannel == kAllChannels) {
            //                    switch (overlayBehaviour) {
            //                        case kErasingBehaviour:
            //                            //eraseMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
            //                            break;
            //                        case kReplacingBehaviour:{
            //                            unsigned char tempSpace[spp];
            //                            memcpy(tempSpace, pData + overlayPos, spp);
            //                            replaceMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
            //                            memcpy(previewData + overlayPos, tempSpace, spp);
            //
            //                        }
            //                            break;
            //                        default:
            //                            specialMergeCustom(m_nSpp, previewData, overlayPos, previewData, overlayPos, pData, overlayPos, brushAlpha);
            //                            break;
            //                    }
            //
            //                }else if (selectedChannel == kPrimaryChannels || floating)
            //                {
            //                    switch (overlayBehaviour) {
            //                        case kReplacingBehaviour:{
            //                            //replacePrimaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
            //                            unsigned char tempSpace[spp];
            //                            memcpy(tempSpace, pData + overlayPos, spp);
            //                            replacePrimaryMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
            //                            memcpy(previewData + overlayPos, tempSpace, spp - 1);
            //                        }
            //                            break;
            //                        default:{
            //                            unsigned char tempSpace[spp];
            //                            memcpy(tempSpace, pData + overlayPos, spp);
            //                            primaryMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha, NO);
            //                            memcpy(previewData + overlayPos, tempSpace, spp - 1);
            //                        }
            //                            break;
            //                    }
            //
            //                }
            //                else if (selectedChannel == kAlphaChannel)
            //                {
            //                    switch (overlayBehaviour) {
            //                        case kReplacingBehaviour:{
            //                            unsigned char tempSpace[spp];
            //                            memcpy(tempSpace, pData + overlayPos, spp);
            //                            replaceAlphaMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
            //                            previewData[overlayPos + spp - 1] = tempSpace[spp - 1];
            //                        }
            //                            break;
            //                        default:{
            //                            unsigned char tempSpace[spp];
            //                            memcpy(tempSpace, pData + overlayPos, spp);
            //                            alphaMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
            //                            previewData[overlayPos + spp - 1] = tempSpace[spp - 1];
            //                        }
            //                            break;
            //                    }
            //
            //                }
            //
            //                memcpy(pData + overlayPos, previewData + overlayPos, spp);
            //            }
            
            memcpy(pData + overlayPos, previewData + overlayPos, m_nSpp);
        }
    }
    
    
    [m_pImageData unLockDataForWrite];
    [[[m_idDocument whiteboard] getOverlayImageData] unLockDataForRead];
    
    [self updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
    
}


- (void)updatePreviewEffectForInRect:(NSRect)rect inThread:(BOOL)inThread mode:(int)mode
{
    [[m_idDocument docView] resetSynthesizedImageRender];
    
 //   m_previewEffectState = 0;
  //  m_previewRect = rect;
  //  m_previewCancled = NO;
    
    RENDER_INFO renderInfo = [self getCurrentRenderInfoForLayer];
    PSSecureImageData *preImageData = [[m_idDocument whiteboard] getOverlayImageData];
    IMAGE_DATA imaData = [preImageData lockDataForWrite];
    
    int selectedChannel = [[m_idDocument contents] selectedChannel];
    
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    if (selectedChannel == kAlphaChannel)
    {
        for (int j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
        {
            for (int i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
            {
                int overlayPos = (j * m_nWidth + i) * m_nSpp;
                imaData.pBuffer[overlayPos + m_nSpp - 1] = imaData.pBuffer[overlayPos];
                memcpy(imaData.pBuffer + overlayPos, pData + overlayPos, m_nSpp - 1);
            }
        }
    }
    else if (selectedChannel == kPrimaryChannels)
    {
        for (int j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
        {
            for (int i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
            {
                int overlayPos = (j * m_nWidth + i) * m_nSpp;
                imaData.pBuffer[overlayPos + m_nSpp - 1] = pData[overlayPos + m_nSpp - 1];
            }
        }
    }
    
    
    
    [m_pImageData unLockDataForRead];
    
    [self addFeatherOnPreviewData:imaData.pBuffer rect:NSRectMakeIntRect(rect)];
    [preImageData unLockDataForWrite];
    renderInfo.dataImage = preImageData;
    [m_pLayerRender renderDirtyWithInfo:renderInfo dirtyRect:rect refreshType:REFRESH_TYPE_DEFAULT];
}


- (void)addFeatherOnPreviewData:(unsigned char*)previewData rect:(IntRect)rect
{
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    
    BOOL floating = [self floating];
    int t1;
    int i, j;
    int selectedChannel = [[m_idDocument contents] selectedChannel];
    int spp = [self spp];
    
    
    if (m_pImageData == NULL) return;
    
    int overlayBehaviour = [[m_idDocument whiteboard] getOverlayBehaviour];
    unsigned char *replace = [[m_idDocument whiteboard] replace];
    unsigned char *overlay = [[m_idDocument whiteboard] overlay];
    int overlayOpacity = [[m_idDocument whiteboard] getOverlayOpacity];
    
    IMAGE_DATA data = [m_pImageData lockDataForRead];
    unsigned char *pData = data.pBuffer;
    
    for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++)
    {
        for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++)
        {
            
            IntPoint tempPoint;
            tempPoint.x = i;
            tempPoint.y = j;
            
            int overlayPos = (j * m_nWidth + i) * m_nSpp;
            int  brushAlpha = 0;
            
            switch (overlayBehaviour)
            {
                case kReplacingBehaviour:
                case kMaskingBehaviour:
                    brushAlpha = replace[j * m_nWidth + i];
                    break;
                default:
                    brushAlpha = overlayOpacity;
                    break;
            }
            
            
            if (mask && useSelection && !floating)
            {
                if (IntPointInRect(tempPoint, selectRect))
                {
                    brushAlpha = int_mult(brushAlpha, mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)], t1);
                    
                }
            }
            
            if (brushAlpha > 0) {
                if (selectedChannel == kAllChannels)
                {
                    switch (overlayBehaviour)
                    {
                        case kErasingBehaviour:
                            //eraseMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
                            break;
                        case kReplacingBehaviour:{
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, pData + overlayPos, spp);
                            replaceMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
                            memcpy(previewData + overlayPos, tempSpace, spp);
                            
                        }
                            break;
                        default:
                        {
                            if (previewData[overlayPos + spp -1] == 0)
                            {
                                memcpy(previewData + overlayPos, pData + overlayPos, m_nSpp);
                                break;
                            }
                            specialMergeCustom(m_nSpp, previewData, overlayPos, previewData, overlayPos, pData, overlayPos, brushAlpha);
                        }
                            break;
                    }
                    
                }else if (selectedChannel == kPrimaryChannels || floating)
                {
                    switch (overlayBehaviour)
                    {
                        case kReplacingBehaviour:
                        {
                            //replacePrimaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, pData + overlayPos, spp);
                            replacePrimaryMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
                            memcpy(previewData + overlayPos, tempSpace, spp - 1);
                        }
                            break;
                        default:
                        {
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, pData + overlayPos, spp);
                            primaryMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha, NO);
                            memcpy(previewData + overlayPos, tempSpace, spp - 1);
                        }
                            break;
                    }
                    
                }
                else if (selectedChannel == kAlphaChannel)
                {
                    switch (overlayBehaviour)
                    {
                        case kReplacingBehaviour:{
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, pData + overlayPos, spp);
                            replaceAlphaMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
                            previewData[overlayPos + spp - 1] = tempSpace[spp - 1];
                        }
                            break;
                        default:
                        {
                            unsigned char tempSpace[spp];
                            memcpy(tempSpace, pData + overlayPos, spp);
                            alphaMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
                            previewData[overlayPos + spp - 1] = tempSpace[spp - 1];
                        }
                            break;
                    }
                    
                }
            }
            else
            {
                memcpy(previewData + overlayPos, pData + overlayPos, m_nSpp);
            }
            
            //            for (int k = 0; k < spp; k++)
            //                overlay[overlayPos + k] = 0;
            replace[j * m_nWidth + i] = 0;
            
            //            if (brushAlpha == 0) {
            //                memcpy(previewData + overlayPos, pData + overlayPos, m_nSpp);
            //            }else{
            //                if (selectedChannel == kAllChannels) {
            //                    if (previewData[overlayPos + spp -1] == 0) {
            //                        memcpy(previewData + overlayPos, pData + overlayPos, m_nSpp);
            //                        //specialMergeCustom(m_nSpp, previewData, overlayPos, previewData, overlayPos, pData, overlayPos, brushAlpha);
            //                    }else{
            //                        specialMergeCustom(m_nSpp, previewData, overlayPos, previewData, overlayPos, pData, overlayPos, brushAlpha);
            //                    }
            //
            //                }else if (selectedChannel == kPrimaryChannels || floating)
            //                {
            //                    unsigned char tempSpace[spp];
            //                    memcpy(tempSpace, pData + overlayPos, spp);
            //                    primaryMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha, NO);
            //                    memcpy(previewData + overlayPos, tempSpace, spp - 1);
            //                }
            //                else if (selectedChannel == kAlphaChannel)
            //                {
            //                    unsigned char tempSpace[spp];
            //                    memcpy(tempSpace, pData + overlayPos, spp);
            //                    alphaMerge(spp, tempSpace, 0, previewData, overlayPos, brushAlpha);
            //                    previewData[overlayPos + spp - 1] = tempSpace[spp - 1];
            //                }
            //
            //            }
            
            
        }
    }
    [m_pImageData unLockDataForRead];
}


//- (void)updatePreviewDataWithEffect:(NSRect)previewRect
//{
//    NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
//
//    NSRect neededRect = [m_pLayerEffect getNeededRectForEffectOfRect:previewRect];
//    IntRect neededIntRect = NSRectMakeIntRect(neededRect);
//    neededIntRect = [self getContainedIntRectFor:neededIntRect InRect:NSRectMakeIntRect(NSMakeRect(0, 0, m_nWidth, m_nHeight))];
//
//    if (neededIntRect.size.width <= 0||neededIntRect.size.height <= 0) {
//        return ;
//    }
//
//    if (m_pImageData == NULL) return;
//
//    IMAGE_DATA data = [m_pImageData lockDataForRead];
//    unsigned char *pData = data.pBuffer;
//
//    unsigned char *realData = m_pPreviewData;
//    if (m_previewCancled)
//    {
//        realData = pData;
//    }else{
//        IntRect previewIntRect = NSRectMakeIntRect(previewRect);
//        [self addFeatherOnPreviewData:realData rect:previewIntRect];
//    }
//    NSRect effectedRect = [m_pLayerEffect getEffectedRectForEffectOfRect:previewRect];
//    effectedRect = [self getContainedRectFor:effectedRect InRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)];
//    IntRect effectedIntRect = NSRectMakeIntRect(effectedRect);
//    effectedIntRect = [self getContainedIntRectFor:effectedIntRect InRect:NSRectMakeIntRect(NSMakeRect(0, 0, m_nWidth, m_nHeight))];
//
//    if (NSEqualRects(previewRect,NSMakeRect(0, 0, m_nWidth, m_nHeight))) {
//        unsigned char *outputData = [m_pLayerEffect getEffectResultForImage:realData width:neededIntRect.size.width height:neededIntRect.size.height spp:m_nSpp distanceInfo:m_pDataDistanceInfo effectState:&m_previewEffectState scale:1.0];
//        if (outputData == NULL) {
//            [m_pImageData unLockDataForRead];
//            return;
//        }
//        unsigned char *effectData = malloc(effectedIntRect.size.width * effectedIntRect.size.height * m_nSpp);
//        for (int i = 0; i < m_nHeight; i++) {
//            memcpy(effectData + ((m_nHeight - i - 1) * m_nWidth) * m_nSpp, outputData + (i * m_nWidth) * m_nSpp, m_nWidth * m_nSpp);
//            if (m_previewEffectState == 0) {
//                free(effectData);
//                [m_pImageData unLockDataForRead];
//                return;
//            }
//        }
//        [self updateCGLayer:effectedIntRect withData:effectData];
//        [self displayPSView:effectedIntRect inThread:YES];
//        free(effectData);
//    }else{
//        unsigned char *neededData = malloc(make_128(neededIntRect.size.width * neededIntRect.size.height * m_nSpp));
//        for (int i = neededIntRect.origin.y; i < neededIntRect.origin.y + neededIntRect.size.height; i++) {
//            int srcPos = (i * m_nWidth + neededIntRect.origin.x) * m_nSpp;
//            int desPos = (i - neededIntRect.origin.y) * neededIntRect.size.width * m_nSpp;
//            memcpy(neededData + desPos, realData + srcPos, neededIntRect.size.width * m_nSpp);
//            if (m_previewEffectState == 0) {
//                free(neededData);
//                [m_pImageData unLockDataForRead];
//                return;
//            }
//        }
//
//        float *distanceInfo = (float*)malloc(neededIntRect.size.width * neededIntRect.size.height * sizeof(float));
//        for (int i = neededIntRect.origin.y; i < neededIntRect.origin.y + neededIntRect.size.height; i++) {
//            int srcPos = (i * m_nWidth + neededIntRect.origin.x);
//            int desPos = (i - neededIntRect.origin.y) * neededIntRect.size.width;
//            memcpy(distanceInfo + desPos, m_pDataDistanceInfo + srcPos, neededIntRect.size.width * sizeof(float));
//            if (m_previewEffectState == 0) {
//                free(neededData);
//                free(distanceInfo);
//                [m_pImageData unLockDataForRead];
//                return;
//            }
//        }
//        unsigned char *outputData = [m_pLayerEffect getEffectResultForImage:neededData width:neededIntRect.size.width height:neededIntRect.size.height spp:m_nSpp distanceInfo:distanceInfo effectState:&m_previewEffectState scale:1.0];
//        if (outputData == NULL) {
//            free(neededData);
//            free(distanceInfo);
//            [m_pImageData unLockDataForRead];
//            return;
//        }
//        if (m_previewEffectState == 0) {
//            free(neededData);
//            free(distanceInfo);
//            [m_pImageData unLockDataForRead];
//            return;
//        }
//
//        IntRect outputIntRect = neededIntRect;
//        unsigned char *effectData = malloc(make_128(effectedIntRect.size.width * effectedIntRect.size.height * m_nSpp));
//        for (int i = effectedIntRect.origin.y; i < effectedIntRect.origin.y + effectedIntRect.size.height; i++) {
//            int srcPos = ((i - outputIntRect.origin.y) * outputIntRect.size.width + (effectedIntRect.origin.x - outputIntRect.origin.x)) * m_nSpp;
//            int desPos = ((effectedIntRect.size.height - i + effectedIntRect.origin.y - 1) * effectedIntRect.size.width) * m_nSpp;
//            memcpy(effectData + desPos, outputData + srcPos, effectedIntRect.size.width * m_nSpp);
//
//            if (m_previewEffectState == 0) {
//                free(neededData);
//                free(distanceInfo);
//                free(effectData);
//                [m_pImageData unLockDataForRead];
//                return;
//            }
//
//        } //out to needed
//        [self updateCGLayer:effectedIntRect withData:effectData];
//        [self displayPSView:effectedIntRect inThread:NO];
//        free(neededData);
//        free(distanceInfo);
//        free(effectData);
//    }
//    [m_pImageData unLockDataForRead];
//
//    NSLog(@"effect time : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
//    //return effectedRect;
//}




#pragma mark - affine preview

- (void)updateData:(unsigned char*)newData width:(int)width height:(int)height xoffset:(int)xoffset yoffset:(int)yoffset
{
    
    m_nWidth = width;
    m_nHeight = height;
    [m_pImageData reInitDataWithBuffer:newData width:m_nWidth height:m_nHeight spp:m_nSpp  alphaPremultiplied:false];
    m_nXoff = xoffset;
    m_nYoff = yoffset;
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:YES];
    
    [self refreshTotalToRender];
}

- (void)resetLayerInfoAndDataWithWidth:(int)width height:(int)height xoffset:(int)xoffset yoffset:(int)yoffset
{
    
    m_nWidth = width;
    m_nHeight = height;
    
    [m_pImageData reInitData:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
    m_nXoff = xoffset;
    m_nYoff = yoffset;
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:YES];
    
}

- (NSColor *)backColor:(BOOL)calibrated
{
    if (calibrated)
        if ([[m_idDocument contents] spp] == 2)
            return [[[m_idDocument contents] background] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
        else
            return [[[m_idDocument contents] background] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        else
            return [[m_idDocument contents] background];
}



#pragma mark - render


- (void)render:(CGContextRef)context viewRect:(NSRect)viewRect
{
    if([self isEmpty]) return;
    
    assert(false);
 /*   float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    [m_pLayerRender renderToContext:context rect:viewRect size:CGSizeMake(xScale, yScale) mode:m_nMode alpha:m_nOpacity/255.0];
  */
}

- (void)renderToContext:(RENDER_CONTEXT_INFO)info
{
    if([self isEmpty]) return;
    
    PSView *psview = [m_idDocument docView];
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    if (xScale <= 0.001 || yScale <= 0.001)
    {
        xScale = 1.0;
        yScale = 1.0;
    }
    
    NSRect visibleRect = [psview visibleRect];
    visibleRect.origin.x /= xScale;
    visibleRect.origin.y /= yScale;
    visibleRect.size.width /= xScale;
    visibleRect.size.height /= yScale;
    
    info.rectSliceInCanvas = visibleRect;
    info.sizeScale = CGSizeMake(xScale, yScale);
    info.pointImageDataOffset = CGPointMake(m_nXoff, m_nYoff);
    
    if (info.state && *info.state == 2)
    {
        [m_pLayerRender renderToContext:info mode:kCGBlendModeCopy alpha:1.0];
    }
    else
    {
        [m_pLayerRender renderToContext:info mode:m_nMode alpha:m_nOpacity/255.0];
    }
    //[m_pLayerRender renderToContext:info mode:m_nMode alpha:m_nOpacity/255.0];
}

- (void)flatternSmartFilters
{
    if([self isEmpty])
    {
        [m_pSmartFilterManager flatternFilters];
        return;
    }
    
    unsigned char* data = malloc(make_128(m_nWidth * m_nHeight * m_nSpp));
    memset(data, 0, m_nWidth * m_nHeight * m_nSpp);
    
    CGColorSpaceRef defaultColorSpace = ((m_nSpp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    CGContextRef bitmapContext = CGBitmapContextCreate(data, m_nWidth, m_nHeight, 8, m_nSpp * m_nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    
    
    RENDER_CONTEXT_INFO info;
    info.context = bitmapContext;
    info.offset = NSMakePoint(m_nXoff, m_nYoff);
    info.scale = CGSizeMake(1.0, 1.0);
    info.refreshMode = 2;
    int state = 2;
    info.state = &state;
    [self renderToContext:info];
    
    
    unsigned char temp[m_nSpp * m_nWidth];
    int j;
    for (j = 0; j < m_nHeight / 2; j++) {
        memcpy(temp, data + (j * m_nWidth) * m_nSpp, m_nSpp * m_nWidth);
        memcpy(data + (j * m_nWidth) * m_nSpp, data + ((m_nHeight - j - 1) * m_nWidth) * m_nSpp, m_nSpp * m_nWidth);
        memcpy(data + ((m_nHeight - j - 1) * m_nWidth) * m_nSpp, temp, m_nSpp * m_nWidth);
    }
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(defaultColorSpace);
    
    unpremultiplyBitmap(m_nSpp, data, data, m_nWidth * m_nHeight);
    
    IMAGE_DATA ImageData = [m_pImageData lockDataForWrite];
    [[self seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, m_nWidth, m_nHeight) automatic:YES date:ImageData.pBuffer];
    memcpy(ImageData.pBuffer, data, m_nWidth * m_nHeight * m_nSpp);
    [m_pImageData unLockDataForWrite];
    free(data);
    
    [m_pSmartFilterManager flatternFilters];
    [self updateFullDataWithFilterAfterDataChangeInRect:NSMakeRect(0, 0, m_nWidth, m_nHeight)];
    
}



- (void)setFullRenderStateDelay:(NSNumber*)canBegin
{
    [m_pLayerRender setFullRenderState:[canBegin boolValue]];
}

- (RENDER_INFO)getCurrentRenderInfoForLayer
{
    RENDER_INFO renderInfo;
    
    renderInfo.dataImage = m_pImageData;
    renderInfo.pointImageDataOffset = CGPointMake(m_nXoff, m_nYoff);
    
    PSView *psview = [m_idDocument docView];
    //float zoom = [(PSView *)[m_idDocument docView] zoom];
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    
    if (xScale <= 0.001 || yScale <= 0.001)
    {
        xScale = 1.0;
        yScale = 1.0;
    }
    
    NSRect visibleRect = [psview visibleRect];
    
    visibleRect.origin.x /= xScale;
    visibleRect.origin.y /= yScale;
    visibleRect.size.width /= xScale;
    visibleRect.size.height /= yScale;
    renderInfo.rectSliceInCanvas = visibleRect;
    renderInfo.sizeScale = CGSizeMake(xScale, yScale);
   // renderInfo.smartFilterManager = m_pSmartFilterManager;
    renderInfo.flagModifiedType = IMAGE_FILTER_MODIFIED;
    
    return renderInfo;
}

- (void)displayRenderedInfo:(CGRect)cgrect
{
    //cgrect = NSMakeRect(0, 0, m_nWidth, m_nHeight);
    IntRect rect = NSRectMakeIntRect(cgrect);
    if (rect.size.width == 0 || (rect.size.height == 0)) return;
    if (rect.size.width == m_nWidth && rect.size.height == m_nHeight)
    {
       // wzq [[m_idDocument docView] setNeedsDisplay:YES];
        return;
    }
    
    
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    rect.origin.x += m_nXoff;
    rect.origin.y += m_nYoff;
    NSRect displayUpdateRect = IntRectMakeNSRect(rect);
    
    __block float zoom = 1.0;
    dispatch_sync(dispatch_get_main_queue(), ^{
         zoom = [(PSView *)[m_idDocument docView] zoom];
    });
    //float zoom = [(PSView *)[m_idDocument docView] zoom];
    int xres = [[m_idDocument contents] xres], yres = [[m_idDocument contents] yres];
    
    if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
    {
        displayUpdateRect.origin.x /= ((float)xres / gScreenResolution.x);
        displayUpdateRect.size.width /= ((float)xres / gScreenResolution.x);
    }
    
    if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
    {
        displayUpdateRect.origin.y /= ((float)yres / gScreenResolution.y);
        displayUpdateRect.size.height /= ((float)yres / gScreenResolution.y);
    }
    
    displayUpdateRect.origin.x *= zoom;
    displayUpdateRect.size.width *= zoom;
    displayUpdateRect.origin.y *= zoom;
    displayUpdateRect.size.height *= zoom;
    
    
    displayUpdateRect.origin.x = floor(displayUpdateRect.origin.x);
    displayUpdateRect.origin.y = floor(displayUpdateRect.origin.y);
    displayUpdateRect.size.width = ceil(displayUpdateRect.size.width) + 1.0;
    displayUpdateRect.size.height = ceil(displayUpdateRect.size.height) + 1.0;
    
    // Now do the refresh
    
    [self performSelectorOnMainThread:@selector(updateViewInMainThread:) withObject:NSStringFromRect(displayUpdateRect) waitUntilDone:NO];
    
    //    [[m_idDocument docView] setNeedsDisplayInRect:displayUpdateRect];
    //    
    //   [[m_idDocument docView] lockFocus];
    //    [NSBezierPath clipRect:displayUpdateRect];
    //    [[m_idDocument docView] drawRect:displayUpdateRect];
    //    
    //    [[m_idDocument docView] setNeedsDisplayInRect:displayUpdateRect];
    //    [[m_idDocument docView] unlockFocus];
    
}

- (void)updateViewInMainThread:(NSString*)rect
{
    [[m_idDocument docView] setNeedsDisplayInRect:NSRectFromString(rect)];
}

#pragma mark -
#pragma mark smart filter delegate

- (NSUndoManager*)getUndoManager
{
    return [m_idDocument undoManager];
}

- (void)updateSmartFilterInterface
{
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:0];
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    int nTag = [menuItem tag];
    
    if(nTag == 390)                                 return NO;        //Raster
    else if(nTag == 393)                            return NO;        //ConvertToShape
    else if (nTag >= 10000 && nTag < 17500)                           //filter
    {
        if (![self visible])                        return NO;        //不可见屏蔽
    }
    else if (nTag >= 500 && nTag < 600)             return NO;          //shape menu
    
    return YES;
}

@end
