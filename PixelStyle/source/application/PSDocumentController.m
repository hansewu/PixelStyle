#import "PSDocumentController.h"
#import "PSPrefs.h"
#import "PSController.h"
#import "PSDocument.h"
#import "Units.h"
#import "PSRecentFileUtility.h"

#import "PSFileImporter.h"

@implementation PSDocumentController

- (id)init
{
	if (![super init])
		return NULL;
		
	m_bStopNotingRecentDocuments = NO;
	
	return self;
}

- (void)initPluginImporterSupportTypes
{
    if (m_importerPluginsSupportTypes != nil) {
        return;
    }
    m_importerPluginsSupportTypes = [[NSMutableArray alloc] init];
    int count = 0;
    char** types = plugin_GetAllSupportedTypes(&count);
    for (int i = 0; i < count; i++) {
        [m_importerPluginsSupportTypes addObject:[NSString stringWithUTF8String:types[i]]];
    }
    if (count > 0 && types != NULL) {
        for (int i = 0; i < count; i++) {
            free(types[i]);
        }
        free(types);
    }

}

- (void)awakeFromNib
{
	int i;
	m_mdEditableTypes = [[NSMutableDictionary dictionary] retain];
	m_mdViewableTypes = [[NSMutableDictionary dictionary] retain];
	
	// The document controller is responsible for tracking document types
	// In addition, as it's in control of open, it also must know the types for import and export
	NSArray *allDocumentTypes = [[[NSBundle mainBundle] infoDictionary]
							  valueForKey:@"CFBundleDocumentTypes"];
	for(i = 0; i < [allDocumentTypes count]; i++){
		NSDictionary *typeDict = [allDocumentTypes objectAtIndex:i];
		NSMutableSet *assembly = [NSMutableSet set];

		[assembly addObjectsFromArray:[typeDict objectForKey:@"CFBundleTypeExtensions"]];
		[assembly addObjectsFromArray:[typeDict objectForKey:@"CFBundleTypeOSTypes"]];
		[assembly addObjectsFromArray:[typeDict objectForKey:@"LSItemContentTypes"]];
		
		NSString* key = [typeDict objectForKey:@"CFBundleTypeName"];
		[assembly addObject:key];
				
		NSString *role = [typeDict objectForKey:@"CFBundleTypeRole"];
		if([role isEqual:@"Editor"]){
			[m_mdEditableTypes setObject:assembly forKey: key];
		}else if ([role isEqual:@"Viewer"]) {
			[m_mdViewableTypes setObject:assembly forKey: key];
		}
	}
    
    //add by lcz
    m_nUnits = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];
    [m_idWidthUnitsMenu selectItemAtIndex: m_nUnits];
    [m_idHeightUnitMenu selectItemAtIndex:m_nUnits];
    [m_idResMenu selectItemAtIndex:[(PSPrefs *)[PSController m_idPSPrefs] resolution]];
    [m_idModeMenu selectItemAtIndex:[(PSPrefs *)[PSController m_idPSPrefs] mode]];
    m_nType = [m_idModeMenu indexOfSelectedItem];
    m_bOpaque = ![m_idBackgroundCheckbox state];
    m_nResolution = [[m_idResMenu selectedItem] tag];
    IntSize size = [(PSPrefs *)[PSController m_idPSPrefs] size];
    [m_idWidthInput setStringValue:StringFromPixels(size.width, m_nUnits, m_nResolution)];
    [m_idHeightInput setStringValue:StringFromPixels(size.height, m_nUnits, m_nResolution)];
    m_nWidth = PixelsFromFloat([m_idWidthInput floatValue], m_nUnits, m_nResolution);
    m_nHeight = PixelsFromFloat([m_idHeightInput floatValue], m_nUnits, m_nResolution);
    [m_idHeightUnits setStringValue:UnitsString(m_nUnits)];
    [m_idBackgroundCheckbox setState:[(PSPrefs *)[PSController m_idPSPrefs] transparentBackground]];
    
    
//    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:[m_idCreatButton title]] autorelease];
//    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
//    [colorTitle addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:titleRange];
//    [colorTitle setAlignment:[m_idCreatButton alignment] range:titleRange];
//    [(NSButton*)m_idCreatButton setAttributedTitle:colorTitle];
    
//    [self initPluginImporterSupportTypes];
//    [self performSelector:@selector(initPluginImporterSupportTypes) withObject:NULL afterDelay:2];
    
    [self initViews];
}

-(void)initViews
{
    m_textFieldPreset.stringValue = [NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Preset", nil)];
    m_textFieldWidth.stringValue = [NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Width", nil)];
    m_textFieldHeight.stringValue = [NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Height", nil)];
    m_textFieldResolution.stringValue = [NSString stringWithFormat:@"%@ :",NSLocalizedString(@"Resolution", nil)];
    
    m_btnOpen.title = [NSString stringWithFormat:@"%@...",NSLocalizedString(@"Open", nil)];
    
    [(NSButton *)m_idBackgroundCheckbox setTitle:NSLocalizedString(@"Transparent background", nil)];
    
    [(NSButton *)m_idCreatButton setTitle:NSLocalizedString(@"Create", nil)];
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_idTemplatesMenu itemAtIndex:[m_idTemplatesMenu indexOfItemWithTag:1]];
    [menuItem setTitle:NSLocalizedString(@"Default", nil)];
    menuItem = [(NSPopUpButton *)m_idTemplatesMenu itemAtIndex:[m_idTemplatesMenu indexOfItemWithTag:2]];
    [menuItem setTitle:NSLocalizedString(@"Clipboard", nil)];
    menuItem = [(NSPopUpButton *)m_idTemplatesMenu itemAtIndex:[m_idTemplatesMenu indexOfItemWithTag:3]];
    [menuItem setTitle:NSLocalizedString(@"Screen size", nil)];
    
    [m_idNewPanel setTitle:NSLocalizedString(@"New Image", nil)];
}

- (void)dealloc
{
	// Then get rid of stuff that's no longer needed
	if (m_mdEditableTypes) [m_mdEditableTypes autorelease];
	if (m_mdViewableTypes) [m_mdViewableTypes autorelease];
    if (m_importerPluginsSupportTypes) {
        [m_importerPluginsSupportTypes release];
    }
	// Finally call the super
	[super dealloc];
}

- (IBAction)newDocument:(id)sender
{
    NSObject *first=[[NSApp mainWindow] firstResponder];
    
	NSString *string;
	id menuItem;
	IntSize size;
	
	// Set paper name
	if ([[NSPrintInfo sharedPrintInfo] respondsToSelector:@selector(localizedPaperName)]) {
		menuItem = [m_idTemplatesMenu itemAtIndex:[m_idTemplatesMenu indexOfItemWithTag:4]];
		string = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"Paper size", nil), [[NSPrintInfo sharedPrintInfo] localizedPaperName]];
		[menuItem setTitle:string];
	}

    [m_idTemplatesMenu selectItemAtIndex:1];
    
	// Display the panel for configuring
	m_nUnits = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];
	[m_idWidthUnitsMenu selectItemAtIndex: m_nUnits];
    [m_idHeightUnitMenu selectItemAtIndex: m_nUnits];
	[m_idResMenu selectItemAtIndex:[(PSPrefs *)[PSController m_idPSPrefs] resolution]];
	[m_idModeMenu selectItemAtIndex:[(PSPrefs *)[PSController m_idPSPrefs] mode]];
	m_nResolution = [[m_idResMenu selectedItem] tag];
	size = [(PSPrefs *)[PSController m_idPSPrefs] size];
	[m_idWidthInput setStringValue:StringFromPixels(size.width, m_nUnits, m_nResolution)];
	[m_idHeightInput setStringValue:StringFromPixels(size.height, m_nUnits, m_nResolution)];
    m_nWidth = PixelsFromFloat([m_idWidthInput floatValue], m_nUnits, m_nResolution);
    m_nHeight = PixelsFromFloat([m_idHeightInput floatValue], m_nUnits, m_nResolution);
	[m_idHeightUnits setStringValue:UnitsString(m_nUnits)];
	[m_idBackgroundCheckbox setState:[(PSPrefs *)[PSController m_idPSPrefs] transparentBackground]];
	
	// Set up the recents menu
	int i;
	NSArray *recentDocs = [super recentDocumentURLs];
	if([recentDocs count]){
		[m_idRecentMenu setEnabled:YES];
		for(i = 0; i < [recentDocs count]; i++){
			NSString *path = [[recentDocs objectAtIndex:i] path];
			NSString *filename = [[path pathComponents] objectAtIndex:[[path pathComponents] count] -1];
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile: path];
			[m_idRecentMenu addItemWithTitle: filename];
			[[m_idRecentMenu itemAtIndex:[m_idRecentMenu numberOfItems] - 1] setRepresentedObject:path];
			[[m_idRecentMenu itemAtIndex:[m_idRecentMenu numberOfItems] - 1] setImage: image];
		}
	}else {
		[m_idRecentMenu setEnabled:NO];
	}

    [(PSRecentFileUtility *)m_idRecentFile updateRecentFile];
	
	[m_idNewPanel center];
	[m_idNewPanel makeKeyAndOrderFront:self];
}

- (IBAction)openDocument:(id)sender
{
//	[m_idNewPanel orderOut:self];
	[super openDocument:sender];
}

- (id)openNonCurrentFile:(NSString *)path
{
	__block id newDocument;
	
	m_bStopNotingRecentDocuments = YES;
	//newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:path display:YES];
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){newDocument = document;}];
	m_bStopNotingRecentDocuments = NO;
	[newDocument setCurrent:NO];
	
	return newDocument;
}

- (IBAction)openRecent:(id)sender
{
	//[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[[sender selectedItem] representedObject] display:YES];
    NSString *path = [[sender selectedItem] representedObject];
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){}];
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument
{
	if (m_bStopNotingRecentDocuments == NO && [(PSDocument *)aDocument current]) {
		[super noteNewRecentDocument:aDocument];
	}
}

- (IBAction)createDocument:(id)sender
{
	// Determine the resolution
	m_nResolution = [[m_idResMenu selectedItem] tag];

	// Parse width and height	
	m_nWidth = PixelsFromFloat([m_idWidthInput floatValue], m_nUnits, m_nResolution);
	m_nHeight = PixelsFromFloat([m_idHeightInput floatValue], m_nUnits, m_nResolution); 
			
	// Don't accept rediculous heights or widths
	if (m_nWidth < kMinImageSize || m_nWidth > kMaxImageSize) { NSBeep(); return; }
	if (m_nHeight < kMinImageSize || m_nHeight > kMaxImageSize) { NSBeep(); return; }
	
	// Determine everything else
	m_nType = [m_idModeMenu indexOfSelectedItem];
	m_bOpaque = ![m_idBackgroundCheckbox state];

	// Create a new document
	[super newDocument:sender];
}

- (IBAction)changeToTemplate:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	float res;
	int selectedTag;
	
	selectedTag = [[m_idTemplatesMenu selectedItem] tag];
	res = [[m_idResMenu selectedItem] tag];
	switch (selectedTag) {
		case 1:
			size = [(PSPrefs *)[PSController m_idPSPrefs] size];
			m_nUnits = [(PSPrefs *)[PSController m_idPSPrefs] newUnits];
			[m_idWidthUnitsMenu selectItemAtIndex: m_nUnits];
            [m_idHeightUnitMenu selectItemAtIndex: m_nUnits];
			res = [(PSPrefs *)[PSController m_idPSPrefs] resolution];
			[m_idResMenu selectItemAtIndex:res];
            res = [[m_idResMenu selectedItem] tag];
		break;
		case 2:
			pboard = [NSPasteboard generalPasteboard];
			availableType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
			if (availableType) {
				image = [[NSImage alloc] initWithData:[pboard dataForType:availableType]];
				size = NSSizeMakeIntSize([image size]);
				[image autorelease];
			}
			else {
				NSBeep();
				return;
			}
			
		break;
		case 3:
			size = NSSizeMakeIntSize([[NSScreen mainScreen] frame].size);
			m_nUnits = kPixelUnits;
			[m_idWidthUnitsMenu selectItemAtIndex: kPixelUnits];
            [m_idHeightUnitMenu selectItemAtIndex: kPixelUnits];
		break;
		case 4:
			paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
			paperSize.height -= [[NSPrintInfo sharedPrintInfo] topMargin] + [[NSPrintInfo sharedPrintInfo] bottomMargin];
			paperSize.width -= [[NSPrintInfo sharedPrintInfo] leftMargin] + [[NSPrintInfo sharedPrintInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			m_nUnits = kInchUnits;
			[m_idWidthUnitsMenu selectItemAtIndex: kInchUnits];
            [m_idHeightUnitMenu selectItemAtIndex: kInchUnits];
			size.width = (float)size.width * (res / 72.0);
			size.height = (float)size.height * (res / 72.0);
		break;
		case 1000:
			/* Henry, add "Add..." item functionality here. */
		break;
		case 1001:
			/* Henry, add "Editor..." item functionality here. */
		break;
	}
	
	if (selectedTag != 1000 && selectedTag != 1001) {
		[m_idWidthInput setStringValue:StringFromPixels(size.width, m_nUnits, res)];
		[m_idHeightInput setStringValue:StringFromPixels(size.height, m_nUnits, res)];
		[m_idHeightUnits setStringValue:UnitsString(m_nUnits)];
	}
}

- (IBAction)changeUnits:(id)sender
{
    NSPopUpButton *popBtn = (NSPopUpButton *)sender;
	IntSize size = IntMakeSize(0, 0);
	int res = [[m_idResMenu selectedItem] tag];

	size.height =  PixelsFromFloat([m_idHeightInput floatValue],m_nUnits,res);
	size.width =  PixelsFromFloat([m_idWidthInput floatValue],m_nUnits,res);

	m_nUnits = [[popBtn selectedItem] tag];
    [m_idWidthUnitsMenu selectItemAtIndex:m_nUnits];
    [m_idHeightUnitMenu selectItemAtIndex: m_nUnits];
	[m_idWidthInput setStringValue:StringFromPixels(size.width, m_nUnits, res)];
	[m_idHeightInput setStringValue:StringFromPixels(size.height, m_nUnits, res)];
	[m_idHeightUnits setStringValue:UnitsString(m_nUnits)];
}

- (void)addDocument:(NSDocument *)document
{
	[m_idNewPanel orderOut:self];
	[super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document
{
	[super removeDocument:document];
}

- (int)type
{
	return m_nType;
}

- (int)height
{
	return m_nHeight;
}

- (int)width
{
	return m_nWidth;
}

- (int)resolution
{
	return m_nResolution;
}

- (int)opaque
{
	return m_bOpaque;
}

- (int)units
{
	return m_nUnits;
}

- (NSMutableDictionary*)editableTypes
{
	return m_mdEditableTypes;
}

- (NSMutableDictionary*)viewableTypes
{
	return m_mdViewableTypes;
}

- (NSArray*)readableTypes
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *e = [m_mdEditableTypes keyEnumerator];
	NSString *key;
	while (key = [e nextObject]) {
		[array addObjectsFromArray:[[m_mdEditableTypes objectForKey:key] allObjects]];
	}
	
	e = [m_mdViewableTypes keyEnumerator];
	while(key = [e nextObject]){
		[array addObjectsFromArray:[[m_mdViewableTypes objectForKey:key] allObjects]];
	}
    
//    int count = 0;
//    char** types = plugin_GetAllSupportedTypes(&count);
//    for (int i = 0; i < count; i++) {
//        [array addObject:[NSString stringWithUTF8String:types[i]]];
//    }
//    if (count > 0 && types != NULL) {
//        for (int i = 0; i < count; i++) {
//            free(types[i]);
//        }
//        free(types);
//    }
    
    [array addObjectsFromArray:m_importerPluginsSupportTypes];
    
	return array;
}

- (NSMutableArray*)importerPluginSupportedTypes
{
    return m_importerPluginsSupportTypes;
}


- (BOOL)isString:(NSString*)fullString contains:(NSString*)other
{
    NSRange range = [fullString rangeOfString:other];
    return range.length != 0;
}


- (BOOL)type:(NSString *)aType isContainedInDocType:(NSString*) key
{
	// We need to special case these for some reason, I don't know why
	if([key isEqual:@"Gimp image"] &&
	   (![aType caseInsensitiveCompare:@"com.gimp.xcf"] ||
	    ![aType caseInsensitiveCompare:@"net.sourceforge.xcf"] ||
		![aType caseInsensitiveCompare:@"Gimp Document"])){
		return YES;
	}
	
	NSMutableSet *set = [m_mdEditableTypes objectForKey:key];
	if(!set){
		set = [m_mdViewableTypes objectForKey:key];
		// That's wierd, someone has passed in an invalid type
		if(!set){
			NSLog(@"Invalid key passed to PSDocumentController: <%@> \n Investigating type: <%@>", key, aType);
			return NO;
		}
        
        //RAW image 格式，包括raw字符
        if([key isEqual:@"RAW image"] && [self isString:aType contains:@"raw"])  return YES;
        
	}
	
	NSEnumerator *e = [set objectEnumerator];
	NSString *candidate;
	while (candidate = [e nextObject]) {
		// I think we don't care about case in types
		if(![aType caseInsensitiveCompare:candidate]){
			return YES;
		}
	}
	return NO;
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
    // Restore the old type
    [self performSelector:@selector(closedoc:) withObject:doc afterDelay:0.1];
    
}

- (void)closedoc:(NSDocument *)doc
{
    
    for (NSWindowController* controller in [doc windowControllers]) {
        [controller setShouldCloseDocument:YES];
        [controller close];
        
    }
}

//- (void)reviewUnsavedDocumentsWithAlertTitle:(nullable NSString *)title cancellable:(BOOL)cancellable delegate:(nullable id)delegate didReviewAllSelector:(nullable SEL)didReviewAllSelector contextInfo:(nullable void *)contextInfo
//{
//    //验证是否注册
//    VerifyRegistration *verifyRegistration = [[[VerifyRegistration alloc] init] autorelease];
//    bool bRegisted = [verifyRegistration isRegisted];
//    if(!bRegisted)
//    {
//        [self closeAllDocumentsWithDelegate:delegate didCloseAllSelector:didReviewAllSelector contextInfo:contextInfo];
//    }
//    else
//        [super reviewUnsavedDocumentsWithAlertTitle:title cancellable:cancellable delegate:delegate didReviewAllSelector:didReviewAllSelector contextInfo:contextInfo];
//}

@end
