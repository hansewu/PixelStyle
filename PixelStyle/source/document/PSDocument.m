#import "PixelStyleProjectContent.h"
#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "PSDocument.h"
#import "PSView.h"
#ifdef USE_CENTERING_CLIPVIEW
#import "CenteringClipView.h"
#endif
#import "PSController.h"
#import "PSWarning.h"
#import "PSWhiteboard.h"
#import "UtilitiesManager.h"
#import "TIFFExporter.h"
#import "XCFExporter.h"
#import "PNGExporter.h"
#import "JPEGExporter.h"
#import "PSPrefs.h"
#import "PSSelection.h"
#import "PSLayer.h"
#import "PSHelpers.h"
#import "PegasusUtility.h"
#import "PSPrintView.h"
#import "PSDocumentController.h"
#import "Units.h"
#import "OptionsUtility.h"
#import "PSWindowContent.h"

#import "PSMemoryManager.h"
#import "PSTools.h"
#import "AbstractTool.h"

#import "ConfigureInfo.h"
#import "iRate.h"

#import "PSFileImporter.h"

#if (defined(TRIAL_VERSION) || defined(REGISTER_VERSION))
#import "VerifyRegistration.h"
#endif

extern int globalUniqueDocID;

extern IntPoint gScreenResolution;

extern BOOL globalReadOnlyWarning;

enum {
	kNoStart = 0,
	kNormalStart = 1,
	kOpenStart = 2,
	kPasteboardStart = 3,
	kPlugInStart = 4
};

@implementation PSDocument

- (id)init
{
	int dtype, dwidth, dheight, dres;
	BOOL dopaque;
	
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset m_nUniqueLayerID
	m_nUniqueLayerID = -1;
	m_nUniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	m_nUniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	m_idWhiteboard = NULL;
	m_bRestoreOldType = NO;
	m_bCurrent = YES;
	m_nSpecialStart = kNormalStart;
	
	// Set the measure style
	m_nMeasureStyle = [(PSDocumentController *)[NSDocumentController sharedDocumentController] units];
	
	// Create m_idContents
	dtype = [(PSDocumentController *)[NSDocumentController sharedDocumentController] type];
	dwidth = [(PSDocumentController *)[NSDocumentController sharedDocumentController] width];
	dheight = [(PSDocumentController *)[NSDocumentController sharedDocumentController] height];
	dres = [(PSDocumentController *)[NSDocumentController sharedDocumentController] resolution];
	dopaque = [(PSDocumentController *)[NSDocumentController sharedDocumentController] opaque];
	m_idContents = [[PSContent alloc] initWithDocument:self type:dtype width:dwidth height:dheight res:dres opaque:dopaque];
	
    
    m_bWantCloseWindow = false;
    
	return self;
}

- (id)initWithPasteboard
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset m_nUniqueLayerID
	m_nUniqueLayerID = -1;
	m_nUniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	m_nUniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	m_idWhiteboard = NULL;
	m_bRestoreOldType = NO;
	m_bCurrent = YES;
	m_nSpecialStart = kPasteboardStart;
	
	// Set the measure style
	m_nMeasureStyle = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];
	
	// Create m_idContents
	m_idContents = [[PSContent alloc] initFromPasteboardWithDocument:self];
	
	// Mark document as dirty
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path ofType:(NSString *)type
{
	// Initialize superclass first
	if (![super init])
		return NULL;
    
    m_timeAwake = [NSDate timeIntervalSinceReferenceDate];
	
	// Reset m_nUniqueLayerID
	m_nUniqueLayerID = -1;
	m_nUniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	m_nUniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	m_idWhiteboard = NULL;
	m_bRestoreOldType = NO;
	m_bCurrent = YES;
	m_nSpecialStart = kOpenStart;
	
	// Set the measure style
	m_nMeasureStyle = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];
	
	// Do required work
	if ([self readFromFile:path ofType:type]) {
//        NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/samples"];
//        if (![[path stringByDeletingPathExtension] hasSuffix:@"CRASHTAG"] && ([path rangeOfString:sPath].length == 0))
        if (![[path stringByDeletingPathExtension] hasSuffix:@"CRASHTAG"]) {
            [self setFileURL:[NSURL fileURLWithPath:path]];
        }
        
		[self setFileType:type];
	}
	else {
		[self autorelease];
		return NULL;
	}
	
	return self;
}

- (id)initWithData:(unsigned char *)data type:(int)type width:(int)width height:(int)height
{
	// Initialize superclass first
	if (![super init])
		return NULL;
	
	// Reset m_nUniqueLayerID
	m_nUniqueLayerID = -1;
	m_nUniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	m_nUniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	m_idWhiteboard = NULL;
	m_bRestoreOldType = NO;
	m_bCurrent = YES;
	m_idContents = [[PSContent alloc] initWithDocument:self data:data type:type width:width height:height res:72];
	m_nSpecialStart = kPlugInStart;

	// Set the measure style
	m_nMeasureStyle = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];

	// Increment change count
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (void)initPluginExporterSupportTypes
{
    if (m_exporterPluginsSupportTypes == nil) {
        m_exporterPluginsSupportTypes = [[NSMutableArray alloc] init];
        int count = 0;
        char** types = plugin_exporter_GetAllSupportedTypes(&count);
        for (int i = 0; i < count; i++) {
            [m_exporterPluginsSupportTypes addObject:[NSString stringWithUTF8String:types[i]]];
        }
        if (count > 0 && types != NULL) {
            for (int i = 0; i < count; i++) {
                free(types[i]);
            }
            free(types);
        }
    }
}

- (void)awakeFromNib
{
	id seaView;
	#ifdef USE_CENTERING_CLIPVIEW
	id newClipView;
	#endif
	
    
	// Believe it or not sometimes this function is called after it has already run
	if (m_idWhiteboard == NULL) {
		m_idExporters = [NSArray arrayWithObjects:
                         m_idPSExporter,
                         m_idJpegExporter,
                         m_idPngExporter,
                         m_idJp2Exporter,
                         m_idTiffExporter,
                         m_idPdfExport,
                         m_idBmpExport,
                         m_idGifExporter,
                         m_idSvgExporter,
                         NULL];
		[m_idExporters retain];
        
        [self initPluginExporterSupportTypes];
        
		
		// Create a fresh m_idWhiteboard and selection manager
		m_idWhiteboard = [[PSWhiteboard alloc] initWithDocument:self];
		m_idSelection = [[PSSelection alloc] initWithDocument:self];
		[m_idWhiteboard update];
		
		// Setup the view to display the whiteboard
		seaView = [[PSView alloc] initWithDocument:self];
		#ifdef USE_CENTERING_CLIPVIEW
		newClipView = [[CenteringClipView alloc] initWithFrame:[[m_idView contentView] frame]];
		[(NSScrollView *)m_idView setContentView:newClipView];
		[newClipView autorelease];
		#endif
		[m_idView setDocumentView:seaView];
		[seaView release];
		[m_idView setDrawsBackground:NO];
		
		// set the frame of the window
		[m_idDocWindow setFrame:[self standardFrame] display:YES];
        [[m_idDocWindow contentView] windowWillResizeTo:((NSWindow *)m_idDocWindow).frame.size];
        [m_idDocWindow makeKeyAndOrderFront:nil];
		
		// Finally, if the doc has any warnings we are ready for them
		[(PSWarning *)[PSController seaWarning] triggerQueue: self];
	}
	
	[m_idDocWindow setAcceptsMouseMovedEvents:YES];
    
    // add by wyl   10.7
    SInt32 nVersMaj, nVersMin, nVersBugFix;
    Gestalt(gestaltSystemVersionMajor, &nVersMaj);
    Gestalt(gestaltSystemVersionMinor, &nVersMin);
    Gestalt(gestaltSystemVersionBugFix, &nVersBugFix);
    if (nVersMaj == 10 && nVersMin < 7)
    {  }
    else
        [m_idDocWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    [self performSelector:@selector(refreshDocumentView) withObject:nil afterDelay:0.05];
    
    //[self performSelectorInBackground:@selector(createSaveTimerInBackground) withObject:nil];
    
    if (m_timerSaveTemp == NULL) {
        m_lockSaveTemp = [[NSLock alloc] init];
        m_timerSaveTemp = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(saveDocumentToTemp) userInfo:nil repeats:YES];
        m_refreshTempDocFile = YES;
        m_nLastSaveIndex = 1;
        
    }
    
}


- (void)reInitData
{
    // Believe it or not sometimes this function is called after it has already run
    if (m_idWhiteboard == NULL) {
        m_idExporters = [NSArray arrayWithObjects:
                         m_idPSExporter,
                         m_idBmpExport,
                         m_idGifExporter,
                         m_idJpegExporter,
                         m_idJp2Exporter,
                         m_idPngExporter,
                         m_idTiffExporter,
                         //					 m_idXcfExporter,
                         m_idPdfExport,
                         m_idSvgExporter,
                         NULL];
        [m_idExporters retain];
        
        [self initPluginExporterSupportTypes];
        
        // Create a fresh m_idWhiteboard and selection manager
        m_idWhiteboard = [[PSWhiteboard alloc] initWithDocument:self];
        m_idSelection = [[PSSelection alloc] initWithDocument:self];
        [m_idWhiteboard update];

    }

    [self performSelector:@selector(refreshDocumentView) withObject:nil afterDelay:0.05];
}

-(void)refreshDocumentView
{
    [[m_idView documentView] setNeedsDisplay:YES];
}

- (void)dealloc
{
//	// Then get rid of stuff that's no longer needed
//	if (m_idSelection) [m_idSelection autorelease];
//	if (m_idWhiteboard) [m_idWhiteboard autorelease];
//	if (m_idContents) [m_idContents autorelease];
//	if (m_idExporters) [m_idExporters autorelease];
		
    [self releaseData];
	// Finally call the super
	[super dealloc];
}

-(void)releaseData
{
    // Then get rid of stuff that's no longer needed
    if (m_idSelection) {[m_idSelection autorelease]; m_idSelection = nil;}
    if (m_idWhiteboard) {[m_idWhiteboard autorelease]; m_idWhiteboard = nil;}
    if (m_idContents) {[m_idContents autorelease]; m_idContents = nil;}
    if (m_idExporters) {[m_idExporters autorelease]; m_idExporters = nil;}
    if (m_idView) {
        [m_idView setDocumentView:nil];
    }
    
}

- (void)revertData
{
    if (m_idSelection) {[m_idSelection autorelease]; m_idSelection = nil;}
    if (m_idWhiteboard) {[m_idWhiteboard autorelease]; m_idWhiteboard = nil;}
    if (m_idContents) {[m_idContents autorelease]; m_idContents = nil;}
    if (m_idExporters) {[m_idExporters autorelease]; m_idExporters = nil;}
    
    NSString *file = [[self fileURL] path];
    NSString *fileType = [self fileType];
    [self initWithContentsOfFile:file ofType:fileType];
//    [self awakeFromNib];
    [self reInitData];
    
    [[self undoManager] removeAllActions];
    [[self helpers] boundariesAndContentChanged:YES];
    [(UtilitiesManager *)[PSController utilitiesManager] activate:self];
    NSPoint point;
    point = [m_idDocWindow mouseLocationOutsideOfEventStream];
    [[self docView] updateRulerMarkings:point andStationary:NSMakePoint(-256e6, -256e6)];
    
    
}

- (IBAction)saveDocument:(id)sender
{
    m_saveActionType = 0;
	m_bCurrent = YES;
    
    //[super saveDocument:sender];
    
    NSURL *fileUrl = [self fileURL];
    //int layerCount = [m_idContents layerCount]; //图片多于1层视为工程并置为导出
    NSString *fileType = [self fileType];
    if (fileUrl != nil && ![fileType isEqualToString:@"pixelstyle.psdb"] && ![fileType isEqualToString:@"PixelStyle image (PSDB)"])
    {
        [super saveDocumentAs:sender];
    }else{
        [super saveDocument:sender];
    }
}

- (IBAction)saveDocumentAs:(id)sender
{
    m_saveActionType = 1;
	m_bCurrent = YES;
	[super saveDocumentAs:sender];
    //[super saveDocumentTo:sender];
}

- (IBAction)saveDocumentTo:(id)sender
{
    m_saveActionType = 2;
    [super saveDocumentTo:sender];
}

- (id)contents
{
	return m_idContents;
}

- (id)whiteboard
{
	return m_idWhiteboard;
}

- (id)selection
{
	return m_idSelection;
}

- (id)operations
{
	return m_idOperations;
}

- (id)tools
{
	return m_idTools;
}

- (id)helpers
{
	return m_idHelpers;
}

//- (id)memoryManager
//{
//    return m_idMemoryManager;
//}

- (id)warnings
{
	return m_idWarnings;
}

- (id)tips
{
    return m_idTips;
}

- (id)pluginData
{
	return m_idPluginData;
}

- (id)docView
{
	return [m_idView documentView];
}

- (id)shadowView
{
    return m_idShadowView;
}

- (id)window
{
	return m_idDocWindow;
}

- (void)updateWindowColor
{
	[m_idView setBackgroundColor:[[PSController m_idPSPrefs] windowBack]];
}

- (id)textureExporter
{
	return m_idTextureExporter;
}

- (BOOL)readFromFile:(NSString *)path ofType:(NSString *)type
{
	BOOL readOnly = NO;
	
	// Determine which document we have and act appropriately
	if ([XCFContent typeIsEditable: type]) {
		
		// Load a GIMP or XCF document
		m_idContents = [[XCFContent alloc] initWithDocument:self contentsOfFile:path];
		if (m_idContents == NULL) {
			return NO;
		}
		
	} else if ([CocoaContent typeIsEditable: type forDoc: self]) {
		
		// Load a PNG, TIFF, JPEG document
		// Or a GIF or JP2 document
		m_idContents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:path];
		if (m_idContents == NULL) {
			return NO;
		}
		
	} else if ([CocoaContent typeIsViewable: type forDoc: self]) {
	
		// Load a PDF, PCT, BMP document
		m_idContents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:path];
		if (m_idContents == NULL) {
			return NO;
		}
		readOnly = YES;
			
	} else if ([XBMContent typeIsEditable: type]) {
	
		// Load a X bitmap document
		m_idContents = [[XBMContent alloc] initWithDocument:self contentsOfFile:path];
		if (m_idContents == NULL) {
			return NO;
		}
		readOnly = YES;
		
	} else if ([SVGContent typeIsViewable: type]) {
	
		// Load a SVG document
		m_idContents = [[SVGContent alloc] initWithDocument:self contentsOfFile:path];
		if (m_idContents == NULL) {
			return NO;
		}
//		readOnly = YES;
		
    }else if ([PixelStyleProjectContent typeIsEditable:type]) {
        
        // Load a PixelStyleProject document
        m_idContents = [[PixelStyleProjectContent alloc] initWithDocument:self contentsOfFile:path];
        if (m_idContents == NULL) {
            return NO;
        }
        readOnly = NO;
        
    }
    else {
		// Handle an unknown document type
		NSLog(@"Unknown type passed to readFromFile:<%@>ofType:<%@>", path, type);
		return NO;
	}
	
	if (readOnly && !globalReadOnlyWarning) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"read only message", @"This file is in a read-only format, as such you cannot save this file. This warning will not be displayed for subsequent files in a read-only format.") forDocument: self level:kLowImportance];
		globalReadOnlyWarning = YES;
	}
	
	return YES;
}



- (BOOL)writeToFile:(NSString *)path ofType:(NSString *)type
{
//#ifdef TRIAL_VERSION
//    //VerifyRegistration  注册码机制
//    VerifyRegistration *verifyRegistration = [[VerifyRegistration alloc] initWithWindowNibName:@"VerifyRegistration"];
//    [verifyRegistration verifyRegistration];
// 
//    bool bRegisted = [verifyRegistration isRegisted];
//    
//    [verifyRegistration release];
//    
//    if(!bRegisted)  return false;
//    
//#endif
    
#if (defined(TRIAL_VERSION) || defined(REGISTER_VERSION))
    NSString *sRegisterBundlePath = [[NSBundle mainBundle] pathForResource:@"EccRegisterBundle" ofType:@"bundle"];
    
//    NSString *sRegisterBundlePath = [[[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"EccRegisterBundle.bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:sRegisterBundlePath];
    if (bundle && [bundle principalClass])
    {
        VerifyRegistration* verifyRegistration = [[bundle principalClass] sharedVerifyRegistration];
        if (verifyRegistration)
        {
            [verifyRegistration verifyRegistration];
            bool bRegisted = [verifyRegistration isRegisted];
            if(!bRegisted)  return false;
        }
        else    return false;
    }
    else    return false;
#endif

    
	BOOL result = NO;
	int i;
	
	for (i = 0; i < [m_idExporters count]; i++) {
		if ([[PSDocumentController sharedDocumentController]
			 type: type
			 isContainedInDocType:[[m_idExporters objectAtIndex:i] title]
			 ]) {
			[[m_idExporters objectAtIndex:i] writeDocument:self toFile:path];
			result = YES;
		}
	}
    
    if (!result) {
        
        int pluginState = plugin_ExportBufferToFile([path UTF8String], self);
        
        if (pluginState == 0) {
            result = YES;
        }
    }
	
	if (!result){
		NSLog(@"Unknown type passed to writeToFile:<%@>ofType:<%@>", path, type);
	}
    
//#ifndef TRIAL_VERSION
#ifdef APPSTORE_VERSION
    if (result && m_bWantCloseWindow == NO) [self promptForRating];
#endif
    
	return result;
}



- (void)printShowingPrintPanel:(BOOL)showPanels
{
	PSPrintView *printView;
	NSPrintOperation *op;
    
	// Create a print operation for the given view
    NSPrintInfo *customPrint = [self printInfo];
    [customPrint setTopMargin:0];
    [customPrint setBottomMargin:0];
    [customPrint setLeftMargin:0];
    [customPrint setRightMargin:0];
    [customPrint setHorizontalPagination:NSFitPagination];
    [customPrint setVerticalPagination:NSFitPagination];
//    [customPrint setHorizontallyCentered:YES];
//    [customPrint setVerticallyCentered:YES];
	printView = [[PSPrintView alloc] initWithDocument:self];
	op = [NSPrintOperation printOperationWithView:printView printInfo:customPrint];
	
	// Insist the view be scaled to fit
	//[op setShowPanels:showPanels];
    [op setShowsPrintPanel:showPanels];
    [self runModalPrintOperation:op delegate:NULL didRunSelector:NULL contextInfo:NULL];

	// Release print view
	[printView autorelease];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    
	int i, exporterIndex = -1;
	
	// Implement the view that allows us to select layers
	[savePanel setAccessoryView:m_idAccessoryView];
    [savePanel setExtensionHidden:NO];
	
	// Find the default exporter's index
	for (i = 0; i < [m_idExporters count]; i++) {
		if ([[PSDocumentController sharedDocumentController]
			 type: [self fileType]
			 isContainedInDocType:[[m_idExporters objectAtIndex:i] title]
			 ]) {
			exporterIndex = i;
			break;
		}
	}
	
	// Deal with the rare case where we don't find one
	if (exporterIndex == -1) {
        exporterIndex = [m_idExporters count] - 1;
		[self setFileType:[[m_idExporters objectAtIndex:[m_idExporters count] - 1] title]];
	}
    
	// Add in our m_idExporters
    //NSMutableArray *titles
	[m_idExportersPopUp removeAllItems];
    [m_idExportersPopUp addItemWithTitle:[[m_idExporters objectAtIndex:0] title]];
	for (i = 1; i < [m_idExporters count]; i++)
		[m_idExportersPopUp addItemWithTitle:[[[m_idExporters objectAtIndex:i] extension] uppercaseString]];
    
    for (int i = 0; i < [m_exporterPluginsSupportTypes count]; i++) {
        [m_idExportersPopUp addItemWithTitle:[[m_exporterPluginsSupportTypes objectAtIndex:i] uppercaseString]];
    }
    
    
//    if (m_saveActionType == 0) {
//        [m_idExportersPopUp removeAllItems];
//        [m_idExportersPopUp addItemWithTitle:[[m_idExporters objectAtIndex:0] title]];
//    }
    
    //set defalut
    exporterIndex = 0;
    [m_idExportersPopUp selectItemAtIndex:exporterIndex];
    
	//[savePanel setRequiredFileType:[[m_idExporters objectAtIndex:exporterIndex] extension]];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:[[m_idExporters objectAtIndex:exporterIndex] extension]]];
    [self setFileType:[[m_idExporters objectAtIndex:exporterIndex] title]];
    [m_idOptionsButton setEnabled:[[m_idExporters objectAtIndex:exporterIndex] hasOptions]];
    [m_idOptionsSummary setStringValue:[[m_idExporters objectAtIndex:exporterIndex] optionsString]];
    
	
	return YES;
}

- (IBAction)showExporterOptions:(id)sender
{
	[[m_idExporters objectAtIndex:[m_idExportersPopUp indexOfSelectedItem]] showOptions:self];
	[m_idOptionsSummary setStringValue:[[m_idExporters objectAtIndex:[m_idExportersPopUp indexOfSelectedItem]] optionsString]];
}

- (IBAction)exporterChanged:(id)sender
{
	//[(NSSavePanel *)[m_idExportersPopUp window] setRequiredFileType:[[m_idExporters objectAtIndex:[m_idExportersPopUp indexOfSelectedItem]] extension]];
    
    int exporterIndex = [m_idExportersPopUp indexOfSelectedItem];
    if (exporterIndex < [m_idExporters count]) {
        id selectedExporter = [m_idExporters objectAtIndex:exporterIndex];
        [(NSSavePanel *)[m_idExportersPopUp window] setAllowedFileTypes:[NSArray arrayWithObject:[selectedExporter extension]]];
        [self setFileType:[selectedExporter title]];
        [m_idOptionsButton setEnabled:[selectedExporter hasOptions]];
        [m_idOptionsSummary setStringValue:[selectedExporter optionsString]];
    }else{
        int index = exporterIndex - [m_idExporters count];
        NSString* extension = [m_exporterPluginsSupportTypes objectAtIndex:index];
        [(NSSavePanel *)[m_idExportersPopUp window] setAllowedFileTypes:[NSArray arrayWithObject:extension]];
        [self setFileType:extension];
        [m_idOptionsButton setEnabled:NO];
        [m_idOptionsSummary setStringValue:@""];
    }
    
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
}

- (void)windowDidEndSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	NSPoint point;
	
	[(UtilitiesManager *)[PSController utilitiesManager] activate:self];
	if ([m_idDocWindow attachedSheet])
		[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = [m_idDocWindow mouseLocationOutsideOfEventStream];
	[[self docView] updateRulerMarkings:point andStationary:NSMakePoint(-256e6, -256e6)];
	[(OptionsUtility *)[(UtilitiesManager *)[PSController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	NSPoint point;
	
	[m_idHelpers endLineDrawing];
	if ([m_idDocWindow attachedSheet])
		[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = NSMakePoint(-256e6, -256e6);
	[[self docView] updateRulerMarkings:point andStationary:point];
	[(OptionsUtility *)[(UtilitiesManager *)[PSController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
	[gColorPanel orderOut:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[self docView] clearScrollingMode];
}

//- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
//{
//    [[(NSWindow *)m_idDocWindow contentView] windowWillResizeTo:frameSize];
//    
//    return frameSize;
//}

- (void)windowDidResize:(NSNotification *)notification
{
    NSRect frame = [(NSWindow *)m_idDocWindow frame];
    
    [[(NSWindow *)m_idDocWindow contentView] windowWillResizeTo:frame.size];
}

// modify by wyl
//- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
//{
////	 I don't know what would call this besides the doc window
//	if(sender != m_idDocWindow){
//		NSLog(@"An unknown window (%@) has attempted to zoom.", sender);
//		return NSZeroRect;
//	}
//	return [self standardFrame];
//}


- (NSRect)standardFrame
{
	NSRect frame;
	float xScale, yScale;
	NSRect rect;
	
	// Get the old frame so we can preserve the top-left origin
	frame = [m_idDocWindow frame];
	float minHeight = 550;

	// Store the initial conditions of the window 
	rect.origin.x = frame.origin.x;
	rect.origin.y = frame.origin.y;
	xScale = [m_idContents xscale];
	yScale = [m_idContents yscale];
	rect.size.width = [(PSContent *)m_idContents width]  * xScale + 100;
	rect.size.height = [(PSContent *)m_idContents height] * yScale + 50;
		
	 // Remember the rulers have dimension
	 if([[PSController m_idPSPrefs] rulers]){
		 rect.size.width += 22;
		 rect.size.height += 31;
	 }
	// Titlebar
	rect.size.height += 22;
	minHeight += 22;
	// Toolbar
	if([[m_idDocWindow toolbar] isVisible])
    {
		// This is innacurate because the toolbar can actually change in height,
		// depending on settings (labels, small etc...)
		rect.size.height += 35;
		minHeight += 35;
	}
	// Options Bar
	rect.size.height += [[m_idDocWindow contentView] sizeForRegion: kOptionsBar];
	 // Status Bar
	rect.size.height += [[m_idDocWindow contentView] sizeForRegion: kStatusBar];
	
	 // Layers
    rect.size.width += [[m_idDocWindow contentView] sizeForRegion: kMyToolsBar];
	rect.size.width += [[m_idDocWindow contentView] sizeForRegion: kSidebar];
	
	// Disallow ridiculously small or large windows
	NSRect defaultFrame = [[m_idDocWindow screen] frame];
	if (rect.size.width > defaultFrame.size.width) rect.size.width = defaultFrame.size.width;
	if (rect.size.height > defaultFrame.size.height) rect.size.height = defaultFrame.size.height;
	if (rect.size.width < 724) rect.size.width = 724;
	if (rect.size.height < minHeight) rect.size.height = minHeight;
	
	// Reset the origin's y-value to keep the titlebar level
	rect.origin.y = rect.origin.y - rect.size.height + frame.size.height;
	
	return rect;
}


- (BOOL)windowShouldClose:(id)sender
{
    NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
    
    if (ABS(current - m_timeAwake) < 1.0)
    {
        return NO;
    }
    else if (ABS(current - m_timeAwake) < 5.0)
    {
        if (m_idContents)
        {
            if ([m_idContents layerCount] < 5)
            {
                return YES;
            }
            if ([m_idContents layerCount] < 15 && ABS(current - m_timeAwake) > 3.0)
            {
                return YES;
            }
            return NO;
            
        }
        else
        {
            return NO;
        }
    }
   
    return YES;
}

- (void)close
{
    [m_timerSaveTemp invalidate];
    m_timerSaveTemp = nil;
    
    if (m_lockSaveTemp)
    {
        [m_lockSaveTemp release];
        m_lockSaveTemp = nil;
    }
    
    [[self docView] shutdown];
	[[PSController utilitiesManager] shutdownFor:self];
    [m_idContents shutdown];
    
    
    [self releaseData];
    
    [[PSController seaWarning] removeCrashInfoForKey:m_nUniqueDocID];
	// Then call our supervisor
	[super close];
}

- (void)saveDocumentToTemp
{
    [self performSelectorInBackground:@selector(saveDocumentToTempInBackground) withObject:nil];
}

- (void)saveDocumentToTempInBackground
{
    if (!m_refreshTempDocFile || !m_timerSaveTemp || ![m_timerSaveTemp isValid]) {
        return;
    }
    if (![m_lockSaveTemp tryLock]) {
        return;
    }
    m_refreshTempDocFile = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachedPath = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([paths count] > 0) {
        cachedPath = [paths objectAtIndex:0];
        cachedPath = [cachedPath stringByAppendingPathComponent:bundleID];
    }
    if (![fileManager fileExistsAtPath:cachedPath]) {
        [fileManager createDirectoryAtPath:cachedPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *oriPath = [self.fileURL path];
    NSString *fileName = @"Untitled";
    if (oriPath) {
        fileName = [[oriPath lastPathComponent] stringByDeletingPathExtension];
    }else{
        oriPath = @"no_original_path";
    }
    NSString *name0 = [NSString stringWithFormat:@"%@_%d_0_CRASHTAG.psdb", fileName, m_nUniqueDocID];
    NSString *name1 = [NSString stringWithFormat:@"%@_%d_1_CRASHTAG.psdb", fileName, m_nUniqueDocID];
    NSString *path0 = [cachedPath stringByAppendingPathComponent:name0];
    NSString *path1 = [cachedPath stringByAppendingPathComponent:name1];
    
    NSMutableDictionary *docInfo = [NSMutableDictionary dictionary];
    [docInfo setObject:oriPath forKey:@"crash original path"];
    
    if (m_nLastSaveIndex == 0) {
        [m_idPSExporter writeDocument:self toFile:path1];
        [docInfo setObject:path1 forKey:@"crash save path"];
        m_nLastSaveIndex = 1;
    }else{
        [m_idPSExporter writeDocument:self toFile:path0];
        [docInfo setObject:path0 forKey:@"crash save path"];
        m_nLastSaveIndex = 0;
    }
    [[PSController seaWarning] addCrashInfo:docInfo forKey:m_nUniqueDocID];
    
    [m_lockSaveTemp unlock];
    
}

- (void)refreshTempDocumentFile
{
    m_refreshTempDocFile = YES;
}

- (BOOL)current
{
	return m_bCurrent;
}

- (void)setCurrent:(BOOL)value
{
	m_bCurrent = value;
}


- (int)uniqueLayerID
{
	m_nUniqueLayerID++;
	return m_nUniqueLayerID;
}

- (int)uniqueFloatingLayerID
{
	m_nUniqueFloatingLayerID++;
	return m_nUniqueFloatingLayerID;
}

- (int)uniqueDocID
{
	return m_nUniqueDocID;
}

- (NSString *)windowNibName
{
    return @"PSDocument";
}

- (IBAction)customUndo:(id)sender
{
	[[self undoManager] undo];
    
    [[self helpers] layerAttributesChanged:kActiveLayer hold:YES];
}

- (IBAction)customRedo:(id)sender
{
	[[self undoManager] redo];
    
    [[self helpers] layerAttributesChanged:kActiveLayer hold:YES];
}

- (void)changeMeasuringStyle:(int)aStyle
{
	m_nMeasureStyle = aStyle;
}

- (int)measureStyle
{
	return m_nMeasureStyle;
}

- (BOOL)locked
{
	return m_bLocked || ([m_idDocWindow attachedSheet] != NULL);
}

- (void)lock
{
	m_bLocked = YES;
}

- (void)unlock
{
	m_bLocked = NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    BOOL bValidate = YES;
	id type = [self fileType];
	
	[m_idHelpers endLineDrawing];
	if ([menuItem tag] == 171) {
		if ([type isEqualToString:@"PDF Document"] || [type isEqualToString:@"PICT Document"] || [type isEqualToString:@"Graphics Interchange Format Image"] || [type isEqualToString:@"Windows Bitmap Image (BMP)"])
			return NO;
		if ([self isDocumentEdited] == NO)
			return NO;
	}
//	if ([menuItem tag] == 171 || ([menuItem tag] == 172)|| ([menuItem tag] == 174)) //save 、save  as 、export
//    {
//        VerifyRegistration *verifyRegistration = [[VerifyRegistration alloc] init];
//        bValidate = [verifyRegistration isRegisted];
//        [verifyRegistration release];
//    }
    
    
    
	if ([menuItem tag] == 180)
		bValidate = (![self locked] && [[self undoManager] canUndo]);
	if ([menuItem tag] == 181)
		bValidate = (![self locked] && [[self undoManager] canRedo]);

    
    if(bValidate)
    {
        //根据当前工具确定
        bValidate = [[[gCurrentDocument tools] currentTool] validateMenuItem:menuItem];
    }
    if(bValidate)
    {
        //根据选中层确定菜单是否可用
        bValidate = [[gCurrentDocument contents] validateMenuItem:menuItem];
    }
    
    return bValidate;
    
    
//	return YES;
}

//-(void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
//{
//    //注册
//    VerifyRegistration *verifyRegistration = [[[VerifyRegistration alloc] init] autorelease];
//    bool bRegisted = [verifyRegistration isRegisted];
//    if(!bRegisted)
//    {
//        NSRunAlertPanel(NSLocalizedString(@"Friendly reminding", nil), NSLocalizedString(@"Purchase the full version to export your projects now.", nil), NSLocalizedString(@"ok", nil), (NSString*)@"", (NSString*)@"");
//        
//        [self updateChangeCount:NSChangeCleared];
////        [m_idDocWindow close];
////        return;
//    }
//    
//    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
//}


- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(nullable id)delegate didSaveSelector:(nullable SEL)didSaveSelector contextInfo:(nullable void *)contextInfo
{
    if (m_saveActionType == 1 && ![typeName isEqualToString:@"pixelstyle.psdb"] && ![typeName isEqualToString:@"PixelStyle image (PSDB)"]) {
        saveOperation = NSSaveToOperation;
    }
    
    NSURL *fileUrl = [self fileURL];
   // int layerCount = [m_idContents layerCount]; //图片多于1层视为工程并置为导出
    if (m_saveActionType == 0 && fileUrl != nil && ![typeName isEqualToString:@"pixelstyle.psdb"] && ![typeName isEqualToString:@"PixelStyle image (PSDB)"])
    {
        saveOperation = NSSaveToOperation;
    }

    [super saveToURL:url ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    
}

-(void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    m_bWantCloseWindow = NO;
    if(contextInfo)
        m_bWantCloseWindow = YES;

    
    //例子的工程只要保存必须是另存
    NSURL *url = [self fileURL];
    if(url)
    {
        NSString *sPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/samples"];
        if ([[url path] rangeOfString:sPath].length > 0)
        {
            [self runModalSavePanelForSaveOperation:NSSaveAsOperation
                                           delegate:delegate
                                    didSaveSelector:didSaveSelector
                                        contextInfo:contextInfo];
            return;
        }
        else
            [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    }
    else
        [self runModalSavePanelForSaveOperation:NSSaveAsOperation
                                       delegate:delegate
                                didSaveSelector:didSaveSelector
                                    contextInfo:contextInfo];
    
  //  if (![self fileURL] && url)
   //     [self setFileURL:url];
}


- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	// Remember the old type
	m_strOldType = [self fileType];
	[m_strOldType retain];
    
	if (saveOperation == NSSaveToOperation)
    {
		m_bRestoreOldType = YES;
	}
	
	// Check we're not meant to call someone
	if (delegate)
		NSLog(@"Delegate specified for save panel");
	
  if(!m_bWantCloseWindow)
        [super runModalSavePanelForSaveOperation:saveOperation delegate:self  didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:contextInfo];
    else
        [super runModalSavePanelForSaveOperation:saveOperation delegate:self  didSaveSelector:didSaveSelector contextInfo:contextInfo];

}



- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
    //NSString *saveType = [self autosavingFileType];
    //NSString * strOldType = [self fileType];
	// Restore the old type
//    if (didSave && m_saveActionType == 0 && ![saveType isEqualToString:@"PixelStyle image (PSDB)"]) {
//        [self setFileURL:nil];
//        [self setFileType:@"pixelstyle.psdb"];
//    }
	if (m_bRestoreOldType && didSave)
    {
		[self setFileType:m_strOldType];
		[m_strOldType autorelease];
		m_bRestoreOldType = NO;
	}
	else if (!didSave)
    {
		[self setFileType:m_strOldType];
		[m_strOldType autorelease];
		m_bRestoreOldType = NO;
	}
    
    if(m_bWantCloseWindow && didSave)
        [m_idDocWindow close];
 
//        [self updateChangeCount:NSChangeCleared];
    
    m_bWantCloseWindow = NO;
}

- (NSString *)fileTypeFromLastRunSavePanel
{
	return [self fileType];
}


- (NSScrollView *)scrollView
{
	return (NSScrollView *)m_idView;
}

- (id)dataSource
{
	return m_idDataSource;
}

- (BOOL)canResponseForView:(id)view
{
    id tool = [m_idTools currentTool];
    
    return [tool canResponseForView:view];
}

#pragma mark - rate
- (void)promptForRating
{
  //  [iRate sharedInstance].previewMode = YES;//TEST
    [iRate sharedInstance].appStoreID = APPLE_ID;
    [iRate sharedInstance].remindPeriod = 0.0;
    [iRate sharedInstance].promptAtLaunch = NO;
    [[iRate sharedInstance] promptIfNetworkAvailable];
}

- (void)alertRate
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *sProductName = [[mainBundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    NSString *sVersion = [[mainBundle infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *sRateKey = [NSString stringWithFormat:@"Rate%@%@", sProductName, sVersion];
    
    BOOL bRate = [[NSUserDefaults standardUserDefaults] boolForKey:sRateKey];
    if(bRate) return;
    
    
    NSString *messageText = @"Rate the app please";//NSLocalizedString(@"Rate the app please", nil);
    
    NSString *defaultButton = @"Rate it now";//NSLocalizedString(@"Rate it now", nil);
    
    NSString *alternateButton = @"No, thanks";//NSLocalizedString(@"No, thanks", nil);
    
    NSString *otherButton = @"Remind me later";//NSLocalizedString(@"Remind me later", nil);
    
    NSString *informativeText = @"If you enjoy using this app, would you mind taking a moment to rate it? Thanks for your support!";//NSLocalizedString(@"If you enjoy using this app, would you mind taking a moment to rate it? Thanks for your support!", nil);
    
    messageText = [mainBundle localizedStringForKey:messageText value:messageText table:@"InfoPlist"];
    
    defaultButton = [mainBundle localizedStringForKey:defaultButton value:defaultButton table:@"InfoPlist"];
    
    alternateButton = [mainBundle localizedStringForKey:alternateButton value:alternateButton table:@"InfoPlist"];
    
    otherButton = [mainBundle localizedStringForKey:otherButton value:otherButton table:@"InfoPlist"];
    
    informativeText = [mainBundle localizedStringForKey:informativeText value:informativeText table:@"InfoPlist"];
    
    
    NSAlert *alertRate = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton alternateButton:alternateButton otherButton:otherButton informativeTextWithFormat:@"%@",informativeText];
    
    
    
    [alertRate beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

#pragma mark - alert delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn)
    {
        NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        NSString *sVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString *sRateKey = [NSString stringWithFormat:@"Rate%@%@", sProductName, sVersion];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:sRateKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *str = [NSString stringWithFormat:
                         @"macappstore://itunes.apple.com/app/id%d?mt=12", APPLE_ID];
        
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:str]];
    }
}

@end
