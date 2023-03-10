#import "PSPrefs.h"
#import "PSDocument.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "InfoUtility.h"
#import "PSWarning.h"
#import "PSView.h"
#import "Units.h"
#import "PSImageToolbarItem.h"
#import "WindowBackColorWell.h"
#import "PSHelpers.h"
#import <IOKit/graphics/IOGraphicsLib.h>

enum {
	kIgnoreResolution,
	kUse72dpiResolution,
	kUseScreenResolution
};

//int memoryCacheSize; //delete by lcz

IntPoint gScreenResolution;

static NSString*	PrefsToolbarIdentifier 	= @"Preferences Toolbar Instance Identifier";

static NSString*	GeneralPrefsIdentifier 	= @"General Preferences Item Identifier";
static NSString*	NewPrefsIdentifier 	= @"New Preferences Item Identifier";
static NSString*    ColorPrefsIdentifier = @"Color Preferences Item Identifier";

static int GetIntFromDictionaryForKey(CFDictionaryRef desc, CFStringRef key)
{
    CFNumberRef value;
    int num = 0;
    
	if ((value = CFDictionaryGetValue(desc, key)) == NULL || CFGetTypeID(value) != CFNumberGetTypeID())
        return 0;
    CFNumberGetValue(value, kCFNumberIntType, &num);
    
	return num;
}

CGDisplayErr GetMainDisplayDPI(float *horizontalDPI, float *verticalDPI)
{
    CGDisplayErr err = kCGErrorFailure;
    io_connect_t displayPort;
    CFDictionaryRef displayDict;
	CFDictionaryRef displayModeDict;
	CGDirectDisplayID displayID;
	
	// Get the main display
	displayModeDict = CGDisplayCurrentMode(kCGDirectMainDisplay);    
	displayID = kCGDirectMainDisplay;
	
    // Grab a connection to IOKit for the requested display
    displayPort = CGDisplayIOServicePort( displayID );
    if ( displayPort != MACH_PORT_NULL ) {
	
        // Find out what IOKit knows about this display
        displayDict = IOCreateDisplayInfoDictionary(displayPort, 0);
        if ( displayDict != NULL ) {
            const double mmPerInch = 25.4;
            double horizontalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, CFSTR(kDisplayHorizontalImageSize)) / mmPerInch;
            double verticalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, CFSTR(kDisplayVerticalImageSize)) / mmPerInch;

            // Make sure to release the dictionary we got from IOKit
            CFRelease(displayDict);

            // Now we can calculate the actual DPI
            // with information from the displayModeDict
            *horizontalDPI = (float)GetIntFromDictionaryForKey( displayModeDict, kCGDisplayWidth ) / horizontalSizeInInches;
            *verticalDPI = (float)GetIntFromDictionaryForKey( displayModeDict, kCGDisplayHeight ) / verticalSizeInInches;
            err = CGDisplayNoErr;
        }
		
    }
	
    return err;
}

@implementation PSPrefs

- (id)init
{
	NSData *tempData;
	float xdpi, ydpi;
	
	// Get bounderies from preferences
	if ([gUserDefaults objectForKey:@"boundaries"] && [gUserDefaults boolForKey:@"boundaries"])
		m_bLayerBounds = YES;
	else
		m_bLayerBounds = NO;

	// Get bounderies from preferences
	if ([gUserDefaults objectForKey:@"guides"] && [gUserDefaults boolForKey:@"guides"])
		m_bGuides = YES;
	else
		m_bGuides = NO;
	
	// Get m_bRulers from preferences
	if ([gUserDefaults objectForKey:@"rulers"] && [gUserDefaults boolForKey:@"rulers"])
		m_bRulers = YES;
	else
		m_bRulers = NO;
	
	// Determine if this is our first run from preferences
	if ([gUserDefaults objectForKey:@"version"] == NULL)  {
		m_bFirstRun = YES;
		[gUserDefaults setObject:@"0.1.9" forKey:@"version"];
	}
	else {
		if ([[gUserDefaults stringForKey:@"version"] isEqualToString:@"0.1.9"]) {
			m_bFirstRun = NO;
		}
		else {
			m_bFirstRun = YES;
			[gUserDefaults setObject:@"0.1.9" forKey:@"version"];
		}
	}
	
	// Get run count
	if (m_bFirstRun) {
		m_nRunCount = 1;
	}
	else {
		if ([gUserDefaults objectForKey:@"runCount"])
			m_nRunCount =  [gUserDefaults integerForKey:@"runCount"] + 1;
		else
			m_nRunCount = 1;
	}

	// Get memory cache size from preferences
	m_nMemoryCacheSize = 4096;
	if ([gUserDefaults objectForKey:@"memoryCacheSize"])
		m_nMemoryCacheSize = [gUserDefaults integerForKey:@"memoryCacheSize"];
	if (m_nMemoryCacheSize < 128 || m_nMemoryCacheSize > 32768)
		m_nMemoryCacheSize = 4096;

	// Get the use of the checkerboard pattern
	if ([gUserDefaults objectForKey:@"useCheckerboard"])
		m_bUseCheckerboard = [gUserDefaults boolForKey:@"useCheckerboard"];
	else
		m_bUseCheckerboard = YES;
	
	// Get the m_bFewerWarnings
	if ([gUserDefaults objectForKey:@"fewerWarnings"])
		m_bFewerWarnings = [gUserDefaults boolForKey:@"fewerWarnings"];
	else
		m_bFewerWarnings = NO;
		
	//  Get the m_bEffectsPanel
	if ([gUserDefaults objectForKey:@"effectsPanel"])
		m_bEffectsPanel = [gUserDefaults boolForKey:@"effectsPanel"];
	else
		m_bEffectsPanel = NO;
	
	//  Get the m_bSmartInterpolation
	if ([gUserDefaults objectForKey:@"smartInterpolation"])
		m_bSmartInterpolation = [gUserDefaults boolForKey:@"smartInterpolation"];
	else
		m_bSmartInterpolation = YES;
	
	//  Get the m_bOpenUntitled
	if ([gUserDefaults objectForKey:@"openUntitled"])
		m_bOpenUntitled = [gUserDefaults boolForKey:@"openUntitled"];
	else
		m_bOpenUntitled = YES;
		
	// Get the selection colour
	m_nSelectionColor = kBlackColor;
	if ([gUserDefaults objectForKey:@"selectionColor"])
		m_nSelectionColor = [gUserDefaults integerForKey:@"selectionColor"];
	if (m_nSelectionColor < 0 || m_nSelectionColor >= kMaxColor)
		m_nSelectionColor = kBlackColor;
	
	// If the layer bounds are white (the alternative is the selection color)
	m_bWhiteLayerBounds = YES;
	if ([gUserDefaults objectForKey:@"whiteLayerBounds"])
		m_bWhiteLayerBounds = [gUserDefaults boolForKey:@"whiteLayerBounds"];

	// Get the guide colour
	m_nGuideColor = kYellowColor;
	if ([gUserDefaults objectForKey:@"guideColor"])
		m_nGuideColor = [gUserDefaults integerForKey:@"guideColor"];
	if (m_nGuideColor < 0 || m_nGuideColor >= kMaxColor)
		m_nGuideColor = kYellowColor;
	
	// Determine the initial color (from preferences if possible)
	if ([gUserDefaults objectForKey:@"windowBackColor"] == NULL) {
//		m_clWindowBackColor = [[NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0] retain];
         m_clWindowBackColor = [[NSColor colorWithCalibratedRed:39.0/255.0 green:39.0/255.0 blue:39.0/255.0 alpha:1.0] retain];
	}
	else {
		tempData = [gUserDefaults dataForKey:@"windowBackColor"];
		if (tempData != nil)
			m_clWindowBackColor = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData] retain];
	}
	
	// Get the default document size
	m_nWidth = 1024;
	if ([gUserDefaults objectForKey:@"width"])
		m_nWidth = [gUserDefaults integerForKey:@"width"];
	m_nHeight = 768;
	if ([gUserDefaults objectForKey:@"height"])
		m_nHeight = [gUserDefaults integerForKey:@"height"];
	
	// The resolution for new documents
	m_nResolution = 72;
	if ([gUserDefaults objectForKey:@"resolution"])
		m_nResolution = [gUserDefaults integerForKey:@"resolution"];
	if (m_nResolution != 72 && m_nResolution != 96 && m_nResolution != 150 && m_nResolution != 300)
		m_nResolution = 72;
	
	// Units used in the new document
	m_nNewUnits = kPixelUnits;
	if ([gUserDefaults objectForKey:@"units"])
		m_nNewUnits = [gUserDefaults integerForKey:@"units"];
	
	// Mode used for the new document
	m_nMode = 0;
	if ([gUserDefaults objectForKey:@"mode"])
		m_nMode = [gUserDefaults integerForKey:@"mode"];

	// Mode used for the new document
	m_nResolutionHandling = kUse72dpiResolution;
	if ([gUserDefaults objectForKey:@"resolutionHandling"])
		m_nResolutionHandling = [gUserDefaults integerForKey:@"resolutionHandling"];

	//  Get the multithreaded
	if ([gUserDefaults objectForKey:@"transparentBackground"])
		m_bTransparentBackground = [gUserDefaults boolForKey:@"transparentBackground"];
	else
		m_bTransparentBackground = NO;

	//  Get the multithreaded
	if ([gUserDefaults objectForKey:@"multithreaded"])
		m_bMultithreaded = [gUserDefaults boolForKey:@"multithreaded"];
	else
		m_bMultithreaded = YES;
		
	//  Get the ignoreFirstTouch
	if ([gUserDefaults objectForKey:@"ignoreFirstTouch"])
		m_bIgnoreFirstTouch = [gUserDefaults boolForKey:@"ignoreFirstTouch"];
	else
		m_bIgnoreFirstTouch = NO;
		
	// Get the mouseCoalescing
	if ([gUserDefaults objectForKey:@"newMouseCoalescing"])
		m_bMouseCoalescing = [gUserDefaults boolForKey:@"newMouseCoalescing"];
	else
		m_bMouseCoalescing = YES;
		
	// Get the m_bCheckForUpdates
	if ([gUserDefaults objectForKey:@"checkForUpdates"]) {
		m_bCheckForUpdates = [gUserDefaults boolForKey:@"checkForUpdates"];
		m_tiLastCheck = [[gUserDefaults objectForKey:@"lastCheck"] doubleValue];
	}
	else {
		m_bCheckForUpdates = YES;
		m_tiLastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
	}
	
	// Get the m_bPreciseCursor
	if ([gUserDefaults objectForKey:@"preciseCursor"])
		m_bPreciseCursor = [gUserDefaults boolForKey:@"preciseCursor"];
	else
		m_bPreciseCursor = NO;

	// Get the m_bUseCoreImage
	if ([gUserDefaults objectForKey:@"useCoreImage"])
		m_bUseCoreImage = [gUserDefaults boolForKey:@"useCoreImage"];
	else
		m_bUseCoreImage = YES;
		
	// Get the main screen resolution
	//if (GetMainDisplayDPI(&xdpi, &ydpi))
    {
		xdpi = ydpi = 72.0;
		NSLog(@"Error finding screen resolution.");
	}
	m_sMainScreenResolution.x = (int)roundf(xdpi);
	m_sMainScreenResolution.y = (int)roundf(ydpi);
#ifdef DEBUG
	// NSLog(@"Screen resolution (dpi): %d x %d", m_sMainScreenResolution.x, m_sMainScreenResolution.y);
#endif
	gScreenResolution = [self screenResolution];

	return self;
}

- (void)awakeFromNib
{
	NSString *fontName;
	float fontSize;
	
	// Get the font name and size
	if ([gUserDefaults objectForKey:@"fontName"] && [gUserDefaults objectForKey:@"fontSize"]) {
		fontName = [gUserDefaults objectForKey:@"fontName"];
		fontSize = [gUserDefaults floatForKey:@"fontSize"];
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
	}
	else {
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont messageFontOfSize:0] isMultiple:NO];
	}
    
    [m_labelImageSetting setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Image Default Settings", nil)]];
    [m_labelWidth setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Width", nil)]];
    [m_labelHeight setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Height", nil)]];
    [m_labelResolution setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Resolution", nil)]];
    [m_idPanel setTitle:NSLocalizedString(@"Preferences", nil)];
    [m_idTransparentBackgroundCheckbox setTitle:NSLocalizedString(@"Transparent background", nil)];
//	// Create the toolbar instance, and attach it to our document window 
//    m_idToolbar = [[[NSToolbar alloc] initWithIdentifier: PrefsToolbarIdentifier] autorelease];
//    
//    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
//    [m_idToolbar setAllowsUserCustomization: YES];
//    [m_idToolbar setAutosavesConfiguration: YES];
//
//    // We are the delegate
//    [m_idToolbar setDelegate: self];
//
//    // Attach the m_idToolbar to the document window 
//    [m_idPanel setToolbar: m_idToolbar];
//	[m_idToolbar setSelectedItemIdentifier:GeneralPrefsIdentifier];
//	[(NSPanel *)m_idPanel setContentView: m_idGeneralPrefsView];
    
    [(NSPanel *)m_idPanel setContentView: m_idNewPrefsView];

	// Register to recieve the terminate message when PixelStyle quits
	[m_idController registerForTermination:self];
}

- (void)terminate
{
	NSFont *font = [[NSFontManager sharedFontManager] selectedFont];

	// For some unknown reason NSColorListMode causes a crash on boot
	NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
	if([colorPanel mode] == NSColorListModeColorPanel){
		[colorPanel setMode:NSWheelModeColorPanel];
	}
	
	[gUserDefaults setObject:(m_bGuides ? @"YES" : @"NO") forKey:@"guides"];
	[gUserDefaults setObject:(m_bLayerBounds ? @"YES" : @"NO") forKey:@"boundaries"];
	[gUserDefaults setObject:(m_bRulers ? @"YES" : @"NO") forKey:@"rulers"];
	[gUserDefaults setInteger:m_nMemoryCacheSize forKey:@"memoryCacheSize"];
	[gUserDefaults setObject:(m_bFewerWarnings ? @"YES" : @"NO") forKey:@"fewerWarnings"];
	[gUserDefaults setObject:(m_bEffectsPanel ? @"YES" : @"NO") forKey:@"effectsPanel"];
	[gUserDefaults setObject:(m_bSmartInterpolation ? @"YES" : @"NO") forKey:@"smartInterpolation"];
	[gUserDefaults setObject:(m_bOpenUntitled ? @"YES" : @"NO") forKey:@"openUntitled"];
	[gUserDefaults setObject:(m_bMultithreaded ? @"YES" : @"NO") forKey:@"multithreaded"];
	[gUserDefaults setObject:(m_bIgnoreFirstTouch ? @"YES" : @"NO") forKey:@"ignoreFirstTouch"];
	[gUserDefaults setObject:(m_bMouseCoalescing ? @"YES" : @"NO") forKey:@"newMouseCoalescing"];
	[gUserDefaults setObject:(m_bCheckForUpdates ? @"YES" : @"NO") forKey:@"checkForUpdates"];
	[gUserDefaults setObject:(m_bPreciseCursor ? @"YES" : @"NO") forKey:@"preciseCursor"];
	[gUserDefaults setObject:(m_bUseCoreImage ? @"YES" : @"NO") forKey:@"useCoreImage"];
	[gUserDefaults setObject:(m_bTransparentBackground ? @"YES" : @"NO") forKey:@"transparentBackground"];
	[gUserDefaults setObject:(m_bUseCheckerboard ? @"YES" : @"NO") forKey:@"useCheckerboard"];
	[gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:m_clWindowBackColor] forKey:@"windowBackColor"];
	[gUserDefaults setInteger:m_nSelectionColor forKey:@"selectionColor"];
	[gUserDefaults setObject:(m_bWhiteLayerBounds ? @"YES" : @"NO") forKey:@"whiteLayerBounds"];
	[gUserDefaults setInteger:m_nGuideColor forKey:@"guideColor"];
	[gUserDefaults setInteger:m_nWidth forKey:@"width"];
	[gUserDefaults setInteger:m_nHeight forKey:@"height"];
	[gUserDefaults setInteger:m_nResolution forKey:@"resolution"];
	[gUserDefaults setInteger:m_nNewUnits forKey:@"units"];
	[gUserDefaults setInteger:m_nMode forKey:@"mode"];
	[gUserDefaults setInteger:m_nResolutionHandling forKey:@"resolutionHandling"];
	[gUserDefaults setInteger:m_nRunCount forKey:@"runCount"];
	[gUserDefaults setObject:[font fontName] forKey:@"fontName"];
	[gUserDefaults setFloat:[font pointSize] forKey:@"fontSize"];
	[gUserDefaults setObject:[NSString stringWithFormat:@"%f", m_tiLastCheck] forKey:@"lastCheck"];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = nil;

    if ([itemIdent isEqual: GeneralPrefsIdentifier]) {
        toolbarItem = [[[PSImageToolbarItem alloc] initWithItemIdentifier: GeneralPrefsIdentifier label: LOCALSTR(@"general", @"General") image: @"GeneralPrefsIcon" toolTip: LOCALSTR(@"general prefs tooltip", @"General application settings") target: self selector: @selector(generalPrefs)] autorelease];
	} else if ([itemIdent isEqual: NewPrefsIdentifier]) {
		toolbarItem = [[[PSImageToolbarItem alloc] initWithItemIdentifier: NewPrefsIdentifier label: LOCALSTR(@"new images", @"New Images") image: @"NewPrefsIcon" toolTip: LOCALSTR(@"new prefs tooltip", @"Settings for new images") target: self selector: @selector(newPrefs)] autorelease];
	} else if ([itemIdent isEqual: ColorPrefsIdentifier]) {
		toolbarItem = [[[PSImageToolbarItem alloc] initWithItemIdentifier: ColorPrefsIdentifier label: LOCALSTR(@"color", @"Colors") image: @"ColorPrefsIcon" toolTip: LOCALSTR(@"color prefs tooltip", @"Display colors") target: self selector: @selector(colorPrefs)] autorelease];
	}
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar;
{
    return [NSArray arrayWithObjects: GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, nil];
}

- (void) generalPrefs {
	[(NSPanel *)m_idPanel setContentView: m_idGeneralPrefsView];
}

- (void) newPrefs {
	[(NSPanel *)m_idPanel setContentView: m_idNewPrefsView];
}

- (void) colorPrefs {
    [(NSPanel *)m_idPanel setContentView: m_idColorPrefsView];
}

- (IBAction)show:(id)sender
{
	// Set the existing settings
	[m_idNewUnitsMenu selectItemAtIndex: m_nNewUnits];
    [m_idNewHeightUnitsMenu selectItemAtIndex: m_nNewUnits];
	[m_idHeightValue setStringValue:StringFromPixels(m_nHeight, m_nNewUnits, m_nResolution)];
	[m_idWidthValue setStringValue:StringFromPixels(m_nWidth, m_nNewUnits, m_nResolution)];
	[m_idHeightUnits setStringValue:UnitsString(m_nNewUnits)];
	[m_idResolutionMenu selectItemAtIndex:[m_idResolutionMenu indexOfItemWithTag:m_nResolution]];
	[m_idModeMenu selectItemAtIndex: m_nMode];
	[m_idCheckerboardMatrix	selectCellAtRow: m_bUseCheckerboard column: 0];
	[m_idLayerBoundsMatrix selectCellAtRow: m_bWhiteLayerBounds column: 0];
	[m_idWindowBackWell setInitialColor:m_clWindowBackColor];
	[m_idTransparentBackgroundCheckbox setState:m_bTransparentBackground];
	[m_idFewerWarningsCheckbox setState:m_bFewerWarnings];
	[m_idEffectsPanelCheckbox setState:m_bEffectsPanel];
	[m_idSmartInterpolationCheckbox setState:m_bSmartInterpolation];
	[m_idOpenUntitledCheckbox setState:m_bOpenUntitled];
	[m_idMultithreadedCheckbox setState:m_bMultithreaded];
	[m_idIgnoreFirstTouchCheckbox setState:m_bIgnoreFirstTouch];
	[m_idCoalescingCheckbox setState:m_bMouseCoalescing];
	[m_idCheckForUpdatesCheckbox setState:m_bCheckForUpdates];
	[m_idPreciseCursorCheckbox setState:m_bPreciseCursor];	
	[m_idUseCoreImageCheckbox setState:m_bUseCoreImage];
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3) {
		[m_idUseCoreImageCheckbox setState:NO];
		[m_idUseCoreImageCheckbox setEnabled:NO];
	}
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
		[m_idMultithreadedCheckbox setState:NO];
		[m_idMultithreadedCheckbox setEnabled:NO];
	}
	[m_idSelectionColorMenu selectItemAtIndex:[m_idSelectionColorMenu indexOfItemWithTag:m_nSelectionColor + 280]];
	[m_idGuideColorMenu selectItemAtIndex:[m_idGuideColorMenu indexOfItemWithTag:m_nGuideColor + 290]];
	[m_idResolutionHandlingMenu selectItemAtIndex:[m_idResolutionHandlingMenu indexOfItemWithTag:m_nResolutionHandling]];
	
	// Display the preferences dialog
	[m_idPanel center];
	[m_idPanel makeKeyAndOrderFront: self];
}

-(IBAction)setWidth:(id)sender
{
	int newWidth = PixelsFromFloat([m_idWidthValue floatValue],m_nNewUnits,m_nResolution);
	
	// Don't accept rediculous widths
	if (newWidth < kMinImageSize || newWidth > kMaxImageSize) { 
		NSBeep(); 
		[m_idWidthValue setStringValue:StringFromPixels(m_nWidth, m_nNewUnits, m_nResolution)];
	}
	else {
		m_nWidth = newWidth;
	}
	
	[self apply: self];
}

-(IBAction)setHeight:(id)sender
{
	int newHeight =  PixelsFromFloat([m_idHeightValue floatValue],m_nNewUnits,m_nResolution);

	// Don't accept rediculous heights
	if (newHeight < kMinImageSize || newHeight > kMaxImageSize) { 
		NSBeep(); 
		[m_idHeightValue setStringValue:StringFromPixels(m_nHeight, m_nNewUnits, m_nResolution)];
	}
	else {
		m_nHeight = newHeight;
	}
	
	[self apply: self];
}

-(IBAction)setNewUnits:(id)sender
{
	m_nNewUnits = [sender tag] % 10;
	[m_idHeightValue setStringValue:StringFromPixels(m_nHeight, m_nNewUnits, m_nResolution)];
	[m_idWidthValue setStringValue:StringFromPixels(m_nWidth, m_nNewUnits, m_nResolution)];	
	[m_idHeightUnits setStringValue:UnitsString(m_nNewUnits)];
    [m_idNewHeightUnitsMenu selectItemAtIndex: m_nNewUnits];
    [m_idNewUnitsMenu selectItemAtIndex: m_nNewUnits];
	[self apply: self];
}

-(IBAction)changeUnits:(id)sender
{
	PSDocument *document = gCurrentDocument;
	[document changeMeasuringStyle:[sender tag] % 10];
	[[document docView] updateRulers];
	[[[PSController utilitiesManager] infoUtilityFor:document] update];
	[[[PSController utilitiesManager] statusUtilityFor:document] update];
}

-(IBAction)setResolution:(id)sender
{
	m_nResolution = [[m_idResolutionMenu selectedItem] tag];
	m_nWidth =  PixelsFromFloat([m_idWidthValue floatValue],m_nNewUnits,m_nResolution);
	m_nHeight =  PixelsFromFloat([m_idHeightValue floatValue],m_nNewUnits,m_nResolution);
	[self apply: self];
}

-(IBAction)setMode:(id)sender
{
	m_nMode = [[m_idModeMenu selectedItem] tag];
	[self apply: self];
}

-(IBAction)setTransparentBackground:(id)sender
{
	m_bTransparentBackground = [m_idTransparentBackgroundCheckbox state];
	[self apply: self];
}

-(IBAction)setFewerWarnings:(id)sender
{
	m_bFewerWarnings = [m_idFewerWarningsCheckbox state];
	[self apply: self];
}
	
-(IBAction)setEffectsPanel:(id)sender
{
	m_bEffectsPanel = [m_idEffectsPanelCheckbox state];
	[self apply: self];
}

-(IBAction)setSmartInterpolation:(id)sender
{
	m_bSmartInterpolation = [m_idSmartInterpolationCheckbox state];
	[self apply: self];
}

-(IBAction)setOpenUntitled:(id)sender
{
	m_bOpenUntitled = [m_idOpenUntitledCheckbox state];
	[self apply: self];
}

-(IBAction)setMultithreaded:(id)sender
{
	m_bMultithreaded = [m_idMultithreadedCheckbox state];
	[self apply: self];
}

-(IBAction)setIgnoreFirstTouch:(id)sender
{
	m_bIgnoreFirstTouch = [m_idIgnoreFirstTouchCheckbox state];
	[self apply: self];
}

-(IBAction)setMouseCoalescing:(id)sender
{
	m_bMouseCoalescing = [m_idCoalescingCheckbox state];
	[self apply: self];
}	


-(IBAction)setCheckForUpdates:(id)sender
{
	m_bCheckForUpdates = [m_idCheckForUpdatesCheckbox state];
	[self apply: self];
}

-(IBAction)setPreciseCursor:(id)sender
{
	m_bPreciseCursor = [m_idPreciseCursorCheckbox state];
	[self apply: self];
}

- (IBAction)setUseCoreImage:(id)sender
{
	m_bUseCoreImage = [m_idUseCoreImageCheckbox state];
	[self apply: self];	
}

-(IBAction)setResolutionHandling:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	m_nResolutionHandling = [[m_idResolutionHandlingMenu selectedItem] tag];
	gScreenResolution = [self screenResolution];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] helpers] resolutionChanged];
	}
}

- (IBAction)apply:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Call for all documents' views to respond to the change
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([m_idPanel isVisible]) {
		[self setWidth: self];
		[self setHeight: self];
	}
}

- (BOOL)layerBounds
{
	return m_bLayerBounds;
}

- (BOOL)guides
{
	return m_bGuides;
}

- (BOOL)rulers
{
	return m_bRulers;
}

- (BOOL)firstRun
{
	return m_bFirstRun;
}

- (int)memoryCacheSize
{
	return m_nMemoryCacheSize;
}

- (int)warningLevel
{
	return (m_bFewerWarnings) ? kModerateImportance : kVeryLowImportance;
}

- (BOOL)effectsPanel
{
	return m_bEffectsPanel;
}

- (BOOL)smartInterpolation
{
	return m_bSmartInterpolation;
}

- (BOOL)useTextures
{
	return m_bUseTextures;
}

- (void)setUseTextures:(BOOL)value
{
	m_bUseTextures = value;
}

- (IBAction)toggleBoundaries:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_bLayerBounds = !m_bLayerBounds;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)toggleGuides:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_bGuides = !m_bGuides;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}
		
- (IBAction)toggleRulers:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_bRulers = !m_bRulers;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] updateRulersVisiblity];
	}
	[[gCurrentDocument docView] checkMouseTracking];
}

- (IBAction)checkerboardChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	m_bUseCheckerboard = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (BOOL) useCheckerboard
{
	return m_bUseCheckerboard;
}

- (IBAction)defaultWindowBack:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	[m_clWindowBackColor autorelease];
//	m_clWindowBackColor = [[NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0] retain];
    m_clWindowBackColor = [[NSColor colorWithCalibratedRed:39.0/255.0 green:39.0/255.0 blue:39.0/255.0 alpha:1.0] retain];
	[m_idWindowBackWell setInitialColor:m_clWindowBackColor];
	for (i = 0; i < [documents count]; i++) {
		[[documents objectAtIndex:i] updateWindowColor];
		[[[[documents objectAtIndex:i] docView] superview] setNeedsDisplay:YES];
	}
}

- (IBAction)windowBackChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	[m_clWindowBackColor autorelease];
	m_clWindowBackColor = [[m_idWindowBackWell color] retain];
	for (i = 0; i < [documents count]; i++) {
		[[documents objectAtIndex:i] updateWindowColor];
		[[[[documents objectAtIndex:i] docView] superview] setNeedsDisplay:YES];
	}
}

- (NSColor *)windowBack
{
    [m_clWindowBackColor autorelease];
    m_clWindowBackColor = [[NSColor colorWithCalibratedRed:39.0/255.0 green:39.0/255.0 blue:39.0/255.0 alpha:1.0] retain];
	
    return m_clWindowBackColor;
}

- (NSColor *)selectionColor:(float)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (m_nSelectionColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
		break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
		break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (int)selectionColorIndex
{
	return m_nSelectionColor;
}

- (IBAction)selectionColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_nSelectionColor = [sender tag] - 280;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (BOOL)whiteLayerBounds
{
	return m_bWhiteLayerBounds;
}

- (IBAction)layerBoundsColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	m_bWhiteLayerBounds = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (NSColor *)guideColor:(float)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (m_nGuideColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
			break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
			break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (int)guideColorIndex
{
	return m_nGuideColor;
}

- (IBAction)guideColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_nGuideColor = [sender tag] - 290;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)rotateSelectionColor:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	m_nSelectionColor = (m_nSelectionColor + 1) % kMaxColor;
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}
	
	// Set the selection colour correctly
	[m_idSelectionColorMenu selectItemAtIndex:[m_idSelectionColorMenu indexOfItemWithTag:m_nSelectionColor + 280]];
}

- (BOOL)multithreaded
{
/*
	BOOL good_os;
	
	good_os = !(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2);

	return multithreaded && good_os;
*/
	return NO;
}

- (BOOL)ignoreFirstTouch
{
	return m_bIgnoreFirstTouch;
}

- (BOOL)mouseCoalescing
{
	return m_bMouseCoalescing;
}

- (BOOL)checkForUpdates
{
	if ([[NSDate date] timeIntervalSinceReferenceDate] - m_tiLastCheck > 7.0 * 24.0 * 60.0 * 60.0) {
		m_tiLastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
		return m_bCheckForUpdates;
	}
	
	return NO;
}

- (BOOL)preciseCursor
{
	return m_bPreciseCursor;
}

- (BOOL)useCoreImage
{
	return m_bUseCoreImage;
}

- (BOOL)delayOverlay
{
	return NO;
}

- (IntSize)size
{
	IntSize result = IntMakeSize(m_nWidth, m_nHeight);
	
	return result;
}

- (int)resolution
{
	switch (m_nResolution) {
		case 72:
			return 0;
		break;
		case 96:
			return 1;
		break;
		case 150:
			return 2;
		break;
		case 300:
			return 3;
		break;
		default:
			return 0;
		break;
	}
}

- (int) newUnits
{
	return m_nNewUnits;
}

- (int)mode
{
	return m_nMode;
}

- (IntPoint)screenResolution
{
	switch (m_nResolutionHandling) {
		case kIgnoreResolution:
			return IntMakePoint(0, 0);
		break;
		case kUse72dpiResolution:
			return IntMakePoint(72, 72);
		break;
		case kUseScreenResolution:
			return m_sMainScreenResolution;
		break;
	}

	return IntMakePoint(72, 72);
}

- (BOOL)transparentBackground
{
	return m_bTransparentBackground;
}

- (int)runCount
{
	return m_nRunCount;
}

- (BOOL)openUntitled
{
	return m_bOpenUntitled;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	// Set the boundaries menu item appropriately
	if ([menuItem tag] == 225) {
		if (m_bLayerBounds)
			[menuItem setTitle:NSLocalizedString(@"Hide Layer Bounds", nil)];
		else
			[menuItem setTitle:NSLocalizedString(@"Show Layer Bounds", nil)];
	}

	// Set the position m_bGuides menu item appropriately
	if ([menuItem tag] == 371) {
		if (m_bGuides)
			[menuItem setTitle:NSLocalizedString(@"Hide Guides", nil)];
		else
			[menuItem setTitle:NSLocalizedString(@"Show Guides", nil)];
	}
	
	// Set the m_bRulers menu item appropriately
	if ([menuItem tag] == 370) {
		if (m_bRulers)
			[menuItem setTitle:NSLocalizedString(@"Hide Rulers", nil)];
		else
			[menuItem setTitle:NSLocalizedString(@"Show Rulers", nil)];
	}

	if ([menuItem tag] >= 710 && [menuItem tag] < 720) {		
		[menuItem setState:[gCurrentDocument measureStyle] + 710 == [menuItem tag]];
	}
	
	return YES;
}

@end
