#import "SVGContent.h"
#import "SVGLayer.h"
#import "PSController.h"
#import "PSDocumentController.h"
#import "PSWarning.h"

#import "SVGLayer.h"
#import "WDDrawing.h"
#import "WDSVGParser.h"
#import "WDLayer.h"

IntSize getDocumentSize(char *path)
{
	FILE *file;
	char header[2056], dstr[128];
	IntSize result = IntMakeSize(0, 0);
	int ivalue;
	char *pos, *value = NULL;
	BOOL quote;
	int tagID, size;
		
	file = fopen(path, "rb");
	fread(header, sizeof(char), 2048, file);
	pos = header;
	quote = NO;
	tagID = 0;
	
	while (pos - header < 2048 && (result.width == 0 || result.height == 0)) {

		if (quote) {
			if (tagID == 1 || tagID == 2) {
				
				ivalue = -1;
				size = pos - value;
				if (size > 127) size = 127;
				if (strncmp(pos, "pt", 2) == 0 || pos[0] == '"') {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 1.25;
				}
				else if (strncmp(pos, "pc", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 15.0;
				}
				else if (strncmp(pos, "mm", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 3.543307;
				}
				else if (strncmp(pos, "cm", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 35.43307;
				}
				else if (strncmp(pos, "in", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 90.0;
				}
				if (ivalue != -1) {
					if (tagID == 1)
						result.width = ivalue;
					else
						result.height = ivalue;
					tagID = 0;
				}
			
			}				
		}
			
	
		if (pos[0] == '"') {
			
			if (quote) {
				quote = NO;
				tagID = 0;
			}
			else {
				quote = YES;
				value = pos + 1;
			}
		
		}
		
		if (!quote) {
			if (strncmp(pos, "width", 5) == 0) {
				tagID = 1;
			}
			if (strncmp(pos, "height", 6) == 0) {
				tagID = 2;
			}
		}
		
		pos++;
	
	}
	
	fclose(file);
	
	return result;
}

@implementation SVGContent

+ (BOOL)typeIsViewable:(NSString *)aType
{
	return [[PSDocumentController sharedDocumentController] type: aType isContainedInDocType: @"SVG document (SVG)"];
}
//
//- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
//{
//	NSString *importerPath;
//	id imageRep, layer;
//	NSImage *image;
//	BOOL test;
//	NSString *path_in, *path_out, *width_arg, *height_arg;
//	NSArray *args;
//	NSTask *task;
//	
//	// Initialize superclass first
//	if (![super initWithDocument:doc])
//		return NULL;
//		
//	// Load nib file
//	[NSBundle loadNibNamed:@"SVGContent" owner:self];
//	
//	// Run the scaling panel
//	[m_idScalePanel center];
//	trueSize = getDocumentSize((char *)[path fileSystemRepresentation]);
//	size.width = trueSize.width; size.height = trueSize.height;
//	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
//	[m_idScaleSlider setIntValue:2];
//	[NSApp runModalForWindow:m_idScalePanel];
//	[m_idScalePanel orderOut:self];
//	
//	// Add all plug-ins to the array
//	importerPath = [[gMainBundle builtInPlugInsPath] stringByAppendingString:@"/SVGImporter.app/Contents/MacOS/SVGImporter"];
//	if ([gFileManager fileExistsAtPath:importerPath]) {
//		if (![gFileManager fileExistsAtPath:@"/tmp/seaimport"])
//            //[gFileManager createDirectoryAtPath:@"/tmp/seaimport" attributes:NULL];
//            [gFileManager createDirectoryAtPath:@"/tmp/seaimport" withIntermediateDirectories:YES attributes:NULL error:NULL];
//		path_in = path;
//		path_out = [NSString stringWithFormat:@"/tmp/seaimport/%@.png", [[path lastPathComponent] stringByDeletingPathExtension]];
//		if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
//			width_arg = [NSString stringWithFormat:@"%d", size.width];
//			height_arg = [NSString stringWithFormat:@"%d", size.height];
//			args = [NSArray arrayWithObjects:path_in, path_out, width_arg, height_arg, NULL];
//		}
//		else {
//			args = [NSArray arrayWithObjects:path_in, path_out, NULL];
//		}
//		[m_idWaitPanel center];
//		[m_idWaitPanel makeKeyAndOrderFront:self];
//		task = [NSTask launchedTaskWithLaunchPath:importerPath arguments:args];
//		[m_idSpinner startAnimation:self];
//		while ([task isRunning]) {
//			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
//		}
//		[m_idSpinner stopAnimation:self];
//		[m_idWaitPanel orderOut:self];
//	}
//	else {
//		[[PSController seaWarning] addMessage:LOCALSTR(@"SVG message", @"PixelStyle is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on PixelStyle's website.") level:kHighImportance];
//		[self autorelease];
//		return NULL;
//	}
//
//	// Open the image
//	image = [[NSImage alloc] initByReferencingFile:path_out];
//	if (image == NULL) {
//		[image autorelease];
//		[self autorelease];
//		return NULL;
//	}
//	
//	// Form a bitmap representation of the file at the specified path
//	imageRep = NULL;
//	if ([[image representations] count] > 0) {
//		imageRep = [[image representations] objectAtIndex:0];
//		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
//			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
//		}
//	}
//	if (imageRep == NULL) {
//		[image autorelease];
//		[self autorelease];
//		return NULL;
//	}
//	
//	// Determine the height and width of the image
//	m_nHeight = [imageRep pixelsHigh];
//	m_nWidth = [imageRep pixelsWide];
//	
//	// Determine the resolution of the image
//	m_nXres = m_nYres = 72;
//	
//	// Determine the image type
//	test = [[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace];
//	test = test || [[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace];
//	if (test) 
//		m_nType = XCF_GRAY_IMAGE;
//	else
//		m_nType = XCF_RGB_IMAGE;
//		
//	// Create the layer
//	layer = [[SVGLayer alloc] initWithImageRep:imageRep document:doc spp:(m_nType == XCF_RGB_IMAGE) ? 4 : 2];
//	if (layer == NULL) {
//		[image autorelease];
//		[self autorelease];
//		return NULL;
//	}
//	m_arrLayers = (NSMutableArray*)[NSArray arrayWithObject:layer];
//	[m_arrLayers retain];
//	
//	// Now forget the NSImage
//	[image autorelease];
//	//[gFileManager removeFileAtPath:path_out handler:NULL];
//    [gFileManager removeItemAtPath:path_out error:NULL];
//	
//	return self;
//}


- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
    // Initialize superclass first
    if (![super initWithDocument:doc])
        return NULL;
    
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
            NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
            NSString *sKey = [NSString stringWithFormat:@"%@ is unable to open the given SVG file because not enough memory.",sProductName];
            [[PSController seaWarning] addMessage:LOCALSTR(@"SVG message", sKey) level:kHighImportance];
            return NULL;
        }
    } else if ([svgParser hadErrors]) {
        if (outError) {
            outError = [[NSError alloc] initWithDomain:@"WDDocument" code:102 userInfo:nil];
            NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
            NSString *sKey = [NSString stringWithFormat:@"%@ is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on %@'s website.",sProductName,sProductName];
            [[PSController seaWarning] addMessage:LOCALSTR(@"SVG message", sKey) level:kHighImportance];
            return NULL;
        }
    }
    
    [drawing endSuppressingNotifications];
    
    // Determine the height and width of the image
    m_nWidth = drawing.dimensions.width;
    m_nHeight = drawing.dimensions.height;
    
    
    for(WDLayer *layer in drawing.layers)
    {
        SVGLayer *svgLayer = [[SVGLayer alloc] initWithLayer:layer document:doc];
        if (svgLayer == NULL)            break;
        
        [svgLayer setName:[layer name]];
        [svgLayer setOpacity:[layer opacity]*255.0];
        [svgLayer setVisible:layer.visible];
        
        // Add the layer
        [self addLayerObject:svgLayer];
    }
    
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
    
    return self;
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
	
	size.width = trueSize.width * factor;
	size.height = trueSize.height * factor;
	
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
}

@end
