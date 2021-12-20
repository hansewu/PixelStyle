#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSBrush.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "PSSelection.h"
#import "PSWarning.h"
#import "PSPrefs.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSDocumentController.h"

#if (defined(TRIAL_VERSION) || defined(REGISTER_VERSION))
#import "VerifyRegistration.h"
#endif

#import "ConfigureInfo.h"
#import "HelpWindow.h"
#import "PSTitleView.h"
#import "PSServerConfig.h"
#import "EmailController.h"

id idPSController;

@implementation PSController

- (id)init
{
	// Remember ourselves
	idPSController = self;
	
	// Creates an array which can store objects that wish to recieve the terminate: message
	m_arrTerminationObjects = [[NSArray alloc] init];
    
	// Specify ourselves as NSApp's delegate
	[NSApp setDelegate:self];

	// We want to know when ColorSync changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSyncChanged:) name:@"AppleColorSyncPreferencesChangedNotification" object:NULL];
    
    	
	return self;
}

- (void)dealloc
{
	if (m_arrTerminationObjects) [m_arrTerminationObjects autorelease];
    if(m_pEmailController) {[m_pEmailController release]; m_pEmailController = nil;}
    
	[super dealloc];
}

void Vector_SetupDefaults();
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self updateMenuView];
    Vector_SetupDefaults();
    
	NSString *crashReport = [NSString stringWithFormat:@"%@/Library/Logs/CrashReporter/PixelStyle.crash.log", NSHomeDirectory()];
	NSString *trashedReport = [NSString stringWithFormat:@"%@/.Trash/PixelStyle.crash.log", NSHomeDirectory()];

	// Run initial tests
	if ([m_idPSPrefs firstRun] && [gFileManager fileExistsAtPath:crashReport]) {
		if ([gFileManager movePath:crashReport toPath:trashedReport handler:NULL]) {
			[m_idPSWarning addMessage:LOCALSTR(@"old crash report message", @"PixelStyle has moved its old crash report to the Trash so that it will be deleted next time you empty the trash.") level:kModerateImportance];
		}
	}
    
    
    
	/*
	[seaWarning addMessage:LOCALSTR(@"beta message", @"PixelStyle is still under development and may contain bugs. Please make sure to only work on copies of images as there is the potential for corruption. Also please report any bugs you find.") level:[m_idPSPrefs firstRun] ? kHighImportance : kVeryLowImportance];
	*/
	
	// Check run count
	/*
	if ([m_idPSPrefs runCount] == 25) {
		if (NSRunAlertPanel(LOCALSTR(@"feedback survey title", @"PixelStyle Feedback Survey"), LOCALSTR(@"feedback survey body", @"In order to improve the next release of PixelStyle we are asking users to participate in a survey. The survey is only one page long and can be accessed by clicking the \"Run Survey\" button. This message should not trouble you again."), LOCALSTR(@"feedback survey button", @"Run Survey"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {
			[seaHelp goSurvey:NULL];
		}
	}
	*/
	
	
    
//    [[NSDocumentController sharedDocumentController] newDocument:self];
    
    
    
    //[self performSelector:@selector(showHelpWindow) withObject:nil afterDelay:0.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
//#ifndef PROPAINT_VERSION
//    [self performSelectorInBackground:@selector(configClientInfo) withObject:nil];
//#endif
    //[self performSelector:@selector(showFeedbackInterface) withObject:nil afterDelay:0.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];

    BOOL openLast = [self judgeAndProcessLastCrashFile];

//#ifdef TRIAL_VERSION
//    //VerifyRegistration  注册码机制
//    VerifyRegistration *verifyRegistration = [[VerifyRegistration alloc] initWithWindowNibName:@"VerifyRegistration"];
//    [self performSelector:@selector(verifyRegistration:) withObject:verifyRegistration afterDelay:0.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
//    
//#endif
    
#if ((defined TRIAL_VERSION) || (defined REGISTER_VERSION))
    
    [self performSelector:@selector(initRegisterVerify) withObject:nil afterDelay:0.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
    
    //[self performSelector:@selector(openHelpUrlDirectly) withObject:nil afterDelay:1.0];
    
    [self performSelector:@selector(checkTrialDaysState) withObject:nil afterDelay:1.0];
    [self performSelectorInBackground:@selector(configClientInfo) withObject:nil];
    
#ifdef PROPAINT_VERSION
   // [self performSelector:@selector(showHelpWindow) withObject:nil afterDelay:1.5 inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
#endif
    
#endif
    
    if (!openLast) {
        
        NSArray *arrDocuments = [[NSDocumentController sharedDocumentController] documents];
        if(!arrDocuments || [arrDocuments count] == 0)
            [self performSelector:@selector(newDocument) withObject:nil afterDelay:1];
    }
}



- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo

{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        NSString *path = [gUserDefaults valueForKey:@"LAST_CRASH_FILE_PATH"];
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){}];
        
    }else if (returnCode == NSAlertSecondButtonReturn){
        
    }else if (returnCode == NSAlertThirdButtonReturn){
        
    }
    [NSApp stopModal];
}

-(void)newDocument
{
    [[NSDocumentController sharedDocumentController] newDocument:self];
}

#if ((defined TRIAL_VERSION) || (defined REGISTER_VERSION))
-(void)initRegisterVerify
{
    NSString *sRegisterBundlePath = [[NSBundle mainBundle] pathForResource:@"EccRegisterBundle" ofType:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:sRegisterBundlePath];
    if (bundle && [bundle principalClass])
    {
        VerifyRegistration* verifyRegistration = [[bundle principalClass] sharedVerifyRegistration];
        if (verifyRegistration)
        {
            
#ifdef REGISTER_VERSION
            [verifyRegistration setRegisterMode:0];
            [verifyRegistration setBuyPath:URL_BUY];
            unsigned char publicKey[] = REGISTER_PUBLIC_KEY;
            [verifyRegistration setPublicKey:publicKey];
#endif
            
            
#ifdef TRIAL_VERSION
            [verifyRegistration setRegisterMode:1];
            [verifyRegistration setBuyPath:URL_PRODUCT];
#endif
            
            NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
            [verifyRegistration setProductName:sProductName];
            
            
            NSMutableAttributedString *tips = [[NSMutableAttributedString alloc] init];
            NSMutableAttributedString *tip = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Thank you for using the trial version of %@", sProductName]] autorelease];
            NSRange range = NSMakeRange(0, [tip length]);
            [tip beginEditing];
            [tip addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithDeviceWhite:0.9 alpha:0.9] range:range];
            [tip addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:range];
            [tip endEditing];
            [tips appendAttributedString:tip];
            
            tip = [[[NSMutableAttributedString alloc] initWithString:@"\n\nNotice: \"Save\" and \"Export\" functions are not available!"] autorelease];
            range = NSMakeRange(0, [tip length]);
            [tip beginEditing];
            [tip addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:range];
            [tip addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:16] range:range];
            [tip endEditing];
            [tips appendAttributedString:tip];
            
            NSString *sTips = [NSString stringWithFormat:@"\n\nBenefits of purchasing  %@ :\n· Life-Time License, No Renewals Fee.\n· Get free technical support service via e-mail.\n· Get free regular upgrade.", sProductName];
            tip = [[[NSMutableAttributedString alloc] initWithString:sTips] autorelease];
            range = NSMakeRange(0, [tip length]);
            [tip beginEditing];
            [tip addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithDeviceWhite:0.9 alpha:0.9] range:range];
            [tip addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:range];
            [tip endEditing];
            [tips appendAttributedString:tip];
            
            tip = [[[NSMutableAttributedString alloc] initWithString:@"\n\nIf you want more details or have any question, please feel free to contact us: market@effectmatrix.com"] autorelease];
            range = NSMakeRange(0, [tip length]);
            [tip beginEditing];
            [tip addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithDeviceWhite:0.9 alpha:0.9] range:range];
            [tip addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:range];
            [tip endEditing];
            [tips appendAttributedString:tip];
            
            
            [verifyRegistration addTips:tips];
            [verifyRegistration verifyRegistration];
        }
    }
    
}
#endif

-(void)openHelpUrlDirectly
{
    
#if ((defined TRIAL_VERSION) || (defined REGISTER_VERSION))
    NSString *sRegisterBundlePath = [[NSBundle mainBundle] pathForResource:@"EccRegisterBundle" ofType:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:sRegisterBundlePath];
    if (bundle && [bundle principalClass])
    {
        VerifyRegistration* verifyRegistration = [(VerifyRegistration *)[bundle principalClass] sharedVerifyRegistration];
        if (verifyRegistration && [verifyRegistration isRegisted]) return;
    }

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.effectmatrix.com/mac-appstore/mac-photo-editor-pixelstyle.htm"]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.effectmatrix.com/mac-appstore/photo-editor-mac-tutorials.htm"]];
    
#endif
    
    
}

-(void)checkTrialDaysState
{
#if ((defined TRIAL_VERSION) || (defined REGISTER_VERSION))
    NSString *sRegisterBundlePath = [[NSBundle mainBundle] pathForResource:@"EccRegisterBundle" ofType:@"bundle"];
    NSBundle* bundle = [NSBundle bundleWithPath:sRegisterBundlePath];
    if (bundle && [bundle principalClass])
    {
        VerifyRegistration* verifyRegistration = [(VerifyRegistration *)[bundle principalClass] sharedVerifyRegistration];
        if (verifyRegistration && [verifyRegistration isRegisted]) return;
    }
    
#endif
    
    NSInteger nsFromTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"TimeFrom"];
    if(nsFromTime == 0)
    {
        nsFromTime = time(NULL);
        [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)time(NULL) forKey:@"TimeFrom"];
    }
    
    NSInteger nDaysRemained = 10 - (time(NULL) - nsFromTime)/(24 * 3600);
    if(nDaysRemained < 0) nDaysRemained = 0;
    
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    NSAlert *pAlertRegister = [NSAlert alertWithMessageText:@"Alert" defaultButton:@"To get full version" alternateButton:nil otherButton:@"Cancel" informativeTextWithFormat:@"Trial Version of %@, \n Free trial time remaining %i days", sProductName, (int)nDaysRemained];
    
    [pAlertRegister setIcon:[NSImage imageNamed:@"Icon.png"]];
    int returnCode = [pAlertRegister runModal];
    if(returnCode == NSAlertDefaultReturn)
    {
        NSString *str = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%d?mt=12", APPLE_ID];
#ifdef REGISTER_VERSION
        str = URL_BUY;
#endif
        
        
#ifdef TRIAL_VERSION
        str = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%d?mt=12", APPLE_ID];
#endif
        
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:str]];
        
        NSInteger nsFromTime    = [[NSUserDefaults standardUserDefaults] integerForKey:@"TimeFrom"];
        NSInteger nDaysRemained = 10 - (time(NULL) - nsFromTime)/(24 * 3600);
        
        if(nDaysRemained <= 0)  [NSApp terminate:nil];
    }
    else if (returnCode == NSAlertOtherReturn)
    {
        NSInteger nsFromTime    = [[NSUserDefaults standardUserDefaults] integerForKey:@"TimeFrom"];
        NSInteger nDaysRemained = 10 - (time(NULL) - nsFromTime)/(24 * 3600);
        
        if(nDaysRemained <= 0)  [NSApp terminate:nil];
    }
    
    [NSApp stopModal];
}

//#ifdef TRIAL_VERSION
//- (void)verifyRegistration:(VerifyRegistration *)verifyRegistration
//{
//    //[NSThread sleepForTimeInterval:0.1];
//    [verifyRegistration verifyRegistration];
//    [verifyRegistration release];
//}
//#endif

-(void)showHelpWindow
{
    bool bHideHelpWindow = [[NSUserDefaults standardUserDefaults] boolForKey:@"HidePixelStyleHelpWindow"];
    if (!bHideHelpWindow)//
    {
        NSRect windowRect = [[NSScreen mainScreen] frame];
        NSRect helpWindowRect = NSMakeRect(windowRect.origin.x +windowRect.size.width/10, windowRect.origin.y +windowRect.size.height/10, windowRect.size.width*4.0/5.0, windowRect.size.height*4.0/5.0);
        //NSRect helpWindowRect = NSMakeRect(0, 0, 800, 600);
        
        HelpWindow  *helpWindow = [[HelpWindow alloc] initWithContentRect:helpWindowRect styleMask:NSTitledWindowMask| NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
        NSRect boundsRect = [[[helpWindow contentView] superview] bounds];
        PSTitleView * titleview = [[PSTitleView alloc] initWithFrame:boundsRect];
        
        NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
        titleview.m_windowTitle=[NSString stringWithFormat:@"%@ Tutorial", sProductName];//@"PixelStyle Tutorial";
        [titleview setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [[[helpWindow contentView] superview] addSubview:titleview positioned:NSWindowBelow relativeTo:[[[[helpWindow contentView] superview] subviews] objectAtIndex:0]];
        
        [NSApp runModalForWindow:helpWindow];
    }
}

-(void)configClientInfo
{
    PSServerConfig *serverConfig = [PSServerConfig ShareInstance];
    [serverConfig checkClientVersion];
}

-(void)showFeedbackInterface
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *sAppName = [infoDictionary objectForKey:(NSString*)kCFBundleNameKey];
    NSString *sVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *sFeedBackApp = [[@"feedBack" stringByAppendingString:sAppName] stringByAppendingString:sVersion];
 
    BOOL bShowed = YES;//[[NSUserDefaults standardUserDefaults] boolForKey:sFeedBackApp];
    
    if(!bShowed)
    {
        NSInteger lastTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultValueKeyUserRateDate"];
        if (lastTime > 0)
        {
            NSInteger timeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970] - lastTime;
            if (timeInterval > 24 * 60 * 60 * 7)
            { // 3天提示一次:24 * 60 * 60 * 3
                if(!m_pEmailController)
                    m_pEmailController = [[EmailController alloc] init];
                NSWindow *w = [gCurrentDocument window];
                [m_pEmailController showEMailWindowWithModel:w];
 
            }
        }
        else
        {
            NSInteger nTime = (NSInteger)[[NSDate date] timeIntervalSince1970];
            [[NSUserDefaults standardUserDefaults] setInteger:nTime forKey:@"defaultValueKeyUserRateDate"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (id)utilitiesManager
{
	return m_idUtilitiesManager;
}

- (id)seaPlugins
{
	return m_idPSPlugins;
}

- (id)m_idPSPrefs
{
	return m_idPSPrefs;
}

- (id)seaProxy
{
	return m_idPSProxy;
}

-(id)psVectorProxy
{
    return m_idPSVectorProxy;
}

- (id)seaHelp
{
	return m_idPSHelp;
}

- (id)seaWarning
{
	return m_idPSWarning;
}

+ (id)utilitiesManager
{
	return [idPSController utilitiesManager];
}

+ (id)seaPlugins
{
	return [idPSController seaPlugins];
}

+ (id)m_idPSPrefs
{
	return [idPSController m_idPSPrefs];
}

+ (id)seaProxy
{
	return [idPSController seaProxy];
}

+ (id)psVectorProxy
{
    return [idPSController psVectorProxy];
}

+ (id)seaHelp
{
	return [idPSController seaHelp];
}

+ (id)seaWarning
{
	return [idPSController seaWarning];
}

- (IBAction)revert:(id)sender
{
	// Question whether to proceed with reverting
	if (NSRunAlertPanel(LOCALSTR(@"revert title", @"Revert"), [NSString stringWithFormat:LOCALSTR(@"revert body", @"\"%@\" has been edited. Are you sure you want to undo changes?"), [gCurrentDocument displayName]], LOCALSTR(@"revert", @"Revert"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {		
        [gCurrentDocument revertData];

	}
}

- (IBAction)editLastSaved:(id)sender
{
	id originalDocument, currentDocument = gCurrentDocument;
	NSString *old_path = [currentDocument fileName], *new_path = NULL;
	int i;
	BOOL done;
	
	// Find a unique new name
	done = NO;
	for (i = 1; i <= 64 && !done; i++) {
		if (i == 1) {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original).%@", [old_path pathExtension]];
			if ([gFileManager fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
		else {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original %d).%@", i, [old_path pathExtension]];
			if ([gFileManager fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
	}
	if (!done) {
		NSLog(@"Can't find suitable filename (last tried: %@)", new_path);
		return;
	}
	
	// Copy the contents on disk and open so the last saved version can be edited
	if ([gFileManager copyPath:old_path toPath:new_path handler:nil]) {
		originalDocument = [(PSDocumentController *)[NSDocumentController sharedDocumentController] openNonCurrentFile:new_path];
	}
	else {
		NSRunAlertPanel(LOCALSTR(@"locked title", @"Operation Failed"), [NSString stringWithFormat:LOCALSTR(@"locked body", @"The \"Compare to Last Saved\" operation failed. The most likely cause for this is that the disk the original is kept on is full or read-only."), [gCurrentDocument displayName]], LOCALSTR(@"ok", @"OK"), NULL, NULL);
		return;
	}
	
	// Finally remove the file we just created
	[gFileManager removeFileAtPath:new_path handler:NULL];
}

- (void)colorSyncChanged:(NSNotification *)notification
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Tell all documents to update there colour worlds
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] whiteboard] updateColorWorld];
	}
}

- (IBAction)showLicense:(id)sender
{
	[m_idLicenseWindow setLevel:NSFloatingWindowLevel];
	[m_idLicenseWindow makeKeyAndOrderFront:self];
}

- (IBAction)newDocumentFromPasteboard:(id)sender
{
	NSDocument *document;
	
	// Ensure that the document is valid
	if(![[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]]){
		NSBeep();
		return;
	}
	
	// We can now create the new document
	document = [[PSDocument alloc] initWithPasteboard];
	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
	[document autorelease];
}

- (void)registerForTermination:(id)object
{
	[m_arrTerminationObjects autorelease];
	m_arrTerminationObjects = [[m_arrTerminationObjects arrayByAddingObject:object] retain];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	int i;
	
	// Inform those that wish to know
	for (i = 0; i < [m_arrTerminationObjects count]; i++)
		[[m_arrTerminationObjects objectAtIndex:i] terminate];
	
	// Save the changes in preferences
	[gUserDefaults synchronize];
    
    [gUserDefaults setBool:0 forKey:@"APP_HAS_CRASHED"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return NO;
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app
{
    return [m_idPSPrefs openUntitled];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)app
{
	[[NSDocumentController sharedDocumentController] newDocument:self];
	
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
    BOOL bValidate = YES;
	id availableType;
	
	switch ([menuItem tag]) {
		case 175:
			bValidate = (gCurrentDocument && [gCurrentDocument fileName] && [gCurrentDocument isDocumentEdited] && [gCurrentDocument current]);
		break;
		case 176:
			bValidate = (gCurrentDocument && [gCurrentDocument fileName] && [gCurrentDocument current]);
		break;
		case 400:
			availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
			if (availableType)
				bValidate = YES;
			else
				bValidate = NO;
		break;
	}
	
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
}

-(void)updateMenuView
{
    //Menu
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    [m_menuItemAbout setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"About", nil),sProductName]];
    [m_menuItemHide setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Hide", nil),sProductName]];
    [m_menuItemQuit setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Quit", nil),sProductName]];
    [m_menuItemHelp setTitle:[NSString stringWithFormat:@"%@ %@",sProductName, NSLocalizedString(@"Help", nil)]];
    [m_menuItemForum setTitle:[NSString stringWithFormat:@"%@ %@",sProductName ,NSLocalizedString(@"Forum", nil)]];
    
//#ifdef PROPAINT_VERSION
//    NSArray *arrMenu = [[NSApp mainMenu] itemArray];
//    for(NSMenuItem *item in arrMenu)
//        if([[item title] isEqualToString:@"Shape"])
//            [[NSApp mainMenu] removeItem:item];
//#endif
}

+ (id)PSController
{
    return idPSController;
}

- (BOOL)judgeAndProcessLastCrashFile
{
    BOOL openLast = NO;
    BOOL hasCrash = [gUserDefaults boolForKey:@"APP_HAS_CRASHED"];
    if (hasCrash) {
        NSDictionary *crashInfo = [gUserDefaults valueForKey:@"LAST_CRASH_FILE_PATH"];
        NSArray *allValues = [crashInfo allValues];
        if (crashInfo ==nil || allValues == nil || [allValues count] <= 0) {
            
        }else{
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert addButtonWithTitle:NSLocalizedString(@"Open", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert setMessageText:NSLocalizedString(@"Do you want to reopen the last edited file ?", nil) ];
            [alert setInformativeText:@""];
            
            [alert setAlertStyle:NSWarningAlertStyle];
            
            int returnCode = [alert runModal];
            
            if (returnCode == NSAlertFirstButtonReturn)
            {
                for (int i = 0; i < [allValues count]; i++) {
                    NSDictionary *fileInfo = [allValues objectAtIndex:i];
                    NSString *path = [fileInfo objectForKey:@"crash save path"];
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES completionHandler:^(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error){
                        
                    }];
                }
                openLast = YES;
            }
            [NSApp stopModal];
        }
    }
    
    [gUserDefaults setBool:1 forKey:@"APP_HAS_CRASHED"];
    [gUserDefaults setValue:nil forKey:@"LAST_CRASH_FILE_PATH"];
    
    return openLast;
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *cachedPath = nil;
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
//    if ([paths count] > 0) {
//        cachedPath = [paths objectAtIndex:0];
//        cachedPath = [cachedPath stringByAppendingPathComponent:bundleID];
//    }
//    [fileManager removeItemAtPath:cachedPath error:nil];
    
    
}


@end
