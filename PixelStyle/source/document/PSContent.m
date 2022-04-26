#import "PSContent.h"
#import "PSLayer.h"
#import "PSTextLayer.h"
#import "PSDocument.h"
#import "UtilitiesManager.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSView.h"
#import "PSHelpers.h"
#import "PegasusUtility.h"
#import "PSLayerUndo.h"
#import "PSSelection.h"
#import "PSWhiteboard.h"
#import "CenteringClipView.h"
#import "Bitmap.h"
#import "PSWarning.h"
#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "CocoaImporter.h"
#import "XCFImporter.h"
#import "XBMImporter.h"
#import "SVGImporter.h"
#import "ToolboxUtility.h"
#import "CloneTool.h"
#import "PositionTool.h"
#import "PSTools.h"
#import "PSTransformTool.h"
#import "PSCompositor.h"
#import "StatusUtility.h"
#import "PSDocumentController.h"
#import "WDDrawingController.h"
#import "WDDrawing.h"

#import "WDLayer.h"

#include "PSFileImporter.h"

extern IntPoint gScreenResolution;
static NSString*	FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSString*	DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";

@implementation PSContent

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@"mac" forKey:@"system"];
    [aCoder encodeObject:@"" forKey:@"descrip"];
    [aCoder encodeObject:[NSNumber numberWithInt:1] forKey:@"versionMajor"];
    [aCoder encodeObject:[NSNumber numberWithInt:0] forKey:@"versionMinor"];
    
    [aCoder encodeObject:[NSNumber numberWithInt:m_nHeight] forKey:@"height"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nWidth] forKey:@"width"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nXres] forKey:@"Xres"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nYres] forKey:@"Yres"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nType] forKey:@"type"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nSelectedChannel] forKey:@"selectedChannel"];
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    [aCoder encodeObject:m_arrLayers forKey:@"layers"];
    //NSLog(@"timeendoce %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    [aCoder encodeObject:[NSNumber numberWithInt:m_nActiveLayerIndex] forKey:@"activeLayerIndex"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (!self)
    {
        return nil;
    }
    
    NSString *sSystem = [aDecoder decodeObjectForKey:@"system"];
    NSString *sDescrip = [aDecoder decodeObjectForKey:@"descrip"];
    m_nVersionMajor = [[aDecoder decodeObjectForKey:@"versionMajor"] intValue];
    m_nVersionMinor = [[aDecoder decodeObjectForKey:@"versionMinor"] intValue];
    
    if(m_nVersionMajor == 1 && m_nVersionMinor == 0) //dengyu
    {
        m_nHeight = [[aDecoder decodeObjectForKey:@"height"] intValue];
        m_nWidth = [[aDecoder decodeObjectForKey:@"width"] intValue];
        m_nXres = [[aDecoder decodeObjectForKey:@"Xres"] intValue];
        m_nYres = [[aDecoder decodeObjectForKey:@"Yres"] intValue];
        m_nType = [[aDecoder decodeObjectForKey:@"type"] intValue];
        m_nSelectedChannel = [[aDecoder decodeObjectForKey:@"selectedChannel"] intValue];
        m_arrLayers = [aDecoder decodeObjectForKey:@"layers"];
        m_nActiveLayerIndex = [[aDecoder decodeObjectForKey:@"activeLayerIndex"] intValue];
    }
    else if(m_nVersionMajor > 1 || (m_nVersionMajor == 1 && m_nVersionMinor > 0))//大于当前应用程序支持版本，提示更新版本
    {
        return NULL;
        
        m_nXres = m_nYres = 72;
        m_nHeight = m_nWidth = m_nType = 0;
        m_nSelectedChannel = kAllChannels;
        m_arrLayers = NULL;
        
        if([aDecoder decodeObjectForKey:@"height"])
            m_nHeight = [[aDecoder decodeObjectForKey:@"height"] intValue];
        if([aDecoder decodeObjectForKey:@"width"])
            m_nWidth = [[aDecoder decodeObjectForKey:@"width"] intValue];
        if([aDecoder decodeObjectForKey:@"Xres"])
            m_nXres = [[aDecoder decodeObjectForKey:@"Xres"] intValue];
        if([aDecoder decodeObjectForKey:@"Yres"])
            m_nYres = [[aDecoder decodeObjectForKey:@"Yres"] intValue];
        if([aDecoder decodeObjectForKey:@"type"])
            m_nType = [[aDecoder decodeObjectForKey:@"type"] intValue];
        if([aDecoder decodeObjectForKey:@"selectedChannel"])
            m_nSelectedChannel = [[aDecoder decodeObjectForKey:@"selectedChannel"] intValue];
        if([aDecoder decodeObjectForKey:@"layers"])
            m_arrLayers = [aDecoder decodeObjectForKey:@"layers"];
    }
    else //小于当前应用程序支持版本，查找当前版本应用的变量，若获取到，就赋值，获取不到就不赋值
    {
        m_nXres = m_nYres = 72;
        m_nHeight = m_nWidth = m_nType = 0;
        m_nSelectedChannel = kAllChannels;
        m_arrLayers = NULL;
        m_nActiveLayerIndex = 0;
        
        if([aDecoder decodeObjectForKey:@"height"])
            m_nHeight = [[aDecoder decodeObjectForKey:@"height"] intValue];
        if([aDecoder decodeObjectForKey:@"width"])
            m_nWidth = [[aDecoder decodeObjectForKey:@"width"] intValue];
        if([aDecoder decodeObjectForKey:@"Xres"])
            m_nXres = [[aDecoder decodeObjectForKey:@"Xres"] intValue];
        if([aDecoder decodeObjectForKey:@"Yres"])
            m_nYres = [[aDecoder decodeObjectForKey:@"Yres"] intValue];
        if([aDecoder decodeObjectForKey:@"type"])
            m_nType = [[aDecoder decodeObjectForKey:@"type"] intValue];
        if([aDecoder decodeObjectForKey:@"selectedChannel"])
            m_nSelectedChannel = [[aDecoder decodeObjectForKey:@"selectedChannel"] intValue];
        if([aDecoder decodeObjectForKey:@"layers"])
            m_arrLayers = [aDecoder decodeObjectForKey:@"layers"];
        if([aDecoder decodeObjectForKey:@"activeLayerIndex"])
            m_nActiveLayerIndex = [[aDecoder decodeObjectForKey:@"activeLayerIndex"] intValue];
    }
    
    
    return self;
}


- (id)initWithDocument:(id)doc
{
    // Set the data members to reasonable values
    m_nXres = m_nYres = 72;
    m_nHeight = m_nWidth = m_nType = 0;
    m_pLostprops = NULL; m_nLostpropsLen = 0;
    m_psParasites = NULL; m_nParasitesCount = 0;
    m_dicExifData = NULL;
    m_arrLayers = NULL; m_nActiveLayerIndex = 0;
    m_maLayersToUndo = [[NSMutableArray array] retain];
    m_maLayersToRedo = [[NSMutableArray array] retain];
    m_maOrderings = [[NSMutableArray array] retain];
    m_arrDeletedLayers = [[NSMutableArray alloc] init];
    m_nSelectedChannel = kAllChannels; m_bTrueView = NO;
    m_bCMYKSave = NO;
    m_sKeeper = allocKeeper();
    m_idDocument = doc;
    
    m_drawingController = [[WDDrawingController alloc] init];
    m_drawing = [[WDDrawing alloc] initWithSize:CGSizeMake(m_nWidth, m_nHeight) andUnits:nil];
    m_drawing.undoManager = [m_idDocument undoManager];
    m_drawingController.drawing = m_drawing;
    [self addNotificationObeserver];
    
    return self;
}

- (id)initFromPasteboardWithDocument:(id)doc
{
    id pboard = [NSPasteboard generalPasteboard];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    int sspp, dspp, space;
    id profile;
    CMProfileLocation cmProfileLoc;
    int bipp, bypr, bps;
    unsigned char *data;
    
    // Get the data from the pasteboard
    imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
    if (imageRepDataType == NULL)
    {
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSPICTPboardType]];
        imageRepData = [pboard dataForType:imageRepDataType];
        image = [[NSImage alloc] initWithData:imageRepData];
        imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        [image autorelease];
    }
    else
    {
        imageRepData = [pboard dataForType:imageRepDataType];
        imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
    }
    
    // Fill out as many of the properties as possible
    m_nHeight = [imageRep pixelsHigh];
    m_nWidth = [imageRep pixelsWide];
    m_nXres = m_nYres = 72;
    m_pLostprops = NULL; m_nLostpropsLen = 0;
    m_psParasites = NULL; m_nParasitesCount = 0;
    m_dicExifData = NULL;
    m_maLayersToUndo = [[NSMutableArray array] retain];
    m_maLayersToRedo = [[NSMutableArray array] retain];
    m_maOrderings = [[NSMutableArray array] retain];
    m_arrDeletedLayers = [[NSMutableArray alloc] init];
    m_nSelectedChannel = kAllChannels; m_bTrueView = NO;
    m_bCMYKSave = NO;
    m_sKeeper = allocKeeper();
    m_idDocument = doc;
    
    // Determine the color space of the pasteboard image and the type
    space = -1;
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
    {
        space = kGrayColorSpace;
        m_nType = XCF_GRAY_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
    {
        space = kInvertedGrayColorSpace;
        m_nType = XCF_GRAY_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
    {
        space = kRGBColorSpace;
        m_nType = XCF_RGB_IMAGE;
    }
    if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
    {
        space = kCMYKColorSpace;
        m_nType = XCF_RGB_IMAGE;
    }
    if (space == -1)
    {
        NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
        return NULL;
    }
    
    m_nType = XCF_RGB_IMAGE;  //add by lcz
    
    // Extract color profile
    //    assert(false);     //modify by wyl
    profile = NULL;//[imageRep valueForProperty:NSImageColorSyncProfileData];
    /*	if (profile) {
     cmProfileLoc.locType = cmPtrBasedProfile;
     cmProfileLoc.u.ptrLoc.p = (Ptr)[profile bytes];
     }
     */
    // Put it in a nice form
    sspp = [imageRep samplesPerPixel];
    bps = [imageRep bitsPerSample];
    bipp = [imageRep bitsPerPixel];
    bypr = [imageRep bytesPerRow];
    if (m_nType == XCF_RGB_IMAGE)
        dspp = 4;
    else
        dspp = 2;
    //	data = convertBitmap(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], nWidth, nHeight, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, 0);
    data = convertBitmap(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], m_nWidth, m_nHeight, sspp, bipp, bypr, space,  NULL, bps, 0);
    if (!data)
    {
        NSLog(@"Required conversion not supported.");
        [imageRep autorelease];
        return NULL;
    }
    unpremultiplyBitmap(dspp, data, data, m_nWidth * m_nHeight);
    [imageRep autorelease];
    
    // Add layer
    m_arrLayers = [[NSMutableArray alloc] initWithObjects:[[PSLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, m_nWidth, m_nHeight) data:data spp:dspp], NULL];
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    m_drawingController = [[WDDrawingController alloc] init];
    m_drawing = [[WDDrawing alloc] initWithSize:CGSizeMake(m_nWidth, m_nHeight) andUnits:nil];
    m_drawingController.drawing = m_drawing;
    
    return self;
}

- (id)initWithDocument:(id)doc type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres opaque:(BOOL)dopaque
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    // Set the data members to appropriate values
    m_nXres = m_nYres = dres;
    m_nType = dtype;
    m_nHeight = dheight; m_nWidth = dwidth;
    
    // Add in a single layer
    m_arrLayers = [[NSMutableArray alloc] initWithObjects:[[PSLayer alloc] initWithDocument:doc width:dwidth height:dheight opaque:dopaque spp:[self spp]], NULL];
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    return self;
}

- (id)initWithDocument:(id)doc data:(unsigned char *)ddata type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres
{
    // Call the core initializer
    if (![self initWithDocument:doc])
        return NULL;
    
    // Set the data members to appropriate values
    m_nXres = m_nYres = dres;
    m_nType = dtype;
    m_nHeight = dheight; m_nWidth = dwidth;
    
    // Add in a single layer
    m_arrLayers = [[NSMutableArray alloc] initWithObjects:[[PSLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, dwidth, dheight) data:ddata spp:(dtype == XCF_RGB_IMAGE) ? 4 : 2], NULL];
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    return self;
}

- (void)dealloc
{
    int i;
    
    freeKeeper(&m_sKeeper);
    if (m_psParasites)
    {
        for (i = 0; i < m_nParasitesCount; i++)
        {
            [m_psParasites[i].name autorelease];
            free(m_psParasites[i].data);
        }
        free(m_psParasites);
    }
    
    if (m_dicExifData) [m_dicExifData autorelease];
    if (m_pLostprops) free(m_pLostprops);
    if (m_arrLayers)
    {
        for (i = 0; i < [m_arrLayers count]; i++)
        {
            //NSLog(@"count %ld",[[m_arrLayers objectAtIndex:i] retainCount]);
            [[m_arrLayers objectAtIndex:i] release];
            //
            //            //[[m_arrLayers objectAtIndex:i] release];
            //            //NSLog(@"count %ld",[[m_arrLayers objectAtIndex:i] retainCount]);
        }
        //        [m_arrLayers removeAllObjects];
        [m_arrLayers release];
        
    }
    
    if (m_maLayersToUndo)
    {
        for (i = 0; i < [m_maLayersToUndo count]; i++)
        {
            [[m_maLayersToUndo objectAtIndex:i] autorelease];
        }
        [m_maLayersToUndo autorelease];
    }
    
    if (m_maLayersToRedo)
    {
        for (i = 0; i < [m_maLayersToRedo count]; i++)
        {
            [[m_maLayersToRedo objectAtIndex:i] autorelease];
        }
        [m_maLayersToRedo autorelease];
    }
    
    if (m_arrDeletedLayers)
    {
        for (i = 0; i < [m_arrDeletedLayers count]; i++)
        {
            [[m_arrDeletedLayers objectAtIndex:i] autorelease];
        }
        //        [m_arrDeletedLayers removeAllObjects];
        [m_arrDeletedLayers autorelease];
    }
    
    if(m_maOrderings)
    {
        for (i = 0; i < [m_maOrderings count]; i++)
        {
            [[m_maOrderings objectAtIndex:i] autorelease];
        }
        [m_maOrderings autorelease];
    }
    
    if(m_drawing) [m_drawing release];
    if(m_drawingController) [m_drawingController release];
    
    //移除obsersver
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)shutdown
{
    if (m_arrLayers)
    {
        for (int i = 0; i < [m_arrLayers count]; i++)
        {
            [[m_arrLayers objectAtIndex:i] shutdown];
        }
    }
}

- (void)addNotificationObeserver
{
    NSNotificationCenter    *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(LayerContentsChanged:) name:@"WDLayerContentsChangedNotification" object:nil];
    
    NSArray *invalidations = @[WDElementChanged,
                               WDDrawingChangedNotification,
                               WDLayersReorderedNotification,
                               WDLayerAddedNotification,
                               WDLayerDeletedNotification,
                               WDIsolateActiveLayerSettingChangedNotification,
                               WDOutlineModeSettingChangedNotification,
                               WDLayerContentsChangedNotification,
                               WDLayerVisibilityChanged,
                               WDLayerOpacityChanged];
    
    [self registerInvalidateNotifications:invalidations];
}

- (void) registerInvalidateNotifications:(NSArray *)array
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    for (NSString *name in array)
    {
        [nc addObserver:self
               selector:@selector(invalidateFromNotification:)
                   name:name
                 object:nil];
    }
}

- (void) invalidateFromNotification:(NSNotification *)aNotification
{
    //    NSValue     *rectValue = [aNotification userInfo][@"rect"];
    //    NSArray     *rects = [aNotification userInfo][@"rects"];
    
    WDLayer *wdlayer = [aNotification userInfo][@"layer"];
    PSVecLayer *vecLayer = (PSVecLayer*)(wdlayer.layerDelegate);
    if ([vecLayer document] != m_idDocument)
    {
        return;
    }
    
    if (wdlayer && vecLayer)
    {
        [vecLayer invalidData];
        [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    }
    //NSLog(@"LayerContentsChanged");
    //[[m_idDocument docView] setNeedsDisplay:YES];
    
}


- (void)LayerContentsChanged:(NSNotification*)sender
{
    
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    id layer;
    int i;
    
    // Change the width and height of the document
    m_nWidth += left + right;
    m_nHeight += top + bottom;
    
    //[[m_idDocument docView] setNeedsDisplay:YES];
    [[m_idDocument docView] readjust:NO];
    // Change the layer offsets of the document
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        layer = [m_arrLayers objectAtIndex:i];
        //		if (left) [layer setOffsets:IntMakePoint([layer xoff] + left, [layer yoff])];
        //		if (top) [layer setOffsets:IntMakePoint([layer xoff], [layer yoff] + top)];
        if (left || top)
        {
            [layer setOffsets:IntMakePoint([layer xoff] + left, [layer yoff] + top)];
        }
    }
    
    [[m_idDocument selection] adjustOffset:IntMakePoint(left, top)];
}

- (WDDrawingController *)wdDrawingController
{
    return m_drawingController;
}

- (int)versionMajor
{
    return m_nVersionMajor;
}

- (int)versionMinor
{
    return m_nVersionMinor;
}

- (int)type
{
    return m_nType;
}

- (int)spp
{
    int result = 0;
    
    switch (m_nType)
    {
        case XCF_RGB_IMAGE:
            result = 4;
            break;
        case XCF_GRAY_IMAGE:
            result = 2;
            break;
        default:
            NSLog(@"Document type not recognised by spp");
            break;
    }
    
    return result;
}

- (int)xres
{
    return m_nXres;
}

- (int)yres
{
    return m_nYres;
}

- (float)xscale
{
    float xscale = [[m_idDocument docView] zoom];
    
    if (gScreenResolution.x != 0 && m_nXres != gScreenResolution.x)
        xscale /= ((float)m_nXres / (float)gScreenResolution.x);
    
    return xscale;
}

- (float)yscale
{
    float yscale = [[m_idDocument docView] zoom];
    
    if (gScreenResolution.y != 0 && m_nYres != gScreenResolution.y)
        yscale /= ((float)m_nYres / (float)gScreenResolution.y);
    
    return yscale;
}

- (void)setResolution:(IntResolution)newRes
{
    m_nXres = newRes.x;
    m_nYres = newRes.y;
}

- (int)height
{
    return m_nHeight;
}

- (int)width
{
    return m_nWidth;
}

- (void)setWidth:(int)newWidth height:(int)newHeight
{
    m_nWidth = newWidth;
    m_nHeight = newHeight;
}

- (int)selectedChannel
{
    return [(PSAbstractLayer*)[self activeLayer] selectedChannelOfLayer];
    //return m_nSelectedChannel;
}

- (void)setSelectedChannel:(int)value;
{
    m_nSelectedChannel = value;
}

- (char *)lostprops
{
    return m_pLostprops;
}

- (int)lostprops_len
{
    return m_nLostpropsLen;
}

- (ParasiteData *)parasites
{
    return m_psParasites;
}

- (int)parasites_count
{
    return m_nParasitesCount;
}

- (ParasiteData *)parasiteWithName:(NSString *)name
{
    int i;
    
    for (i = 0; i < m_nParasitesCount; i++)
    {
        if ([name isEqualToString:m_psParasites[i].name])
            return &(m_psParasites[i]);
    }
    
    return NULL;
}

- (void)deleteParasiteWithName:(NSString *)name
{
    int i, x;
    
    // Find the parasite to delete
    x = -1;
    for (i = 0; i < m_nParasitesCount && x == -1; i++)
    {
        if ([name isEqualToString:m_psParasites[i].name])
            x = i;
    }
    
    if (x != -1)
    {
        
        // Destroy it
        [m_psParasites[x].name autorelease];
        free(m_psParasites[x].data);
        
        // Update the parasites list
        m_nParasitesCount--;
        if (m_nParasitesCount > 0)
        {
            for (i = x; i < m_nParasitesCount; i++)
            {
                m_psParasites[i] = m_psParasites[i + 1];
            }
            m_psParasites = realloc(m_psParasites, sizeof(ParasiteData) * m_nParasitesCount);
        }
        else
        {
            free(m_psParasites);
            m_psParasites = NULL;
        }
        
    }
}

- (void)addParasite:(ParasiteData)parasite
{
    // Delete existing parasite with the same name (if any)
    [self deleteParasiteWithName:parasite.name];
    
    // Add parasite
    m_nParasitesCount++;
    if (m_nParasitesCount == 1) m_psParasites = malloc(sizeof(ParasiteData) * m_nParasitesCount);
    else m_psParasites = realloc(m_psParasites, sizeof(ParasiteData) * m_nParasitesCount);
    m_psParasites[m_nParasitesCount - 1] = parasite;
}

- (BOOL)trueView
{
    return m_bTrueView;
}

- (void)setTrueView:(BOOL)value
{
    m_bTrueView = value;
}

- (NSColor *)foreground
{
    id foreground;
    
    foreground = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] foreground];
    if (m_nType == XCF_RGB_IMAGE && m_nSelectedChannel != kAlphaChannel)
        return [foreground colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    else if (m_nType == XCF_GRAY_IMAGE)
        return [foreground colorUsingColorSpaceName:NSDeviceWhiteColorSpace];
    else
        return [[foreground colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

- (NSColor *)background
{
    id background;
    
    background = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] background];
    
    if (m_nType == XCF_RGB_IMAGE && m_nSelectedChannel != kAlphaChannel)
        return [background colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    else if (m_nType == XCF_GRAY_IMAGE)
        return [background colorUsingColorSpaceName:NSDeviceWhiteColorSpace];
    else
        return [[background colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

- (void)setCMYKSave:(BOOL)value
{
    m_bCMYKSave = value;
}

- (BOOL)cmykSave
{
    return m_bCMYKSave;
}

- (NSDictionary *)exifData
{
    return m_dicExifData;
}

- (id)layer:(int)index
{
    return [m_arrLayers objectAtIndex:index];
}

- (int)layerCount
{
    return [m_arrLayers count];
}

- (int)layerIndex:(id)layer
{
    //-1 not found
    NSUInteger index = [m_arrLayers indexOfObject:layer];
    if (index == NSNotFound)
    {
        return -1;
    }
    return index;
}

- (id)activeLayer
{
    return (m_nActiveLayerIndex < 0) ? NULL : [m_arrLayers objectAtIndex:m_nActiveLayerIndex];
}

- (int)activeLayerIndex
{
    return m_nActiveLayerIndex;
}

//- (void)setActiveLayerIndex:(int)value
//{
//	m_nActiveLayerIndex = value;
//}

- (void)setActiveLayerIndexComplete:(int)value
{
    [[m_idDocument helpers] activeLayerWillChange];
    m_nActiveLayerIndex = value;
    
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    PSAbstractLayer *player = [self layer:m_nActiveLayerIndex];
    [player setLinked:YES];
    [[m_idDocument helpers] activeLayerChanged:kLayerSwitched rect:NULL];
}

- (void)layerBelow
{
    //    if(m_nActiveLayerIndex >= [self layerCount] - 1) return;
    
    int newIndex;
    if(m_nActiveLayerIndex + 1 >= [self layerCount])
    {
        newIndex = 0;
    }
    else
    {
        newIndex = m_nActiveLayerIndex + 1;
        //        newIndex = m_nActiveLayerIndex + 2;
    }
    
    //    [self moveLayerOfIndex:m_nActiveLayerIndex toIndex:newIndex];
    //    [self setActiveLayerIndexComplete:newIndex-1];
    [self setActiveLayerIndexComplete:newIndex];
    //    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)layerAbove
{
    //    if(m_nActiveLayerIndex <= 0) return;
    int newIndex;
    if(m_nActiveLayerIndex - 1 < 0)
    {
        newIndex = [self layerCount] - 1;
        //        newIndex = [self layerCount] - 1 + 1;
    }
    else
    {
        newIndex = m_nActiveLayerIndex - 1;
    }
    //    [self moveLayerOfIndex:m_nActiveLayerIndex toIndex:newIndex];
    
    [self setActiveLayerIndexComplete:newIndex];
    //    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)fillQuick
{
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width], height = [(PSLayer *)layer height];
    int spp = [(PSLayer *)layer spp];
    int channel = [self selectedChannel];
    
    unsigned char aBasePixel[4];
    if (spp == 4)
    {
        NSColor* color = [[m_idDocument contents] foreground];
        aBasePixel[0] = (unsigned char)([color redComponent] * 255.0);
        aBasePixel[1] = (unsigned char)([color greenComponent] * 255.0);
        aBasePixel[2] = (unsigned char)([color blueComponent] * 255.0);
        aBasePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
        if(channel == kAlphaChannel)
            aBasePixel[3] = ((int)aBasePixel[0]*30 + (int)aBasePixel[1]*59 + (int)aBasePixel[2]*11)/100;
    }
    else
    {
        NSColor* color = [[m_idDocument contents] foreground];
        aBasePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
        aBasePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
    }
    
    IntRect selectRect = [[m_idDocument selection] localRect];
    unsigned char *mask = [(PSSelection*)[m_idDocument selection] mask];
    IntPoint maskOffset = [[m_idDocument selection] maskOffset];
    IntPoint trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
    IntSize maskSize = [[m_idDocument selection] maskSize];
    BOOL useSelection = [[m_idDocument selection] active];
    unsigned char *layerData = [layer getRawData];
    
    
    if (useSelection)
    {
        [[layer seaLayerUndo] takeSnapshot:selectRect automatic:YES];
        
        selectRect = IntConstrainRect(selectRect, IntMakeRect(0, 0, width, height));
        for (int j = selectRect.origin.y; j < selectRect.origin.y + selectRect.size.height; j++)
        {
            for (int i = selectRect.origin.x; i < selectRect.origin.x + selectRect.size.width; i++)
            {
                int position = (j * width + i) * spp;
                int brushAlpha = 0;
                IntPoint tempPoint;
                tempPoint.x = i;
                tempPoint.y = j;
                if (mask)
                    brushAlpha = mask[(trueMaskOffset.y + tempPoint.y) * maskSize.width + (trueMaskOffset.x + tempPoint.x)];
                if (brushAlpha > 0)
                {
                    if(channel != kAlphaChannel)
                        specialMergeCustom(spp, layerData, position, aBasePixel, 0, layerData, position, brushAlpha);
                    else
                    {
                        replaceAlphaMerge(spp, layerData, position, aBasePixel, 0, 255);
                    }
                }
                
            }
        }
        
    }
    else
    {
        [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, width, height) automatic:YES];
        for (int j = 0; j < height; j++)
        {
            for (int i = 0; i < width; i++)
            {
                int position = (j * width + i) * spp;
                //memcpy(layerData + position, aBasePixel, spp);
                if(channel != kAlphaChannel)
                    specialMergeCustom(spp, layerData, position, aBasePixel, 0, layerData, position, 255);
                else
                    replaceAlphaMerge(spp, layerData, position, aBasePixel, 0, 255);
            }
        }
    }
    
    [layer unLockRawData];
    [layer refreshTotalToRender];
}

- (BOOL)canImportLayerFromFile:(NSString *)path
{
    NSString *docType;
    BOOL success = NO;
    
    // Determine which document we have and act appropriately
    docType = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                (CFStringRef)[path pathExtension],
                                                                (CFStringRef)@"public.data");
    
//    BOOL pluginSupport = NO;
//    int count = 0;
//    char** types = plugin_GetAllSupportedTypes(&count);
//    for (int i = 0; i < count; i++) {
//        BOOL equal = [[[path pathExtension] uppercaseString] isEqualToString:[[NSString stringWithUTF8String:types[i]] uppercaseString]];
//        if (equal) {
//            pluginSupport = YES;
//            break;
//        }
//    }
//    if (count > 0 && types != NULL) {
//        for (int i = 0; i < count; i++) {
//            free(types[i]);
//        }
//        free(types);
//    }
    
    BOOL pluginSupport = NO;
    NSMutableArray *types = [(PSDocumentController*)[NSDocumentController sharedDocumentController] importerPluginSupportedTypes];
    int count = [types count];
    for (int i = 0; i < count; i++) {
        BOOL equal = [[[path pathExtension] uppercaseString] isEqualToString:[types[i] uppercaseString]];
        if (equal) {
            pluginSupport = YES;
            break;
        }
    }
    
    
    success = [XCFContent typeIsEditable:docType] ||
    [XBMContent typeIsEditable:docType] ||
    [CocoaContent typeIsViewable:docType forDoc: m_idDocument] ||
    [SVGContent typeIsViewable:docType] || pluginSupport;
    
    [docType release];
    
    return success;
}


- (BOOL)importLayerFromFile:(NSString *)path
{
    NSString *docType;
    BOOL success = NO;
    id importer;
    
    docType = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                (CFStringRef)[path pathExtension],
                                                                (CFStringRef)@"public.data");
    
    if ([XCFContent typeIsEditable:docType])
    {
        
        // Load GIMP or XCF layers
        importer = [[XCFImporter alloc] init];
        success = [importer addToDocument:m_idDocument contentsOfFile:path];
        [importer autorelease];
        
    }
    else if ([CocoaContent typeIsViewable:docType forDoc: m_idDocument])
    {
        
        // Load PNG, TIFF, JPEG, GIF and other layers
        importer = [[CocoaImporter alloc] init];
        success = [importer addToDocument:m_idDocument contentsOfFile:path];
        [importer autorelease];
        
        if(success)
        {
            ToolboxUtility *toolUtility = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
            if(toolUtility)
            {
                [toolUtility switchToolWithToolIndex:kTransformTool];
                
                id toolTransform = [[m_idDocument tools] getTool:kTransformTool];
                
                if([toolTransform isKindOfClass:[PSTransformTool class]])
                [(PSTransformTool *)[[m_idDocument tools] getTool:kTransformTool] autoTransformKeepRatio];
            }
        
        }
    }
    else if ([XBMContent typeIsEditable:docType])
    {
        
        // Load X bitmap layers
        importer = [[XBMImporter alloc] init];
        success = [importer addToDocument:m_idDocument contentsOfFile:path];
        [importer autorelease];
        
        
    }
    else if ([SVGContent typeIsViewable:docType])
    {
        
        // Load SVG layers
        importer = [[SVGImporter alloc] init];
        success = [importer addToDocument:m_idDocument contentsOfFile:path];
        [importer autorelease];
        
        
    }
    else
    {
        int result = plugin_ImportImageToDocument([path UTF8String], m_idDocument);
        if (result == 0) {
            success = YES;
            if(success)
            {
                ToolboxUtility *toolUtility = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
                if(toolUtility)
                {
                    [toolUtility switchToolWithToolIndex:kTransformTool];
                    
                    id toolTransform = [[m_idDocument tools] getTool:kTransformTool];
                    
                    if([toolTransform isKindOfClass:[PSTransformTool class]])
                        [(PSTransformTool *)[[m_idDocument tools] getTool:kTransformTool] autoTransformKeepRatio];
                }
                
            }
        }else if (result == -1){
            // Handle an unknown document type
            NSLog(@"Unknown type passed to importLayerFromFile:<%@> docType:<%@>", path, docType);
            success = NO;
        }
        
//        // Handle an unknown document type
//        NSLog(@"Unknown type passed to importLayerFromFile:<%@> docType:<%@>", path, docType);
//        success = NO;
        
    }
    
    
    
    // Inform the user of failure
    if (!success)
    {
        [[PSController seaWarning] addMessage:LOCALSTR(@"import failure message", @"The selected file was not able to be successfully imported into this document.") forDocument:m_idDocument level:kHighImportance];
    }
    
    [docType release];
    
    return success;
}

- (void)importPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    //NSArray *filenames = [panel filenames];
    NSArray *fileUrls = [panel URLs];
    int i;
    
    if (returnCode == NSOKButton)
    {
        for (i = 0; i < [fileUrls count]; i++)
        {
            [self importLayerFromFile:[[fileUrls objectAtIndex:i] path]];
        }
    }
}

- (void)importLayer
{
    // Run import dialog
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    NSArray *types = [(PSDocumentController*)[NSDocumentController sharedDocumentController] readableTypes];
    [openPanel beginSheetForDirectory:NULL file:NULL types:types modalForWindow:[m_idDocument window] modalDelegate:self didEndSelector:@selector(importPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addVectorLayer:(int)index
{
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    NSArray *tempArray = [NSArray array];
    int i;
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    
    // Create a new array with all the existing layers and the one being added
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:[[PSVecLayer alloc] initWithDocument:m_idDocument width:m_nWidth height:m_nHeight opaque:NO spp:[self spp]]];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    
}

- (void)addTextLayer:(int)index  atPoint:(CGPoint)point
{
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    NSArray *tempArray = [NSArray array];
    int i;
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    
    // Create a new array with all the existing layers and the one being added
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:[[PSTextLayer alloc] initWithDocument:m_idDocument width:m_nWidth height:m_nHeight opaque:NO spp:[self spp] atPoint:point]];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    
}

- (void)addLayer:(int)index
{
    
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    NSArray *tempArray = [NSArray array];
    int i;
    
    if([[m_idDocument selection] floating])
    {
        unsigned char *data;
        int spp = [self spp];
        IntRect dataRect;
        id layer;
        
        // Save the existing selection
        layer = [m_arrLayers objectAtIndex:m_nActiveLayerIndex];
        dataRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);;
        data = malloc(make_128(dataRect.size.width * dataRect.size.height * spp));
        memcpy(data, [(PSLayer *)layer getRawData], dataRect.size.width * dataRect.size.height * spp);
        [(PSLayer *)layer unLockRawData];
        
        // Delete the floating layer
        [self deleteLayer:m_nActiveLayerIndex];
        
        // Clear the selection
        [[m_idDocument selection] clearSelection];
        
        // Inform the helpers we will change the layer
        [[m_idDocument helpers] activeLayerWillChange];
        
        // Create a new array with all the existing layers and the one being added
        layer = [[PSLayer alloc] initWithDocument:m_idDocument rect:dataRect data:data spp:spp];
        for (i = 0; i < [m_arrLayers count] + 1; i++)
        {
            if (i == m_nActiveLayerIndex)
                tempArray = [tempArray arrayByAddingObject:layer];
            else
                tempArray = [tempArray arrayByAddingObject:(i > m_nActiveLayerIndex) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
        }
        
        // Now substitute in our new array
        [m_arrLayers autorelease];
        [tempArray retain];
        m_arrLayers = tempArray;
        
        [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
        
        // Inform document of layer change
        [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&dataRect];
        
        [[m_idDocument docView] resetSynthesizedImageRender];
        
        // Make action undoable
        [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:m_nActiveLayerIndex];
    }
    else
    {
        
        // Inform the helpers we will change the layer
        [[m_idDocument helpers] activeLayerWillChange];
        
        // Correct index
        if (index == kActiveLayer) index = m_nActiveLayerIndex;
        
        // Create a new array with all the existing layers and the one being added
        for (i = 0; i < [m_arrLayers count] + 1; i++)
        {
            if (i == index){
                //初始化小一些
//                tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocument:m_idDocument width:m_nWidth height:m_nHeight opaque:NO spp:[self spp]]];
                tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocument:m_idDocument width:10 height:10 opaque:NO spp:[self spp]]];
            }
            else
                tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
        }
        
        // Now substitute in our new array
        [m_arrLayers autorelease];
        [tempArray retain];
        m_arrLayers = tempArray;
        
        [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
        
        // Inform document of layer change
        [[m_idDocument helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
        
        [[m_idDocument docView] resetSynthesizedImageRender];
        
        // Make action undoable
        [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    }
}

- (void)addLayerObject:(id)layer
{
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    NSArray *tempArray = [NSArray array];
    int i, index;
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Find index
    index = m_nActiveLayerIndex;
    
    // Create a new array with all the existing layers and the one being added
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == index)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)addLayerFromPasteboard:(id)pboard centerPointInCanvas:(NSPoint)centerPoint
{
    NSString *dataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:SEA_LAYER_PBOARD_TYPE]];
    NSData *data = [pboard dataForType:dataType];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *arrDraggedLayers = [unarchiver decodeObjectForKey:@"draggedLayers"];
    [unarchiver finishDecoding];
    
    for(id layer in arrDraggedLayers)
    {
        //        IntPoint offset;
        //        offset.x = centerPoint.x - [(PSAbstractLayer *)layer width]/2.0;
        //        offset.y = centerPoint.y - [(PSAbstractLayer *)layer height]/2.0;
        //        [(PSAbstractLayer *)layer setOffsets:offset];
        
        
        for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
        {
            PSAbstractLayer *pLayer = [self layer:nIndex];
            [pLayer setLinked:NO];
        }
        NSArray *tempArray = [NSArray array];
        int i, index;
        
        // Inform the helpers we will change the layer
        [[m_idDocument helpers] activeLayerWillChange];
        
        // Create a new array with all the existing layers and the one being added
        index = m_nActiveLayerIndex;
        for (i = 0; i < [m_arrLayers count] + 1; i++)
        {
            if (i == index)
            {
                if([layer layerFormat] == PS_TEXT_LAYER)
                    tempArray = [tempArray arrayByAddingObject:[[PSTextLayer alloc] initWithDocumentAfterCoder:m_idDocument layer:layer]];
                else if([layer layerFormat] == PS_VECTOR_LAYER)
                    tempArray = [tempArray arrayByAddingObject:[[PSVecLayer alloc] initWithDocumentAfterCoder:m_idDocument layer:layer]];
                else
                    tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocumentAfterCoder:m_idDocument layer:layer]];
            }
            
            else
                tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
        }
        
        // Now substitute in our new array
        [m_arrLayers autorelease];
        [tempArray retain];
        m_arrLayers = tempArray;
        
        [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
        
        // Inform document of layer change
        [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:NULL];
        
        [[m_idDocument docView] resetSynthesizedImageRender];
        
        // Make action undoable
        [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    }
    
    [arrDraggedLayers release];
}



- (void)copyLayer:(id)layer
{
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    NSArray *tempArray = [NSArray array];
    int i, index;
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    index = m_nActiveLayerIndex;
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == index)
        {
            if([layer layerFormat] == PS_TEXT_LAYER)
                tempArray = [tempArray arrayByAddingObject:[[PSTextLayer alloc] initWithDocument:m_idDocument layer:layer]];
            else if([layer layerFormat] == PS_VECTOR_LAYER)
                tempArray = [tempArray arrayByAddingObject:[[PSVecLayer alloc] initWithDocument:m_idDocument layer:layer]];
            else
                tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocument:m_idDocument layer:layer]];
        }
        else
            tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:NULL];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}


- (void)duplicateLayer:(int)index
{
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    int nMinLinkedLayerIndex = [self minlinkedLayerIndex];
    NSMutableArray *linkedLayerIndexes = [[self linkedLayersIndexs] retain];
    
    int nActiveLayer = m_nActiveLayerIndex;
    for(int nIndex = 0; nIndex < [linkedLayerIndexes count]; nIndex++)
    {
        int nFromIndex = [[linkedLayerIndexes objectAtIndex:nIndex] intValue] + nIndex;
        
        [self duplicateLayer:nFromIndex toIndex:nMinLinkedLayerIndex+nIndex];
        
        if(nActiveLayer == [[linkedLayerIndexes objectAtIndex:nIndex] intValue])
            nActiveLayer = nIndex + nMinLinkedLayerIndex;
    }
    
    m_nActiveLayerIndex = nActiveLayer;
    
    [self clearAllLinks];
    for(int nIndex = 0; nIndex < [linkedLayerIndexes count]; nIndex++)
        [self setLinked:YES forLayer:nMinLinkedLayerIndex+nIndex];
    
    [linkedLayerIndexes release];
    
    // Inform document of layer change
    index = m_nActiveLayerIndex;
    IntRect rect = IntMakeRect([[m_arrLayers objectAtIndex:index] xoff], [[m_arrLayers objectAtIndex:index] yoff], [(PSLayer *)[m_arrLayers objectAtIndex:index] width], [(PSLayer *)[m_arrLayers objectAtIndex:index] height]);
    [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&rect];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)duplicateLayer:(int)nFromIndex toIndex:(int)nToIndex
{
    NSArray *tempArray = [NSArray array];
    
    // Create a new array with all the existing layers and the one being added
    for (int nIndex = 0; nIndex < [m_arrLayers count] + 1; nIndex++)
    {
        if(nIndex < nToIndex)
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:nIndex]];
        else if (nIndex == nToIndex)
        {
            PSAbstractLayer *layer = [m_arrLayers objectAtIndex:nFromIndex];
            
            if([layer layerFormat] == PS_RASTER_LAYER)
                tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocument:m_idDocument layer:[m_arrLayers objectAtIndex:nFromIndex]]];
            else if([layer layerFormat] == PS_TEXT_LAYER)
                tempArray = [tempArray arrayByAddingObject:[[PSTextLayer alloc] initWithDocument:m_idDocument layer:[m_arrLayers objectAtIndex:nFromIndex]]];
            else if([layer layerFormat] == PS_VECTOR_LAYER)
                tempArray = [tempArray arrayByAddingObject:[[PSVecLayer alloc] initWithDocument:m_idDocument layer:[m_arrLayers objectAtIndex:nFromIndex]]];
            else assert(false);
        }
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:nIndex - 1]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:nToIndex];
}

//- (void)duplicateLayer:(int)index
//{
//    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
//    {
//        PSAbstractLayer *layer = [self layer:nIndex];
//        [layer setLinked:NO];
//    }
//
//	NSArray *tempArray = [NSArray array];
//	IntRect rect;
//	int i;
//
//	// Inform the helpers we will change the layer
//	[[m_idDocument helpers] activeLayerWillChange];
//
//	// Correct index
//	if (index == kActiveLayer) index = m_nActiveLayerIndex;
//
//	// Create a new array with all the existing layers and the one being added
//	for (i = 0; i < [m_arrLayers count] + 1; i++) {
//		if (i == index)
//        {
//            PSLayer *layer = [m_arrLayers objectAtIndex:index];
//
//            if([layer layerFormat] == PS_RASTER_LAYER)
//                tempArray = [tempArray arrayByAddingObject:[[PSLayer alloc] initWithDocument:m_idDocument layer:[m_arrLayers objectAtIndex:index]]];
//            else if([layer layerFormat] == PS_TEXT_LAYER)
//                tempArray = [tempArray arrayByAddingObject:[[PSTextLayer alloc] initWithDocument:m_idDocument layer:[m_arrLayers objectAtIndex:index]]];
//            else assert(false);
//
//        }
//		else
//			tempArray = [tempArray arrayByAddingObject:(i > index) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
//	}
//
//	// Now substitute in our new array
//	[m_arrLayers autorelease];
//	[tempArray retain];
//	m_arrLayers = tempArray;
//
//	// Inform document of layer change
//	rect = IntMakeRect([[m_arrLayers objectAtIndex:index] xoff], [[m_arrLayers objectAtIndex:index] yoff], [(PSLayer *)[m_arrLayers objectAtIndex:index] width], [(PSLayer *)[m_arrLayers objectAtIndex:index] height]);
//	[[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&rect];
//
//	// Make action undoable
//	[(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
//}

- (void)deleteLayer
{
    if ([self layerCount] <= 1)
    {
        return;
    }
    
    NSMutableArray *linkedLayersIndexs = [self linkedLayersIndexs];
    if([linkedLayersIndexs count] == [self layerCount]) return;
    
    for (int i = [linkedLayersIndexs count] - 1; i >= 0; i--)
    {
        int nWillDeletedLayerIndex = [[linkedLayersIndexs objectAtIndex:i] intValue];
        
        [self deleteLayer:nWillDeletedLayerIndex];
    }
    
    // Change the layer
    m_nActiveLayerIndex = [[linkedLayersIndexs objectAtIndex:0] intValue];
    if (m_nActiveLayerIndex >= [m_arrLayers count]) m_nActiveLayerIndex = [m_arrLayers count] - 1;
    
    
    for (int i = 0; i < [self layerCount]; i++)
        [self setLinked:NO forLayer:i];
    [self setLinked:YES forLayer:m_nActiveLayerIndex];
    
    
    // Update PixelStyle with the changes
    [[m_idDocument helpers] activeLayerChanged:kLayerDeleted rect:nil];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)deleteLayer:(int)index
{
    if ([self layerCount] <= 1)
    {
        return;
    }
    
    if(index == kActiveLayer)
    {
        [self deleteLayer];
        return;
    }
    
    id layer;
    NSArray *tempArray = [NSArray array];
    IntRect rect;
    int i;
    
    // Correct index
    //	if (index == kActiveLayer) index = m_nActiveLayerIndex;
    layer = [m_arrLayers objectAtIndex:index];
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Clear the selection if the layer is a floating one
    if ([layer floating])
    {
        [[m_idDocument selection] clearSelection];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] anchorTool];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:YES];
    }
    
    // Create a new array with all the existing layers except the one being deleted
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        if (i != index)
        {
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
        }
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Add the layer to the lost layers (compressed)
    [layer compress];
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)[m_arrDeletedLayers arrayByAddingObject:layer];
    [m_arrDeletedLayers retain];
    
    // Change the layer
    if (m_nActiveLayerIndex >= [m_arrLayers count]) m_nActiveLayerIndex = [m_arrLayers count] - 1;
    
    // Update PixelStyle with the changes
    rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    [[m_idDocument helpers] activeLayerChanged:kLayerDeleted rect:&rect];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Unset the clone tool
    [[[m_idDocument tools] getTool:kCloneTool] unset];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreLayer:index fromLostIndex:[m_arrDeletedLayers count] - 1];
    
    // Update toolbox
    if ([layer floating])
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:YES];
}

- (void)restoreLayer:(int)index fromLostIndex:(int)lostIndex
{
    id layer = [m_arrDeletedLayers objectAtIndex:lostIndex];
    NSArray *tempArray;
    IntRect rect;
    int i;
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Decompress the layer we are restoring
    [layer decompress];
    
    // Create a new array with all the existing layers including the one being restored
    tempArray = [NSArray array];
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == index)
        {
            tempArray = [tempArray arrayByAddingObject:layer];
        }
        else
        {
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:(i > index) ? i - 1 : i]];
        }
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    m_arrLayers = tempArray;
    [m_arrLayers retain];
    
    // Create a new array of lost layers with the removed layer replaced with "BLANK"
    tempArray = [NSArray array];
    for (i = 0; i < [m_arrDeletedLayers count]; i++)
    {
        if (i == lostIndex)
            tempArray = [tempArray arrayByAddingObject:[[NSString alloc] initWithString:@"BLANK"]];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrDeletedLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)tempArray;
    [m_arrDeletedLayers retain];
    
    // Update PixelStyle with the changes
    m_nActiveLayerIndex = index;
    
    for (int i = 0; i < [self layerCount]; i++)
        [self setLinked:NO forLayer:i];
    [self setLinked:YES forLayer:m_nActiveLayerIndex];
    
    // Wrap selection to the opaque if the layer is a floating one
    if ([layer floating])
        [[m_idDocument selection] selectOpaque];
    
    // Update PixelStyle with the changes
    rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&rect];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
    
    // Update toolbox
    if ([layer floating])
    {
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] floatTool];
        [(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:YES];
    }
}

- (void)makeSelectionFloat:(BOOL)duplicate
{
    NSArray *tempArray = [NSArray array];
    BOOL containsNothing;
    unsigned char *data;
    IntRect rect;
    id layer;
    int i, spp = [[m_idDocument contents] spp];
    
    // Check the state is valid
    if (![[m_idDocument selection] active] || [[m_idDocument selection] floating])
        return;
    
    // Save the existing selection
    rect = [[m_idDocument selection] globalRect];
    data = [[m_idDocument selection] selectionData:NO];
    
    // Check that the selection contains something
    containsNothing = YES;
    for (i = 0; containsNothing && (i < rect.size.width * rect.size.height); i++)
    {
        if (data[(i + 1) * spp - 1] != 0x00)
            containsNothing = NO;
    }
    
    if (containsNothing)
    {
        free(data);
        NSRunAlertPanel(LOCALSTR(@"empty selection title", @"Selection empty"), LOCALSTR(@"empty selection body", @"The selection cannot be floated since it is empty."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
        return;
    }
    
    // Remove the old selection if we're not duplicating
    if(!duplicate)
        [[m_idDocument selection] deleteSelection];
    
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    
    //    layer = [[PSLayer alloc] initFloatingWithDocument:m_idDocument rect:rect data:data];
    //    [layer trimLayer];
    layer = [[PSLayer alloc] initWithDocument:m_idDocument rect:rect data:data spp:spp];
    
    
    
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == m_nActiveLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > m_nActiveLayerIndex) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Wrap selection to the opaque
    //[[m_idDocument selection] selectOpaque];
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&rect];
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Inform the tools of the floating
    //[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] floatTool];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:m_nActiveLayerIndex];
}

-(IBAction)duplicate:(id)sender
{
    [self makeSelectionFloat:YES];
}

-(void)toggleFloatingSelection
{
    if ([[m_idDocument selection] floating])
    {
        [self anchorSelection];
    }
    else
    {
        [self makeSelectionFloat:NO];
    }
}

- (void)makePasteboardFloat:(NSPasteboard *)pDragBoard center:(NSPoint)pointCenter
//- (void)makePasteboardFloat
{
    NSArray *tempArray = [NSArray array];
    NSString *imageRepDataType;
    NSData *imageRepData;
    NSBitmapImageRep *imageRep;
    NSImage *image;
    IntRect rect;
    
    id pboard = [NSPasteboard generalPasteboard];
    id layer;
    unsigned char *data, *tdata;
    int i, spp = [[m_idDocument contents] spp], sspp, dspp, space;
    CMProfileLocation cmProfileLoc;
    int bipp, bypr, bps;
    id profile;
    NSPoint centerPoint;
    IntPoint sel_point;
    IntSize sel_size;
    
    if(pDragBoard != nil) pboard = pDragBoard;
    
    // Check the state is valid
    if ([[m_idDocument selection] floating])
        return;
    
    // Get the data from the pasteboard
    imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSTIFFPboardType]];
    if (imageRepDataType == NULL)
    {
        imageRepDataType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSPICTPboardType]];
        imageRepData = [pboard dataForType:imageRepDataType];
        image = [[NSImage alloc] initWithData:imageRepData];
        imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        [image autorelease];
    }
    else
    {
        imageRepData = [pboard dataForType:imageRepDataType];
        imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
    }
    
    // Determine the color space of pasteboard image
    space = -1;
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
        space = kGrayColorSpace;
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
        space = kInvertedGrayColorSpace;
    if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
        space = kRGBColorSpace;
    if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
        space = kCMYKColorSpace;
    if (space == -1) {
        NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
        return;
    }
    
    // Do not extract color profile
    profile = NULL;
    
    /*
     Here the reason we don't extract the profile data is because data on the pasteboard is already
     in the proper color profile. By applying that profile again we're apparently double-converting.
     There should be a better way to do this but this works for now.
     
     profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
     if (profile) {
     cmProfileLoc.locType = cmPtrBasedProfile;
     cmProfileLoc.u.ptrLoc.p = (Ptr)[profile bytes];
     }
     */
    
    // Work out the correct center point
    sel_size = IntMakeSize([imageRep pixelsWide], [imageRep pixelsHigh]);
    if ([[m_idDocument selection] selectionSizeMatch:sel_size])
    {
        sel_point = [[m_idDocument selection] selectionPoint];
        rect = IntMakeRect(sel_point.x, sel_point.y, sel_size.width, sel_size.height);
    }
    else if ((m_nHeight > 64 && m_nWidth > 64 && sel_size.height > m_nHeight - 12 &&  sel_size.width > m_nWidth - 12) || (sel_size.height >= m_nHeight &&  sel_size.width >= m_nWidth))
    {
        rect = IntMakeRect(m_nWidth / 2 - sel_size.width / 2, m_nHeight / 2 - sel_size.height / 2, sel_size.width, sel_size.height);
    }
    else
    {
        if(pDragBoard == nil)
        {
            centerPoint = [(CenteringClipView *)[[m_idDocument docView] superview] centerPoint];
            centerPoint.x /= [[m_idDocument docView] zoom];
            centerPoint.y /= [[m_idDocument docView] zoom];
        }
        else centerPoint = pointCenter;
        
        rect = IntMakeRect(centerPoint.x - sel_size.width / 2, centerPoint.y - sel_size.height / 2, sel_size.width, sel_size.height);
        
    }
    
    // Put it in a nice form
    sspp = [imageRep samplesPerPixel];
    bps = [imageRep bitsPerSample];
    bipp = [imageRep bitsPerPixel];
    bypr = [imageRep bytesPerRow];
    dspp = spp;
    if (spp == 4 && m_nSelectedChannel == kAlphaChannel)
    {
        dspp = 2;
    }
    
    data = convertBitmap(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], rect.size.width, rect.size.height, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, 0);
    if (!data)
    {
        NSLog(@"Required conversion not supported.");
        return;
    }
    unpremultiplyBitmap(dspp, data, data, rect.size.width * rect.size.height);
    [imageRep autorelease];
    
    // Handle the special case where a GGGA graphic is wanted
    if (spp == 4 && dspp == 2)
    {
        tdata = malloc(make_128(rect.size.width * rect.size.height * 4));
        for (i = 0; i < rect.size.width * rect.size.height; i++)
        {
            tdata[i * 4] = data[i * 2];
            tdata[i * 4 + 1] = data[i * 2];
            tdata[i * 4 + 2] = data[i * 2];
            tdata[i * 4 + 3] = data[i * 2 + 1];
        }
        free(data);
        data = tdata;
    }
    
    for (int nIndex = 0; nIndex < [m_arrLayers count]; nIndex++)
    {
        PSAbstractLayer *layer = [self layer:nIndex];
        [layer setLinked:NO];
    }
    
    // Inform the helpers we will change the layer
    [[m_idDocument helpers] activeLayerWillChange];
    
    // Create a new array with all the existing layers and the one being added
    //	layer = [[PSLayer alloc] initFloatingWithDocument:m_idDocument rect:rect data:data];
    //    [layer trimLayer];
    
    layer = [[PSLayer alloc] initWithDocument:m_idDocument rect:rect data:data spp:spp];
    
    for (i = 0; i < [m_arrLayers count] + 1; i++)
    {
        if (i == m_nActiveLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:(i > m_nActiveLayerIndex) ? [m_arrLayers objectAtIndex:i - 1] : [m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Wrap selection to the opaque
    //[[m_idDocument selection] selectOpaque];
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Inform document of layer change
    [[m_idDocument helpers] activeLayerChanged:kLayerAdded rect:&rect];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Inform the tools of the floating
    //[[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] floatTool];
    
    // Make action undoable
    [(PSContent *)[[m_idDocument undoManager] prepareWithInvocationTarget:self] deleteLayer:m_nActiveLayerIndex];
}

- (void)anchorSelection
{
    unsigned char *data, *overlay;
    IntRect dataRect, layerRect;
    int i, j, destXPos, destYPos, spp = [self spp];
    int floatingLayerIndex = -1;
    id layer;
    
    // Don't do anything if there's no selection
    if (![[m_idDocument selection] floating])
        return;
    
    // We need to figure out what layer is floating
    // This isn't nessisarily the current active layer since people can select different
    // layers while there is a floating layer.
    for(i = 0; i < [m_arrLayers count]; i++)
    {
        if([[m_arrLayers objectAtIndex:i] floating])
        {
            if(floatingLayerIndex != -1)
            {
                NSLog(@"Multiple floating layers?");
            }
            else
            {
                floatingLayerIndex = i;
            }
        }
    }
    
    if(floatingLayerIndex == -1)
    {
        NSLog(@"There were no floating layers!");
    }
    
    // Save the existing selection
    layer = [m_arrLayers objectAtIndex:floatingLayerIndex];
    dataRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);;
    data = malloc(make_128(dataRect.size.width * dataRect.size.height * spp));
    memcpy(data, [(PSLayer *)layer getRawData], dataRect.size.width * dataRect.size.height * spp);
    [(PSLayer *)layer unLockRawData];
    
    // Delete the floating layer
    [self deleteLayer:floatingLayerIndex];
    
    // Work out the new layer rectangle
    layer = [m_arrLayers objectAtIndex:m_nActiveLayerIndex];
    layerRect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
    
    // Copy the selection to the overlay
    overlay = [[m_idDocument whiteboard] overlay];
    [[m_idDocument whiteboard] setOverlayOpacity:255];
    for (j = 0; j < dataRect.size.height; j++)
    {
        for (i = 0; i < dataRect.size.width; i++)
        {
            destXPos = dataRect.origin.x - layerRect.origin.x + i;
            destYPos = dataRect.origin.y - layerRect.origin.y + j;
            if (destXPos >= 0 && destXPos < layerRect.size.width && destYPos >= 0 && destYPos < layerRect.size.height)
            {
                memcpy(&(overlay[(destYPos * layerRect.size.width + destXPos) * spp]), &(data[(j * dataRect.size.width + i) * spp]), spp);
            }
        }
    }
    free(data);
    
    // Clear the selection
    [[m_idDocument selection] clearSelection];
    
    // We would inform the tools of the floating but this is already called in the deleteLayer method
    
    // Apply the overlay
    [(PSHelpers *)[m_idDocument helpers] applyOverlay];
}

- (BOOL)canRaise:(int)index
{
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    return !(index == 0);
}

- (BOOL)canLower:(int)index
{
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    if ([[m_arrLayers objectAtIndex:index] floating] && index == [m_arrLayers count] - 2) return NO;
    return !(index == [m_arrLayers count] - 1);
}

- (void)moveLayer:(id)layer toIndex:(int)index
{
    [self moveLayerOfIndex:[m_arrLayers indexOfObject:layer] toIndex: index];
}

- (void)moveLayerOfIndex:(int)source toIndex:(int)dest
{
    NSMutableArray *tempArray;
    
    // An invalid destination
    if(dest < 0 || dest > [m_arrLayers count])
        return;
    
    // Correct index
    if (source == kActiveLayer) source = m_nActiveLayerIndex;
    id activeLayer = [m_arrLayers objectAtIndex:m_nActiveLayerIndex];
    
    // Allocate space for a new array
    tempArray = [m_arrLayers mutableCopy];
    [tempArray removeObjectAtIndex:source];
    
    int actualFinal;
    
    if(dest >= [m_arrLayers count])
    {
        actualFinal = [m_arrLayers count] - 1;
    }
    else if(dest > source)
    {
        actualFinal = dest - 1;
    }
    else
    {
        actualFinal = dest;
    }
    
    [tempArray insertObject:[m_arrLayers objectAtIndex:source] atIndex:actualFinal];
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    m_arrLayers = [[NSArray arrayWithArray:tempArray] retain];
    
    // Update PixelStyle with the changes
    m_nActiveLayerIndex = [m_arrLayers indexOfObject:activeLayer];
    [[m_idDocument helpers] layerLevelChanged:m_nActiveLayerIndex];
    
    // For the undo we need to make sure we get the offset right
    if(source >= dest){
        source++;
    }
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] moveLayerOfIndex: actualFinal toIndex: source];
    
}


- (void)raiseLayer:(int)index
{
    NSArray *tempArray;
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canRaise:index])
        return;
    
    // Allocate space for a new array
    tempArray = [NSArray array];
    
    // Go through and add all existing objects to the new array
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == index - 1)
        {
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i + 1]];
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
            i++;
        }
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Update PixelStyle with the changes
    m_nActiveLayerIndex = index - 1;
    [[m_idDocument helpers] layerLevelChanged:m_nActiveLayerIndex];
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] lowerLayer:index - 1];
}

- (void)lowerLayer:(int)index
{
    NSArray *tempArray;
    int i;
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    
    // Do nothing if we can't do anything
    if (![self canLower:index])
        return;
    
    // Allocate space for a new array
    tempArray = [NSArray array];
    
    // Go through and add all existing objects to the new array
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == index)
        {
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i + 1]];
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
            i++;
        }
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    // Update PixelStyle with the changes
    m_nActiveLayerIndex = index + 1;
    [[m_idDocument helpers] layerLevelChanged:m_nActiveLayerIndex];
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] raiseLayer:index + 1];
}

- (void)clearAllLinks
{
    int i;
    
    // Go through all layers and toggle them back so they are unlinked
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        if ([[m_arrLayers objectAtIndex:i] linked])
            [self setLinked: NO forLayer: i];
    }
}

- (void)setLinked:(BOOL)isLinked forLayer:(int)index
{
    id layer;
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    layer = [m_arrLayers objectAtIndex:index];
    
    // Apply the changes
    [layer setLinked:isLinked];
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
    
    // Make action undoable ---has error
    //[[[m_idDocument undoManager] prepareWithInvocationTarget:self] setLinked:!isLinked forLayer:index];
}

- (void)setVisible:(BOOL)isVisible forLayer:(int)index
{
    id layer;
    
    // Correct index
    if (index == kActiveLayer) index = m_nActiveLayerIndex;
    layer = [m_arrLayers objectAtIndex:index];
    
    // Apply the changes
    [layer setVisible:isVisible];
    [[m_idDocument helpers] layerAttributesChanged:index hold:YES];
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] setVisible:!isVisible forLayer:index];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
    
    
}

- (void)copyMerged
{
    id pboard = [NSPasteboard generalPasteboard];
    int spp = [[m_idDocument contents] spp], i , j, k, t1;
    NSBitmapImageRep *imageRep;
    IntRect globalRect;
    unsigned char *data = [(PSWhiteboard *)[m_idDocument whiteboard] data];
    unsigned char *ndata = NULL;
    unsigned char *mask;
    
    // Check selection
    if ([[m_idDocument selection] active])
    {
        mask = [[m_idDocument selection] mask];
        globalRect = [[m_idDocument selection] globalRect];
        ndata = malloc(make_128(globalRect.size.width * globalRect.size.height * spp));
        if (mask)
        {
            for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++)
            {
                for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++)
                {
                    for (k = 0; k < spp; k++)
                    {
                        ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  int_mult(data[(j * m_nWidth + i) * spp + k], mask[(j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)], t1);
                    }
                }
            }
        }
        else
        {
            for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++)
            {
                for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++)
                {
                    for (k = 0; k < spp; k++)
                    {
                        ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  data[(j * m_nWidth + i) * spp + k];
                    }
                }
            }
        }
    }
    else
    {
        ndata = data;
        globalRect.origin.x = globalRect.origin.y = 0;
        globalRect.size.width = m_nWidth;
        globalRect.size.height = m_nHeight;
    }
    
    // Declare the data being added to the pasteboard
    [pboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:NULL];
    
    // Add it to the pasteboard
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&ndata pixelsWide:globalRect.size.width pixelsHigh:globalRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:globalRect.size.width * spp bitsPerPixel:8 * spp];
    [pboard setData:[imageRep TIFFRepresentation] forType:NSTIFFPboardType];
    [imageRep autorelease];
    
    // Clean out the remains
    if (ndata != data)
    {
        free(ndata);
    }
}

- (BOOL)canFlatten
{
    // No, if there is a floating selection active
    if ([[m_idDocument selection] floating])
        return NO;
    
    // Yes, if there are one or more layers
    if ([m_arrLayers count] != 1)
        return YES;
    
    // Yes, if single layer is out of place
    if ([[m_arrLayers objectAtIndex:0] xoff] != 0 || [[m_arrLayers objectAtIndex:0] yoff] != 0
        || [(PSLayer *)[m_arrLayers objectAtIndex:0] width] != m_nWidth || [(PSLayer *)[m_arrLayers objectAtIndex:0] height] != m_nHeight)
        return YES;
    
    return NO;
}

- (void)flatten
{
    [self merge:[m_arrLayers retain] useRepresentation: NO withName: LOCALSTR(@"flattened", @"Flattened Layer")]; //YES 不能用了，没有合成好的数据
}

- (void)mergeLinked
{
    PSLayer *layer;
    NSMutableArray *linkedLayers = [[NSMutableArray array] retain];
    // Go through noting each linked layer
    NSEnumerator *e = [m_arrLayers objectEnumerator];
    while(layer = [e nextObject])
    {
        if ([layer linked])
            [linkedLayers addObject: layer];
    }
    // Preform the merge
    [self merge:linkedLayers useRepresentation: NO withName: LOCALSTR(@"flattened", @"Flattened Layer")];
}

- (void)mergeDown
{
    // Make sure there is a layer to merge into
    if([self canLower:m_nActiveLayerIndex])
    {
        NSArray *twoLayers = [NSArray arrayWithObject:[m_arrLayers  objectAtIndex:m_nActiveLayerIndex]];
        // Add the layer we're going into
        twoLayers = [twoLayers arrayByAddingObject:[m_arrLayers  objectAtIndex:m_nActiveLayerIndex + 1]];
        [twoLayers retain];
        [self merge: twoLayers useRepresentation: NO withName: [[m_arrLayers  objectAtIndex:m_nActiveLayerIndex + 1] name]];
    }
}

- (void)merge:(NSArray *)mergingLayers useRepresentation: (BOOL)useRepresenation withName:(NSString *)newName
{
    CompositorOptions options;
    unsigned char *data;
    PSLayer *layer, *lostLayer, *tempLayer = [PSLayer alloc];
    int spp = [self spp];
    BOOL indexFound = NO;
    NSMutableArray *tempArray = [NSMutableArray array];
    IntRect rect = IntMakeRect(0,0,0,0);
    // The ordering dictionary is needed because layers which are linked are not
    // nessisarily contiguous -- thus just keeping a stack in the undo history
    // would not totally restore their state
    NSMutableDictionary *ordering = [[NSMutableDictionary dictionaryWithCapacity:[m_arrLayers count]] retain];
    
    // Do nothing if we can't do anything
    if (![self canFlatten])
        return;
    
    // Inform the helpers we will flatten the document
    [[m_idDocument helpers] documentWillFlatten];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMergeWith:[m_arrLayers count] andOrdering: ordering];
    [m_maOrderings addObject:ordering];
    // Create the replacement flat layer
    
    // Use representation is used when we want to use the pre-made image
    // representation of the image. Basicially, just when flattening the whole
    // file.
    if(useRepresenation)
    {
        rect.size.width = m_nWidth;
        rect.size.height = m_nHeight;
        data = malloc(make_128(rect.size.width * rect.size.height * spp));
        memcpy(data, [[[[[m_idDocument whiteboard] image] representations] objectAtIndex:0] bitmapData], rect.size.width * rect.size.height * spp);
        
        NSEnumerator *e = [m_arrLayers objectEnumerator];
        
        while(layer = [e nextObject])
        {
            [ordering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
        }
        [tempArray addObject:tempLayer];
    }
    else
    {
        NSEnumerator *e = [m_arrLayers objectEnumerator];
        // Here we find out the dimensions of the new layer, plus keep track of
        // which layers are not going to be merged (tempArray).
        while(layer = [e nextObject])
        {
            [ordering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
            if([mergingLayers indexOfObject:layer] != NSNotFound)
            {
                IntRect thisRect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
                rect = IntSumRects(rect, thisRect);
                if(!indexFound)
                    [tempArray addObject:tempLayer];
            }
            else
            {
                [tempArray addObject:layer];
            }
        }
        data = malloc(make_128(rect.size.width * rect.size.height * spp));
        memset(data, 0, rect.size.width * rect.size.height * spp);
        // Set the composting options
        
        // Composite the linked layers
        CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
        CGContextRef bitmapContext = CGBitmapContextCreate(data, rect.size.width, rect.size.height, 8, spp * rect.size.width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
        assert(bitmapContext);
        
        
        //        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);
        //        CGContextConcatCTM(bitmapContext, flipVertical);
        
        NSEnumerator *f = [mergingLayers reverseObjectEnumerator];
        while(layer = [f nextObject])
        {
            RENDER_CONTEXT_INFO info;
            info.context = bitmapContext;
            info.offset = IntPointMakeNSPoint(rect.origin);
            info.scale = CGSizeMake(1.0, 1.0);
            info.refreshMode = 2;
            int state = 0;
            info.state = &state;
            [layer renderToContext:info];
        }
        
        unsigned char temp[spp * rect.size.width];
        int j;
        
        for (j = 0; j < rect.size.height / 2; j++)
        {
            memcpy(temp, data + (j * rect.size.width) * spp, spp * rect.size.width);
            memcpy(data + (j * rect.size.width) * spp, data + ((rect.size.height - j - 1) * rect.size.width) * spp, spp * rect.size.width);
            memcpy(data + ((rect.size.height - j - 1) * rect.size.width) * spp, temp, spp * rect.size.width);
        }
        
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(defaultColorSpace);
        
    }
    unpremultiplyBitmap(spp, data, data, rect.size.width * rect.size.height);
    layer = [[PSLayer alloc] initWithDocument:m_idDocument rect:rect data:data spp:spp];
    [layer setName:[[NSString alloc] initWithString:newName]];
    
    // Get rid of all the other layers
    NSEnumerator *g = [mergingLayers objectEnumerator];
    while(lostLayer = [g nextObject])
        [m_maLayersToUndo addObject: lostLayer];
    
    // Revise layers
    [m_arrLayers autorelease];
    m_nActiveLayerIndex = [tempArray indexOfObject:tempLayer];
    [tempArray replaceObjectAtIndex:m_nActiveLayerIndex withObject:layer];
    
    [tempArray removeObject:tempLayer];
    
    [tempLayer release];
    
    m_arrLayers = tempArray;
    m_nSelectedChannel = kAllChannels;
    [m_arrLayers retain];
    
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    // Unset the clone tool
    [[[m_idDocument tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have flattened the m_idDocument
    [[m_idDocument helpers] documentFlattened];
    [mergingLayers release];
}


/*
 - (void)merge:(NSArray *)mergingLayers useRepresentation: (BOOL)useRepresenation withName:(NSString *)newName
 {
	CompositorOptions options;
	unsigned char *data;
	PSLayer *layer, *lostLayer, *tempLayer = [PSLayer alloc];
	int spp = [self spp];
	BOOL indexFound = NO;
	NSMutableArray *tempArray = [NSMutableArray array];
	IntRect rect = IntMakeRect(0,0,0,0);
	// The ordering dictionary is needed because layers which are linked are not
	// nessisarily contiguous -- thus just keeping a stack in the undo history
	// would not totally restore their state
	NSMutableDictionary *ordering = [[NSMutableDictionary dictionaryWithCapacity:[m_arrLayers count]] retain];
	
	// Do nothing if we can't do anything
	if (![self canFlatten])
 return;
	
	// Inform the helpers we will flatten the document
	[[m_idDocument helpers] documentWillFlatten];
	
	// Make action undoable
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMergeWith:[m_arrLayers count] andOrdering: ordering];
	[m_maOrderings addObject:ordering];
	// Create the replacement flat layer
	
	// Use representation is used when we want to use the pre-made image
	// representation of the image. Basicially, just when flattening the whole
	// file.
	if(useRepresenation){
 rect.size.width = m_nWidth;
 rect.size.height = m_nHeight;
 data = malloc(make_128(rect.size.width * rect.size.height * spp));
 memcpy(data, [[[[[m_idDocument whiteboard] image] representations] objectAtIndex:0] bitmapData], rect.size.width * rect.size.height * spp);
 NSEnumerator *e = [m_arrLayers objectEnumerator];
 while(layer = [e nextObject]){
 [ordering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
 }
 [tempArray addObject:tempLayer];
	}else{
 NSEnumerator *e = [m_arrLayers objectEnumerator];
 // Here we find out the dimensions of the new layer, plus keep track of
 // which layers are not going to be merged (tempArray).
 while(layer = [e nextObject]) {
 [ordering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
 if([mergingLayers indexOfObject:layer] != NSNotFound){
 IntRect thisRect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
 rect = IntSumRects(rect, thisRect);
 if(!indexFound)
 [tempArray addObject:tempLayer];
 }else{
 [tempArray addObject:layer];
 }
 }
 data = malloc(make_128(rect.size.width * rect.size.height * spp));
 memset(data, 0, rect.size.width * rect.size.height * spp);
 // Set the composting options
 
 // Composite the linked layers
 CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
 CGContextRef bitmapContext = CGBitmapContextCreate(data, rect.size.width, rect.size.height, 8, spp * rect.size.width, defaultColorSpace, kCGImageAlphaPremultipliedLast);
 assert(bitmapContext);
 
 
 //        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);
 //        CGContextConcatCTM(bitmapContext, flipVertical);
 
 NSEnumerator *f = [mergingLayers reverseObjectEnumerator];
 while(layer = [f nextObject]){
 int nMode,nLayerWidth,nLayerHeight;
 int nOffsetX, nOffsetY;
 int nLayerAlpha;
 LAYER_SHADOW sLayerShadow;
 BOOL isLayerShadowEnable;
 
 nMode = [layer mode];
 nOffsetX = [layer xoff];
 nOffsetY = [layer yoff];
 nLayerWidth = [layer width];
 nLayerHeight = [layer height];
 nLayerAlpha = [layer opacity];
 PSLayerEffect *effect = [layer getLayerEffect];
 sLayerShadow = [effect getShadow];
 isLayerShadowEnable = [effect shadowIsEnable];
 
 CGContextSaveGState(bitmapContext);
 if (isLayerShadowEnable) {
 CGColorRef shadowColor = CGColorCreateGenericRGB(sLayerShadow.color[0]/255.0,sLayerShadow.color[1]/255.0, sLayerShadow.color[2]/255.0, sLayerShadow.color[3]/255.0);
 CGContextSetShadowWithColor(bitmapContext, CGSizeMake(sLayerShadow.offset.width, -sLayerShadow.offset.height), sLayerShadow.fBlur,shadowColor);
 CGColorRelease(shadowColor);
 }else{
 CGContextSetShadowWithColor(bitmapContext, CGSizeMake(0, 0), 0, NULL);
 }
 
 CGContextSetAlpha(bitmapContext, nLayerAlpha/255.0);
 CGContextSetBlendMode(bitmapContext, nMode);
 CGRect destRect = CGRectMake(nOffsetX - rect.origin.x, nOffsetY - rect.origin.y, nLayerWidth, nLayerHeight);
 CGLayerRef cgLayer = [(PSLayer *)layer getCGLayer];
 CGContextDrawLayerInRect(bitmapContext, destRect, cgLayer);
 CGContextRestoreGState(bitmapContext);
 }
 unsigned char temp[spp * rect.size.width];
 int j;
 for (j = 0; j < rect.size.height / 2; j++) {
 memcpy(temp, data + (j * rect.size.width) * spp, spp * rect.size.width);
 memcpy(data + (j * rect.size.width) * spp, data + ((rect.size.height - j - 1) * rect.size.width) * spp, spp * rect.size.width);
 memcpy(data + ((rect.size.height - j - 1) * rect.size.width) * spp, temp, spp * rect.size.width);
 }
 CGContextRelease(bitmapContext);
 CGColorSpaceRelease(defaultColorSpace);
 
	}
	unpremultiplyBitmap(spp, data, data, rect.size.width * rect.size.height);
	layer = [[PSLayer alloc] initWithDocument:m_idDocument rect:rect data:data spp:spp];
	[layer setName:[[NSString alloc] initWithString:newName]];
 
	// Get rid of all the other layers
	NSEnumerator *g = [mergingLayers objectEnumerator];
	while(lostLayer = [g nextObject])
 [m_maLayersToUndo addObject: lostLayer];
	
	// Revise layers
	[m_arrLayers autorelease];
	m_nActiveLayerIndex = [tempArray indexOfObject:tempLayer];
	[tempArray replaceObjectAtIndex:m_nActiveLayerIndex withObject:layer];
 
	[tempArray removeObject:tempLayer];
 
 [tempLayer release];
 
	m_arrLayers = tempArray;
	m_nSelectedChannel = 0;
	[m_arrLayers retain];
	
	// Unset the clone tool
	[[[m_idDocument tools] getTool:kCloneTool] unset];
	
	// Inform the helpers we have flattened the m_idDocument
	[[m_idDocument helpers] documentFlattened];
	[mergingLayers release];
 }
 */



//-(void)createCGLayer
//{
//    CGColorSpaceRef defaultColorSpace = (([self spp] == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
//    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, m_nWidth, m_nHeight, 8, [self spp] * m_nWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
//    assert(bitmapContext);
//
//    m_cgLayer = CGLayerCreateWithContext(bitmapContext, CGSizeMake(m_nWidth, m_nHeight), nil);
//    assert(m_cgLayer);
//    CGContextRelease(bitmapContext);
//}

- (void)undoMergeWith:(int)oldNoLayers andOrdering: (NSMutableDictionary *)ordering
{
    NSMutableArray *oldLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
    NSMutableDictionary *newOrdering = [[NSMutableDictionary dictionaryWithCapacity:[m_arrLayers count]] retain];
    int i;
    PSLayer *layer;
    
    // Inform the helpers we will unflatten the m_idDocument
    [[m_idDocument helpers] documentWillFlatten];
    
    // Get the current m_maOrderings for the undo history
    NSEnumerator *e = [m_arrLayers objectEnumerator];
    while(layer = [e nextObject])
        [newOrdering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] redoMergeWith:[m_arrLayers count] andOrdering: newOrdering];
    
    // This is just to make the dimensions of the array correct
    while([oldLayers count] < oldNoLayers)
        [oldLayers addObject: [m_arrLayers lastObject]];
    
    // Store the previous layers to their correct location in the array
    for(i = 0; i < oldNoLayers - [m_arrLayers count] + 1; i++)
    {
        PSLayer *oldLayer = [m_maLayersToUndo lastObject];
        [m_maLayersToUndo removeLastObject];
        int replInd = [[ordering objectForKey:[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]] intValue];
        [oldLayers replaceObjectAtIndex:replInd withObject:oldLayer];
    }
    
    for(i = 0; i < [m_arrLayers count]; i++)
    {
        PSLayer *oldLayer = [m_arrLayers objectAtIndex:i];
        NSNumber *oldIndex = [ordering objectForKey:[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]];
        // We also will need to store the merged layer for redo
        if(oldIndex != nil)
            [oldLayers replaceObjectAtIndex: [oldIndex intValue] withObject:oldLayer];
        else
            [m_maLayersToRedo addObject:oldLayer];
    }
    
    // Empty the layers array
    [m_arrLayers autorelease];
    m_arrLayers = oldLayers;
    [m_arrLayers retain];
    
    // Unset the clone tool
    [[[m_idDocument tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have unflattened the document
    [[m_idDocument helpers] documentFlattened];
    
    [m_maOrderings removeObject: ordering];
    [m_maOrderings addObject:newOrdering];
    [ordering release];
}

- (unsigned char *)bitmapUnderneath:(IntRect)rect
{
    CompositorOptions options;
    unsigned char *data;
    PSLayer *layer;
    int i, spp = [self spp];
    
    // Create the replacement flat layer
    data = malloc(make_128(rect.size.width * rect.size.height * spp));
    memset(data, 0, rect.size.width * rect.size.height * spp);
    
    // Set the composting options
    options.forceNormal = 0;
    options.rect = rect;
    options.destRect = rect;
    options.insertOverlay = NO;
    options.useSelection = NO;
    options.overlayOpacity = 255;
    options.overlayBehaviour = kNormalBehaviour;
    options.spp = spp;
    
    // Composite the layers underneath
    for (i = [m_arrLayers count] - 1; i >= m_nActiveLayerIndex; i--)
    {
        layer = [m_arrLayers objectAtIndex:i];
        if ([layer visible])
        {
            [[[m_idDocument whiteboard] compositor] compositeLayer:layer withOptions:options andData:data];
        }
    }
    
    return data;
}

- (void)redoMergeWith:(int)oldNoLayers andOrdering:(NSMutableDictionary *)ordering
{
    NSMutableArray *newLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
    NSMutableDictionary *oldOrdering = [[NSMutableDictionary dictionaryWithCapacity:[m_arrLayers count]] retain];
    int i;
    PSLayer *layer;
    
    // Inform the helpers we will flatten the document
    [[m_idDocument helpers] documentWillFlatten];
    
    // Store the m_maOrderings
    NSEnumerator *e = [m_arrLayers objectEnumerator];
    while(layer = [e nextObject])
        [oldOrdering setValue: [NSNumber numberWithInt:[m_arrLayers indexOfObject: layer]] forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMergeWith:[m_arrLayers count] andOrdering:oldOrdering];
    
    // Populate the array
    while([newLayers count] < oldNoLayers)
        [newLayers addObject: [m_arrLayers lastObject]];
    
    PSLayer *newLayer = [m_maLayersToRedo lastObject];
    [m_maLayersToRedo removeLastObject];
    [newLayers replaceObjectAtIndex:[[ordering objectForKey:[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]] intValue] withObject:newLayer];
    
    // Go through and insert the layers at the appropriate places
    for(i = 0; i < [m_arrLayers count]; i++)
    {
        PSLayer *newLayer = [m_arrLayers objectAtIndex:i];
        NSNumber *newIndex = [ordering objectForKey:[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]];
        if(newIndex != nil)
            [newLayers replaceObjectAtIndex: [newIndex intValue] withObject:newLayer];
        else
            [m_maLayersToUndo addObject:newLayer];
    }
    
    // Empty the layers array
    [m_arrLayers autorelease];
    m_arrLayers = newLayers;
    [m_arrLayers retain];
    
    
    // Unset the clone tool
    [[[m_idDocument tools] getTool:kCloneTool] unset];
    
    // Inform the helpers we have flattened the document
    [[m_idDocument helpers] documentFlattened];
    
    [m_maOrderings removeObject:ordering];
    [m_maOrderings addObject:oldOrdering];
    
    [ordering release];
}

- (void)convertToType:(int)newType
{
    IndiciesRecord record;
    id layer;
    int i;
    
    // Do nothing if there is nothing to do
    if (newType == m_nType)
        return;
    
    // Make action undoable
    record.length = [m_arrLayers count];
    record.indicies = malloc([m_arrLayers count] * sizeof(int));
    for (i = 0; i < [m_arrLayers count]; i++)
    {
        layer = [m_arrLayers objectAtIndex:i];
        record.indicies[i] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(PSLayer *)layer width], [(PSLayer *)layer height]) automatic:NO];
    }
    addToKeeper(&m_sKeeper, record);
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] revertToType:m_nType withRecord:record];
    
    // Go through and convert all layers to the new given type
    for (i = 0; i < [m_arrLayers count]; i++)
        [[m_arrLayers objectAtIndex:i] convertFromType:m_nType to:newType];
    
    // Then save the new type
    m_nType = newType;
    
    // Update everything
    [[m_idDocument helpers] typeChanged];
}

- (void)revertToType:(int)newType withRecord:(IndiciesRecord)record
{
    int i;
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] convertToType:m_nType];
    
    // Go through and convert all layers to the new given type
    for (i = 0; i < [m_arrLayers count]; i++)
        [[m_arrLayers objectAtIndex:i] convertFromType:m_nType to:newType];
    
    // Then save the new type
    m_nType = newType;
    
    // Restore the layers
    for (i = 0; i < [m_arrLayers count]; i++)
        [[[m_arrLayers objectAtIndex:i] seaLayerUndo] restoreSnapshot:record.indicies[i] automatic:NO];
    
    // Update everything
    [[m_idDocument helpers] typeChanged];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if (![[m_idDocument selection] active])
        return NO;
    
    if([[theItem itemIdentifier] isEqual: FloatAnchorToolbarItemIdentifier])
    {
        if ([[m_idDocument selection] floating])
        {
            [theItem setLabel: @"Anchor"];
            [theItem setPaletteLabel: LOCALSTR(@"anchor selection", @"Anchor Selection")];
            [theItem setImage:[NSImage imageNamed:@"anchor-tb"]];
        }
        else
        {
            [theItem setLabel:@"Float"];
            [theItem setPaletteLabel:LOCALSTR(@"float selection", @"Float Selection")];
            [theItem setImage:[NSImage imageNamed:@"float-tb"]];
        }
    }
    else if([[theItem itemIdentifier] isEqual: DuplicateSelectionToolbarItemIdentifier])
    {
        if([[m_idDocument selection]floating])
            return NO;
    }
    
    return YES;
}


#pragma mark - vector layer convert raster

-(void)convertVectorLayerToRaster:(int)nLayerIndex
{
    PSAbstractLayer *layer = [self layer:nLayerIndex];
    if([layer layerFormat] != PS_VECTOR_LAYER && ([layer layerFormat] != PS_TEXT_LAYER)) return;
    
    PSLayer *newLayer = [[PSLayer alloc] initWithDocument:m_idDocument layer:(PSVecLayer *)layer];
    NSArray *tempArray = [NSArray array];
    for (int i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == nLayerIndex)
            tempArray = [tempArray arrayByAddingObject:newLayer];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    
    // Add the layer to the lost layers (compressed)
    [layer compress];
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)[m_arrDeletedLayers arrayByAddingObject:layer];
    [m_arrDeletedLayers retain];
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:NO];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] revertRasterLayerToVector:nLayerIndex fromLostIndex:[m_arrDeletedLayers count] - 1];
}

- (void)revertRasterLayerToVector:(int)nLayerIndex fromLostIndex:(int)nLostIndex
{
    id layer = [m_arrDeletedLayers objectAtIndex:nLostIndex];
    
    // Decompress the layer we are restoring
    [layer decompress];
    
    NSArray *tempArray = [NSArray array];
    for (int i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == nLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    m_arrLayers = tempArray;
    [m_arrLayers retain];
    
    
    // Create a new array of lost layers with the removed layer replaced with "BLANK"
    tempArray = [NSArray array];
    for (int i = 0; i < [m_arrDeletedLayers count]; i++)
    {
        if (i == nLostIndex)
            tempArray = [tempArray arrayByAddingObject:[[NSString alloc] initWithString:@"BLANK"]];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrDeletedLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)tempArray;
    [m_arrDeletedLayers retain];
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:NO];
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] convertVectorLayerToRaster:nLayerIndex];
}

#pragma mark - text layer convert to shape

-(void)convertTextLayerToShape:(int)nLayerIndex
{
    PSAbstractLayer *layer = [self layer:nLayerIndex];
    if([layer layerFormat] != PS_TEXT_LAYER) return;
    
    PSVecLayer *newLayer = [[PSVecLayer alloc] initWithDocument:m_idDocument textLayer:(PSTextLayer *)layer];
    NSArray *tempArray = [NSArray array];
    for (int i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == nLayerIndex)
            tempArray = [tempArray arrayByAddingObject:newLayer];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    [tempArray retain];
    m_arrLayers = tempArray;
    
    
    // Add the layer to the lost layers (compressed)
    [layer compress];
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)[m_arrDeletedLayers arrayByAddingObject:layer];
    [m_arrDeletedLayers retain];
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:NO];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] revertVectorLayerToText:nLayerIndex fromLostIndex:[m_arrDeletedLayers count] - 1];
}


- (void)revertVectorLayerToText:(int)nLayerIndex fromLostIndex:(int)nLostIndex
{
    id layer = [m_arrDeletedLayers objectAtIndex:nLostIndex];
    
    // Decompress the layer we are restoring
    [layer decompress];
    
    NSArray *tempArray = [NSArray array];
    for (int i = 0; i < [m_arrLayers count]; i++)
    {
        if (i == nLayerIndex)
            tempArray = [tempArray arrayByAddingObject:layer];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrLayers autorelease];
    m_arrLayers = tempArray;
    [m_arrLayers retain];
    
    
    // Create a new array of lost layers with the removed layer replaced with "BLANK"
    tempArray = [NSArray array];
    for (int i = 0; i < [m_arrDeletedLayers count]; i++)
    {
        if (i == nLostIndex)
            tempArray = [tempArray arrayByAddingObject:[[NSString alloc] initWithString:@"BLANK"]];
        else
            tempArray = [tempArray arrayByAddingObject:[m_arrDeletedLayers objectAtIndex:i]];
    }
    
    // Now substitute in our new array
    [m_arrDeletedLayers autorelease];
    m_arrDeletedLayers = (NSMutableArray *)tempArray;
    [m_arrDeletedLayers retain];
    
    [[m_idDocument whiteboard] readjustLayer:NO];
    [[m_idDocument whiteboard] readjustAltData:NO];
    
    // Make action undoable
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] convertTextLayerToShape:nLayerIndex];
}


-(int)linkedLayerCount
{
    int nLinkedLayerCount = 0;
    for (int i = 0; i < [self layerCount]; i++)
    {
        if ([[self layer:i] linked])
        {
            nLinkedLayerCount ++;
        }
    }
    
    return nLinkedLayerCount;
}

-(NSMutableArray *)linkedLayersIndexs
{
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i = 0; i < [self layerCount]; i++)
    {
        if ([[self layer:i] linked])
        {
            [mArray addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    return mArray;
}

-(int)minlinkedLayerIndex
{
    int nMinlinkedLayerIndex = 0;
    for (int i = 0; i < [self layerCount]; i++)
    {
        if ([[self layer:i] linked])
        {
            nMinlinkedLayerIndex = i;
            break;
        }
    }
    
    return nMinlinkedLayerIndex;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    int nTag = [menuItem tag];
    
    int nLinkedLayerCount = [self linkedLayerCount];
    if(nLinkedLayerCount > 1) //多选
    {
        if (nTag >= 10000 && nTag < 17500)      return NO;          //filter
        else if (nTag >= 500 && nTag < 600)     return NO;          //shape menu
        else if (nTag >= 213  && nTag <= 216)   return NO;          //layer->上移下移
        else if (nTag >= 360  && nTag <= 362)   return NO;          //layer->Trim Boundaries
        else if (nTag >= 330  && nTag <= 332)   return NO;          //layer->Scale/Rotate/Boundaries
        else if (nTag == 348)                   return NO;          //layer->Merge with Underlying
        else if (nTag == 390)                                       //layer->Raster
        {
            for (int i = 0; i < [self layerCount]; i++) {
                if ([[self layer:i] linked])
                {
                    PA_LAYER_FORMAT layerFormat = [[self layer:i] layerFormat];
                    if(layerFormat == PS_TEXT_LAYER || (layerFormat == PS_VECTOR_LAYER))    return YES;
                }
            }
            return NO;
        }
        else if (nTag == 391)                   return NO;          //layer->layer above
        else if (nTag == 392)                   return NO;          //layer->layer below
        else if (nTag == 393)                   return NO;          //ConvertToShape
        else                                    return YES;
    }
    else
    {
        BOOL bValidate = [[self activeLayer] validateMenuItem:menuItem];
        if(!bValidate)  return bValidate;
        
        if (nTag == 349)                        return NO;          //layer->Merge selected layer
        else if (nTag == 381)                   return NO;          //layer->unselected
        else                                    return YES;
    }
    
    return YES;
}



@end
