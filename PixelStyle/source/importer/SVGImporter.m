#import "SVGImporter.h"
#import "CocoaLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSView.h"
#import "CenteringClipView.h"
#import "PSOperations.h"
#import "PSAlignment.h"
#import "PSController.h"
#import "PSWarning.h"
#import "PSVecLayer.h"

#import "SVGLayer.h"
#import "wdDrawingController.h"
#import "WDDrawing.h"
#import "WDSVGParser.h"
#import "WDLayer.h"

extern IntSize getDocumentSize(char *path);

@implementation SVGImporter

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
    // Load nib file
    [NSBundle loadNibNamed:@"SVGContent" owner:self];
    
    // Run the scaling panel
//    [m_idScalePanel center];
//    m_sISTrueSize = getDocumentSize((char *)[path fileSystemRepresentation]);
//    m_sISSize.width = m_sISTrueSize.width; m_sISSize.height = m_sISTrueSize.height;
//    [m_idSizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", m_sISSize.width, m_sISSize.height]];
//    [m_idScaleSlider setIntValue:2];
//    [NSApp runModalForWindow:m_idScalePanel];
//    [m_idScalePanel orderOut:self];
    
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
    
        // load the whole drawing if we are either asked to or we failed to find a thumbnail
    NSError *outError = nil;
        WDDrawing   *drawing = [[WDDrawing alloc] initWithUnits:@"Points"];
        [drawing beginSuppressingNotifications];
        WDSVGParser *svgParser = [[WDSVGParser alloc] initWithDrawing:drawing];
        [xmlParser setDelegate:svgParser];
        [xmlParser parse];
        if ([svgParser hadMemoryWarning]) {
            if (outError) {
                outError = [[NSError alloc] initWithDomain:@"WDDocument" code:101 userInfo:nil];
                [[PSController seaWarning] addMessage:LOCALSTR(@"SVG message", @"PixelStyle is unable to open the given SVG file because not enough memory.") level:kHighImportance];
                		return NO;
            }
        } else if ([svgParser hadErrors]) {
            if (outError) {
                outError = [[NSError alloc] initWithDomain:@"WDDocument" code:102 userInfo:nil];
                [[PSController seaWarning] addMessage:LOCALSTR(@"SVG message", @"PixelStyle is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on PixelStyle's website.") level:kHighImportance];
                return NO;
            }
        }
    
        [drawing endSuppressingNotifications];
    
    
    for(WDLayer *layer in drawing.layers)
    {
        SVGLayer *svgLayer = [[SVGLayer alloc] initWithLayer:layer document:doc];
        if (svgLayer == NULL)            break;
        
        [svgLayer setName:[layer name]];
        [svgLayer setOpacity:[layer opacity]*255.0];
        [svgLayer setVisible:layer.visible];
       
        // Add the layer
        [[doc contents] addLayerObject:svgLayer];
    }
    
//    // Position the new layer correctly
//    [[(PSOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
//    [[(PSOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
        
    
    return YES;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)update:(id)sender
{
	double factor;
	
	switch ([m_idScaleSlider intValue]) {
		case 0:
			factor = 0.5;
		break;
		case 1:
			factor = 0.75;
		break;
		case 2:
			factor = 1.0;
		break;
		case 3:
			factor = 1.5;
		break;
		case 4:
			factor = 2.0;
		break;
		case 5:
			factor = 3.75;
		break;
		case 6:
			factor = 5.0;
		break;
		case 7:
			factor = 7.5;
		break;
		case 8:
			factor = 10.0;
		break;
		case 9:
			factor = 25.0;
		break;
		case 10:
			factor = 50.0;
		break;
		default:
			factor = 1.0;
		break;
	}
	
	m_sISSize.width = m_sISTrueSize.width * factor;
	m_sISSize.height = m_sISTrueSize.height * factor;
	
	[m_idSizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", m_sISSize.width, m_sISSize.height]];
}

@end
