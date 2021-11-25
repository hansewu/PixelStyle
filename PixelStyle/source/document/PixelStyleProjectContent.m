//
//  PixelStyleProjectContent.m
//  PixelStyle
//
//  Created by wyl on 15/9/18.
//
//
#import "PSDocumentController.h"
#import "PSDocument.h"
#import "WDDrawingController.h"
#import "PSLayer.h"
#import "PSTextLayer.h"
#import "PSVecLayer.h"
#import "PixelStyleProjectContent.h"
//#import "PSServerConfig.h"

@implementation PixelStyleProjectContent

+ (BOOL)typeIsEditable:(NSString *)aType
{
    return [[PSDocumentController sharedDocumentController] type: aType isContainedInDocType: @"PixelStyle image (PSDB)"];
}

- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
//    NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    if(!unarchiver)
    {
        NSRunAlertPanel(LOCALSTR(@"alert", @"Alert"), LOCALSTR(@"alert body", @"The file has been damaged."), LOCALSTR(@"ok", @"OK"),NULL, NULL);
        
        return NULL;
    }
    
    PSContent * idContents = [unarchiver decodeObjectForKey:@"content"];
    [unarchiver finishDecoding];
    
    if(!idContents)//老版本读新版本
    {
        NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        NSString *string = [NSString stringWithFormat:@"The current version is out-dated, please update to the latest version of %@.", sProductName];
        NSRunAlertPanel(LOCALSTR(@"alert", @"Alert"), LOCALSTR(@"alert body", string), LOCALSTR(@"ok", @"OK"),NULL, NULL);
        
//        [self performSelectorInBackground:@selector(configClientInfo) withObject:nil];
        
        return NULL;
    }
        
    id result = [self initWithDocumentAfterCoder:doc content:idContents];
    if(!result) return NULL;
    
    
    if(m_arrLayers == NULL)
        m_arrLayers = [[NSMutableArray alloc] init];
    for(int nIndex = 0; nIndex < [idContents layerCount]; nIndex++)
    {
        PSAbstractLayer *pLayer = nil;
        PSAbstractLayer *pLayerTemp =  [idContents layer:nIndex];
        if ([pLayerTemp layerFormat] == PS_RASTER_LAYER)
            pLayer = [[PSLayer alloc] initWithDocumentAfterCoder:doc layer:(PSLayer *)pLayerTemp];
        else if ([pLayerTemp layerFormat] == PS_TEXT_LAYER)
            pLayer = [[PSTextLayer alloc] initWithDocumentAfterCoder:doc layer:(PSTextLayer *)pLayerTemp];
        else if ([pLayerTemp layerFormat] == PS_VECTOR_LAYER)
            pLayer = [[PSVecLayer alloc] initWithDocumentAfterCoder:doc layer:(PSVecLayer *)pLayerTemp];
        else
        {}
        
        [m_arrLayers addObject:pLayer];
    }
    
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    //[idContents shutdown];
    [idContents release];
    
    return self;
}

-(id)initWithDocumentAfterCoder:doc content:(PSContent *)idContents
{
    // Initialize superclass first
    if (![super initWithDocument:doc])
        return NULL;
    // Set the data members to reasonable values
//    if ([idContents versionMajor] == 1 && [idContents versionMinor] == 0)
//    {
        m_nHeight = [idContents height];
        m_nWidth = [idContents width];
        m_nXres = [idContents xres];
        m_nYres = [idContents yres];
        m_nType = [idContents type];
        m_nSelectedChannel = [idContents selectedChannel];
        m_nActiveLayerIndex = [idContents activeLayerIndex];
//    }
    
     return self;
}

@end
